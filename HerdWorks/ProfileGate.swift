import Foundation
import Combine

@MainActor
public final class ProfileGate: ObservableObject {
    @Published public var shouldPresentProfileEdit: Bool = false
    @Published public var error: Error?
    @Published public var isEvaluating: Bool = false
    
    private let store: UserProfileStore
    
    init(store: UserProfileStore) {
        self.store = store
    }
    
    public func evaluate(for userId: String) async {
        isEvaluating = true
        error = nil
        
        do {
            if let profile = try await store.fetch(userId: userId) {
                shouldPresentProfileEdit = !profile.isProfileComplete
            } else {
                shouldPresentProfileEdit = true
            }
        } catch {
            // ✅ FIX: Expose error to UI instead of silently swallowing
            self.error = error
            print("❌ [ProfileGate] Error evaluating profile: \(error.localizedDescription)")
            // Still show profile edit as fallback, but user will see error alert
            shouldPresentProfileEdit = true
        }
        
        isEvaluating = false
    }
    
    public func dismissError() {
        error = nil
    }
}

