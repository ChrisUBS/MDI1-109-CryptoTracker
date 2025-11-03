//
//  RootView.swift
//  MDI1-109-CryptoTracker
//
//  Created by Christian Bonilla on 30/10/25.
//

import SwiftUI
import CoreData

struct RootView: View {
    var body: some View {
        TabView {
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "list.bullet")
                }

            HoldingsView(context: PersistenceController.shared.container.viewContext)
                .tabItem {
                    Label("Holdings", systemImage: "bitcoinsign.circle")
                }
        }
    }
}
