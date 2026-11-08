import SwiftUI

/// Edit Task screen: change title, description and status, or delete the task.
struct EditTaskView: View {
    @State private var viewModel: TaskEditorViewModel

    init(task: TodoTask, userID: String, taskService: TaskServicing) {
        _viewModel = State(initialValue: TaskEditorViewModel(mode: .edit(task), userID: userID, taskService: taskService))
    }

    var body: some View {
        TaskEditorView(viewModel: viewModel)
    }
}
