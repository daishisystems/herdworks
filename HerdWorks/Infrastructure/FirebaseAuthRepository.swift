//
//  FirebaseAuthRepository.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//


import Foundation
import FirebaseAuth

public final class FirebaseAuthRepository: AuthRepository {
    public init() {}

    // MARK: - AuthRepository

    public func signIn(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return map(user: result.user)
    }

    public func signUp(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return map(user: result.user)
    }

    public func signOut() throws {
        try Auth.auth().signOut()
    }

    public func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    public func authState() -> AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user.map(self.map(user:)))
            }
            continuation.onTermination = { @Sendable _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    // MARK: - Mapping & Errors

    private func map(user: FirebaseAuth.User) -> AuthUser {
        AuthUser(uid: user.uid, email: user.email)
    }

    public struct AuthFriendlyError: LocalizedError, Equatable {
        public let message: String
        public let underlying: NSError?
        public var errorDescription: String? { message }
    }

    public static func friendly(_ error: Error) -> AuthFriendlyError {
        let ns = error as NSError
        // Build an AuthErrorCode from the NSError, then read its enum .code
        let code = AuthErrorCode(_bridgedNSError: ns)?.code ?? .internalError

        let message: String
        switch code {
        case .invalidEmail:         message = "The email address is invalid."
        case .emailAlreadyInUse:    message = "This email is already in use."
        case .weakPassword:         message = "Password is too weak."
        case .wrongPassword:        message = "Incorrect password."
        case .userNotFound:         message = "No account found with this email."
        case .networkError:         message = "Network error. Check your connection."
        case .tooManyRequests:      message = "Too many attempts. Try again later."
        default:                    message = ns.localizedDescription
        }

        return AuthFriendlyError(message: message, underlying: ns)
    }
}
