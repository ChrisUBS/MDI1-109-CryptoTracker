//
//  JSONManager.swift
//  CryptoTracker
//
//  Created by Christian Bonilla on 03/11/25.
//

import Foundation
import CoreData
import SwiftUI
internal import Combine

@MainActor
final class JSONManager: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published var statusMessage: String? = nil

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Export Holdings
    func exportHoldings(_ holdings: [Holding], currentPrices: [String: (Double, Date)]) throws -> Data {
        let dtos = holdings.compactMap { holding -> HoldingDTO? in
            guard let symbol = holding.symbol, let buyAt = holding.buyAt else { return nil }
            let cur = currentPrices[symbol]
            return HoldingDTO(
                symbol: symbol,
                buyPrice: holding.buyPrice,
                buyAtISO: HoldingDTO.iso(buyAt),
                currentPrice: cur?.0,
                currentAtISO: cur.map { HoldingDTO.iso($0.1) },
                note: holding.note
            )
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        statusMessage = "Exported \(dtos.count) holdings successfully."
        return try encoder.encode(dtos)
    }

    // MARK: - Import Holdings
    @MainActor
    func importHoldings(from data: Data) throws {
        let decoder = JSONDecoder()
        let dtos = try decoder.decode([HoldingDTO].self, from: data)

        for dto in dtos {
            upsertHolding(dto: dto)
        }

        if context.hasChanges {
            try context.save()
            context.refreshAllObjects() // 🔥 fuerza a Core Data a notificar cambios
        }

        statusMessage = "Imported \(dtos.count) holdings successfully."
    }

    private func upsertHolding(dto: HoldingDTO) {
        let req: NSFetchRequest<Holding> = Holding.fetchRequest()
        req.predicate = NSPredicate(
            format: "symbol == %@ AND buyAt == %@",
            dto.symbol,
            ISO8601DateFormatter().date(from: dto.buyAtISO)! as NSDate
        )
        req.fetchLimit = 1

        let existing = (try? context.fetch(req))?.first
        let holding = existing ?? Holding(context: context)

        holding.id = existing?.id ?? UUID()
        holding.symbol = dto.symbol
        holding.buyPrice = dto.buyPrice
        holding.buyAt = ISO8601DateFormatter().date(from: dto.buyAtISO)
        holding.note = dto.note
    }
}
