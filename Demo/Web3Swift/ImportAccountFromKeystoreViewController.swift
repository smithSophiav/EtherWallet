//
//  ImportAccountViewController.swift
//  Web3Swift
//
//  Created by smithSophiav on 2023/9/17.
//

import UIKit
import EtherWallet
class ImportAccountFromKeystoreViewController: UIViewController {
    lazy var web3: Web3_v1 = .init()

    lazy var importAccountBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("ImportAccount", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(importAccountAction), for: .touchUpInside)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        return btn
    }()

    lazy var passwordField: UITextField = {
        let passwordField = UITextField()
        passwordField.borderStyle = .line
        passwordField.placeholder = "please input password"
        passwordField.adjustsFontSizeToFitWidth = true
        passwordField.minimumFontSize = 0.5
        passwordField.text = "123456789"
        return passwordField
    }()

    lazy var KeystoreTextView: UITextView = {
        let textView = UITextView()
        textView.text = "please input Keystore"
        textView.textColor = UIColor.brown
        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 1.0
        textView.font = UIFont.systemFont(ofSize: 13.0)
        return textView
    }()

    lazy var importAccountTextView: UITextView = {
        let textView = UITextView()
        textView.textColor = UIColor.brown
        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 1.0
        textView.font = UIFont.systemFont(ofSize: 13.0)
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        // Do any additional setup after loading the view.
    }

    func setupView() {
        setupNav()
        setupContent()
    }

    func setupNav() {
        title = "Import Account"
    }

    func setupContent() {
        view.backgroundColor = .white
        view.addSubviews(importAccountBtn, passwordField, KeystoreTextView, importAccountTextView)
        importAccountBtn.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.bottom.equalTo(-100)
            make.height.equalTo(40)
        }
        passwordField.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(150)
            make.height.equalTo(40)
        }
        KeystoreTextView.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(passwordField.snp.bottom).offset(20)
            make.height.equalTo(280)
        }
        importAccountTextView.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(KeystoreTextView.snp.bottom).offset(20)
            make.bottom.equalTo(importAccountBtn.snp.top).offset(-20)
        }
    }

    @objc func importAccountAction() {
        print("importAccountAction")
        importAccountBtn.isEnabled = false
        guard let password = passwordField.text, let Keystore = KeystoreTextView.text else { return }
        if web3.isWeb3LoadFinished {
            importAccount(password: password, Keystore: Keystore)
        } else {
            web3.setup { [weak self] web3LoadFinished in
                guard let self = self else { return }
                if web3LoadFinished {
                    self.importAccount(password: password, Keystore: Keystore)
                }
            }
        }
    }

    func importAccount(password: String, Keystore: String) {
        web3.importAccount(decryptPassword: password, keystore: Keystore) { [weak self] (state, address, privateKey,error) in
            guard let self = self else { return }
            self.importAccountBtn.isEnabled = true
            if state {
                let text =
                    "address: " + address + "\n\n" +
                    "privateKey: " + privateKey
                self.importAccountTextView.text = text
            } else {
                self.importAccountTextView.text = error
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
