import Foundation
import Observation

/// Dashboard state: the user's live task list, filters, and quick actions.
@MainActor
@Observable
final class TaskListViewModel {
    let user: AppUser

    private(set) var tasks: [TodoTask] = []
    var filter: TaskFilter = .all
    var searchText = ""
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    var errorMessage: String?
    /// Set when the user asks to delete a task; drives the confirmation dialog.
    var taskPendingDeletion: TodoTask?

    private let taskService: TaskServicing
    @ObservationIgnored private var observation: ObservationToken?

    init(user: AppUser, taskService: TaskServicing) {
        self.user = user
        self.taskService = taskService
    }

    // MARK: Derived state

    /// Tasks after applying the selected filter and search text.
    var visibleTasks: [TodoTask] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return tasks.filter { task in
            guard filter.includes(task) else { return false }
            guard !query.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(query)
                || task.details.localizedCaseInsensitiveContains(query)
        }
    }

    var completedCount: Int { tasks.filter(\.isCompleted).count }
    var pendingCount: Int { tasks.count - completedCount }

    /// Share of tasks completed, from 0 to 1.
    var progress: Double {
        tasks.isEmpty ? 0 : Double(completedCount) / Double(tasks.count)
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: Real-time updates

    func startListening() {
        guard observation == nil else { return }
        isLoading = !hasLoaded
        observation = taskService.observeTasks(userID: user.id) { [weak self] result in
            self?.handle(result)
        }
    }

    func stopListening() {
        observation?.cancel()
        observation = nil
    }

    private func handle(_ result: Result<[TodoTask], Error>) {
        isLoading = false
        hasLoaded = true
        switch result {
        case .success(let tasks):
            self.tasks = tasks.sorted { $0.createdAt > $1.createdAt }
        case .failure(let error):
            errorMessage = ErrorMessageMapper.message(for: error)
        }
    }

    // MARK: Actions

    func toggleCompletion(of task: TodoTask) async {
        do {
            try await taskService.setCompletion(
                userID: user.id,
                taskID: task.id,
                isCompleted: !task.isCompleted
            )
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
        }
    }

    func requestDeletion(of task: TodoTask) {
        taskPendingDeletion = task
    }

    func delete(_ task: TodoTask) async {
        taskPendingDeletion = nil
        do {
            try await taskService.deleteTask(userID: user.id, taskID: task.id)
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
        }
    }
}
