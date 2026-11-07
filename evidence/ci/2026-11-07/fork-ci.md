# Fork CI results, read 2026-11-07

Read with `gh` (`gh run list`, `gh api .../actions/runs/<id>/jobs`, `gh api .../actions/jobs/<id>/logs`)
on 2026-11-07 between 00:30Z and 00:33Z. The fork workflows `provenance` and `tests` call the reusable
workflows of the home repo (`zephyr-backports/zephyr-backports/.github/workflows/{provenance,tests}.yml@main`);
the commit of the home repo each job used is in the column "home". All jobs ran on GitHub's
`ubuntu-22.04` runner (image version 20261028.624 for the tests jobs).

## zephyr

| run | workflow | event | head | job | conclusion | start (UTC) | end (UTC) | home |
|---|---|---|---|---|---|---|---|---|
| [42197802268](https://github.com/zephyr-backports/zephyr/actions/runs/42197802268) | provenance | push `security/v2.3.0` | `e9cf10f79` | 127825328648 | success | 2026-11-06T09:48:28Z | 09:48:47Z | `f92c84a` |
| [42197802293](https://github.com/zephyr-backports/zephyr/actions/runs/42197802293) | tests | push `security/v2.3.0` | `e9cf10f79` | 127825329040 | success | 2026-11-06T09:48:29Z | 10:03:37Z | `f92c84a` |
| [42313222178](https://github.com/zephyr-backports/zephyr/actions/runs/42313222178) | provenance | push `pr/sec.2` | `1c1982aa7` | 128219475305 | success | 2026-11-06T23:38:16Z | 23:38:37Z | `1ed06b0` |
| [42313222174](https://github.com/zephyr-backports/zephyr/actions/runs/42313222174) | tests | push `pr/sec.2` | `1c1982aa7` | 128219475411 | success | 2026-11-06T23:38:16Z | 2026-11-07T00:13:44Z | `1ed06b0` |
| [42313227566](https://github.com/zephyr-backports/zephyr/actions/runs/42313227566) | provenance | pull request [#3](https://github.com/zephyr-backports/zephyr/pull/3) | `1c1982aa7` | 128219493197 | success | 2026-11-06T23:38:19Z | 23:38:39Z | `1ed06b0` |
| [42313227604](https://github.com/zephyr-backports/zephyr/actions/runs/42313227604) | tests | pull request [#3](https://github.com/zephyr-backports/zephyr/pull/3) | `1c1982aa7` | 128219492915 | success | 2026-11-06T23:38:18Z | 2026-11-07T00:13:36Z | `1ed06b0` |
| [42318365472](https://github.com/zephyr-backports/zephyr/actions/runs/42318365472) | provenance | push `security/v2.3.0` | `1c1982aa7` | 128236549919 | success | 2026-11-07T00:27:52Z | 00:28:08Z | `1ed06b0` |
| [42318365265](https://github.com/zephyr-backports/zephyr/actions/runs/42318365265) | tests | push `security/v2.3.0` | `1c1982aa7` | 128236549637 | success (in progress at 00:30Z, read again 01:05Z) | 2026-11-07T00:27:51Z | 00:39:57Z | `1ed06b0` |

Pull request #3 (`pr/sec.2` → `security/v2.3.0`, head `1c1982aa7`) shows as merged at
2026-11-07T00:27:47Z (the maintainer's fast-forward push); the last two rows are the runs of that push.

### Quoted lines, tests jobs
Job 127825329040 (`e9cf10f79`, home `f92c84a`: all unit tests in one run; the gamma test was split
off in the home repo's `tests.yml` afterwards):
```
2026-11-06T09:48:51.9846907Z HEAD is now at e9cf10f79 security: unit-test CI
2026-11-06T09:51:07.1721027Z -- The CXX compiler identification is GNU 11.4.0
2026-11-06T10:03:34.1888199Z [  PASSED  ] 1006 tests.
```
Job 128219475411 (push `pr/sec.2`, `1c1982aa7`, home `1ed06b0`: all tests except
`select_outputs.gamma`, then that test apart, up to three times):
```
2026-11-06T23:38:25.7419141Z HEAD is now at 1c1982aa7 security: draft advisories SB-015 to SB-034 for v2.3.0-sec.2
2026-11-07T00:03:46.3688903Z -- The CXX compiler identification is GNU 11.4.0
2026-11-07T00:13:40.6862989Z [  PASSED  ] 1005 tests.
2026-11-07T00:13:40.9609049Z [  PASSED  ] 1 test.
```
Job 128219492915 (pull request #3, `1c1982aa7`, home `1ed06b0`):
```
2026-11-06T23:38:29.0230324Z HEAD is now at 1c1982aa7 security: draft advisories SB-015 to SB-034 for v2.3.0-sec.2
2026-11-07T00:02:34.1684909Z -- The CXX compiler identification is GNU 11.4.0
2026-11-07T00:13:32.9321328Z [  PASSED  ] 1005 tests.
2026-11-07T00:13:33.2353527Z [  PASSED  ] 1 test.
```
Job 128236549637 (push `security/v2.3.0`, `1c1982aa7`, home `1ed06b0`; read again at 2026-11-07T01:05Z):
```
2026-11-07T00:28:01.0525877Z HEAD is now at 1c1982aa7 security: draft advisories SB-015 to SB-034 for v2.3.0-sec.2
2026-11-07T00:29:32.2328133Z -- The CXX compiler identification is GNU 11.4.0
2026-11-07T00:39:54.7684117Z [  PASSED  ] 1005 tests.
2026-11-07T00:39:55.0466177Z [  PASSED  ] 1 test.
```
Gamma retries: none. `grep -cE 'select_outputs.gamma failed \(attempt [0-9]'` gives 0 in all three
logs (the only matching text is the script itself echoed by the runner, with the literal `$i`); 0 in job 128236549637 as well.

### Quoted lines, provenance jobs
Every provenance job checks out the head and ends with `provenance OK`:
```
2026-11-06T09:48:36.9789209Z HEAD is now at e9cf10f79 security: unit-test CI
2026-11-06T09:48:45.0268576Z provenance OK
2026-11-06T23:38:26.1205764Z HEAD is now at 1c1982aa7 security: draft advisories SB-015 to SB-034 for v2.3.0-sec.2
2026-11-06T23:38:34.5940809Z provenance OK
2026-11-06T23:38:28.2535925Z HEAD is now at 1c1982aa7 security: draft advisories SB-015 to SB-034 for v2.3.0-sec.2
2026-11-06T23:38:36.6778083Z provenance OK
2026-11-07T00:27:59.3749240Z HEAD is now at 1c1982aa7 security: draft advisories SB-015 to SB-034 for v2.3.0-sec.2
2026-11-07T00:28:05.7174130Z provenance OK
```
(in table order: 42197802268, 42313222178, 42313227566, 42318365472).

## zephyr-cpp

| run | workflow | event | head | job | conclusion | start (UTC) | end (UTC) | home |
|---|---|---|---|---|---|---|---|---|
| [42090724866](https://github.com/zephyr-backports/zephyr-cpp/actions/runs/42090724866) | provenance | push `security/v2.3.0` | `56abaf948` | 127467719841 | success | 2026-11-05T19:06:44Z | 19:06:53Z | `694e426` |

```
2026-11-05T19:06:47.5712996Z HEAD is now at 56abaf9 security: advisories SB-011 to SB-014 for v2.3.0-sec.1
2026-11-05T19:06:50.6459871Z provenance OK
```
zephyr-cpp has no other workflow (`gh api repos/zephyr-backports/zephyr-cpp/actions/workflows`:
`provenance` only).

## Upstream's own workflows are disabled in the zephyr fork
`gh api repos/zephyr-backports/zephyr/actions/workflows`:
```
408508021	ci/gh-actions/cli	.github/workflows/build.yml	disabled_manually	2026-11-06T09:43:01.000Z
408508022	ci/gh-actions/depends	.github/workflows/depends.yml	disabled_manually	2026-11-06T09:43:02.000Z
408508033	provenance	.github/workflows/provenance.yml	active	2026-11-05T18:40:49.000Z
409162178	tests	.github/workflows/tests.yml	active	2026-11-06T09:43:54.000Z
```
Upstream's `build.yml` and `depends.yml` are disabled as a repository setting, and the tree is
unchanged. Their last runs, on `714ef9cd9` (runs 42090187958 and 42090187971, push of 2026-11-05T19:03Z), could not
complete. Every job on `ubuntu-20.04`, a runner image GitHub has retired, stayed queued until it was
cancelled after 24 hours (for example `build-ubuntu (ubuntu-20.04)`, job 127465888763, cancelled
2026-11-06T19:03:29Z), and so did the whole `depends` matrix. `build-windows` failed because MSYS2 no longer has two package
names (job 127465888830):
```
2026-11-05T19:04:31.7333745Z Enter a selection (default=all): error: target not found: mingw-w64-x86_64-hidapi
2026-11-05T19:04:31.7344881Z error: target not found: mingw-w64-x86_64-libusb
```
`build-ubuntu (ubuntu-22.04)` of the same run passed. Upstream's own `test-ubuntu` job is commented
out in its `build.yml`. The unit tests therefore run in the fork's own `tests` workflow above.
