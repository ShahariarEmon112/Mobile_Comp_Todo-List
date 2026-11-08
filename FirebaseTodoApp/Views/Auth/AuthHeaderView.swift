import SwiftUI

/// Logo, title and subtitle at the top of the Login and Register screens.
struct AuthHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            AppLogoView()
            VStack(spacing: 6) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Theme.Spacing.sm)
    }
}
