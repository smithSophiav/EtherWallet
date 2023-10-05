//
//  TransferViewController.swift
//  Web3Swift
//
//  Created by smithSophiav on 2023/8/26.
//

import SafariServices
import SnapKit
import UIKit
import EtherWallet
enum TransferType: String, CaseIterable {
    case sendETH
    case sendERC20Token
}

class TransferViewController: UIViewController {
    var chainType: ChainType = .main
    var transferType: TransferType = .sendETH
    lazy var web3: Web3_v1 = {
        let tronweb = Web3_v1()
        return tronweb
    }()

    lazy var transferBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("Start Transfer", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(transferAction), for: .touchUpInside)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        return btn
    }()
    
    lazy var privateKeyTextView: UITextView = {
        let textView = UITextView()
        // ce3d417791511ecf059e9fa1375
        // b6579d16bd2944a52cead6de1bb5bbb15abe8
        let p1 = "6a0a5b7cf783129266cf1c50"
        let p2 = "9eebe05c54e33d5341c7b96fb0b17b4882d7c6da"
//        let p1 = "ce3d417791511ecf059e9fa1375"
//        let p2 = "b6579d16bd2944a52cead6de1bb5bbb15abe8"
        textView.text = p1 + p2
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.brown.cgColor
        return textView
    }()
    
    lazy var reviceAddressField: UITextField = {
        let reviceAddressField = UITextField()
        reviceAddressField.adjustsFontSizeToFitWidth = true
        reviceAddressField.minimumFontSize = 0.5
        reviceAddressField.borderStyle = .line
        reviceAddressField.placeholder = "please input recipient address"
        reviceAddressField.text = "0x8A1a6B95bd4749e64d678E5Acc1D04E2A4DFD696"
        return reviceAddressField
    }()
    
    lazy var erc20AddressTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .line
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 0.5
        textField.placeholder = "please input erc20 contract address"
        return textField
    }()
    
    lazy var amountTextField: UITextField = {
        let amountTextField = UITextField()
        amountTextField.borderStyle = .line
        amountTextField.keyboardType = .numberPad
        amountTextField.placeholder = "please input amount"
        amountTextField.text = "0.0001"
        amountTextField.delegate = self
        return amountTextField
    }()
    
    lazy var hashLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "Transaction Hash"
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .center
        label.textColor = .blue
        label.backgroundColor = .lightGray
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        return label
    }()
    
    lazy var detailBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("get detail in etherscan.io", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(queryAction), for: .touchUpInside)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        return btn
    }()
    
    init(_ chainType: ChainType, _ transferType: TransferType) {
        super.init(nibName: nil, bundle: nil)
        self.chainType = chainType
        self.transferType = transferType
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TransferViewController")
        setupView()
    }

    func setupView() {
        setupNav()
        setupContent()
    }

    func setupNav() {
        title = chainType == .main ? "mainnet transfer" : "goerlNet transfer"
    }
    
    func setupContent() {
        view.backgroundColor = .white
        view.addSubviews(transferBtn, privateKeyTextView, reviceAddressField, amountTextField, erc20AddressTextField, hashLabel, detailBtn)
        transferBtn.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.bottom.equalTo(-100)
            make.height.equalTo(40)
        }
        detailBtn.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.bottom.equalTo(transferBtn.snp.top).offset(-20)
            make.height.equalTo(40)
        }
        hashLabel.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.bottom.equalTo(detailBtn.snp.top).offset(-20)
            make.height.equalTo(60)
        }
        privateKeyTextView.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(150)
            make.height.equalTo(80)
        }
        
        reviceAddressField.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(privateKeyTextView.snp.bottom).offset(20)
            make.height.equalTo(44)
        }
        amountTextField.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(reviceAddressField.snp.bottom).offset(20)
            make.height.equalTo(44)
        }
        erc20AddressTextField.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(amountTextField.snp.bottom).offset(20)
            make.height.equalTo(44)
        }
       
        erc20AddressTextField.isHidden = transferType == .sendETH
        erc20AddressTextField.text = (chainType == .main) ? erc20USDTAddress : ""
    }

    func ethTransfer() {
        guard let reviceAddress = reviceAddressField.text,
              let amountText = amountTextField.text, let privateKey = privateKeyTextView.text else { return }
        
        let providerUrl = chainType == .main ? MainNet : "https://goerli.infura.io/v3/fe816c09404d406f8f47af0b78413806"

        web3.ETHTransfer(recipientAddress: reviceAddress,
                         amount: amountText,
                         senderPrivateKey: privateKey,
                         providerUrl: providerUrl) { [weak self] (state,txid,error) in
            guard let self = self else { return }
            print("state = \(state)")
            print("txid = \(txid)")
            if state {
                self.hashLabel.text = txid
            } else {
                self.hashLabel.text = error
            }
        }
    }
    
    func erc20Transfer() {
        guard let reviceAddress = reviceAddressField.text,
              let contractAddress = erc20AddressTextField.text,
              let amountText = amountTextField.text,
              let privateKey = privateKeyTextView.text else { return }
        let providerUrl = MainNet
        web3.erc20TokenTransfer(providerUrl: providerUrl,
                                senderPrivateKey: privateKey,
                                recipientAddress: reviceAddress,
                                erc20ContractAddress: contractAddress,
                                amount: amountText,
                                decimal: 6.0) { [weak self] (state,txid,error) in
            guard let self = self else { return }
            print("state = \(state)")
            print("txid = \(txid)")
            if state {
                self.hashLabel.text = txid
            } else {
                self.hashLabel.text = error
            }
        }
    }
 
    @objc func transferAction() {
        if web3.isWeb3LoadFinished {
            transferType == .sendETH ? ethTransfer() : erc20Transfer()
        } else {
            web3.setup { [weak self] web3LoadFinished in
                guard let self = self else { return }
                if web3LoadFinished {
                    self.transferType == .sendETH ? self.ethTransfer() : self.erc20Transfer()
                }
            }
        }
    }

    @objc func queryAction() {
        guard let hash = hashLabel.text, hash.count > 10 else { return }
        var urlString = chainType == .main ? "https://etherscan.io/tx/" : "https://goerli.etherscan.io/tx/"
        urlString += hash
        showSafariVC(for: urlString)
    }

    func showSafariVC(for url: String) {
        guard let url = URL(string: url) else {
            return
        }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: nil)
    }
    
    func estimateTransactionFee() {
        transferType == .sendETH ? estimateETHTransactionFee() : estimateERC20TransactionFee()
    }
    
    func estimateETHTransactionFee() {
        guard let reviceAddress = reviceAddressField.text,
              let amountText = amountTextField.text else { return }
        let senderAddress = "0x2bD47B6fbCb229dDc69534Ac564D93C264F70453"
        hashLabel.text = "estimate ETH Transaction Fee is caculating...."
        web3.estimateETHTransactionFee(recipientAddress: reviceAddress,
                                       senderAddress: senderAddress,
                                       amount: amountText) { [weak self] (state,estimateTransactionFee,error) in
            guard let self = self else { return }
            print("state = \(state)")
            print("estimateTransactionFee = \(estimateTransactionFee)")
            if state {
                self.hashLabel.text = "estimate Transaction Fee " + estimateTransactionFee + " ETH"
            } else {
                self.hashLabel.text = error
            }
        }
    }
    
    func estimateERC20TransactionFee() {
        guard let reviceAddress = reviceAddressField.text,
              let contractAddress = erc20AddressTextField.text,
              let amountText = amountTextField.text else { return }
        let providerUrl = MainNet
        let senderAddress = "0x2bD47B6fbCb229dDc69534Ac564D93C264F70453"
        
        hashLabel.text = "estimate ERC20 Transaction Fee is caculating...."
        
        web3.estimateERC20TransactionFee(providerUrl: providerUrl,
                                         recipientAddress: reviceAddress,
                                         senderAddress: senderAddress,
                                         amount: amountText,
                                         decimal: 6.0,
                                         contractAddress: contractAddress) { [weak self] (state,estimateTransactionFee,error) in
            guard let self = self else { return }
            print("state = \(state)")
            print("estimateTransactionFee = \(estimateTransactionFee)")
            if state {
                self.hashLabel.text = "estimate Transaction Fee " + estimateTransactionFee + " ETH"
            } else {
                self.hashLabel.text = error
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

extension TransferViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == amountTextField {
            if web3.isWeb3LoadFinished {
                estimateTransactionFee()
            } else {
                web3.setup { [weak self] web3LoadFinished in
                    guard let self = self else { return }
                    if web3LoadFinished {
                        estimateTransactionFee()
                    }
                }
            }
        }
    }
}
