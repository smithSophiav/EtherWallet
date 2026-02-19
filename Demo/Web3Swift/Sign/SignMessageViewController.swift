//
//  SignMessageViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit

/// Sign message (EIP-191 personal_sign via signMessage).
final class SignMessageViewController: UIViewController {

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
    private let messageTextView: UITextView = {
        let t = UITextView()
        t.font = .systemFont(ofSize: 15, weight: .regular)
        t.layer.cornerRadius = 8
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.separator.cgColor
        t.autocapitalizationType = .none
        return t
    }()
    private let signButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Sign Message", for: .normal)
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
        b.setTitle("Copy Signature", for: .normal)
        return b
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var lastSignature: String?
    private var isWebReady = false {
        didSet { updateSignButtonState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign Message"
        view.backgroundColor = .systemBackground

        layoutUI()
        setupEtherWeb()
        signButton.addTarget(self, action: #selector(signTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        privateKeyField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inputChanged),
            name: UITextView.textDidChangeNotification,
            object: messageTextView
        )
        updateSignButtonState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func layoutUI() {
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        let pkLabel = UILabel()
        pkLabel.text = "Private key"
        pkLabel.font = .systemFont(ofSize: 13, weight: .medium)
        pkLabel.textColor = .secondaryLabel

        let msgLabel = UILabel()
        msgLabel.text = "Message"
        msgLabel.font = .systemFont(ofSize: 13, weight: .medium)
        msgLabel.textColor = .secondaryLabel

        contentStack.addArrangedSubview(pkLabel)
        contentStack.addArrangedSubview(privateKeyField)
        contentStack.addArrangedSubview(msgLabel)
        contentStack.addArrangedSubview(messageTextView)
        contentStack.addArrangedSubview(signButton)
        contentStack.addArrangedSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true

        let resultLabel = UILabel()
        resultLabel.text = "Signature"
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
        messageTextView.snp.makeConstraints { make in
            make.height.equalTo(80)
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

    private func updateSignButtonState() {
        let hasPk = privateKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasMsg = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        signButton.isEnabled = isWebReady && hasPk && hasMsg
        signButton.alpha = (isWebReady && hasPk && hasMsg) ? 1 : 0.6
    }

    @objc private func inputChanged() {
        updateSignButtonState()
    }

    @objc private func signTapped() {
        guard isWebReady else { return }
        let pk = privateKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let message = messageTextView.text ?? ""
        if pk.isEmpty || message.isEmpty { return }
        signButton.isEnabled = false
        loadingIndicator.startAnimating()
        resultTextView.text = ""
        lastSignature = nil
        Task { [weak self] in
            guard let self = self else { return }
            let signature = await etherWeb.signMessage(privateKey: pk, message: message)
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.updateSignButtonState()
                if let sig = signature {
                    self.lastSignature = sig
                    self.resultTextView.text = sig
                    self.resultTextView.textColor = .label
                } else {
                    self.resultTextView.text = "Sign failed. Check private key."
                    self.resultTextView.textColor = .systemRed
                }
            }
        }
    }

    @objc private func copyTapped() {
        guard let sig = lastSignature, !sig.isEmpty else { return }
        UIPasteboard.general.string = sig
        copyButton.setTitle("Copied", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyButton.setTitle("Copy Signature", for: .normal)
        }
    }
}
