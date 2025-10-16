import Foundation

#if canImport(FirebaseFirestore) && canImport(FirebaseFirestoreSwift)
import FirebaseFirestore
import FirebaseFirestoreSwift

actor FirestoreUserProfileStore: UserProfileStore {
    private let db: Firestore
    private let collectionName: String

    init(db: Firestore = .firestore(), collectionName: String = "users") {
        self.db = db
        self.collectionName = collectionName
    }

    func createOrUpdate(_ profile: UserProfile) async throws {
        let ref = db.collection(collectionName).document(profile.userId)

        // Encode domain model to DTO first
        let dto = FirestoreUserProfileDTO(fromDomain: profile)
        var data = try FirestoreEncoder().encode(dto)

        // Use server timestamps: createdAt only if document doesn't exist; updatedAt always
        let snapshot = try await ref.getDocument()
        if snapshot.exists == false {
            data["createdAt"] = FieldValue.serverTimestamp()
        }
        data["updatedAt"] = FieldValue.serverTimestamp()

        try await ref.setData(data, merge: true)
    }

    func fetch(userId: String) async throws -> UserProfile? {
        let ref = db.collection(collectionName).document(userId)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists, var dto = try snapshot.data(as: FirestoreUserProfileDTO.self) else {
            return nil
        }
        // Map to domain; we don't have lastKnown here, so use fallback
        let domain = UserProfileMapper.toDomain(dto: dto)
        return domain
    }

    func delete(userId: String) async throws {
        let ref = db.collection(collectionName).document(userId)
        try await ref.delete()
    }
}

#else

// Fallback stub to keep builds green when Firebase isn't available.
actor FirestoreUserProfileStore: UserProfileStore {
    func createOrUpdate(_ profile: UserProfile) async throws { fatalError("Firebase not linked") }
    func fetch(userId: String) async throws -> UserProfile? { fatalError("Firebase not linked") }
    func delete(userId: String) async throws { fatalError("Firebase not linked") }
}

#endif
