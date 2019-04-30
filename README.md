# thanos-manifests

Kustomize templates for Thanos and Prometheus.

`/base/local` contains team specific Thanos configuration, it provides Thanos Store, Prometheus, Thanos Compact and Thanos Rule services.

`/base/global` contains global Thanos configuration, it provides Thanos Query, Alertmanager.

```
.
├── base
│   ├── aws
│   │   ├── kustomization.yaml
│   │   ├── prometheus.yaml
│   │   └── thanos-rule.yaml
│   ├── gcp
│   │   ├── kustomization.yaml
│   │   ├── prometheus.yaml
│   │   ├── thanos-compact.yaml
│   │   ├── thanos-rule.yaml
│   │   └── thanos-store.yaml
│   ├── global
│   └── local
│       ├── alerts.yaml
│       ├── kustomization.yaml
│       ├── prometheus-alerts.yaml
│       ├── prometheus-configmap.yaml
│       ├── prometheus.yaml
│       ├── thanos-compact.yaml
│       ├── thanos-rule.yaml
│       ├── thanos-storage-secret.yaml
│       └── thanos-store.yaml
├── example
│   ├── kustomization.yaml
│   ├── prometheus-alerts.yaml
│   ├── prometheus.yaml
│   ├── thanos-compact.yaml
│   ├── thanos-rule.yaml
│   └── thanos-storage-secret.yaml
├── LICENSE
└── README.md
```

## Conventions

### Prometheus local alerts live in `thanos-rule-alerts` ConfigMap; key needs to be `thanos-rule.yaml`.

Example:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: thanos-rule-alert
data:
  thanos-rule.yaml: ...
```

### S3 storage bucket secret lives in `thanos-storage` secret, key needs to be `config.yaml`:

Example:

```
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: thanos-storage
data:
  config.yaml: ...
```

You need to base64 encode the storage config even in GCP case.

Config format can be seen in https://thanos.io/storage.md/#aws-s3-configuration.

### Prod Ingress needs correct DNS annotations

AWS example:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/target: in-k8s.prod.uw.systems
```

GCP example:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prometheus
  annotations:
    external-dns.alpha.kubernetes.io/target: private-ingress-k8s.prod.gcp.uw.systems
```

### Alerts that run in Thanos rule should live in `alerts` ConfigMap.

Example:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: alerts
data:
  telco-ops.yaml: ...
```

**Make sure that alert files end in `.yaml` !!!!**

### It's safe to assume defaults for Thanos Store and Thanos Compact

If you correctly setup Secrets it should just work. 

Consider adding overlay only if you need to set custom resource requirements.

### Make sure your custom overlays are under `patchesStrategicMerge`

Example:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
- github.com/utilitywarehouse/thanos-manifests/base/aws?ref=v1.1.12
namespace: telecom
patchesStrategicMerge:
- secrets/thanos-storage-secrets.yaml
- thanos-rule-alerts.yaml
- prometheus-configmap.yaml
- alerts.yaml
- thanos-rule.yaml
- prometheus.yaml
resources:
- 00-namespace.yaml
- ...
```

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
