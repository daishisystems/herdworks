import Foundation

// Firestore transport model with optional timestamps to tolerate pending server values
struct FirestoreUserProfileDTO: Codable, Equatable {
    var userId: String
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var personalAddress: Address
    var createdAt: Date? // server timestamp may be pending
    var updatedAt: Date? // server timestamp may be pending
}

extension FirestoreUserProfileDTO {
    init(fromDomain profile: UserProfile) {
        self.userId = profile.userId
        self.firstName = profile.firstName
        self.lastName = profile.lastName
        self.email = profile.email
        self.phoneNumber = profile.phoneNumber
        self.personalAddress = profile.personalAddress
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
    }
}

struct UserProfileMapper {
    /// Maps a DTO to a domain model, providing fallbacks when timestamps are pending.
    /// - Parameters:
    ///   - dto: The Firestore transport model (may contain nil timestamps when pending).
    ///   - lastKnown: An optional last-known domain model to preserve stable timestamps while offline.
    ///   - fallbackNow: A date to use when both dto and lastKnown are nil for timestamps.
    /// - Returns: A fully-populated domain UserProfile with non-optional dates.
    static func toDomain(dto: FirestoreUserProfileDTO, lastKnown: UserProfile? = nil, fallbackNow: Date = Date()) -> UserProfile {
        let created = dto.createdAt ?? lastKnown?.createdAt ?? fallbackNow
        let updatedCandidate = dto.updatedAt ?? lastKnown?.updatedAt ?? fallbackNow
        let updated = max(created, updatedCandidate)
        return UserProfile(
            userId: dto.userId,
            firstName: dto.firstName,
            lastName: dto.lastName,
            email: dto.email,
            phoneNumber: dto.phoneNumber,
            personalAddress: dto.personalAddress,
            createdAt: created,
            updatedAt: updated
        )
    }
}
