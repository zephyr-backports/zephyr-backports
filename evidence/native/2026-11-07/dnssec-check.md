# DNSSEC root key check, 2026-11-07

SB-010 (`e62963ceb`, "dns_util: add new DNSSEC trust anchor"). The root zone's key-signing key was
rolled over from KSK-2017 (key tag 20326) to KSK-2024 (key tag 38696) on 2026-10-11, per the work
order. A resolver that knows only the old trust anchor can no longer validate DNSSEC answers.
`zephyrd` uses DNSSEC-validated TXT records for its update check (`updates.moneropulse.org`) and its
DNS blocklist (`blocklist.moneropulse.*`, `--enable-dns-blocklist`); both run with `--offline`.

The two daemons were started one after the other, never together. Each ran 90 s with `--offline`
(no p2p), RPC on 127.0.0.1:28481 and ZMQ on 127.0.0.1:28482, and was then stopped. The resolver
is the machine's (`127.0.0.53`), with the daemon's own fallback to its well-known resolvers. The home
directory is written as `~`; colour codes are removed.

## Runs
```
### control START 2026-11-07T00:50:34Z Zephyr 'Version 2.3' (v2.3.0-release)
$ ~/tmp/zeph-r4/zephyr-v2.3.0/build/bin/zephyrd --offline --enable-dns-blocklist --log-level 2 --log-file ~/tmp/zeph-r4/dns-control.log --data-dir ~/tmp/zeph-r4/data-dns-control --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28481 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28480 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28482 --no-igd --non-interactive --detach --pidfile ~/tmp/zeph-r4/dns-control.pid
2026-11-07 00:50:35.139	D Created directory: ~/tmp/zeph-r4/data-dns-control
2026-11-07 00:50:35.139	I Zephyr 'Version 2.3' (v2.3.0-release)
2026-11-07 00:50:35.139	I Moving from main() into the daemonize now.
Forking to background...
pid 636996
listening sockets: 2
kill 636996 at 2026-11-07T00:52:05Z
exited by 2026-11-07T00:52:07Z
### control END
### sec2 START 2026-11-07T00:52:07Z Zephyr 'Version 2.3' (v2.3.0-16018bb0b)
$ ~/tmp/zeph-r4/zephyr-sec2/build/bin/zephyrd --offline --enable-dns-blocklist --log-level 2 --log-file ~/tmp/zeph-r4/dns-sec2.log --data-dir ~/tmp/zeph-r4/data-dns-sec2 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28481 --p2p-bind-ip 127.0.0.1 --p2p-bind-port 28480 --zmq-rpc-bind-ip 127.0.0.1 --zmq-rpc-bind-port 28482 --no-igd --non-interactive --detach --pidfile ~/tmp/zeph-r4/dns-sec2.pid
2026-11-07 00:52:07.545	D Created directory: ~/tmp/zeph-r4/data-dns-sec2
2026-11-07 00:52:07.545	I Zephyr 'Version 2.3' (v2.3.0-16018bb0b)
2026-11-07 00:52:07.545	I Moving from main() into the daemonize now.
Forking to background...
pid 639516
listening sockets: 2
kill 639516 at 2026-11-07T00:53:37Z
exited by 2026-11-07T00:53:38Z
### sec2 END
```
Bind lines from the logs:
```
2026-11-07 00:50:35.789	    7103bb257ec0	INFO	global	contrib/epee/include/net/http_server_impl_base.h:79	Binding on 127.0.0.1 (IPv4):28481
2026-11-07 00:50:37.663	    7103bb257ec0	INFO	net.zmq	src/rpc/zmq_server.cpp:85	ZMQ now listening at tcp://127.0.0.1:28482
2026-11-07 00:52:07.907	    765070951ec0	INFO	global	contrib/epee/include/net/http_server_impl_base.h:79	Binding on 127.0.0.1 (IPv4):28481
2026-11-07 00:52:08.645	    765070951ec0	INFO	net.zmq	src/rpc/zmq_server.cpp:86	ZMQ now listening at tcp://127.0.0.1:28482
```

## Result
| | control, upstream v2.3.0 | sec2, `16018bb0b` |
|---|---|---|
| trust anchors loaded | `DS 20326` only | `DS 20326` and `DS 38696` |
| `updates.moneropulse.org` | `Invalid DNSSEC TXT record signature … validation failure … signature for expected key and algorithm missing`, then `falling back to TCP with well known DNSSEC resolvers` | no validation warning |
| blocklist, 7 hosts | each `validation failure`; `DNSSEC validation failed for hostname … skipping` × 7; `WARNING: no two valid DNS TXT records were received` | `Found 4/7 matching records from 6 valid records` |
| blocklist applied | no (no `addresses added` line) | `431 addresses added to the blocklist` |

**Shown:** after the root key rollover, the upstream daemon fails DNSSEC validation for every TXT record and
applies no blocklist. The sec2 daemon, with the added KSK-2024 anchor, validates the records and applies
the blocklist. Both logs have 19 to 29 `Found TXT record` lines per host: the records arrive in both
cases, and only the control cannot validate them.

## Every matching line, control (`grep -E 'dns|DNS|blocklist|DNSSEC|validat' ~/tmp/zeph-r4/dns-control.log`)
Three lines match only through the data directory path `data-dns-control`, and one only through `Invalidating`.
```
2026-11-07 00:50:35.139	    7103bb257ec0	DEBUG	util	src/common/util.cpp:366	Created directory: ~/tmp/zeph-r4/data-dns-control
2026-11-07 00:50:35.143	    7103bb257ec0	INFO	global	src/cryptonote_core/cryptonote_core.cpp:515	Loading blockchain from folder ~/tmp/zeph-r4/data-dns-control/lmdb ...
2026-11-07 00:50:35.781	    7103bb257ec0	DEBUG	blockchain	src/cryptonote_core/blockchain.cpp:6128	Invalidating block template cache
2026-11-07 00:50:38.666	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:221	adding trust anchor: . IN DS 20326 8 2 E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D
2026-11-07 00:50:38.666	    71032abfb6c0	DEBUG	net.dns	src/common/dns_utils.cpp:310	Performing DNSSEC TXT record query for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	WARNING	net.dns	src/common/dns_utils.cpp:319	Invalid DNSSEC TXT record signature for updates.moneropulse.org: validation failure <updates.moneropulse.org. TXT IN>: signature for expected key and algorithm missing from 127.0.0.53 for trust anchor . while building chain of trust
2026-11-07 00:50:38.749	    71032abfb6c0	WARNING	net.dns	src/common/dns_utils.cpp:320	Possibly your DNS service is problematic. You can have monerod use an alternate via env variable DNS_PUBLIC. Example: DNS_PUBLIC=tcp://9.9.9.9
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for updates.moneropulse.org
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:273	Failed to verify DNSSEC record from updates.moneropulse.org, falling back to TCP with well known DNSSEC resolvers
2026-11-07 00:50:38.749	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:221	adding trust anchor: . IN DS 20326 8 2 E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D
2026-11-07 00:50:38.749	    71032abfb6c0	DEBUG	net.dns	src/common/dns_utils.cpp:310	Performing DNSSEC TXT record query for blocklist.moneropulse.se
2026-11-07 00:50:38.749	    71032a6fa6c0	DEBUG	net.dns	src/common/dns_utils.cpp:310	Performing DNSSEC TXT record query for blocklist.moneropulse.org
2026-11-07 00:50:38.749	    7103297f76c0	DEBUG	net.dns	src/common/dns_utils.cpp:310	Performing DNSSEC TXT record query for blocklist.moneropulse.de
2026-11-07 00:50:38.750	    71032a1f96c0	DEBUG	net.dns	src/common/dns_utils.cpp:310	Performing DNSSEC TXT record query for blocklist.moneropulse.ch
2026-11-07 00:50:38.750	    7103292f66c0	DEBUG	net.dns	src/common/dns_utils.cpp:310	Performing DNSSEC TXT record query for blocklist.moneropulse.fr
2026-11-07 00:50:38.750	    710329cf86c0	DEBUG	net.dns	src/common/dns_utils.cpp:310	Performing DNSSEC TXT record query for blocklist.moneropulse.no
2026-11-07 00:50:38.750	    710328df56c0	DEBUG	net.dns	src/common/dns_utils.cpp:310	Performing DNSSEC TXT record query for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	WARNING	net.dns	src/common/dns_utils.cpp:319	Invalid DNSSEC TXT record signature for blocklist.moneropulse.net: validation failure <blocklist.moneropulse.net. TXT IN>: signature for expected key and algorithm missing from 109.69.8.51 for trust anchor . while building chain of trust
2026-11-07 00:50:38.834	    710328df56c0	WARNING	net.dns	src/common/dns_utils.cpp:320	Possibly your DNS service is problematic. You can have monerod use an alternate via env variable DNS_PUBLIC. Example: DNS_PUBLIC=tcp://9.9.9.9
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.834	    710328df56c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:50:38.838	    710329cf86c0	WARNING	net.dns	src/common/dns_utils.cpp:319	Invalid DNSSEC TXT record signature for blocklist.moneropulse.no: validation failure <blocklist.moneropulse.no. TXT IN>: signature for expected key and algorithm missing from 194.150.168.168 for trust anchor . while building chain of trust
2026-11-07 00:50:38.838	    710329cf86c0	WARNING	net.dns	src/common/dns_utils.cpp:320	Possibly your DNS service is problematic. You can have monerod use an alternate via env variable DNS_PUBLIC. Example: DNS_PUBLIC=tcp://9.9.9.9
2026-11-07 00:50:38.838	    7103297f76c0	WARNING	net.dns	src/common/dns_utils.cpp:319	Invalid DNSSEC TXT record signature for blocklist.moneropulse.de: validation failure <blocklist.moneropulse.de. TXT IN>: signature for expected key and algorithm missing from 80.67.169.40 for trust anchor . while building chain of trust
2026-11-07 00:50:38.838	    7103297f76c0	WARNING	net.dns	src/common/dns_utils.cpp:320	Possibly your DNS service is problematic. You can have monerod use an alternate via env variable DNS_PUBLIC. Example: DNS_PUBLIC=tcp://9.9.9.9
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.838	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.839	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.839	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.839	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.839	    7103297f76c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:50:38.841	    71032abfb6c0	WARNING	net.dns	src/common/dns_utils.cpp:319	Invalid DNSSEC TXT record signature for blocklist.moneropulse.se: validation failure <blocklist.moneropulse.se. TXT IN>: signature for expected key and algorithm missing from 193.58.251.251 for trust anchor . while building chain of trust
2026-11-07 00:50:38.841	    71032abfb6c0	WARNING	net.dns	src/common/dns_utils.cpp:320	Possibly your DNS service is problematic. You can have monerod use an alternate via env variable DNS_PUBLIC. Example: DNS_PUBLIC=tcp://9.9.9.9
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.841	    71032abfb6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:50:38.845	    71032a6fa6c0	WARNING	net.dns	src/common/dns_utils.cpp:319	Invalid DNSSEC TXT record signature for blocklist.moneropulse.org: validation failure <blocklist.moneropulse.org. TXT IN>: signature for expected key and algorithm missing from 194.150.168.168 for trust anchor . while building chain of trust
2026-11-07 00:50:38.845	    71032a6fa6c0	WARNING	net.dns	src/common/dns_utils.cpp:320	Possibly your DNS service is problematic. You can have monerod use an alternate via env variable DNS_PUBLIC. Example: DNS_PUBLIC=tcp://9.9.9.9
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.845	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.846	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.846	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.846	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.846	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.846	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.846	    71032a6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:50:38.846	    7103292f66c0	WARNING	net.dns	src/common/dns_utils.cpp:319	Invalid DNSSEC TXT record signature for blocklist.moneropulse.fr: validation failure <blocklist.moneropulse.fr. TXT IN>: signature for expected key and algorithm missing from 109.69.8.51 for trust anchor . while building chain of trust
2026-11-07 00:50:38.846	    7103292f66c0	WARNING	net.dns	src/common/dns_utils.cpp:320	Possibly your DNS service is problematic. You can have monerod use an alternate via env variable DNS_PUBLIC. Example: DNS_PUBLIC=tcp://9.9.9.9
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    7103292f66c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:50:38.846	    71032a1f96c0	WARNING	net.dns	src/common/dns_utils.cpp:319	Invalid DNSSEC TXT record signature for blocklist.moneropulse.ch: validation failure <blocklist.moneropulse.ch. TXT IN>: signature for expected key and algorithm missing from 80.67.169.40 for trust anchor . while building chain of trust
2026-11-07 00:50:38.846	    71032a1f96c0	WARNING	net.dns	src/common/dns_utils.cpp:320	Possibly your DNS service is problematic. You can have monerod use an alternate via env variable DNS_PUBLIC. Example: DNS_PUBLIC=tcp://9.9.9.9
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.846	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.847	    71032a1f96c0	INFO	net.dns	src/common/dns_utils.cpp:330	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:50:38.847	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:513	DNSSEC validation failed for hostname: blocklist.moneropulse.ch, skipping.
2026-11-07 00:50:38.847	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:513	DNSSEC validation failed for hostname: blocklist.moneropulse.se, skipping.
2026-11-07 00:50:38.847	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:513	DNSSEC validation failed for hostname: blocklist.moneropulse.org, skipping.
2026-11-07 00:50:38.847	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:513	DNSSEC validation failed for hostname: blocklist.moneropulse.net, skipping.
2026-11-07 00:50:38.847	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:513	DNSSEC validation failed for hostname: blocklist.moneropulse.no, skipping.
2026-11-07 00:50:38.847	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:513	DNSSEC validation failed for hostname: blocklist.moneropulse.fr, skipping.
2026-11-07 00:50:38.847	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:513	DNSSEC validation failed for hostname: blocklist.moneropulse.de, skipping.
2026-11-07 00:50:38.847	[P2P1]	WARNING	net.dns	src/common/dns_utils.cpp:535	WARNING: no two valid DNS TXT records were received
2026-11-07 00:52:05.681	[SRV_MAIN]	DEBUG	util	src/common/util.cpp:366	Created directory: ~/tmp/zeph-r4/data-dns-control/28480
```

## Every matching line, sec2 (`grep -E 'dns|DNS|blocklist|DNSSEC|validat' ~/tmp/zeph-r4/dns-sec2.log`)
Three lines match only through the data directory path `data-dns-sec2`, and one only through `Invalidating`.
```
2026-11-07 00:52:07.545	    765070951ec0	DEBUG	util	src/common/util.cpp:366	Created directory: ~/tmp/zeph-r4/data-dns-sec2
2026-11-07 00:52:07.548	    765070951ec0	INFO	global	src/cryptonote_core/cryptonote_core.cpp:515	Loading blockchain from folder ~/tmp/zeph-r4/data-dns-sec2/lmdb ...
2026-11-07 00:52:07.903	    765070951ec0	DEBUG	blockchain	src/cryptonote_core/blockchain.cpp:6128	Invalidating block template cache
2026-11-07 00:52:09.648	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:222	adding trust anchor: . IN DS 20326 8 2 E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D
2026-11-07 00:52:09.648	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:222	adding trust anchor: . IN DS 38696 8 2 683D2D0ACB8C9B712A1948B27F741219298D0A450D612C483AF444A4C0FB2B16
2026-11-07 00:52:09.648	    764fcffff6c0	DEBUG	net.dns	src/common/dns_utils.cpp:311	Performing DNSSEC TXT record query for updates.moneropulse.org
2026-11-07 00:52:09.711	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.711	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.711	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.711	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.711	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.711	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.711	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for updates.moneropulse.org
2026-11-07 00:52:09.712	    764fcffff6c0	DEBUG	net.dns	src/common/dns_utils.cpp:311	Performing DNSSEC TXT record query for blocklist.moneropulse.se
2026-11-07 00:52:09.712	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:311	Performing DNSSEC TXT record query for blocklist.moneropulse.no
2026-11-07 00:52:09.712	    764fcfafe6c0	DEBUG	net.dns	src/common/dns_utils.cpp:311	Performing DNSSEC TXT record query for blocklist.moneropulse.net
2026-11-07 00:52:09.712	    764fce6fa6c0	DEBUG	net.dns	src/common/dns_utils.cpp:311	Performing DNSSEC TXT record query for blocklist.moneropulse.org
2026-11-07 00:52:09.712	    764fcf0fc6c0	DEBUG	net.dns	src/common/dns_utils.cpp:311	Performing DNSSEC TXT record query for blocklist.moneropulse.de
2026-11-07 00:52:09.712	    764fcebfb6c0	DEBUG	net.dns	src/common/dns_utils.cpp:311	Performing DNSSEC TXT record query for blocklist.moneropulse.fr
2026-11-07 00:52:09.712	    764fcf5fd6c0	DEBUG	net.dns	src/common/dns_utils.cpp:311	Performing DNSSEC TXT record query for blocklist.moneropulse.ch
2026-11-07 00:52:09.736	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.736	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.736	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.736	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.737	    764fce6fa6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.org
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.754	    764fcffff6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.se
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.756	    764fcebfb6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.fr
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcfafe6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.net
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.761	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.762	    764fcf0fc6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.de
2026-11-07 00:52:09.763	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.763	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.763	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.763	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.763	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	    764fcf5fd6c0	INFO	net.dns	src/common/dns_utils.cpp:331	Found TXT record for blocklist.moneropulse.ch
2026-11-07 00:52:09.764	[P2P1]	DEBUG	net.dns	src/common/dns_utils.cpp:555	Found 4/7 matching records from 6 valid records
2026-11-07 00:52:09.796	[P2P1]	INFO	net.p2p	src/p2p/net_node.inl:2062	431 addresses added to the blocklist
2026-11-07 00:53:37.663	[SRV_MAIN]	DEBUG	util	src/common/util.cpp:366	Created directory: ~/tmp/zeph-r4/data-dns-sec2/28480
```
