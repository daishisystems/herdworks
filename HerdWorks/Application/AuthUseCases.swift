//
//  AuthUseCases.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//


import Foundation

public struct AuthUseCases: Sendable {
    private let repo: AuthRepository

    public init(repo: AuthRepository) {
        self.repo = repo
    }

    public func signIn(email: String, password: String) async throws -> AuthUser {
        try await repo.signIn(email: email, password: password)
    }

    public func signUp(email: String, password: String) async throws -> AuthUser {
        try await repo.signUp(email: email, password: password)
    }

    public func signOut() throws {
        try repo.signOut()
    }

    public func resetPassword(email: String) async throws {
        try await repo.sendPasswordReset(email: email)
    }

    public func authState() -> AsyncStream<AuthUser?> {
        repo.authState()
    }
}
