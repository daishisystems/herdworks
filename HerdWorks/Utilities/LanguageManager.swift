//
//  LanguageManager.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/21.
//

import SwiftUI
import Combine

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            // Invalidate cached bundle when language changes
            cachedBundle = nil
        }
    }
    
    private var cachedBundle: Bundle?
    
    enum Language: String, CaseIterable, Identifiable {
        case afrikaans = "af"
        case english = "en"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .afrikaans: return "Afrikaans"
            case .english: return "English"
            }
        }
        
        var flag: String {
            switch self {
            case .afrikaans: return "🇿🇦"
            case .english: return "🇬🇧"
            }
        }
    }
    
    private init() {
        // Default to Afrikaans, or load saved preference
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? Language.afrikaans.rawValue
        self.currentLanguage = Language(rawValue: savedLanguage) ?? .afrikaans
        
        print("🌍 LanguageManager initialized with language: \(currentLanguage.rawValue)")
    }
    
    func localized(_ key: String) -> String {
        // Get or create the language bundle
        if cachedBundle == nil {
            if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj") {
                cachedBundle = Bundle(path: path)
                print("✅ Loaded language bundle for: \(currentLanguage.rawValue)")
            } else {
                print("⚠️ Could not find bundle for language: \(currentLanguage.rawValue)")
            }
        }
        
        // Try to get localized string from the language bundle
        if let bundle = cachedBundle {
            let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
            
            // If we got the key back (no translation found), log it
            if localizedString == key {
                print("⚠️ No translation found for key: \(key)")
                return key
            }
            
            return localizedString
        }
        
        // Fallback to system localization
        print("⚠️ Using fallback localization for key: \(key)")
        return NSLocalizedString(key, comment: "")
    }
}

// Helper for SwiftUI Text views
extension String {
    func localized() -> String {
        LanguageManager.shared.localized(self)
    }
}
