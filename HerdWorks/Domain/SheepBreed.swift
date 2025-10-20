//
//  SheepBreed.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/20.
//

import Foundation

enum SheepBreed: String, Codable, CaseIterable, Sendable {
    // Wool Breeds
    case dohneMerino = "Dohne Merino"
    case merino = "Merino"
    case saStrongwool = "SA Strongwool"
    
    // Mutton Breeds
    case dorper = "Dorper"
    case whiteDorper = "White Dorper"
    case dormer = "Dormer"
    case meatmaster = "Meatmaster"
    case vanRooy = "Van Rooy"
    case damara = "Damara"
    
    // Dual Purpose
    case dohne = "Dohne"
    case southAfricanMerino = "South African Merino"
    
    // Other
    case other = "Other"
    
    var displayName: String { rawValue }
}
