//
//  NetworkViewController.swift
//  Web3Swift
//

import UIKit
import SnapKit

/// Network selection. Uses only NetworkManager (no EtherWeb).
final class NetworkViewController: UIViewController {

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        return t
    }()

    private var networks: [NetworkManager.NetworkModel] {
        NetworkManager.shared.allNetworks()
    }

    private var currentNetworkKey: String {
        NetworkManager.shared.currentNetworkKey
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Network"
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkDidChange),
            name: .networkManagerDidChangeNetwork,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func networkDidChange() {
        tableView.reloadData()
    }
}

extension NetworkViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        networks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let c = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            cell = c
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        }
        let item = networks[indexPath.row]
        cell.textLabel?.text = item.label
        cell.detailTextLabel?.text = item.chainId
        cell.accessoryType = (currentNetworkKey == item.key) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = networks[indexPath.row].key
        NetworkManager.shared.setCurrentNetwork(key: key)
        tableView.reloadData()
    }
}
