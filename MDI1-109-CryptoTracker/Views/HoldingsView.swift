//
//  HoldingsView.swift
//  CryptoTracker
//
//  Created by Christian Bonilla on 03/11/25.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
internal import Combine

struct HoldingsView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: HoldingsViewModel
    @StateObject private var jsonManager: JSONManager
    @State private var showingAdd = false
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportData: Data?

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: HoldingsViewModel(context: context))
        _jsonManager = StateObject(wrappedValue: JSONManager(context: context))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 20) {
                    // Estado de carga / error / vacío
                    if viewModel.isLoading {
                        ProgressView("Fetching prices...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                    } else if let err = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(err)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await viewModel.fetchCurrentPrices() }
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if viewModel.holdings.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No holdings yet")
                                .font(.headline)
                            Text("Tap + to add your first crypto holding.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        List {
                            ForEach(viewModel.holdings) { holding in
                                HoldingCardView(
                                    holding: holding,
                                    current: viewModel.currentPrices[holding.symbol ?? ""],
                                    delta: viewModel.delta(for: holding.symbol ?? "", buyPrice: holding.buyPrice)
                                )
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let item = viewModel.holdings[index]
                                    viewModel.deleteHolding(item)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }

                    // Botón de refrescar precios
                    Button {
                        Task { await viewModel.fetchCurrentPrices() }
                    } label: {
                        Label("Refresh Prices", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("🚀 Holdings")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            do {
                                exportData = try jsonManager.exportHoldings(viewModel.holdings, currentPrices: viewModel.currentPrices)
                                showExporter = true
                            } catch {
                                viewModel.errorMessage = "Failed to export JSON: \(error.localizedDescription)"
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }

                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }

                    Button {
                        showingAdd.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddHoldingView(viewModel: viewModel)
            }
            .task {
                await viewModel.fetchCurrentPrices()
            }
            // MARK: - File Exporter / Importer
            .fileExporter(
                isPresented: $showExporter,
                document: exportData.map { JSONFile(data: $0) },
                contentType: .json,
                defaultFilename: "holdings-export.json"
            ) { result in
                if case .failure(let error) = result {
                    viewModel.errorMessage = "Export failed: \(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json]
            ) { result in
                Task {
                    do {
                        let selectedFile = try result.get()
                        let data = try Data(contentsOf: selectedFile)
                        try jsonManager.importHoldings(from: data)

                        // 🔁 Re-fetch + broadcast cambio
                        await MainActor.run {
                            viewModel.fetchHoldings()
                            viewModel.objectWillChange.send()
                            withAnimation(.easeInOut) {
                                viewModel.errorMessage = "✅ Import successful!"
                            }
                        }

                        // 🔄 También refrescar precios automáticamente
                        Task {
                            await viewModel.fetchCurrentPrices()
                        }

                    } catch {
                        await MainActor.run {
                            viewModel.errorMessage = "Import failed: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
}

// MARK: - HoldingCardView
private struct HoldingCardView: View {
    let holding: Holding
    let current: (Double, Date)?
    let delta: (Double, Double)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(holding.symbol ?? "")
                    .font(.title3.bold())
                Spacer()
                if let cur = current?.0 {
                    Text(String(format: "$%.2f", cur))
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
            }

            if let d = delta {
                let color: Color = d.0 >= 0 ? .green : .red
                HStack {
                    Image(systemName: d.0 >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.bold())
                    Text(String(format: "Δ %.2f (%.2f%%)", d.0, d.1))
                }
                .foregroundColor(color)
                .font(.subheadline)
            }

            Text("Bought at $\(holding.buyPrice, specifier: "%.2f") on \(holding.buyAt?.formatted(date: .numeric, time: .shortened) ?? "")")
                .font(.caption)
                .foregroundColor(.secondary)

            if let note = holding.note, !note.isEmpty {
                Text("“\(note)”")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 2)
        .transition(.opacity.combined(with: .scale))
    }
}
