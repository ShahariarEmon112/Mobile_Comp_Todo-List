import SwiftUI

/// Switches between the splash, sign-in flow, and dashboard based on auth state.
struct RootView: View {
    @Bindable var session: SessionViewModel
    let services: AppServices

    var body: some View {
        ZStack {
            switch session.state {
            case .loading:
                SplashView()
                    .transition(.opacity)
            case .signedOut:
                AuthFlowView(authService: services.auth, onRegistered: session.userDidRegister)
                    .transition(.opacity)
            case .signedIn(let user):
                TaskListView(user: user, taskService: services.tasks, onSignOut: session.signOut)
                    // A different user gets a fresh dashboard and listener.
                    .id(user.id)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.state)
        .task { session.start() }
        .errorAlert($session.errorMessage)
    }
}
