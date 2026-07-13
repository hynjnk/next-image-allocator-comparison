# Next.js Image Allocator Comparison

This repository compares container memory usage for the official Next.js `with-docker` example while it optimizes a fixed image workload. It compares the glibc allocator Dockerfile with the same Dockerfile after installing and preloading jemalloc.

## Variants

- `Dockerfile`: the glibc baseline.
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
| glibc | 40.49 MiB | 358.90 MiB | 318.41 MiB |
| jemalloc | 47.40 MiB | 84.53 MiB | 37.13 MiB |

## Measurement Environment

- Measurement date: 2026-07-15
- Node.js base image tag: `24.13.0-slim`
- Docker Engine: 29.3.1
- Container architecture: x86_64
- Container CPU limit: 2
- Container memory limit: 1 GiB, with swap disabled

## License

MIT
