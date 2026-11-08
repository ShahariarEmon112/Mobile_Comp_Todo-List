import SwiftUI

/// A text input with a visible label above it and an inline error or hint below.
struct LabeledFormField<Content: View>: View {
    let label: String
    let error: String?
    let hint: String?
    let content: Content

    init(
        _ label: String,
        error: String?,
        hint: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.error = error
        self.hint = hint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            content
                .padding(.horizontal, 14)
                .frame(minHeight: Theme.Size.fieldHeight)
                .background(
                    Theme.Palette.surface,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(
                            error == nil ? Theme.Palette.border : Theme.Palette.danger,
                            lineWidth: error == nil ? 0.5 : 1.5
                        )
                )

            if let error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.danger)
                    .accessibilityLabel("\(label) error: \(error)")
                    .transition(.opacity)
            } else if let hint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.easeOut(duration: 0.2), value: error)
    }
}
