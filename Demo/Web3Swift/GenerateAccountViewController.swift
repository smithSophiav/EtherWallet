//
//  GenerateWalletViewController.swift
//  Web3Swift
//
//  Created by smithSophiav on 2023/9/17.
//

import UIKit
import SnapKit
import EtherWallet
class GenerateAccountViewController: UIViewController {

    lazy var web3: Web3_v1 = .init()

    lazy var generateAccountBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("GenerateAccount", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(generateAccountAction), for: .touchUpInside)
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
    
    lazy var generateAccountTextView: UITextView = {
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
        title = "Generate Account"
    }

    func setupContent() {
        view.backgroundColor = .white
        view.addSubviews(generateAccountBtn, passwordField, generateAccountTextView)
        generateAccountBtn.snp.makeConstraints { make in
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
        generateAccountTextView.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(passwordField.snp.bottom).offset(20)
            make.bottom.equalTo(generateAccountBtn.snp.top).offset(-20)
        }
    }
    @objc func generateAccountAction() {
        print("generateAccountAction")
        generateAccountBtn.isEnabled = false
        guard let password = passwordField.text else { return }
        if web3.isWeb3LoadFinished {
            generateAccount(password: password)
        } else {
            web3.setup { [weak self] web3LoadFinished in
                guard let self = self else { return }
                if web3LoadFinished {
                    self.generateAccount(password: password)
                }
            }
        }
    }
    
    func generateAccount(password:String) {
        web3.generateAccount(password: password) { [weak self] (state, address,mnemonic,privateKey, keystore,error) in
            guard let self = self else { return }
            self.generateAccountBtn.isEnabled = true
            if state {
                let text =
                "address: " + address + "\n\n" +
                "mnemonic: " + mnemonic + "\n\n" +
                "privateKey: " + privateKey + "\n\n" +
                "keystore: " + keystore
                generateAccountTextView.text = text
            } else {
                generateAccountTextView.text = error
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
}
