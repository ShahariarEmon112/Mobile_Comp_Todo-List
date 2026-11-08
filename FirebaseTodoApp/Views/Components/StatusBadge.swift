import SwiftUI

/// "Completed" / "Pending" chip. Uses an icon and text, not color alone.
struct StatusBadge: View {
    let isCompleted: Bool

    private var color: Color { isCompleted ? Theme.Palette.completed : Theme.Palette.pending }

    var body: some View {
        Label(
            isCompleted ? "Completed" : "Pending",
            systemImage: isCompleted ? "checkmark.circle.fill" : "clock"
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, Theme.Spacing.xs)
        .background(color.opacity(0.14), in: Capsule())
        .fixedSize()
    }
}

#Preview {
    HStack {
        StatusBadge(isCompleted: false)
        StatusBadge(isCompleted: true)
    }
}
