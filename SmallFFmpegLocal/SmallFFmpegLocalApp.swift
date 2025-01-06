//
//  SmallFFmpegLocalApp.swift
//  SmallFFmpegLocal
//
//  Created by Jose Vigil on 05/12/2024.
//

import SwiftUI

@main
struct SmallFFmpegApp: App {
    @State private var window: NSWindow?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 1000, height: 1000) // Set your initial view size
                .onAppear {
                    // Set the window size once it appears on screen
                    if let window = NSApplication.shared.windows.first {
                        self.window = window
                        window.setContentSize(NSSize(width: 800, height: 600)) // Set your window size
                        window.center() // Center the window if needed
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // Optional: hides the title bar
        .windowToolbarStyle(UnifiedWindowToolbarStyle()) // Optional: customizes the toolbar
    }
}
