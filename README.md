# thanos-manifests

Kustomize templates for Thanos and Prometheus.

`/base/local` contains basic Thanos configuration, it provides Thanos Store,
Prometheus, Thanos Compact and Thanos Rule services.

`/base/cloud-provider` contains provider specific patches.

```
.
├── base
│   ├── aws
│   │   ├── kustomization.yaml
│   │   ├── prometheus.yaml
│   │   ├── thanos-query.yaml
│   │   └── thanos-rule.yaml
│   ├── gcp
│   │   ├── kustomization.yaml
│   │   ├── prometheus.yaml
│   │   ├── thanos-compact.yaml
│   │   ├── thanos-query.yaml
│   │   ├── thanos-rule.yaml
│   │   └── thanos-store.yaml
│   └── local
│       ├── kustomization.yaml
│       ├── prometheus.yaml
│       ├── thanos-compact.yaml
│       ├── thanos-query.yaml
│       ├── thanos-rule.yaml
│       └── thanos-store.yaml
├── CODEOWNERS
├── example
│   └── aws
│       ├── kustomization.yaml
│       ├── prometheus.yaml
│       ├── resources
│       │   ├── prometheus-alerts.yaml
│       │   ├── prometheus.yaml.tmpl
│       │   ├── query-sd.yaml
│       │   ├── store-sd.yaml
│       │   └── thanos-rule-alerts.yaml
│       ├── secrets
│       │   └── thanos-storage-secret.yaml
│       ├── thanos-compact.yaml
│       └── thanos-rule.yaml
├── LICENSE
└── README.md
```

# Migration to v0.4.0 notes

On migration to v0.4.0 run thanos compact with `--index.generate-missing-cache-file`, it will make your Thanos Store start up blazingly fast.

> New Compactor flag: --index.generate-missing-cache-file was added to allow quicker addition of index cache files. If enabled it precomputes missing files on compactor startup. Note that it will take time and it's only one-off step per bucket.<Paste>

Also make sure to adjust:

```
--index-cache-size
--chunk-pool-size
```

Previously Cache limiting wasn't working properly and in v0.4.0 it's fixed and by default limits to 250MB.

## Configuration

follow examples in `/example/aws/`

You need following 5 configMaps:

- prometheus-alerts.yaml
- prometheus.yaml.tmpl
- query-sd.yaml
- store-sd.yaml
- thanos-rule-alerts.yaml

And 1 secret:

- thanos-storage-secret.yaml

**Make sure that alert files end in `.yaml` !!!!**

### It's safe to assume defaults for Thanos Store and Thanos Compact

If you correctly setup Secrets it should just work. 

Consider adding overlay only if you need to set custom resource requirements.

### Make sure your custom overlays are under `patchesStrategicMerge`

**All other non kustomize resources need to live to be listed in `resources` section, as kube-applier will only apply those**

### Import correct base

For AWS please use:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
- github.com/utilitywarehouse/thanos-manifests/base/aws?ref=v1.1.12
```

For GCP please use:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
- github.com/utilitywarehouse/thanos-manifests/base/gcp?ref=v1.1.12
```

### GCP bucket secret must have `config.yaml` and `credentials.json`

Example:

```
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: thanos-storage
data:
  config.yaml: SECRET
  credentials.json: GCP_SERVICE_ACCOUNT_BASE64_ENCODED_JSON
```

`config.yaml` doesn't actually contain any secret.

I generate it using:

```
echo -n 'type: GCS
config:
  bucket: BUCKET_NAME' | base64 -w0 | x
```

## Example

Check out `kustomization.yaml` in `example` directory. 

You can build example with:

```
kustomize build example 
```

## Requires

- https://github.com/kubernetes-sigs/kustomize

```
go get -u sigs.k8s.io/kustomize
```
