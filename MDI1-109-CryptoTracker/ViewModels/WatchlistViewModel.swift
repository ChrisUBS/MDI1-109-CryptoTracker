//
//  WatchlistViewModel.swift
//  CryptoTracker
//
//  Created by Christian Bonilla on 03/11/25.
//

import Foundation
internal import Combine

@MainActor
final class WatchlistViewModel: ObservableObject {
    @Published var prices: [String: (Double, Date)] = [:]
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let api = CryptoAPI.shared
    private let manager = WatchlistManager.shared

    func fetchPrices() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await api.fetchPrices(for: manager.symbols)
            prices = result
        } catch {
            if let cryptoError = error as? CryptoAPIError {
                errorMessage = cryptoError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func formattedPrice(for symbol: String) -> String {
        guard let price = prices[symbol]?.0 else { return "—" }
        return String(format: "$%.2f", price)
    }

    func formattedDate(for symbol: String) -> String {
        guard let date = prices[symbol]?.1 else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
