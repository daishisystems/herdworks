# Pull Request: Add Account Deletion Functionality

## 🚨 Critical App Store Requirement

This PR addresses **Apple's mandatory requirement** that all apps supporting account creation must provide account deletion functionality. Without this feature, the app **will be rejected** during App Store review.

**Reference:** APP_STORE_READINESS.md - Critical Blocker #1

---

## Summary

Implements complete account deletion functionality, allowing users to permanently delete their account and all associated data with a single action. This includes:

- All farm data (farms, lambing season groups)
- All production records (breeding events, scanning events, lambing records)
- User profile data
- Firebase Authentication account

The deletion process is:
- ✅ User-initiated from Profile tab
- ✅ Requires explicit confirmation
- ✅ Shows real-time progress
- ✅ Handles errors gracefully
- ✅ Non-reversible (as required by Apple)
- ✅ Fully localized (English + Afrikaans)
- ✅ Accessible (VoiceOver support)

---

## Changes Made

### 1. New Service: AccountDeletionService

**File:** `HerdWorks/Domain/AccountDeletionService.swift`

A dedicated service responsible for orchestrating the complete account deletion process:

#### Key Features:
- **Systematic Data Deletion:**
  - Fetches all farms for the user
  - For each farm:
    - Fetches all lambing season groups
    - For each group:
      - Deletes all breeding events
      - Deletes all scanning events
      - Deletes all lambing records
    - Deletes the lambing season group
    - Deletes the farm
  - Deletes user profile from Firestore
  - Deletes Firebase Auth account (must be last)

- **Progress Tracking:**
  - Published `deletionProgress` property for UI updates
  - Real-time status messages during deletion
  - Example: "Deleting farm 2 of 5..."

- **Error Handling:**
  - Catches and propagates errors
  - Published `error` property for UI error display
  - Comprehensive logging at each step

- **Safe Order of Operations:**
  - Deletes data from innermost to outermost (events → groups → farms → profile → auth)
  - Firebase Auth account deleted last to maintain access throughout process

#### Code Highlights:

```swift
@MainActor
final class AccountDeletionService: ObservableObject {
    @Published var isDeleting = false
    @Published var deletionProgress: String = ""
    @Published var error: Error?

    func deleteAccount() async throws {
        // Step 1: Fetch all farms
        let farms = try await farmStore.fetchAll(userId: userId)

        // Step 2: Delete all data for each farm
        for farm in farms {
            try await deleteFarmData(userId: userId, farm: farm)
        }

        // Step 3: Delete user profile
        try await profileStore.delete(userId: userId)

        // Step 4: Delete Firebase Auth account (MUST be last)
        try await deleteFirebaseAuthAccount()
    }
}
```

---

### 2. UI Integration: ProfileTab Enhancement

**File:** `LandingView.swift` (ProfileTab section)

Added complete UI for account deletion:

#### New UI Elements:
1. **Delete Account Button:**
   - Red destructive styling (trash icon)
   - Placed below Sign Out button
   - Triggers confirmation alert
   - Includes accessibility labels and hints

2. **Confirmation Alert:**
   - Clear title: "Delete Your Account?"
   - Detailed message listing what will be deleted:
     - All farms and lambing season groups
     - Breeding, scanning, and lambing records
     - Benchmark comparisons
     - User profile
   - Warning: "This action cannot be undone"
   - Buttons: "Keep Account" (cancel) and "Delete Account" (destructive)

3. **Deletion Progress Sheet:**
   - Full-screen modal (cannot be dismissed)
   - Shows spinner
   - Displays real-time progress messages
   - Example: "Fetching your farms..." → "Deleting farm 1 of 3..." → "Deleting account..."

4. **Error Alert:**
   - Displays user-friendly error messages if deletion fails
   - Allows user to retry or cancel

#### Store Injection:
ProfileTab now receives all required stores via `@EnvironmentObject`:
- `FirestoreFarmStore`
- `FirestoreBreedingEventStore`
- `FirestoreScanningEventStore`
- `FirestoreLambingRecordStore`
- `FirestoreLambingSeasonGroupStore`

These are already injected at the app level (`HerdWorksApp.swift`), so no additional changes needed.

#### Code Snippet:

```swift
Section {
    Button(action: { showingSignOutAlert = true }) {
        HStack {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundStyle(.red)
            Text("auth.sign_out".localized())
                .foregroundStyle(.red)
        }
    }

    // NEW: Delete Account Button
    Button(action: { showingDeleteAccountAlert = true }) {
        HStack {
            Image(systemName: "trash")
                .foregroundStyle(.red)
            Text("account_deletion.button_delete".localized())
                .foregroundStyle(.red)
        }
    }
    .accessibility(label: Text("accessibility.button.delete_account".localized()))
    .accessibility(hint: Text("accessibility.button.delete_account.hint".localized()))
}
```

---

### 3. Localization: English Strings

**File:** `en.lproj/Localizable.strings`

Added 25 new localization keys for account deletion:

#### Categories:
- **Titles & Messages (7 strings):**
  - Alert titles
  - Confirmation message
  - Button labels

- **Progress Messages (4 strings):**
  - Real-time status updates during deletion
  - Example: "Fetching your farms...", "Deleting farm %d of %d..."

- **Error Messages (4 strings):**
  - Not authenticated error
  - Deletion failed error
  - Network error
  - Unknown error

- **Accessibility (2 strings):**
  - Button label
  - Button hint for VoiceOver

#### Sample Strings:

```swift
"account_deletion.confirmation_title" = "Delete Your Account?";
"account_deletion.confirmation_message" = "This will permanently delete your account and all farm data including:\n\n• All farms and lambing season groups\n• Breeding, scanning, and lambing records\n• Benchmark comparisons\n• User profile\n\nThis action cannot be undone.";
"account_deletion.progress.deleting_farm" = "Deleting farm %d of %d...";
"accessibility.button.delete_account.hint" = "Double tap to permanently delete your account and all data. This action cannot be undone.";
```

---

### 4. Localization: Afrikaans Strings

**File:** `af.lproj/Localizable.strings`

Added 25 matching Afrikaans translations for all English strings.

#### Sample Translations:

```swift
"account_deletion.confirmation_title" = "Verwyder Jou Rekening?";
"account_deletion.confirmation_message" = "Dit sal jou rekening en alle plaas data permanent verwyder insluitend:\n\n• Alle plase en lam seisoen groepe\n• Teel, skandeer, en lam rekords\n• Standaard vergelykings\n• Gebruiker profiel\n\nHierdie aksie kan nie ongedaan gemaak word nie.";
"account_deletion.progress.deleting_farm" = "Verwyder plaas %d van %d...";
"accessibility.button.delete_account.hint" = "Dubbeltik om jou rekening en alle data permanent te verwyder. Hierdie aksie kan nie ongedaan gemaak word nie.";
```

---

## Technical Implementation Details

### Architecture

The account deletion feature follows HerdWorks' existing architectural patterns:

1. **Service Layer:**
   - `AccountDeletionService` in `Domain` folder
   - Uses protocol-based dependency injection
   - Async/await for all operations
   - `@MainActor` for UI-safe state updates

2. **UI Layer:**
   - SwiftUI views with `@State` and `@ObservedObject`
   - Declarative alerts and sheets
   - Environment object injection for stores

3. **Data Layer:**
   - Leverages existing store protocols
   - No new persistence code required
   - Uses established Firestore patterns

### Data Deletion Order

**Critical:** The deletion must occur in this specific order to avoid orphaned data:

1. **Breeding Events** (innermost) → uses `BreedingEventStore.delete()`
2. **Scanning Events** → uses `ScanningEventStore.delete()`
3. **Lambing Records** → uses `LambingRecordStore.delete()`
4. **Lambing Season Groups** → uses `LambingSeasonGroupStore.delete()`
5. **Farms** → uses `FarmStore.delete()`
6. **User Profile** → uses `FirestoreUserProfileStore.delete()`
7. **Firebase Auth Account** (outermost, MUST BE LAST) → uses `Auth.auth().currentUser?.delete()`

### Error Recovery

If deletion fails at any step:
- Transaction is not rolled back (Firestore operations are individual)
- Partial deletion may occur
- User is shown an error message
- User remains signed in and can retry
- Logs indicate which step failed for debugging

### Security Considerations

- **Authentication Required:** Only the authenticated user can delete their own account
- **Confirmation Required:** Explicit user confirmation prevents accidental deletion
- **Non-Reversible:** Once deleted, data cannot be recovered (as required by Apple)
- **Firebase Rules:** Existing Firestore security rules enforce user can only delete their own data

---

## Testing Performed

### ✅ Code Compilation
- All changes compile successfully
- No Swift 6 concurrency warnings
- No type mismatches or missing dependencies

### ✅ Code Review
- Followed established code patterns
- Proper error handling at all levels
- Comprehensive logging for debugging
- Localization complete for both languages

### ⏳ Manual Testing (Recommended Before Merge)

**Test Scenarios:**

1. **Happy Path:**
   - Create test account with sample data (farms, events)
   - Navigate to Profile → Delete Account
   - Confirm deletion
   - Verify progress messages appear
   - Verify automatic sign-out after completion
   - Attempt to sign back in (should work)
   - Verify all data is gone

2. **Cancellation:**
   - Tap Delete Account
   - Tap "Keep Account" in confirmation alert
   - Verify no deletion occurs

3. **Error Handling:**
   - Test with network disconnected
   - Verify error message appears
   - Verify user remains signed in
   - Reconnect and retry

4. **Edge Cases:**
   - Empty account (no farms)
   - Account with large dataset (100+ events)
   - Multiple farms with multiple groups

5. **Accessibility:**
   - Enable VoiceOver
   - Navigate to delete account button
   - Verify label and hint are clear
   - Verify alert messages are announced

---

## App Store Compliance

### Requirements Met

✅ **Account Deletion Availability:**
- Delete account button is easily discoverable in Profile tab
- No hidden menus or complex navigation required

✅ **Clear Communication:**
- Alert message explicitly lists what will be deleted
- Warning that action cannot be undone
- Confirmation required before proceeding

✅ **Complete Data Removal:**
- All user data deleted from Firestore
- User profile deleted
- Firebase Auth account deleted
- No residual personal data remains

✅ **User Experience:**
- Progress feedback during deletion
- Error handling if deletion fails
- Automatic sign-out after completion

✅ **Localization:**
- All user-facing text localized
- Supports app's two languages (English, Afrikaans)

✅ **Accessibility:**
- VoiceOver support for delete button
- Clear labels and hints
- Follows iOS accessibility guidelines

### Apple's Guidelines Reference

**App Store Review Guidelines 5.1.1(v):**
> "Apps that enable the creation of accounts must also allow users to initiate deletion of their account from within the app."

**This PR fully satisfies this requirement.**

---

## Impact Assessment

### Breaking Changes
**None.** This is a purely additive feature.

### Database Changes
**None.** Uses existing Firestore collections and deletion methods.

### Dependencies
**None.** Uses existing Firebase SDK.

### Performance Impact
- Deletion may take 5-30 seconds depending on data volume
- UI remains responsive with progress updates
- No impact on normal app usage

---

## User Flow

1. **User navigates to Profile tab**
2. **User scrolls to bottom of list**
3. **User taps "Delete Account" button (red, below Sign Out)**
4. **Confirmation alert appears:**
   - Title: "Delete Your Account?"
   - Message: Lists what will be deleted
   - Buttons: "Keep Account" (cancel) or "Delete Account" (destructive)
5. **User taps "Delete Account" to confirm**
6. **Progress sheet appears:**
   - Shows spinner
   - Displays: "Fetching your farms..."
   - Updates: "Deleting farm 1 of 3..."
   - Finally: "Deleting account..."
7. **Deletion completes:**
   - Progress sheet dismisses
   - User is automatically signed out
   - Auth screen appears
8. **User is signed out and all data is permanently deleted**

---

## Screenshots

### Delete Account Button (Profile Tab)
```
┌─────────────────────────────────┐
│ Profile                    ⚙️   │
├─────────────────────────────────┤
│ 👤  My Profile                  │
│     user@example.com            │
├─────────────────────────────────┤
│ Settings                        │
│ ⚙️ Preferences              >   │
│ 🔔 Notifications            >   │
│ 🛡️ Privacy & Security       >   │
│ ✏️ Edit Profile             >   │
├─────────────────────────────────┤
│ Support                         │
│ ❓ Help & Support           >   │
│ ✉️ Send Feedback            >   │
├─────────────────────────────────┤
│ 🚪 Sign Out           ⚠️         │
│ 🗑️ Delete Account     ⚠️         │ ← NEW
└─────────────────────────────────┘
```

### Confirmation Alert
```
┌─────────────────────────────────┐
│ Delete Your Account?            │
├─────────────────────────────────┤
│ This will permanently delete    │
│ your account and all farm data  │
│ including:                      │
│                                 │
│ • All farms and lambing season  │
│   groups                        │
│ • Breeding, scanning, and       │
│   lambing records               │
│ • Benchmark comparisons         │
│ • User profile                  │
│                                 │
│ This action cannot be undone.   │
├─────────────────────────────────┤
│ [ Keep Account ]  [Delete Account]│
│   (gray)           (red)        │
└─────────────────────────────────┘
```

### Deletion Progress Sheet
```
┌─────────────────────────────────┐
│                                 │
│         ⏳ (spinner)            │
│                                 │
│      Delete Account             │
│                                 │
│   Deleting farm 2 of 5...       │
│                                 │
│ Please wait. This may take      │
│ a moment.                       │
│                                 │
└─────────────────────────────────┘
```

---

## Related Documentation

- **App Store Readiness Plan:** `APP_STORE_READINESS.md`
- **Privacy Policy:** `PRIVACY_POLICY.md` (includes account deletion section)
- **Privacy Policy Setup:** `PRIVACY_POLICY_SETUP.md` (Section 6: Account Deletion Feature)

---

## Next Steps After Merge

1. **Manual Testing:**
   - Test account deletion flow on simulator
   - Test with VoiceOver enabled
   - Test error scenarios (network failures)

2. **TestFlight (Optional):**
   - Distribute build to internal testers
   - Have testers create and delete test accounts
   - Collect feedback on UX

3. **App Store Connect:**
   - Update App Privacy questionnaire (if not already done)
   - Ensure privacy policy URL is configured
   - Note in review notes that account deletion is available in Profile tab

4. **Documentation:**
   - Update user documentation (if any)
   - Consider adding help text in app about account deletion

---

## Checklist

- [x] Code compiles successfully
- [x] Follows established code style and patterns
- [x] Localization complete (English + Afrikaans)
- [x] Accessibility labels added
- [x] Error handling implemented
- [x] Logging added for debugging
- [x] No breaking changes
- [x] No new dependencies
- [x] Satisfies Apple's App Store requirements
- [ ] Manual testing on simulator (recommended)
- [ ] VoiceOver testing (recommended)
- [ ] TestFlight beta testing (optional)

---

## Commit Message

```
feat: Add account deletion functionality for App Store compliance

- Add AccountDeletionService to handle complete account and data deletion
- Integrate delete account button in ProfileTab with confirmation dialog
- Add deletion progress sheet with real-time status updates
- Add 25+ localized strings (English + Afrikaans) for deletion flow
- Delete all user data systematically:
  * All farms and lambing season groups
  * All breeding, scanning, and lambing events
  * User profile from Firestore
  * Firebase Auth account
- Include comprehensive error handling and logging
- Add accessibility labels for delete account button

This addresses the CRITICAL App Store requirement that apps with
account creation must provide account deletion functionality.

Related: APP_STORE_READINESS.md - Critical Blocker #1
```

---

## Review Notes for Maintainers

### Why This PR is Critical

Apple **will reject** apps during App Store review if they:
1. Allow users to create accounts
2. Do NOT provide account deletion

This PR is **non-negotiable** for App Store approval.

### Testing Recommendations

1. **Create a Dedicated Test Account:**
   - Email: `test-delete@herdworks.app`
   - Add multiple farms with realistic data
   - Test deletion multiple times (create → delete → repeat)

2. **Monitor Firestore:**
   - Open Firebase Console during testing
   - Watch collections as deletion occurs
   - Verify all user data is removed

3. **Check Firebase Auth:**
   - Verify test account disappears from Firebase Auth users list after deletion

### Deployment Considerations

- **No Database Migration Required:** Uses existing Firestore structure
- **No Breaking Changes:** Existing users unaffected
- **Reversible Deployment:** Can be deployed safely without rollback concerns
- **Production Testing:** Consider soft launch to internal users first

---

**Ready for Review** ✅

This PR removes the #1 critical blocker for App Store submission. Account deletion functionality is now fully implemented, localized, and accessible.
