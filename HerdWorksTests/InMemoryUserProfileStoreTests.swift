import Foundation
import Testing
@testable import HerdWorks

@MainActor
@Suite
struct InMemoryUserProfileStoreTests {

  func makeProfile(
    userId: String = "u1",
    firstName: String = "A",
    lastName: String = "Z",
    email: String = "a@example.com",
    phoneNumber: String = "555-0000",
    address: Address? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) -> UserProfile {
    let resolvedAddress = address ?? Address(street: "1 Main St", city: "Town", state: "ST", zipCode: "12345", country: "US")
    return UserProfile(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      personalAddress: resolvedAddress,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }

  @Test
  func testCreateStoresProfileAndFetchReturnsIt() async throws {
      let store = InMemoryUserProfileStore()
    let now = Date()
    let profile = makeProfile(createdAt: now, updatedAt: now)

    try await store.createOrUpdate(profile)

    let fetched = try #require(await store.fetch(userId: profile.userId))
    #expect(fetched.userId == profile.userId)
    #expect(fetched.firstName == profile.firstName)
    #expect(fetched.createdAt == profile.createdAt)
    #expect(fetched.updatedAt == profile.updatedAt)
  }

  @Test
  func testUpdatePreservesCreatedAtAndBumpsUpdatedAt() async throws {
      let store = InMemoryUserProfileStore()
    let createdAt = Date()
    let original = makeProfile(createdAt: createdAt, updatedAt: createdAt)

    try await store.createOrUpdate(original)

    // Small delay to ensure updatedAt will be different
    try await Task.sleep(nanoseconds: 1_000_000)

    let updatedAt = Date()
    let updated = UserProfile(
      userId: original.userId,
      firstName: "B",
      lastName: original.lastName,
      email: original.email,
      phoneNumber: original.phoneNumber,
      personalAddress: original.personalAddress,
      createdAt: original.createdAt,
      updatedAt: updatedAt
    )

    try await store.createOrUpdate(updated)

    let fetched = try #require(await store.fetch(userId: original.userId))
    #expect(fetched.userId == original.userId)
    #expect(fetched.firstName == "B")
    #expect(fetched.createdAt == createdAt)
    #expect(fetched.updatedAt >= original.updatedAt)
  }

  @Test
  func testDeleteRemovesProfile() async throws {
    let store = InMemoryUserProfileStore()
    let profile = makeProfile()

    try await store.createOrUpdate(profile)

    var fetched = try await store.fetch(userId: profile.userId)
    #expect(fetched != nil)

    try await store.delete(userId: profile.userId)

    fetched = try await store.fetch(userId: profile.userId)
    #expect(fetched == nil)
  }
}

