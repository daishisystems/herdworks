//
//  FarmDetailViewModel.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import SwiftUI
import FirebaseAuth
import Combine
import MapKit  // ✅ Changed from CoreLocation

@MainActor
final class FarmDetailViewModel: ObservableObject {
    // Required fields
    @Published var name: String = ""
    @Published var breed: SheepBreed = .dohneMerino
    @Published var ewesText: String = ""
    @Published var city: String = ""
    @Published var province: SouthAfricanProvince = .westernCape
    
    // Optional fields
    @Published var showOptionalFields = false
    @Published var companyName: String = ""
    @Published var sizeText: String = ""
    @Published var streetAddress: String = ""
    @Published var postalCode: String = ""
    @Published var productionSystem: ProductionSystem?
    @Published var preferredAgent: String = ""
    @Published var preferredAbattoir: String = ""
    @Published var preferredVeterinarian: String = ""
    @Published var coOp: String = ""
    
    // State
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let store: FarmStore
    private let userId: String
    private var existingFarm: Farm?
    
    var isEditing: Bool {
        existingFarm != nil
    }
    
    var navigationTitle: String {
        isEditing ? "Edit Farm" : "Add Farm"
    }
    
    init(store: FarmStore, userId: String, farm: Farm? = nil) {
        self.store = store
        self.userId = userId
        self.existingFarm = farm
        
        if let farm = farm {
            loadFarm(farm)
        }
    }
    
    private func loadFarm(_ farm: Farm) {
        name = farm.name
        breed = farm.breed
        ewesText = "\(farm.totalProductionEwes)"
        city = farm.city
        province = farm.province
        companyName = farm.companyName ?? ""
        sizeText = farm.sizeHectares.map { "\($0)" } ?? ""
        streetAddress = farm.streetAddress ?? ""
        postalCode = farm.postalCode ?? ""
        productionSystem = farm.productionSystem
        preferredAgent = farm.preferredAgent ?? ""
        preferredAbattoir = farm.preferredAbattoir ?? ""
        preferredVeterinarian = farm.preferredVeterinarian ?? ""
        coOp = farm.coOp ?? ""
        
        // Show optional fields if any are filled
        showOptionalFields = farm.companyName != nil ||
                            farm.sizeHectares != nil ||
                            farm.streetAddress != nil ||
                            farm.productionSystem != nil
    }
    
    var isValid: Bool {
        !name.isEmpty &&
        !city.isEmpty &&
        totalEwes != nil &&
        (totalEwes ?? 0) > 0
    }
    
    private var totalEwes: Int? {
        Int(ewesText.trimmingCharacters(in: .whitespaces))
    }
    
    private var farmSize: Double? {
        let trimmed = sizeText.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : Double(trimmed)
    }
    
    func saveFarm() async -> Bool {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return false
        }
        
        guard let ewes = totalEwes else {
            errorMessage = "Please enter a valid number of ewes"
            showError = true
            return false
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Geocode address if we have enough info
            let gpsLocation = await geocodeAddress()
            
            let farm: Farm
            if let existing = existingFarm {
                // Update existing
                farm = Farm(
                    id: existing.id,
                    userId: userId,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    breed: breed,
                    totalProductionEwes: ewes,
                    city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                    province: province,
                    companyName: companyName.isEmpty ? nil : companyName.trimmingCharacters(in: .whitespacesAndNewlines),
                    sizeHectares: farmSize,
                    streetAddress: streetAddress.isEmpty ? nil : streetAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                    postalCode: postalCode.isEmpty ? nil : postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
                    gpsLocation: gpsLocation,
                    productionSystem: productionSystem,
                    preferredAgent: preferredAgent.isEmpty ? nil : preferredAgent.trimmingCharacters(in: .whitespacesAndNewlines),
                    preferredAbattoir: preferredAbattoir.isEmpty ? nil : preferredAbattoir.trimmingCharacters(in: .whitespacesAndNewlines),
                    preferredVeterinarian: preferredVeterinarian.isEmpty ? nil : preferredVeterinarian.trimmingCharacters(in: .whitespacesAndNewlines),
                    coOp: coOp.isEmpty ? nil : coOp.trimmingCharacters(in: .whitespacesAndNewlines),
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
                try await store.update(farm)
            } else {
                // Create new
                farm = Farm(
                    userId: userId,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    breed: breed,
                    totalProductionEwes: ewes,
                    city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                    province: province,
                    companyName: companyName.isEmpty ? nil : companyName.trimmingCharacters(in: .whitespacesAndNewlines),
                    sizeHectares: farmSize,
                    streetAddress: streetAddress.isEmpty ? nil : streetAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                    postalCode: postalCode.isEmpty ? nil : postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
                    gpsLocation: gpsLocation,
                    productionSystem: productionSystem,
                    preferredAgent: preferredAgent.isEmpty ? nil : preferredAgent.trimmingCharacters(in: .whitespacesAndNewlines),
                    preferredAbattoir: preferredAbattoir.isEmpty ? nil : preferredAbattoir.trimmingCharacters(in: .whitespacesAndNewlines),
                    preferredVeterinarian: preferredVeterinarian.isEmpty ? nil : preferredVeterinarian.trimmingCharacters(in: .whitespacesAndNewlines),
                    coOp: coOp.isEmpty ? nil : coOp.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                try await store.create(farm)
            }
            
            return true
        } catch {
            errorMessage = "Failed to save farm: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
    
    // ✅ Updated: Modern MapKit geocoding
    private func geocodeAddress() async -> GPSCoordinate? {
        // Build address string
        var components: [String] = []
        
        if !streetAddress.isEmpty {
            components.append(streetAddress)
        }
        components.append(city)
        components.append(province.rawValue)
        if !postalCode.isEmpty {
            components.append(postalCode)
        }
        components.append("South Africa")
        
        let addressString = components.joined(separator: ", ")
        
        // Use modern MapKit geocoding
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = addressString
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -30.5595, longitude: 22.9375), // South Africa center
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            // ✅ location is not optional - just access it directly
            if let firstItem = response.mapItems.first {
                let location = firstItem.location
                return GPSCoordinate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        } catch {
            // Silently fail - GPS is optional
            print("Geocoding failed: \(error.localizedDescription)")
        }
        
        return nil
    }
}
