import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var name = ""
    var email = ""
    var password = ""
    var confirmPassword = ""

    var nameError: String?
    var emailError: String?
    var passwordError: String?
    var confirmPasswordError: String?
    var errorMessage: String?

    private(set) var isLoading = false

    private let authService: AuthServicing
    private let onRegistered: @MainActor (AppUser) -> Void

    init(authService: AuthServicing, onRegistered: @escaping @MainActor (AppUser) -> Void = { _ in }) {
        self.authService = authService
        self.onRegistered = onRegistered
    }

    @discardableResult
    func validate() -> Bool {
        nameError = InputValidator.nameError(for: name)
        emailError = InputValidator.emailError(for: email)
        passwordError = InputValidator.newPasswordError(for: password)
        confirmPasswordError = InputValidator.confirmPasswordError(password: password, confirmation: confirmPassword)
        return [nameError, emailError, passwordError, confirmPasswordError].allSatisfy { $0 == nil }
    }

    func register() async {
        guard !isLoading else { return }
        errorMessage = nil
        guard validate() else { return }

        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await authService.register(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            onRegistered(user)
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
        }
    }
}
