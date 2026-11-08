import FirebaseAuth
import Foundation

/// Email/password authentication backed by Firebase Authentication.
/// Firebase stores the session in the Keychain, so users stay signed in
/// between launches until they sign out.
final class FirebaseAuthService: AuthServicing {
    private var auth: Auth { Auth.auth() }

    var currentUser: AppUser? {
        auth.currentUser.map(AppUser.init(firebaseUser:))
    }

    func observeAuthState(_ handler: @escaping @MainActor (AppUser?) -> Void) -> ObservationToken {
        let handle = auth.addStateDidChangeListener { _, user in
            let appUser = user.map(AppUser.init(firebaseUser:))
            Task { @MainActor in handler(appUser) }
        }
        return AuthStateObservation(handle: handle)
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        let result = try await auth.signIn(withEmail: email, password: password)
        return AppUser(firebaseUser: result.user)
    }

    func register(name: String, email: String, password: String) async throws -> AppUser {
        let result = try await auth.createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        // The account already exists at this point; a failed name update
        // should not be reported as a failed registration.
        try? await changeRequest.commitChanges()
        return AppUser(id: result.user.uid, email: result.user.email ?? email, displayName: name)
    }

    func sendPasswordReset(to email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try auth.signOut()
    }
}

private final class AuthStateObservation: ObservationToken {
    private var handle: NSObjectProtocol?

    init(handle: NSObjectProtocol) {
        self.handle = handle
    }

    func cancel() {
        guard let handle else { return }
        Auth.auth().removeStateDidChangeListener(handle)
        self.handle = nil
    }

    deinit { cancel() }
}

extension AppUser {
    init(firebaseUser: User) {
        self.init(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName
        )
    }
}
