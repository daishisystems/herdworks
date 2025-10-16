import Testing
import Foundation

@testable import HerdWorks

@Suite("UserProfileStore unit tests")
struct UserProfileStoreTests {

    @Test("Create new profile sets timestamps and fields")
    @MainActor
    func createProfile() async throws {
        let store = InMemoryUserProfileStore()
        let profile = UserProfile(
            userId: "u1",
            firstName: "Alex",
            lastName: "Farmer",
            email: "alex@example.com",
            phoneNumber: "555-0100",
            personalAddress: Address(
                street: "1 Farm Lane",
                city: "Fieldtown",
                state: "CA",
                zipCode: "95014",
                country: "US"
            )
        )

        try await store.createOrUpdate(profile)
        let fetched = try await store.fetch(userId: "u1")
        let saved = try #require(fetched)

        #expect(saved == profile)
        #expect(saved.createdAt <= saved.updatedAt)
    }

    @Test("Update profile preserves createdAt and bumps updatedAt")
    @MainActor
    func updateProfile() async throws {
        let store = InMemoryUserProfileStore()
        let userId = "u2"
        var p = UserProfile(
            userId: userId,
            firstName: "Alex",
            lastName: "Farmer",
            email: "alex@example.com",
            phoneNumber: "555-0100",
            personalAddress: Address(
                street: "1 Farm Lane",
                city: "Fieldtown",
                state: "CA",
                zipCode: "95014",
                country: "US"
            )
        )
        try await store.createOrUpdate(p)
        let original = try #require(try await store.fetch(userId: userId))
        let originalCreatedAt = original.createdAt
        let originalUpdatedAt = original.updatedAt

        p = p.updatedProfile(
            firstName: "Alexandra",
            lastName: "Farmer",
            email: "alex@example.com",
            phoneNumber: "555-0100",
            personalAddress: p.personalAddress
        )
        try await store.createOrUpdate(p)

        let updated = try #require(try await store.fetch(userId: userId))
        #expect(updated.firstName == "Alexandra")
        #expect(updated.createdAt == originalCreatedAt)
        #expect(updated.updatedAt >= originalUpdatedAt)
    }

    @Test("Fetch returns nil when user does not exist")
    @MainActor
    func fetchMissing() async throws {
        let store = InMemoryUserProfileStore()
        let result = try await store.fetch(userId: "missing")
        #expect(result == nil)
    }

    @Test("Delete removes profile")
    @MainActor
    func deleteProfile() async throws {
        let store = InMemoryUserProfileStore()
        let userId = "u3"
        let p = UserProfile(
            userId: userId,
            firstName: "A",
            lastName: "B",
            email: "a@b.com",
            phoneNumber: "555",
            personalAddress: Address(
                street: "S",
                city: "C",
                state: "ST",
                zipCode: "Z",
                country: "US"
            )
        )
        try await store.createOrUpdate(p)
        try await store.delete(userId: userId)
        let result = try await store.fetch(userId: userId)
        #expect(result == nil)
    }

    @Test("isProfileComplete reflects validity")
    func profileCompleteness() {
        var p = UserProfile(
            userId: "u4",
            firstName: "A",
            lastName: "B",
            email: "a@b.com",
            phoneNumber: "555",
            personalAddress: Address(
                street: "S",
                city: "C",
                state: "ST",
                zipCode: "Z",
                country: "US"
            )
        )
        #expect(p.isProfileComplete == true)

        p.firstName = ""
        #expect(p.isProfileComplete == false)
    }
}

