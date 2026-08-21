#!/bin/sh
# Thanos store-gateway sharding entrypoint.
#
# Single StatefulSet, R replicas per shard:
#   shard = ordinal / REPLICAS_PER_SHARD  (R=2: pods 0,1->shard0; 2,3->shard1)
#
# Writes a per-pod relabel config that keeps only this shard's blocks, then
# starts thanos with --selector.relabel-config-file. Writing to a file avoids
# k8s/thanos $(VAR) arg-expansion (k8s pre-expands $(...) in args; thanos
# expandEnv chokes on it) - the mechanism that failed on exp-1.
set -eu
# thanos-store-5 -> ordinal 5
ordinal="${POD_NAME##*-}"
shard=$(( ordinal / REPLICAS_PER_SHARD ))

# Fail loud instead of silent under-coverage: if replicas were overridden
# without matching SHARD_COUNT/REPLICAS_PER_SHARD, shard can exceed the
# modulus, the keep regex matches nothing, and the pod serves zero blocks.
if [ "$shard" -ge "$SHARD_COUNT" ]; then
  echo "shard $shard >= SHARD_COUNT $SHARD_COUNT;" \
    "check replicas / REPLICAS_PER_SHARD" >&2
  exit 1
fi

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
exec /bin/thanos "$@" \
  --selector.relabel-config-file=/var/thanos/shard/relabel.yaml
