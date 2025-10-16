import Foundation

actor InMemoryUserProfileStore: UserProfileStore {
    private var storage: [String: UserProfile] = [:]

    func createOrUpdate(_ profile: UserProfile) async throws {
        // Extract userId on the main actor to avoid cross-actor access to a main-actor isolated type
        let userId: String = await MainActor.run { profile.userId }

        if let existing = storage[userId] {
            // Build the updated profile on the main actor to satisfy main-actor isolated initializer
            let updated: UserProfile = await MainActor.run {
                UserProfile(
                    userId: userId,
                    firstName: profile.firstName,
                    lastName: profile.lastName,
                    email: profile.email,
                    phoneNumber: profile.phoneNumber,
                    personalAddress: profile.personalAddress,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
            }
            storage[userId] = updated
        } else {
            // No existing profile; store the provided profile using the extracted userId
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
