//
//  HerdWorksTests.swift
//  HerdWorksTests
//
//  Created by Paul Mooney on 2025/10/10.
//

import Testing
import Foundation  // Added for JSONEncoder/JSONDecoder
@testable import HerdWorks

struct HerdWorksTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - Address Model Tests

@Suite("Address Model Tests")
struct AddressTests {
    
    @Test("Address should be created with all required fields")
    @MainActor func createAddressWithAllFields() {
        // Arrange & Act
        let address = Address(
            street: "123 Farm Road",
            city: "Farmville", 
            state: "TX",
            zipCode: "75001",
            country: "USA"
        )
        
        // Assert
        #expect(address.street == "123 Farm Road")
        #expect(address.city == "Farmville")
        #expect(address.state == "TX")
        #expect(address.zipCode == "75001")
        #expect(address.country == "USA")
    }
    
    @Test("Address should conform to Codable for Firestore integration")
    @MainActor func addressShouldBeEncodableAndDecodable() async throws {
        // Arrange
        let originalAddress = Address(
            street: "456 Ranch Lane",
            city: "Livestock City",
            state: "OK", 
            zipCode: "73001",
            country: "USA"
        )
        
        // Act - Encode to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalAddress)
        
        // Act - Decode from JSON
        let decoder = JSONDecoder()
        let decodedAddress = try decoder.decode(Address.self, from: data)
        
        // Assert all fields are preserved
        #expect(decodedAddress.street == originalAddress.street)
        #expect(decodedAddress.city == originalAddress.city)
        #expect(decodedAddress.state == originalAddress.state)
        #expect(decodedAddress.zipCode == originalAddress.zipCode)
        #expect(decodedAddress.country == originalAddress.country)
    }
    
    @Test("Address should handle empty strings gracefully")
    @MainActor func addressShouldAcceptEmptyStrings() {
        // Arrange & Act - This tests that we can create addresses with empty fields
        // (validation will be handled at a higher level)
        let address = Address(
            street: "",
            city: "",
            state: "",
            zipCode: "",
            country: ""
        )
        
        // Assert
        #expect(address.street.isEmpty)
        #expect(address.city.isEmpty)
        #expect(address.state.isEmpty)
        #expect(address.zipCode.isEmpty)
        #expect(address.country.isEmpty)
    }
    
    @Test("Address should support typical US farm addresses")
    @MainActor func addressShouldSupportFarmAddresses() {
        // Arrange & Act - Test with realistic farm address data
        let farmAddress = Address(
            street: "15847 County Road 245",
            city: "Muleshoe",
            state: "Texas",
            zipCode: "79347",
            country: "United States"
        )
        
        // Assert
        #expect(farmAddress.street == "15847 County Road 245")
        #expect(farmAddress.city == "Muleshoe")
        #expect(farmAddress.state == "Texas")
        #expect(farmAddress.zipCode == "79347")
        #expect(farmAddress.country == "United States")
    }
}

// MARK: - UserProfile Model Tests

@Suite("UserProfile Model Tests")
struct UserProfileTests {
    
    @Test("UserProfile should be created with all required fields")
    @MainActor func createUserProfileWithAllFields() {
        // Arrange
        let address = Address(
            street: "123 Farm Road",
            city: "Farmville",
            state: "TX", 
            zipCode: "75001",
            country: "USA"
        )
        
        // Act
        let profile = UserProfile(
            userId: "user123",
            firstName: "John",
            lastName: "Farmer",
            email: "john@example.com",
            phoneNumber: "555-0123",
            personalAddress: address
        )
        
        // Assert
        #expect(profile.userId == "user123")
        #expect(profile.firstName == "John")
        #expect(profile.lastName == "Farmer") 
        #expect(profile.email == "john@example.com")
        #expect(profile.phoneNumber == "555-0123")
        #expect(profile.personalAddress.street == "123 Farm Road")
    }
    
    @Test("UserProfile should conform to Codable for Firestore integration")
    @MainActor func userProfileShouldBeEncodableAndDecodable() async throws {
        // Arrange
        let address = Address(
            street: "456 Ranch Lane",
            city: "Livestock City",
            state: "OK",
            zipCode: "73001", 
            country: "USA"
        )
        
        let originalProfile = UserProfile(
            userId: "user456",
            firstName: "Jane",
            lastName: "Rancher",
            email: "jane@ranch.com",
            phoneNumber: "555-0456",
            personalAddress: address
        )
        
        // Act - Encode to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalProfile)
        
        // Act - Decode from JSON
        let decoder = JSONDecoder()
        let decodedProfile = try decoder.decode(UserProfile.self, from: data)
        
        // Assert all fields are preserved including nested Address
        #expect(decodedProfile.userId == originalProfile.userId)
        #expect(decodedProfile.firstName == originalProfile.firstName)
        #expect(decodedProfile.lastName == originalProfile.lastName)
        #expect(decodedProfile.email == originalProfile.email)
        #expect(decodedProfile.phoneNumber == originalProfile.phoneNumber)
        #expect(decodedProfile.personalAddress.street == originalProfile.personalAddress.street)
        #expect(decodedProfile.personalAddress.city == originalProfile.personalAddress.city)
    }
    
    @Test("UserProfile should calculate completion status correctly")
    @MainActor func userProfileShouldCalculateCompletionStatus() {
        // Test Case 1: Complete profile
        let completeAddress = Address(
            street: "123 Complete St",
            city: "Complete City",
            state: "TX",
            zipCode: "12345",
            country: "USA"
        )
        
        let completeProfile = UserProfile(
            userId: "complete123",
            firstName: "Complete",
            lastName: "User",
            email: "complete@test.com", 
            phoneNumber: "555-0001",
            personalAddress: completeAddress
        )
        
        #expect(completeProfile.isProfileComplete == true)
        
        // Test Case 2: Incomplete profile - empty first name
        let incompleteProfile = UserProfile(
            userId: "incomplete123",
            firstName: "", // Empty first name
            lastName: "User",
            email: "incomplete@test.com",
            phoneNumber: "555-0002", 
            personalAddress: completeAddress
        )
        
        #expect(incompleteProfile.isProfileComplete == false)
    }
    
    @Test("UserProfile should handle empty address fields in completion check")
    @MainActor func userProfileShouldHandleIncompleteAddress() {
        // Arrange - Address with empty required fields
        let incompleteAddress = Address(
            street: "", // Empty street
            city: "Some City",
            state: "",  // Empty state
            zipCode: "12345",
            country: "USA"
        )
        
        let profileWithIncompleteAddress = UserProfile(
            userId: "user789",
            firstName: "Test",
            lastName: "User", 
            email: "test@example.com",
            phoneNumber: "555-0789",
            personalAddress: incompleteAddress
        )
        
        // Act & Assert - Profile should be incomplete due to address
        #expect(profileWithIncompleteAddress.isProfileComplete == false)
    }
    
    @Test("UserProfile should detect incomplete profiles for each empty field")
    @MainActor func userProfileShouldDetectAllIncompleteFields() {
        let completeAddress = Address(
            street: "123 Complete St",
            city: "Complete City",
            state: "TX",
            zipCode: "12345",
            country: "USA"
        )
        
        // Test empty lastName
        let emptyLastName = UserProfile(
            userId: "test1", firstName: "John", lastName: "", 
            email: "john@test.com", phoneNumber: "555-0001", 
            personalAddress: completeAddress
        )
        #expect(emptyLastName.isProfileComplete == false)
        
        // Test empty email
        let emptyEmail = UserProfile(
            userId: "test2", firstName: "John", lastName: "Doe", 
            email: "", phoneNumber: "555-0002", 
            personalAddress: completeAddress
        )
        #expect(emptyEmail.isProfileComplete == false)
        
        // Test empty phone
        let emptyPhone = UserProfile(
            userId: "test3", firstName: "John", lastName: "Doe", 
            email: "john@test.com", phoneNumber: "", 
            personalAddress: completeAddress
        )
        #expect(emptyPhone.isProfileComplete == false)
        
        // Test each address field individually
        let emptyCity = Address(street: "123 St", city: "", state: "TX", zipCode: "12345", country: "USA")
        let emptyCityProfile = UserProfile(
            userId: "test4", firstName: "John", lastName: "Doe", 
            email: "john@test.com", phoneNumber: "555-0004", 
            personalAddress: emptyCity
        )
        #expect(emptyCityProfile.isProfileComplete == false)
        
        let emptyZipCode = Address(street: "123 St", city: "City", state: "TX", zipCode: "", country: "USA")
        let emptyZipProfile = UserProfile(
            userId: "test5", firstName: "John", lastName: "Doe", 
            email: "john@test.com", phoneNumber: "555-0005", 
            personalAddress: emptyZipCode
        )
        #expect(emptyZipProfile.isProfileComplete == false)
        
        let emptyCountry = Address(street: "123 St", city: "City", state: "TX", zipCode: "12345", country: "")
        let emptyCountryProfile = UserProfile(
            userId: "test6", firstName: "John", lastName: "Doe", 
            email: "john@test.com", phoneNumber: "555-0006", 
            personalAddress: emptyCountry
        )
        #expect(emptyCountryProfile.isProfileComplete == false)
    }
    
    @Test("UserProfile should include timestamps for audit trail")  
    @MainActor func userProfileShouldIncludeTimestamps() {
        // Arrange
        let address = Address(
            street: "123 Time St",
            city: "Time City",
            state: "TX",
            zipCode: "12345",
            country: "USA"
        )
        
        let beforeCreation = Date()
        
        // Act
        let profile = UserProfile(
            userId: "time123",
            firstName: "Time",
            lastName: "User",
            email: "time@test.com",
            phoneNumber: "555-TIME",
            personalAddress: address
        )
        
        let afterCreation = Date()
        
        // Assert - Timestamps should be set and reasonable
        #expect(profile.createdAt >= beforeCreation)
        #expect(profile.createdAt <= afterCreation)
        #expect(profile.updatedAt >= beforeCreation)  
        #expect(profile.updatedAt <= afterCreation)
        #expect(profile.createdAt == profile.updatedAt) // Should be same on creation
    }
    
    @Test("UserProfile should support updating with new timestamp")
    @MainActor func userProfileShouldSupportUpdating() async throws {
        // Arrange
        let address = Address(
            street: "123 Update St",
            city: "Update City", 
            state: "TX",
            zipCode: "12345",
            country: "USA"
        )
        
        var profile = UserProfile(
            userId: "update123",
            firstName: "Original",
            lastName: "User",
            email: "original@test.com",
            phoneNumber: "555-0001",
            personalAddress: address
        )
        
        let originalUpdatedAt = profile.updatedAt
        
        // Act - Simulate a small delay then update
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms delay
        
        profile = profile.updatedProfile(
            firstName: "Updated",
            lastName: "NewUser", 
            email: "updated@test.com",
            phoneNumber: "555-0002",
            personalAddress: address
        )
        
        // Assert
        #expect(profile.firstName == "Updated")
        #expect(profile.lastName == "NewUser")
        #expect(profile.email == "updated@test.com") 
        #expect(profile.phoneNumber == "555-0002")
        #expect(profile.updatedAt > originalUpdatedAt) // Should be newer
    }
    
    @Test("UserProfile should preserve original createdAt when using updatedProfile")
    @MainActor func userProfileShouldPreserveCreatedAt() async throws {
        // Arrange
        let address = Address(
            street: "123 Original St",
            city: "Original City",
            state: "TX",
            zipCode: "12345",
            country: "USA"
        )
        
        let original = UserProfile(
            userId: "preserve123",
            firstName: "Original",
            lastName: "User",
            email: "original@test.com",
            phoneNumber: "555-0001",
            personalAddress: address
        )
        
        let originalCreatedAt = original.createdAt
        let originalUpdatedAt = original.updatedAt
        
        // Act - Add a small delay to ensure timestamp difference, then update
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms delay
        
        let updated = original.updatedProfile(
            firstName: "Updated",
            lastName: "User",
            email: "updated@test.com",
            phoneNumber: "555-0002",
            personalAddress: address
        )
        
        // Assert - CreatedAt should remain the same, updatedAt should be newer
        #expect(updated.createdAt == originalCreatedAt)
        #expect(updated.updatedAt > originalUpdatedAt)
        #expect(updated.userId == original.userId) // userId should be preserved
    }
}
