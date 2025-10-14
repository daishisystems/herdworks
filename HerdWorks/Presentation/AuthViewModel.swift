//
//  AuthViewModel.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//


import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode: Hashable { case signIn, signUp }

    @Published var mode: Mode = .signIn
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isBusy: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var currentUser: AuthUser?

    private let useCases: AuthUseCases
    private var authStateTask: Task<Void, Never>?

    init(repo: AuthRepository) {
        self.useCases = AuthUseCases(repo: repo)
        self.observeAuth()
    }

    deinit { authStateTask?.cancel() }

    func observeAuth() {
        authStateTask?.cancel()
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await user in self.useCases.authState() {
                self.currentUser = user
            }
        }
    }

    func signIn() async {
        await run {
            _ = try await self.useCases.signIn(email: self.email, password: self.password)
        }
    }

    func signUp() async {
        await run {
            _ = try await self.useCases.signUp(email: self.email, password: self.password)
        }
    }

    func resetPassword() async {
        await run {
            try await self.useCases.resetPassword(email: self.email)
        }
    }

    func signOut() {
        do {
            try useCases.signOut()
            errorMessage = nil
        } catch {
            errorMessage = FirebaseAuthRepository.friendly(error).message
        }
    }

    // MARK: - Helper

    private func run(_ work: @escaping () async throws -> Void) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await work()
        } catch {
            errorMessage = FirebaseAuthRepository.friendly(error).message
        }
    }
}
