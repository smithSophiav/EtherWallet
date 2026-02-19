//
//  NetworkManager.swift
//  Web3Swift
//

import Foundation

/// Single source of truth for current network on iOS. Persists selection; does not call EtherWeb.
public final class NetworkManager {

    public static let shared = NetworkManager()

    public struct NetworkModel {
        public let key: String
        public let label: String
        public let rpcUrl: String
        public let chainId: String

        public init(key: String, label: String, rpcUrl: String, chainId: String) {
            self.key = key
            self.label = label
            self.rpcUrl = rpcUrl
            self.chainId = chainId
        }
    }

    private let defaultsKey = "com.wallet.Web3Swift.currentNetworkKey"

    private let networks: [NetworkModel] = [
        NetworkModel(
            key: "mainnet",
            label: "Mainnet",
            rpcUrl: "https://mainnet.infura.io/v3/fe816c09404d406f8f47af0b78413806",
            chainId: "1"
        ),
        NetworkModel(
            key: "sepolia",
            label: "Sepolia",
            rpcUrl: "https://sepolia.infura.io/v3/fe816c09404d406f8f47af0b78413806",
            chainId: "11155111"
        ),
    ]

    /// Current network key (persisted in UserDefaults). Read-only for consumers.
    public private(set) var currentNetworkKey: String

    private init() {
        let saved = UserDefaults.standard.string(forKey: defaultsKey) ?? "sepolia"
        self.currentNetworkKey = ["mainnet", "sepolia"].contains(saved) ? saved : "sepolia"
        if currentNetworkKey != saved {
            UserDefaults.standard.set(currentNetworkKey, forKey: defaultsKey)
        }
    }

    /// All available networks (matches config.js).
    public func allNetworks() -> [NetworkModel] {
        networks
    }

    /// Current network model, or nil if key not found.
    public func currentNetwork() -> NetworkModel? {
        networks.first { $0.key == currentNetworkKey }
    }

    /// Current RPC URL (from selected preset). Use this for Bridge calls instead of networkKey.
    public var currentRpcUrl: String {
        currentNetwork()?.rpcUrl ?? networks.first?.rpcUrl ?? ""
    }

    /// Current chain ID (from selected preset).
    public var currentChainId: String {
        currentNetwork()?.chainId ?? networks.first?.chainId ?? ""
    }

    /// Current network label for UI (e.g. "Mainnet", "Sepolia").
    public var currentNetworkLabel: String {
        currentNetwork()?.label ?? currentNetworkKey
    }

    /// Set current network by key. Ignores unknown keys; persists and posts notification.
    public func setCurrentNetwork(key: String) {
        guard networks.contains(where: { $0.key == key }) else { return }
        currentNetworkKey = key
        UserDefaults.standard.set(key, forKey: defaultsKey)
        NotificationCenter.default.post(name: .networkManagerDidChangeNetwork, object: nil)
    }
}

extension Notification.Name {
    public static let networkManagerDidChangeNetwork = Notification.Name("networkManagerDidChangeNetwork")
}
