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
    
    // ✅ FIX: Use a class to manage auth listener lifecycle properly
    @StateObject private var authManager = AuthStateManager()
    
    // ✅ FIX: Local state for alert presentation
    @State private var showProfileError = false
    @State private var profileErrorMessage: String?

    var body: some View {
        Group {
            if isSignedIn {
                LandingView()
            } else {
                AuthView(vm: vm)
            }
        }
        .onAppear {
            authManager.startListening { user in
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
        // ✅ FIX: Monitor profileGate error using onChange with error description
        .onChange(of: profileGate.error?.localizedDescription) { oldValue, newValue in
            if let errorDescription = newValue {
                profileErrorMessage = errorDescription
                showProfileError = true
            }
        }
        // ✅ FIX: Show error alert with proper state management
        .alert(
            "error.profile_load_failed_title".localized(),
            isPresented: $showProfileError
        ) {
            Button("common.ok".localized()) {
                profileGate.dismissError()
                showProfileError = false
            }
        } message: {
            if let message = profileErrorMessage {
                Text(message)
            }
        }
        // ✅ FIX: Show loading overlay during profile evaluation
        .overlay {
            if profileGate.isEvaluating {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// ✅ FIX: Dedicated class for auth state management
@MainActor
private class AuthStateManager: ObservableObject {
    private var handle: AuthStateDidChangeListenerHandle?
    
    func startListening(onChange: @escaping (User?) -> Void) {
        guard handle == nil else { return }
        handle = Auth.auth().addStateDidChangeListener { _, user in
            onChange(user)
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

#Preview {
    RootView()
}
