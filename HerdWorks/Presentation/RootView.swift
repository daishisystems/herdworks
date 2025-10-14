//
//  RootView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//

import SwiftUI
import FirebaseAuth

@MainActor
struct RootView: View {
    @State private var isSignedIn: Bool = (Auth.auth().currentUser != nil)
    @StateObject private var vm = AuthViewModel(repo: FirebaseAuthRepository())
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if isSignedIn {
                MainAppView()
            } else {
                AuthView(vm: vm)
            }
        }
        .onAppear(perform: startAuthStateListener)
        .onDisappear {
            stopAuthStateListener()
        }
    }

    private func startAuthStateListener() {
        guard authListenerHandle == nil else { return }
        authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            let nowSignedIn = (user != nil)
            if nowSignedIn != isSignedIn {
                print("✅ Auth state changed: \(nowSignedIn ? "signed in" : "signed out")")
                withAnimation {
                    isSignedIn = nowSignedIn
                }
            } else {
                // Still log initial state on first run
                print("ℹ️ Auth state: \(isSignedIn ? "signed in" : "signed out")")
            }
        }
    }

    private func stopAuthStateListener() {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authListenerHandle = nil
        }
    }
}

private struct MainAppView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Main App")
                    .font(.title)
                Text("You're signed in.")
                    .foregroundStyle(.secondary)
                Button("Sign out") {
                    try? Auth.auth().signOut()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("HerdWorks")
        }
    }
}

#Preview {
    RootView()
}
