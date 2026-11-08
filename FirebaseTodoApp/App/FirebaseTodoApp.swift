import SwiftUI

@main
struct FirebaseTodoApp: App {
    private let services: AppServices?
    @State private var session: SessionViewModel?

    init() {
        // Firebase must be configured before any Auth or Firestore call,
        // so it happens here rather than in a later lifecycle callback.
        if FirebaseBootstrap.configure() {
            let services = AppServices.firebase()
            self.services = services
            _session = State(initialValue: SessionViewModel(authService: services.auth))
        } else {
            services = nil
            _session = State(initialValue: nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let services, let session {
                RootView(session: session, services: services)
            } else {
                MissingConfigurationView()
            }
        }
    }
}
