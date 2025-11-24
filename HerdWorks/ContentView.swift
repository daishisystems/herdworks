//
//  ContentView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/10.
//  Note: This file is deprecated and no longer used in the app.
//  The app uses RootView as its entry point.
//  This file is kept for legacy reference and can be safely deleted.
//

import SwiftUI

/// DEPRECATED: This view is no longer used in the application.
/// See RootView.swift for the actual app entry point.
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

// Preview removed to eliminate deprecation warnings
// This file can be safely deleted from the project
