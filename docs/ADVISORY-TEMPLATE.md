### SB-NNN — <short title>

- **Tag:** v2.3.0-sec.N
- **Origin:** monero-project/monero `<full sha>` (<date>, "<subject>"), released in Monero vX.Y.Z
- **Class:** memory | secrets | funds | privacy | dos | dependency
- **Component:** wallet2 | epee | serialization | daemon (p2p/rpc/zmq) | both
- **Affects:** who is exposed (wallet users scanning the chain / nodes serving RPC / …) and how it is triggered (untrusted input from a node, on-chain data, a peer, …)
- **Impact:** what can happen without the fix, in one or two sentences, without exaggeration
- **Compatibility statement:** which rules of POLICY §4 were checked and how — no consensus/relay change (files touched: …), no wire change, no file-format change, parsing strictness only for never-valid input (full-chain scan: height 0 → <tip> on <date>, 0 rejections) / not applicable
- **Conflict resolution:** none | context-only in <files> (trailer in the commit)
- **Test evidence:** fork CI build <link>; webwallet harness run <date> (identical behaviour, cross-open both ways with upstream binary); other
- **Notes:** anything a reviewer or the ZephyrProtocol team should know
