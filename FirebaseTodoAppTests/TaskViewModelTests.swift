import XCTest
@testable import FirebaseTodoApp

@MainActor
final class TaskListViewModelTests: XCTestCase {
    private let user = AppUser(id: "uid-1", email: "student@uni.edu", displayName: "Student")

    private func makeViewModel() -> (TaskListViewModel, MockTaskService) {
        let service = MockTaskService()
        return (TaskListViewModel(user: user, taskService: service), service)
    }

    func testListeningLoadsTasksNewestFirst() {
        let (viewModel, service) = makeViewModel()
        viewModel.startListening()
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(service.observedUserIDs, ["uid-1"])

        let older = TodoTask.fixture(id: "old", createdAt: Date(timeIntervalSince1970: 100))
        let newer = TodoTask.fixture(id: "new", createdAt: Date(timeIntervalSince1970: 200))
        service.emit(.success([older, newer]))

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.hasLoaded)
        XCTAssertEqual(viewModel.tasks.map(\.id), ["new", "old"])
    }

    func testStartListeningTwiceKeepsOneListener() {
        let (viewModel, service) = makeViewModel()
        viewModel.startListening()
        viewModel.startListening()
        XCTAssertEqual(service.observedUserIDs.count, 1)
    }

    func testStopListeningCancelsListener() {
        let (viewModel, service) = makeViewModel()
        viewModel.startListening()
        viewModel.stopListening()
        XCTAssertEqual(service.lastToken?.isCancelled, true)
    }

    func testListenerErrorShowsMessage() {
        let (viewModel, service) = makeViewModel()
        viewModel.startListening()
        service.emit(.failure(NSError.firestore(ErrorMessageMapper.FirestoreCode.permissionDenied)))
        XCTAssertEqual(viewModel.errorMessage, "You don't have permission to do that.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testCountsProgressFilterAndSearch() {
        let (viewModel, service) = makeViewModel()
        viewModel.startListening()
        service.emit(.success([
            .fixture(id: "1", title: "Buy milk", isCompleted: true),
            .fixture(id: "2", title: "Lab report", details: "Firestore rules"),
            .fixture(id: "3", title: "Gym", isCompleted: true),
            .fixture(id: "4", title: "Call mom"),
        ]))

        XCTAssertEqual(viewModel.completedCount, 2)
        XCTAssertEqual(viewModel.pendingCount, 2)
        XCTAssertEqual(viewModel.progress, 0.5, accuracy: 0.001)

        viewModel.filter = .completed
        XCTAssertEqual(Set(viewModel.visibleTasks.map(\.id)), ["1", "3"])

        viewModel.filter = .pending
        XCTAssertEqual(Set(viewModel.visibleTasks.map(\.id)), ["2", "4"])

        viewModel.filter = .all
        viewModel.searchText = "firestore"
        XCTAssertEqual(viewModel.visibleTasks.map(\.id), ["2"], "search matches the description too")
    }

    func testProgressIsZeroWithNoTasks() {
        let (viewModel, _) = makeViewModel()
        XCTAssertEqual(viewModel.progress, 0)
    }

    func testToggleCompletionFlipsStatus() async {
        let (viewModel, service) = makeViewModel()
        await viewModel.toggleCompletion(of: .fixture(id: "t1", isCompleted: false))
        await viewModel.toggleCompletion(of: .fixture(id: "t2", isCompleted: true))
        XCTAssertEqual(service.completionChanges.map(\.taskID), ["t1", "t2"])
        XCTAssertEqual(service.completionChanges.map(\.isCompleted), [true, false])
    }

    func testDeleteFlow() async {
        let (viewModel, service) = makeViewModel()
        let task = TodoTask.fixture(id: "t1")

        viewModel.requestDeletion(of: task)
        XCTAssertEqual(viewModel.taskPendingDeletion, task)

        await viewModel.delete(task)
        XCTAssertNil(viewModel.taskPendingDeletion)
        XCTAssertEqual(service.deletedTaskIDs, ["t1"])
    }

    func testDeleteFailureShowsMessage() async {
        let (viewModel, service) = makeViewModel()
        service.errorToThrow = NSError.firestore(ErrorMessageMapper.FirestoreCode.unavailable)
        await viewModel.delete(.fixture(id: "t1"))
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

@MainActor
final class TaskEditorViewModelTests: XCTestCase {
    func testCreateRequiresTitle() async {
        let service = MockTaskService()
        let viewModel = TaskEditorViewModel(mode: .create, userID: "uid-1", taskService: service)
        XCTAssertFalse(viewModel.canSave)

        viewModel.title = "   "
        let saved = await viewModel.save()

        XCTAssertFalse(saved)
        XCTAssertNotNil(viewModel.titleError)
        XCTAssertTrue(service.createdTasks.isEmpty)
    }

    func testCreateTrimsAndSaves() async {
        let service = MockTaskService()
        let viewModel = TaskEditorViewModel(mode: .create, userID: "uid-1", taskService: service)
        viewModel.title = "  Finish lab  "
        viewModel.details = " Add screenshots \n"
        XCTAssertTrue(viewModel.canSave)
        XCTAssertEqual(viewModel.navigationTitle, "New Task")

        let saved = await viewModel.save()

        XCTAssertTrue(saved)
        XCTAssertEqual(service.createdTasks.first?.userID, "uid-1")
        XCTAssertEqual(service.createdTasks.first?.title, "Finish lab")
        XCTAssertEqual(service.createdTasks.first?.details, "Add screenshots")
    }

    func testDescriptionLimitIsEnforced() async {
        let service = MockTaskService()
        let viewModel = TaskEditorViewModel(mode: .create, userID: "uid-1", taskService: service)
        viewModel.title = "Valid"
        viewModel.details = String(repeating: "a", count: InputValidator.maximumDescriptionLength + 1)

        let saved = await viewModel.save()

        XCTAssertFalse(saved)
        XCTAssertNotNil(viewModel.detailsError)
    }

    func testEditStartsWithTaskValuesAndTracksChanges() {
        let task = TodoTask.fixture(id: "t1", title: "Old", details: "Notes", isCompleted: false)
        let viewModel = TaskEditorViewModel(mode: .edit(task), userID: "uid-1", taskService: MockTaskService())

        XCTAssertEqual(viewModel.title, "Old")
        XCTAssertEqual(viewModel.details, "Notes")
        XCTAssertEqual(viewModel.navigationTitle, "Edit Task")
        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertFalse(viewModel.canSave)

        viewModel.isCompleted = true
        XCTAssertTrue(viewModel.hasChanges)
        XCTAssertTrue(viewModel.canSave)
    }

    func testEditSavesUpdatedTaskKeepingIdentity() async {
        let created = Date(timeIntervalSince1970: 1_000)
        let task = TodoTask.fixture(id: "t1", title: "Old", createdAt: created)
        let service = MockTaskService()
        let viewModel = TaskEditorViewModel(mode: .edit(task), userID: "uid-1", taskService: service)
        viewModel.title = "New title"
        viewModel.isCompleted = true

        let saved = await viewModel.save()

        XCTAssertTrue(saved)
        let updated = try? XCTUnwrap(service.updatedTasks.first)
        XCTAssertEqual(updated?.id, "t1")
        XCTAssertEqual(updated?.title, "New title")
        XCTAssertEqual(updated?.isCompleted, true)
        XCTAssertEqual(updated?.createdAt, created)
    }

    func testSaveFailureKeepsScreenOpenWithMessage() async {
        let service = MockTaskService()
        service.errorToThrow = NSError.firestore(ErrorMessageMapper.FirestoreCode.permissionDenied)
        let viewModel = TaskEditorViewModel(mode: .create, userID: "uid-1", taskService: service)
        viewModel.title = "Task"

        let saved = await viewModel.save()

        XCTAssertFalse(saved)
        XCTAssertEqual(viewModel.errorMessage, "You don't have permission to do that.")
        XCTAssertFalse(viewModel.isSaving)
    }

    func testDeleteFromEditor() async {
        let service = MockTaskService()
        let viewModel = TaskEditorViewModel(mode: .edit(.fixture(id: "t9")), userID: "uid-1", taskService: service)

        let deleted = await viewModel.delete()

        XCTAssertTrue(deleted)
        XCTAssertEqual(service.deletedTaskIDs, ["t9"])
    }

    func testDeleteIsUnavailableWhenCreating() async {
        let service = MockTaskService()
        let viewModel = TaskEditorViewModel(mode: .create, userID: "uid-1", taskService: service)
        let deleted = await viewModel.delete()
        XCTAssertFalse(deleted)
        XCTAssertTrue(service.deletedTaskIDs.isEmpty)
    }
}
