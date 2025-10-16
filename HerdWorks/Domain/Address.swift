//
//  Address.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/16.
//

import Foundation

/// Represents a physical address for users or farms
/// Designed to be Codable for Firestore integration
public struct Address: Codable, Equatable, Sendable {
    public let street: String
    public let city: String
    public let state: String
    public let zipCode: String
    public let country: String
    
    /// Creates a new Address with all required fields
    /// - Parameters:
    ///   - street: Street address including number and name
    ///   - city: City name
    ///   - state: State or province
    ///   - zipCode: Postal/ZIP code
    ///   - country: Country name
    public init(street: String, city: String, state: String, zipCode: String, country: String) {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
}
