# `contrib/depends` build with the bumped libraries, 2026-11-07: **not completed, pending (R12-5)**

Tree `~/tmp/zeph-r4/zephyr-sec2`, tip `16018bb0b`. Its `contrib/depends` is identical to the published sec.2 tip
`1c1982aa7`: `git diff --stat 16018bb0b 1c1982aa7 -- contrib/depends` in the fork is empty, and the tree's
`contrib/depends` has no local change. Host toolchain: `gcc (Debian 14.2.0-19) 14.2.0`. The home directory
is written as `~`.

Pinned versions (`$(package)_version` in `contrib/depends/packages/*.mk`, as read from the tree):
unbound `1.26.1`, openssl `3.0.22`, boost `1_64_0`, zeromq `4.3.5`, expat `2.6.0`, sodium `1.0.18`.
RandomX is not a depends package; it is in `external/randomx`.

## Command and duration
```
$ make -C contrib/depends HOST=x86_64-linux-gnu -j6 2>&1 | tee ~/tmp/zeph-r4/depends-x86_64.log
```
Start 2026-11-07T00:55:45Z, end 00:57:23Z (1 min 38 s), exit 2. The daemon build against the
toolchain file was not started, because it needs the finished depends prefix.

Packages handled, in log order (`grep -E '^(Fetching|Extracting|…|Caching) '`):
```
Fetching protobuf-cpp-3.21.12.tar.gz from https://github.com/protocolbuffers/protobuf/releases/download/v21.12/
Extracting native_protobuf...
Preprocessing native_protobuf...
Configuring native_protobuf...
Building native_protobuf...
Staging native_protobuf...
Postprocessing native_protobuf...
Caching native_protobuf...
Fetching boost_1_64_0.tar.bz2 from https://downloads.sourceforge.net/project/boost/boost/1.64.0/
Extracting boost...
Preprocessing boost...
Configuring boost...
Building Boost.Build engine with toolset gcc...
```
`native_protobuf` 21.12 was fetched, built and cached
(`built/x86_64-linux-gnu/native_protobuf/native_protobuf-21.12-a4ab5cd740f.tar.gz`). boost 1.64.0 was fetched, and its
checksum passed. **Configuring boost failed.** `make` stopped there, so openssl, unbound, zeromq,
expat and sodium were not reached (their `built/` directories are empty). The end of the log, verbatim:
```


~/tmp/zeph-r4/zephyr-sec2/contrib/depends/work/download/boost-1_64_0/boost_1_64_0.tar.bz2.temp: OK
Extracting boost...
~/tmp/zeph-r4/zephyr-sec2/contrib/depends/sources/boost_1_64_0.tar.bz2: OK
Preprocessing boost...
patching file tools/build/src/tools/gcc.jam
patching file tools/build/src/tools/darwin.jam
Configuring boost...
Building Boost.Build engine with toolset gcc...
Failed to build Boost.Build build engine
Consult 'bootstrap.log' for more details
make: *** [funcs.mk:270: ~/tmp/zeph-r4/zephyr-sec2/contrib/depends/work/build/x86_64-linux-gnu/boost/1_64_0-9467eec650d/./.stamp_configured] Error 1
make: Leaving directory '~/tmp/zeph-r4/zephyr-sec2/contrib/depends'
```
`bootstrap.log` of boost (`contrib/depends/work/build/x86_64-linux-gnu/boost/1_64_0-9467eec650d/bootstrap.log`), the error lines:
```
execcmd.c:120:5: error: implicit declaration of function ‘out_printf’ [-Wimplicit-function-declaration]
make.c:132:13: error: implicit declaration of function ‘out_printf’ [-Wimplicit-function-declaration]
make.c:735:13: error: implicit declaration of function ‘out_flush’ [-Wimplicit-function-declaration]
filesys.c:360:10: error: implicit declaration of function ‘filelist_empty’; did you mean ‘filelist_next’? [-Wimplicit-function-declaration]
modules/path.c:16:12: error: implicit declaration of function ‘file_query’ [-Wimplicit-function-declaration]
fileunix.c:233:10: error: implicit declaration of function ‘filelist_empty’; did you mean ‘filelist_next’? [-Wimplicit-function-declaration]
fileunix.c:235:14: error: implicit declaration of function ‘file_collect_archive_content_’; did you mean ‘file_collect_dir_content_’? [-Wimplicit-function-declaration]
```
Cause, as read: boost 1.64.0's Boost.Build engine (`bjam`) is C code with implicit function
declarations. GCC 14 treats them as an error by default (`-Wimplicit-function-declaration` is an error from GCC 14 on). The
bootstrap uses the host `gcc`. Nothing here comes from the fork's changes: SB-020, SB-021, SB-024 and SB-027 to SB-029 change the
openssl and unbound pins (SB-022 the autoconf cross-compile mode), not boost. No URL, pin or compiler flag was changed, and nothing was retried.

## The CI form
Upstream's `depends.yml` is disabled in the fork. Its matrix ran only on the retired `ubuntu-20.04`
runners (see `../../ci/2026-11-07/fork-ci.md`), so the CI form of this check stays unavailable. Upstream's
own `depends` CI is as broken as in the fork.

## Bumped packages only (2026-11-07T01:38Z): **built**
The two bumped pins do not need boost, so only they (and what they depend on) were built, in the same tree:
```
$ make -C contrib/depends HOST=x86_64-linux-gnu openssl unbound -j6 2>&1 | tee ~/tmp/zeph-r4/depends-pkgs.log
```
Start 2026-11-07T01:38:36Z, end 01:39:57Z (1 min 21 s), exit 0. `make` also built expat 2.6.0, which unbound depends on.
The steps as printed (`grep -E '^(Fetching|…|Caching) |: OK$'`), with the home directory written as `~`:
```
Fetching openssl-3.0.22.tar.gz from https://github.com/openssl/openssl/releases/download/openssl-3.0.22
~/tmp/zeph-r4/zephyr-sec2/contrib/depends/work/download/openssl-3.0.22/openssl-3.0.22.tar.gz.temp: OK
Extracting openssl...
~/tmp/zeph-r4/zephyr-sec2/contrib/depends/sources/openssl-3.0.22.tar.gz: OK
Preprocessing openssl...
Configuring openssl...
Configuring OpenSSL version 3.0.22 for target linux-x86_64
Building openssl...
Staging openssl...
Postprocessing openssl...
Caching openssl...
Fetching expat-2.6.0.tar.bz2 from https://github.com/libexpat/libexpat/releases/download/R_2_6_0/
~/tmp/zeph-r4/zephyr-sec2/contrib/depends/work/download/expat-2.6.0/expat-2.6.0.tar.bz2.temp: OK
Extracting expat...
~/tmp/zeph-r4/zephyr-sec2/contrib/depends/sources/expat-2.6.0.tar.bz2: OK
Preprocessing expat...
Configuring expat...
Building expat...
Staging expat...
Postprocessing expat...
Caching expat...
Fetching unbound-1.26.1.tar.gz from https://www.nlnetlabs.nl/downloads/unbound/
~/tmp/zeph-r4/zephyr-sec2/contrib/depends/work/download/unbound-1.26.1/unbound-1.26.1.tar.gz.temp: OK
Extracting unbound...
~/tmp/zeph-r4/zephyr-sec2/contrib/depends/sources/unbound-1.26.1.tar.gz: OK
Preprocessing unbound...
Configuring unbound...
Building unbound...
Staging unbound...
Postprocessing unbound...
Caching unbound...
```
Pins and checksums (`contrib/depends/packages/{openssl,unbound,expat}.mk`) against `sha256sum` of the fetched sources;
`make` printed `OK` for each, on download and again on extraction:

| package | version | URL | pinned sha256 = `sha256sum` of `sources/` |
|---|---|---|---|
| openssl | 3.0.22 | `https://github.com/openssl/openssl/releases/download/openssl-3.0.22/openssl-3.0.22.tar.gz` | `67ebca7e50d17383028045486653492195b83db95f8558709701bb47b5c1ef81` |
| unbound | 1.26.1 | `https://www.nlnetlabs.nl/downloads/unbound/unbound-1.26.1.tar.gz` | `35a6dc0e425a9282c3426d9a3043144011bf0534aed4b73ab62c52aee0af1503` |
| expat | 2.6.0 | `https://github.com/libexpat/libexpat/releases/download/R_2_6_0/expat-2.6.0.tar.bz2` | `ff60e6a6b6ce570ae012dc7b73169c7fdf4b6bf08c12ed0ec6f55736b78d85ba` |

Result per package: all three were configured, built, staged and cached without error. The cache files are
`built/x86_64-linux-gnu/openssl/openssl-3.0.22-bbd11d4ae66.tar.gz` and `built/x86_64-linux-gnu/unbound/unbound-1.26.1-92dd5a0bc1b.tar.gz`.
```
$ ls contrib/depends/x86_64-linux-gnu/lib | grep -E "ssl|crypto|unbound"
libcrypto.a
libssl.a
ossl-modules
$ tar -tzf contrib/depends/built/x86_64-linux-gnu/unbound/unbound-1.26.1-92dd5a0bc1b.tar.gz | grep -E 'lib/|include/unbound'
./include/unbound.h
./lib/
./lib/libunbound.a
./lib/libunbound.la
./lib/pkgconfig/
./lib/pkgconfig/libunbound.pc
```
The prefix `x86_64-linux-gnu/` holds openssl (`libssl.a`, `libcrypto.a`) because unbound's build depends on it and
`make` unpacked it there. unbound itself is only in its cache tarball (with `lib/libunbound.a`), because no further
package in this run depends on it. A full `depends` run unpacks all packages into the prefix.

**Shown:** openssl 3.0.22 and unbound 1.26.1 fetch from their pinned URLs, verify against their pinned checksums and
build with `contrib/depends` for `x86_64-linux-gnu`. **Still pending:** a full `depends` daemon build, which needs
an older toolchain than GCC 14 for boost 1.64's `bjam` (see above). That belongs to the release builder (`tools/release/`),
not to this VM, which has no container runtime.
