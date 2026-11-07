# The fork node serving upstream wallets, 2026-11-07

POLICY §6.4, second part: the fork `zephyrd` serves wallets built from upstream v2.3.0, and a fork
wallet works against an upstream node. The fork daemon is the native `wip/sec.2` build from
`../2026-11-05/unit-tests.md` (`v2.3.0-16018bb0b`; the published sec.2 tip `1c1982aa7` differs from
`16018bb0b` only in `SECURITY-BACKPORTS.md` and `.github/workflows/tests.yml`). It ran on the data
directory synced in `../2026-11-05/sync-from-local-node.md`. The upstream node is the owner's synced
v2.3.0 node `10.1.0.128` (restricted RPC). The home directory is written as `~`. Colour and cursor
codes are removed from console output. The 25-word seeds of the throwaway test wallets are redacted.

## 1. Fork daemon on the synced data directory
```
$ date -u +%FT%TZ
2026-11-07T00:34:32Z
$ ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd --data-dir ~/tmp/zeph-r4/data-sync-sec2 --add-exclusive-node 10.1.0.128:17766 --no-igd --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28380 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28381 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28382 --out-peers 1 --in-peers 0 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-serve.pid --log-file ~/tmp/zeph-r4/zephyrd-serve.log
2026-11-07 00:34:32.695	I Zephyr 'Version 2.3' (v2.3.0-16018bb0b)
2026-11-07 00:34:32.695	I Moving from main() into the daemonize now.
Forking to background...
$ ss -ltnp | grep -E ':2838[0-2]'
LISTEN 0      100                                 127.0.0.1:28382      0.0.0.0:*    users:(("zephyrd",pid=554973,fd=21))
LISTEN 0      4096                                127.0.0.1:28381      0.0.0.0:*    users:(("zephyrd",pid=554973,fd=14))
LISTEN 0      4096                                127.0.0.1:28380      0.0.0.0:*    users:(("zephyrd",pid=554973,fd=10))
```
`get_info` every 15 s on the fork (`height target_height synchronized outgoing_connections_count`)
and on the node (`height`). The first poll already shows it synchronized and at the node's height:
```
2026-11-07T00:34:39Z fork=[902049 0 True 1] node=902049
2026-11-07T00:36:56Z fork=[902050 0 True 1] node=902050
2026-11-07T00:41:43Z fork=[902056 0 True 1] node=902056
```
(every one of the 40 polls up to 00:44:29Z shows equal heights and `True`).

## 2. Upstream CLI wallet against the fork node: **not shown, pending (R12-1)**
```
$ cat ~/tmp/zeph-r4/wallet-up-on-fork.heights     # fork height at 2026-11-07T00:45:14Z, restore height = minus 200
902056 901856
$ ~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28381 --trusted-daemon --generate-new-wallet ~/tmp/zeph-r4/wallets/up-on-fork --password '' --mnemonic-language English --restore-height 901856 --log-file ~/tmp/zeph-r4/wallet-up-on-fork.log <<'EOF'
N
refresh
status
balance
show_transfers
bc_height
exit
EOF
```
With `--trusted-daemon`, a new wallet asks whether to set up background mining on the daemon
(`simple_wallet::check_background_mining`, `src/simplewallet/simplewallet.cpp:5606` of v2.3.0). The
first stdin line `N` answers that prompt, so that no command line is taken as the answer and mining
stays off. Output (exit code 0, 2026-11-07T00:45:14Z to 00:45:29Z):
```
This is the command line zephyr wallet. It needs to connect to a zephyr
daemon to work correctly.
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.
Zephyr 'Version 2.3' (v2.3.0-release)
Logging to ~/tmp/zeph-r4/wallet-up-on-fork.log
Generated new wallet: ZEPHYR33ZsRVkciV8GpewU671iYoEt8hgXY2psqy4PxJ9XJhAh7qVBsP7YYXioHWevXhoirveu9o6i48jzoScVE452T2MVuNRfA23
View key: 60326d936d15dd44dbdc6cee097c8eb56ba6800af26c72466e6ebd8973cf630a
**********************************************************************
Your wallet has been generated!
To start synchronizing with the daemon, use the "refresh" command.
Use the "help" command to see a simplified list of available commands.
Use "help all" command to see the list of all available commands.
Use "help <command>" to see a command's documentation.
Always use the "exit" command when closing zephyr-wallet-cli to save
your current session's state. Otherwise, you might need to synchronize
your wallet again (your wallet keys are NOT at risk in any case).
Filename: "~/tmp/zeph-r4/wallets/up-on-fork.keys"
NOTE: the following 25 words can be used to recover access to your wallet. Write them down and store them somewhere safe and secure. Please do not store them in your email or on file storage services outside of your immediate control.
<25-word seed redacted>
<25-word seed redacted>
<25-word seed redacted>
**********************************************************************
The daemon is not set up to background mine.
With background mining enabled, the daemon will mine when idle and not on battery.
Enabling this supports the network you are using, and makes you eligible for receiving new zephyr
Do you want to do it now? (Y/Yes/N/No): : Background mining not enabled. Set setup-background-mining to 1 to change.
If you are new to Zephyr, type "welcome" for a brief overview.
Starting refresh...
(91 progress lines "Height N / M", the last: Height 899733 / 902056)
Refresh done, blocks received: 0
Untagged accounts:
             Account               Balance      Unlocked balance           Asset                 Label
------------------------------------------------------------------------------------
Currently selected account: [0] Primary account
Tag: (No tag assigned)
Background refresh thread started
[wallet ZEPHYR33Z]:
```
The wallet refreshed on start against the fork node, with no error and no warning about the daemon
(the wallet log has only its log-level line). After answering the prompt, though, it ran **none of the
six commands** from stdin: it printed its prompt and ended with exit code 0. So the expected
`Height X/X`, balance 0 and `bc_height` were not shown. The same here-doc without the prompt works
(section 4). Not retried with other flags; question R12-1.

## 3. Upstream WASM wallet against the fork node
The harness `tools/wasm/test/core-test.cjs` copies the files of `--dist` into `<harness>/dist`
(lines 33 to 36) and then loads that copy. After earlier runs, `~/tmp/zeph-r3/cache/harness/dist` holds the last
build tested, not upstream's. A first run with `--dist ~/tmp/zeph-r3/cache/harness/dist` (00:46:02Z) therefore
loaded our sec2 build (`distSha` `fc630b04…`/`2ba10e6f…`); it does not count:
```
RESULT {"dist":"~/tmp/zeph-r3/cache/harness/dist","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"2ba10e6fc8bf1c06"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZu ...
```
Upstream's prebuilt dist was then taken unchanged from zephyr-javascript `9d022ded` into its own
read-only directory:
`git -C ~/tmp/zeph-r3/src/zephyr-javascript archive 9d022ded dist | tar -x -C ~/tmp/zeph-r3/upstream-dist-9d022ded --strip-components=1`,
giving `monero_wallet_keys.wasm` `a541c83c2efdeb39…` and `monero_wallet_full.wasm` `b4d7413ef80f3e59…`, as in
`../../wasm/2026-11-05/harness-results.md`'s first `upstream` line.
```
$ node --no-experimental-fetch tools/wasm/test/core-test.cjs --harness ~/tmp/zeph-r3/cache/harness --dist ~/tmp/zeph-r3/upstream-dist-9d022ded --node http://127.0.0.1:28381
### TEST upstream-on-fork-node START 2026-11-07T00:46:54Z
RESULT {"dist":"~/tmp/zeph-r3/upstream-dist-9d022ded","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902057,"fullAddressMatches":true,"isSynced":true,"walletHeight":902057,"syncSeconds":5.44,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1688,"cacheBytes":29276047,"reopenAddressMatches":true,"reopenHeight":902057,"wrongPassword":"invalid password"}
### TEST upstream-on-fork-node END 2026-11-07T00:47:08Z exit=0
```
**Shown:** upstream's WASM wallet synced to the fork node's height (`daemonHeight` = `walletHeight` =
902057, `isSynced` true). It also read the reserve info (`hfVersion` 11), showed balance 0 in every asset, and saved and
reopened the wallet.

## 4. Fork CLI wallet against the upstream node
```
$ cat ~/tmp/zeph-r4/wallet-fork-on-up.heights     # node height at 2026-11-07T00:47:18Z, restore height = minus 200
902058 901858
$ ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyr-wallet-cli --daemon-address 10.1.0.128:17767 --generate-new-wallet ~/tmp/zeph-r4/wallets/fork-on-up --password '' --mnemonic-language English --restore-height 901858 --log-file ~/tmp/zeph-r4/wallet-fork-on-up.log <<'EOF'
refresh
status
balance
show_transfers
bc_height
exit
EOF
This is the command line zephyr wallet. It needs to connect to a zephyr
daemon to work correctly.
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.
Zephyr 'Version 2.3' (v2.3.0-16018bb0b)
Logging to ~/tmp/zeph-r4/wallet-fork-on-up.log
Generated new wallet: ZEPHYR3NpR3RpSa9rpvEPr1tvoUMuTS1hD1Yys3L4zNtGaFkFjeaifGR2oKmKtG8RAX2Aoge5jCQm41JRkcua3qqHxqKmR5Hvx31n
View key: 9f0e939d9b3a6abf8231c1fe2fb8e1545b45ddebf4afd7b3bb7c5b48b4b56c06
**********************************************************************
Your wallet has been generated!
To start synchronizing with the daemon, use the "refresh" command.
Use the "help" command to see a simplified list of available commands.
Use "help all" command to see the list of all available commands.
Use "help <command>" to see a command's documentation.
Always use the "exit" command when closing zephyr-wallet-cli to save
your current session's state. Otherwise, you might need to synchronize
your wallet again (your wallet keys are NOT at risk in any case).
Filename: "~/tmp/zeph-r4/wallets/fork-on-up.keys"
NOTE: the following 25 words can be used to recover access to your wallet. Write them down and store them somewhere safe and secure. Please do not store them in your email or on file storage services outside of your immediate control.
<25-word seed redacted>
<25-word seed redacted>
<25-word seed redacted>
**********************************************************************
Warning: using an untrusted daemon at 10.1.0.128:17767
Using a third party daemon can be detrimental to your security and privacy
Using your own without SSL exposes your RPC traffic to monitoring
You are strongly encouraged to connect to the Zephyr network using your own daemon
If you or someone you trust are operating this daemon, you can use --trusted-daemon
Using an untrusted daemon, skipping background mining check
If you are new to Zephyr, type "welcome" for a brief overview.
Starting refresh...
(90 progress lines "Height N / M", the last: Height 899733 / 902058)
Refresh done, blocks received: 0
Untagged accounts:
             Account               Balance      Unlocked balance           Asset                 Label
------------------------------------------------------------------------------------
Currently selected account: [0] Primary account
Tag: (No tag assigned)
Background refresh thread started
[wallet ZEPHYR3Np]: refresh
[wallet ZEPHYR3Np]:
Starting refresh...
Refresh done, blocks received: 0
Currently selected account: [0] Primary account
Tag: (No tag assigned)
[wallet ZEPHYR3Np]: status
[wallet ZEPHYR3Np]:
Refreshed 902058/902058, synced, daemon RPC v3.13, no SSL
[wallet ZEPHYR3Np]: balance
[wallet ZEPHYR3Np]:
Currently selected account: [0] Primary account
Tag: (No tag assigned)
[wallet ZEPHYR3Np]: show_transfers
[wallet ZEPHYR3Np]:
[wallet ZEPHYR3Np]: bc_height
[wallet ZEPHYR3Np]:
902058
[wallet ZEPHYR3Np]: exit
```
**Shown:** exit code 0 (00:47:18Z to 00:47:34Z). Every command ran. `status` gives
`Refreshed 902058/902058, synced, daemon RPC v3.13, no SSL`, `bc_height` gives 902058, and `show_transfers` is empty.
`balance` prints the account line but no amount line (the same as the account table at startup,
which has a header and no row). The untrusted-daemon warning is the standard one for a restricted
node without `--trusted-daemon`.

## 5. Stop and the daemon's log
```
$ kill 554973                      # 2026-11-07T00:47:55Z
exited by 2026-11-07T00:47:58Z; last log line:
2026-11-07 00:47:56.852	[SRV_MAIN]	INFO	global	src/daemon/protocol.h:79	Cryptonote protocol stopped successfully
```
The fork daemon's `WARNING`/`ERROR` lines over the whole run, verbatim. There are no `ERROR` lines, and no
`rejected`, `Block with id`, `verification failed` or `Failed to add`:
```
2026-11-07 00:34:32.697	    75bee4b65ec0	WARNING	daemon	src/daemon/executor.cpp:61	Zephyr 'Version 2.3' (v2.3.0-16018bb0b) Daemonised
2026-11-07 00:34:32.698	    75bee4b65ec0	WARNING	global	src/blockchain_db/lmdb/db_lmdb.cpp:2173	The blockchain is on a rotating drive: this will be very slow, use an SSD if possible
2026-11-07 00:34:34.519	[P2P1]	WARNING	net.p2p.tx	src/cryptonote_protocol/levin_notify.cpp:454	Unable to send transaction(s), no available connections
2026-11-07 00:36:15.589	[P2P4]	WARNING	global	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2944	zephyrd is now disconnected from the network
```
The third line comes two seconds after the start, before the first connection. The fourth is the daemon's own peer rotation,
reconnected to the same node one second later:
```
2026-11-07 00:36:15.589	[P2P4]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1832	[10.1.0.128:17766 OUT] dropping synced peer, 0 syncing, 1 synced, 1 max out peers
2026-11-07 00:36:16.593	[P2P0]	INFO	net.p2p	src/p2p/net_node.inl:2663	[10.1.0.128:17766 c55ab627-6ad6-4369-9237-86d7d75bedef OUT] NEW CONNECTION
```
Before the stop: fork `get_info` height 902058, `synchronized` true, 1 outgoing, 0 incoming,
`rpc_connections_count` 1; node height 902058.

## 3.2, second attempt (2026-11-07T01:35Z)
The fork daemon was started again on the same data directory with the same flags as in section 1
(`--pidfile ~/tmp/zeph-r4/zephyrd-serve2.pid --log-file ~/tmp/zeph-r4/zephyrd-serve2.log`), pid 949930,
2026-11-07T01:35:16Z, listening on 127.0.0.1:28380/28381/28382 only. The first poll was synchronized:
```
2026-11-07T01:35:26Z fork=[902084 0 True 1] node=902084
```
The upstream CLI wallet opened the wallet created in section 2, whose background-mining setting is now "no", so
there is no prompt, with the here-doc of the work order:
```
$ ~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyr-wallet-cli --daemon-address 127.0.0.1:28381 --trusted-daemon --wallet-file ~/tmp/zeph-r4/wallets/up-on-fork --password '' --log-file ~/tmp/zeph-r4/wallet-up-on-fork-2.log <<'EOF'
refresh
status
balance
show_transfers
bc_height
exit
EOF
This is the command line zephyr wallet. It needs to connect to a zephyr
daemon to work correctly.
WARNING: Do not reuse your Zephyr keys on another fork, UNLESS this fork has key reuse mitigations built in. Doing so will harm your privacy.
Zephyr 'Version 2.3' (v2.3.0-release)
Logging to ~/tmp/zeph-r4/wallet-up-on-fork-2.log
Opened wallet: ZEPHYR33ZsRVkciV8GpewU671iYoEt8hgXY2psqy4PxJ9XJhAh7qVBsP7YYXioHWevXhoirveu9o6i48jzoScVE452T2MVuNRfA23
**********************************************************************
Use the "help" command to see a simplified list of available commands.
Use "help all" to see the list of all available commands.
Use "help <command>" to see a command's documentation.
**********************************************************************
Background mining not enabled. Run "set setup-background-mining 1" to change.
Starting refresh...
(1 progress lines, the last: Height 902056 / 902084)
Refresh done, blocks received: 28
Untagged accounts:
             Account               Balance      Unlocked balance           Asset                 Label
------------------------------------------------------------------------------------
Currently selected account: [0] Primary account
Tag: (No tag assigned)
Background refresh thread started
[wallet ZEPHYR33Z]: refresh
[wallet ZEPHYR33Z]:
Starting refresh...
Refresh done, blocks received: 0
Currently selected account: [0] Primary account
Tag: (No tag assigned)
[wallet ZEPHYR33Z]: status
[wallet ZEPHYR33Z]:
Refreshed 902084/902084, synced, daemon RPC v3.13, SSL
[wallet ZEPHYR33Z]: balance
[wallet ZEPHYR33Z]:
Currently selected account: [0] Primary account
Tag: (No tag assigned)
[wallet ZEPHYR33Z]: show_transfers
[wallet ZEPHYR33Z]:
[wallet ZEPHYR33Z]: bc_height
[wallet ZEPHYR33Z]:
902084
[wallet ZEPHYR33Z]: exit
```
Exit code 0, 01:35:33Z to 01:35:41Z. **Shown:** the upstream v2.3.0 CLI wallet refreshed against the fork node from
902056, where section 2 had left it (`blocks received: 28`), to the fork's height. It reported `Refreshed 902084/902084, synced, daemon RPC v3.13`
(over SSL, `--daemon-ssl` autodetect). `bc_height` gave 902084, the fork's `get_info` height at that moment, and `show_transfers` was empty.
The wallet log has no `ERROR` or `WARNING` line. The fork daemon's log has no `ERROR` line and no fatal pattern. Its three
`WARNING` lines are the startup notices of section 5 (`Daemonised`, rotating drive, and `Unable to send transaction(s), no available
connections` at 01:35:19Z before the first connection). Stopped with `kill 949930` at 01:35:49Z; it exited by 01:35:51Z
(`Cryptonote protocol stopped successfully`).
