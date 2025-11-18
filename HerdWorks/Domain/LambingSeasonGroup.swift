//
//  LambingSeasonGroup.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/22.
//

import Foundation

struct LambingSeasonGroup: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let userId: String
    let farmId: String
    var code: String
    var name: String
    var matingStart: Date
    var matingEnd: Date
    var lambingStart: Date
    var lambingEnd: Date
    var isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Number of days in the mating period
    var matingDurationDays: Int {
        Calendar.current.dateComponents([.day], from: matingStart, to: matingEnd).day ?? 0
    }
    
    /// Number of days in the lambing period
    var lambingDurationDays: Int {
        Calendar.current.dateComponents([.day], from: lambingStart, to: lambingEnd).day ?? 0
    }
    
    /// Number of days between mating start and lambing start (gestation period)
    var gestationDays: Int {
        Calendar.current.dateComponents([.day], from: matingStart, to: lambingStart).day ?? 0
    }
    
    /// Warns if gestation period is outside normal sheep range (140-160 days)
    var gestationWarning: String? {
        let days = gestationDays
        if days < 140 {
            return "Gestation period is shorter than typical (140-160 days)"
        } else if days > 160 {
            return "Gestation period is longer than typical (140-160 days)"
        }
        return nil
    }
    
    /// Display name combining code and name if both exist
    var displayName: String {
        if code.isEmpty {
            return name
        } else if name.isEmpty {
            return code
        } else {
            return "\(code) - \(name)"
        }
    }
    
    // MARK: - Initializers
    
    /// Create new lambing season group
    init(
        userId: String,
        farmId: String,
        code: String,
        name: String,
        matingStart: Date,
        matingEnd: Date,
        lambingStart: Date,
        lambingEnd: Date,
        isActive: Bool = true
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.farmId = farmId
        self.code = code
        self.name = name
        self.matingStart = matingStart
        self.matingEnd = matingEnd
        self.lambingStart = lambingStart
        self.lambingEnd = lambingEnd
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Full initializer (for updates/Firestore)
    init(
        id: String,
        userId: String,
        farmId: String,
        code: String,
        name: String,
        matingStart: Date,
        matingEnd: Date,
        lambingStart: Date,
        lambingEnd: Date,
        isActive: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.farmId = farmId
        self.code = code
        self.name = name
        self.matingStart = matingStart
        self.matingEnd = matingEnd
        self.lambingStart = lambingStart
        self.lambingEnd = lambingEnd
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Validation
    
    /// Returns validation errors, if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Code is required")
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name is required")
        }
        
        if matingEnd <= matingStart {
            errors.append("Mating end date must be after mating start date")
        }
        
        if lambingStart <= matingEnd {
            errors.append("Lambing start date must be after mating end date")
        }
        
        if lambingEnd <= lambingStart {
            errors.append("Lambing end date must be after lambing start date")
        }
        
        return errors
    }
    
    var isValid: Bool {
        validationErrors.isEmpty
    }
}

// MARK: - Firestore Coding Keys
extension LambingSeasonGroup {
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case farmId
        case code
        case name
        case matingStart
        case matingEnd
        case lambingStart
        case lambingEnd
        case isActive
        case createdAt
        case updatedAt
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension LambingSeasonGroup {
    static var preview: LambingSeasonGroup {
        LambingSeasonGroup(
            userId: "preview-user",
            farmId: "preview-farm",
            code: "B22",
            name: "LB 22",
            matingStart: Date(timeIntervalSince1970: 1641024000), // Jan 1, 2022
            matingEnd: Date(timeIntervalSince1970: 1643702400),   // Feb 1, 2022
            lambingStart: Date(timeIntervalSince1970: 1653696000), // May 27, 2022
            lambingEnd: Date(timeIntervalSince1970: 1657065600),   // July 5, 2022
            isActive: true
        )
    }
    
    static var previews: [LambingSeasonGroup] {
        [
            LambingSeasonGroup(
                userId: "preview-user",
                farmId: "preview-farm",
                code: "B22",
                name: "LB 22",
                matingStart: Date(timeIntervalSince1970: 1641024000),
                matingEnd: Date(timeIntervalSince1970: 1643702400),
                lambingStart: Date(timeIntervalSince1970: 1653696000),
                lambingEnd: Date(timeIntervalSince1970: 1657065600),
                isActive: true
            ),
            LambingSeasonGroup(
                userId: "preview-user",
                farmId: "preview-farm",
                code: "LB21",
                name: "LB 21",
                matingStart: Date(timeIntervalSince1970: 1640937600),
                matingEnd: Date(timeIntervalSince1970: 1643616000),
                lambingStart: Date(timeIntervalSince1970: 1653609600),
                lambingEnd: Date(timeIntervalSince1970: 1657152000),
                isActive: true
            ),
            LambingSeasonGroup(
                userId: "preview-user",
                farmId: "preview-farm",
                code: "2019-01",
                name: "2019-01",
                matingStart: Date(timeIntervalSince1970: 1641196800),
                matingEnd: Date(timeIntervalSince1970: 1643875200),
                lambingStart: Date(timeIntervalSince1970: 1653782400),
                lambingEnd: Date(timeIntervalSince1970: 1657324800),
                isActive: false
            )
        ]
    }
}
#endif
