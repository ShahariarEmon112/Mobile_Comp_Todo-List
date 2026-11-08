import SwiftUI

/// Brand mark: a checklist symbol on a rounded teal square.
struct AppLogoView: View {
    var size: CGFloat = 72

    var body: some View {
        Image(systemName: "checklist")
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Theme.Palette.accent.gradient,
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    AppLogoView()
}
