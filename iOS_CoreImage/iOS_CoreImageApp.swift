//
//  iOS_CoreImageApp.swift
//  iOS_CoreImage
//
//  Created by Niklas Diekhöner on 19.02.23.
//

import SwiftUI

@main
struct iOS_CoreImageApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
