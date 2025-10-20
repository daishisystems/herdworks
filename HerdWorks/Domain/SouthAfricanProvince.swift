//
//  SouthAfricanProvince.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

enum SouthAfricanProvince: String, Codable, CaseIterable, Sendable {
    case westernCape = "Western Cape"
    case easternCape = "Eastern Cape"
    case northernCape = "Northern Cape"
    case freeState = "Free State"
    case kwazuluNatal = "KwaZulu-Natal"
    case gauteng = "Gauteng"
    case limpopo = "Limpopo"
    case mpumalanga = "Mpumalanga"
    case northWest = "North West"
    
    var displayName: String { rawValue }
}
