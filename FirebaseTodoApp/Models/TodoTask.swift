import Foundation

/// A single todo item stored at `users/{uid}/tasks/{taskId}` in Firestore.
struct TodoTask: Identifiable, Equatable, Hashable, Sendable {
    /// Firestore document ID (also stored in the `id` field).
    let id: String
    var title: String
    /// The task description. Named `details` in Swift to avoid confusion with
    /// `CustomStringConvertible.description`; stored as `description` in Firestore.
    var details: String
    var isCompleted: Bool
    let createdAt: Date
    var updatedAt: Date?

    init(
        id: String,
        title: String,
        details: String,
        isCompleted: Bool = false,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Firestore field names. Must match `Firestore/firestore.rules`.
    enum Field {
        static let id = "id"
        static let title = "title"
        static let description = "description"
        static let isCompleted = "isCompleted"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let ownerID = "ownerId"
    }
}
