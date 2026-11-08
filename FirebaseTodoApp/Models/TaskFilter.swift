import Foundation

/// Segments shown above the task list.
enum TaskFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case pending
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .completed: return "Completed"
        }
    }

    func includes(_ task: TodoTask) -> Bool {
        switch self {
        case .all: return true
        case .pending: return !task.isCompleted
        case .completed: return task.isCompleted
        }
    }
}
