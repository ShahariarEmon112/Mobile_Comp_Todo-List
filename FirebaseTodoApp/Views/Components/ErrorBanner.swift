import SwiftUI

/// Inline banner for errors returned by Firebase (wrong password, network, etc.).
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text(message)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .foregroundStyle(Theme.Palette.danger)
        .padding(Theme.Spacing.md)
        .background(
            Theme.Palette.danger.opacity(0.12),
            in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

#Preview {
    ErrorBanner(message: "Incorrect email or password.")
        .padding()
}
