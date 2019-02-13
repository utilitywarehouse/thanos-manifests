# thanos-manifests

Kustomize templates for Thanos and Prometheus.

`/base/local` contains team specific Thanos configuration, it provides Thanos Store, Prometheus, Thanos Compact and Thanos Rule services.

`/base/global` contains global Thanos configuration, it provides Thanos Query, Alertmanager.

```
tree
.
├── base
│   ├── global
│   └── local
│       ├── kustomization.yaml
│       ├── prometheus.yaml
│       ├── thanos-compact.yaml
│       ├── thanos-rule.yaml
│       └── thanos-store.yaml
├── example
│   ├── kustomization.yaml
│   ├── thanos-compact.yaml
│   └── thanos-rule.yaml
├── LICENSE
├── out.log
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
