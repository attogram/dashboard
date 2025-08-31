# Crypto Donations Module

The Crypto Donations module allows you to display the balances of your public cryptocurrency wallets on the dashboard. It uses the [GoldRush API by Covalent](https://www.covalenthq.com/platform/) to fetch real-time balance data for a wide variety of blockchains.

## Configuration

To use this module, you need to configure two things in your `config.sh` file: your GoldRush API key and the wallet addresses you want to track.

### 1. GoldRush API Key

First, you need to get a free API key from the [GoldRush Platform](https://www.covalenthq.com/platform/). Once you have your key, add it to your `config.sh` file:

```bash
# Your GoldRush API Key from Covalent
GOLDRUSH_API_KEY="cqt_YOUR_API_KEY"
```

### 2. Wallet Addresses

Next, you need to add the wallet addresses you want to track. The module will automatically detect any variable that starts with `CRYPTO_WALLET_`. The format is `CRYPTO_WALLET_<TICKER>="your_address"`.

`<TICKER>` is a short code for the blockchain. Here is a list of supported tickers:

| Ticker  | Blockchain      |
| ------- | --------------- |
| `BTC`   | Bitcoin         |
| `ETH`   | Ethereum        |
| `MATIC` | Polygon         |
| `SOL`   | Solana          |
| `AVAX`  | Avalanche       |
| `ARB`   | Arbitrum        |
| `OP`    | Optimism        |
| `BASE`  | Base            |
| `FTM`   | Fantom          |
| `BNB`   | BNB Smart Chain |

Here is an example configuration for a few wallets:

```bash
# Your crypto wallet addresses
CRYPTO_WALLET_BTC="bc1q..."
CRYPTO_WALLET_ETH="0x..."
CRYPTO_WALLET_MATIC="0x..."
```

The module will fetch the balance for every token held in each of these wallets.

## Output Example

Here is an example of what the output from this module looks like in the `plain` format.

```
Crypto Donations
BTC (bc1q...)
  - BTC: 0.05
ETH (0x...)
  - ETH: 1.234
  - USDC: 50.12
```

And here is the `json` output for the same data:

```json
"crypto": [
  {
    "chain": "BTC",
    "address": "bc1q...",
    "tokens": [
      {
        "symbol": "BTC",
        "balance": "0.05"
      }
    ]
  },
  {
    "chain": "ETH",
    "address": "0x...",
    "tokens": [
      {
        "symbol": "ETH",
        "balance": "1.234"
      },
      {
        "symbol": "USDC",
        "balance": "50.12"
      }
    ]
  }
]
```
