//
//  WatchlistManager.swift
//  CryptoTracker
//
//  Created by Christian Bonilla on 03/11/25.
//

import Foundation
internal import Combine

final class WatchlistManager: ObservableObject {
    static let shared = WatchlistManager()
    private let key = "watchlistSymbols"
    private let defaults = UserDefaults.standard

    @Published var symbols: [String] = [] {
        didSet { save() }
    }

    init() {
        load()
    }

    func load() {
        if let saved = defaults.array(forKey: key) as? [String] {
            symbols = saved
        } else {
            // Default watchlist
            symbols = ["BTC", "ETH", "LTC"]
            save()
        }
    }

    func addSymbol(_ symbol: String) {
        let s = symbol.uppercased()
        guard !symbols.contains(s), symbols.count < 4 else { return }
        symbols.append(s)
    }

    func removeSymbol(_ symbol: String) {
        symbols.removeAll { $0 == symbol }
    }

    private func save() {
        defaults.set(symbols, forKey: key)
    }
}
