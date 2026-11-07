# Which backports of the release set are compiled into the WASM (2026-11-07)

Build: `set-2026-11-07-build-manifest.json` (zephyr `v2.3.0-sec.2` `8c6a120256b4bd887d6e7167d929d76e3507e0e5`,
zephyr-cpp `v2.3.0-sec.1` `3a2ee602ee28e6b7941b617ad4706349ad992641`, zephyr-javascript `9d022ded`), build tree
`/tmp/zeph-wasm/build`.

Method: the compiler dependency files of the WASM link (`build/CMakeFiles/monero_wallet_{full,keys}.dir/**/*.o.d`,
142 objects) list every source and header each object was compiled from: 316 files of zephyr and 12 of zephyr-cpp
(outside its `external/`). For every cherry-pick above the upstream base (zephyr `v2.3.0..8c6a12025`, zephyr-cpp
`4a99272..3a2ee602e`), the files the commit changes (`git show --name-only`) are intersected with that list. This
is a file-level check: a file that is compiled in may still hold a changed function that the linker drops.

| advisory | upstream commit | files compiled into the WASM (target) |
|---|---|---|
| SB-001 | monero `74c313420` | `contrib/epee/src/byte_slice.cpp` (full, keys) |
| SB-002 | monero `1d3d30c50` | `src/crypto/hash.h` (full, keys) |
| SB-003 | monero `7a7c42ffb` | `src/serialization/binary_archive.h` (full, keys) |
| SB-004 | monero `dedae5272` | `contrib/epee/src/parserse_base_utils.cpp` (full, keys) |
| SB-005 | monero `0b7967907` | `src/wallet/wallet2.cpp` (full) |
| SB-006 | monero `72d91039e` | `src/wallet/wallet2.cpp` (full) |
| SB-007 | monero `987a2a77d` | `src/wallet/wallet2.cpp` (full) |
| SB-008 | monero `ef7bdda92` | `src/wallet/wallet2.cpp` (full) |
| SB-009 | monero `d9236332a` | `src/wallet/wallet2.cpp` (full) |
| SB-010 | monero `e62963ceb` | none |
| SB-011 | monero-cpp `6d6d203f9` | `src/wallet/monero_wallet_full.cpp` (full) |
| SB-012 | monero-cpp `83832b89f` | `src/wallet/monero_wallet_model.cpp` (full, keys) |
| SB-013 | monero-cpp `48664ebaf` | `src/wallet/monero_wallet_model.cpp` (full, keys) |
| SB-014 | monero-cpp `44c81a80c` | `src/wallet/monero_wallet_full.cpp` (full) |
| SB-015 | monero `b99d15f08` | `src/wallet/wallet2.cpp` (full) |
| SB-016 | monero `bbd635075` | `src/wallet/wallet2.cpp` (full), `src/wallet/wallet2.h` (full, keys) |
| SB-017 | monero `c86fd739d` | `src/wallet/wallet2.cpp` (full) |
| SB-018 | monero `144b3f9e6` | `src/wallet/wallet2.cpp` (full) |
| SB-019 | monero `52b33f4fb` | `external/easylogging++/easylogging++.cc`, `.h` (full, keys) |
| SB-020 to SB-029 | depends, RandomX, Windows build | none |
| SB-030 to SB-034 | daemon RPC, levin, ZMQ | none |

Result: 19 of the 34 advisories of the release set change code compiled into the WASM (SB-001 to SB-009,
SB-011 to SB-019); SB-010 and SB-020 to SB-034 do not reach it.
