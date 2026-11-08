import SwiftUI

/// Greeting and progress overview at the top of the dashboard.
struct TaskSummaryCard: View {
    let greetingName: String
    let completedCount: Int
    let pendingCount: Int
    let progress: Double

    private var totalCount: Int { completedCount + pendingCount }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Hello, \(greetingName)")
                    .font(.title3.weight(.semibold))
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(Theme.Palette.accent)
                .accessibilityLabel("Progress")
                .accessibilityValue("\(Int((progress * 100).rounded())) percent complete")

            HStack(spacing: Theme.Spacing.sm) {
                statPill(count: pendingCount, label: "Pending", systemImage: "clock", color: Theme.Palette.pending)
                statPill(count: completedCount, label: "Completed", systemImage: "checkmark.circle.fill", color: Theme.Palette.completed)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.Palette.surface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        )
    }

    private var summaryText: String {
        if totalCount == 0 { return "You have no tasks yet." }
        if pendingCount == 0 { return "All \(totalCount) tasks done. Nice work!" }
        return "\(completedCount) of \(totalCount) tasks completed"
    }

    private func statPill(count: Int, label: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TaskSummaryCard(greetingName: "Saikat", completedCount: 3, pendingCount: 2, progress: 0.6)
        .padding()
        .background(Theme.Palette.background)
}
