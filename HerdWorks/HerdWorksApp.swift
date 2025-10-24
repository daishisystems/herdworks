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
        guard let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            fatalError("❌ Missing Firebase plist: \(plistName).plist")
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

    // ✅ Use FirestoreUserProfileStore for production
    @StateObject private var profileGate = ProfileGate(
        store: FirestoreUserProfileStore()
    )
    
    // ✅ Add LanguageManager
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(profileGate)
                .environmentObject(languageManager)  // ✅ Inject language manager
        }
    }
}
