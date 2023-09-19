//
//  ImportAccountFromPrivateKeyViewController.swift
//  Web3Swift
//
//  Created by smithSophiav on 2023/9/18.
//

import UIKit
import EtherWallet

class ImportAccountFromPrivateKeyViewController: UIViewController {
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

    lazy var privateKeyTextView: UITextView = {
        let textView = UITextView()
        textView.text = "please input privateKey"
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
        view.addSubviews(importAccountBtn, passwordField, privateKeyTextView, importAccountTextView)
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
        privateKeyTextView.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(passwordField.snp.bottom).offset(20)
            make.height.equalTo(100)
        }
        importAccountTextView.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(privateKeyTextView.snp.bottom).offset(20)
            make.bottom.equalTo(importAccountBtn.snp.top).offset(-20)
        }
    }

    @objc func importAccountAction() {
        print("importAccountAction")
        importAccountBtn.isEnabled = false
        guard let password = passwordField.text, let privateKey = privateKeyTextView.text else { return }
        if web3.isWeb3LoadFinished {
            importAccount(password: password, privateKey: privateKey)
        } else {
            web3.setup { [weak self] web3LoadFinished in
                guard let self = self else { return }
                if web3LoadFinished {
                    self.importAccount(password: password, privateKey: privateKey)
                }
            }
        }
    }

    func importAccount(password: String, privateKey: String) {
        web3.importAccount(privateKey: privateKey, encrypedPassword: password){ [weak self] state, address, keystore,error in
            guard let self = self else { return }
            self.importAccountBtn.isEnabled = true
            if state {
                let text =
                    "address: " + address + "\n\n" +
                    "keystore: " + "\n" + keystore
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
