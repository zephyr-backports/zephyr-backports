# Console-output sanitising check, 2026-11-07

SB-019 (`52b33f4fb`, "common: sanitize message writer console output"), SB-017 (`c86fd739d`, "wallet2:
filter unchecked RPC error statuses") and SB-018 (`144b3f9e6`, "wallet2: sanitize untrusted daemon
status in sweep unmixable"). The test: a fake daemon returns a `status` field with terminal escape codes
and a newline, and the CLI wallets of upstream v2.3.0 (control) and of `wip/sec.2` (`16018bb0b`) run
against it, with the terminal output kept as bytes. The home directory is written as `~`. The seeds of the
throwaway wallets are redacted.

## Fake daemon
`~/tmp/zeph-r4/fake-daemon.py` (Python standard library, `ThreadingHTTPServer` on 127.0.0.1:28581, started with
`setsid nohup python3 -I fake-daemon.py`). `/get_info`, `/getheight`, `/get_height` and `/json_rpc`
(`get_info`, `get_version` with `version` 3.13, `get_block_count`) answer HTTP 200 with height 902000 and
```
"status": "OK\u001b[31m\u001b]0;INJECTED\u0007\nFAKE LINE"
```
(ESC `[31m` red, ESC `]0;INJECTED` BEL a window-title sequence, then a newline and an injected line).
`/getblocks.bin` answers HTTP 500, and anything else 404. Every request is logged.

## Runs
Both under `script` so that the terminal output is kept as bytes, one after the other, each with
`printf 'N\nrefresh\nexit\n'` on stdin and `timeout 180`. As in `serving-upstream-wallets.md`, with
`--trusted-daemon` a new wallet first asks whether to set up background mining, and `N` answers that.
```
$ printf 'N\nrefresh\nexit\n' | timeout 180 script -q -c "~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28581 --trusted-daemon --generate-new-wallet ~/tmp/zeph-r4/wallets/fake-control --password '' --mnemonic-language English" ~/tmp/zeph-r4/console-control.typescript
$ printf 'N\nrefresh\nexit\n' | timeout 180 script -q -c "~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28581 --trusted-daemon --generate-new-wallet ~/tmp/zeph-r4/wallets/fake-sec2 --password '' --mnemonic-language English" ~/tmp/zeph-r4/console-sec2.typescript
```
control 2026-11-07T00:56:34Z to 00:59:36Z, sec2 00:59:36Z to 01:02:38Z. Both ended at the 180 s timeout.

### `cat -v ~/tmp/zeph-r4/console-control.typescript`
```
Script started on 2026-11-07 00:56:34+00:00 [COMMAND="~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28581 --trusted-daemon --generate-new-wallet ~/tmp/zeph-r4/wallets/fake-control --password '' --mnemonic-language English" <not executed on terminal>]
N^M
refresh^M
exit^M
This is the command line zephyr wallet. It needs to connect to a zephyr^M
daemon to work correctly.^M
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.^M
^M
Zephyr 'Version 2.3' (v2.3.0-release)^M
Logging to ~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli.log^M
^[[1;37mGenerated new wallet: ZEPHYR3QCyDT4bQVybXyVXQvNQfYpVSmtH9LsMobsuQ7Tzb91txx9ZVe2mZh7Jc5qTPbrgVdbLZEQi9yFotDPPcCeWTAih8byjA3i^[[0m^M
View key: 545499c3b8553f1eac3c947c71815eb48193a706bca120036e292d2f54dace08^M
**********************************************************************^M
Your wallet has been generated!^M
To start synchronizing with the daemon, use the "refresh" command.^M
Use the "help" command to see a simplified list of available commands.^M
Use "help all" command to see the list of all available commands.^M
Use "help <command>" to see a command's documentation.^M
Always use the "exit" command when closing zephyr-wallet-cli to save ^M
your current session's state. Otherwise, you might need to synchronize ^M
your wallet again (your wallet keys are NOT at risk in any case).^M
^M
Filename: "~/tmp/zeph-r4/wallets/fake-control.keys"^M
^[[0;32m^M
NOTE: the following 25 words can be used to recover access to your wallet. Write them down and store them somewhere safe and secure. Please do not store them in your email or on file storage services outside of your immediate control.^M
<25-word seed redacted>
<25-word seed redacted>
<25-word seed redacted>
<25-word seed redacted>
**********************************************************************^M
The daemon is not set up to background mine.^M
With background mining enabled, the daemon will mine when idle and not on battery.^M
Enabling this supports the network you are using, and makes you eligible for receiving new zephyr^M
Do you want to do it now? (Y/Yes/N/No): : ^[[0;31mBackground mining not enabled. Set setup-background-mining to 1 to change.^[[0m^M
^[[1;33mIf you are new to Zephyr, type "welcome" for a brief overview.^[[0m^M
^[[1;31mError: wallet failed to connect to daemon: 127.0.0.1:28581. Daemon either is not started or wrong port was passed. Please make sure daemon is running or change the daemon address using the 'set_daemon' command.^[[0m^M
^[[0;32mBackground refresh thread started^[[0m^M
^[[1;33m[wallet ZEPHYR3QC (no daemon)]: ^[[0m
Script done on 2026-11-07 00:59:36+00:00 [COMMAND_EXIT_CODE="0"]
```

### `cat -v ~/tmp/zeph-r4/console-sec2.typescript`
```
Script started on 2026-11-07 00:59:36+00:00 [COMMAND="~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28581 --trusted-daemon --generate-new-wallet ~/tmp/zeph-r4/wallets/fake-sec2 --password '' --mnemonic-language English" <not executed on terminal>]
N^M
refresh^M
exit^M
This is the command line zephyr wallet. It needs to connect to a zephyr^M
daemon to work correctly.^M
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.^M
^M
Zephyr 'Version 2.3' (v2.3.0-16018bb0b)^M
Logging to ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli.log^M
^[[1;37mGenerated new wallet: ZEPHYR2kpgw8c75ZGcZrtpFwow3MvwFtEcvRSyfy9zoZbkG4AEZ9Skq44DTM7rWqaG4zjSbkb77o7DuwsqBPg7fS6zmvXgdHmW32X^[[0m^M
View key: ad056a7e543186e866c24ed6def289b8725c67d7885f3f29aeeb940a15c10202^M
**********************************************************************^M
Your wallet has been generated!^M
To start synchronizing with the daemon, use the "refresh" command.^M
Use the "help" command to see a simplified list of available commands.^M
Use "help all" command to see the list of all available commands.^M
Use "help <command>" to see a command's documentation.^M
Always use the "exit" command when closing zephyr-wallet-cli to save ^M
your current session's state. Otherwise, you might need to synchronize ^M
your wallet again (your wallet keys are NOT at risk in any case).^M
^M
Filename: "~/tmp/zeph-r4/wallets/fake-sec2.keys"^M
^[[0;32m^M
NOTE: the following 25 words can be used to recover access to your wallet. Write them down and store them somewhere safe and secure. Please do not store them in your email or on file storage services outside of your immediate control.^M
<25-word seed redacted>
<25-word seed redacted>
<25-word seed redacted>
<25-word seed redacted>
**********************************************************************^M
The daemon is not set up to background mine.^M
With background mining enabled, the daemon will mine when idle and not on battery.^M
Enabling this supports the network you are using, and makes you eligible for receiving new zephyr^M
Do you want to do it now? (Y/Yes/N/No): : ^[[0;31mBackground mining not enabled. Set setup-background-mining to 1 to change.^[[0m^M
^[[1;33mIf you are new to Zephyr, type "welcome" for a brief overview.^[[0m^M
^[[1;31mError: wallet failed to connect to daemon: 127.0.0.1:28581. Daemon either is not started or wrong port was passed. Please make sure daemon is running or change the daemon address using the 'set_daemon' command.^[[0m^M
^[[0;32mBackground refresh thread started^[[0m^M
^[[1;33m[wallet ZEPHYR2kp (no daemon)]: ^[[0m
Script done on 2026-11-07 01:02:38+00:00 [COMMAND_EXIT_CODE="0"]
```

### Requests seen by the fake daemon
```
2026-11-07T00:56:35Z code 400, message Bad request version ('\x00\x04\x03\x00\x01\x02\x00')
2026-11-07T00:56:35Z "?????????????D???????E6??k????t2A^??>?????*????|??>??o`??3?? ???@(??????5????o???????L????h???],??????:WD??W??????????????,??+??????0??/???}??????????????	127.0.0.1?????????" 400 -
  json_rpc method get_info
2026-11-07T00:56:36Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_info
2026-11-07T00:56:36Z "POST /json_rpc HTTP/1.1" 200 -
2026-11-07T00:56:37Z "POST /mining_status HTTP/1.1" 404 -
  json_rpc method get_version
2026-11-07T00:56:37Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T00:56:37Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T00:56:37Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T00:56:37Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T00:57:58Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T00:59:32Z "POST /json_rpc HTTP/1.1" 200 -
2026-11-07T00:59:40Z code 400, message Bad request syntax ('\x16\x03\x01\x05??\x01\x00\x05??\x03\x03')
2026-11-07T00:59:40Z "?????????????" 400 -
  json_rpc method get_info
2026-11-07T00:59:40Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_info
2026-11-07T00:59:40Z "POST /json_rpc HTTP/1.1" 200 -
2026-11-07T00:59:42Z "POST /mining_status HTTP/1.1" 404 -
  json_rpc method get_version
2026-11-07T00:59:43Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T00:59:43Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T00:59:43Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T00:59:43Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_version
2026-11-07T01:01:19Z "POST /json_rpc HTTP/1.1" 200 -
```
The binary `400` lines are each wallet's TLS handshake attempt (the wallet tries SSL first on a daemon
address, `--daemon-ssl` defaults to autodetect). After that it sends `get_info`, `mining_status`, and
`get_version` four times right away and twice more later. `/getblocks.bin` and `/getheight` were never called.

## Result: **not shown, pending (R12-4)**
Neither typescript carries the status text. `grep -c INJECTED` gives 0 in both typescripts and in both
wallets' default logs (`zephyr-wallet-cli.log` next to each binary). In both versions the wallet takes the non-`OK` status of `get_version` as a failed
connection and prints only
`Error: wallet failed to connect to daemon: 127.0.0.1:28581. Daemon either is not started or wrong port was passed. …`
(identical in both). It shows the prompt `[wallet … (no daemon)]`, never reaches a `refresh` that would call `/getblocks.bin`,
and does not act on the `refresh` and `exit` lines from stdin. The control and sec2 behave identically.
So this test does not reach the code that SB-017 to SB-019 change, and the
expected difference (raw escape sequence in the control, escaped or stripped in sec2) is not shown.
The fake daemon was stopped at 2026-11-07T01:02:56Z, and port 28581 is free.

## Second design (2026-11-07T01:36Z)
`~/tmp/zeph-r4/fake-daemon2.py` (standard library, 127.0.0.1:28581). `get_version` (json_rpc) gives
`{"version": 196621, "release": true, "status": "OK", "untrusted": false}`. `get_info` (json_rpc and `/get_info`)
gives the first design's body with `"status": "OK"`. `/getheight` and `/get_height` give
`{"height": 902000, "status": <INJECTED>, "untrusted": false}`, and `/get_public_nodes` gives
`{"white": [], "gray": [], "status": <INJECTED>, "untrusted": false}`, with the same `<INJECTED>` as above.
Anything else gets HTTP 404. Both CLI wallets ran **without** `--trusted-daemon`, on the wallets created in the first design:
```
$ printf 'bc_height\npublic_nodes\nexit\n' | timeout 120 script -q -c "~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28581 --wallet-file ~/tmp/zeph-r4/wallets/fake-control --password ''" ~/tmp/zeph-r4/console2-control.typescript
$ printf 'bc_height\npublic_nodes\nexit\n' | timeout 120 script -q -c "~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28581 --wallet-file ~/tmp/zeph-r4/wallets/fake-sec2 --password ''" ~/tmp/zeph-r4/console2-sec2.typescript
```
control 01:36:51Z to 01:37:00Z, sec2 01:37:00Z to 01:37:07Z. Both ran all three commands and exited with exit code 0.

### `cat -v ~/tmp/zeph-r4/console2-control.typescript`
```
Script started on 2026-11-07 01:36:51+00:00 [COMMAND="~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28581 --wallet-file ~/tmp/zeph-r4/wallets/fake-control --password ''" <not executed on terminal>]
bc_height^M
public_nodes^M
exit^M
This is the command line zephyr wallet. It needs to connect to a zephyr^M
daemon to work correctly.^M
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.^M
^M
Zephyr 'Version 2.3' (v2.3.0-release)^M
Logging to ~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli.log^M
^[[1;37mOpened wallet: ZEPHYR3QCyDT4bQVybXyVXQvNQfYpVSmtH9LsMobsuQ7Tzb91txx9ZVe2mZh7Jc5qTPbrgVdbLZEQi9yFotDPPcCeWTAih8byjA3i^[[0m^M
**********************************************************************^M
Use the "help" command to see a simplified list of available commands.^M
Use "help all" to see the list of all available commands.^M
Use "help <command>" to see a command's documentation.^M
**********************************************************************^M
^[[0;31mBackground mining not enabled. Run "set setup-background-mining 1" to change.^[[0m^M
Starting refresh...^M
^[[1;31mError: refresh failed: no connection to daemon. Please make sure daemon is running.. Blocks received: 0^[[0m^M
^[[0;32mBackground refresh thread started^[[0m^M
^[[1;33m[wallet ZEPHYR3QC (out of sync)]: ^[[0mbc_height^M
^[[1;33m[wallet ZEPHYR3QC (out of sync)]: ^[[0m^M^[[K902000^M
                                                 ^M^[[15P^[[1;33m[wallet ZEPHYR3QC (out of sync)]: ^[[0mpublic_nodes^M
^[[1;33m[wallet ZEPHYR3QC (out of sync)]: ^[[0m^M^[[K^[[1;31mError: Error retrieving public node list: error in /get_public_nodes RPC: OK^[[31m^[]0;INJECTED^G^M
FAKE LINE^[[0m^M
^[[1;31mMost of these nodes are probably spies. You should not use them unless connecting via Tor or I2P^[[0m^M
                                                 ^M^[[15P^[[1;33m[wallet ZEPHYR3QC (out of sync)]: ^[[0mexit^M

Script done on 2026-11-07 01:37:00+00:00 [COMMAND_EXIT_CODE="0"]
```

### `cat -v ~/tmp/zeph-r4/console2-sec2.typescript`
```
Script started on 2026-11-07 01:37:00+00:00 [COMMAND="~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28581 --wallet-file ~/tmp/zeph-r4/wallets/fake-sec2 --password ''" <not executed on terminal>]
bc_height^M
public_nodes^M
exit^M
This is the command line zephyr wallet. It needs to connect to a zephyr^M
daemon to work correctly.^M
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.^M
^M
Zephyr 'Version 2.3' (v2.3.0-16018bb0b)^M
Logging to ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli.log^M
^[[1;37mOpened wallet: ZEPHYR2kpgw8c75ZGcZrtpFwow3MvwFtEcvRSyfy9zoZbkG4AEZ9Skq44DTM7rWqaG4zjSbkb77o7DuwsqBPg7fS6zmvXgdHmW32X^[[0m^M
**********************************************************************^M
Use the "help" command to see a simplified list of available commands.^M
Use "help all" to see the list of all available commands.^M
Use "help <command>" to see a command's documentation.^M
**********************************************************************^M
^[[0;31mBackground mining not enabled. Run "set setup-background-mining 1" to change.^[[0m^M
Starting refresh...^M
^[[1;31mError: refresh failed: no connection to daemon. Please make sure daemon is running.. Blocks received: 0^[[0m^M
^[[0;32mBackground refresh thread started^[[0m^M
^[[1;33m[wallet ZEPHYR2kp (out of sync)]: ^[[0mbc_height^M
^[[1;33m[wallet ZEPHYR2kp (out of sync)]: ^[[0m^M^[[K902000^M
                                                 ^M^[[15P^[[1;33m[wallet ZEPHYR2kp (out of sync)]: ^[[0mpublic_nodes^M
^[[1;33m[wallet ZEPHYR2kp (out of sync)]: ^[[0m^M^[[K^[[1;31mError: Error retrieving public node list: error in /get_public_nodes RPC: OK?[31m?]0;INJECTED?^M
FAKE LINE^[[0m^M
^[[1;31mMost of these nodes are probably spies. You should not use them unless connecting via Tor or I2P^[[0m^M
                                                 ^M^[[15P^[[1;33m[wallet ZEPHYR2kp (out of sync)]: ^[[0mexit^M

Script done on 2026-11-07 01:37:07+00:00 [COMMAND_EXIT_CODE="0"]
```
The `public_nodes` error line as bytes (`grep -a -o 'RPC: OK.*' <typescript> | od -c`):
```
control:
0000000   R   P   C   :       O   K 033   [   3   1   m 033   ]   0   ;
0000020   I   N   J   E   C   T   E   D  \a  \r  \n
0000033
sec2:
0000000   R   P   C   :       O   K   ?   [   3   1   m   ?   ]   0   ;
0000020   I   N   J   E   C   T   E   D   ?  \r  \n
0000033
```
Requests seen by the fake daemon (non-printable bytes of the TLS probe shown as `?`, cut at 60 characters):
```
2026-11-07T01:36:59Z code 400, message Bad request version (
2026-11-07T01:36:59Z "?????????????yO????+??e??????)%???????
  json_rpc method get_version
2026-11-07T01:36:59Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_info
2026-11-07T01:36:59Z "POST /json_rpc HTTP/1.1" 200 -
2026-11-07T01:36:59Z "POST /gethashes.bin HTTP/1.1" 404 -
2026-11-07T01:37:00Z "POST /gethashes.bin HTTP/1.1" 404 -
2026-11-07T01:37:00Z "POST /get_public_nodes HTTP/1.1" 200 -
2026-11-07T01:37:06Z code 400, message Bad request version (
2026-11-07T01:37:06Z "???????????????Z??????????Z??????1??G?
  json_rpc method get_version
2026-11-07T01:37:06Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_info
2026-11-07T01:37:06Z "POST /json_rpc HTTP/1.1" 200 -
2026-11-07T01:37:06Z "POST /gethashes.bin HTTP/1.1" 404 -
2026-11-07T01:37:06Z "POST /get_public_nodes HTTP/1.1" 200 -
2026-11-07T01:37:06Z "POST /gethashes.bin HTTP/1.1" 404 -
```

### Result
| | control v2.3.0 | sec2 `16018bb0b` |
|---|---|---|
| `public_nodes` error line | `Error retrieving public node list: error in /get_public_nodes RPC: OK^[[31m^[]0;INJECTED^G`, then `FAKE LINE` on its own line: raw ESC (033) and BEL (`\a`) reach the terminal | `… RPC: OK?[31m?]0;INJECTED?`, then `FAKE LINE` on its own line: ESC and BEL replaced by `?`, newline kept |
| `bc_height` | `902000` | `902000` |

- **SB-019 shown:** the message writer of sec2 replaces the control characters of the daemon's status with `?` before they reach the
  terminal. The control passes them raw, so the injected `ESC [31m` (red) and the window-title sequence `ESC ]0;INJECTED BEL` take
  effect there. That newline, tab and carriage return are kept is the sanitiser's design (`el::base::sanitize`,
  `external/easylogging++/easylogging++.cc:2579` in sec2: `if (c == 9 || c == 10 || c == 13) return c;`, other C0, 0x7f and C1
  become `?`), so `FAKE LINE` still starts a new line in sec2.
- **SB-017 not exercised:** sec2 still prints the daemon's status text. `wallet2::get_rpc_status` returns it unchanged
  when the daemon is trusted (`src/wallet/wallet2.cpp:15025`), and the wallet treats a daemon at a local
  address as trusted without `--trusted-daemon` (`wallet2.cpp:453`, `Daemon is local, assuming trusted`; neither
  typescript has the untrusted-daemon warning). So the filter for untrusted daemons is never reached with a fake daemon on
  127.0.0.1. Pending (R13-1).
- **`bc_height` path not reached:** both print the height. `get_daemon_blockchain_height` uses
  `NodeRPCProxy::get_height`, which takes the height from the json_rpc `get_info` (cached 30 s;
  `src/wallet/node_rpc_proxy.cpp:153`), not from `/getheight`. The fake daemon logged no `/getheight` request.
  The `failed to get blockchain height` line therefore never appears. Pending (R13-1).
- SB-018 (sweep unmixable): same filter as SB-017, not exercised.

The fake daemon was stopped at 2026-11-07T01:37:59Z, and port 28581 is free.

## Third run: untrusted daemon (2026-11-07T01:55Z)
The second design's fake daemon again (`fake-daemon2.py`, unchanged, sha256 `d112778deaff94e5…`, 127.0.0.1:28581, log
`fake-daemon3.log`). Both CLI wallets ran with `--untrusted-daemon` added, so that the local fake daemon is not taken
as trusted:
```
$ printf 'public_nodes\nexit\n' | timeout 120 script -q -c "~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli --untrusted-daemon --daemon-address 127.0.0.1:28581 --wallet-file ~/tmp/zeph-r4/wallets/fake-control --password ''" ~/tmp/zeph-r4/console3-control.typescript
$ printf 'public_nodes\nexit\n' | timeout 120 script -q -c "~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli --untrusted-daemon --daemon-address 127.0.0.1:28581 --wallet-file ~/tmp/zeph-r4/wallets/fake-sec2 --password ''" ~/tmp/zeph-r4/console3-sec2.typescript
```
control 01:55:51Z to 01:55:53Z, sec2 01:55:53Z to 01:55:57Z, both exit 0.

### `cat -v ~/tmp/zeph-r4/console3-control.typescript`
```
Script started on 2026-11-07 01:55:51+00:00 [COMMAND="~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli --untrusted-daemon --daemon-address 127.0.0.1:28581 --wallet-file ~/tmp/zeph-r4/wallets/fake-control --password ''" <not executed on terminal>]
public_nodes^M
exit^M
This is the command line zephyr wallet. It needs to connect to a zephyr^M
daemon to work correctly.^M
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.^M
^M
Zephyr 'Version 2.3' (v2.3.0-release)^M
Logging to ~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli.log^M
^[[1;37mOpened wallet: ZEPHYR3QCyDT4bQVybXyVXQvNQfYpVSmtH9LsMobsuQ7Tzb91txx9ZVe2mZh7Jc5qTPbrgVdbLZEQi9yFotDPPcCeWTAih8byjA3i^[[0m^M
**********************************************************************^M
Use the "help" command to see a simplified list of available commands.^M
Use "help all" to see the list of all available commands.^M
Use "help <command>" to see a command's documentation.^M
**********************************************************************^M
^[[1;31mWarning: using an untrusted daemon at 127.0.0.1:28581^[[0m^M
^[[1;31mUsing a third party daemon can be detrimental to your security and privacy^[[0m^M
^[[1;31mUsing your own without SSL exposes your RPC traffic to monitoring^[[0m^M
^[[1;31mYou are strongly encouraged to connect to the Zephyr network using your own daemon^[[0m^M
^[[1;31mIf you or someone you trust are operating this daemon, you can use --trusted-daemon^[[0m^M
^[[0;31mBackground mining not enabled. Run "set setup-background-mining 1" to change.^[[0m^M
Starting refresh...^M
^[[1;31mError: refresh failed: no connection to daemon. Please make sure daemon is running.. Blocks received: 0^[[0m^M
^[[0;32mBackground refresh thread started^[[0m^M
^[[1;33m[wallet ZEPHYR3QC (out of sync)]: ^[[0mpublic_nodes^M
^[[1;33m[wallet ZEPHYR3QC (out of sync)]: ^[[0m^M^[[K^[[1;31mError: Error retrieving public node list: error in /get_public_nodes RPC: OK^[[31m^[]0;INJECTED^G^M
FAKE LINE^[[0m^M
^[[1;31mMost of these nodes are probably spies. You should not use them unless connecting via Tor or I2P^[[0m^M
                                                 ^M^[[15P^[[1;33m[wallet ZEPHYR3QC (out of sync)]: ^[[0mexit^M

Script done on 2026-11-07 01:55:53+00:00 [COMMAND_EXIT_CODE="0"]
```

### `cat -v ~/tmp/zeph-r4/console3-sec2.typescript`
```
Script started on 2026-11-07 01:55:53+00:00 [COMMAND="~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli --untrusted-daemon --daemon-address 127.0.0.1:28581 --wallet-file ~/tmp/zeph-r4/wallets/fake-sec2 --password ''" <not executed on terminal>]
public_nodes^M
exit^M
This is the command line zephyr wallet. It needs to connect to a zephyr^M
daemon to work correctly.^M
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.^M
^M
Zephyr 'Version 2.3' (v2.3.0-16018bb0b)^M
Logging to ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli.log^M
^[[1;37mOpened wallet: ZEPHYR2kpgw8c75ZGcZrtpFwow3MvwFtEcvRSyfy9zoZbkG4AEZ9Skq44DTM7rWqaG4zjSbkb77o7DuwsqBPg7fS6zmvXgdHmW32X^[[0m^M
**********************************************************************^M
Use the "help" command to see a simplified list of available commands.^M
Use "help all" to see the list of all available commands.^M
Use "help <command>" to see a command's documentation.^M
**********************************************************************^M
^[[1;31mWarning: using an untrusted daemon at 127.0.0.1:28581^[[0m^M
^[[1;31mUsing a third party daemon can be detrimental to your security and privacy^[[0m^M
^[[1;31mUsing your own without SSL exposes your RPC traffic to monitoring^[[0m^M
^[[1;31mYou are strongly encouraged to connect to the Zephyr network using your own daemon^[[0m^M
^[[1;31mIf you or someone you trust are operating this daemon, you can use --trusted-daemon^[[0m^M
^[[0;31mBackground mining not enabled. Run "set setup-background-mining 1" to change.^[[0m^M
Starting refresh...^M
^[[1;31mError: refresh failed: no connection to daemon. Please make sure daemon is running.. Blocks received: 0^[[0m^M
^[[0;32mBackground refresh thread started^[[0m^M
^[[1;33m[wallet ZEPHYR2kp (out of sync)]: ^[[0mpublic_nodes^M
^[[1;33m[wallet ZEPHYR2kp (out of sync)]: ^[[0m^M^[[K^[[1;31mError: Error retrieving public node list: error in /get_public_nodes RPC: <error>^[[0m^M
^[[1;31mMost of these nodes are probably spies. You should not use them unless connecting via Tor or I2P^[[0m^M
                                                 ^M^[[15P^[[1;33m[wallet ZEPHYR2kp (out of sync)]: ^[[0mexit^M

Script done on 2026-11-07 01:55:57+00:00 [COMMAND_EXIT_CODE="0"]
```
The error line as bytes (`grep -a -o 'RPC: .*' <typescript> | od -c`):
```
control:
0000000   R   P   C   :       O   K 033   [   3   1   m 033   ]   0   ;
0000020   I   N   J   E   C   T   E   D  \a  \r  \n
0000033
sec2:
0000000   R   P   C   :       <   e   r   r   o   r   > 033   [   0   m
0000020  \r  \n
0000022
```
Requests seen by the fake daemon (non-printable bytes of the TLS probe shown as `?`, cut at 60 characters):
```
2026-11-07T01:55:52Z code 400, message Bad request version (
2026-11-07T01:55:52Z "?????????????r?????????????[??j???????
  json_rpc method get_version
2026-11-07T01:55:53Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_info
2026-11-07T01:55:53Z "POST /json_rpc HTTP/1.1" 200 -
2026-11-07T01:55:53Z "POST /get_info HTTP/1.1" 200 -
2026-11-07T01:55:53Z "POST /gethashes.bin HTTP/1.1" 404 -
2026-11-07T01:55:53Z "POST /gethashes.bin HTTP/1.1" 404 -
2026-11-07T01:55:53Z "POST /get_public_nodes HTTP/1.1" 200 -
2026-11-07T01:55:57Z code 400, message Bad request version (
2026-11-07T01:55:57Z "???????????????????????,4J????????????
  json_rpc method get_version
2026-11-07T01:55:57Z "POST /json_rpc HTTP/1.1" 200 -
  json_rpc method get_info
2026-11-07T01:55:57Z "POST /json_rpc HTTP/1.1" 200 -
2026-11-07T01:55:57Z "POST /get_info HTTP/1.1" 200 -
2026-11-07T01:55:57Z "POST /gethashes.bin HTTP/1.1" 404 -
2026-11-07T01:55:57Z "POST /gethashes.bin HTTP/1.1" 404 -
2026-11-07T01:55:57Z "POST /get_public_nodes HTTP/1.1" 200 -
```

### Result: **SB-017 shown**
Both wallets now print `Warning: using an untrusted daemon at 127.0.0.1:28581`. On `public_nodes` the control
prints the daemon's status raw: `error in /get_public_nodes RPC: OK`, then ESC `[31m` ESC `]0;INJECTED` BEL, then
`FAKE LINE` on a new line. sec2 prints `error in /get_public_nodes RPC: <error>`, with no daemon text at all
(`grep -c INJECTED console3-sec2.typescript` gives 0). In v2.3.0 the `/get_public_nodes` call reports its status with
`THROW_ON_RPC_RESPONSE_ERROR_GENERIC`, which passes the status raw. `c86fd739d` routes it, and four other calls, through
`wallet2::get_rpc_status` (`src/wallet/wallet2.cpp:15023` in sec2, the same function in both trees), which returns
`<error>` for any status of an untrusted daemon other than `OK`, `BUSY` or `PAYMENT REQUIRED`. SB-018 (sweep unmixable) uses the same filter and
was not exercised. The fake daemon was stopped at 01:56:05Z, and port 28581 is free.
