import FirebaseCore
import Foundation

/// Configures Firebase from `GoogleService-Info.plist` exactly once.
enum FirebaseBootstrap {
    static let configFileName = "GoogleService-Info"

    /// Returns `false` (instead of crashing) when the plist is missing from the app bundle.
    @discardableResult
    static func configure() -> Bool {
        if FirebaseApp.app() != nil { return true }
        guard Bundle.main.path(forResource: configFileName, ofType: "plist") != nil else {
            return false
        }
        FirebaseApp.configure()
        return true
    }
}
