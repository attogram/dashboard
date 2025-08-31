# Crypto Donations Module

The Crypto Donations module allows you to display the balances of your public cryptocurrency wallets on the dashboard. It is highly flexible, allowing you to fetch balances from different sources (or "providers"), such as public APIs or your own self-hosted nodes.

## Configuration

Configuring the module involves three parts: setting up API keys (if needed), configuring providers for each cryptocurrency, and listing the wallet addresses you want to track.

### 1. Providers

There are three types of providers available:

- **`local`**: Uses a local, self-hosted node for the blockchain. This is the most private and robust option. Currently, this is only supported for Bitcoin via `bitcoin-cli`.
- **`blockcypher`**: Uses the free tier of the [BlockCypher API](https://www.blockcypher.com). This is the recommended provider for its supported chains, as it does not require an API key for simple balance lookups. It supports BTC, ETH, LTC, DASH, and DOGE.
- **`covalent`**: Uses the [Covalent API](https://www.covalenthq.com/platform/). This provider supports a very wide variety of EVM-compatible chains but requires an API key. Note that the free tier for Covalent may be time-limited.

### 2. API Keys (Optional)

Some providers require an API key. You should add these to your `config.sh` file if you intend to use them.

```bash
# (Optional) Your Covalent API Key. Required for the "covalent" provider.
COVALENT_API_KEY="cqt_YOUR_API_KEY"

# (Optional) Your BlockCypher API Token. Not required for balance checks,
# but can be used to get higher rate limits.
BLOCKCYPHER_TOKEN=""
```

### 3. Wallet and Provider Configuration

For each cryptocurrency you want to track, you need to add a `CRYPTO_WALLET_<TICKER>` variable to your `config.sh`.

You can also specify which provider to use for each ticker with a `CRYPTO_<TICKER>_PROVIDER` variable. If you don't specify a provider for a coin, the module will use a sensible default (`blockcypher` for supported coins, `covalent` otherwise).

Here is an example configuration demonstrating different setups:

```bash
# --- Provider Configuration ---
# Use a local Bitcoin node. The address in CRYPTO_WALLET_BTC will be ignored.
CRYPTO_BTC_PROVIDER="local"

# Use BlockCypher for Ethereum (this is the default, so this line is optional)
CRYPTO_ETH_PROVIDER="blockcypher"

# Use Covalent for Polygon (MATIC)
CRYPTO_MATIC_PROVIDER="covalent"


# --- Wallet Addresses ---
# The CRYPTO_WALLET_ variable must be present for the module to track the chain.
CRYPTO_WALLET_BTC="your_local_wallet"
CRYPTO_WALLET_ETH="0x..."
CRYPTO_WALLET_MATIC="0x..."
CRYPTO_WALLET_LTC="ltc1..." # This will use the default provider (blockcypher)
```

## Output Example

Here is an example of what the output from this module looks like in the `plain` format, based on the configuration above.

```
Crypto Donations
BTC (local node (my-wallet-name))
  - BTC: 1.50000000
ETH (0x...)
  - ETH: 2.123
LTC (ltc1...)
  - LTC: 10.5
MATIC (0x...)
  - MATIC: 150.75
  - USDC: 250.00
```
