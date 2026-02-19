//
//  ImportMnemonicViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit
import EtherWallet
/// Import from mnemonic (importAccountFromMnemonic).
final class ImportMnemonicViewController: UIViewController {

    private let etherWeb = EtherWeb()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let mnemonicTextView: UITextView = {
        let t = UITextView()
        t.font = .systemFont(ofSize: 15, weight: .regular)
        t.layer.cornerRadius = 8
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.separator.cgColor
        t.autocapitalizationType = .none
        t.autocorrectionType = .no
        return t
    }()
    private let importButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Import", for: .normal)
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
        b.setTitle("Copy result", for: .normal)
        return b
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var lastResult: [String: Any]?
    private var isWebReady = false {
        didSet { updateImportButtonState() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Import from Mnemonic"
        view.backgroundColor = .systemBackground

        layoutUI()
        setupEtherWeb()
        importButton.addTarget(self, action: #selector(importTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inputChanged),
            name: UITextView.textDidChangeNotification,
            object: mnemonicTextView
        )
        updateImportButtonState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func layoutUI() {
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        let label = UILabel()
        label.text = "Mnemonic (12 or 24 words)"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel

        contentStack.addArrangedSubview(label)
        contentStack.addArrangedSubview(mnemonicTextView)
        contentStack.addArrangedSubview(importButton)
        contentStack.addArrangedSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true

        let resultLabel = UILabel()
        resultLabel.text = "Result"
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
        mnemonicTextView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
        resultTextView.snp.makeConstraints { make in
            make.height.equalTo(140)
        }
    }

    private func setupEtherWeb() {
        Task { [weak self] in
            guard let self = self else { return }
            _ = await etherWeb.setup(showLog: false)
            await MainActor.run { self.isWebReady = true }
        }
    }

    private func updateImportButtonState() {
        let text = mnemonicTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasInput = !text.isEmpty
        importButton.isEnabled = isWebReady && hasInput
        importButton.alpha = (isWebReady && hasInput) ? 1 : 0.6
    }

    @objc private func inputChanged() {
        updateImportButtonState()
    }

    @objc private func importTapped() {
        guard isWebReady else { return }
        let mnemonic = mnemonicTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if mnemonic.isEmpty { return }
        importButton.isEnabled = false
        loadingIndicator.startAnimating()
        resultTextView.text = ""
        lastResult = nil
        Task { [weak self] in
            guard let self = self else { return }
            let result = await etherWeb.importAccountFromMnemonicAsync(mnemonic: mnemonic)
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.updateImportButtonState()
                if let result = result {
                    self.lastResult = result
                    self.displayResult(result)
                } else {
                    self.resultTextView.text = "Invalid mnemonic."
                    self.resultTextView.textColor = .systemRed
                }
            }
        }
    }

    private func displayResult(_ result: [String: Any]) {
        var lines: [String] = []
        if let address = result["address"] as? String { lines.append("Address: \(address)") }
        if let privateKey = result["privateKey"] as? String { lines.append("Private Key: \(privateKey)") }
        if let mnemonic = result["mnemonic"] as? String { lines.append("Mnemonic: \(mnemonic)") }
        resultTextView.text = lines.joined(separator: "\n\n")
        resultTextView.textColor = .label
    }

    @objc private func copyTapped() {
        guard let last = lastResult else { return }
        let text: String
        if let jsonData = try? JSONSerialization.data(withJSONObject: last),
           let json = String(data: jsonData, encoding: .utf8) {
            text = json
        } else {
            text = resultTextView.text ?? ""
        }
        UIPasteboard.general.string = text
        copyButton.setTitle("Copied", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyButton.setTitle("Copy result", for: .normal)
        }
    }
}
