//
//  UserProfile.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/16.
//

import Foundation

/// Represents a user's personal profile information
/// Domain entity containing user data and business logic for profile completion
/// Designed for livestock farmers with personal address (separate from farm addresses)
struct UserProfile: Codable, Equatable, Sendable {
    let userId: String
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var personalAddress: Address
    let createdAt: Date
    var updatedAt: Date
    
    /// Creates a new UserProfile with current timestamps
    /// - Parameters:
    ///   - userId: Unique identifier (typically Firebase Auth UID)
    ///   - firstName: User's first name
    ///   - lastName: User's last name  
    ///   - email: User's email address
    ///   - phoneNumber: User's phone number
    ///   - personalAddress: User's personal/home address
    init(
        userId: String,
        firstName: String,
        lastName: String,
        email: String,
        phoneNumber: String,
        personalAddress: Address
    ) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.personalAddress = personalAddress
        
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
    
    /// Internal initializer for decoding and updates (preserves original createdAt)
    internal init(
        userId: String,
        firstName: String,
        lastName: String,
        email: String,
        phoneNumber: String,
        personalAddress: Address,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.personalAddress = personalAddress
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Computed property that determines if the user profile is complete
    /// Profile is complete when all required fields are filled and address is valid
    var isProfileComplete: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !email.isEmpty &&
               !phoneNumber.isEmpty &&
               isAddressComplete
    }
    
    /// Helper computed property to check address completeness
    private var isAddressComplete: Bool {
        return !personalAddress.street.isEmpty &&
               !personalAddress.city.isEmpty &&
               !personalAddress.state.isEmpty &&
               !personalAddress.zipCode.isEmpty &&
               !personalAddress.country.isEmpty
    }
    
    /// Creates an updated copy of the profile with new values and updated timestamp
    /// Follows functional programming principles for immutable updates
    /// - Parameters:
    ///   - firstName: Updated first name
    ///   - lastName: Updated last name
    ///   - email: Updated email address
    ///   - phoneNumber: Updated phone number
    ///   - personalAddress: Updated personal address
    /// - Returns: New UserProfile instance with updated values and current timestamp
    func updatedProfile(
        firstName: String,
        lastName: String,
        email: String,
        phoneNumber: String,
        personalAddress: Address
    ) -> UserProfile {
        return UserProfile(
            userId: self.userId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
            personalAddress: personalAddress,
            createdAt: self.createdAt, // Preserve original creation time
            updatedAt: Date()          // Set new update time
        )
    }
}
