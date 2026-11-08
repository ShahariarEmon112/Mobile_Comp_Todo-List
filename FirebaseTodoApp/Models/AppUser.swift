import Foundation

/// The signed-in user, decoupled from the Firebase `User` type.
struct AppUser: Identifiable, Equatable, Sendable {
    let id: String
    let email: String
    let displayName: String?

    /// A friendly name for greetings: the display name, or the part of the
    /// email address before the "@".
    var greetingName: String {
        if let displayName, !displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            return displayName
        }
        return email.split(separator: "@").first.map(String.init) ?? email
    }
}
