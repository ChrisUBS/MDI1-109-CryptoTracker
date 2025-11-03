//
//  WatchlistView.swift
//  CryptoTracker
//
//  Created by Christian Bonilla on 03/11/25.
//

import SwiftUI

struct WatchlistView: View {
    @StateObject private var manager = WatchlistManager.shared
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var newSymbol: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // MARK: - Input Field
                HStack(spacing: 12) {
                    TextField("Add symbol (e.g. BTC)", text: $newSymbol)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)

                    Button {
                        let trimmed = newSymbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        guard !trimmed.isEmpty else { return }
                        manager.addSymbol(trimmed)
                        newSymbol = ""
                        Task { await viewModel.fetchPrices() }
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(manager.symbols.count >= 4)
                }
                .padding(.horizontal)

                // MARK: - Content
                Group {
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Fetching latest prices…")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.red)
                                .font(.callout)
                            Button {
                                Task { await viewModel.fetchPrices() }
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise.circle.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 40)
                    } else if manager.symbols.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No symbols in your watchlist.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                    } else {
                        List {
                            ForEach(manager.symbols, id: \.self) { sym in
                                WatchlistRow(
                                    symbol: sym,
                                    price: viewModel.formattedPrice(for: sym),
                                    date: viewModel.formattedDate(for: sym)
                                )
                                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    manager.removeSymbol(manager.symbols[index])
                                }
                                Task { await viewModel.fetchPrices() }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                        .animation(.easeInOut, value: manager.symbols)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.isLoading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // MARK: - Refresh Button
                Button {
                    Task { await viewModel.fetchPrices() }
                } label: {
                    Label("Refresh Prices", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, 24)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.bottom)
            }
            .navigationTitle("📈 Watchlist")
            .toolbarBackground(.visible, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
            .task {
                await viewModel.fetchPrices()
            }
        }
    }
}

// MARK: - Row Component
private struct WatchlistRow: View {
    let symbol: String
    let price: String
    let date: String?

    var body: some View {
        HStack {
            Text(symbol)
                .font(.headline)
                .padding(.leading, 8)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(price)
                    .font(.title3.bold())
                if let date = date {
                    Text(date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }
}
