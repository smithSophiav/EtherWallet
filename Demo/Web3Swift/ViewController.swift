//
//  ViewController.swift
//  Web3Swift
//
//  Created by smithSophiav on 2023/8/26.
//

import SnapKit
import UIKit
enum ChainType: String, CaseIterable {
    case main
}
enum OperationType: String, CaseIterable {
    case generateAccount
    case importAccountFromKeystore
    case importAccountFromPrivateKey
    case importAccountFromMnemonic
    case getETHBalance
    case getERC20TokenBalance
    case ethTransfer
    case erc20Transfer
    
}

class ViewController: UIViewController {
    lazy var chainTypes: [ChainType] = ChainType.allCases
    lazy var operationTypes: [OperationType] = OperationType.allCases
    lazy var transferTypes: [TransferType] = TransferType.allCases

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        title = "Web3Swift"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chainType = chainTypes[indexPath.section]
        let operationType = operationTypes[indexPath.row]
        switch operationType {
        case .generateAccount:
            navigationController?.pushViewController(GenerateAccountViewController(), animated: true)
        case .importAccountFromKeystore:
            navigationController?.pushViewController(ImportAccountFromKeystoreViewController(), animated: true)
        case .importAccountFromPrivateKey:
            navigationController?.pushViewController(ImportAccountFromPrivateKeyViewController(), animated: true)
        case .importAccountFromMnemonic:
            navigationController?.pushViewController(ImportAccountFromMnemonicViewController(), animated: true)
        case .ethTransfer,.erc20Transfer:
            let transferType = transferTypes[indexPath.row]
            let vc = TransferViewController(chainType, transferType)
            navigationController?.pushViewController(vc, animated: true)
        case .getERC20TokenBalance,.getETHBalance:
            let vc = GetBalanceViewController.init(chainType, operationType)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return operationTypes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
        let title = operationTypes[indexPath.row].rawValue
        cell.textLabel?.text = title
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return chainTypes.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = chainTypes[section]
        return title.rawValue
    }
}

public extension UIView {
    func addSubviews(_ subviews: UIView...) {
        for index in subviews {
            addSubview(index)
        }
    }
}
