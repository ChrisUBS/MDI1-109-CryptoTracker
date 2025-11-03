//
//  CryptoAPI.swift
//  CryptoTracker
//
//  Created by Christian Bonilla on 03/11/25.
//

import Foundation

struct CryptoPrice: Codable {
    let symbol: String
    let price: Double
    let date: Date
}

enum CryptoAPIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case badStatus(Int)
    case decodingError
    case missingData
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Missing API key in Info.plist."
        case .invalidURL: return "Invalid API URL."
        case .invalidResponse: return "Invalid server response."
        case .badStatus(let code): return "Server returned HTTP \(code)."
        case .decodingError: return "Could not decode API data."
        case .missingData: return "No price data received."
        case .unknown(let err): return err.localizedDescription
        }
    }
}

final class CryptoAPI {
    static let shared = CryptoAPI()

    private let baseURL = "https://api.freecryptoapi.com/v1/getData"

    private var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "FREECRYPTO_API_KEY") as? String
    }

    func fetchPrices(for symbols: [String]) async throws -> [String: (Double, Date)] {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw CryptoAPIError.missingAPIKey
        }
        guard !symbols.isEmpty else {
            throw CryptoAPIError.missingData
        }

        guard var components = URLComponents(string: baseURL) else {
            throw CryptoAPIError.invalidURL
        }

        let joined = symbols.joined(separator: "+")
        components.queryItems = [URLQueryItem(name: "symbol", value: joined)]

        guard let url = components.url else { throw CryptoAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw CryptoAPIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw CryptoAPIError.badStatus(http.statusCode) }

        // Decoding structure from your screenshot
        struct APIResponse: Codable {
            let status: String
            let symbols: [SymbolInfo]

            struct SymbolInfo: Codable {
                let symbol: String
                let last: String
                let date: String
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted({
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd HH:mm:ss"
            f.timeZone = TimeZone.current
            return f
        }())

        guard let decoded = try? decoder.decode(APIResponse.self, from: data),
              decoded.status == "success" else {
            print("⚠️ Raw JSON:\n\(String(data: data, encoding: .utf8) ?? "")")
            throw CryptoAPIError.decodingError
        }

        var result: [String: (Double, Date)] = [:]
        for s in decoded.symbols {
            if let price = Double(s.last),
               let date = decoder.dateDecodingStrategy.dateFormatter?.date(from: s.date) {
                result[s.symbol] = (price, date)
            }
        }

        if result.isEmpty { throw CryptoAPIError.missingData }
        return result
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    var dateFormatter: DateFormatter? {
        switch self {
        case .formatted(let f): return f
        default: return nil
        }
    }
}
