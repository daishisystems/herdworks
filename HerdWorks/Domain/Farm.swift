//
//  Farm.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

struct Farm: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let userId: String
    
    // Required fields
    var name: String
    var breed: SheepBreed
    var totalProductionEwes: Int
    var city: String
    var province: SouthAfricanProvince
    
    // Optional fields
    var companyName: String?
    var sizeHectares: Double?
    var streetAddress: String?
    var postalCode: String?
    var gpsLocation: GPSCoordinate?
    var productionSystem: ProductionSystem?
    var preferredAgent: PreferredAgent?
    var preferredAbattoir: String?
    var preferredVeterinarian: String?
    var coOp: CoOp?
    
    let createdAt: Date
    var updatedAt: Date
    
    /// Creates a new Farm with current timestamps
    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        breed: SheepBreed,
        totalProductionEwes: Int,
        city: String,
        province: SouthAfricanProvince,
        companyName: String? = nil,
        sizeHectares: Double? = nil,
        streetAddress: String? = nil,
        postalCode: String? = nil,
        gpsLocation: GPSCoordinate? = nil,
        productionSystem: ProductionSystem? = nil,
        preferredAgent: PreferredAgent? = nil,
        preferredAbattoir: String? = nil,
        preferredVeterinarian: String? = nil,
        coOp: CoOp? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.breed = breed
        self.totalProductionEwes = totalProductionEwes
        self.city = city
        self.province = province
        self.companyName = companyName
        self.sizeHectares = sizeHectares
        self.streetAddress = streetAddress
        self.postalCode = postalCode
        self.gpsLocation = gpsLocation
        self.productionSystem = productionSystem
        self.preferredAgent = preferredAgent
        self.preferredAbattoir = preferredAbattoir
        self.preferredVeterinarian = preferredVeterinarian
        self.coOp = coOp
        
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
    
    /// Internal initializer for decoding and updates
    internal init(
        id: String,
        userId: String,
        name: String,
        breed: SheepBreed,
        totalProductionEwes: Int,
        city: String,
        province: SouthAfricanProvince,
        companyName: String?,
        sizeHectares: Double?,
        streetAddress: String?,
        postalCode: String?,
        gpsLocation: GPSCoordinate?,
        productionSystem: ProductionSystem?,
        preferredAgent: PreferredAgent?,
        preferredAbattoir: String?,
        preferredVeterinarian: String?,
        coOp: CoOp?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.breed = breed
        self.totalProductionEwes = totalProductionEwes
        self.city = city
        self.province = province
        self.companyName = companyName
        self.sizeHectares = sizeHectares
        self.streetAddress = streetAddress
        self.postalCode = postalCode
        self.gpsLocation = gpsLocation
        self.productionSystem = productionSystem
        self.preferredAgent = preferredAgent
        self.preferredAbattoir = preferredAbattoir
        self.preferredVeterinarian = preferredVeterinarian
        self.coOp = coOp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Validation: Check if required fields are valid
    var isValid: Bool {
        !name.isEmpty &&
        totalProductionEwes > 0 &&
        !city.isEmpty
    }
}
