import SwiftUI

/// Shown instead of crashing when GoogleService-Info.plist is not in the app bundle.
struct MissingConfigurationView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Firebase isn't configured", systemImage: "exclamationmark.icloud")
        } description: {
            Text("Add GoogleService-Info.plist for bundle ID com.saikat.firebasetodo to FirebaseTodoApp/Resources, then regenerate the project and build again. See MAC_SETUP.md.")
        }
        .background(Theme.Palette.background.ignoresSafeArea())
    }
}

#Preview {
    MissingConfigurationView()
}
