//
//  ETHBalanceViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit
import EtherWallet
/// Query ETH balance (getETHBalance). Uses current network from NetworkManager.
final class ETHBalanceViewController: UIViewController {

    private let etherWeb = EtherWeb()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let addressField: UITextField = {
        let f = UITextField()
        f.placeholder = "Address (0x...)"
        f.autocapitalizationType = .none
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
    private let queryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Query Balance", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return b
    }()
    private let resultLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.numberOfLines = 0
        return l
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var isWebReady = false {
        didSet { updateQueryButtonState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ETH Balance"
        view.backgroundColor = .systemBackground

        layoutUI()
        setupEtherWeb()
        updateNetworkLabel()
        queryButton.addTarget(self, action: #selector(queryTapped), for: .touchUpInside)
        addressField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
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

        let addressLabel = UILabel()
        addressLabel.text = "Address"
        addressLabel.font = .systemFont(ofSize: 13, weight: .medium)
        addressLabel.textColor = .secondaryLabel

        contentStack.addArrangedSubview(addressLabel)
        contentStack.addArrangedSubview(addressField)
        contentStack.addArrangedSubview(networkLabel)
        contentStack.addArrangedSubview(queryButton)
        contentStack.addArrangedSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        contentStack.addArrangedSubview(resultLabel)

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
        let hasAddress = addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        queryButton.isEnabled = isWebReady && hasAddress
        queryButton.alpha = (isWebReady && hasAddress) ? 1 : 0.6
    }

    @objc private func inputChanged() {
        updateQueryButtonState()
    }

    @objc private func queryTapped() {
        guard isWebReady else { return }
        let address = addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if address.isEmpty { return }

        queryButton.isEnabled = false
        loadingIndicator.startAnimating()
        resultLabel.text = ""
        resultLabel.textColor = .label

        let rpcUrl = NetworkManager.shared.currentRpcUrl
        let chainId = NetworkManager.shared.currentChainId
        Task { [weak self] in
            guard let self = self else { return }
            let balance = await etherWeb.getETHBalance(address: address, rpcUrl: rpcUrl, chainId: chainId)
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.updateQueryButtonState()
                if let balance = balance {
                    self.resultLabel.text = "\(balance) ETH"
                    self.resultLabel.textColor = .label
                } else {
                    self.resultLabel.text = "Failed to fetch balance."
                    self.resultLabel.textColor = .systemRed
                }
            }
        }
    }
}
