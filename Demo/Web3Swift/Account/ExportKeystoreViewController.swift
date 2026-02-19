//
//  ExportKeystoreViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit
import EtherWallet
/// Private key to Keystore (generate Keystore from private key + password).
final class ExportKeystoreViewController: UIViewController {

    private let etherWeb = EtherWeb()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let privateKeyField: UITextField = {
        let f = UITextField()
        f.placeholder = "Private key (0x...)"
        f.isSecureTextEntry = true
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.borderStyle = .roundedRect
        return f
    }()
    private let passwordField: UITextField = {
        let f = UITextField()
        f.placeholder = "Keystore password"
        f.isSecureTextEntry = true
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.borderStyle = .roundedRect
        return f
    }()
    private let generateButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Generate Keystore", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return b
    }()
    private let resultTextView: UITextView = {
        let t = UITextView()
        t.isEditable = false
        t.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        t.layer.cornerRadius = 8
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.separator.cgColor
        return t
    }()
    private let copyButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Copy Keystore", for: .normal)
        return b
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var lastKeystore: String?
    private var isWebReady = false {
        didSet { updateGenerateButtonState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Private Key to Keystore"
        view.backgroundColor = .systemBackground

        layoutUI()
        setupEtherWeb()
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        privateKeyField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        updateGenerateButtonState()
    }

    @objc private func inputChanged() {
        updateGenerateButtonState()
    }

    private func layoutUI() {
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        let pkLabel = UILabel()
        pkLabel.text = "Private key"
        pkLabel.font = .systemFont(ofSize: 13, weight: .medium)
        pkLabel.textColor = .secondaryLabel

        let pwLabel = UILabel()
        pwLabel.text = "Keystore password"
        pwLabel.font = .systemFont(ofSize: 13, weight: .medium)
        pwLabel.textColor = .secondaryLabel

        contentStack.addArrangedSubview(pkLabel)
        contentStack.addArrangedSubview(privateKeyField)
        contentStack.addArrangedSubview(pwLabel)
        contentStack.addArrangedSubview(passwordField)
        contentStack.addArrangedSubview(generateButton)
        contentStack.addArrangedSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true

        let resultLabel = UILabel()
        resultLabel.text = "Keystore JSON"
        resultLabel.font = .systemFont(ofSize: 13, weight: .medium)
        resultLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(resultLabel)
        contentStack.addArrangedSubview(resultTextView)
        contentStack.addArrangedSubview(copyButton)

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
            make.height.equalTo(160)
        }
    }

    private func setupEtherWeb() {
        Task { [weak self] in
            guard let self = self else { return }
            _ = await etherWeb.setup(showLog: false)
            await MainActor.run { self.isWebReady = true }
        }
    }

    private func updateGenerateButtonState() {
        let hasInput = (privateKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            && (passwordField.text?.isEmpty == false)
        generateButton.isEnabled = isWebReady && hasInput
        generateButton.alpha = (isWebReady && hasInput) ? 1 : 0.6
    }

    @objc private func generateTapped() {
        guard isWebReady else { return }
        let pk = privateKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        if pk.isEmpty || password.isEmpty {
            return
        }
        loadingIndicator.startAnimating()
        generateButton.isEnabled = false
        Task { [weak self] in
            guard let self = self else { return }
            let keystore = await etherWeb.privateKeyToKeystore(privateKey: pk, password: password)
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.generateButton.isEnabled = self.isWebReady
                self.updateGenerateButtonState()
                if let ks = keystore {
                    self.lastKeystore = ks
                    self.resultTextView.text = ks
                } else {
                    self.lastKeystore = nil
                    self.resultTextView.text = "Failed to generate keystore. Check private key format."
                }
            }
        }
    }

    @objc private func copyTapped() {
        guard let text = lastKeystore, !text.isEmpty else { return }
        UIPasteboard.general.string = text
        copyButton.setTitle("Copied", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyButton.setTitle("Copy Keystore", for: .normal)
        }
    }
}
