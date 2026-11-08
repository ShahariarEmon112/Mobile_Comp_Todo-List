import XCTest
@testable import FirebaseTodoApp

@MainActor
final class AuthViewModelTests: XCTestCase {
    // MARK: Login

    func testLoginWithInvalidInputDoesNotCallFirebase() async {
        let auth = MockAuthService()
        let viewModel = LoginViewModel(authService: auth)
        viewModel.email = "bad"
        viewModel.password = ""

        await viewModel.signIn()

        XCTAssertNotNil(viewModel.emailError)
        XCTAssertNotNil(viewModel.passwordError)
        XCTAssertTrue(auth.signInCalls.isEmpty)
    }

    func testLoginTrimsEmailAndSignsIn() async {
        let auth = MockAuthService()
        let viewModel = LoginViewModel(authService: auth)
        viewModel.email = "  student@uni.edu "
        viewModel.password = "secret123"

        await viewModel.signIn()

        XCTAssertEqual(auth.signInCalls.first?.email, "student@uni.edu")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoginShowsFriendlyFirebaseError() async {
        let auth = MockAuthService()
        auth.errorToThrow = NSError.auth(ErrorMessageMapper.AuthCode.invalidCredential)
        let viewModel = LoginViewModel(authService: auth)
        viewModel.email = "student@uni.edu"
        viewModel.password = "wrong"

        await viewModel.signIn()

        XCTAssertEqual(viewModel.errorMessage, "Incorrect email or password.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testPasswordResetRequiresValidEmail() async {
        let auth = MockAuthService()
        let viewModel = LoginViewModel(authService: auth)

        await viewModel.sendPasswordReset()
        XCTAssertNotNil(viewModel.emailError)
        XCTAssertTrue(auth.passwordResetEmails.isEmpty)

        viewModel.email = "student@uni.edu"
        await viewModel.sendPasswordReset()
        XCTAssertEqual(auth.passwordResetEmails, ["student@uni.edu"])
        XCTAssertNotNil(viewModel.infoMessage)
    }

    // MARK: Register

    func testRegisterValidatesAllFields() async {
        let auth = MockAuthService()
        let viewModel = RegisterViewModel(authService: auth)
        viewModel.password = "short"
        viewModel.confirmPassword = "different"

        await viewModel.register()

        XCTAssertNotNil(viewModel.nameError)
        XCTAssertNotNil(viewModel.emailError)
        XCTAssertNotNil(viewModel.passwordError)
        XCTAssertNotNil(viewModel.confirmPasswordError)
        XCTAssertTrue(auth.registerCalls.isEmpty)
    }

    func testRegisterSuccessReportsUser() async {
        let auth = MockAuthService()
        var registeredUser: AppUser?
        let viewModel = RegisterViewModel(authService: auth) { registeredUser = $0 }
        viewModel.name = " Saikat "
        viewModel.email = "saikat@uni.edu"
        viewModel.password = "secret123"
        viewModel.confirmPassword = "secret123"

        await viewModel.register()

        XCTAssertEqual(auth.registerCalls.first?.name, "Saikat")
        XCTAssertEqual(registeredUser?.displayName, "Saikat")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRegisterShowsEmailInUseError() async {
        let auth = MockAuthService()
        auth.errorToThrow = NSError.auth(ErrorMessageMapper.AuthCode.emailAlreadyInUse)
        let viewModel = RegisterViewModel(authService: auth)
        viewModel.name = "Saikat"
        viewModel.email = "saikat@uni.edu"
        viewModel.password = "secret123"
        viewModel.confirmPassword = "secret123"

        await viewModel.register()

        XCTAssertTrue(viewModel.errorMessage?.contains("already exists") == true)
    }

    // MARK: Session

    func testSessionFollowsAuthState() {
        let auth = MockAuthService()
        let session = SessionViewModel(authService: auth)
        XCTAssertEqual(session.state, .loading)

        session.start()
        auth.emit(nil)
        XCTAssertEqual(session.state, .signedOut)

        let user = AppUser(id: "uid-1", email: "a@b.com", displayName: nil)
        auth.emit(user)
        XCTAssertEqual(session.state, .signedIn(user))

        let named = AppUser(id: "uid-1", email: "a@b.com", displayName: "Alice")
        session.userDidRegister(named)
        XCTAssertEqual(session.state, .signedIn(named))

        session.signOut()
        XCTAssertEqual(auth.signOutCallCount, 1)
    }

    func testSessionIgnoresProfileUpdateForDifferentUser() {
        let auth = MockAuthService()
        let session = SessionViewModel(authService: auth)
        session.start()
        let user = AppUser(id: "uid-1", email: "a@b.com", displayName: nil)
        auth.emit(user)

        session.userDidRegister(AppUser(id: "uid-2", email: "x@y.com", displayName: "X"))

        XCTAssertEqual(session.state, .signedIn(user))
    }
}
