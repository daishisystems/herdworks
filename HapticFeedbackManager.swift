//
//  HapticFeedbackManager.swift
//  HerdWorks
//
//  Created by Code Review on 2025/11/24.
//  Purpose: Centralized haptic feedback management following HIG guidelines
//

import UIKit
import SwiftUI

/// Manages haptic feedback throughout the app following Apple HIG guidelines
/// Usage: HapticFeedbackManager.shared.success()
@MainActor
final class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private init() {}
    
    // MARK: - Notification Feedback
    
    /// Indicates a task has completed successfully
    /// Use: After saving data, completing forms, successful login
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Indicates a task has failed or an error occurred
    /// Use: Failed validation, network errors, authentication failures
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Indicates a warning or important information
    /// Use: Validation warnings, data conflicts, important alerts
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // MARK: - Impact Feedback
    
    /// Light impact feedback
    /// Use: Small button taps, toggles, checkboxes
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact feedback
    /// Use: Standard button taps, selections, navigation
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact feedback
    /// Use: Destructive actions, important confirmations
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Rigid impact feedback (iOS 13+)
    /// Use: Precise interactions, stepper controls
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// Soft impact feedback (iOS 13+)
    /// Use: Subtle interactions, gentle feedback
    func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed feedback
    /// Use: Scrolling through pickers, segment controls, sliders at detents
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Prepared Generators (for better performance)
    
    /// Prepares a notification generator for imminent use
    /// Call this before showing alerts or completing tasks for better timing
    func prepareNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
    }
    
    /// Prepares an impact generator for imminent use
    /// Call this before user interactions that will trigger feedback
    func prepareImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Adds haptic feedback on button tap
    /// - Parameter style: The haptic style to use (default: .medium)
    /// - Returns: Modified view with haptic feedback
    func hapticFeedback(_ style: HapticStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                switch style {
                case .light:
                    HapticFeedbackManager.shared.light()
                case .medium:
                    HapticFeedbackManager.shared.medium()
                case .heavy:
                    HapticFeedbackManager.shared.heavy()
                case .soft:
                    HapticFeedbackManager.shared.soft()
                case .rigid:
                    HapticFeedbackManager.shared.rigid()
                case .success:
                    HapticFeedbackManager.shared.success()
                case .warning:
                    HapticFeedbackManager.shared.warning()
                case .error:
                    HapticFeedbackManager.shared.error()
                case .selection:
                    HapticFeedbackManager.shared.selection()
                }
            }
        )
    }
}

enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case success
    case warning
    case error
    case selection
}
