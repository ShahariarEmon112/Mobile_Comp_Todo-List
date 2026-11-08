import SwiftUI

/// Secure text field with a show/hide toggle. Works with password managers
/// through `textContentType`.
struct PasswordField<FocusValue: Hashable>: View {
    let placeholder: String
    var accessibilityTitle = "Password"
    @Binding var text: String
    var textContentType: UITextContentType = .password
    let focus: FocusState<FocusValue?>.Binding
    let focusValue: FocusValue

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(textContentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused(focus, equals: focusValue)
            .accessibilityLabel(accessibilityTitle)

            Button {
                isRevealed.toggle()
                focus.wrappedValue = focusValue
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
                    .frame(width: Theme.Size.minTouchTarget, height: Theme.Size.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, -Theme.Spacing.sm)
            .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
        }
    }
}
