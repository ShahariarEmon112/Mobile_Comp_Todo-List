import SwiftUI

/// Main dashboard: progress summary, filters, and the live task list.
struct TaskListView: View {
    @State private var viewModel: TaskListViewModel
    @State private var isAddingTask = false
    @State private var editingTask: TodoTask?
    @State private var isConfirmingSignOut = false

    private let taskService: TaskServicing
    private let onSignOut: @MainActor () -> Void

    init(user: AppUser, taskService: TaskServicing, onSignOut: @escaping @MainActor () -> Void) {
        _viewModel = State(initialValue: TaskListViewModel(user: user, taskService: taskService))
        self.taskService = taskService
        self.onSignOut = onSignOut
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Palette.background.ignoresSafeArea())
                .navigationTitle("My Tasks")
                .toolbar { toolbarContent }
                .searchable(text: $viewModel.searchText, prompt: "Search tasks")
        }
        .task { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
        .sheet(isPresented: $isAddingTask) {
            AddTaskView(userID: viewModel.user.id, taskService: taskService)
        }
        .sheet(item: $editingTask) { task in
            EditTaskView(task: task, userID: viewModel.user.id, taskService: taskService)
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: isConfirmingDeletion,
            titleVisibility: .visible,
            presenting: viewModel.taskPendingDeletion
        ) { task in
            Button("Delete Task", role: .destructive) {
                Task { await viewModel.delete(task) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { task in
            Text("\u{201C}\(task.title)\u{201D} will be permanently deleted.")
        }
        .confirmationDialog("Sign out of your account?", isPresented: $isConfirmingSignOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                viewModel.stopListening()
                onSignOut()
            }
            Button("Cancel", role: .cancel) {}
        }
        .errorAlert($viewModel.errorMessage)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading || !viewModel.hasLoaded {
            ProgressView("Loading your tasks\u{2026}")
        } else if viewModel.tasks.isEmpty {
            ContentUnavailableView {
                Label("No tasks yet", systemImage: "checklist")
            } description: {
                Text("Create your first task to start tracking what you need to do.")
            } actions: {
                Button {
                    isAddingTask = true
                } label: {
                    Label("Add Task", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, Theme.Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        } else {
            taskList
        }
    }

    private var taskList: some View {
        List {
            TaskSummaryCard(
                greetingName: viewModel.user.greetingName,
                completedCount: viewModel.completedCount,
                pendingCount: viewModel.pendingCount,
                progress: viewModel.progress
            )
            .cardRow(top: Theme.Spacing.sm)

            Picker("Filter", selection: $viewModel.filter) {
                ForEach(TaskFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .cardRow(top: Theme.Spacing.sm, bottom: Theme.Spacing.sm)

            if viewModel.visibleTasks.isEmpty {
                filteredEmptyState
                    .cardRow()
            } else {
                ForEach(viewModel.visibleTasks) { task in
                    TaskCardView(
                        task: task,
                        onToggleCompletion: { toggle(task) },
                        onEdit: { editingTask = task }
                    )
                    .cardRow()
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { toggle(task) } label: {
                            Label(
                                task.isCompleted ? "Mark Pending" : "Complete",
                                systemImage: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle"
                            )
                        }
                        .tint(task.isCompleted ? Theme.Palette.pending : Theme.Palette.completed)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button { viewModel.requestDeletion(of: task) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(Theme.Palette.danger)

                        Button { editingTask = task } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Theme.Palette.accent)
                    }
                    .contextMenu {
                        Button { editingTask = task } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button { toggle(task) } label: {
                            Label(
                                task.isCompleted ? "Mark as Pending" : "Mark as Completed",
                                systemImage: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle"
                            )
                        }
                        Divider()
                        Button(role: .destructive) { viewModel.requestDeletion(of: task) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.default, value: viewModel.visibleTasks)
    }

    @ViewBuilder
    private var filteredEmptyState: some View {
        if viewModel.isSearching {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else if viewModel.filter == .completed {
            ContentUnavailableView(
                "Nothing completed yet",
                systemImage: "checkmark.circle",
                description: Text("Tasks you complete will show up here.")
            )
        } else {
            ContentUnavailableView(
                "All caught up",
                systemImage: "party.popper",
                description: Text("You have no pending tasks.")
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Section(viewModel.user.email) {
                    Button(role: .destructive) {
                        isConfirmingSignOut = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title3)
            }
            .accessibilityLabel("Account")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isAddingTask = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Add task")
        }
    }

    // MARK: Helpers

    private var isConfirmingDeletion: Binding<Bool> {
        Binding(
            get: { viewModel.taskPendingDeletion != nil },
            set: { isPresented in
                if !isPresented { viewModel.taskPendingDeletion = nil }
            }
        )
    }

    private func toggle(_ task: TodoTask) {
        Task { await viewModel.toggleCompletion(of: task) }
    }
}

private extension View {
    /// Styles a List row as a floating card on the grouped background.
    func cardRow(top: CGFloat = 6, bottom: CGFloat = 6) -> some View {
        listRowInsets(EdgeInsets(top: top, leading: Theme.Spacing.md, bottom: bottom, trailing: Theme.Spacing.md))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
