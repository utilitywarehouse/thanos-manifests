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

```console
make update-memcached
```