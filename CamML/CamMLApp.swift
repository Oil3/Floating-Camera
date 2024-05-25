//
//  CamMLApp.swift
//  CamML
//
//  Created by Almahdi Morris on 05/25/24.
//

import SwiftUI

@main
struct CamMLApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
              //  .windowStyle(HiddenTitleBarWindowStyle())
        }
        .commands {
            CommandMenu("Camera") {
                Button("Take Photo") {
                    // Implement take photo action
                }
                Button("Copy Frame") {
                    // Implement copy frame action
                }
                Button("Pause Live Feed") {
                    // Implement pause live feed action
                }
                Button("Start Recording") {
                    // Implement start recording action
                }
            }
        }
    }
}
