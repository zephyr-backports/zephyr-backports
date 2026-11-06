# Sync of the sec.2 daemon from an upstream node, 2026-11-05

POLICY §6.4, first part: a fork `zephyrd` with an empty data directory syncs mainnet from a single
upstream v2.3.0 node and must reach the same chain (same height, same block hashes) without any
block being rejected. The binary is the native `wip/sec.2` build from `unit-tests.md`, built from
`16018bb0b` (`zephyrd --version`: `Zephyr 'Version 2.3' (v2.3.0-16018bb0b)`); the final `wip/sec.2`
tip `9a7478705` differs from `16018bb0b` only in `SECURITY-BACKPORTS.md` (`git diff --stat
16018bb0b 9a7478705`: 1 file, 35 insertions, 35 deletions), so the daemon code is the same.

The upstream node is a synced mainnet v2.3.0 node on the local network (`10.1.0.128`, p2p `17766`,
RPC `17767`, restricted RPC). Against it only `get_info` and `get_block_header_by_height` are used.
The fork daemon has that node as its only peer (`--add-exclusive-node`, `--out-peers 1
--in-peers 0`), every listener on 127.0.0.1, and unrestricted RPC so that `get_info` shows the real
connection count. The home directory of the machine is written as `~`; colour codes from the
daemon's console output are removed.

## Start
```
$ date -u +%FT%TZ
2026-11-05T19:13:43Z
$ ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd --data-dir ~/tmp/zeph-r4/data-sync-sec2 --add-exclusive-node 10.1.0.128:17766 --no-igd --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28380 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28381 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28382 --out-peers 1 --in-peers 0 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-sync-sec2.pid --log-file ~/tmp/zeph-r4/zephyrd-sync-sec2.log
2026-11-05 19:13:44.072	I Zephyr 'Version 2.3' (v2.3.0-16018bb0b)
2026-11-05 19:13:44.072	I Moving from main() into the daemonize now.
Forking to background...
$ ss -ltnp | grep zephyrd
LISTEN 0      100                                 127.0.0.1:28382      0.0.0.0:*    users:(("zephyrd",pid=142695,fd=21))
LISTEN 0      4096                                127.0.0.1:28381      0.0.0.0:*    users:(("zephyrd",pid=142695,fd=14))
LISTEN 0      4096                                127.0.0.1:28380      0.0.0.0:*    users:(("zephyrd",pid=142695,fd=10))
```
The only peer (`get_connections` is a JSON-RPC method; the plain path `/get_connections` answers
`404`):
```
$ date -u +%FT%TZ
2026-11-05T19:14:38Z
$ curl -s http://127.0.0.1:28381/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_connections"}' -H 'Content-Type: application/json'
{
  "id": "0",
  "jsonrpc": "2.0",
  "result": {
    "connections": [{
      "address": "10.1.0.128:17766",
      "address_type": 1,
      "avg_download": 121,
      "avg_upload": 2,
      "connection_id": "b31852f2aa3149b99bd38b61927bf7a7",
      "current_download": 150,
      "current_upload": 2,
      "height": 901179,
      "host": "10.1.0.128",
      "incoming": false,
      "ip": "10.1.0.128",
      "live_time": 51,
      "local_ip": true,
      "localhost": false,
      "peer_id": "267ac4ec22e20fb1",
      "port": "17766",
      "pruning_seed": 0,
      "recv_count": 6347316,
      "recv_idle_time": 1,
      "rpc_credits_per_hash": 0,
      "rpc_port": 0,
      "send_count": 137213,
      "send_idle_time": 1,
      "state": "synchronizing",
      "support_flags": 1
    }],
    "status": "OK",
    "untrusted": false
  }
}
```

## Watched log lines
The log (level 1) is followed from its first line for `ERROR`, `rejected`, `Block with id`,
`verification failed` and `Failed to add`. Line 1 of the log matches `ERROR` only as a log-level
setting (`New log categories: ... daemon.rpc.payment:ERROR ...`) and is not counted. Every other
match is quoted here verbatim. No `rejected`, `Block with id`, `verification failed` or `Failed to
add` line has appeared. One `ERROR` message recurs: about every 10,000 blocks the daemon finds it
can request nothing more from its only peer, drops the connection and reconnects to the same node
within one second, and the sync goes on (heights at the six occurrences up to 19:33Z: 10000, 19999,
29998, 39997, 49996, 59995). The first occurrence with the lines around it:
```
2026-11-05 19:16:01.084	[P2P0]	INFO	global	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1694	Synced 10000/901180 (1%, 891180 left) (1.347318 sec, 73.479312 blocks/sec), 0.000000 MB queued in 0 spans, stripe 3 -> 3
2026-11-05 19:16:01.084	[P2P0]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1702	[10.1.0.128:17766 OUT] [0] state: stopping adding blocks in state synchronizing
2026-11-05 19:16:01.084	[P2P0]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2380	[10.1.0.128:17766 OUT] [0] state: We can download nothing from this peer, dropping in state synchronizing
2026-11-05 19:16:01.084	[P2P0]	ERROR	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1722	[10.1.0.128:17766 OUT] Failed to request missing objects, dropping connection
2026-11-05 19:16:01.084	[P2P0]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2940	Target height decreasing from 901180 to 0
2026-11-05 19:16:01.084	[P2P0]	WARNING	global	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2944	zephyrd is now disconnected from the network
2026-11-05 19:16:01.084	[P2P0]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2950	[10.1.0.128:17766 OUT] [0] state: closed in state synchronizing
2026-11-05 19:16:01.084	[P2P0]	INFO	net.p2p	src/p2p/net_node.inl:2682	[10.1.0.128:17766 b31852f2-aa31-49b9-9bd3-8b61927bf7a7 OUT] CLOSE CONNECTION
2026-11-05 19:16:01.643	[P2P3]	INFO	net.p2p	src/p2p/net_node.inl:2663	[10.1.0.128:17766 34ec80d0-98d6-45c5-949b-45d81e3b2220 OUT] NEW CONNECTION
```
`git diff --stat v2.3.0 16018bb0b -- src/cryptonote_protocol/ src/p2p/` is empty: the fork changes
nothing in this code. The first two occurrences, verbatim:
```
2026-11-05 19:16:01.084	[P2P0]	ERROR	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1722	[10.1.0.128:17766 OUT] Failed to request missing objects, dropping connection
2026-11-05 19:18:46.621	[P2P5]	ERROR	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1722	[10.1.0.128:17766 OUT] Failed to request missing objects, dropping connection
```
Count up to 2026-11-05T19:33:35Z: six, all this line, and no other match. The period of 9,999
blocks matches one chain entry of 10,000 block ids (`BLOCKS_IDS_SYNCHRONIZING_DEFAULT_COUNT`): with
one exclusive peer the block queue runs dry once per chain entry, and the daemon drops the peer and
reconnects. The control run below, with the upstream v2.3.0 binary, is there to show the same line
at the same heights. Later matches are collected by the watcher described under "Logger"; the end-of-sync record gives
their count and quotes any line other than this one.

Up to 2026-11-05T19:52Z the watcher collected 11 drop lines (heights 10000 to 99991, one per 9,999
blocks) and 142 `WARNING` lines. Those match only because `LEVIN_ERROR_CONNECTION_DESTROYED`
contains `ERROR`: 141 refused handshakes during the control run (see "Control") and one timed sync
that was still in flight when the connection was dropped at height 69994:
```
2026-11-05 19:34:51.168	[P2P9]	WARNING	net.p2p	src/p2p/net_node.inl:1236	[10.1.0.128:17766 OUT] COMMAND_TIMED_SYNC invoke failed. (-3, LEVIN_ERROR_CONNECTION_DESTROYED)
2026-11-05 19:45:27.101	[P2P6]	WARNING	net.p2p	src/p2p/net_node.inl:1148	[10.1.0.128:17766 OUT] COMMAND_HANDSHAKE invoke failed. (-3, LEVIN_ERROR_CONNECTION_DESTROYED)
```
The first comes in the same millisecond as the drop line at 69994. The second is the first of the 141.

Counting rule for the end of the sync (owner, 2026-11-05): `WARNING` lines that match only through
`LEVIN_ERROR_...` are connection noise and say nothing about blocks. They are the refused handshakes
while two daemons competed for the one per-IP slot, and a timed sync cut off by a drop. The final
record gives them one line with their count and cause. The counts that matter are `rejected`, `Block with id`,
`verification failed`, `Failed to add`, and every `ERROR`-level line other than the R10-3 drop line.

## Progress while the session watched (2026-11-05T19:15Z to 19:26Z)
`get_info` on both nodes: `height target_height synchronized outgoing_connections_count`. The
upstream node's RPC is restricted, so its connection count reads 0. The 19:26:11Z row is an extra
poll taken when the session's loop was resumed after the first pattern match.

| UTC | fork daemon | upstream node |
|---|---|---|
| 2026-11-05T19:15:21Z | `7301 901179 False 1` | `901179 0 True 0` |
| 2026-11-05T19:25:22Z | `41597 901185 False 1` | `901185 0 True 0` |
| 2026-11-05T19:26:11Z | `44197 901185 False 1` | `901185 0 True 0` |

## Logger (from 2026-11-05T19:33Z)
The sync takes about two days (owner's estimate, 2026-11-05), so the session does not wait for it. From
2026-11-05T19:33Z two detached processes run next to the fork daemon. They are started with `setsid
nohup ... >/dev/null 2>&1 &`, so they are not tied to the session:
- `~/tmp/zeph-r4/sync-log.sh` appends one line every 10 minutes to `~/tmp/zeph-r4/sync-log.txt`:
  `<UTC time> fork=<height>/<target_height>/<synchronized> node=<height>` (fork: `get_info` on
  127.0.0.1:28381; node: `get_info` on 10.1.0.128:17767; `no-answer` if a node does not answer).
- `~/tmp/zeph-r4/sync-watch.sh` follows the daemon log across rotation (`tail -F`) and appends
  every line that matches the five watched patterns to `~/tmp/zeph-r4/sync-log-matches.txt`. It is
  needed because the daemon keeps only 50 rotated log files of about 100 MB (`--max-log-files`
  default 50, `--max-log-file-size` default 104850000); at about 10 minutes per file, that is about
  8.7 hours of log. The file was seeded with the session's own matches from log line 1 onwards,
  so it may hold a line twice where the two watchers overlapped; `sort -u` removes that.

| process | pid | pid file |
|---|---|---|
| fork `zephyrd` | 142695 | `~/tmp/zeph-r4/zephyrd-sync-sec2.pid` |
| logger `sync-log.sh` | 146864 | `~/tmp/zeph-r4/sync-log.pid` |
| watcher `sync-watch.sh` (its `tail -F` is 146659, same process group) | 146657 | `~/tmp/zeph-r4/sync-watch.pid` |

First logger line:
```
2026-11-05T19:33:35Z fork=65995/901187/False node=901187
```
The end-of-sync checks (equal height, `synchronized` true, block hashes at heights 0, 1000, the
median and the top on both nodes, stopping the fork daemon) are done in a later round from
`sync-log.txt` and `sync-log-matches.txt`.

## Control (v2.3.0 binary, first 25,000 blocks)
Goal: show that the drop line above is v2.3.0's own behaviour with a single peer. Binary
`~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyrd`, `--version`: `Zephyr 'Version 2.3' (v2.3.0-release)`,
tree at `67c5f53b8` (tag `v2.3.0`). Fresh data dir, same flags as the sec2 daemon, own ports.
```
$ date -u +%FT%TZ
2026-11-05T19:43:52Z
$ ~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyrd --data-dir ~/tmp/zeph-r4/data-sync-ctrl --add-exclusive-node 10.1.0.128:17766 --no-igd --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28480 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28481 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28482 --out-peers 1 --in-peers 0 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-sync-ctrl.pid --log-file ~/tmp/zeph-r4/zephyrd-sync-ctrl.log
2026-11-05 19:43:52.480	I Zephyr 'Version 2.3' (v2.3.0-release)
2026-11-05 19:43:52.480	I Moving from main() into the daemonize now.
Forking to background...
$ ss -ltnp | grep -E ':2848[0-2]'
LISTEN 0      100                                 127.0.0.1:28482      0.0.0.0:*    users:(("zephyrd",pid=149634,fd=21))
LISTEN 0      4096                                127.0.0.1:28481      0.0.0.0:*    users:(("zephyrd",pid=149634,fd=14))
LISTEN 0      4096                                127.0.0.1:28480      0.0.0.0:*    users:(("zephyrd",pid=149634,fd=10))
```
`get_info` on 28481 every 60 s (`height target_height synchronized outgoing_connections_count`):

| UTC | control |
|---|---|
| 2026-11-05T19:44:05Z | `1 0 False 0` |
| 2026-11-05T19:45:06Z | `1 0 False 0` |
| 2026-11-05T19:46:06Z | `2901 901193 False 1` |
| 2026-11-05T19:47:06Z | `7201 901193 False 1` |
| 2026-11-05T19:48:06Z | `10000 0 False 0` |
| 2026-11-05T19:49:06Z | `10000 0 False 0` |
| 2026-11-05T19:50:06Z | no answer: stopped by the reviewer (see "Stop") |

**Result: the drop line of R10-3 appears in the control at height 10000, as in the sec2 daemon.**
That one occurrence on the upstream binary is the point of the control, and task 4 is closed with it.
The control stopped at height 10000 because of the upstream node's limit of one connection per IP
(below). A longer control, if wanted, runs after the main sync, never beside it. The one `ERROR`
line of the control, with the lines around it, verbatim:
```
2026-11-05 19:47:48.231	[P2P3]	INFO	global	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1694	Synced 10000/901194 (1%, 891194 left) (1.429935 sec, 69.233916 blocks/sec), 0.000000 MB queued in 0 spans, stripe 3 -> 3
2026-11-05 19:47:48.231	[P2P3]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1702	[10.1.0.128:17766 OUT] [0] state: stopping adding blocks in state synchronizing
2026-11-05 19:47:48.232	[P2P3]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2380	[10.1.0.128:17766 OUT] [0] state: We can download nothing from this peer, dropping in state synchronizing
2026-11-05 19:47:48.232	[P2P3]	ERROR	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:1722	[10.1.0.128:17766 OUT] Failed to request missing objects, dropping connection
2026-11-05 19:47:48.232	[P2P3]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2940	Target height decreasing from 901194 to 0
2026-11-05 19:47:48.232	[P2P3]	WARNING	global	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2944	zephyrd is now disconnected from the network
2026-11-05 19:47:48.232	[P2P3]	INFO	net.cn	src/cryptonote_protocol/cryptonote_protocol_handler.inl:2950	[10.1.0.128:17766 OUT] [0] state: closed in state synchronizing
2026-11-05 19:47:48.232	[P2P3]	INFO	net.p2p	src/p2p/net_node.inl:2682	[10.1.0.128:17766 c7e40db4-77e0-42a8-92a4-96918ade0b83 OUT] CLOSE CONNECTION
2026-11-05 19:47:49.125	[P2P6]	INFO	net.p2p	src/p2p/net_node.inl:2663	[10.1.0.128:17766 0404887f-916d-44aa-9ac4-d22641efef16 OUT] NEW CONNECTION
2026-11-05 19:47:49.515	[P2P4]	WARNING	net.p2p	src/p2p/net_node.inl:1148	[10.1.0.128:17766 OUT] COMMAND_HANDSHAKE invoke failed. (-3, LEVIN_ERROR_CONNECTION_DESTROYED)
```
These lines are the same as at the sec2 daemon's first drop (same height 10000, same file and line
numbers 1694, 1702, 2380, 1722, 2940, 2944, 2950). The difference is the reconnect: here it was refused.
No `rejected`, `Block with id`, `verification failed` or `Failed to add` line in the control log.

**One connection per IP, the reason for the stop at 10000.** The upstream node accepts one p2p
connection per IP address (`--max-connections-per-ip`, default 1, `src/p2p/net_node.cpp:172` of
v2.3.0). Both daemons on this machine connect from the same address, so they competed for one slot,
and the one without it had its handshakes refused:
- 19:43:55Z to 19:45:25Z: the sec2 daemon held the connection. All 91 handshakes of the control were
  refused: `COMMAND_HANDSHAKE invoke failed. (-3, LEVIN_ERROR_CONNECTION_DESTROYED)`.
- 19:45:26.426Z: the sec2 daemon had its own regular drop at height 99991 (the tenth: 10000 + 9 × 9,999).
  At 19:45:27Z the control got the connection (first `Synced 101/901193` at 19:45:27.715Z). From then on the sec2
  daemon's handshakes were refused, 141 of them, the first:
  ```
  2026-11-05 19:45:27.101	[P2P6]	WARNING	net.p2p	src/p2p/net_node.inl:1148	[10.1.0.128:17766 OUT] COMMAND_HANDSHAKE invoke failed. (-3, LEVIN_ERROR_CONNECTION_DESTROYED)
  ```
- 19:47:48.232Z: the control dropped at height 10000 (above). At 19:47:48.851Z the sec2 daemon was
  connected again and kept syncing (`Synced 100591/901194` at 19:48:02Z). It lost about 2 minutes 20 seconds,
  rejected nothing, and its 141 handshake failures have this one cause. From 19:47:49Z the control
  had no connection, and its handshakes were refused again, 120 times, until it was stopped (211 for
  the control in all: 91 before it got the slot, 120 after).

**Stop.** The reviewer stopped the control at 2026-11-05T19:49:50Z with `kill 149634` because of
the per-IP limit; it exited after about 1 s. Its log shows the orderly shutdown from 19:49:49.751Z
(`net_service loop stopped.`, `p2p net loop stopped`, `Node stopped.`, `Deinitializing core...`)
to the last line at 19:49:50.266Z, `Cryptonote protocol stopped successfully`, with no error
before it. At log level 1 a signal leaves no line of its own (the handler only sets a flag,
`src/daemon/daemon.cpp:208`). The data dir `~/tmp/zeph-r4/data-sync-ctrl` (41 MB, height 10000)
and the log are kept. No second daemon runs against the upstream node while the main sync runs.

## Log archiver (from 2026-11-05T19:44Z)
To keep the whole daemon log beyond the daemon's 50-file window, a third detached process gzips
every rotated log file once, into `~/tmp/zeph-r4/synclog-archive/`. It never touches the live log
and deletes nothing; the daemon removes its own old files. Started at 2026-11-05T19:44:13Z with
`setsid nohup ./sync-archive.sh >/dev/null 2>&1 &`, pid **149847** (`~/tmp/zeph-r4/sync-archive.pid`).
```
#!/usr/bin/env bash
# Every 60 s: gzip each rotated sync-sec2 log file (never the live log) into synclog-archive/,
# once, listing it in sync-archive.done. Deletes nothing; the daemon removes its own old files.
D=$HOME/tmp/zeph-r4
mkdir -p "$D/synclog-archive"; touch "$D/sync-archive.done"
shopt -s nullglob
while :; do
  for f in "$D"/zephyrd-sync-sec2.log-*; do
    n=$(basename "$f")
    grep -qxF "$n" "$D/sync-archive.done" && continue
    if gzip -c "$f" > "$D/synclog-archive/$n.gz"; then
      echo "$n" >> "$D/sync-archive.done"
    fi
  done
  sleep 60
done
```
First archived file: `zephyrd-sync-sec2.log-2026-11-05-19-24-08.gz`, 10114007 bytes (from 104850033;
it is the first log file, starting at log line 1). By 2026-11-05T19:45Z three files were archived,
each about 10 MB, and `gzip -t` passed on all three. Room: `df -h ~/tmp` → `492G size, 387G used, 86G avail, 82%`. At about
100 MB raw per 10 minutes (about 29 GB over two days) and a ratio of about 10:1, the archive will grow
to about 3 GB (estimate).

## The `stacktrace` lines
The log carries many `INFO stacktrace` lines (category `stacktrace`, `src/common/stack_trace.cpp`).
That code logs the call stack of every C++ exception when it is thrown, including exceptions that
are caught and handled. The oldest log file still present is
`zephyrd-sync-sec2.log-2026-11-05-19-24-08` (log line 1 onwards, 19:13:44Z to 19:24:08Z). In it, the
first `stacktrace` line is line 46 (line 1 matches only as the setting `stacktrace:INFO`). The five
lines before it and the first ten lines of the block, verbatim (home directory written as `~`,
trailing spaces removed):
```
2026-11-05 19:13:44.078	    7df61bdd9ec0	INFO	blockchain	src/cryptonote_core/blockchain.cpp:395	  }
2026-11-05 19:13:44.078	    7df61bdd9ec0	INFO	blockchain	src/cryptonote_core/blockchain.cpp:395	}
2026-11-05 19:13:44.078	    7df61bdd9ec0	INFO	blockchain	src/cryptonote_core/blockchain.cpp:398	genesis miner tx hash: <dfaed909a6e706d63a3c7ed73237d466d910897ef2d3e8b1429474aeafd4f563>
2026-11-05 19:13:44.079	    7df61bdd9ec0	INFO	blockchain	src/cryptonote_core/blockchain.cpp:401	genesis miner tx hex: 023c01ff00018080c89d9deb96f8060257f131265da14cfbe25847967c687aea29d0673bbeeebbaa2e6bdec6c6d572d6045a4550482c2101e04f1b00cf7e4bdf8c36a8c54092d5ed1c16ebf2777a0a891ac2ed0c7ff6f22600000000
2026-11-05 19:13:44.079	    7df61bdd9ec0	INFO	randomx	contrib/epee/src/mlog.cpp:516	RandomX new secondary seed hash is 0000000000000000000000000000000000000000000000000000000000000000
2026-11-05 19:13:44.079	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:133	Exception: std::bad_alloc
2026-11-05 19:13:44.079	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:134	Unwound call stack:
2026-11-05 19:13:44.080	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:172	    [1]  0xae) [0x57c85a745c94]:__cxa_throw+0xae) [0x57c85a745c94]
2026-11-05 19:13:44.080	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:172	    [2] ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd(+0x12ee20) [0x57c85a7b7e20]
2026-11-05 19:13:44.080	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:172	    [3] ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd(+0x9911e1) [0x57c85b01a1e1]
2026-11-05 19:13:44.080	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:172	    [4] ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd(+0x688da4) [0x57c85ad11da4]
2026-11-05 19:13:44.080	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:172	    [5] ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd(+0x689b1a) [0x57c85ad12b1a]
2026-11-05 19:13:44.080	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:172	    [6] ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd(+0x64490e) [0x57c85accd90e]
2026-11-05 19:13:44.080	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:172	    [7] ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd(+0x892b42) [0x57c85af1bb42]
2026-11-05 19:13:44.080	    7df61bdd9ec0	INFO	stacktrace	src/common/stack_trace.cpp:172	    [8] ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd(+0x65ce80) [0x57c85ace5e80]
```
Frames of this block, resolved with `addr2line -f -C -e` on the binary (offsets after `zephyrd(+`):
`randomx_alloc_cache` ← `rx_alloc_cache` (`rx-slow-hash.c`) ← `rx_slow_hash` ← the genesis-block PoW
in `generate_genesis_block` ← `Blockchain::init` ← `core::init` ← `main`. (Frame 2 resolves to
`randomx::generateSuperscalar [clone .cold]`, probably just the nearest symbol to a cold code section.) The exception is
`std::bad_alloc` from `randomx::LargePageAllocator::allocMemory` (`external/randomx/src/allocator.cpp`),
which throws when no large page can be allocated. This machine has none: `/proc/sys/vm/nr_hugepages`
is `0` and `HugePages_Total: 0`. `randomx.cpp` catches it and returns NULL. `rx-slow-hash.c` then retries
without `RANDOMX_FLAG_LARGE_PAGES`: `rx_alloc_cache` after
`alloc_err_msg("Couldn't allocate RandomX cache using large pages")`, and `rx_init_light_vm` in the
same way for the VM. So the exception is caught and handled every time, and the trace is only logged.

Counts in that file (19:13:44Z to 19:24:08Z, heights 1 to 37,598): 30,008 `stacktrace` lines in 1,640
blocks. Of these, 1,529 are `Exception: std::bad_alloc` and 111 are `Exception: cryptonote::BLOCK_DNE`.
- `std::bad_alloc`: The later throws resolve to `block_longhash_worker` →
  `get_block_longhash` → `rx_slow_hash` → `rx_init_light_vm` → `randomx_create_vm` →
  `VmBase<LargePageAllocator>::allocate`, which is the RandomX VM of the PoW check, tried with large pages first.
  They come in fixed numbers per batch of added blocks: between two consecutive `Synced` lines (one batch of about 100
  blocks), 357 batches have 4, 18 have 5 and the first has 7. The extra one per batch matches the
  RandomX seed changes (19 times `RandomX secondary cache updated` in the file), where a cache is
  allocated as well. That is 125 to 190 per full minute. The trace path `block_longhash_worker` →
  `get_block_longhash` → `rx_slow_hash` shows that the daemon computes the RandomX proof of work for
  every batch during this sync.
- `cryptonote::BLOCK_DNE`: all 111 come in the first minute (19:13Z), before the first `Synced` line. They
  follow `Attempt to get hash from height ... failed -- hash not in db` or `Attempted to retrieve
  non-existent block height` (`db_lmdb.cpp:81`/`:88`) during the first chain request on an empty
  database.
- None of these follows the drops of R10-3 (3 drops in the file against 1,640 traces). The drop
  line comes from the protocol handler and throws no exception.

## End of sync
All from `~/tmp/zeph-r4/`, read on 2026-11-06 between 23:22Z and 23:25Z with the fork daemon still running.

**Times** (from `sync-log.txt`, one line every 10 minutes). Start 2026-11-05T19:13:43Z; the first
`True` line:
```
2026-11-06T18:29:08Z fork=890915/901866/False node=901866
2026-11-06T18:39:08Z fork=901872/0/True node=901872
```
Wall time from the start to the first `True` line: **23 h 25 min 25 s**. The upstream node's outage (it
stopped during a software update on the host; restarted by the owner): the first and last
`node=no-answer` lines, 62 lines in a row, during which the fork stood at 274,874 with no connection
(`target_height` 0):
```
2026-11-05T21:44:00Z fork=269974/0/False node=901253
2026-11-05T21:54:00Z fork=274874/0/False node=no-answer
...
2026-11-06T08:04:05Z fork=274874/0/False node=no-answer
2026-11-06T08:14:08Z fork=286673/901572/False node=901572
```
Outage window (first to last `no-answer` line): 10 h 10 min 05 s. Effective syncing time (wall time
minus the outage): **13 h 15 min 20 s**. The fork resumed by itself; it was not restarted.
Its own RPC did not answer within the logger's 20 s timeout at six polls (09:34:47Z,
10:45:46Z, 10:56:06Z, 12:57:03Z, 13:07:23Z, 13:17:43Z on 2026-11-06), while it kept syncing.

**Block hashes.** The fork's `get_info` height, read once at 2026-11-06T23:22:35Z: 902016, so top = 902015.
`get_block_header_by_height` via `/json_rpc` on the fork (127.0.0.1:28381) and on the upstream node
(10.1.0.128:17767):

| height | fork hash | upstream node hash | equal |
|---|---|---|---|
| 0 | `f53afd86c39b60858bd5fc9ea9f4b8e688f79c2b0158b211463bb34494730505` | `f53afd86c39b60858bd5fc9ea9f4b8e688f79c2b0158b211463bb34494730505` | yes |
| 1000 | `6e596448f4e7d5d617269d3faf5669082bb42fd935c067cec20211d463ab3452` | `6e596448f4e7d5d617269d3faf5669082bb42fd935c067cec20211d463ab3452` | yes |
| 451007 | `a81672f21254414ae0b144e364ba63d14e079446543c09ff403b8c9aa1de14c6` | `a81672f21254414ae0b144e364ba63d14e079446543c09ff403b8c9aa1de14c6` | yes |
| 902015 | `40eccad0610cc1688e831e45138cfa3cf18ff2e743eb9db1af6153e4fe838eec` | `40eccad0610cc1688e831e45138cfa3cf18ff2e743eb9db1af6153e4fe838eec` | yes |

`get_last_block_header` on both: height 902015, hash
`40eccad0610cc1688e831e45138cfa3cf18ff2e743eb9db1af6153e4fe838eec`, timestamp 1794007298 (equal).

**Every block was fully verified.** The tree ships compiled-in block hashes
(`src/blocks/checkpoints.dat`, 332,676 bytes). With `PER_BLOCK_CHECKPOINT` defined, they would let
the daemon skip the proof-of-work and transaction-input checks below their height (`fast_check` in
`Blockchain::handle_block_to_main_chain`, `src/cryptonote_core/blockchain.cpp:4485` to `:4506` and
`:4653`). `CMakeLists.txt:382` sets `PER_BLOCK_CHECKPOINT 0`, and no `flags.make` in the build tree
carries `-DPER_BLOCK_CHECKPOINT`, so that path is compiled out. The whole log has no `Loading
precomputed blocks` or `No pre-validated hash` line. Every block went through `get_block_longhash`
(precomputed by `block_longhash_worker`, see "The `stacktrace` lines"), `check_hash` against its
difficulty, and `check_tx_inputs`.

**Watched lines.** `sync-log-matches.txt`: 36,894 lines, all unique. One is the log-level setting on
line 1. The rest, by message type:

| count | level | source | message | type |
|---|---|---|---|---|
| 88 | ERROR | `cryptonote_protocol_handler.inl:1722` | `Failed to request missing objects, dropping connection` | drop line of R10-3 |
| 36,639 | WARNING | `net_node.inl:1148` | `COMMAND_HANDSHAKE invoke failed. (-3, LEVIN_ERROR_CONNECTION_DESTROYED)` | `LEVIN_ERROR` |
| 67 | WARNING | `net_node.inl:1148` | `COMMAND_HANDSHAKE invoke failed. (-1, LEVIN_ERROR_CONNECTION)` | `LEVIN_ERROR` |
| 15 | WARNING | `net_node.inl:1236` | `COMMAND_TIMED_SYNC invoke failed. (-3, LEVIN_ERROR_CONNECTION_DESTROYED)` | `LEVIN_ERROR` |
| 4 | WARNING | `net_node.inl:1236` | `COMMAND_TIMED_SYNC invoke failed. (..., LEVIN_ERROR_CONNECTION)` | `LEVIN_ERROR` |
| 3 | WARNING | `net_node.inl:1236` | `COMMAND_TIMED_SYNC invoke failed. (..., LEVIN_ERROR_CONNECTION_TIMEDOUT)` | `LEVIN_ERROR` |
| 71 | ERROR | `levin_protocol_handler_async.h:627` | `Failed to do_send` | `Failed to do_send` |
| 3 | ERROR | `levin_protocol_handler_async.h:665` | `Failed to send message, dropping it` | other |
| 2 | ERROR | `levin_protocol_handler_async.h:340` | `[levin_protocol] -->> start_outer_call failed` | other |
| 1 | ERROR | `levin_protocol_handler_async.h:513` | `Received levin response but have no invoke handlers` | other |

Following the owner's counting rule (R10-6), the `LEVIN_ERROR` warnings are connection noise, one
line: **36,728, of which 36,706 are refused handshakes.** 141 of those came while two daemons competed for the
one per-IP slot (control run), and 36,565 came during the node's outage; there were none at any other time. The 22 timed-sync
failures are syncs cut off by a drop or by the outage. Of the 71 `Failed to do_send`, 67 fall in the
outage window and 4 outside it (2026-11-06 10:47:56Z, 10:54:27Z, 10:55:27Z, 13:14:51Z). The six
lines of the three other types, verbatim:
```
2026-11-06 05:53:35.862	    7df5b2ffc6c0	ERROR	net	contrib/epee/include/net/levin_protocol_handler_async.h:340	[10.1.0.128:17766 OUT] [levin_protocol] -->> start_outer_call failed
2026-11-06 07:14:44.630	[P2P8]	ERROR	net	contrib/epee/include/net/levin_protocol_handler_async.h:340	[10.1.0.128:17766 OUT] [levin_protocol] -->> start_outer_call failed
2026-11-06 10:48:36.992	[P2P4]	ERROR	net	contrib/epee/include/net/levin_protocol_handler_async.h:665	[10.1.0.128:17766 OUT] Failed to send message, dropping it
2026-11-06 10:48:36.993	[P2P4]	ERROR	net	contrib/epee/include/net/levin_protocol_handler_async.h:513	Received levin response but have no invoke handlers
2026-11-06 10:55:34.963	[P2P5]	ERROR	net	contrib/epee/include/net/levin_protocol_handler_async.h:665	[10.1.0.128:17766 OUT] Failed to send message, dropping it
2026-11-06 13:14:51.580	[P2P4]	ERROR	net	contrib/epee/include/net/levin_protocol_handler_async.h:665	[10.1.0.128:17766 OUT] Failed to send message, dropping it
```
The two `start_outer_call failed` lines fall in the outage window. The four send-failure lines after it
(10:47Z to 10:55Z and 13:14Z) and the four `Failed to do_send` outside the outage fall in the two
periods in which the fork's own RPC missed polls (10:45Z to 10:56Z and 12:57Z to 13:17Z). All of them
are in the network-message layer (`levin_protocol_handler_async.h`), and none of them is about a block
(question R11-2).

Fatal patterns over the whole log, archive and live files:
```
$ (for f in synclog-archive/*.gz; do zcat "$f"; done; cat zephyrd-sync-sec2.log*) | grep -c -E 'rejected|Block with id|verification failed|Failed to add'
0
```
The pipeline read the whole log: on the same input, `grep -c 'BLOCK SUCCESSFULLY ADDED'` gives
897,810 for the archive and 4,207 for the live file `zephyrd-sync-sec2.log` (902,017 lines for the
902,016 blocks at heights 0 to 902015).
Archive at that moment: 46 files (every rotated file; the daemon deleted none, because it stayed below its
50-file window), 398750046 bytes (381 MB) gzipped. Live log files: 47 (46 rotated plus the current one),
4.6 GB.

**Fork daemon at the end** (2026-11-06T23:23:08Z, `get_info`): height 902016, `synchronized` true,
`outgoing_connections_count` 1, `incoming_connections_count` 0, `database_size` 13926629376,
`top_block_hash` `40eccad0610cc1688e831e45138cfa3cf18ff2e743eb9db1af6153e4fe838eec`.
`du -sh ~/tmp/zeph-r4/data-sync-sec2` → `13G`.

## Stop (2026-11-06)
```
$ kill 142695                      # 2026-11-06T23:24:22Z
exited by 2026-11-06T23:24:25Z (about 4 s); last log line:
2026-11-06 23:24:23.164	[SRV_MAIN]	INFO	global	src/daemon/protocol.h:79	Cryptonote protocol stopped successfully
$ kill -- -146657; kill 146864; kill 149847      # 2026-11-06T23:24:30Z (watcher with its tail, logger, archiver)
$ ps -p 146657,146659,146864,149847,142695       # none running
```
The archiver's last pass was done by hand. Every rotated file was already in `sync-archive.done`,
and the live log was archived as `synclog-archive/zephyrd-sync-sec2.log-final.gz` (27552008 bytes →
1975874 bytes, 2026-11-06T23:24:38Z). Final archive: 47 files, 400725920 bytes (383 MB), `gzip -t`
passed on all of them. `df -h /` → `492G size, 101G used, 372G avail, 22%`. The data directory
`~/tmp/zeph-r4/data-sync-sec2` (13 GB) and the archive are kept. The owner's node keeps running and
was only read (`get_info`, `get_block_header_by_height`, `get_last_block_header`).
