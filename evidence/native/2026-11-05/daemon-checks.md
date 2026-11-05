# Restricted-RPC checks on native daemons, 2026-11-05

Upstream v2.3.0 and `wip/sec.2` (`7ba805e61`) `zephyrd` from the native builds in
`unit-tests.md`, each started `--offline --restricted-rpc --no-igd` with every listener on
127.0.0.1 and an empty data directory (chain height 1), then probed with `curl -s -i`, then stopped.
ZMQ checks were not run in the first two passes (no ZMQ client library on the machine yet); they
follow in the section "ZMQ" below. The home directory of the machine is
written as `~`; colour codes from the daemon's console output are removed.

| request | v2.3.0 | wip/sec.2 |
|---|---|---|
| `GET /get_transaction_pool` | `HTTP/1.1 200 Ok` | `HTTP/1.1 404 Not found` |
| `GET /get_alt_blocks_hashes` | `HTTP/1.1 200 Ok` | `HTTP/1.1 404 Not found` |
| `GET /get_transaction_pool_hashes.bin` | `HTTP/1.1 200 Ok` | `HTTP/1.1 200 Ok` |
| `GET /get_info` | `HTTP/1.1 200 Ok` | `HTTP/1.1 200 Ok` |

## Output, verbatim
```
## start 2026-11-05T11:27:09Z
$ (cd ~/tmp/zeph-r4/zephyr-v2.3.0/build && ./bin/zephyrd --offline --restricted-rpc --no-igd --data-dir ~/tmp/zeph-r4/data-v2.3.0 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28081 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28082 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28080 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-v2.3.0.pid --log-file ~/tmp/zeph-r4/zephyrd-v2.3.0.log)
2026-11-05 11:27:09.857	I Zephyr 'Version 2.3' (v2.3.0-release)
2026-11-05 11:27:09.857	I Moving from main() into the daemonize now.
Forking to background...
rpc up after 4s
$ (cd ~/tmp/zeph-r4/zephyr-sec2/build && ./bin/zephyrd --offline --restricted-rpc --no-igd --data-dir ~/tmp/zeph-r4/data-sec2 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28181 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28182 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28180 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-sec2.pid --log-file ~/tmp/zeph-r4/zephyrd-sec2.log)
2026-11-05 11:27:13.026	I Zephyr 'Version 2.3' (v2.3.0-7ba805e61)
2026-11-05 11:27:13.026	I Moving from main() into the daemonize now.
Forking to background...
rpc up after 3s

## listening sockets of the two daemons
LISTEN 0      100                                 127.0.0.1:28182      0.0.0.0:*    users:(("zephyrd",pid=65761,fd=20))       
LISTEN 0      4096                                127.0.0.1:28181      0.0.0.0:*    users:(("zephyrd",pid=65761,fd=13))       
LISTEN 0      100                                 127.0.0.1:28082      0.0.0.0:*    users:(("zephyrd",pid=65711,fd=20))       
LISTEN 0      4096                                127.0.0.1:28081      0.0.0.0:*    users:(("zephyrd",pid=65711,fd=13))       

### v2.3.0: $ curl -s -i http://127.0.0.1:28081/get_transaction_pool
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 81
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 11:27:15 GMT
Accept-Ranges: bytes

{
  "credits": 0,
  "status": "OK",
  "top_hash": "",
  "untrusted": false
}
(curl exit=0)

### v2.3.0: $ curl -s -i http://127.0.0.1:28081/get_alt_blocks_hashes
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 81
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 11:27:15 GMT
Accept-Ranges: bytes

{
  "credits": 0,
  "status": "OK",
  "top_hash": "",
  "untrusted": false
}
(curl exit=0)

### v2.3.0: $ curl -s -i http://127.0.0.1:28081/get_transaction_pool_hashes.bin
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 81
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 11:27:15 GMT
Accept-Ranges: bytes

{
  "credits": 0,
  "status": "OK",
  "top_hash": "",
  "untrusted": false
}
(curl exit=0)

### v2.3.0: $ curl -s -i http://127.0.0.1:28081/get_info
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 1225
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 11:27:15 GMT
Accept-Ranges: bytes

{
  "adjusted_time": 1793878035,
  "alt_blocks_count": 0,
  "block_size_limit": 600000,
  "block_size_median": 300000,
  "block_weight_limit": 600000,
  "block_weight_median": 300000,
  "bootstrap_daemon_address": "",
  "busy_syncing": false,
  "credits": 0,
  "cumulative_difficulty": 1,
  "cumulative_difficulty_top64": 0,
  "database_size": 5368709120,
  "difficulty": 1,
  "difficulty_top64": 0,
  "free_space": 18446744073709551615,
  "grey_peerlist_size": 0,
  "height": 1,
  "height_without_bootstrap": 0,
  "incoming_connections_count": 0,
  "mainnet": true,
  "nettype": "mainnet",
  "offline": true,
  "outgoing_connections_count": 0,
  "restricted": true,
  "rpc_connections_count": 0,
  "stagenet": false,
  "start_time": 0,
  "status": "OK",
  "synchronized": true,
  "target": 120,
  "target_height": 0,
  "testnet": false,
  "top_block_hash": "f53afd86c39b60858bd5fc9ea9f4b8e688f79c2b0158b211463bb34494730505",
  "top_hash": "",
  "tx_count": 0,
  "tx_pool_size": 0,
  "untrusted": false,
  "update_available": false,
  "version": "",
  "was_bootstrap_ever_used": false,
  "white_peerlist_size": 0,
  "wide_cumulative_difficulty": "0x1",
  "wide_difficulty": "0x1"
}
(curl exit=0)

### sec2: $ curl -s -i http://127.0.0.1:28181/get_transaction_pool
HTTP/1.1 404 Not found
Server: Epee-based
Content-Length: 0
Content-Type: text/plain
Last-Modified: Thu, 05 Nov 2026 11:27:15 GMT
Accept-Ranges: bytes


(curl exit=0)

### sec2: $ curl -s -i http://127.0.0.1:28181/get_alt_blocks_hashes
HTTP/1.1 404 Not found
Server: Epee-based
Content-Length: 0
Content-Type: text/plain
Last-Modified: Thu, 05 Nov 2026 11:27:15 GMT
Accept-Ranges: bytes


(curl exit=0)

### sec2: $ curl -s -i http://127.0.0.1:28181/get_transaction_pool_hashes.bin
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 81
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 11:27:15 GMT
Accept-Ranges: bytes

{
  "credits": 0,
  "status": "OK",
  "top_hash": "",
  "untrusted": false
}
(curl exit=0)

### sec2: $ curl -s -i http://127.0.0.1:28181/get_info
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 1225
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 11:27:15 GMT
Accept-Ranges: bytes

{
  "adjusted_time": 1793878035,
  "alt_blocks_count": 0,
  "block_size_limit": 600000,
  "block_size_median": 300000,
  "block_weight_limit": 600000,
  "block_weight_median": 300000,
  "bootstrap_daemon_address": "",
  "busy_syncing": false,
  "credits": 0,
  "cumulative_difficulty": 1,
  "cumulative_difficulty_top64": 0,
  "database_size": 5368709120,
  "difficulty": 1,
  "difficulty_top64": 0,
  "free_space": 18446744073709551615,
  "grey_peerlist_size": 0,
  "height": 1,
  "height_without_bootstrap": 0,
  "incoming_connections_count": 0,
  "mainnet": true,
  "nettype": "mainnet",
  "offline": true,
  "outgoing_connections_count": 0,
  "restricted": true,
  "rpc_connections_count": 0,
  "stagenet": false,
  "start_time": 0,
  "status": "OK",
  "synchronized": true,
  "target": 120,
  "target_height": 0,
  "testnet": false,
  "top_block_hash": "f53afd86c39b60858bd5fc9ea9f4b8e688f79c2b0158b211463bb34494730505",
  "top_hash": "",
  "tx_count": 0,
  "tx_pool_size": 0,
  "untrusted": false,
  "update_available": false,
  "version": "",
  "was_bootstrap_ever_used": false,
  "white_peerlist_size": 0,
  "wide_cumulative_difficulty": "0x1",
  "wide_difficulty": "0x1"
}
(curl exit=0)

## ZMQ: ModuleNotFoundError: No module named 'zmq'
## stop 2026-11-05T11:27:15Z
kill v2.3.0 pid 65711
kill sec2 pid 65761
v2.3.0 pid 65711 exited after 3s
sec2 pid 65761 exited after 1s
112K	~/tmp/zeph-r4/data-v2.3.0
112K	~/tmp/zeph-r4/data-sec2
## end 2026-11-05T11:27:17Z
```

## Re-run on the rewritten branches (2026-11-05, later the same day)
The same script against the control and the rebuilt `wip/sec.2` binary at `16018bb0b`, fresh data
directories, same ports and flags. ZMQ was again not tested (no ZMQ client library).

| request | v2.3.0 | wip/sec.2 (`16018bb0b`) |
|---|---|---|
| `GET /get_transaction_pool` | `HTTP/1.1 200 Ok` | `HTTP/1.1 404 Not found` |
| `GET /get_alt_blocks_hashes` | `HTTP/1.1 200 Ok` | `HTTP/1.1 404 Not found` |
| `GET /get_transaction_pool_hashes.bin` | `HTTP/1.1 200 Ok` | `HTTP/1.1 200 Ok` |
| `GET /get_info` | `HTTP/1.1 200 Ok` | `HTTP/1.1 200 Ok` |

Output, verbatim:
```
## start 2026-11-05T12:49:59Z
$ (cd ~/tmp/zeph-r4/zephyr-v2.3.0/build && ./bin/zephyrd --offline --restricted-rpc --no-igd --data-dir ~/tmp/zeph-r4/data-v2.3.0 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28081 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28082 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28080 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-v2.3.0.pid --log-file ~/tmp/zeph-r4/zephyrd-v2.3.0.log)
2026-11-05 12:49:59.455	I Zephyr 'Version 2.3' (v2.3.0-release)
2026-11-05 12:49:59.455	I Moving from main() into the daemonize now.
Forking to background...
rpc up after 6s
$ (cd ~/tmp/zeph-r4/zephyr-sec2/build && ./bin/zephyrd --offline --restricted-rpc --no-igd --data-dir ~/tmp/zeph-r4/data-sec2 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28181 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28182 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28180 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-sec2.pid --log-file ~/tmp/zeph-r4/zephyrd-sec2.log)
2026-11-05 12:50:04.660	I Zephyr 'Version 2.3' (v2.3.0-16018bb0b)
2026-11-05 12:50:04.660	I Moving from main() into the daemonize now.
Forking to background...
rpc up after 2s

## listening sockets of the two daemons
LISTEN 0      100                                 127.0.0.1:28182      0.0.0.0:*    users:(("zephyrd",pid=97127,fd=20))       
LISTEN 0      4096                                127.0.0.1:28181      0.0.0.0:*    users:(("zephyrd",pid=97127,fd=13))       
LISTEN 0      100                                 127.0.0.1:28082      0.0.0.0:*    users:(("zephyrd",pid=97073,fd=20))       
LISTEN 0      4096                                127.0.0.1:28081      0.0.0.0:*    users:(("zephyrd",pid=97073,fd=13))       

### v2.3.0: $ curl -s -i http://127.0.0.1:28081/get_transaction_pool
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 81
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 12:50:05 GMT
Accept-Ranges: bytes

{
  "credits": 0,
  "status": "OK",
  "top_hash": "",
  "untrusted": false
}
(curl exit=0)

### v2.3.0: $ curl -s -i http://127.0.0.1:28081/get_alt_blocks_hashes
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 81
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 12:50:05 GMT
Accept-Ranges: bytes

{
  "credits": 0,
  "status": "OK",
  "top_hash": "",
  "untrusted": false
}
(curl exit=0)

### v2.3.0: $ curl -s -i http://127.0.0.1:28081/get_transaction_pool_hashes.bin
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 81
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 12:50:05 GMT
Accept-Ranges: bytes

{
  "credits": 0,
  "status": "OK",
  "top_hash": "",
  "untrusted": false
}
(curl exit=0)

### v2.3.0: $ curl -s -i http://127.0.0.1:28081/get_info
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 1225
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 12:50:05 GMT
Accept-Ranges: bytes

{
  "adjusted_time": 1793883005,
  "alt_blocks_count": 0,
  "block_size_limit": 600000,
  "block_size_median": 300000,
  "block_weight_limit": 600000,
  "block_weight_median": 300000,
  "bootstrap_daemon_address": "",
  "busy_syncing": false,
  "credits": 0,
  "cumulative_difficulty": 1,
  "cumulative_difficulty_top64": 0,
  "database_size": 5368709120,
  "difficulty": 1,
  "difficulty_top64": 0,
  "free_space": 18446744073709551615,
  "grey_peerlist_size": 0,
  "height": 1,
  "height_without_bootstrap": 0,
  "incoming_connections_count": 0,
  "mainnet": true,
  "nettype": "mainnet",
  "offline": true,
  "outgoing_connections_count": 0,
  "restricted": true,
  "rpc_connections_count": 0,
  "stagenet": false,
  "start_time": 0,
  "status": "OK",
  "synchronized": true,
  "target": 120,
  "target_height": 0,
  "testnet": false,
  "top_block_hash": "f53afd86c39b60858bd5fc9ea9f4b8e688f79c2b0158b211463bb34494730505",
  "top_hash": "",
  "tx_count": 0,
  "tx_pool_size": 0,
  "untrusted": false,
  "update_available": false,
  "version": "",
  "was_bootstrap_ever_used": false,
  "white_peerlist_size": 0,
  "wide_cumulative_difficulty": "0x1",
  "wide_difficulty": "0x1"
}
(curl exit=0)

### sec2: $ curl -s -i http://127.0.0.1:28181/get_transaction_pool
HTTP/1.1 404 Not found
Server: Epee-based
Content-Length: 0
Content-Type: text/plain
Last-Modified: Thu, 05 Nov 2026 12:50:05 GMT
Accept-Ranges: bytes


(curl exit=0)

### sec2: $ curl -s -i http://127.0.0.1:28181/get_alt_blocks_hashes
HTTP/1.1 404 Not found
Server: Epee-based
Content-Length: 0
Content-Type: text/plain
Last-Modified: Thu, 05 Nov 2026 12:50:05 GMT
Accept-Ranges: bytes


(curl exit=0)

### sec2: $ curl -s -i http://127.0.0.1:28181/get_transaction_pool_hashes.bin
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 81
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 12:50:05 GMT
Accept-Ranges: bytes

{
  "credits": 0,
  "status": "OK",
  "top_hash": "",
  "untrusted": false
}
(curl exit=0)

### sec2: $ curl -s -i http://127.0.0.1:28181/get_info
HTTP/1.1 200 Ok
Server: Epee-based
Content-Length: 1225
Content-Type: application/json
Last-Modified: Thu, 05 Nov 2026 12:50:05 GMT
Accept-Ranges: bytes

{
  "adjusted_time": 1793883005,
  "alt_blocks_count": 0,
  "block_size_limit": 600000,
  "block_size_median": 300000,
  "block_weight_limit": 600000,
  "block_weight_median": 300000,
  "bootstrap_daemon_address": "",
  "busy_syncing": false,
  "credits": 0,
  "cumulative_difficulty": 1,
  "cumulative_difficulty_top64": 0,
  "database_size": 5368709120,
  "difficulty": 1,
  "difficulty_top64": 0,
  "free_space": 18446744073709551615,
  "grey_peerlist_size": 0,
  "height": 1,
  "height_without_bootstrap": 0,
  "incoming_connections_count": 0,
  "mainnet": true,
  "nettype": "mainnet",
  "offline": true,
  "outgoing_connections_count": 0,
  "restricted": true,
  "rpc_connections_count": 0,
  "stagenet": false,
  "start_time": 0,
  "status": "OK",
  "synchronized": true,
  "target": 120,
  "target_height": 0,
  "testnet": false,
  "top_block_hash": "f53afd86c39b60858bd5fc9ea9f4b8e688f79c2b0158b211463bb34494730505",
  "top_hash": "",
  "tx_count": 0,
  "tx_pool_size": 0,
  "untrusted": false,
  "update_available": false,
  "version": "",
  "was_bootstrap_ever_used": false,
  "white_peerlist_size": 0,
  "wide_cumulative_difficulty": "0x1",
  "wide_difficulty": "0x1"
}
(curl exit=0)

## ZMQ: ModuleNotFoundError: No module named 'zmq'
## stop 2026-11-05T12:50:05Z
kill v2.3.0 pid 97073
kill sec2 pid 97127
v2.3.0 pid 97073 exited after 3s
sec2 pid 97127 exited after 1s
112K	~/tmp/zeph-r4/data-v2.3.0
112K	~/tmp/zeph-r4/data-sec2
## end 2026-11-05T12:50:07Z
```

## ZMQ (2026-11-05, round 8)
pyzmq 26.4.0 (libzmq 4.3.5). Daemons: upstream v2.3.0 and `wip/sec.2` built from `16018bb0b` (the final
tip `dce3c58d2` differs from it only in `SECURITY-BACKPORTS.md`), started as above with fresh data
directories, ZMQ-RPC on 127.0.0.1:28082 (v2.3.0) and 127.0.0.1:28182 (sec2), 5 s send/receive timeout
per step, a fresh REQ socket per step.

### Run 1, as prescribed (single-frame oversized request)
Steps: (a) `{"jsonrpc":"2.0","id":0,"method":"get_info"}`; (b) one 11 MiB message (`b"x"*11534336`,
a single frame); (c) `get_info` again on a fresh socket.

| step | v2.3.0 | sec2 |
|---|---|---|
| (a) | reply, `"Malformed json"`, `Key "params" missing from object.` | the same |
| (b) single 11 MiB frame | TIMEOUT after 5.02 s | TIMEOUT after 5.01 s |
| (c) | reply (same "Malformed json" as (a)) | the same |

Both daemons behave the same: both set `ZMQ_MAXMSGSIZE` = 10 MiB per frame on the ZMQ-RPC socket
(`src/rpc/zmq_server.cpp`, in both trees), so libzmq refuses the single 11 MiB frame before the
daemon's receive loop sees it; no reply, nothing in either log, and both keep serving. The request
of (a) has no `params` field, which both daemons reject as malformed. This run does not reach the
code of the picks.

### Run 2, extra: multipart oversized request
Steps: (a') `get_info` with `"params":{}`; (b') one multipart message of 11 parts × 1 MiB (each part
below the per-frame limit, 11 MiB in total); (c') `get_info` with params again on a fresh socket.

| step | v2.3.0 | sec2 |
|---|---|---|
| (a') | `result` with `info` (height 1) | the same |
| (b') 11 × 1 MiB multipart | reply after 0.03 s: `"error_str":"Malformed json","message":"Failed to parse the json request"` (the 11 MiB were received and parsed) | reply after 0.05 s: `"error_str":"Request too large","message":"Request exceeds maximum message size."`; daemon log: `ERROR net.zmq src/rpc/zmq_server.cpp:176 ZMQ-RPC request exceeds maximum message size` |
| (c') | `result` with `info` | `result` with `info` |
| HTTP `/get_info` afterwards | answers | answers |

sec2 caps the aggregate size of a multipart request (`4f6652f35`), answers it with the new
"Request too large" error and keeps serving (`d1508916b`). The control accepts the 11 MiB message,
fails to parse it and keeps serving; its server loop did not end in this test.

### Output, verbatim
Run 1 (`~/tmp/zeph-r4/zmq-check.py`):
```
## start 2026-11-05T15:24:10Z; pyzmq 26.4.0 libzmq 4.3.5
$ (cd ~/tmp/zeph-r4/zephyr-v2.3.0/build && ./bin/zephyrd --offline --restricted-rpc --no-igd --data-dir ~/tmp/zeph-r4/data-zmq-v2.3.0 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28081 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28082 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28080 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-zmq-v2.3.0.pid --log-file ~/tmp/zeph-r4/zephyrd-zmq-v2.3.0.log)
2026-11-05 15:24:11.049	I Moving from main() into the daemonize now.
Forking to background...
rpc up after 4s
$ (cd ~/tmp/zeph-r4/zephyr-sec2/build && ./bin/zephyrd --offline --restricted-rpc --no-igd --data-dir ~/tmp/zeph-r4/data-zmq-sec2 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28181 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28182 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28180 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-zmq-sec2.pid --log-file ~/tmp/zeph-r4/zephyrd-zmq-sec2.log)
2026-11-05 15:24:14.229	I Moving from main() into the daemonize now.
Forking to background...
rpc up after 3s
LISTEN 0      100                                 127.0.0.1:28182      0.0.0.0:*    users:(("zephyrd",pid=114549,fd=20))      
LISTEN 0      4096                                127.0.0.1:28181      0.0.0.0:*    users:(("zephyrd",pid=114549,fd=13))      
LISTEN 0      100                                 127.0.0.1:28082      0.0.0.0:*    users:(("zephyrd",pid=114497,fd=20))      
LISTEN 0      4096                                127.0.0.1:28081      0.0.0.0:*    users:(("zephyrd",pid=114497,fd=13))      

### v2.3.0: $ python3 ~/tmp/zeph-r4/zmq-check.py 28082   (2026-11-05T15:24:16Z)
a) get_info: reply after 0.00s, 123 bytes: b'{"jsonrpc":"2.0","id":null,"error":{"code":1,"error_str":"Malformed json","message":"Key \\"params\\" missing from object."}}'
b) 11 MiB message: TIMEOUT after 5.02s
c) get_info again (fresh socket): reply after 0.00s, 123 bytes: b'{"jsonrpc":"2.0","id":null,"error":{"code":1,"error_str":"Malformed json","message":"Key \\"params\\" missing from object."}}'
### v2.3.0: $ curl -s http://127.0.0.1:28081/get_info | head -3
{
  "adjusted_time": 1793892261,
  "alt_blocks_count": 0,
(curl exit=0)
v2.3.0 daemon pid 114497 still running

### sec2: $ python3 ~/tmp/zeph-r4/zmq-check.py 28182   (2026-11-05T15:24:21Z)
a) get_info: reply after 0.00s, 123 bytes: b'{"jsonrpc":"2.0","id":null,"error":{"code":1,"error_str":"Malformed json","message":"Key \\"params\\" missing from object."}}'
b) 11 MiB message: TIMEOUT after 5.01s
c) get_info again (fresh socket): reply after 0.00s, 123 bytes: b'{"jsonrpc":"2.0","id":null,"error":{"code":1,"error_str":"Malformed json","message":"Key \\"params\\" missing from object."}}'
### sec2: $ curl -s http://127.0.0.1:28181/get_info | head -3
{
  "adjusted_time": 1793892266,
  "alt_blocks_count": 0,
(curl exit=0)
sec2 daemon pid 114549 still running

## daemon log lines mentioning ZMQ (after start-up)
--- v2.3.0
2026-11-05 15:24:11.052	    7fdf1c1d5ec0	INFO	global	src/cryptonote_core/cryptonote_core.cpp:515	Loading blockchain from folder ~/tmp/zeph-r4/data-zmq-v2.3.0/lmdb ...
2026-11-05 15:24:13.337	    7fdf1c1d5ec0	INFO	net.zmq	src/rpc/zmq_server.cpp:85	ZMQ now listening at tcp://127.0.0.1:28082
2026-11-05 15:24:13.338	    7fdeb3ffe6c0	INFO	net.zmq	src/rpc/zmq_server.cpp:128	ZMQ Server started
--- sec2
2026-11-05 15:24:14.232	    7607b5c7fec0	INFO	global	src/cryptonote_core/cryptonote_core.cpp:515	Loading blockchain from folder ~/tmp/zeph-r4/data-zmq-sec2/lmdb ...
2026-11-05 15:24:15.386	    7607b5c7fec0	INFO	net.zmq	src/rpc/zmq_server.cpp:86	ZMQ now listening at tcp://127.0.0.1:28182
2026-11-05 15:24:15.387	    76074d7f96c0	INFO	net.zmq	src/rpc/zmq_server.cpp:129	ZMQ Server started

## stop 2026-11-05T15:24:26Z
kill v2.3.0 pid 114497
kill sec2 pid 114549
v2.3.0 pid 114497 exited after 3s
sec2 pid 114549 exited after 1s
## end 2026-11-05T15:24:28Z
```

Run 2 (`~/tmp/zeph-r4/zmq-check-multipart.py`):
```
## start 2026-11-05T15:25:09Z; pyzmq 26.4.0 libzmq 4.3.5
$ (cd ~/tmp/zeph-r4/zephyr-v2.3.0/build && ./bin/zephyrd --offline --restricted-rpc --no-igd --data-dir ~/tmp/zeph-r4/data-zmq-v2.3.0 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28081 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28082 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28080 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-zmq-v2.3.0.pid --log-file ~/tmp/zeph-r4/zephyrd-zmq-v2.3.0.log)
2026-11-05 15:25:09.861	I Moving from main() into the daemonize now.
Forking to background...
rpc up after 2s
$ (cd ~/tmp/zeph-r4/zephyr-sec2/build && ./bin/zephyrd --offline --restricted-rpc --no-igd --data-dir ~/tmp/zeph-r4/data-zmq-sec2 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28181 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28182 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28180 --log-level 1 --non-interactive --detach --pidfile ~/tmp/zeph-r4/zephyrd-zmq-sec2.pid --log-file ~/tmp/zeph-r4/zephyrd-zmq-sec2.log)
2026-11-05 15:25:11.008	I Moving from main() into the daemonize now.
Forking to background...
rpc up after 3s
LISTEN 0      100                                 127.0.0.1:28182      0.0.0.0:*    users:(("zephyrd",pid=114793,fd=20))      
LISTEN 0      4096                                127.0.0.1:28181      0.0.0.0:*    users:(("zephyrd",pid=114793,fd=13))      
LISTEN 0      100                                 127.0.0.1:28082      0.0.0.0:*    users:(("zephyrd",pid=114762,fd=20))      
LISTEN 0      4096                                127.0.0.1:28081      0.0.0.0:*    users:(("zephyrd",pid=114762,fd=13))      

### v2.3.0: $ python3 ~/tmp/zeph-r4/zmq-check-multipart.py 28082   (2026-11-05T15:25:13Z)
a') get_info with params: reply after 0.00s, 614 bytes: b'{"jsonrpc":"2.0","id":0,"result":{"rpc_version":131072,"info":{"height":1,"target_height":1,"difficulty":1,"target":120,"tx_count":0,"tx_pool_size":0,"alt_blocks_count":0,"outgoing_connections_count":0,"incoming_connections_count":0,"white_peerlist_size":0,"grey_peerlist_size":0,"mainnet":true,"test'
b') 11 x 1 MiB multipart message: reply after 0.03s, 120 bytes: b'{"jsonrpc":"2.0","id":null,"error":{"code":1,"error_str":"Malformed json","message":"Failed to parse the json request"}}'
c') get_info with params again (fresh socket): reply after 0.00s, 614 bytes: b'{"jsonrpc":"2.0","id":1,"result":{"rpc_version":131072,"info":{"height":1,"target_height":1,"difficulty":1,"target":120,"tx_count":0,"tx_pool_size":0,"alt_blocks_count":0,"outgoing_connections_count":0,"incoming_connections_count":0,"white_peerlist_size":0,"grey_peerlist_size":0,"mainnet":true,"test'
### v2.3.0: $ curl -s http://127.0.0.1:28081/get_info | head -3
{
  "adjusted_time": 1793892313,
  "alt_blocks_count": 0,
(curl exit=0)
v2.3.0 daemon pid 114762 still running

### sec2: $ python3 ~/tmp/zeph-r4/zmq-check-multipart.py 28182   (2026-11-05T15:25:13Z)
a') get_info with params: reply after 0.00s, 614 bytes: b'{"jsonrpc":"2.0","id":0,"result":{"rpc_version":131072,"info":{"height":1,"target_height":1,"difficulty":1,"target":120,"tx_count":0,"tx_pool_size":0,"alt_blocks_count":0,"outgoing_connections_count":0,"incoming_connections_count":0,"white_peerlist_size":0,"grey_peerlist_size":0,"mainnet":true,"test'
b') 11 x 1 MiB multipart message: reply after 0.05s, 128 bytes: b'{"jsonrpc":"2.0","id":null,"error":{"code":1,"error_str":"Request too large","message":"Request exceeds maximum message size."}}'
c') get_info with params again (fresh socket): reply after 0.00s, 614 bytes: b'{"jsonrpc":"2.0","id":1,"result":{"rpc_version":131072,"info":{"height":1,"target_height":1,"difficulty":1,"target":120,"tx_count":0,"tx_pool_size":0,"alt_blocks_count":0,"outgoing_connections_count":0,"incoming_connections_count":0,"white_peerlist_size":0,"grey_peerlist_size":0,"mainnet":true,"test'
### sec2: $ curl -s http://127.0.0.1:28181/get_info | head -3
{
  "adjusted_time": 1793892313,
  "alt_blocks_count": 0,
(curl exit=0)
sec2 daemon pid 114793 still running

## daemon log lines mentioning ZMQ (after start-up)
--- v2.3.0
2026-11-05 15:24:11.052	    7fdf1c1d5ec0	INFO	global	src/cryptonote_core/cryptonote_core.cpp:515	Loading blockchain from folder ~/tmp/zeph-r4/data-zmq-v2.3.0/lmdb ...
2026-11-05 15:24:13.337	    7fdf1c1d5ec0	INFO	net.zmq	src/rpc/zmq_server.cpp:85	ZMQ now listening at tcp://127.0.0.1:28082
2026-11-05 15:24:13.338	    7fdeb3ffe6c0	INFO	net.zmq	src/rpc/zmq_server.cpp:128	ZMQ Server started
2026-11-05 15:25:09.863	    79519d42cec0	INFO	global	src/cryptonote_core/cryptonote_core.cpp:515	Loading blockchain from folder ~/tmp/zeph-r4/data-zmq-v2.3.0/lmdb ...
2026-11-05 15:25:10.668	    79519d42cec0	INFO	net.zmq	src/rpc/zmq_server.cpp:85	ZMQ now listening at tcp://127.0.0.1:28082
2026-11-05 15:25:10.669	    795134ff86c0	INFO	net.zmq	src/rpc/zmq_server.cpp:128	ZMQ Server started
--- sec2
2026-11-05 15:24:14.232	    7607b5c7fec0	INFO	global	src/cryptonote_core/cryptonote_core.cpp:515	Loading blockchain from folder ~/tmp/zeph-r4/data-zmq-sec2/lmdb ...
2026-11-05 15:24:15.386	    7607b5c7fec0	INFO	net.zmq	src/rpc/zmq_server.cpp:86	ZMQ now listening at tcp://127.0.0.1:28182
2026-11-05 15:24:15.387	    76074d7f96c0	INFO	net.zmq	src/rpc/zmq_server.cpp:129	ZMQ Server started
2026-11-05 15:25:11.012	    729b06494ec0	INFO	global	src/cryptonote_core/cryptonote_core.cpp:515	Loading blockchain from folder ~/tmp/zeph-r4/data-zmq-sec2/lmdb ...
2026-11-05 15:25:12.628	    729b06494ec0	INFO	net.zmq	src/rpc/zmq_server.cpp:86	ZMQ now listening at tcp://127.0.0.1:28182
2026-11-05 15:25:12.629	    729a9dffa6c0	INFO	net.zmq	src/rpc/zmq_server.cpp:129	ZMQ Server started
2026-11-05 15:25:13.425	    729a9dffa6c0	ERROR	net.zmq	src/rpc/zmq_server.cpp:176	ZMQ-RPC request exceeds maximum message size

## stop 2026-11-05T15:25:13Z
kill v2.3.0 pid 114762
kill sec2 pid 114793
v2.3.0 pid 114762 exited after 2s
sec2 pid 114793 exited after 1s
## end 2026-11-05T15:25:14Z
```

Script of run 2:
```python
# Extra to WORKORDER round 8 task 1 (same structure, two changes): a valid get_info (with "params"),
# and the oversized request as ONE multipart message of 11 parts x 1 MiB, each part below the
# 10 MiB per-frame ZMQ_MAXMSGSIZE both daemons set, 11 MiB in total.
import sys, zmq, json, time
port = int(sys.argv[1]); ctx = zmq.Context()
def req(parts, label):
    s = ctx.socket(zmq.REQ); s.setsockopt(zmq.LINGER, 0); s.setsockopt(zmq.RCVTIMEO, 5000); s.setsockopt(zmq.SNDTIMEO, 5000)
    s.connect(f"tcp://127.0.0.1:{port}")
    t = time.time()
    try:
        s.send_multipart(parts); r = s.recv()
        print(f"{label}: reply after {time.time()-t:.2f}s, {len(r)} bytes: {r[:300]!r}")
    except zmq.error.Again:
        print(f"{label}: TIMEOUT after {time.time()-t:.2f}s")
    finally:
        s.close()
GI = lambda i: json.dumps({"jsonrpc":"2.0","id":i,"method":"get_info","params":{}}).encode()
req([GI(0)], "a') get_info with params")
req([b"x" * 1048576] * 11, "b') 11 x 1 MiB multipart message")
req([GI(1)], "c') get_info with params again (fresh socket)")
```
