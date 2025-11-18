import Foundation

import Foundation
import Combine

@MainActor
final class InMemoryUserProfileStore: UserProfileStore, ObservableObject {
    private var storage: [String: UserProfile] = [:]

    func createOrUpdate(_ profile: UserProfile) async throws {
        let userId = profile.userId

        if let existing = storage[userId] {
            let updated = UserProfile(
                userId: userId,
                firstName: profile.firstName,
                lastName: profile.lastName,
                email: profile.email,
                phoneNumber: profile.phoneNumber,
                personalAddress: profile.personalAddress,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
            storage[userId] = updated
        } else {
            storage[userId] = profile
        }
    }

    func fetch(userId: String) async throws -> UserProfile? {
        return storage[userId]
    }

    func delete(userId: String) async throws {
        storage[userId] = nil
    }
}
