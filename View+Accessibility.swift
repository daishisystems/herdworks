//
//  View+Accessibility.swift
//  HerdWorks
//
//  Created by Code Review on 2025/11/24.
//  Purpose: SwiftUI extensions for HIG-compliant accessibility
//

import SwiftUI

extension View {
    /// Ensures the view meets minimum touch target size (44x44pt) per Apple HIG
    /// - Parameter minSize: Minimum size (default: 44pt as per HIG)
    /// - Returns: View with guaranteed minimum tap target
    func minimumTapTarget(minSize: CGFloat = 44) -> some View {
        self.frame(minWidth: minSize, minHeight: minSize)
    }
    
    /// Adds a transparent tap area expansion without changing visual appearance
    /// Useful for small icons or text that need larger tap targets
    /// - Parameter padding: Amount to expand tap area (default: 8pt on all sides)
    /// - Returns: View with expanded tap area
    func expandTapArea(by padding: CGFloat = 8) -> some View {
        self.padding(padding)
            .contentShape(Rectangle())
    }
    
    /// Adds proper accessibility traits and labels for buttons
    /// - Parameters:
    ///   - label: Accessibility label
    ///   - hint: Accessibility hint (optional)
    ///   - traits: Additional traits (default: .isButton)
    /// - Returns: View with accessibility metadata
    func accessibleButton(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = .isButton
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Makes text conform to Dynamic Type while setting reasonable bounds
    /// - Parameters:
    ///   - minScale: Minimum scale factor (default: 0.8)
    ///   - maxScale: Maximum scale factor (default: 1.5)
    /// - Returns: View with bounded Dynamic Type scaling
    func boundedDynamicType(minScale: CGFloat = 0.8, maxScale: CGFloat = 1.5) -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .minimumScaleFactor(minScale)
    }
}

// MARK: - Empty State View Helper

extension View {
    /// Wraps content in a standard empty state container
    /// - Parameters:
    ///   - icon: SF Symbol name
    ///   - title: Main title
    ///   - subtitle: Descriptive subtitle
    ///   - action: Optional action button
    /// - Returns: Standardized empty state view
    func emptyState(
        icon: String,
        title: String,
        subtitle: String,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) -> some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .imageScale(.large)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading State Helper

extension View {
    /// Adds a standard loading overlay
    /// - Parameters:
    ///   - isLoading: Binding to loading state
    ///   - message: Optional loading message
    /// - Returns: View with loading overlay
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        if let message = message {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 20)
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Card Style Helper

extension View {
    /// Applies standard card styling consistent with iOS design
    /// - Parameters:
    ///   - padding: Internal padding (default: 16)
    ///   - cornerRadius: Corner radius (default: 12)
    /// - Returns: View styled as a card
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
