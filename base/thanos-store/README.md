# Store
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
