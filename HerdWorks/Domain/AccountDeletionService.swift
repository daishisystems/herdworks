//
//  AccountDeletionService.swift
//  HerdWorks
//
//  Created by Claude on 2025/01/19.
//  Purpose: Handles complete account deletion including all user data from Firestore and Firebase Auth
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

/// Service responsible for deleting user account and all associated data
@MainActor
final class AccountDeletionService: ObservableObject {
    private let farmStore: FirestoreFarmStore
    private let breedingStore: FirestoreBreedingEventStore
    private let scanningStore: FirestoreScanningEventStore
    private let lambingStore: FirestoreLambingRecordStore
    private let groupStore: FirestoreLambingSeasonGroupStore
    private let profileStore: FirestoreUserProfileStore

    @Published var isDeleting = false
    @Published var deletionProgress: String = ""
    @Published var error: Error?

    init(
        farmStore: FirestoreFarmStore,
        breedingStore: FirestoreBreedingEventStore,
        scanningStore: FirestoreScanningEventStore,
        lambingStore: FirestoreLambingRecordStore,
        groupStore: FirestoreLambingSeasonGroupStore,
        profileStore: FirestoreUserProfileStore
    ) {
        self.farmStore = farmStore
        self.breedingStore = breedingStore
        self.scanningStore = scanningStore
        self.lambingStore = lambingStore
        self.groupStore = groupStore
        self.profileStore = profileStore
    }

    /// Deletes the user's account and all associated data
    /// - Throws: Error if deletion fails at any step
    func deleteAccount() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AccountDeletionError.notAuthenticated
        }

        isDeleting = true
        error = nil

        do {
            // Step 1: Fetch all farms for this user
            deletionProgress = "account_deletion.progress.fetching_farms".localized()
            print("🗑️ [ACCOUNT-DELETE] Step 1: Fetching all farms for user: \(userId)")
            let farms = try await farmStore.fetchAll(userId: userId)
            print("🗑️ [ACCOUNT-DELETE] Found \(farms.count) farms to delete")

            // Step 2: Delete all data for each farm
            for (index, farm) in farms.enumerated() {
                deletionProgress = String(format: "account_deletion.progress.deleting_farm".localized(), index + 1, farms.count)
                print("🗑️ [ACCOUNT-DELETE] Step 2.\(index + 1): Processing farm: \(farm.name) (ID: \(farm.id))")

                try await deleteFarmData(userId: userId, farm: farm)
            }

            // Step 3: Delete user profile from Firestore
            deletionProgress = "account_deletion.progress.deleting_profile".localized()
            print("🗑️ [ACCOUNT-DELETE] Step 3: Deleting user profile")
            try await profileStore.delete(userId: userId)
            print("✅ [ACCOUNT-DELETE] User profile deleted")

            // Step 4: Delete Firebase Auth account (MUST be last)
            deletionProgress = "account_deletion.progress.deleting_auth".localized()
            print("🗑️ [ACCOUNT-DELETE] Step 4: Deleting Firebase Auth account")
            try await deleteFirebaseAuthAccount()
            print("✅ [ACCOUNT-DELETE] Firebase Auth account deleted")

            print("✅ [ACCOUNT-DELETE] Account deletion completed successfully")
            
            // ✅ Success haptic feedback
            HapticFeedbackManager.shared.success()
            
            isDeleting = false

        } catch {
            print("❌ [ACCOUNT-DELETE] Error during deletion: \(error.localizedDescription)")
            
            // ✅ Error haptic feedback
            HapticFeedbackManager.shared.error()
            
            self.error = error
            isDeleting = false
            throw error
        }
    }

    /// Deletes all data associated with a specific farm
    private func deleteFarmData(userId: String, farm: Farm) async throws {
        print("🗑️ [ACCOUNT-DELETE] Deleting data for farm: \(farm.name)")

        // Fetch all lambing season groups for this farm
        let groups = try await groupStore.fetchAll(userId: userId, farmId: farm.id)
        print("🗑️ [ACCOUNT-DELETE] Found \(groups.count) lambing season groups for farm: \(farm.name)")

        // Delete all data for each group
        for group in groups {
            print("🗑️ [ACCOUNT-DELETE] Processing group: \(group.displayName) (ID: \(group.id))")
            try await deleteGroupData(userId: userId, farmId: farm.id, groupId: group.id)

            // Delete the group itself
            print("🗑️ [ACCOUNT-DELETE] Deleting group: \(group.displayName)")
            try await groupStore.delete(userId: userId, farmId: farm.id, groupId: group.id)
            print("✅ [ACCOUNT-DELETE] Group deleted: \(group.displayName)")
        }

        // Delete the farm
        print("🗑️ [ACCOUNT-DELETE] Deleting farm: \(farm.name)")
        try await farmStore.delete(farmId: farm.id, userId: userId)
        print("✅ [ACCOUNT-DELETE] Farm deleted: \(farm.name)")
    }

    /// Deletes all events and records for a specific lambing season group
    private func deleteGroupData(userId: String, farmId: String, groupId: String) async throws {
        print("🗑️ [ACCOUNT-DELETE] Deleting events for group: \(groupId)")

        // Delete all breeding events
        let breedingEvents = try await breedingStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
        print("🗑️ [ACCOUNT-DELETE] Found \(breedingEvents.count) breeding events to delete")
        for event in breedingEvents {
            try await breedingStore.delete(userId: userId, farmId: farmId, groupId: groupId, eventId: event.id)
        }
        print("✅ [ACCOUNT-DELETE] Deleted \(breedingEvents.count) breeding events")

        // Delete all scanning events
        let scanningEvents = try await scanningStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
        print("🗑️ [ACCOUNT-DELETE] Found \(scanningEvents.count) scanning events to delete")
        for event in scanningEvents {
            try await scanningStore.delete(userId: userId, farmId: farmId, groupId: groupId, eventId: event.id)
        }
        print("✅ [ACCOUNT-DELETE] Deleted \(scanningEvents.count) scanning events")

        // Delete all lambing records
        let lambingRecords = try await lambingStore.fetchAll(userId: userId, farmId: farmId, groupId: groupId)
        print("🗑️ [ACCOUNT-DELETE] Found \(lambingRecords.count) lambing records to delete")
        for record in lambingRecords {
            try await lambingStore.delete(userId: userId, farmId: farmId, groupId: groupId, recordId: record.id)
        }
        print("✅ [ACCOUNT-DELETE] Deleted \(lambingRecords.count) lambing records")
    }

    /// Deletes the Firebase Authentication account
    private func deleteFirebaseAuthAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AccountDeletionError.notAuthenticated
        }

        try await user.delete()
    }
}

// MARK: - Errors

enum AccountDeletionError: LocalizedError {
    case notAuthenticated
    case deletionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "account_deletion.error.not_authenticated".localized()
        case .deletionFailed(let reason):
            return String(format: "account_deletion.error.deletion_failed".localized(), reason)
        }
    }
}
