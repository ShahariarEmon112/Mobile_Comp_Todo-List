import Foundation

/// A handle for a live listener (auth state or Firestore snapshots).
/// Calling `cancel()` stops it; implementations also cancel on deinit.
protocol ObservationToken: AnyObject {
    func cancel()
}

/// Authentication operations used by the view models.
/// `FirebaseAuthService` is the real implementation; tests use a mock.
protocol AuthServicing: AnyObject {
    var currentUser: AppUser? { get }

    /// Calls `handler` now with the current user and again on every sign-in or sign-out.
    func observeAuthState(_ handler: @escaping @MainActor (AppUser?) -> Void) -> ObservationToken

    func signIn(email: String, password: String) async throws -> AppUser
    func register(name: String, email: String, password: String) async throws -> AppUser
    func sendPasswordReset(to email: String) async throws
    func signOut() throws
}

/// Task CRUD for one user's `users/{uid}/tasks` collection.
protocol TaskServicing: AnyObject {
    /// Streams the user's tasks in real time, newest first.
    func observeTasks(
        userID: String,
        onChange: @escaping @MainActor (Result<[TodoTask], Error>) -> Void
    ) -> ObservationToken

    func createTask(userID: String, title: String, details: String) async throws
    func updateTask(userID: String, task: TodoTask) async throws
    func setCompletion(userID: String, taskID: String, isCompleted: Bool) async throws
    func deleteTask(userID: String, taskID: String) async throws
}

/// The live services the app runs with.
struct AppServices {
    let auth: AuthServicing
    let tasks: TaskServicing

    /// Call only after `FirebaseBootstrap.configure()` returned `true`.
    static func firebase() -> AppServices {
        AppServices(auth: FirebaseAuthService(), tasks: FirestoreTaskService())
    }
}
