#!/usr/bin/env bash

set -euo pipefail

trap 'docker rm -f next-image-glibc next-image-jemalloc >/dev/null 2>&1 || true' EXIT

measure() {
  local allocator=$1
  local name="next-image-${allocator}"

  docker run -d --name "$name" -p 3000:3000 \
    --cpus=2 --memory=1g --memory-swap=1g "$name" >/dev/null

  sleep 1

  if [[ "$allocator" == "glibc" ]]; then
    docker exec "$name" sh -c \
      '! dpkg -s libjemalloc2 >/dev/null 2>&1; ! grep -q libjemalloc /proc/1/maps'
  else
    docker exec "$name" sh -c \
      'dpkg -s libjemalloc2 >/dev/null 2>&1; grep -q libjemalloc.so.2 /proc/1/maps'
  fi

  local start_memory start_mib after_memory after_mib increase_mib
  start_memory=$(docker stats --no-stream --format '{{.MemUsage}}' "$name")
  start_mib=${start_memory%% *}

  printf '%03d\n' {1..192} | xargs -P 8 -I{} sh -c '
    headers=$(curl --fail --silent --show-error --max-time 60 \
      --dump-header - --output /dev/null -H "Accept: image/webp" \
      "http://localhost:3000/_next/image?url=%2Fsource-{}.png&w=1920&q=75")
    printf "%s" "$headers" | grep -qi "^content-type: image/webp" &&
      printf "%s" "$headers" | grep -qi "^x-nextjs-cache: miss"
  '

  sleep 30
  after_memory=$(docker stats --no-stream --format '{{.MemUsage}}' "$name")
  after_mib=${after_memory%% *}
  increase_mib=$(LC_NUMERIC=C awk \
    -v start="${start_mib%MiB}" -v after="${after_mib%MiB}" \
    'BEGIN { printf "%.2f", after - start }')

  printf '%-8s start=%s after-idle=%s increase=%s MiB\n' \
    "$allocator" "$start_mib" "$after_mib" "$increase_mib"

  docker stop "$name" >/dev/null
}

docker build -f Dockerfile -t next-image-glibc .
docker build -f Dockerfile.jemalloc -t next-image-jemalloc .

measure glibc
measure jemalloc

docker rm -f next-image-glibc next-image-jemalloc >/dev/null
