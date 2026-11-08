import SwiftUI

struct LoginView: View {
    private enum Field: Hashable {
        case email
        case password
    }

    @State private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?

    init(authService: AuthServicing) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                AuthHeaderView(
                    title: "Welcome back",
                    subtitle: "Sign in to see and manage your tasks."
                )

                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message)
                        .transition(.opacity)
                }

                VStack(spacing: Theme.Spacing.md) {
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

                    LabeledFormField("Password", error: viewModel.passwordError) {
                        PasswordField(
                            placeholder: "Your password",
                            text: $viewModel.password,
                            textContentType: .password,
                            focus: $focusedField,
                            focusValue: .password
                        )
                        .submitLabel(.go)
                        .onSubmit(signIn)
                    }

                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            focusedField = nil
                            Task { await viewModel.sendPasswordReset() }
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(minHeight: Theme.Size.minTouchTarget)
                        .disabled(viewModel.isLoading)
                    }
                }

                PrimaryButton(title: "Sign In", isLoading: viewModel.isLoading, action: signIn)

                HStack(spacing: Theme.Spacing.xs) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    NavigationLink("Create one", value: AuthRoute.register)
                        .fontWeight(.semibold)
                        .frame(minHeight: Theme.Size.minTouchTarget)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
            .frame(maxWidth: Theme.Size.maxFormWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Palette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeOut(duration: 0.2), value: viewModel.errorMessage)
        .onChange(of: viewModel.email) { viewModel.emailError = nil }
        .onChange(of: viewModel.password) { viewModel.passwordError = nil }
        .messageAlert("Check your inbox", message: $viewModel.infoMessage)
    }

    private func signIn() {
        focusedField = nil
        Task { await viewModel.signIn() }
    }
}
