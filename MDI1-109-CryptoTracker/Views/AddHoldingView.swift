//
//  AddHoldingView.swift
//  CryptoTracker
//
//  Created by Christian Bonilla on 03/11/25.
//

import SwiftUI

struct AddHoldingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HoldingsViewModel

    @State private var symbol = ""
    @State private var buyPrice = ""
    @State private var buyAt = Date()
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Symbol (e.g. BTC)", text: $symbol)
                        .autocapitalization(.allCharacters)
                    TextField("Buy price (USD)", text: $buyPrice)
                        .keyboardType(.decimalPad)
                    DatePicker("Buy date", selection: $buyAt, displayedComponents: [.date, .hourAndMinute])
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("New Holding")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let price = Double(buyPrice), !symbol.isEmpty {
                            viewModel.addHolding(symbol: symbol, buyPrice: price, buyAt: buyAt, note: note)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
