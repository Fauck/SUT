//
//  SUTApp.swift
//  SUT
//
//  Created by bokmacdev on 2025/12/9.
//

import SwiftUI

@main
struct SUTApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
