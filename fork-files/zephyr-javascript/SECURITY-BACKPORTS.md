# Security backports

Base: `ZephyrProtocol/zephyr-javascript` commit `9d022ded` ("Updates for version 2.3.0", 2025-06-16;
the state the Zephyr v2.3.0 wallets were built from), itself on `woodser/monero-javascript` `1dd86702`
(2023-06-09). Policy: https://github.com/zephyr-backports/zephyr-backports (docs/POLICY.md). Each entry
is one cherry-picked monero-ts commit into the C++ bridge, one dependency pin (trailer `Advisory:`) or one
artefact rebuild (trailers `Built-From:`); the Type column is `pick`, `pin` or `artefact`.

| # | Tag | Type | Advisory / source | Component | Summary |
|---|---|---|---|---|---|

## Advisories

<!-- One section per change; template: docs/ADVISORY-TEMPLATE.md in zephyr-backports/zephyr-backports -->
