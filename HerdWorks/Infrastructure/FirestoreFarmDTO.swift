//
//  FirestoreFarmDTO.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

// ✅ No @MainActor - DTOs should be Sendable and actor-agnostic
struct FirestoreFarmDTO: Codable, Equatable, Sendable {
    var id: String
    var userId: String
    var name: String
    var breed: String
    var totalProductionEwes: Int
    var city: String
    var province: String
    var companyName: String?
    var sizeHectares: Double?
    var streetAddress: String?
    var postalCode: String?
    var gpsLatitude: Double?
    var gpsLongitude: Double?
    var productionSystem: String?
    var preferredAgent: String?
    var preferredAbattoir: String?
    var preferredVeterinarian: String?
    var coOp: String?
    var createdAt: Date?
    var updatedAt: Date?
}

// ✅ Extension is not @MainActor
extension FirestoreFarmDTO {
    init(fromDomain farm: Farm) {
        self.id = farm.id
        self.userId = farm.userId
        self.name = farm.name
        self.breed = farm.breed.rawValue
        self.totalProductionEwes = farm.totalProductionEwes
        self.city = farm.city
        self.province = farm.province.rawValue
        self.companyName = farm.companyName
        self.sizeHectares = farm.sizeHectares
        self.streetAddress = farm.streetAddress
        self.postalCode = farm.postalCode
        self.gpsLatitude = farm.gpsLocation?.latitude
        self.gpsLongitude = farm.gpsLocation?.longitude
        self.productionSystem = farm.productionSystem?.rawValue
        self.preferredAgent = farm.preferredAgent
        self.preferredAbattoir = farm.preferredAbattoir
        self.preferredVeterinarian = farm.preferredVeterinarian
        self.coOp = farm.coOp
        self.createdAt = farm.createdAt
        self.updatedAt = farm.updatedAt
    }
}

// ✅ Mapper is not @MainActor
struct FarmMapper {
    static func toDomain(dto: FirestoreFarmDTO, lastKnown: Farm? = nil, fallbackNow: Date = Date()) -> Farm? {
        guard let breed = SheepBreed(rawValue: dto.breed),
              let province = SouthAfricanProvince(rawValue: dto.province) else {
            return nil
        }
        
        let created = dto.createdAt ?? lastKnown?.createdAt ?? fallbackNow
        let updatedCandidate = dto.updatedAt ?? lastKnown?.updatedAt ?? fallbackNow
        let updated = max(created, updatedCandidate)
        
        let gpsLocation: GPSCoordinate?
        if let lat = dto.gpsLatitude, let lon = dto.gpsLongitude {
            gpsLocation = GPSCoordinate(latitude: lat, longitude: lon)
        } else {
            gpsLocation = nil
        }
        
        let productionSystem = dto.productionSystem.flatMap { ProductionSystem(rawValue: $0) }
        
        return Farm(
            id: dto.id,
            userId: dto.userId,
            name: dto.name,
            breed: breed,
            totalProductionEwes: dto.totalProductionEwes,
            city: dto.city,
            province: province,
            companyName: dto.companyName,
            sizeHectares: dto.sizeHectares,
            streetAddress: dto.streetAddress,
            postalCode: dto.postalCode,
            gpsLocation: gpsLocation,
            productionSystem: productionSystem,
            preferredAgent: dto.preferredAgent,
            preferredAbattoir: dto.preferredAbattoir,
            preferredVeterinarian: dto.preferredVeterinarian,
            coOp: dto.coOp,
            createdAt: created,
            updatedAt: updated
        )
    }
}
