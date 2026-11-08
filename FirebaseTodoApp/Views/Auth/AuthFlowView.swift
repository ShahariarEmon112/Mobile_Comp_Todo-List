import SwiftUI

enum AuthRoute: Hashable {
    case register
}

/// Navigation container for the signed-out screens (Login -> Register).
struct AuthFlowView: View {
    let authService: AuthServicing
    let onRegistered: @MainActor (AppUser) -> Void

    var body: some View {
        NavigationStack {
            LoginView(authService: authService)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView(authService: authService, onRegistered: onRegistered)
                    }
                }
        }
    }
}
