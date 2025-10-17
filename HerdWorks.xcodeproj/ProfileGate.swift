import Foundation
import Combine

@MainActor
public final class ProfileGate: ObservableObject {
    @Published public var shouldPresentProfileEdit: Bool = false
    private let store: UserProfileStore
    
    public init(store: UserProfileStore) {
        self.store = store
    }
    
    public func evaluate(for userId: String) async {
        do {
            if let profile = try await store.fetch(userId: userId) {
                shouldPresentProfileEdit = !profile.isProfileComplete
            } else {
                shouldPresentProfileEdit = true
            }
        } catch {
            shouldPresentProfileEdit = true
        }
    }
}
