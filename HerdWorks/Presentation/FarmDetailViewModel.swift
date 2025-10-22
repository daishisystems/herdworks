//
//  FarmDetailViewModel.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import SwiftUI
import FirebaseAuth
import Combine  // ✅ ADD THIS LINE

@MainActor
final class FarmDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var breed: SheepBreed = .dohneMerino
    // ... rest of the file stays the same
    @Published var ewesText: String = ""
    @Published var city: String = ""
    @Published var province: SouthAfricanProvince = .westernCape
    
    // Optional fields
    @Published var companyName: String = ""
    @Published var sizeText: String = ""
    @Published var streetAddress: String = ""
    @Published var postalCode: String = ""
    @Published var productionSystem: ProductionSystem?
    @Published var preferredAgent: PreferredAgent?
    @Published var preferredAbattoir: String = ""
    @Published var preferredVeterinarian: String = ""
    @Published var coOp: CoOp?
    
    // Manual GPS fields
    @Published var useManualGPS: Bool = false
    @Published var manualLatitude: String = ""
    @Published var manualLongitude: String = ""
    
    // UI State
    @Published var isSaving: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showOptionalFields: Bool = false
    
    // MARK: - Private Properties
    private let store: FarmStore
    private let userId: String
    private let existingFarm: Farm?
    
    // MARK: - Computed Properties
    var isValid: Bool {
        !name.isEmpty &&
        !city.isEmpty &&
        totalEwes != nil &&
        (totalEwes ?? 0) > 0
    }
    
    var navigationTitle: String {
        existingFarm == nil ? "farm.add_farm".localized() : "farm.edit_farm".localized()
    }
    
    var totalEwes: Int? {
        Int(ewesText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    var farmSize: Double? {
        guard !sizeText.isEmpty else { return nil }
        return Double(sizeText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    // MARK: - Initialization
    init(store: FarmStore, userId: String, farm: Farm? = nil) {
        self.store = store
        self.userId = userId
        self.existingFarm = farm
        
        print("🔵 [VIEWMODEL] FarmDetailViewModel initialized")
        print("🔵 [VIEWMODEL] User ID: \(userId)")
        print("🔵 [VIEWMODEL] Auth user: \(Auth.auth().currentUser?.uid ?? "none")")
        print("🔵 [VIEWMODEL] Is editing: \(farm != nil)")
        
        if let farm = farm {
            loadFarm(farm)
        }
    }
    
    // MARK: - Private Methods
    private func loadFarm(_ farm: Farm) {
        print("🔵 [VIEWMODEL] Loading existing farm: \(farm.name)")
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
        preferredAgent = farm.preferredAgent
        preferredAbattoir = farm.preferredAbattoir ?? ""
        preferredVeterinarian = farm.preferredVeterinarian ?? ""
        coOp = farm.coOp
        
        // Load GPS coordinates if available
        if let gps = farm.gpsLocation {
            manualLatitude = "\(gps.latitude)"
            manualLongitude = "\(gps.longitude)"
            useManualGPS = true
        }
        
        // Show optional fields if any are filled
        showOptionalFields = farm.companyName != nil ||
                            farm.sizeHectares != nil ||
                            farm.streetAddress != nil ||
                            farm.productionSystem != nil
    }
    
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
        print("🔵 [GEOCODE] Address string: \(addressString)")
        
        // Use Nominatim (OpenStreetMap) API
        let encodedAddress = addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://nominatim.openstreetmap.org/search?q=\(encodedAddress)&format=json&limit=1&countrycodes=za"
        
        guard let url = URL(string: urlString) else {
            print("⚠️ [GEOCODE] Invalid URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("HerdWorks/1.0 (Sheep Farm Management App)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            struct NominatimResponse: Codable {
                let lat: String
                let lon: String
                let display_name: String?
            }
            
            let results = try JSONDecoder().decode([NominatimResponse].self, from: data)
            
            if let first = results.first,
               let lat = Double(first.lat),
               let lon = Double(first.lon) {
                print("✅ [GEOCODE] Success: \(lat), \(lon)")
                if let displayName = first.display_name {
                    print("✅ [GEOCODE] Found location: \(displayName)")
                }
                return GPSCoordinate(latitude: lat, longitude: lon)
            } else {
                print("⚠️ [GEOCODE] No results found")
            }
        } catch {
            print("⚠️ [GEOCODE] Failed: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Public Methods
    func saveFarm() async -> Bool {
        print("🔵 [VIEWMODEL] saveFarm() called")
        print("🔵 [VIEWMODEL] Name: \(name)")
        print("🔵 [VIEWMODEL] Breed: \(breed.rawValue)")
        print("🔵 [VIEWMODEL] Ewes text: \(ewesText)")
        print("🔵 [VIEWMODEL] City: \(city)")
        print("🔵 [VIEWMODEL] Province: \(province.rawValue)")
        
        guard isValid else {
            print("⚠️ [VIEWMODEL] Validation failed")
            errorMessage = "error.fill_required_fields".localized()
            showError = true
            return false
        }
        
        guard let ewes = totalEwes else {
            print("⚠️ [VIEWMODEL] Invalid ewes number")
            errorMessage = "error.invalid_ewes_number".localized()
            showError = true
            return false
        }
        
        print("✅ [VIEWMODEL] Validation passed, ewes: \(ewes)")
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Determine GPS location
            let gpsLocation: GPSCoordinate?
            
            if useManualGPS,
               let lat = Double(manualLatitude.trimmingCharacters(in: .whitespacesAndNewlines)),
               let lon = Double(manualLongitude.trimmingCharacters(in: .whitespacesAndNewlines)) {
                // Use manual coordinates
                print("🔵 [VIEWMODEL] Using manual GPS coordinates")
                gpsLocation = GPSCoordinate(latitude: lat, longitude: lon)
            } else {
                // Auto-geocode from address
                print("🔵 [VIEWMODEL] Starting geocoding...")
                gpsLocation = await geocodeAddress()
                if let gps = gpsLocation {
                    print("✅ [VIEWMODEL] Geocoded: \(gps.latitude), \(gps.longitude)")
                } else {
                    print("⚠️ [VIEWMODEL] Geocoding returned nil")
                }
            }
            
            let farm: Farm
            if let existing = existingFarm {
                print("🔵 [VIEWMODEL] Updating existing farm")
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
                    preferredAgent: preferredAgent,
                    preferredAbattoir: preferredAbattoir.isEmpty ? nil : preferredAbattoir.trimmingCharacters(in: .whitespacesAndNewlines),
                    preferredVeterinarian: preferredVeterinarian.isEmpty ? nil : preferredVeterinarian.trimmingCharacters(in: .whitespacesAndNewlines),
                    coOp: coOp,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
                print("🔵 [VIEWMODEL] Calling store.update()")
                try await store.update(farm)
                print("✅ [VIEWMODEL] store.update() completed")
            } else {
                print("🔵 [VIEWMODEL] Creating new farm")
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
                    preferredAgent: preferredAgent,
                    preferredAbattoir: preferredAbattoir.isEmpty ? nil : preferredAbattoir.trimmingCharacters(in: .whitespacesAndNewlines),
                    preferredVeterinarian: preferredVeterinarian.isEmpty ? nil : preferredVeterinarian.trimmingCharacters(in: .whitespacesAndNewlines),
                    coOp: coOp
                )
                print("🔵 [VIEWMODEL] Farm object created with ID: \(farm.id)")
                print("🔵 [VIEWMODEL] Calling store.create()")
                try await store.create(farm)
                print("✅ [VIEWMODEL] store.create() completed successfully")
            }
            
            print("✅ [VIEWMODEL] Save completed, returning true")
            return true
        } catch {
            print("❌ [VIEWMODEL] Save failed with error")
            print("❌ [VIEWMODEL] Error: \(error)")
            print("❌ [VIEWMODEL] Error type: \(type(of: error))")
            print("❌ [VIEWMODEL] Error description: \(error.localizedDescription)")
            errorMessage = String(format: "error.failed_to_save".localized(), error.localizedDescription)
            showError = true
            return false
        }
    }
}
