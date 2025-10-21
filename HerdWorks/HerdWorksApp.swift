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
        
        // ✅ MODERN API: Enable offline persistence for field users
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        
        let db = Firestore.firestore()
        db.settings = settings

        #if DEBUG
        print("✅ Firebase initialized for \(plistName)")
        print("✅ Firestore offline persistence enabled with unlimited cache")
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
