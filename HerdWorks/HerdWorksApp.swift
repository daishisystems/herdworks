import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        configureFirebase()
        return true
    }
    
    // MARK: - Firebase Configuration
    private func configureFirebase() {
        // Pick correct GoogleService-Info plist based on Info.plist key
        let plistName = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_PLIST_NAME") as? String
            ?? "GoogleService-Info-Prod"
        #if DEBUG
        let resolvedName = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_PLIST_NAME") as? String ?? "(missing)"
        print("FIREBASE_PLIST_NAME =", resolvedName)
        #endif
        
        // ✅ FIX: Gracefully handle missing Firebase configuration instead of crashing
        guard let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            #if DEBUG
            // In debug builds, assert for developer awareness
            assertionFailure("❌ Missing Firebase plist: \(plistName).plist")
            print("❌ CRITICAL: Firebase configuration file '\(plistName).plist' not found.")
            print("❌ Please ensure the correct GoogleService-Info plist is included in your target.")
            #endif
            // In production, continue without crashing - app will show error UI when Firebase is needed
            print("⚠️ WARNING: Firebase not configured. Some features may be unavailable.")
            return
        }

        print("Bundle.main.bundleIdentifier =", Bundle.main.bundleIdentifier ?? "nil")
        print("Firebase options bundleID =", String(describing: options.bundleID))

        FirebaseApp.configure(options: options)
        
        // ✅ MODERN API: Enable offline persistence for field users with bounded cache (Info.plist configurable)
        let settings = FirestoreSettings()

        // Firestore cache size configuration (Info.plist-driven)
        // - Keys:
        //   - FIRESTORE_CACHE_MB_DEV  (Number or String): Cache size in MB for Debug builds. Default = 48.
        //   - FIRESTORE_CACHE_MB_PROD (Number or String): Cache size in MB for Release builds. Default = 192.
        // - Rationale:
        //   Field-first app with offline usage needs a bounded cache for predictability and responsiveness.
        //   Values are read from Info.plist; if missing or invalid, sensible defaults are used.
        // - Notes:
        //   - Minimum enforced is 1 MB to avoid accidental zero/negative.
        //   - Adjust these values per your offline data footprint and validate with Instruments.

        // Read cache size (MB) from Info.plist with sensible defaults
        let devCacheMB = (Bundle.main.object(forInfoDictionaryKey: "FIRESTORE_CACHE_MB_DEV") as? NSNumber)?.intValue
            ?? Int((Bundle.main.object(forInfoDictionaryKey: "FIRESTORE_CACHE_MB_DEV") as? String) ?? "") ?? 48
        let prodCacheMB = (Bundle.main.object(forInfoDictionaryKey: "FIRESTORE_CACHE_MB_PROD") as? NSNumber)?.intValue
            ?? Int((Bundle.main.object(forInfoDictionaryKey: "FIRESTORE_CACHE_MB_PROD") as? String) ?? "") ?? 192

        #if DEBUG
        let selectedCacheMB = max(1, devCacheMB)
        #else
        let selectedCacheMB = max(1, prodCacheMB)
        #endif
        let cacheBytes = selectedCacheMB * 1024 * 1024

        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: cacheBytes))

        let db = Firestore.firestore()
        db.settings = settings

        #if DEBUG
        print("✅ Firebase initialized for \(plistName)")
        print("✅ Firestore offline persistence enabled with bounded cache: \(selectedCacheMB) MB (from Info.plist)")
        #endif
    }
}

@main
struct HerdWorksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Existing State Objects

    // ✅ Use FirestoreUserProfileStore for production
    @StateObject private var profileGate = ProfileGate(
        store: FirestoreUserProfileStore()
    )

    // ✅ Add LanguageManager
    @StateObject private var languageManager = LanguageManager.shared
    
    // ✅ FIX: Add NetworkMonitor for connectivity awareness
    @StateObject private var networkMonitor = NetworkMonitor.shared

    // MARK: - Shared Firestore Stores
    // ✅ FIX: Create shared store instances once at app level to prevent memory leak
    // Previously: Each BenchmarkComparisonView created 4 new stores (64+ instances for 16 groups)
    // Now: Single shared instance per store type used throughout app

    @StateObject private var benchmarkStore = FirestoreBenchmarkStore()
    @StateObject private var breedingStore = FirestoreBreedingEventStore()
    @StateObject private var scanningStore = FirestoreScanningEventStore()
    @StateObject private var lambingStore = FirestoreLambingRecordStore()
    @StateObject private var farmStore = FirestoreFarmStore()
    @StateObject private var groupStore = FirestoreLambingSeasonGroupStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(profileGate)
                .environmentObject(languageManager)
                .environmentObject(networkMonitor)  // ✅ FIX: Add network monitor
                // ✅ FIX: Inject shared stores into environment for dependency injection
                .environmentObject(benchmarkStore)
                .environmentObject(breedingStore)
                .environmentObject(scanningStore)
                .environmentObject(lambingStore)
                .environmentObject(farmStore)
                .environmentObject(groupStore)
        }
    }
}
