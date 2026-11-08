import XCTest
@testable import FirebaseTodoApp

final class ModelTests: XCTestCase {
    func testTaskFilter() {
        let pending = TodoTask.fixture(isCompleted: false)
        let done = TodoTask.fixture(isCompleted: true)

        XCTAssertTrue(TaskFilter.all.includes(pending))
        XCTAssertTrue(TaskFilter.all.includes(done))
        XCTAssertTrue(TaskFilter.pending.includes(pending))
        XCTAssertFalse(TaskFilter.pending.includes(done))
        XCTAssertTrue(TaskFilter.completed.includes(done))
        XCTAssertFalse(TaskFilter.completed.includes(pending))
    }

    func testGreetingNameFallsBackToEmail() {
        XCTAssertEqual(AppUser(id: "1", email: "saikat@uni.edu", displayName: "Saikat").greetingName, "Saikat")
        XCTAssertEqual(AppUser(id: "1", email: "saikat@uni.edu", displayName: nil).greetingName, "saikat")
        XCTAssertEqual(AppUser(id: "1", email: "saikat@uni.edu", displayName: "  ").greetingName, "saikat")
    }

    func testFirestoreFieldNamesMatchSecurityRules() {
        XCTAssertEqual(TodoTask.Field.description, "description")
        XCTAssertEqual(TodoTask.Field.ownerID, "ownerId")
        XCTAssertEqual(TodoTask.Field.isCompleted, "isCompleted")
        XCTAssertEqual(TodoTask.Field.createdAt, "createdAt")
    }
}

final class ErrorMessageMapperTests: XCTestCase {
    func testAuthErrors() {
        XCTAssertEqual(
            ErrorMessageMapper.message(for: NSError.auth(ErrorMessageMapper.AuthCode.invalidCredential)),
            "Incorrect email or password."
        )
        XCTAssertEqual(
            ErrorMessageMapper.message(for: NSError.auth(ErrorMessageMapper.AuthCode.wrongPassword)),
            "Incorrect email or password."
        )
        XCTAssertTrue(
            ErrorMessageMapper.message(for: NSError.auth(ErrorMessageMapper.AuthCode.emailAlreadyInUse))
                .contains("already exists")
        )
        XCTAssertTrue(
            ErrorMessageMapper.message(for: NSError.auth(ErrorMessageMapper.AuthCode.networkError))
                .contains("Network")
        )
    }

    func testFirestoreErrors() {
        XCTAssertEqual(
            ErrorMessageMapper.message(for: NSError.firestore(ErrorMessageMapper.FirestoreCode.permissionDenied)),
            "You don't have permission to do that."
        )
        XCTAssertTrue(
            ErrorMessageMapper.message(for: NSError.firestore(ErrorMessageMapper.FirestoreCode.unavailable))
                .contains("connection")
        )
    }

    func testUnknownErrorsUseGenericMessage() {
        XCTAssertEqual(ErrorMessageMapper.message(for: MockError()), ErrorMessageMapper.genericMessage)
        XCTAssertEqual(ErrorMessageMapper.message(for: NSError.auth(99999)), ErrorMessageMapper.genericMessage)
    }
}
