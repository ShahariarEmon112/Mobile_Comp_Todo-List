import SwiftUI

/// Form used by both the Add Task and Edit Task screens.
struct TaskEditorView: View {
    private enum Field: Hashable {
        case title
        case details
    }

    @Bindable var viewModel: TaskEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                descriptionSection
                if let task = viewModel.originalTask {
                    statusSection
                    infoSection(for: task)
                    deleteSection
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .disabled(viewModel.isSaving || viewModel.isDeleting)
            .interactiveDismissDisabled(viewModel.hasChanges || viewModel.isSaving)
            .confirmationDialog("Discard your changes?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
            .confirmationDialog("Delete this task?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete Task", role: .destructive) { delete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
            .errorAlert($viewModel.errorMessage)
            .onChange(of: viewModel.title) { viewModel.titleError = nil }
            .onChange(of: viewModel.details) { viewModel.detailsError = nil }
            .onAppear {
                if !viewModel.isEditing { focusedField = .title }
            }
        }
    }

    // MARK: Sections

    private var titleSection: some View {
        Section {
            TextField("What needs to be done?", text: $viewModel.title)
                .font(.body.weight(.medium))
                .submitLabel(.next)
                .focused($focusedField, equals: .title)
                .onSubmit { focusedField = .details }
                .accessibilityLabel("Title")
        } header: {
            Text("Title")
        } footer: {
            fieldFooter(
                error: viewModel.titleError,
                count: viewModel.trimmedTitle.count,
                limit: InputValidator.maximumTitleLength
            )
        }
    }

    private var descriptionSection: some View {
        Section {
            TextField("Add details (optional)", text: $viewModel.details, axis: .vertical)
                .lineLimit(4...10)
                .focused($focusedField, equals: .details)
                .accessibilityLabel("Description")
        } header: {
            Text("Description")
        } footer: {
            fieldFooter(
                error: viewModel.detailsError,
                count: viewModel.trimmedDetails.count,
                limit: InputValidator.maximumDescriptionLength
            )
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Toggle(isOn: $viewModel.isCompleted) {
                Label(
                    viewModel.isCompleted ? "Completed" : "Pending",
                    systemImage: viewModel.isCompleted ? "checkmark.circle.fill" : "clock"
                )
                .foregroundStyle(viewModel.isCompleted ? Theme.Palette.completed : Theme.Palette.pending)
            }
            .tint(Theme.Palette.completed)
            .accessibilityLabel("Mark as completed")
        }
    }

    private func infoSection(for task: TodoTask) -> some View {
        Section("Details") {
            LabeledContent("Created", value: task.createdAt.formatted(date: .long, time: .shortened))
            if let updatedAt = task.updatedAt {
                LabeledContent("Last updated", value: updatedAt.formatted(date: .long, time: .shortened))
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isDeleting {
                        ProgressView()
                    } else {
                        Label("Delete Task", systemImage: "trash")
                    }
                    Spacer()
                }
            }
        }
    }

    private func fieldFooter(error: String?, count: Int, limit: Int) -> some View {
        HStack(alignment: .top) {
            if let error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(Theme.Palette.danger)
            }
            Spacer()
            Text("\(count)/\(limit)")
                .monospacedDigit()
                .foregroundStyle(count > limit ? Theme.Palette.danger : .secondary)
                .accessibilityLabel("\(count) of \(limit) characters")
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if viewModel.hasChanges {
                    isConfirmingDiscard = true
                } else {
                    dismiss()
                }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            if viewModel.isSaving {
                ProgressView()
                    .accessibilityLabel("Saving")
            } else {
                Button(viewModel.isEditing ? "Save" : "Add") { save() }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canSave)
            }
        }
    }

    // MARK: Actions

    private func save() {
        focusedField = nil
        Task {
            if await viewModel.save() { dismiss() }
        }
    }

    private func delete() {
        Task {
            if await viewModel.delete() { dismiss() }
        }
    }
}
