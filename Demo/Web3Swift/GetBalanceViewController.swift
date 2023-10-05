//
//  GetBalanceViewController.swift
//  Web3Swift
//
//  Created by smithSophiav on 2023/8/26.
//

import UIKit
import SnapKit
import EtherWallet
enum GetBalanceType: String, CaseIterable {
    case getETHBalance
    case getERC20TokenBalance
}

class GetBalanceViewController: UIViewController {
    var chainType: ChainType = .main
    var operationType: OperationType = .getETHBalance
    lazy var web3: Web3_v1 = .init()

    lazy var getBalanceBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("getBalance", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(getBalanceAction), for: .touchUpInside)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        return btn
    }()

    lazy var balanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.text = "wait for get balance…"
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    lazy var addressField: UITextField = {
        let addressField = UITextField()
        addressField.borderStyle = .line
        addressField.placeholder = "please input address"
        addressField.adjustsFontSizeToFitWidth = true
        addressField.minimumFontSize = 0.5
        addressField.text = "0x28c6c06298d514db089934071355e5743bf21d60"
        return addressField
    }()

    lazy var erc20AddressTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .line
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 0.5
        textField.placeholder = "please input erc20Contract Address"
        return textField
    }()

    init(_ chainType: ChainType, _ operationType: OperationType) {
        super.init(nibName: nil, bundle: nil)
        self.chainType = chainType
        self.operationType = operationType
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("GetBalanceViewController")
        setupView()
        // Do any additional setup after loading the view.
    }

    deinit {
        print("\(type(of: self)) release")
    }

    func setupView() {
        setupNav()
        setupContent()
    }

    func setupNav() {
        title = chainType == .main ? "get balance in main" :"get balance in goerli"
    }

    func setupContent() {
        view.backgroundColor = .white
        view.addSubviews(getBalanceBtn, addressField, erc20AddressTextField, balanceLabel)
        getBalanceBtn.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.bottom.equalTo(-100)
            make.height.equalTo(40)
        }
        addressField.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(150)
            make.height.equalTo(40)
        }
        balanceLabel.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.bottom.equalTo(getBalanceBtn.snp.top).offset(-20)
            make.height.equalTo(40)
        }
        erc20AddressTextField.snp.makeConstraints { make in
            make.left.equalTo(margin)
            make.right.equalTo(-margin)
            make.top.equalTo(addressField.snp.bottom).offset(20)
            make.height.equalTo(44)
        }
        erc20AddressTextField.isHidden = operationType == .getETHBalance
        erc20AddressTextField.text = (chainType == .main) ? erc20USDTAddress : ""
    }

    @objc func getBalanceAction() {
        print("getBalanceAction")
        getBalanceBtn.isEnabled = false
        balanceLabel.text = "querying balance"
        guard let address = addressField.text, let erc20Address = erc20AddressTextField.text else { return }
        if web3.isWeb3LoadFinished {
            operationType == .getETHBalance ? getETHBalance(address: address) : getERC20Balance(address: address, contractAddress: erc20Address, symbol: "USDT")
        } else {
            web3.setup { [weak self] web3LoadFinished in
                guard let self = self else { return }
                if web3LoadFinished {
                    self.operationType == .getETHBalance ? self.getETHBalance(address: address) : self.getERC20Balance(address: address, contractAddress: erc20Address, symbol: "USDT")
                }
            }
        }
    }

    func getETHBalance(address: String) {
        print("start get ETH Balance")
        
        let providerUrl = chainType == .main ? MainNet : "https://goerli.infura.io/v3/fe816c09404d406f8f47af0b78413806"
        
        web3.getETHBalance(address: address,providerUrl: providerUrl) { [weak self] (state,balance,error) in
            guard let self = self else { return }
            self.getBalanceBtn.isEnabled = true
            if state {
                let title = chainType == .main ? "main balance：" : "goerli balance: "
                self.balanceLabel.text = title + balance
                print("balance = \(balance)")
            } else {
                self.balanceLabel.text = error
            }
        }
    }

    func getERC20Balance(address: String, contractAddress: String, symbol: String) {
        print("start get ERC20 Balance")
        
        let providerUrl = chainType == .main ? MainNet : "https://goerli.infura.io/v3/fe816c09404d406f8f47af0b78413806"
        
        web3.getERC20TokenBalance(address: address,
                                  contractAddress: contractAddress,
                                  decimals: 6.0,
                                  providerUrl:providerUrl) { [weak self] (state,balance,error) in
            guard let self = self else { return }
            self.getBalanceBtn.isEnabled = true
            if state {
                let title = chainType == .main ? "main balance：" : "goerli balance: "
                self.balanceLabel.text = title + balance + symbol
            } else {
                self.balanceLabel.text = error
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
