//
//  GPSCoordinate.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

struct GPSCoordinate: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    
    var isValid: Bool {
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    }
}
