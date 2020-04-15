# Thanos Manifests

This repository provides [Kustomize][1] base to deploy [Prometheus][2] +
[Thanos][3] and example overlays for general deployment in either AWS or GCP.

Table of Contents
=================

   * [Thanos Manifests](#thanos-manifests)
   * [Table of Contents](#table-of-contents)
      * [Usage](#usage)
         * [GCP configuration](#gcp-configuration)
      * [Requires](#requires)
      * [Migration to v0.4.0 notes](#migration-to-v040-notes)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

## Usage

To use the base, reference the remote in you `kustomization.yaml`

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/thanos-manifests/base?ref=v1.3.1
```

You then MUST patch the following resources:

- Prometheus `PROMETHEUS_URL` envvar
- Thanos Rule `ALERTMANAGER_URL` envvar
- Thanos Rule `THANOS_QUERY_URL` envvar

You MUST provide the following ConfigMaps:

- `alerts`
- `prometheus`
- `thanos-rule-alerts`
- `thanos-rule`
- `thanos-query`

You MUST provide the following Secrets:
- `thanos-storage`

Alert files MUST have `.yaml` extension.

### Additional Components

You will find that the base actually pulls each individual component as a sub-
base. The reason for this is so that we can add additional components without
having to deploy the entire stack.

The prime example of this is adding an extra set of a `prometheus`,
`thanos-storage` and `thanos-compact` stack which can be used with a separate
configuration. You can reference the more specific bases:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/thanos-manifests/base/prometheus?ref=v1.3.1
  - github.com/utilitywarehouse/thanos-manifests/base/thanos-store?ref=v1.3.1
  - github.com/utilitywarehouse/thanos-manifests/base/thanos-compact?ref=v1.3.1
```

Note that in this case you must still follow the configuration instructions in
the previous section, ignoring any parts for `thanos-rule` and `thanos-query`.

### GCP configuration

- Secret: `thanos-storage` contains an extra file `credentials.json`
- Patch Prometheus, Thanos Compact and Thanos Store with a new volumeMount, to
  provide thanos-storage credentials.json.

For a full example of Kustomize overlay please refer to the provider specific
example:

- [aws](example/aws/kustomization.yaml)
- [gcp](example/gcp/kustomization.yaml)

## Requires

- https://github.com/kubernetes-sigs/kustomize

```
go get -u sigs.k8s.io/kustomize
```

## Migration to v0.4.0 notes

On migration to v0.4.0 run thanos compact with
`--index.generate-missing-cache-file`, it will make your Thanos Store start up
blazingly fast.

> New Compactor flag: --index.generate-missing-cache-file was added to allow
quicker addition of index cache files. If enabled it precomputes missing files
on compactor startup. Note that it will take time and it's only one-off step
per bucket.

Also make sure to adjust:

```
--index-cache-size
--chunk-pool-size
```

Previously Cache limiting wasn't working properly and in v0.4.0 it's fixed and
by default limits to 250MB.

[1]: https://kustomize.io/
[2]: https://prometheus.io/
[3]: https://thanos.io/
