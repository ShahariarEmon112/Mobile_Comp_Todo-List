import SwiftUI

/// Design tokens used across the app. Colors adapt to light and dark mode
/// through system colors and the asset catalog (`Resources/Assets.xcassets`).
enum Theme {
    enum Palette {
        /// Teal brand color (`AccentColor` in the asset catalog).
        static let accent = Color.accentColor
        static let completed = Color("TaskCompleted")
        static let pending = Color("TaskPending")
        static let danger = Color(uiColor: .systemRed)
        static let background = Color(uiColor: .systemGroupedBackground)
        static let surface = Color(uiColor: .secondarySystemGroupedBackground)
        static let border = Color(uiColor: .separator)
    }

    /// 4pt spacing rhythm.
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let control: CGFloat = 12
        static let card: CGFloat = 16
        static let logo: CGFloat = 22
    }

    enum Size {
        /// Minimum touch target recommended by Apple's HIG.
        static let minTouchTarget: CGFloat = 44
        static let buttonHeight: CGFloat = 52
        static let fieldHeight: CGFloat = 50
        /// Keeps forms readable on iPad and in landscape.
        static let maxFormWidth: CGFloat = 480
    }
}
