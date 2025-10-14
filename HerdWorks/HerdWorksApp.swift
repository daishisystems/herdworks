import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct HerdWorksApp: App {
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
        guard let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            fatalError("❌ Missing Firebase plist: \(plistName).plist")
        }

        print("Bundle.main.bundleIdentifier =", Bundle.main.bundleIdentifier ?? "nil")
        print("Firebase options bundleID =", String(describing: options.bundleID))

        FirebaseApp.configure(options: options)

        #if DEBUG
        let useEmu = ProcessInfo.processInfo.arguments.contains("USE_AUTH_EMULATOR")
        if useEmu {
            #if targetEnvironment(simulator)
            // Simulator connects to localhost
            Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
            #else
            // On-device: replace with your Mac's LAN IP that's reachable from the device
            Auth.auth().useEmulator(withHost: "192.168.15.225", port: 9099)
            #endif
            print("⚙️ Using Firebase Auth Emulator")
        }
        #endif

        #if DEBUG
        print("✅ Firebase initialized for \(plistName)")
        #endif
    }
}
