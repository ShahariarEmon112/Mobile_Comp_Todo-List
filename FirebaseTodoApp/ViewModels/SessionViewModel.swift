import Foundation
import Observation

/// Tracks whether a user is signed in and drives the root navigation
/// (splash -> auth screens -> dashboard).
@MainActor
@Observable
final class SessionViewModel {
    enum State: Equatable {
        case loading
        case signedOut
        case signedIn(AppUser)
    }

    private(set) var state: State = .loading
    var errorMessage: String?

    private let authService: AuthServicing
    @ObservationIgnored private var authObservation: ObservationToken?

    init(authService: AuthServicing) {
        self.authService = authService
    }

    /// Starts listening to Firebase auth changes. Safe to call more than once.
    func start() {
        guard authObservation == nil else { return }
        authObservation = authService.observeAuthState { [weak self] user in
            self?.apply(user)
        }
    }

    /// Updates the stored user after registration sets the display name,
    /// because Firebase does not send a new auth event for profile changes.
    func userDidRegister(_ user: AppUser) {
        guard case .signedIn(let current) = state, current.id == user.id else { return }
        state = .signedIn(user)
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
        }
    }

    private func apply(_ user: AppUser?) {
        if let user {
            state = .signedIn(user)
        } else {
            state = .signedOut
        }
    }
}
