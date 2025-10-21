//
//  CoOp.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/21.
//


enum CoOp: String, Codable, CaseIterable, Identifiable {
    case ssk = "SSK"
    case overbergAgri = "Overberg Agri"
    case kaapAgri = "Kaap Agri"
    case gwk = "GWK"
    case bkb = "BKB"
    case other = "Other"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}
