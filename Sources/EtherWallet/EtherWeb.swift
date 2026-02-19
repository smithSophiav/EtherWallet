//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE. 
import WebKit

/// Please login https://app.infura.io apply for your own API KEYs
public let MainNet: String = "https://mainnet.infura.io/v3/fe816c09404d406f8f47af0b78413806"
public let SepoliaNet: String = "https://sepolia.infura.io/v3/fe816c09404d406f8f47af0b78413806"

@MainActor
public class EtherWeb: NSObject {
    var webView: WKWebView!
    var bridge: EtherWebViewJavascriptBridge!
    public var isWeb3LoadFinished: Bool = false
    var onCompleted: ((Bool) -> Void)?
    var showLog: Bool = true

    override public init() {
        super.init()
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.bridge = EtherWebViewJavascriptBridge(webView: self.webView, isHookConsole: true)
    }

    deinit {
        print("\(type(of: self)) release")
    }

    public func setup(showLog: Bool = true, onCompleted: ((Bool) -> Void)? = nil) {
        self.onCompleted = onCompleted
        self.showLog = showLog
       
        self.bridge.consolePipeClosure = { water in
            guard let jsConsoleLog = water else {
                print("Javascript console.log give native is nil!")
                return
            }
            print(jsConsoleLog)
        }
        
        self.bridge.register(handlerName: "FinishLoad") { [weak self] _, _ in
            guard let self = self else { return }
            self.isWeb3LoadFinished = true
            self.onCompleted?(true)
        }
        
        if let url = EtherResourceLoader.url(name: "index", ext: "html", subdirectory: "web3swift.bundle") {
            self.webView.loadFileURL(url, allowingReadAccessTo: url)
        }
    }

    /// Async version: wait until JS bundle has loaded and bridge is ready.
    /// - Returns: `true` when load finished successfully.
    public func setup(showLog: Bool = true) async -> Bool {
        await withCheckedContinuation { continuation in
            self.setup(showLog: showLog) { _ in
                continuation.resume(returning: true)
            }
        }
    }

    // MARK: - Wallet Management

    /// Generate new account via JS bridge. Optionally include keystore if password is provided.
    /// - Parameters:
    ///   - password: If non-nil, JS will also return keystore encrypted with this password.
    ///   - completion: Called with result dict (address, privateKey, mnemonic, keystore?) or nil on error.
    public func generateAccount(password: String? = nil, completion: @escaping ([String: Any]?) -> Void) {
        var params: [String: Any] = [:]
        if let p = password, !p.isEmpty {
            params["password"] = p
        }
        bridge.call(handlerName: "generateAccount", data: params.isEmpty ? nil : params) { response in
            guard let wrapper = response as? [String: Any],
                  wrapper["state"] as? Bool == true,
                  let result = wrapper["result"] as? [String: Any] else {
                completion(nil)
                return
            }
            completion(result)
        }
    }

    /// Await version: generate new account. Use `await etherWeb.generateAccount(password: p)`.
    public func generateAccount(password: String? = nil) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.generateAccount(password: password) { result in
                    continuation.resume(returning: result)
                }
            }
        }
    }

    public func importAccountFromMnemonic(mnemonic: String, completion: @escaping ([String: Any]?) -> Void) {
        let params = ["mnemonic": mnemonic]
        self.bridge.call(handlerName: "importAccountFromMnemonic", data: params) { response in
            completion(self.importUnwrap(response))
        }
    }

    /// Async version of importAccountFromMnemonic
    public func importAccountFromMnemonicAsync(mnemonic: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.importAccountFromMnemonic(mnemonic: mnemonic) { response in
                    continuation.resume(returning: response)
                }
            }
        }
    }

    public func importAccountFromPrivateKey(privateKey: String, completion: @escaping ([String: Any]?) -> Void) {
        let params = ["privateKey": privateKey]
        self.bridge.call(handlerName: "importAccountFromPrivateKey", data: params) { response in
            completion(self.importUnwrap(response))
        }
    }

    public func importAccountFromPrivateKey(privateKey: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.importAccountFromPrivateKey(privateKey: privateKey) { continuation.resume(returning: $0) }
            }
        }
    }

    /// Import from Keystore JSON + password. Returns address, privateKey, keystore.
    public func importAccountFromKeystore(json: String, password: String, completion: @escaping ([String: Any]?) -> Void) {
        let params: [String: Any] = ["json": json, "password": password]
        bridge.call(handlerName: "importAccountFromKeystore", data: params) { response in
            completion(self.importUnwrap(response))
        }
    }

    public func importAccountFromKeystore(json: String, password: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.importAccountFromKeystore(json: json, password: password) { continuation.resume(returning: $0) }
            }
        }
    }

    private func importUnwrap(_ response: Any?) -> [String: Any]? {
        guard let wrapper = response as? [String: Any],
              wrapper["state"] as? Bool == true,
              let result = wrapper["result"] as? [String: Any] else { return nil }
        return result
    }

    /// Private key to Keystore JSON string (JS: privateKeyToKeystore). Uses light PBKDF2 encryption.
    public func privateKeyToKeystore(privateKey: String, password: String, completion: @escaping (String?) -> Void) {
        let params: [String: Any] = ["privateKey": privateKey, "password": password]
        bridge.call(handlerName: "privateKeyToKeystore", data: params) { response in
            guard let wrapper = response as? [String: Any],
                  wrapper["state"] as? Bool == true,
                  let result = wrapper["result"] else {
                completion(nil)
                return
            }
            completion(result as? String)
        }
    }

    public func privateKeyToKeystore(privateKey: String, password: String) async -> String? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.privateKeyToKeystore(privateKey: privateKey, password: password) { result in
                    continuation.resume(returning: result)
                }
            }
        }
    }

    // MARK: - Sign / Verify Message (EIP-191 personal_sign)

    /// Sign message with private key. Returns signature hex or nil.
    public func signMessage(privateKey: String, message: String, completion: @escaping (String?) -> Void) {
        let params: [String: Any] = ["privateKey": privateKey, "message": message]
        bridge.call(handlerName: "signMessage", data: params) { response in
            guard let wrapper = response as? [String: Any],
                  wrapper["state"] as? Bool == true,
                  let result = wrapper["result"] else {
                completion(nil)
                return
            }
            completion(result as? String)
        }
    }

    public func signMessage(privateKey: String, message: String) async -> String? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.signMessage(privateKey: privateKey, message: message) { continuation.resume(returning: $0) }
            }
        }
    }

    /// Recover signer address from message + signature. Returns address string or nil.
    public func verifyMessage(message: String, signature: String, completion: @escaping (String?) -> Void) {
        let params: [String: Any] = ["message": message, "signature": signature]
        bridge.call(handlerName: "verifyMessage", data: params) { response in
            guard let wrapper = response as? [String: Any],
                  wrapper["state"] as? Bool == true,
                  let result = wrapper["result"] else {
                completion(nil)
                return
            }
            completion(result as? String)
        }
    }

    public func verifyMessage(message: String, signature: String) async -> String? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.verifyMessage(message: message, signature: signature) { continuation.resume(returning: $0) }
            }
        }
    }

    /// Check if message + signature was signed by expectedAddress. Returns true/false.
    public func verifyMessageSignature(message: String, signature: String, expectedAddress: String, completion: @escaping (Bool) -> Void) {
        let params: [String: Any] = ["message": message, "signature": signature, "expectedAddress": expectedAddress]
        bridge.call(handlerName: "verifyMessageSignature", data: params) { response in
            guard let wrapper = response as? [String: Any],
                  wrapper["state"] as? Bool == true,
                  let result = wrapper["result"] else {
                completion(false)
                return
            }
            completion(result as? Bool ?? false)
        }
    }

    public func verifyMessageSignature(message: String, signature: String, expectedAddress: String) async -> Bool {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.verifyMessageSignature(message: message, signature: signature, expectedAddress: expectedAddress) { continuation.resume(returning: $0) }
            }
        }
    }

    // MARK: - Balance / Gas (caller passes rpcUrl + chainId, e.g. from NetworkManager)

    private func unwrapResult(_ response: Any?) -> [String: Any]? {
        guard let wrapper = response as? [String: Any],
              wrapper["state"] as? Bool == true,
              let result = wrapper["result"] else { return nil }
        if let dict = result as? [String: Any] { return dict }
        return ["result": result]
    }

    /// getETHBalance; caller passes rpcUrl and chainId. Returns human-readable ETH string or nil.
    public func getETHBalance(address: String, rpcUrl: String, chainId: String, completion: @escaping (String?) -> Void) {
        let params: [String: Any] = ["address": address, "rpcUrl": rpcUrl, "chainId": chainId]
        bridge.call(handlerName: "getETHBalance", data: params) { [weak self] response in
            guard let self = self, let out = self.unwrapResult(response) else {
                completion(nil)
                return
            }
            completion(out["result"] as? String)
        }
    }

    public func getETHBalance(address: String, rpcUrl: String, chainId: String) async -> String? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.getETHBalance(address: address, rpcUrl: rpcUrl, chainId: chainId) { continuation.resume(returning: $0) }
            }
        }
    }

    /// getERC20TokenBalance; caller passes rpcUrl and chainId.
    public func getERC20TokenBalance(tokenAddress: String, walletAddress: String, rpcUrl: String, chainId: String, completion: @escaping ([String: Any]?) -> Void) {
        let params: [String: Any] = [
            "tokenAddress": tokenAddress,
            "walletAddress": walletAddress,
            "rpcUrl": rpcUrl,
            "chainId": chainId,
        ]
        bridge.call(handlerName: "getERC20TokenBalance", data: params) { [weak self] response in
            completion(self?.unwrapResult(response) as? [String: Any])
        }
    }

    public func getERC20TokenBalance(tokenAddress: String, walletAddress: String, rpcUrl: String, chainId: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.getERC20TokenBalance(tokenAddress: tokenAddress, walletAddress: walletAddress, rpcUrl: rpcUrl, chainId: chainId) { continuation.resume(returning: $0) }
            }
        }
    }

    /// getGasPrice; caller passes rpcUrl and chainId.
    public func getGasPrice(rpcUrl: String, chainId: String, completion: @escaping ([String: Any]?) -> Void) {
        let params: [String: Any] = ["rpcUrl": rpcUrl, "chainId": chainId]
        bridge.call(handlerName: "getGasPrice", data: params) { [weak self] response in
            completion(self?.unwrapResult(response) as? [String: Any])
        }
    }

    public func getGasPrice(rpcUrl: String, chainId: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.getGasPrice(rpcUrl: rpcUrl, chainId: chainId) { continuation.resume(returning: $0) }
            }
        }
    }

    /// getSuggestedFees; caller passes rpcUrl and chainId.
    public func getSuggestedFees(rpcUrl: String, chainId: String, completion: @escaping ([String: Any]?) -> Void) {
        let params: [String: Any] = ["rpcUrl": rpcUrl, "chainId": chainId]
        bridge.call(handlerName: "getSuggestedFees", data: params) { [weak self] response in
            completion(self?.unwrapResult(response) as? [String: Any])
        }
    }

    public func getSuggestedFees(rpcUrl: String, chainId: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.getSuggestedFees(rpcUrl: rpcUrl, chainId: chainId) { continuation.resume(returning: $0) }
            }
        }
    }

    // MARK: - Transfer (caller passes rpcUrl + chainId)

    /// getAddressFromPrivateKey; returns address string or nil.
    public func getAddressFromPrivateKey(privateKey: String, completion: @escaping (String?) -> Void) {
        let params: [String: Any] = ["privateKey": privateKey]
        bridge.call(handlerName: "getAddressFromPrivateKey", data: params) { response in
            guard let wrapper = response as? [String: Any],
                  wrapper["state"] as? Bool == true,
                  let result = wrapper["result"] else {
                completion(nil)
                return
            }
            completion(result as? String)
        }
    }

    public func getAddressFromPrivateKey(privateKey: String) async -> String? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.getAddressFromPrivateKey(privateKey: privateKey) { continuation.resume(returning: $0) }
            }
        }
    }

    /// estimateEthTransferGas; returns gasLimit, gasPrice, estimatedFeeWei, estimatedFeeEth.
    public func estimateEthTransferGas(fromAddress: String, to: String, valueEth: String, rpcUrl: String, chainId: String, completion: @escaping ([String: Any]?) -> Void) {
        let params: [String: Any] = [
            "fromAddress": fromAddress,
            "to": to,
            "valueEth": valueEth,
            "rpcUrl": rpcUrl,
            "chainId": chainId,
        ]
        bridge.call(handlerName: "estimateEthTransferGas", data: params) { [weak self] response in
            completion(self?.unwrapResult(response) as? [String: Any])
        }
    }

    public func estimateEthTransferGas(fromAddress: String, to: String, valueEth: String, rpcUrl: String, chainId: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.estimateEthTransferGas(fromAddress: fromAddress, to: to, valueEth: valueEth, rpcUrl: rpcUrl, chainId: chainId) { continuation.resume(returning: $0) }
            }
        }
    }

    /// ethTransfer; opts: gasLimit, gasPrice, maxFeePerGas, maxPriorityFeePerGas (all optional). Returns hash, from, to.
    public func ethTransfer(privateKey: String, to: String, valueEth: String, gasLimit: String?, gasPrice: String?, maxFeePerGas: String?, maxPriorityFeePerGas: String?, rpcUrl: String, chainId: String, completion: @escaping ([String: Any]?) -> Void) {
        var params: [String: Any] = ["privateKey": privateKey, "to": to, "valueEth": valueEth, "rpcUrl": rpcUrl, "chainId": chainId]
        if let v = gasLimit { params["gasLimit"] = v }
        if let v = gasPrice { params["gasPrice"] = v }
        if let v = maxFeePerGas { params["maxFeePerGas"] = v }
        if let v = maxPriorityFeePerGas { params["maxPriorityFeePerGas"] = v }
        bridge.call(handlerName: "ethTransfer", data: params) { [weak self] response in
            completion(self?.unwrapResult(response) as? [String: Any])
        }
    }

    public func ethTransfer(privateKey: String, to: String, valueEth: String, gasLimit: String?, gasPrice: String?, maxFeePerGas: String?, maxPriorityFeePerGas: String?, rpcUrl: String, chainId: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.ethTransfer(privateKey: privateKey, to: to, valueEth: valueEth, gasLimit: gasLimit, gasPrice: gasPrice, maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas, rpcUrl: rpcUrl, chainId: chainId) { continuation.resume(returning: $0) }
            }
        }
    }

    /// estimateErc20TransferGas; returns gasLimit, gasPrice, estimatedFeeWei, estimatedFeeEth.
    public func estimateErc20TransferGas(fromAddress: String, tokenAddress: String, to: String, amountHuman: String, decimals: Int, rpcUrl: String, chainId: String, completion: @escaping ([String: Any]?) -> Void) {
        let params: [String: Any] = [
            "fromAddress": fromAddress,
            "tokenAddress": tokenAddress,
            "to": to,
            "amountHuman": amountHuman,
            "decimals": decimals,
            "rpcUrl": rpcUrl,
            "chainId": chainId,
        ]
        bridge.call(handlerName: "estimateErc20TransferGas", data: params) { [weak self] response in
            completion(self?.unwrapResult(response) as? [String: Any])
        }
    }

    public func estimateErc20TransferGas(fromAddress: String, tokenAddress: String, to: String, amountHuman: String, decimals: Int, rpcUrl: String, chainId: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.estimateErc20TransferGas(fromAddress: fromAddress, tokenAddress: tokenAddress, to: to, amountHuman: amountHuman, decimals: decimals, rpcUrl: rpcUrl, chainId: chainId) { continuation.resume(returning: $0) }
            }
        }
    }

    /// erc20Transfer; gas params optional. Returns hash, from, to.
    public func erc20Transfer(privateKey: String, tokenAddress: String, to: String, amountHuman: String, decimals: Int, gasLimit: String?, gasPrice: String?, maxFeePerGas: String?, maxPriorityFeePerGas: String?, rpcUrl: String, chainId: String, completion: @escaping ([String: Any]?) -> Void) {
        var params: [String: Any] = [
            "privateKey": privateKey,
            "tokenAddress": tokenAddress,
            "to": to,
            "amountHuman": amountHuman,
            "decimals": decimals,
            "rpcUrl": rpcUrl,
            "chainId": chainId,
        ]
        if let v = gasLimit { params["gasLimit"] = v }
        if let v = gasPrice { params["gasPrice"] = v }
        if let v = maxFeePerGas { params["maxFeePerGas"] = v }
        if let v = maxPriorityFeePerGas { params["maxPriorityFeePerGas"] = v }
        bridge.call(handlerName: "erc20Transfer", data: params) { [weak self] response in
            completion(self?.unwrapResult(response) as? [String: Any])
        }
    }

    public func erc20Transfer(privateKey: String, tokenAddress: String, to: String, amountHuman: String, decimals: Int, gasLimit: String?, gasPrice: String?, maxFeePerGas: String?, maxPriorityFeePerGas: String?, rpcUrl: String, chainId: String) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.erc20Transfer(privateKey: privateKey, tokenAddress: tokenAddress, to: to, amountHuman: amountHuman, decimals: decimals, gasLimit: gasLimit, gasPrice: gasPrice, maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas, rpcUrl: rpcUrl, chainId: chainId) { continuation.resume(returning: $0) }
            }
        }
    }
}
