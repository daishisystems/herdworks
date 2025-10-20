import Foundation

// ✅ Make it Sendable, no @MainActor needed
struct FirestoreUserProfileDTO: Codable, Equatable, Sendable {
    var userId: String
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var personalAddress: Address
    var createdAt: Date?
    var updatedAt: Date?
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

// ✅ No actor isolation needed for pure data transformation
struct UserProfileMapper {
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
