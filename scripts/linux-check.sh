#!/usr/bin/env bash
# Checks the Swift code on Linux (no Mac needed) using the official Swift Docker image.
#
# 1. Parses EVERY Swift file in the app and tests (syntax check only; SwiftUI
#    and Firebase cannot be type-checked on Linux).
# 2. Compiles the Firebase-independent code (models, utilities, view models,
#    service protocols) and runs the unit tests against it.
#
# Usage:  ./scripts/linux-check.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${SWIFT_IMAGE:-swift:6.1-jammy}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PKG="$WORK/pkg"
mkdir -p "$PKG/Sources/FirebaseTodoApp" "$PKG/Tests/FirebaseTodoAppTests"

# Firebase-independent app sources.
cp "$ROOT"/FirebaseTodoApp/Models/*.swift "$PKG/Sources/FirebaseTodoApp/"
cp "$ROOT"/FirebaseTodoApp/ViewModels/*.swift "$PKG/Sources/FirebaseTodoApp/"
cp "$ROOT"/FirebaseTodoApp/Services/ServiceProtocols.swift "$PKG/Sources/FirebaseTodoApp/"
cp "$ROOT"/FirebaseTodoApp/Utilities/InputValidator.swift "$PKG/Sources/FirebaseTodoApp/"
cp "$ROOT"/FirebaseTodoApp/Utilities/ErrorMessageMapper.swift "$PKG/Sources/FirebaseTodoApp/"

# Linux-only placeholders for the Firebase-backed services referenced by AppServices.
cat > "$PKG/Sources/FirebaseTodoApp/LinuxFirebaseStandIns.swift" <<'SWIFT'
import Foundation
// Placeholders so ServiceProtocols.swift compiles without the Firebase SDK. Never called in tests.
final class FirebaseAuthService: AuthServicing {
    var currentUser: AppUser? { nil }
    func observeAuthState(_ handler: @escaping @MainActor (AppUser?) -> Void) -> ObservationToken { fatalError("Firebase unavailable on Linux") }
    func signIn(email: String, password: String) async throws -> AppUser { fatalError("Firebase unavailable on Linux") }
    func register(name: String, email: String, password: String) async throws -> AppUser { fatalError("Firebase unavailable on Linux") }
    func sendPasswordReset(to email: String) async throws { fatalError("Firebase unavailable on Linux") }
    func signOut() throws { fatalError("Firebase unavailable on Linux") }
}
final class FirestoreTaskService: TaskServicing {
    func observeTasks(userID: String, onChange: @escaping @MainActor (Result<[TodoTask], Error>) -> Void) -> ObservationToken { fatalError("Firebase unavailable on Linux") }
    func createTask(userID: String, title: String, details: String) async throws { fatalError("Firebase unavailable on Linux") }
    func updateTask(userID: String, task: TodoTask) async throws { fatalError("Firebase unavailable on Linux") }
    func setCompletion(userID: String, taskID: String, isCompleted: Bool) async throws { fatalError("Firebase unavailable on Linux") }
    func deleteTask(userID: String, taskID: String) async throws { fatalError("Firebase unavailable on Linux") }
}
SWIFT

cp -R "$ROOT"/FirebaseTodoAppTests/. "$PKG/Tests/FirebaseTodoAppTests/"

cat > "$PKG/Package.swift" <<'SWIFT'
// swift-tools-version:5.10
import PackageDescription
let package = Package(
    name: "FirebaseTodoApp",
    targets: [
        .target(name: "FirebaseTodoApp", swiftSettings: [.unsafeFlags(["-swift-version", "5"])]),
        .testTarget(name: "FirebaseTodoAppTests", dependencies: ["FirebaseTodoApp"],
                    swiftSettings: [.unsafeFlags(["-swift-version", "5"])]),
    ]
)
SWIFT

echo "==> Parsing all Swift files (syntax check)"
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$ROOT":/src:ro "$IMAGE" bash -c '
  set -e
  files=$(find /src/FirebaseTodoApp /src/FirebaseTodoAppTests -name "*.swift" | sort)
  for f in $files; do swiftc -parse "$f" || { echo "PARSE FAILED: $f"; exit 1; }; done
  echo "Parsed $(echo "$files" | wc -l) files OK"
'

echo "==> Building Firebase-independent code and running unit tests"
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$PKG":/pkg -w /pkg "$IMAGE" swift test 2>&1
