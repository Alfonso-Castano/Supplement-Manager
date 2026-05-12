//
//  StackWiseApp.swift
//  StackWise
//
//  Created by Alfonso (Picus) Castano on 5/11/26.
//

import SwiftUI
import CoreData

@main
struct StackWiseApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
