import SwiftUI

struct RegisterView: View {
    private enum Field: Hashable {
        case name
        case email
        case password
        case confirmPassword
    }

    @State private var viewModel: RegisterViewModel
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss

    init(authService: AuthServicing, onRegistered: @escaping @MainActor (AppUser) -> Void) {
        _viewModel = State(initialValue: RegisterViewModel(authService: authService, onRegistered: onRegistered))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                AuthHeaderView(
                    title: "Create account",
                    subtitle: "Your tasks are saved securely and synced to your account."
                )

                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message)
                        .transition(.opacity)
                }

                VStack(spacing: Theme.Spacing.md) {
                    LabeledFormField("Name", error: viewModel.nameError) {
                        TextField("Your name", text: $viewModel.name)
                            .accessibilityLabel("Name")
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .name)
                            .onSubmit { focusedField = .email }
                    }

                    LabeledFormField("Email", error: viewModel.emailError) {
                        TextField("name@example.com", text: $viewModel.email)
                            .accessibilityLabel("Email")
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }
                    }

                    LabeledFormField(
                        "Password",
                        error: viewModel.passwordError,
                        hint: "At least \(InputValidator.minimumPasswordLength) characters, with a letter and a number."
                    ) {
                        PasswordField(
                            placeholder: "Create a password",
                            text: $viewModel.password,
                            textContentType: .newPassword,
                            focus: $focusedField,
                            focusValue: .password
                        )
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
                    }

                    LabeledFormField("Confirm password", error: viewModel.confirmPasswordError) {
                        PasswordField(
                            placeholder: "Re-enter your password",
                            accessibilityTitle: "Confirm password",
                            text: $viewModel.confirmPassword,
                            textContentType: .newPassword,
                            focus: $focusedField,
                            focusValue: .confirmPassword
                        )
                        .submitLabel(.join)
                        .onSubmit(register)
                    }
                }

                PrimaryButton(title: "Create Account", isLoading: viewModel.isLoading, action: register)

                HStack(spacing: Theme.Spacing.xs) {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign in") { dismiss() }
                        .fontWeight(.semibold)
                        .frame(minHeight: Theme.Size.minTouchTarget)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
            .frame(maxWidth: Theme.Size.maxFormWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Palette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .onChange(of: viewModel.name) { viewModel.nameError = nil }
        .onChange(of: viewModel.email) { viewModel.emailError = nil }
        .onChange(of: viewModel.password) { viewModel.passwordError = nil }
        .onChange(of: viewModel.confirmPassword) { viewModel.confirmPasswordError = nil }
    }

    private func register() {
        focusedField = nil
        Task { await viewModel.register() }
    }
}
