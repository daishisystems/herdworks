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
    
    var displayName: String {
        switch LanguageManager.shared.currentLanguage {
        case .afrikaans:
            switch self {
            case .westernCape: return "Wes-Kaap"
            case .easternCape: return "Oos-Kaap"
            case .northernCape: return "Noord-Kaap"
            case .freeState: return "Vrystaat"
            case .kwazuluNatal: return "KwaZulu-Natal"
            case .gauteng: return "Gauteng"
            case .limpopo: return "Limpopo"
            case .mpumalanga: return "Mpumalanga"
            case .northWest: return "Noordwes"
            }
        case .english:
            return rawValue
        }
    }
}
