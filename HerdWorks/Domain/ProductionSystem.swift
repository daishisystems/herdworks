//
//  ProductionSystem.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

enum ProductionSystem: String, Codable, CaseIterable, Sendable {
    case livestock30Crops70 = "30% Livestock 70% Crops"
    case livestock50Crops50 = "50% Livestock 50% Crops"
    case livestock70Crops30 = "70% Livestock 30% Crops"
    case livestock100 = "100% Livestock"
    case crops100 = "100% Crops"
    
    var displayName: String { rawValue }
}
