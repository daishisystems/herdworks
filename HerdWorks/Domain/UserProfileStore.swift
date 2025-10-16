import Foundation

protocol UserProfileStore {
    func createOrUpdate(_ profile: UserProfile) async throws
    func fetch(userId: String) async throws -> UserProfile?
    func delete(userId: String) async throws
}

enum UserProfileStoreError: Error, Equatable {
    case notFound
    case invalidData
}
