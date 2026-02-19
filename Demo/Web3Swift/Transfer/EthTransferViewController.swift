//
//  EthTransferViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit
import EtherWallet
/// ETH transfer (estimateEthTransferGas + ethTransfer). Uses NetworkManager for rpcUrl + chainId.
final class EthTransferViewController: UIViewController {

    private let etherWeb = EtherWeb()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let privateKeyField: UITextField = {
        let f = UITextField()
        f.placeholder = "Sender private key (0x...)"
        f.isSecureTextEntry = true
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.borderStyle = .roundedRect
        return f
    }()
    private let fromAddressField: UITextField = {
        let f = UITextField()
        f.placeholder = "From address (optional, for estimate)"
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.borderStyle = .roundedRect
        return f
    }()
    private let toAddressField: UITextField = {
        let f = UITextField()
        f.placeholder = "To address (0x...)"
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.borderStyle = .roundedRect
        return f
    }()
    private let valueField: UITextField = {
        let f = UITextField()
        f.placeholder = "Amount (ETH), e.g. 0.01"
        f.keyboardType = .decimalPad
        f.autocorrectionType = .no
        f.borderStyle = .roundedRect
        return f
    }()
    private let networkLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()
    private let estimateButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Estimate Gas", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return b
    }()
    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Send", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return b
    }()
    private let resultTextView: UITextView = {
        let t = UITextView()
        t.isEditable = false
        t.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        t.layer.cornerRadius = 8
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.separator.cgColor
        return t
    }()
    private let copyJsonButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Copy Json", for: .normal)
        return b
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var isWebReady = false { didSet { updateButtonState() } }
    private var lastEstimate: [String: Any]?
    private var lastTxResult: [String: Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ETH Transfer"
        view.backgroundColor = .systemBackground

        layoutUI()
        setupEtherWeb()
        updateNetworkLabel()
        estimateButton.addTarget(self, action: #selector(estimateTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        copyJsonButton.addTarget(self, action: #selector(copyJsonTapped), for: .touchUpInside)
        privateKeyField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        fromAddressField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        toAddressField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        valueField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        updateButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNetworkLabel()
    }

    private func layoutUI() {
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        let pkLabel = UILabel()
        pkLabel.text = "Private key"
        pkLabel.font = .systemFont(ofSize: 13, weight: .medium)
        pkLabel.textColor = .secondaryLabel
        let fromLabel = UILabel()
        fromLabel.text = "From address (optional, for estimate)"
        fromLabel.font = .systemFont(ofSize: 13, weight: .medium)
        fromLabel.textColor = .secondaryLabel
        let toLabel = UILabel()
        toLabel.text = "To address"
        toLabel.font = .systemFont(ofSize: 13, weight: .medium)
        toLabel.textColor = .secondaryLabel
        let valueLabel = UILabel()
        valueLabel.text = "Amount (ETH)"
        valueLabel.font = .systemFont(ofSize: 13, weight: .medium)
        valueLabel.textColor = .secondaryLabel

        contentStack.addArrangedSubview(pkLabel)
        contentStack.addArrangedSubview(privateKeyField)
        contentStack.addArrangedSubview(fromLabel)
        contentStack.addArrangedSubview(fromAddressField)
        contentStack.addArrangedSubview(toLabel)
        contentStack.addArrangedSubview(toAddressField)
        contentStack.addArrangedSubview(valueLabel)
        contentStack.addArrangedSubview(valueField)
        contentStack.addArrangedSubview(networkLabel)
        contentStack.addArrangedSubview(estimateButton)
        contentStack.addArrangedSubview(sendButton)
        contentStack.addArrangedSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        let resultLabel = UILabel()
        resultLabel.text = "Result"
        resultLabel.font = .systemFont(ofSize: 13, weight: .medium)
        resultLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(resultLabel)
        contentStack.addArrangedSubview(resultTextView)
        contentStack.addArrangedSubview(copyJsonButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(20)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(20)
            make.trailing.equalTo(scrollView.frameLayoutGuide).offset(-20)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-20)
        }
        resultTextView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
    }

    private func setupEtherWeb() {
        Task { [weak self] in
            guard let self = self else { return }
            _ = await etherWeb.setup(showLog: false)
            await MainActor.run { self.isWebReady = true }
        }
    }

    private func updateNetworkLabel() {
        networkLabel.text = "Network: \(NetworkManager.shared.currentNetworkLabel)"
    }

    private func updateButtonState() {
        let hasPk = privateKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasFrom = fromAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasTo = toAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasValue = valueField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let canEstimate = hasTo && hasValue && (hasFrom || hasPk)
        let canSend = hasPk && hasTo && hasValue
        estimateButton.isEnabled = isWebReady && canEstimate
        sendButton.isEnabled = isWebReady && canSend
        estimateButton.alpha = isWebReady && canEstimate ? 1 : 0.6
        sendButton.alpha = isWebReady && canSend ? 1 : 0.6
    }

    @objc private func inputChanged() {
        updateButtonState()
    }

    @objc private func estimateTapped() {
        guard isWebReady else { return }
        let fromText = fromAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pk = privateKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let to = toAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let valueEth = valueField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if to.isEmpty || valueEth.isEmpty { return }
        if fromText.isEmpty && pk.isEmpty { return }

        estimateButton.isEnabled = false
        sendButton.isEnabled = false
        loadingIndicator.startAnimating()
        resultTextView.text = ""
        resultTextView.textColor = .label
        let rpcUrl = NetworkManager.shared.currentRpcUrl
        let chainId = NetworkManager.shared.currentChainId

        Task { [weak self] in
            guard let self = self else { return }
            let fromAddress: String?
            if !fromText.isEmpty {
                fromAddress = fromText
            } else {
                fromAddress = await etherWeb.getAddressFromPrivateKey(privateKey: pk)
                if fromAddress == nil {
                    await MainActor.run {
                        self.loadingIndicator.stopAnimating()
                        self.updateButtonState()
                        self.resultTextView.text = "Invalid private key."
                        self.resultTextView.textColor = .systemRed
                    }
                    return
                }
            }
            guard let from = fromAddress else { return }
            let estimate = await etherWeb.estimateEthTransferGas(fromAddress: from, to: to, valueEth: valueEth, rpcUrl: rpcUrl, chainId: chainId)
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.updateButtonState()
                self.lastEstimate = estimate
                if let est = estimate {
                    var lines: [String] = []
                    if let gasLimit = est["gasLimit"] as? String { lines.append("Gas limit: \(gasLimit)") }
                    if let gasPrice = est["gasPrice"] as? String { lines.append("Gas price: \(gasPrice) wei") }
                    if let feeEth = est["estimatedFeeEth"] as? String { lines.append("Est. fee: \(feeEth) ETH") }
                    self.resultTextView.text = lines.joined(separator: "\n")
                    self.resultTextView.textColor = .label
                } else {
                    self.resultTextView.text = "Estimate failed."
                    self.resultTextView.textColor = .systemRed
                }
            }
        }
    }

    @objc private func sendTapped() {
        guard isWebReady else { return }
        let pk = privateKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let to = toAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let valueEth = valueField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if pk.isEmpty || to.isEmpty || valueEth.isEmpty { return }

        estimateButton.isEnabled = false
        sendButton.isEnabled = false
        loadingIndicator.startAnimating()
        resultTextView.text = "Sending..."
        resultTextView.textColor = .label
        let rpcUrl = NetworkManager.shared.currentRpcUrl
        let chainId = NetworkManager.shared.currentChainId
        let gasLimit = lastEstimate?["gasLimit"] as? String
        let gasPrice = lastEstimate?["gasPrice"] as? String

        Task { [weak self] in
            guard let self = self else { return }
            let tx = await etherWeb.ethTransfer(
                privateKey: pk,
                to: to,
                valueEth: valueEth,
                gasLimit: gasLimit,
                gasPrice: gasPrice,
                maxFeePerGas: nil,
                maxPriorityFeePerGas: nil,
                rpcUrl: rpcUrl,
                chainId: chainId
            )
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.updateButtonState()
                if let tx = tx, let hash = tx["hash"] as? String {
                    self.lastTxResult = tx
                    self.resultTextView.text = "Tx hash: \(hash)"
                    self.resultTextView.textColor = .label
                } else {
                    self.lastTxResult = nil
                    self.resultTextView.text = "Send failed."
                    self.resultTextView.textColor = .systemRed
                }
            }
        }
    }

    @objc private func copyJsonTapped() {
        guard let json = lastTxResult,
              let data = try? JSONSerialization.data(withJSONObject: json),
              let text = String(data: data, encoding: .utf8) else { return }
        UIPasteboard.general.string = text
        copyJsonButton.setTitle("Copied", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyJsonButton.setTitle("Copy Json", for: .normal)
        }
    }
}
