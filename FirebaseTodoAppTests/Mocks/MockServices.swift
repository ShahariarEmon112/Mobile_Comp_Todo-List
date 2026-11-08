import Foundation
@testable import FirebaseTodoApp

/// Test-only token that records cancellation.
final class MockObservationToken: ObservationToken {
    private(set) var isCancelled = false
    func cancel() { isCancelled = true }
}

struct MockError: Error {}

/// In-memory stand-in for FirebaseAuthService. Used only by unit tests.
final class MockAuthService: AuthServicing {
    var currentUser: AppUser?
    var errorToThrow: Error?

    private(set) var signInCalls: [(email: String, password: String)] = []
    private(set) var registerCalls: [(name: String, email: String, password: String)] = []
    private(set) var passwordResetEmails: [String] = []
    private(set) var signOutCallCount = 0
    private var authHandler: (@MainActor (AppUser?) -> Void)?

    func observeAuthState(_ handler: @escaping @MainActor (AppUser?) -> Void) -> ObservationToken {
        authHandler = handler
        return MockObservationToken()
    }

    @MainActor
    func emit(_ user: AppUser?) {
        currentUser = user
        authHandler?(user)
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        signInCalls.append((email, password))
        if let errorToThrow { throw errorToThrow }
        return AppUser(id: "uid-1", email: email, displayName: nil)
    }

    func register(name: String, email: String, password: String) async throws -> AppUser {
        registerCalls.append((name, email, password))
        if let errorToThrow { throw errorToThrow }
        return AppUser(id: "uid-1", email: email, displayName: name)
    }

    func sendPasswordReset(to email: String) async throws {
        passwordResetEmails.append(email)
        if let errorToThrow { throw errorToThrow }
    }

    func signOut() throws {
        signOutCallCount += 1
        if let errorToThrow { throw errorToThrow }
    }
}

/// In-memory stand-in for FirestoreTaskService. Used only by unit tests.
final class MockTaskService: TaskServicing {
    var errorToThrow: Error?

    private(set) var observedUserIDs: [String] = []
    private(set) var createdTasks: [(userID: String, title: String, details: String)] = []
    private(set) var updatedTasks: [TodoTask] = []
    private(set) var completionChanges: [(taskID: String, isCompleted: Bool)] = []
    private(set) var deletedTaskIDs: [String] = []
    private(set) var lastToken: MockObservationToken?
    private var listener: (@MainActor (Result<[TodoTask], Error>) -> Void)?

    func observeTasks(
        userID: String,
        onChange: @escaping @MainActor (Result<[TodoTask], Error>) -> Void
    ) -> ObservationToken {
        observedUserIDs.append(userID)
        listener = onChange
        let token = MockObservationToken()
        lastToken = token
        return token
    }

    @MainActor
    func emit(_ result: Result<[TodoTask], Error>) {
        listener?(result)
    }

    func createTask(userID: String, title: String, details: String) async throws {
        if let errorToThrow { throw errorToThrow }
        createdTasks.append((userID, title, details))
    }

    func updateTask(userID: String, task: TodoTask) async throws {
        if let errorToThrow { throw errorToThrow }
        updatedTasks.append(task)
    }

    func setCompletion(userID: String, taskID: String, isCompleted: Bool) async throws {
        if let errorToThrow { throw errorToThrow }
        completionChanges.append((taskID, isCompleted))
    }

    func deleteTask(userID: String, taskID: String) async throws {
        if let errorToThrow { throw errorToThrow }
        deletedTaskIDs.append(taskID)
    }
}

extension TodoTask {
    static func fixture(
        id: String = UUID().uuidString,
        title: String = "Task",
        details: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) -> TodoTask {
        TodoTask(id: id, title: title, details: details, isCompleted: isCompleted, createdAt: createdAt)
    }
}

extension NSError {
    static func auth(_ code: Int) -> NSError {
        NSError(domain: ErrorMessageMapper.authDomain, code: code)
    }

    static func firestore(_ code: Int) -> NSError {
        NSError(domain: ErrorMessageMapper.firestoreDomain, code: code)
    }
}
