//
//  VerifyMessageViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit
import EtherWallet
/// Verify message (recover signer from message + signature; optional check against expected address).
final class VerifyMessageViewController: UIViewController {

    private let etherWeb = EtherWeb()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let messageTextView: UITextView = {
        let t = UITextView()
        t.font = .systemFont(ofSize: 15, weight: .regular)
        t.layer.cornerRadius = 8
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.separator.cgColor
        t.autocapitalizationType = .none
        return t
    }()
    private let signatureTextView: UITextView = {
        let t = UITextView()
        t.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        t.layer.cornerRadius = 8
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.separator.cgColor
        t.autocapitalizationType = .none
        t.autocorrectionType = .no
        return t
    }()
    private let expectedAddressField: UITextField = {
        let f = UITextField()
        f.placeholder = "Expected signer address (optional)"
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.borderStyle = .roundedRect
        return f
    }()
    private let verifyButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Verify", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return b
    }()
    private let resultTextView: UITextView = {
        let t = UITextView()
        t.isEditable = false
        t.font = .systemFont(ofSize: 15, weight: .regular)
        t.layer.cornerRadius = 8
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.separator.cgColor
        return t
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var isWebReady = false {
        didSet { updateVerifyButtonState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Verify Message"
        view.backgroundColor = .systemBackground

        layoutUI()
        setupEtherWeb()
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inputChanged),
            name: UITextView.textDidChangeNotification,
            object: messageTextView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inputChanged),
            name: UITextView.textDidChangeNotification,
            object: signatureTextView
        )
        expectedAddressField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        updateVerifyButtonState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func layoutUI() {
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        let msgLabel = UILabel()
        msgLabel.text = "Message"
        msgLabel.font = .systemFont(ofSize: 13, weight: .medium)
        msgLabel.textColor = .secondaryLabel

        let sigLabel = UILabel()
        sigLabel.text = "Signature (hex)"
        sigLabel.font = .systemFont(ofSize: 13, weight: .medium)
        sigLabel.textColor = .secondaryLabel

        let expectedLabel = UILabel()
        expectedLabel.text = "Expected signer (optional)"
        expectedLabel.font = .systemFont(ofSize: 13, weight: .medium)
        expectedLabel.textColor = .secondaryLabel

        contentStack.addArrangedSubview(msgLabel)
        contentStack.addArrangedSubview(messageTextView)
        contentStack.addArrangedSubview(sigLabel)
        contentStack.addArrangedSubview(signatureTextView)
        contentStack.addArrangedSubview(expectedLabel)
        contentStack.addArrangedSubview(expectedAddressField)
        contentStack.addArrangedSubview(verifyButton)
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
        messageTextView.snp.makeConstraints { make in
            make.height.equalTo(70)
        }
        signatureTextView.snp.makeConstraints { make in
            make.height.equalTo(80)
        }
        resultTextView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
    }

    private func setupEtherWeb() {
        Task { [weak self] in
            guard let self = self else { return }
            _ = await etherWeb.setup(showLog: false)
            await MainActor.run { self.isWebReady = true }
        }
    }

    private func updateVerifyButtonState() {
        let hasMsg = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasSig = signatureTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        verifyButton.isEnabled = isWebReady && hasMsg && hasSig
        verifyButton.alpha = (isWebReady && hasMsg && hasSig) ? 1 : 0.6
    }

    @objc private func inputChanged() {
        updateVerifyButtonState()
    }

    @objc private func verifyTapped() {
        guard isWebReady else { return }
        let message = messageTextView.text ?? ""
        let signature = signatureTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let expected = expectedAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.isEmpty || signature.isEmpty { return }

        verifyButton.isEnabled = false
        loadingIndicator.startAnimating()
        resultTextView.text = ""
        Task { [weak self] in
            guard let self = self else { return }
            if let expected = expected, !expected.isEmpty {
                let valid = await etherWeb.verifyMessageSignature(message: message, signature: signature, expectedAddress: expected)
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.updateVerifyButtonState()
                    if valid {
                        self.resultTextView.text = "Signature is valid.\nSigner matches: \(expected)"
                        self.resultTextView.textColor = .systemGreen
                    } else {
                        self.resultTextView.text = "Signature invalid or signer does not match expected address."
                        self.resultTextView.textColor = .systemRed
                    }
                }
            } else {
                let recovered = await etherWeb.verifyMessage(message: message, signature: signature)
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.updateVerifyButtonState()
                    if let addr = recovered {
                        self.resultTextView.text = "Recovered signer:\n\(addr)"
                        self.resultTextView.textColor = .label
                    } else {
                        self.resultTextView.text = "Invalid signature or message."
                        self.resultTextView.textColor = .systemRed
                    }
                }
            }
        }
    }
}
