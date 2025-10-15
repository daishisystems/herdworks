import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

@main
struct HerdWorksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        configureFirebase()
    }

    var body: some Scene {
        WindowGroup {
            RootView() // Temporary placeholder; will become RootView()
        }
    }
}

// MARK: - Firebase Configuration
extension HerdWorksApp {
    func configureFirebase() {
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

        #if DEBUG
        print("✅ Firebase initialized for \(plistName)")
        #endif
    }
}
