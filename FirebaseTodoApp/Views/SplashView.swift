import SwiftUI

/// Shown briefly while Firebase restores the saved session.
struct SplashView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            AppLogoView(size: 88)
            ProgressView()
                .accessibilityLabel("Loading")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.background.ignoresSafeArea())
    }
}

#Preview {
    SplashView()
}
