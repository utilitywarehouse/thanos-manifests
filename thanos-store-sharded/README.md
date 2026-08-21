# thanos-store-sharded

Kustomize component that turns the vanilla `base/thanos-store` into a
horizontally sharded store-gateway. Blocks are split across pods by
`hashmod(__block_id, SHARD_COUNT)`, so each pod holds ~1/N of the blocks
and per-pod memory drops ~1/N. The store scales out instead of falling
over when query traffic grows.

This component only overlays the sharding mechanism on the base. It does
not replace anything the base already provides.

## Consuming from an overlay

Reference the base and this component together, pinned to the same
commit so the build is reproducible:

```yaml
# <consumer>/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
nameSuffix: -sharded

resources:
  - github.com/utilitywarehouse/thanos-manifests/base/thanos-store?ref=MYREF
components:
  - github.com/utilitywarehouse/thanos-manifests/thanos-store-sharded?ref=MYREF
```

If you add a `nameSuffix`, the store's `MEMCACHED_SVC` env must point at
the renamed memcached peers service. Substitute it from the generated
service:

```yaml
replacements:
  - source:
      kind: Service
      name: thanos-store-memcached-peers
    targets:
      - fieldPaths:
          - spec.template.spec.containers.[name=thanos-store].env.[name=MEMCACHED_SVC].value
        select:
          kind: StatefulSet
          name: thanos-store
```

## What the consuming overlay must still provide

The component adds the mechanism only. Environment-specific bits stay in
the overlay:

- ServiceAccount (IAM/Vault role for object storage) and any vault
  sidecar annotation
- `OTEL_SERVICE_NAME` so traces identify the environment
- Resources/limits sized for the environment
- Storage and tracing configs (e.g. a `thanos-storage-config` reference
  replacing the base's placeholder)

Defaults the component sets, and how to override them:

| Field                      | Default | Override              |
|----------------------------|---------|-----------------------|
| `replicas`                 | 8       | patch `spec.replicas` |
| `REPLICAS_PER_SHARD` (env) | 2       | patch container env   |
| `SHARD_COUNT` (env)        | 4       | patch container env   |

`SHARD_COUNT` is the hashmod modulus; it must equal `replicas /
REPLICAS_PER_SHARD`. Keep the same shape across environments and scale
by size, not by structure: sharding, replication, and limits must match
between dev and prod, or prod becomes the first place a new shape runs.

## Rolling out PVC or replica-shape changes

Bumping `replicas` syncs like any StatefulSet change. Changing the data
PVC (via `volumeClaimTemplates` in the consuming overlay) does not:
Kubernetes forbids patching a live StatefulSet's volumeClaimTemplates,
and existing PVC claims can only grow, never shrink. Roll such a change
by deleting the StatefulSet and letting the deployer recreate it (Argo
CD selfHeal, kube-applier, or plain `kubectl apply`). The `data` volume
only caches per-shard index headers, so pods re-download theirs from
object storage on startup; if the claim size must change, delete the
old PVCs too (the new claims are provisioned fresh).

## How it works

The entrypoint (mounted from a generated ConfigMap) computes each pod's
shard from its ordinal:

    shard = ordinal / REPLICAS_PER_SHARD    # pods 0,1 -> shard 0; 2,3 -> shard 1; ...

writes a relabel config that keeps only that shard's blocks, then execs
thanos with `--selector.relabel-config-file`. Constraints that shaped
this design:

- K8s pre-expands `$(VAR)` in container args, and thanos `expandEnv`
  chokes on it, so the relabel config is written to a file at startup
  and passed via `--selector.relabel-config-file` rather than inlined in
  args.
- `--selector.relabel-config-file` must come after the `store`
  subcommand (it fails with "unknown long flag" earlier), so it is
  appended in the entrypoint's final `exec`, after `"$@"`.
- `SHARD_COUNT` / `REPLICAS_PER_SHARD` come only from the StatefulSet
  env; the entrypoint has no fallback defaults, so the env is the single
  source of truth.
- The entrypoint ConfigMap keeps a stable name (no content hash), so
  editing `entrypoint.sh` will not trigger a pod rollout on its own;
  run a manual rollout restart after script changes.

Verify a deployment by checking that each pod's
`thanos_bucket_store_blocks_loaded` is roughly total-blocks / N, and
that a query server pointed at the (single) store service still returns
results merged across all shards.
