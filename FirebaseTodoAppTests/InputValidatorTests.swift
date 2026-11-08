import XCTest
@testable import FirebaseTodoApp

final class InputValidatorTests: XCTestCase {
    func testEmailValidation() {
        XCTAssertNil(InputValidator.emailError(for: "student@uni.edu"))
        XCTAssertNil(InputValidator.emailError(for: "  first.last+todo@example.co.uk  "))
        XCTAssertNotNil(InputValidator.emailError(for: ""))
        XCTAssertNotNil(InputValidator.emailError(for: "not-an-email"))
        XCTAssertNotNil(InputValidator.emailError(for: "missing@tld"))
        XCTAssertNotNil(InputValidator.emailError(for: "@example.com"))
    }

    func testLoginPasswordOnlyRequiresInput() {
        XCTAssertNotNil(InputValidator.loginPasswordError(for: ""))
        XCTAssertNil(InputValidator.loginPasswordError(for: "x"))
    }

    func testNewPasswordRules() {
        XCTAssertNotNil(InputValidator.newPasswordError(for: ""))
        XCTAssertNotNil(InputValidator.newPasswordError(for: "abc12"), "too short")
        XCTAssertNotNil(InputValidator.newPasswordError(for: "abcdefgh"), "no number")
        XCTAssertNotNil(InputValidator.newPasswordError(for: "12345678"), "no letter")
        XCTAssertNil(InputValidator.newPasswordError(for: "secret123"))
    }

    func testConfirmPassword() {
        XCTAssertNil(InputValidator.confirmPasswordError(password: "secret123", confirmation: "secret123"))
        XCTAssertNotNil(InputValidator.confirmPasswordError(password: "secret123", confirmation: "secret124"))
        XCTAssertNotNil(InputValidator.confirmPasswordError(password: "secret123", confirmation: ""))
    }

    func testName() {
        XCTAssertNil(InputValidator.nameError(for: "Saikat"))
        XCTAssertNotNil(InputValidator.nameError(for: "   "))
        XCTAssertNotNil(InputValidator.nameError(for: String(repeating: "a", count: InputValidator.maximumNameLength + 1)))
    }

    func testTitleLimitsMatchSecurityRules() {
        XCTAssertNotNil(InputValidator.titleError(for: ""))
        XCTAssertNotNil(InputValidator.titleError(for: "  \n "))
        XCTAssertNil(InputValidator.titleError(for: String(repeating: "a", count: 120)))
        XCTAssertNotNil(InputValidator.titleError(for: String(repeating: "a", count: 121)))
    }

    func testDescriptionLimitsMatchSecurityRules() {
        XCTAssertNil(InputValidator.descriptionError(for: ""))
        XCTAssertNil(InputValidator.descriptionError(for: String(repeating: "a", count: 1000)))
        XCTAssertNotNil(InputValidator.descriptionError(for: String(repeating: "a", count: 1001)))
    }
}
