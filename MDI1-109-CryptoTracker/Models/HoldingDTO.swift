//
//  HoldingDTO.swift
//  MDI1-109-CryptoTracker
//
//  Created by Christian Bonilla on 30/10/25.
//

import Foundation

/// Portable schema used for export/import. Separate from Core Data.
struct HoldingDTO: Codable, Hashable {
    var symbol: String
    var buyPrice: Double
    var buyAtISO: String
    var currentPrice: Double?
    var currentAtISO: String?
    var note: String?
    
    static func iso(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
