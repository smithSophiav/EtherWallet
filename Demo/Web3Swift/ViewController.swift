//
//  ViewController.swift
//  Web3Swift
//
//  Created by mac on 2026/2/18.
//

import UIKit
import SnapKit
/// Home: entry list and navigation to each feature VC (matches PC wallet features).
class ViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private struct Row {
        let title: String
        let vcType: UIViewController.Type
    }

    private struct Section {
        let title: String
        let rows: [Row]
    }

    private lazy var sections: [Section] = [
        Section(title: "Network", rows: [
            Row(title: "Network", vcType: NetworkViewController.self),
        ]),
        Section(title: "Account", rows: [
            Row(title: "Generate Wallet", vcType: GenerateAccountViewController.self),
            Row(title: "Import from Private Key", vcType: ImportPrivateKeyViewController.self),
            Row(title: "Import from Mnemonic", vcType: ImportMnemonicViewController.self),
            Row(title: "Import from Keystore", vcType: ImportKeystoreViewController.self),
            Row(title: "Private Key to Keystore", vcType: ExportKeystoreViewController.self),
        ]),
        Section(title: "Sign", rows: [
            Row(title: "Sign Message", vcType: SignMessageViewController.self),
            Row(title: "Verify Message", vcType: VerifyMessageViewController.self),
        ]),
        Section(title: "Balance", rows: [
            Row(title: "ETH Balance", vcType: ETHBalanceViewController.self),
            Row(title: "ERC20 Balance", vcType: ERC20BalanceViewController.self),
        ]),
        Section(title: "Transfer", rows: [
            Row(title: "ETH Transfer", vcType: EthTransferViewController.self),
            Row(title: "ERC20 Transfer", vcType: Erc20TransferViewController.self),
        ]),
        Section(title: "Gas", rows: [
            Row(title: "Gas", vcType: GasViewController.self),
        ])
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ethereum Wallet"
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let c = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            cell = c
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
            cell.accessoryType = .disclosureIndicator
        }
        cell.textLabel?.text = sections[indexPath.section].rows[indexPath.row].title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        let vc = row.vcType.init()
        navigationController?.pushViewController(vc, animated: true)
    }
}

