//
//  PreferredAgent.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/21.
//


enum PreferredAgent: String, Codable, CaseIterable, Identifiable {
    case bkb = "BKB"
    case cmw = "CMW"
    case ovk = "OVK"
    case vleisSentraal = "Vleis Sentraal"
    case `private` = "Private"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}
