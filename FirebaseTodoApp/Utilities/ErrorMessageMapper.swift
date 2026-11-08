import Foundation

/// Turns Firebase and network errors into short, friendly messages.
///
/// Matches on the `NSError` domain and code so it works without importing
/// Firebase (and can be unit tested). Codes come from `FIRAuthErrorCode`
/// and `FIRFirestoreErrorCode` in the Firebase Apple SDK.
enum ErrorMessageMapper {
    static let authDomain = "FIRAuthErrorDomain"
    static let firestoreDomain = "FIRFirestoreErrorDomain"
    static let genericMessage = "Something went wrong. Please try again."

    enum AuthCode {
        static let invalidCredential = 17004
        static let userDisabled = 17005
        static let operationNotAllowed = 17006
        static let emailAlreadyInUse = 17007
        static let invalidEmail = 17008
        static let wrongPassword = 17009
        static let tooManyRequests = 17010
        static let userNotFound = 17011
        static let networkError = 17020
        static let weakPassword = 17026
    }

    enum FirestoreCode {
        static let cancelled = 1
        static let deadlineExceeded = 4
        static let notFound = 5
        static let permissionDenied = 7
        static let resourceExhausted = 8
        static let unavailable = 14
        static let unauthenticated = 16
    }

    static func message(for error: Error) -> String {
        let nsError = error as NSError
        switch nsError.domain {
        case authDomain:
            return authMessage(forCode: nsError.code)
        case firestoreDomain:
            return firestoreMessage(forCode: nsError.code)
        case NSURLErrorDomain:
            return "You appear to be offline. Check your connection and try again."
        default:
            return genericMessage
        }
    }

    static func authMessage(forCode code: Int) -> String {
        switch code {
        case AuthCode.invalidCredential, AuthCode.wrongPassword, AuthCode.userNotFound:
            return "Incorrect email or password."
        case AuthCode.emailAlreadyInUse:
            return "An account with this email already exists. Try signing in instead."
        case AuthCode.invalidEmail:
            return "That email address doesn't look right."
        case AuthCode.weakPassword:
            return "That password is too weak. Use at least \(InputValidator.minimumPasswordLength) characters with letters and numbers."
        case AuthCode.userDisabled:
            return "This account has been disabled."
        case AuthCode.tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case AuthCode.networkError:
            return "Network error. Check your connection and try again."
        case AuthCode.operationNotAllowed:
            return "Email sign-in is not enabled for this Firebase project."
        default:
            return genericMessage
        }
    }

    static func firestoreMessage(forCode code: Int) -> String {
        switch code {
        case FirestoreCode.permissionDenied:
            return "You don't have permission to do that."
        case FirestoreCode.unauthenticated:
            return "Your session has expired. Please sign in again."
        case FirestoreCode.notFound:
            return "This task no longer exists."
        case FirestoreCode.unavailable, FirestoreCode.deadlineExceeded:
            return "Can't reach the server. Check your connection and try again."
        case FirestoreCode.resourceExhausted:
            return "The server is busy. Please try again later."
        default:
            return genericMessage
        }
    }
}
