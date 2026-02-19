//
//  ERC20BalanceViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit
import EtherWallet
/// Query ERC20 token balance (getERC20TokenBalance). Uses current network from NetworkManager.
final class ERC20BalanceViewController: UIViewController {

    private let etherWeb = EtherWeb()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let tokenAddressField: UITextField = {
        let f = UITextField()
        f.placeholder = "Token contract address (0x...)"
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.borderStyle = .roundedRect
        return f
    }()
    private let walletAddressField: UITextField = {
        let f = UITextField()
        f.placeholder = "Wallet address (0x...)"
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
        title = "ERC20 Balance"
        view.backgroundColor = .systemBackground

        layoutUI()
        setupEtherWeb()
        updateNetworkLabel()
        queryButton.addTarget(self, action: #selector(queryTapped), for: .touchUpInside)
        tokenAddressField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        walletAddressField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
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

        let tokenLabel = UILabel()
        tokenLabel.text = "Token contract"
        tokenLabel.font = .systemFont(ofSize: 13, weight: .medium)
        tokenLabel.textColor = .secondaryLabel

        let walletLabel = UILabel()
        walletLabel.text = "Wallet address"
        walletLabel.font = .systemFont(ofSize: 13, weight: .medium)
        walletLabel.textColor = .secondaryLabel

        contentStack.addArrangedSubview(tokenLabel)
        contentStack.addArrangedSubview(tokenAddressField)
        contentStack.addArrangedSubview(walletLabel)
        contentStack.addArrangedSubview(walletAddressField)
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
        let hasToken = tokenAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasWallet = walletAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        queryButton.isEnabled = isWebReady && hasToken && hasWallet
        queryButton.alpha = (isWebReady && hasToken && hasWallet) ? 1 : 0.6
    }

    @objc private func inputChanged() {
        updateQueryButtonState()
    }

    @objc private func queryTapped() {
        guard isWebReady else { return }
        let tokenAddress = tokenAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let walletAddress = walletAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if tokenAddress.isEmpty || walletAddress.isEmpty { return }

        queryButton.isEnabled = false
        loadingIndicator.startAnimating()
        resultLabel.text = ""
        resultLabel.textColor = .label

        let rpcUrl = NetworkManager.shared.currentRpcUrl
        let chainId = NetworkManager.shared.currentChainId
        Task { [weak self] in
            guard let self = self else { return }
            let result = await etherWeb.getERC20TokenBalance(
                tokenAddress: tokenAddress,
                walletAddress: walletAddress,
                rpcUrl: rpcUrl,
                chainId: chainId
            )
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.updateQueryButtonState()
                if let result = result,
                   let balance = result["balance"] as? String,
                   let decimals = result["decimals"] as? Int {
                    self.resultLabel.text = "\(balance)\n(decimals: \(decimals))"
                    self.resultLabel.textColor = .label
                } else {
                    self.resultLabel.text = "Failed to fetch balance."
                    self.resultLabel.textColor = .systemRed
                }
            }
        }
    }
}
