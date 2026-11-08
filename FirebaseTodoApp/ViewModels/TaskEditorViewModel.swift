import Foundation
import Observation

/// Shared logic for the Add Task and Edit Task screens.
@MainActor
@Observable
final class TaskEditorViewModel {
    enum Mode: Equatable {
        case create
        case edit(TodoTask)
    }

    let mode: Mode

    var title: String
    var details: String
    var isCompleted: Bool

    var titleError: String?
    var detailsError: String?
    var errorMessage: String?

    private(set) var isSaving = false
    private(set) var isDeleting = false

    private let userID: String
    private let taskService: TaskServicing

    init(mode: Mode, userID: String, taskService: TaskServicing) {
        self.mode = mode
        self.userID = userID
        self.taskService = taskService
        switch mode {
        case .create:
            title = ""
            details = ""
            isCompleted = false
        case .edit(let task):
            title = task.title
            details = task.details
            isCompleted = task.isCompleted
        }
    }

    // MARK: Derived state

    var originalTask: TodoTask? {
        if case .edit(let task) = mode { return task }
        return nil
    }

    var isEditing: Bool { originalTask != nil }

    var navigationTitle: String { isEditing ? "Edit Task" : "New Task" }

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedDetails: String { details.trimmingCharacters(in: .whitespacesAndNewlines) }

    var hasChanges: Bool {
        guard let original = originalTask else {
            return !trimmedTitle.isEmpty || !trimmedDetails.isEmpty
        }
        return trimmedTitle != original.title
            || trimmedDetails != original.details
            || isCompleted != original.isCompleted
    }

    var canSave: Bool {
        !isSaving && !isDeleting && !trimmedTitle.isEmpty && hasChanges
    }

    // MARK: Actions

    @discardableResult
    func validate() -> Bool {
        titleError = InputValidator.titleError(for: title)
        detailsError = InputValidator.descriptionError(for: details)
        return titleError == nil && detailsError == nil
    }

    /// Creates or updates the task. Returns `true` when the screen can close.
    func save() async -> Bool {
        guard !isSaving else { return false }
        errorMessage = nil
        guard validate() else { return false }

        isSaving = true
        defer { isSaving = false }
        do {
            if let original = originalTask {
                var updated = original
                updated.title = trimmedTitle
                updated.details = trimmedDetails
                updated.isCompleted = isCompleted
                try await taskService.updateTask(userID: userID, task: updated)
            } else {
                try await taskService.createTask(userID: userID, title: trimmedTitle, details: trimmedDetails)
            }
            return true
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
            return false
        }
    }

    /// Deletes the task being edited. Returns `true` when the screen can close.
    func delete() async -> Bool {
        guard let original = originalTask, !isDeleting else { return false }
        errorMessage = nil
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await taskService.deleteTask(userID: userID, taskID: original.id)
            return true
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
            return false
        }
    }
}
