# Native builds with Monero's unit tests, 2026-11-05

Three trees cloned from the zephyr fork and built on Debian 13.7 with gcc 14.2.0, cmake 3.31.6,
boost 1.83 (distribution packages), `cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON -DUSE_CCACHE=ON ..`
and `make -j6 daemon simplewallet wallet_rpc_server unit_tests`, then `./tests/unit_tests/unit_tests`.
No patch and no extra define in any tree. The home directory of the build machine is written as `~`.

| tree | ref | HEAD | configure / build | `--version` (zephyrd, zephyr-wallet-cli, zephyr-wallet-rpc) |
|---|---|---|---|---|
| v2.3.0 (control) | tag `v2.3.0` | `67c5f53b878fef41fb5e74c4382d5b7a2f37fd8a` | OK / OK | `Zephyr 'Version 2.3' (v2.3.0-release)` |
| sec1 | `security/v2.3.0` | `20d689be7c3f4948c186ae1d110f4dab4b12d997` | OK / OK | `Zephyr 'Version 2.3' (v2.3.0-20d689be7)` |
| sec2 | `wip/sec.2` | `7ba805e61cfb9a3df3cb9d5cf946433f10d9af0a` | OK / OK | `Zephyr 'Version 2.3' (v2.3.0-7ba805e61)` |

The version suffix is set by `cmake/GitVersion.cmake`: `release` when a tag points at HEAD, the
9-character commit otherwise. The version number is the same in all three.

## gtest summaries, verbatim

v2.3.0:
```
 1 FAILED TEST
[  FAILED  ] 1 test, listed below:
[  FAILED  ] notify.works
[  FAILED  ] notify.works (1 ms)
[  PASSED  ] 1005 tests.
[==========] 1006 tests from 138 test cases ran. (61273 ms total)
[==========] Running 1006 tests from 138 test cases.
```

sec1:
```
 2 FAILED TESTS
[  FAILED  ] 2 tests, listed below:
[  FAILED  ] notify.works
[  FAILED  ] notify.works (0 ms)
[  FAILED  ] select_outputs.exact_unlock_block_tiny
[  FAILED  ] select_outputs.exact_unlock_block_tiny (0 ms)
[  PASSED  ] 1004 tests.
[==========] 1006 tests from 138 test cases ran. (59726 ms total)
[==========] Running 1006 tests from 138 test cases.
```

sec2:
```
 2 FAILED TESTS
[  FAILED  ] 2 tests, listed below:
[  FAILED  ] notify.works
[  FAILED  ] notify.works (0 ms)
[  FAILED  ] select_outputs.exact_unlock_block_tiny
[  FAILED  ] select_outputs.exact_unlock_block_tiny (0 ms)
[  PASSED  ] 1004 tests.
[==========] 1006 tests from 138 test cases ran. (62417 ms total)
[==========] Running 1006 tests from 138 test cases.
```

## Per-test comparison (all 1006 tests; status lines parsed with colour codes removed)
```
v2.3.0 1006 tests, 1005 OK, failed: ['notify.works']
sec1 1006 tests, 1004 OK, failed: ['notify.works', 'select_outputs.exact_unlock_block_tiny']
sec2 1006 tests, 1004 OK, failed: ['notify.works', 'select_outputs.exact_unlock_block_tiny']
DIFF select_outputs.exact_unlock_block_tiny {'v2.3.0': 'OK', 'sec1': 'FAILED', 'sec2': 'FAILED'}
```

### `notify.works` (fails on all three; a build-target artefact)
```
[ RUN      ] notify.works
unknown file: Failure
C++ exception with description "File not found: ./tests/unit_tests/test_notifier" thrown in the test body.
[  FAILED  ] notify.works (1 ms)
```
`notify.works` runs the helper `test_notifier`, a separate target (`tests/unit_tests/CMakeLists.txt`
line 158) not in the make line above. After `make -j6 test_notifier` in each tree,
`./tests/unit_tests/unit_tests --gtest_filter='notify.*'` gives `[  PASSED  ] 1 test.` on v2.3.0,
sec1 and sec2.

### `select_outputs.exact_unlock_block_tiny` (new failure on sec1 and sec2, passes on v2.3.0)
```
[ RUN      ] select_outputs.exact_unlock_block_tiny
unknown file: Failure
C++ exception with description "No outputs in consideration window" thrown in the test body.
[  FAILED  ] select_outputs.exact_unlock_block_tiny (0 ms)
```
Deterministic (3 of 3 runs with `--gtest_filter` on sec1; `select_outputs.*` on v2.3.0:
`[  PASSED  ] 7 tests.`). The exception text is the line that sec.1 pick `7507aed69` ("wallet2:
guard gamma picker against zero-output windows", from Monero `release-v0.18`) adds to
`gamma_picker::gamma_picker`. The test comes from Monero commit `eb0e4052b` ("gamma picker: relax
constructor requirements and test for selecting outputs from first spendable block"), which is in
Zephyr's base (Monero master) and not on Monero's `release-v0.18`.

## Re-run on the rewritten branches (2026-11-05, later the same day)
sec.1 now carries Monero master `0b7967907` in place of release-v0.18 `7507aed69` (it adds the same
guard and corrects the master-only test `select_outputs.exact_unlock_block_tiny`); sec.2 was rebased
onto the new sec.1 tip. The sec1 and sec2 trees were moved to the new tips
(`git fetch -q origin && git checkout -q <tip> && git submodule update --init --recursive`),
reconfigured with the same cmake command (so that the version tag follows the new commit), and built
with `make -j6 daemon simplewallet wallet_rpc_server unit_tests test_notifier`; the control tree is
unchanged. Binary sizes are the same as in the first run.

| tree | HEAD | `--version` (all three binaries) | unit tests |
|---|---|---|---|
| sec1 | `54aa43b128149488523c79fbb3f7cfab6f4431c2` | `Zephyr 'Version 2.3' (v2.3.0-54aa43b12)` | 1006 tests., 0 failed |
| sec2 | `16018bb0bdbcfb49283b539485426e8c55ccf64d` | `Zephyr 'Version 2.3' (v2.3.0-16018bb0b)` | 1006 tests., 0 failed |

sec1, verbatim:
```
[  PASSED  ] 1006 tests.
[==========] 1006 tests from 138 test cases ran. (51325 ms total)
[==========] Running 1006 tests from 138 test cases.
[       OK ] notify.works (104 ms)
[       OK ] select_outputs.exact_unlock_block_tiny (0 ms)
```

sec2, verbatim:
```
[  PASSED  ] 1006 tests.
[==========] 1006 tests from 138 test cases ran. (41391 ms total)
[==========] Running 1006 tests from 138 test cases.
[       OK ] notify.works (103 ms)
[       OK ] select_outputs.exact_unlock_block_tiny (0 ms)
```

Both trees: 1006 passed, 0 failed; `select_outputs.exact_unlock_block_tiny` and `notify.works` pass.
