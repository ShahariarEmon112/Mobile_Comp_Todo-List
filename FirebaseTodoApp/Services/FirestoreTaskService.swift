import FirebaseFirestore
import Foundation

/// Task CRUD backed by Cloud Firestore.
///
/// Data layout: `users/{uid}/tasks/{taskId}`. Every document stores its own
/// `id` and `ownerId`, which the security rules check against the path.
final class FirestoreTaskService: TaskServicing {
    enum Path {
        static let users = "users"
        static let tasks = "tasks"
    }

    private var db: Firestore { Firestore.firestore() }

    private func tasksCollection(for userID: String) -> CollectionReference {
        db.collection(Path.users).document(userID).collection(Path.tasks)
    }

    // MARK: Read (real-time)

    func observeTasks(
        userID: String,
        onChange: @escaping @MainActor (Result<[TodoTask], Error>) -> Void
    ) -> ObservationToken {
        let registration = tasksCollection(for: userID)
            .order(by: TodoTask.Field.createdAt, descending: true)
            .addSnapshotListener { snapshot, error in
                let result: Result<[TodoTask], Error>
                if let error {
                    result = .failure(error)
                } else {
                    // `.estimate` fills in pending server timestamps locally so new
                    // tasks appear instantly, before the server confirms the write.
                    let tasks = snapshot?.documents.compactMap { document in
                        TaskDocumentMapper.task(
                            id: document.documentID,
                            data: document.data(with: .estimate)
                        )
                    } ?? []
                    result = .success(tasks)
                }
                Task { @MainActor in onChange(result) }
            }
        return FirestoreListenerObservation(registration: registration)
    }

    // MARK: Create

    func createTask(userID: String, title: String, details: String) async throws {
        let document = tasksCollection(for: userID).document()
        let data = TaskDocumentMapper.newTaskData(
            id: document.documentID,
            ownerID: userID,
            title: title,
            details: details
        )
        try await document.setData(data)
    }

    // MARK: Update

    func updateTask(userID: String, task: TodoTask) async throws {
        try await tasksCollection(for: userID)
            .document(task.id)
            .updateData(TaskDocumentMapper.updateData(for: task))
    }

    func setCompletion(userID: String, taskID: String, isCompleted: Bool) async throws {
        try await tasksCollection(for: userID)
            .document(taskID)
            .updateData(TaskDocumentMapper.completionData(isCompleted: isCompleted))
    }

    // MARK: Delete

    func deleteTask(userID: String, taskID: String) async throws {
        try await tasksCollection(for: userID).document(taskID).delete()
    }
}

/// Converts between `TodoTask` and Firestore document data.
enum TaskDocumentMapper {
    typealias Field = TodoTask.Field

    static func task(id: String, data: [String: Any]) -> TodoTask? {
        guard let title = data[Field.title] as? String else { return nil }
        return TodoTask(
            id: id,
            title: title,
            details: data[Field.description] as? String ?? "",
            isCompleted: data[Field.isCompleted] as? Bool ?? false,
            createdAt: (data[Field.createdAt] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data[Field.updatedAt] as? Timestamp)?.dateValue()
        )
    }

    static func newTaskData(id: String, ownerID: String, title: String, details: String) -> [String: Any] {
        [
            Field.id: id,
            Field.ownerID: ownerID,
            Field.title: title,
            Field.description: details,
            Field.isCompleted: false,
            Field.createdAt: FieldValue.serverTimestamp(),
        ]
    }

    static func updateData(for task: TodoTask) -> [AnyHashable: Any] {
        [
            Field.title: task.title,
            Field.description: task.details,
            Field.isCompleted: task.isCompleted,
            Field.updatedAt: FieldValue.serverTimestamp(),
        ]
    }

    static func completionData(isCompleted: Bool) -> [AnyHashable: Any] {
        [
            Field.isCompleted: isCompleted,
            Field.updatedAt: FieldValue.serverTimestamp(),
        ]
    }
}

private final class FirestoreListenerObservation: ObservationToken {
    private var registration: ListenerRegistration?

    init(registration: ListenerRegistration) {
        self.registration = registration
    }

    func cancel() {
        registration?.remove()
        registration = nil
    }

    deinit { cancel() }
}
