#!/bin/sh
# Thanos store-gateway sharding entrypoint.
#
# Single StatefulSet, R replicas per shard:
#   shard = ordinal / REPLICAS_PER_SHARD   (e.g. R=2 -> pods 0,1->shard0, 2,3->shard1)
#
# Writes a per-pod relabel config that keeps only this shard's blocks, then
# starts thanos with --selector.relabel-config-file. Writing to a file avoids
# k8s/thanos $(VAR) arg-expansion (k8s pre-expands $(...) in args; thanos
# expandEnv chokes on it) - the mechanism that failed on exp-1.
set -e
ordinal="${POD_NAME##*-}"                                # thanos-...-5 -> 5
shard=$(( ordinal / REPLICAS_PER_SHARD ))              # R from StatefulSet env

mkdir -p /var/thanos/shard
cat > /var/thanos/shard/relabel.yaml <<EOF
- action: hashmod
  source_labels: ["__block_id"]
  modulus: ${SHARD_COUNT}
  target_label: __tmp_shard
- action: keep
  source_labels: ["__tmp_shard"]
  regex: "^${shard}\$"
EOF

# --selector.relabel-config-file must come AFTER the `store` subcommand.
exec /bin/thanos "$@" --selector.relabel-config-file=/var/thanos/shard/relabel.yaml
