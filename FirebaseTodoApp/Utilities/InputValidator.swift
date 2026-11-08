import Foundation

/// Validation rules shared by the auth and task forms.
/// Each function returns a user-facing error message, or `nil` when valid.
/// Task limits match the checks in `Firestore/firestore.rules`.
enum InputValidator {
    static let minimumPasswordLength = 8
    static let maximumNameLength = 50
    static let maximumTitleLength = 120
    static let maximumDescriptionLength = 1000

    private static let emailPattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#

    static func emailError(for email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Enter your email address." }
        if trimmed.range(of: emailPattern, options: .regularExpression) == nil {
            return "Enter a valid email address, like name@example.com."
        }
        return nil
    }

    /// Login only checks that a password was entered; Firebase decides if it is correct.
    static func loginPasswordError(for password: String) -> String? {
        password.isEmpty ? "Enter your password." : nil
    }

    static func newPasswordError(for password: String) -> String? {
        if password.isEmpty { return "Choose a password." }
        if password.count < minimumPasswordLength {
            return "Use at least \(minimumPasswordLength) characters."
        }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        if !hasLetter || !hasNumber {
            return "Include at least one letter and one number."
        }
        return nil
    }

    static func confirmPasswordError(password: String, confirmation: String) -> String? {
        if confirmation.isEmpty { return "Re-enter your password." }
        return password == confirmation ? nil : "Passwords don't match."
    }

    static func nameError(for name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Enter your name." }
        if trimmed.count > maximumNameLength {
            return "Keep your name under \(maximumNameLength) characters."
        }
        return nil
    }

    static func titleError(for title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Give your task a title." }
        if trimmed.count > maximumTitleLength {
            return "Titles can be up to \(maximumTitleLength) characters."
        }
        return nil
    }

    static func descriptionError(for description: String) -> String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > maximumDescriptionLength {
            return "Descriptions can be up to \(maximumDescriptionLength) characters."
        }
        return nil
    }
}
