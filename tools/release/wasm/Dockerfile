# DRAFT, not run. Container for the reproducible WASM build of the Zephyr wallet library.
#
# It runs the webwallet project's build script unchanged, mounted read-only:
#   ~/github/zeph-webwallet-workrepo/tools/wasm/build.sh
# The script pins every source and tool itself (commits, sha256 of tarballs, emsdk version and
# installer commit) and writes build-manifest.json with the output hashes. This image only
# freezes the host side: base image by digest, Debian packages from a dated snapshot, and emsdk
# 3.1.10 preinstalled at the installer commit build.sh pins (so the build needs no network for
# the toolchain; it still fetches the pinned tarballs and, without mirrors, the sources).
#
# Build:  docker build -t zephyr-wasm-builder tools/release/wasm
# Run:    see README.md next to this file.

# debian:bookworm-slim, linux/amd64 manifest, digest looked up 2026-11-05. bookworm rather than
# trixie: emsdk 3.1.10 (2022) and its Python scripts predate Python 3.12/3.13 module removals;
# bookworm ships Python 3.11 (estimate of the risk, not tested on trixie).
FROM --platform=linux/amd64 debian:bookworm-slim@sha256:a3bba7dc7dbcc1f37c2856c51fc9a7fac96608f50cb87b1b4e4d8b8c85ae988e

# Debian packages from snapshot.debian.org at a fixed point in time, so a rebuild of the image
# gets the same package versions.
ARG DEBIAN_SNAPSHOT=20261105T000000Z
RUN rm -f /etc/apt/sources.list.d/debian.sources \
 && printf '%s\n' \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} bookworm main" \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} bookworm-updates main" \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT} bookworm-security main" \
      > /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      bash binutils ca-certificates coreutils curl g++ git make perl python3 tar xz-utils \
 && rm -rf /var/lib/apt/lists/*

# build.sh needs: bash, git, curl, perl, python3, make, a host C/C++ compiler (translations
# tool), strings (binutils), sha256sum and nproc (coreutils).
RUN useradd -m -u 1000 builder \
 && git config --system --add safe.directory '*'   # sources are cloned from read-only mounts owned by another uid

# Same layout build.sh expects in $WASM_CACHE: tools/emsdk at the pinned installer commit.
ARG EMSDK_REPO_COMMIT=d7b4130688bfa348392b921ab04015aa15c4f154
ARG EMSDK_VERSION=3.1.10
ENV WASM_CACHE=/cache
RUN mkdir -p /cache/tools /cache/dl && chown -R builder:builder /cache
USER builder
RUN git clone -q https://github.com/emscripten-core/emsdk.git /cache/tools/emsdk \
 && git -C /cache/tools/emsdk checkout -q "${EMSDK_REPO_COMMIT}" \
 && cd /cache/tools/emsdk \
 && ./emsdk install "${EMSDK_VERSION}" \
 && ./emsdk activate "${EMSDK_VERSION}"

# /webwallet: the webwallet work repo, mounted read-only (build.sh derives ROOT from its own path).
# /work:      writable mount; build.sh wipes and refills $WASM_BUILD, so it must be a directory
#             inside the mount, not the mount point itself.
# /mirrors:   optional read-only mirrors of zephyr, zephyr-cpp, zephyr-javascript (ZEPH_SRC);
#             without them build.sh clones from github.com/ZephyrProtocol.
ENV WASM_BUILD=/work/build \
    ZEPH_SRC=/mirrors
WORKDIR /work
ENTRYPOINT ["/webwallet/tools/wasm/build.sh"]
