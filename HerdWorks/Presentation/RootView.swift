//
//  RootView.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//

import SwiftUI
import FirebaseAuth
import Combine

@MainActor
struct RootView: View {
    @State private var isSignedIn: Bool = (Auth.auth().currentUser != nil)
    @StateObject private var vm = AuthViewModel(repo: FirebaseAuthRepository())
    @EnvironmentObject private var profileGate: ProfileGate

    var body: some View {
        Group {
            if isSignedIn {
                LandingView()
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
                if nowSignedIn, let uid = user?.uid {
                    Task { await profileGate.evaluate(for: uid) }
                } else {
                    profileGate.shouldPresentProfileEdit = false
                }
            }
        }
    }

    private func stopAuthStateListener() {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authListenerHandle = nil
            profileGate.shouldPresentProfileEdit = false
        }
    }
    
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?
}

#Preview {
    RootView()
}
