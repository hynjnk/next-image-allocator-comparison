# Next.js Image Allocator Comparison

This repository compares container memory usage for the official Next.js `with-docker` example while it optimizes a fixed image workload. It compares the glibc allocator Dockerfile with the same Dockerfile after installing and preloading jemalloc.

## Variants

- `Dockerfile`: the glibc baseline. It does not install `libjemalloc2` and does not set `LD_PRELOAD`.
- `Dockerfile.jemalloc`: the jemalloc variant. It installs `libjemalloc2` and sets `LD_PRELOAD=libjemalloc.so.2`.

The input is one committed 2800x2800 patterned PNG at `public/source.png`. `public/source-001.png` through `public/source-192.png` are symbolic links to that file.

For allocator background, see [Sharp's Linux memory allocator guidance](https://sharp.pixelplumbing.com/install/#linux-memory-allocator).

## Measurement Procedure

Run `./compare.sh` to build both images and measure their container memory usage.

The workload has 192 successful optimizer requests, concurrency 8, 2800x2800 PNG sources, `w=1920`, `q=75`, and `Accept: image/webp`.

## Results

Container memory is the `docker stats --no-stream` memory value. Values are recorded at startup and after the 30-second idle period.

| Allocator | Start | After idle | Increase |
| --- | ---: | ---: | ---: |
| glibc | 41.24 MiB | 358.40 MiB | 317.16 MiB |
| jemalloc | 47.59 MiB | 85.09 MiB | 37.50 MiB |

## Measurement Environment

- Measurement date: 2026-07-13
- Node.js base image tag: `24.13.0-slim`
- Docker Engine: 29.3.1
- Container architecture: x86_64
- Container CPU limit: 2
- Container memory limit: 1 GiB, with swap disabled

## License

MIT
