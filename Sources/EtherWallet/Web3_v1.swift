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

extension Web3_v1: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.showLog { print("didFinish") }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if self.showLog { print("error = \(error)") }
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if self.showLog { print("didStartProvisionalNavigation ") }
    }
}

public class Web3_v1: NSObject {
    var webView: WKWebView!
    var bridge: ETHWebViewJavascriptBridge!
    public var isWeb3LoadFinished: Bool = false
    var onCompleted: ((Bool) -> Void)?
    var showLog: Bool = true
    override public init() {
        super.init()
        let webConfiguration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.webView.navigationDelegate = self
        self.webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        self.bridge = ETHWebViewJavascriptBridge(webView: self.webView, isHookConsole: true)
    }

    deinit {
        print("\(type(of: self)) release")
    }

    public func setup(showLog: Bool = true, onCompleted: ((Bool) -> Void)? = nil) {
        self.onCompleted = onCompleted
        self.showLog = showLog
        #if !DEBUG
        self.showLog = false
        #endif
        if showLog {
            self.bridge.consolePipeClosure = { water in
                guard let jsConsoleLog = water else {
                    print("Javascript console.log give native is nil!")
                    return
                }
                print(jsConsoleLog)
            }
        }
        self.bridge.register(handlerName: "FinishLoad") { [weak self] _, _ in
            guard let self = self else { return }
            print("js load finished")
            self.isWeb3LoadFinished = true
            self.onCompleted?(true)
        }
        let htmlSource = self.loadBundleResource(bundleName: "web3swift", sourceName: "/Index.html")
        let url = URL(fileURLWithPath: htmlSource)
        self.webView.loadFileURL(url, allowingReadAccessTo: url)
    }

    func loadBundleResource(bundleName: String, sourceName: String) -> String {
       let bundleResourcePath = Bundle.module.path(forResource: bundleName, ofType: "bundle")
//         var bundleResourcePath = Bundle.main.path(forResource: "Frameworks/\(bundleName).framework/\(bundleName)", ofType: "bundle")
//         if bundleResourcePath == nil {
//             bundleResourcePath = Bundle.main.path(forResource: bundleName, ofType: "bundle") ?? ""
//         }

        return bundleResourcePath! + sourceName
    }

    // MARK: generateAccount

    public func generateAccount(password: String, onCompleted: ((Bool, String, String, String, String, String) -> Void)? = nil) {
        let params: [String: String] = ["password": password]
        self.bridge.call(handlerName: "generateAccount", data: params) { response in
            if self.showLog {
                print("response = \(String(describing: response))")
            }
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "", "", "", "", "Invalid response format")
                return
            }
            if let state = temp["state"] as? Bool, state,
               let address = temp["address"] as? String,
               let privateKey = temp["privateKey"] as? String,
               let keystore = temp["Keystore"] as? String,
               let mnemonic = temp["mnemonic"] as? String
            {
                onCompleted?(state, address, mnemonic, privateKey, keystore, "")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", "", "", "", error)
            } else {
                onCompleted?(false, "", "", "", "", "Unknown response format")
            }
        }
    }

    // MARK: importAccount -- (password,Keystore)
    public func importAccount(decryptPassword: String, keystore: String, onCompleted: ((Bool, String, String, String) -> Void)? = nil) {
        typealias Parameters = [String: String]

        let params: Parameters = ["decryptPassword": decryptPassword, "Keystore": keystore]

        self.bridge.call(handlerName: "importAccountFromKeystore", data: params) { response in
            if self.showLog {
                print("response = \(String(describing: response))")
            }

            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "", "", "Invalid response format")
                return
            }

            if let state = temp["state"] as? Bool, state,
               let address = temp["address"] as? String,
               let privateKey = temp["privateKey"] as? String
            {
                onCompleted?(state, address, privateKey, "")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", "", error)
            } else {
                onCompleted?(false, "", "", "Unknown response format")
            }
        }
    }

    // MARK: importAccount -- (privateKey)

    public func importAccount(privateKey: String, encrypedPassword: String, onCompleted: ((Bool, String, String,String) -> Void)? = nil) {
        let params: [String: String] = ["privateKey": privateKey, "encrypedPassword": encrypedPassword]
        self.bridge.call(handlerName: "importAccountFromPrivateKey", data: params) { response in
            if self.showLog { print("response = \(String(describing: response))") }
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "", "", "Invalid response format")
                return
            }
            
            if let state = temp["state"] as? Bool, state,
               let address = temp["address"] as? String,
               let keystore = temp["Keystore"] as? String
            {
                onCompleted?(state, address, keystore, "")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", "", error)
            } else {
                onCompleted?(false, "", "", "Unknown response format")
            }
        }
    }

    // MARK: importAccount -- (mnemonic) Only English mnemonics are supported

    public func importAccount(mnemonic: String, encrypedPassword: String, onCompleted: ((Bool, String, String, String,String) -> Void)? = nil) {
        let params: [String: String] = ["mnemonic": mnemonic, "encrypedPassword": encrypedPassword]
        self.bridge.call(handlerName: "importAccountFromMnemonic", data: params) { response in
            if self.showLog { print("response = \(String(describing: response))") }
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "", "", "","Invalid response format")
                return
            }
            if let state = temp["state"] as? Bool, state,
               let address = temp["address"] as? String,
               let keystore = temp["Keystore"] as? String,
               let privateKey = temp["privateKey"] as? String
            {
                onCompleted?(state, address,privateKey, keystore, "")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", "","", error)
            } else {
                onCompleted?(false, "", "","", "Unknown response format")
            }
        }
    }

    // MARK: getETHBalance

    public func getETHBalance(address: String,
                              providerUrl: String = MainNet,
                              onCompleted: ((Bool, String,String) -> Void)? = nil)
    {
        let params: [String: String] = ["address": address,
                                        "providerUrl": providerUrl]
        self.bridge.call(handlerName: "getETHBalance", data: params) { response in
            if self.showLog { print("response = \(String(describing: response))") }
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "","Invalid response format")
                return
            }
            if let state = temp["state"] as? Bool, state,
               let balance = temp["balance"] as? String
            {
                onCompleted?(state, balance,"")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", error)
            } else {
                onCompleted?(false, "", "Unknown response format")
            }
        }
    }

    // MARK: getERC20TokenBalance

    public func getERC20TokenBalance(address: String,
                                     contractAddress: String,
                                     decimals: Double,
                                     providerUrl: String = MainNet,
                                     onCompleted: ((Bool, String,String) -> Void)? = nil)
    {
        let params: [String: Any] = ["address": address,
                                     "providerUrl": providerUrl,
                                     "contractAddress": contractAddress,
                                     "decimals": decimals]
        self.bridge.call(handlerName: "getERC20TokenBalance", data: params) { response in
            if self.showLog { print("response = \(String(describing: response))") }
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "","Invalid response format")
                return
            }
            if let state = temp["state"] as? Bool, state,
               let balance = temp["balance"] as? String
            {
                onCompleted?(state, balance,"")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", error)
            } else {
                onCompleted?(false, "", "Unknown response format")
            }
        }
    }

    // MARK: estimateETHTransactionFee

    public func estimateETHTransactionFee(recipientAddress: String,
                                          senderAddress: String,
                                          amount: String,
                                          providerUrl: String = MainNet,
                                          onCompleted: ((Bool, String,String) -> Void)? = nil)
    {
        let params: [String: String] = ["recipientAddress": recipientAddress,
                                        "providerUrl": providerUrl,
                                        "senderAddress": senderAddress,
                                        "amount": amount]
        self.bridge.call(handlerName: "estimateETHTransactionFee", data: params) { response in
            if self.showLog { print("response = \(String(describing: response))") }
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "","Invalid response format")
                return
            }
            if let state = temp["state"] as? Bool, state,
               let estimateTransactionFee = temp["estimateTransactionFee"] as? String
            {
                onCompleted?(state, estimateTransactionFee,"")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", error)
            } else {
                onCompleted?(false, "", "Unknown response format")
            }
        }
    }

    // MARK: estimateERC20TransactionFee

    public func estimateERC20TransactionFee(providerUrl: String = MainNet,
                                            recipientAddress: String,
                                            senderAddress: String,
                                            amount: String,
                                            decimal: Double = 6,
                                            contractAddress: String,
                                            onCompleted: ((Bool, String,String) -> Void)? = nil)
    {
        let params: [String: Any] = ["providerUrl": providerUrl,
                                     "recipientAddress": recipientAddress,
                                     "senderAddress": senderAddress,
                                     "amount": amount,
                                     "contractAddress": contractAddress,
                                     "decimal": decimal]
        self.bridge.call(handlerName: "estimateERC20TransactionFee", data: params) { response in
            if self.showLog { print("response = \(String(describing: response))") }
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "","Invalid response format")
                return
            }
            if let state = temp["state"] as? Bool, state,
               let estimateTransactionFee = temp["estimateTransactionFee"] as? String
            {
                onCompleted?(state, estimateTransactionFee,"")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", error)
            } else {
                onCompleted?(false, "", "Unknown response format")
            }
        }
    }

    // MARK: ETHTransfer

    public func ETHTransfer(recipientAddress: String,
                            amount: String,
                            senderPrivateKey: String,
                            providerUrl: String = MainNet,
                            onCompleted: ((Bool, String,String) -> Void)? = nil)
    {
        let params: [String: String] = ["recipientAddress": recipientAddress,
                                        "providerUrl": providerUrl,
                                        "senderPrivateKey": senderPrivateKey,
                                        "amount": amount]
        self.bridge.call(handlerName: "ETHTransfer", data: params) { response in
            if self.showLog { print("response = \(String(describing: response))") }
            
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "","Invalid response format")
                return
            }
            if let state = temp["state"] as? Bool, state,
               let txid = temp["txid"] as? String
            {
                onCompleted?(state, txid,"")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", error)
            } else {
                onCompleted?(false, "", "Unknown response format")
            }
        }
    }

    // MARK: erc20TokenTransfer

    public func erc20TokenTransfer(providerUrl: String = MainNet,
                                   senderPrivateKey: String,
                                   recipientAddress: String,
                                   erc20ContractAddress: String,
                                   amount: String,
                                   decimal: Double = 6,
                                   onCompleted: ((Bool, String,String) -> Void)? = nil)
    {
        let params: [String: Any] = ["recipientAddress": recipientAddress,
                                     "providerUrl": providerUrl,
                                     "senderPrivateKey": senderPrivateKey,
                                     "contractAddress": erc20ContractAddress,
                                     "amount": amount,
                                     "decimal": decimal]
        self.bridge.call(handlerName: "ERC20Transfer", data: params) { response in
            if self.showLog { print("response = \(String(describing: response))") }
            guard let temp = response as? [String: Any] else {
                onCompleted?(false, "","Invalid response format")
                return
            }
            if let state = temp["state"] as? Bool, state,
               let txid = temp["txid"] as? String
            {
                onCompleted?(state, txid,"")
            } else if let error = temp["error"] as? String {
                onCompleted?(false, "", error)
            } else {
                onCompleted?(false, "", "Unknown response format")
            }
        }
    }
}
