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
