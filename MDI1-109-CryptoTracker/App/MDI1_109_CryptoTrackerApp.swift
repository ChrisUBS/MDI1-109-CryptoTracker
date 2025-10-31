//
//  MDI1_109_CryptoTrackerApp.swift
//  MDI1-109-CryptoTracker
//
//  Created by Christian Bonilla on 30/10/25.
//

import SwiftUI
internal import CoreData

@main
struct MDI1_109_CryptoTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
