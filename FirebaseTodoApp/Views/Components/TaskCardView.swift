import SwiftUI

/// One task in the dashboard list.
struct TaskCardView: View {
    let task: TodoTask
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            completionButton

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !task.details.isEmpty {
                    Text(task.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Spacing.sm) {
                        createdLabel
                        Spacer(minLength: Theme.Spacing.sm)
                        StatusBadge(isCompleted: task.isCompleted)
                    }
                    // Large Dynamic Type sizes: stack the footer instead of truncating.
                    VStack(alignment: .leading, spacing: 6) {
                        createdLabel
                        StatusBadge(isCompleted: task.isCompleted)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 11)
        }
        .padding(.leading, Theme.Spacing.xs)
        .padding(.trailing, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Theme.Palette.surface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onTapGesture(perform: onEdit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(task.title)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Double-tap to edit.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onEdit)
        .accessibilityAction(named: task.isCompleted ? "Mark as pending" : "Mark as completed", onToggleCompletion)
    }

    private var completionButton: some View {
        Button(action: onToggleCompletion) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(task.isCompleted ? Theme.Palette.completed : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: Theme.Size.minTouchTarget, height: Theme.Size.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .sensoryFeedback(.success, trigger: task.isCompleted) { _, isNowCompleted in isNowCompleted }
    }

    private var createdLabel: some View {
        Label {
            Text(task.createdAt, format: .dateTime.day().month(.abbreviated).year().hour().minute())
        } icon: {
            Image(systemName: "calendar")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var accessibilityValue: String {
        let status = task.isCompleted ? "Completed" : "Pending"
        let created = task.createdAt.formatted(date: .abbreviated, time: .shortened)
        let details = task.details.isEmpty ? "" : "\(task.details). "
        return "\(details)\(status). Created \(created)."
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        TaskCardView(
            task: TodoTask(id: "1", title: "Finish lab report", details: "Write the Firestore section and add screenshots.", createdAt: .now),
            onToggleCompletion: {},
            onEdit: {}
        )
        TaskCardView(
            task: TodoTask(id: "2", title: "Buy groceries", details: "", isCompleted: true, createdAt: .now),
            onToggleCompletion: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Theme.Palette.background)
}
#endif
