//
//  GasViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit
import EtherWallet
/// Current network gas (getGasPrice / getSuggestedFees). Uses NetworkManager for rpcUrl + chainId.
final class GasViewController: UIViewController {

    private let etherWeb = EtherWeb()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let networkLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()
    private let queryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Query Gas", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return b
    }()
    private let resultTextView: UITextView = {
        let t = UITextView()
        t.isEditable = false
        t.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        t.layer.cornerRadius = 8
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.separator.cgColor
        return t
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var isWebReady = false {
        didSet { updateQueryButtonState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gas"
        view.backgroundColor = .systemBackground

        layoutUI()
        setupEtherWeb()
        updateNetworkLabel()
        queryButton.addTarget(self, action: #selector(queryTapped), for: .touchUpInside)
        updateQueryButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNetworkLabel()
    }

    private func layoutUI() {
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        contentStack.addArrangedSubview(networkLabel)
        contentStack.addArrangedSubview(queryButton)
        contentStack.addArrangedSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true

        let resultLabel = UILabel()
        resultLabel.text = "Result"
        resultLabel.font = .systemFont(ofSize: 13, weight: .medium)
        resultLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(resultLabel)
        contentStack.addArrangedSubview(resultTextView)

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
            make.height.equalTo(180)
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

    private func updateQueryButtonState() {
        queryButton.isEnabled = isWebReady
        queryButton.alpha = isWebReady ? 1 : 0.6
    }

    @objc private func queryTapped() {
        guard isWebReady else { return }
        queryButton.isEnabled = false
        loadingIndicator.startAnimating()
        resultTextView.text = ""
        resultTextView.textColor = .label

        let rpcUrl = NetworkManager.shared.currentRpcUrl
        let chainId = NetworkManager.shared.currentChainId
        Task { [weak self] in
            guard let self = self else { return }
            async let gasPrice = etherWeb.getGasPrice(rpcUrl: rpcUrl, chainId: chainId)
            async let suggestedFees = etherWeb.getSuggestedFees(rpcUrl: rpcUrl, chainId: chainId)
            let (gas, fees) = await (gasPrice, suggestedFees)
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.updateQueryButtonState()
                self.displayResult(gasPrice: gas, suggestedFees: fees)
            }
        }
    }

    private func displayResult(gasPrice: [String: Any]?, suggestedFees: [String: Any]?) {
        var lines: [String] = []
        if let gas = gasPrice {
            if let gwei = gas["gasPriceGwei"] as? String {
                lines.append("Gas Price (legacy): \(gwei) Gwei")
            }
            if let wei = gas["gasPriceWei"] as? String {
                lines.append("  (wei: \(wei))")
            }
        }
        if let fees = suggestedFees, !fees.isEmpty {
            lines.append("")
            lines.append("Suggested (EIP-1559):")
            if let v = fees["gasPrice"] as? String { lines.append("  gasPrice: \(v) wei") }
            if let v = fees["maxFeePerGas"] as? String { lines.append("  maxFeePerGas: \(v) wei") }
            if let v = fees["maxPriorityFeePerGas"] as? String { lines.append("  maxPriorityFeePerGas: \(v) wei") }
        }
        if lines.isEmpty {
            resultTextView.text = "Failed to fetch gas."
            resultTextView.textColor = .systemRed
        } else {
            resultTextView.text = lines.joined(separator: "\n")
            resultTextView.textColor = .label
        }
    }
}
