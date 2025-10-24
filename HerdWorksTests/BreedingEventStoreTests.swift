//
//  BreedingEventStoreTests 2.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/24.
//

import Testing
@testable import HerdWorks

@Suite struct BreedingEventStoreTests {

  @Test @MainActor
  func fetchAllReturnsSampleEvents() async throws {
    // Arrange
    let store = InMemoryBreedingEventStore.withSampleData()

    // Act
    let events = try await store.fetchAll(
      userId: "preview-user",
      farmId: "preview-farm",
      groupId: "preview-group"
    )

    // Assert
    #expect(!events.isEmpty, "Expected sample events to be returned")
  }

  @Test @MainActor
  func fetchAllFiltersByIds() async throws {
    let store = InMemoryBreedingEventStore.withSampleData()
    let events = try await store.fetchAll(
      userId: "preview-user",
      farmId: "preview-farm",
      groupId: "preview-group"
    )

    // Example of richer checks
    #expect(events.allSatisfy { $0.userId == "preview-user" })
    #expect(events.allSatisfy { $0.farmId == "preview-farm" })
      #expect(events.allSatisfy { $0.lambingSeasonGroupId == "preview-group" })
  }
}
