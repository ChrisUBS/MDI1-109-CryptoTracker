//
//  HoldingsViewModel.swift
//  CryptoTracker
//
//  Created by Christian Bonilla on 03/11/25.
//

import SwiftUI
import CoreData
internal import Combine

@MainActor
final class HoldingsViewModel: ObservableObject {
    @Published var holdings: [Holding] = []
    @Published var currentPrices: [String: (Double, Date)] = [:]
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let context: NSManagedObjectContext
    private let api = CryptoAPI.shared

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchHoldings()
    }

    func fetchHoldings() {
        let request = Holding.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Holding.buyAt, ascending: false)]
        holdings = (try? context.fetch(request)) ?? []
    }

    func fetchCurrentPrices() async {
        // Filtra símbolos válidos
        let symbols = holdings
            .compactMap { $0.symbol?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }
        guard !symbols.isEmpty else {
            errorMessage = "No holdings to update."
            return
        }

        isLoading = true
        do {
            let uniqueSymbols = Array(Set(symbols))
            let data = try await api.fetchPrices(for: uniqueSymbols)
            guard !data.isEmpty else {
                errorMessage = "No price data received."
                return
            }
            currentPrices = data
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addHolding(symbol: String, buyPrice: Double, buyAt: Date, note: String?) {
        let new = Holding(context: context)
        new.id = UUID()
        new.symbol = symbol.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        new.buyPrice = buyPrice
        new.buyAt = buyAt
        new.note = note
        save()
    }

    func deleteHolding(_ holding: Holding) {
        context.delete(holding)
        save()
    }

    func save() {
        do {
            try context.save()
            fetchHoldings()
        } catch {
            print("❌ Error saving: \(error)")
        }
    }

    // MARK: - Helpers
    func delta(for symbol: String, buyPrice: Double) -> (Double, Double)? {
        guard let cur = currentPrices[symbol]?.0 else { return nil }
        let diff = cur - buyPrice
        let percent = (diff / buyPrice) * 100
        return (diff, percent)
    }
}
