# thanos-manifests

Kustomize templates for Thanos and Prometheus.

Main components that you get from base are:

- StatefulSet Prometheus    (replica x2)
- Deployment Thanos Compact (replica x1)
- Deployment Thanos Query   (replica x3)
- Deployment Thanos Rule    (replica x2)
- StatefulSet Thanos Store  (replica x2)

You need to provide config for the base to use, please refer to `/example`
overlays.

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

**Make sure that alert files end in `.yaml` !!!!**

### It's safe to assume defaults for Thanos Store and Thanos Compact

If you correctly setup Secrets it should just work. 

Consider adding overlay only if you need to set custom resource requirements.

### Make sure your custom overlays are under `patchesStrategicMerge`

**All other non kustomize resources need to live to be listed in `resources` section, as kube-applier will only apply those**

## Example

Check out `gcp/` and `aws/` overlays in `example` directory. 

You can build example with:

```
kustomize build example/aws/
```

## Requires

- https://github.com/kubernetes-sigs/kustomize

```
go get -u sigs.k8s.io/kustomize
```
