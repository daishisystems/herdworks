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
        #if DEBUG
        print("🔐 [SIGN-IN] Attempting sign in for: \(email)")
        #endif
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            #if DEBUG
            print("✅ [SIGN-IN] Success for: \(email)")
            #endif
            
            return map(user: result.user)
        } catch {
            #if DEBUG
            let ns = error as NSError
            let authCode = AuthErrorCode(_bridgedNSError: ns)?.code
            print("❌ [SIGN-IN] Failed for: \(email)")
            print("   Error code: \(authCode?.rawValue ?? -1) (\(String(describing: authCode)))")
            print("   Error message: \(error.localizedDescription)")
            #endif
            throw error
        }
    }

    public func signUp(email: String, password: String) async throws -> AuthUser {
        #if DEBUG
        print("📝 [SIGN-UP] Attempting sign up for: \(email)")
        #endif
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            #if DEBUG
            print("✅ [SIGN-UP] Success for: \(email)")
            #endif
            
            return map(user: result.user)
        } catch {
            #if DEBUG
            let ns = error as NSError
            let authCode = AuthErrorCode(_bridgedNSError: ns)?.code
            print("❌ [SIGN-UP] Failed for: \(email)")
            print("   Error code: \(authCode?.rawValue ?? -1) (\(String(describing: authCode)))")
            print("   Error message: \(error.localizedDescription)")
            #endif
            throw error
        }
    }

    public func signOut() throws {
        try Auth.auth().signOut()
    }

    public func sendPasswordReset(email: String) async throws {
        print("🔄 [PASSWORD-RESET] Attempting to send password reset to: \(email)")
        print("🔄 [PASSWORD-RESET] Trimmed email: '\(email.trimmingCharacters(in: .whitespacesAndNewlines))'")
        
        // ✅ FIX: Trim whitespace from email
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: cleanEmail)
            print("✅ [PASSWORD-RESET] Firebase accepted the request for: \(cleanEmail)")
            print("✅ [PASSWORD-RESET] Check your email inbox AND spam/junk folder")
            print("✅ [PASSWORD-RESET] Email may take 1-5 minutes to arrive")
        } catch let error as NSError {
            print("❌ [PASSWORD-RESET] Failed with error:")
            print("   Error code: \(error.code)")
            print("   Error domain: \(error.domain)")
            print("   Error localizedDescription: \(error.localizedDescription)")
            
            // Check for specific Firebase Auth error codes
            if let authError = AuthErrorCode(rawValue: error.code) {
                print("   Firebase Auth Error Code: \(authError)")
                switch authError {
                case .userNotFound:
                    print("   ⚠️ This email is not registered in Firebase")
                case .invalidEmail:
                    print("   ⚠️ The email format is invalid")
                case .tooManyRequests:
                    print("   ⚠️ Too many password reset attempts - wait 10-15 minutes")
                default:
                    print("   ⚠️ Other auth error: \(authError)")
                }
            }
            
            throw error
        }
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

        #if DEBUG
        // Log the actual error code for debugging
        print("🔍 [AUTH-ERROR] Firebase Error Code: \(code.rawValue)")
        print("🔍 [AUTH-ERROR] Error Description: \(ns.localizedDescription)")
        #endif

        let message: String
        switch code {
        // MARK: - Email/Password Issues
        case .invalidEmail:
            message = "The email address is invalid. Please check and try again."
        case .emailAlreadyInUse:
            message = "This email is already in use. Please sign in instead."
        case .weakPassword:
            message = "Password is too weak. Use at least 6 characters."
        case .missingEmail:
            message = "Please enter your email address."
        
        // MARK: - Sign In Issues
        case .wrongPassword:
            message = "Incorrect email or password. Double-check your password or use 'Forgot Password' to reset it."
        case .invalidCredential:
            // ✅ FIX: Firebase now uses this for wrong password/email
            message = "Incorrect email or password. Double-check your password or use 'Forgot Password' to reset it."
        case .userNotFound:
            message = "No account found with this email. Please check your email address or sign up for a new account."
        case .userDisabled:
            message = "This account has been disabled. Please contact support."
        case .userMismatch:
            message = "The credentials don't match this account."
        
        // MARK: - Network & Rate Limiting
        case .networkError:
            message = "Network error. Please check your internet connection and try again."
        case .tooManyRequests:
            message = "Too many failed attempts. Please wait 10-15 minutes and try again."
        
        // MARK: - Session Issues
        case .userTokenExpired:
            message = "Your session has expired. Please sign in again."
        case .requiresRecentLogin:
            message = "This action requires a recent login. Please sign in again."
        case .invalidUserToken:
            message = "Your session is invalid. Please sign in again."
        
        // MARK: - Multi-Factor Authentication
        case .secondFactorRequired:
            message = "Two-factor authentication is required."
        case .maximumSecondFactorCountExceeded:
            message = "Maximum number of second factors exceeded."
        
        // MARK: - Configuration Issues
        case .operationNotAllowed:
            message = "This sign-in method is not enabled. Please contact support."
        case .invalidAPIKey:
            message = "App configuration error. Please contact support."
        case .appNotAuthorized:
            message = "This app is not authorized. Please contact support."
        
        // MARK: - Provider Issues
        case .accountExistsWithDifferentCredential:
            message = "An account already exists with the same email but different sign-in method."
        case .credentialAlreadyInUse:
            message = "This credential is already in use."
        
        // MARK: - Other Common Issues
        case .internalError:
            message = "An internal error occurred. Please try again later."
        case .webContextCancelled:
            message = "Sign-in was cancelled."
        case .webContextAlreadyPresented:
            message = "A sign-in is already in progress."
        
        default:
            // ✅ FIX: Better fallback with the actual error for transparency
            #if DEBUG
            message = "Authentication error: \(ns.localizedDescription)"
            #else
            message = "Unable to sign in. Please check your email and password and try again. If the problem persists, please contact support."
            #endif
        }

        return AuthFriendlyError(message: message, underlying: ns)
    }
}
