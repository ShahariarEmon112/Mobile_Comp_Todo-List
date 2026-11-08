import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""

    var emailError: String?
    var passwordError: String?
    /// Error returned by Firebase, shown in a banner above the form.
    var errorMessage: String?
    /// Confirmation after a password reset email is sent.
    var infoMessage: String?

    private(set) var isLoading = false

    private let authService: AuthServicing

    init(authService: AuthServicing) {
        self.authService = authService
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Validates the form. Returns `true` when it can be submitted.
    @discardableResult
    func validate() -> Bool {
        emailError = InputValidator.emailError(for: email)
        passwordError = InputValidator.loginPasswordError(for: password)
        return emailError == nil && passwordError == nil
    }

    func signIn() async {
        guard !isLoading else { return }
        errorMessage = nil
        guard validate() else { return }

        isLoading = true
        defer { isLoading = false }
        do {
            // On success the auth listener in SessionViewModel switches to the dashboard.
            _ = try await authService.signIn(email: trimmedEmail, password: password)
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
        }
    }

    func sendPasswordReset() async {
        guard !isLoading else { return }
        errorMessage = nil
        emailError = InputValidator.emailError(for: email)
        guard emailError == nil else { return }

        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.sendPasswordReset(to: trimmedEmail)
            infoMessage = "If an account exists for \(trimmedEmail), we've sent a link to reset your password."
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
        }
    }
}
