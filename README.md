# EtherWallet
**EtherWallet** is an iOS toolbelt for interaction with the Ethereum network.

![language](https://img.shields.io/badge/Language-Swift-green)
[![CocoaPods](https://img.shields.io/badge/support-SwiftPackageManagr-green)](https://www.swift.org/getting-started/#using-the-package-manager)

![](Resource/Demo01.png)

For more specific usage, please refer to the [demo](https://github.com/smithSophiav/EtherWallet/tree/main/Demo)

### Swift Package Manager

```ruby
dependencies: [
    .package(url: "https://github.com/smithSophiav/EtherWallet.git", .upToNextMajor(from: "1.1.2"))
]
```
### Example usage in Swift Package Manager

```swift
import EtherWallet
```
## Quick Start

1. **Create and setup** (must be called before any other API; loads the JS bundle).

```swift
let etherWeb = EtherWeb()

// Async (recommended)
Task { @MainActor in
    let ready = await etherWeb.setup(showLog: false)
    if ready {
        // Call any EtherWeb API
    }
}

// Or with completion
etherWeb.setup(showLog: true) { success in
    if success {
        // Call any EtherWeb API
    }
}
```

2. **Call APIs** — All methods have both **completion-handler** and **async** variants. Use **async** when you are in an async context (e.g. `Task` or `async` function).

---

## API Reference

### Wallet

| Method | Description | Returns |
|--------|-------------|--------|
| `generateAccount(password: String?)` | Create new wallet (mnemonic + derived key). Optional `password` returns keystore in result. | `[String: Any]?` → address, privateKey, mnemonic, keystore? |
| `importAccountFromPrivateKey(privateKey:)` | Import from hex private key. | address, privateKey |
| `importAccountFromMnemonic(mnemonic:)` | Import from 12/24-word mnemonic (first account). | address, privateKey, mnemonic |
| `importAccountFromKeystore(json:password:)` | Import from Keystore JSON string. | address, privateKey, keystore |
| `privateKeyToKeystore(privateKey:password:)` | Encrypt private key to Keystore JSON (light PBKDF2). | Keystore JSON string or nil |
| `getAddressFromPrivateKey(privateKey:)` | Get Ethereum address from private key. | Address string or nil |

**Example**

```swift
// Generate wallet (optional password for keystore)
let result = await etherWeb.generateAccount(password: "myPassword")
if let r = result {
    print(r["address"] as? String ?? "")
    print(r["privateKey"] as? String ?? "")
    print(r["keystore"] as? String ?? "")
}

// Import from mnemonic
let imported = await etherWeb.importAccountFromMnemonicAsync(mnemonic: "abandon abandon ...")
```

---

### Sign & Verify Message (EIP-191)

| Method | Description | Returns |
|--------|-------------|--------|
| `signMessage(privateKey:message:)` | Sign message with private key (personal_sign). | Signature hex or nil |
| `verifyMessage(message:signature:)` | Recover signer address from message + signature. | Recovered address or nil |
| `verifyMessageSignature(message:signature:expectedAddress:)` | Check if signature was produced by expected address. | Bool |

**Example**

```swift
let signature = await etherWeb.signMessage(privateKey: pk, message: "Hello")
let recovered = await etherWeb.verifyMessage(message: "Hello", signature: signature ?? "")
let isValid = await etherWeb.verifyMessageSignature(message: "Hello", signature: sig, expectedAddress: "0x...")
```

---

### Balance & Gas

All of these require **rpcUrl** and **chainId** from the caller (e.g. from your `NetworkManager`).

| Method | Description | Returns |
|--------|-------------|--------|
| `getETHBalance(address:rpcUrl:chainId:)` | Native ETH balance. | Human-readable ETH string or nil |
| `getERC20TokenBalance(tokenAddress:walletAddress:rpcUrl:chainId:)` | ERC20 balance. | Dict: balance, decimals |
| `getGasPrice(rpcUrl:chainId:)` | Current gas price (legacy). | gasPriceWei, gasPriceGwei |
| `getSuggestedFees(rpcUrl:chainId:)` | EIP-1559 style fees. | gasPrice?, maxFeePerGas?, maxPriorityFeePerGas? |

**Example**

```swift
let rpcUrl = NetworkManager.shared.currentRpcUrl   // your source of RPC URL
let chainId = NetworkManager.shared.currentChainId

let ethBalance = await etherWeb.getETHBalance(address: "0x...", rpcUrl: rpcUrl, chainId: chainId)
let tokenBalance = await etherWeb.getERC20TokenBalance(
    tokenAddress: "0x...", walletAddress: "0x...", rpcUrl: rpcUrl, chainId: chainId
)
let gasPrice = await etherWeb.getGasPrice(rpcUrl: rpcUrl, chainId: chainId)
let fees = await etherWeb.getSuggestedFees(rpcUrl: rpcUrl, chainId: chainId)
```

---

### Transfer

| Method | Description | Returns |
|--------|-------------|--------|
| `getAddressFromPrivateKey(privateKey:)` | Resolve address from private key (e.g. for estimate). | Address string or nil |
| `estimateEthTransferGas(fromAddress:to:valueEth:rpcUrl:chainId:)` | Estimate gas for ETH transfer. | gasLimit, gasPrice, estimatedFeeWei, estimatedFeeEth |
| `ethTransfer(privateKey:to:valueEth:gasLimit:gasPrice:maxFeePerGas:maxPriorityFeePerGas:rpcUrl:chainId:)` | Send ETH. Gas params optional (pass nil to let provider decide). | hash, from, to |
| `estimateErc20TransferGas(fromAddress:tokenAddress:to:amountHuman:decimals:rpcUrl:chainId:)` | Estimate gas for ERC20 transfer. | gasLimit, gasPrice, estimatedFeeWei, estimatedFeeEth |
| `erc20Transfer(privateKey:tokenAddress:to:amountHuman:decimals:gasLimit:gasPrice:maxFeePerGas:maxPriorityFeePerGas:rpcUrl:chainId:)` | Send ERC20. Gas params optional. | hash, from, to |

**Example**

```swift
let rpcUrl = NetworkManager.shared.currentRpcUrl
let chainId = NetworkManager.shared.currentChainId

// 1) Estimate ETH transfer
let from = await etherWeb.getAddressFromPrivateKey(privateKey: privateKey)
let estimate = await etherWeb.estimateEthTransferGas(
    fromAddress: from!, to: "0x...", valueEth: "0.01", rpcUrl: rpcUrl, chainId: chainId
)
let gasLimit = estimate?["gasLimit"] as? String
let gasPrice = estimate?["gasPrice"] as? String

// 2) Send ETH (optionally use estimated gas)
let tx = await etherWeb.ethTransfer(
    privateKey: privateKey, to: "0x...", valueEth: "0.01",
    gasLimit: gasLimit, gasPrice: gasPrice, maxFeePerGas: nil, maxPriorityFeePerGas: nil,
    rpcUrl: rpcUrl, chainId: chainId
)
let txHash = tx?["hash"] as? String

// ERC20 transfer
let erc20Tx = await etherWeb.erc20Transfer(
    privateKey: pk, tokenAddress: "0x...", to: "0x...", amountHuman: "10", decimals: 18,
    gasLimit: nil, gasPrice: nil, maxFeePerGas: nil, maxPriorityFeePerGas: nil,
    rpcUrl: rpcUrl, chainId: chainId
)
```

---

## Conventions

- **MainActor**: `EtherWeb` is `@MainActor`; call its methods from the main thread or from Swift concurrency (e.g. `Task { @MainActor in ... }`).
- **rpcUrl + chainId**: For balance, gas, and transfer APIs you must supply the current chain's RPC URL and chain ID. EtherWeb does not store or choose networks; your app does (e.g. via a `NetworkManager`).
- **Async vs completion**: Prefer the async overloads when writing async Swift code; use the completion versions from callback-based code.
- **Errors**: Failed bridge calls typically return `nil` (or `false` for `verifyMessageSignature`). Ensure your JS bundle returns `{ state: true, result }` on success and `{ state: false, error }` on failure so the native side can distinguish.

---

## License

EtherWallet is released under the MIT license. [See LICENSE](https://github.com/smithSophiav/EtherWallet/blob/main/LICENSE) for details.
