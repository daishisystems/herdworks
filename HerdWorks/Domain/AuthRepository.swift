//
//  AuthRepository.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//


import Foundation

public protocol AuthRepository: Sendable {
    func signIn(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String) async throws -> AuthUser
    func signOut() throws
    func sendPasswordReset(email: String) async throws
    func authState() -> AsyncStream<AuthUser?>
}
