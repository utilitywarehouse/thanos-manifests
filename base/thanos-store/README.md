# Store

# Kustomize nameSuffix patch

If you use `nameSuffix` in Kustomize, you need the following `replacement` for
Memcached Service reference in the base :

```
replacements:
  - source:
      kind: Service
      name: thanos-store-memcached-peers
    targets:
      - select:
          name: thanos-store
          kind: StatefulSet
        fieldPaths:
          - spec.template.spec.containers.[name=thanos-store].env.[name=MEMCACHED_SVC].value
```

## Updating Memcached

Add Bitnami repo locally:

```
$ helm repo add bitnami https://charts.bitnami.com/bitnami
```

Render Memcached manifest:

```
$ helm template thanos-store bitnami/memcached -f values.yaml > memcached.yaml
```

It comes with `namespace: default`, so remove that, I don't know if there is a
Helm native way to do it:

```
$ sd '^\s*namespace: default\n' '' memcached.yaml
```
