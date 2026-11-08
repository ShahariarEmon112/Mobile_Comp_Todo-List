import SwiftUI

/// Add Task screen (presented as a sheet from the dashboard).
struct AddTaskView: View {
    @State private var viewModel: TaskEditorViewModel

    init(userID: String, taskService: TaskServicing) {
        _viewModel = State(initialValue: TaskEditorViewModel(mode: .create, userID: userID, taskService: taskService))
    }

    var body: some View {
        TaskEditorView(viewModel: viewModel)
    }
}
