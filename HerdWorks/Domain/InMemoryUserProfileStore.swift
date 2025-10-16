import Foundation

actor InMemoryUserProfileStore: UserProfileStore {
    private var storage: [String: UserProfile] = [:]

    func createOrUpdate(_ profile: UserProfile) async throws {
        if let existing = storage[profile.userId] {
            // Preserve createdAt, bump updatedAt
            let updated = UserProfile(
                userId: existing.userId,
                firstName: profile.firstName,
                lastName: profile.lastName,
                email: profile.email,
                phoneNumber: profile.phoneNumber,
                personalAddress: profile.personalAddress,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
            storage[profile.userId] = updated
        } else {
            storage[profile.userId] = profile
        }
    }

    func fetch(userId: String) async throws -> UserProfile? {
        return storage[userId]
    }

    func delete(userId: String) async throws {
        storage[userId] = nil
    }
}
