# Firebase Todo App (iOS · SwiftUI · Firebase)

A todo list app for iOS built with **SwiftUI**, **Firebase Authentication**, and **Cloud Firestore**, using the **MVVM** architecture.
Each user signs up with email and password, and their tasks sync in real time and stay private to their account.

> Mobile Computing Lab assignment: Firebase Integrated Todo List App
> Bundle ID: `com.saikat.firebasetodo` · Minimum iOS: **17.0**

---

## Contents

1. [Features](#features)
2. [Technologies](#technologies)
3. [Architecture](#architecture)
4. [Project structure](#project-structure)
5. [Firebase setup](#firebase-setup)
6. [Firestore security rules](#firestore-security-rules)
7. [GoogleService-Info.plist](#googleservice-infoplist)
8. [Requirements](#requirements)
9. [Generate the Xcode project (XcodeGen)](#generate-the-xcode-project-xcodegen)
10. [Resolve Firebase packages](#resolve-firebase-packages)
11. [Run the app](#run-the-app)
12. [How to test every feature](#how-to-test-every-feature)
13. [Automated tests](#automated-tests)
14. [Troubleshooting](#troubleshooting)

**Just want to run it?** See **[run_command.md](run_command.md)**: clone, `xcodegen generate`, open in Xcode, ⌘R. No Firebase setup needed.
For a full step-by-step Mac guide, see **[MAC_SETUP.md](MAC_SETUP.md)**.

---

## Features

**Authentication (Firebase Authentication)**
- Register with name, email and password (with a confirmation field)
- Sign in with email and password
- Sign out (with a confirmation dialog)
- Stay signed in between launches (Firebase keeps the session in the Keychain)
- "Forgot password?" sends a reset email
- Validation next to each field (email format, password strength, matching passwords)
- Friendly Firebase error messages (wrong password, email already in use, no network, …)
- Loading spinners on buttons while requests run

**Tasks (Cloud Firestore, full CRUD)**
- **Create**: add a task with a title and an optional description
- **Read**: a live list of the signed-in user's tasks that updates in real time
- **Update**: edit the title and description, and mark tasks completed or pending
- **Delete**: swipe, long-press menu, or the Edit screen, always with a confirmation dialog
- Each task stores an **ID, title, description, completion status and creation date** (plus last-updated date)
- Completed / pending indicators (checkbox, strikethrough, and a status badge with icon and text)
- Progress summary: "3 of 5 tasks completed" with a progress bar
- Filter by All / Pending / Completed, and search by title or description
- Empty states for "no tasks yet", "no results" and filtered views
- Unsaved-changes protection when closing the editor

**Design**
- Clean, minimal iOS design with SF Symbols and a teal accent color
- Full **light and dark mode** support (system colors + asset catalog colors with dark variants)
- Works with Dynamic Type, VoiceOver labels, and 44 pt minimum touch targets
- Works on iPhone and iPad, in portrait and landscape

---

## Technologies

| Area | Technology |
|------|------------|
| Language | Swift 5 language mode (Xcode 16.2+) |
| UI | SwiftUI (iOS 17 `@Observable`, `ContentUnavailableView`, `NavigationStack`) |
| Auth | Firebase Authentication (email/password) |
| Database | Cloud Firestore (real-time snapshot listeners) |
| Architecture | MVVM with protocol-based services |
| Dependencies | Swift Package Manager: `firebase-ios-sdk` 12.x (`FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`) |
| Project generation | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) |
| Tests | XCTest (unit tests) · Firebase Emulator + `@firebase/rules-unit-testing` (security rules) |

No other third-party libraries are used.

---

## Architecture

```
 ┌──────────────┐   observes   ┌──────────────────┐   calls   ┌───────────────────────┐
 │ SwiftUI View │ ───────────▶ │    ViewModel     │ ────────▶ │ Service (protocol)    │
 │  (Views/)    │ ◀─────────── │  (@Observable,   │ ◀──────── │  FirebaseAuthService  │──▶ Firebase Auth
 └──────────────┘   state      │   @MainActor)    │  results  │  FirestoreTaskService │──▶ Cloud Firestore
                               └──────────────────┘           └───────────────────────┘
```

- **Models** (`TodoTask`, `AppUser`, `TaskFilter`): plain Swift structs with no Firebase imports.
- **Services**: `AuthServicing` and `TaskServicing` protocols. The Firebase classes implement them, so view models never import Firebase. Unit tests swap in mock services.
- **ViewModels**: hold screen state, validate input, call services with `async/await`, and turn errors into friendly messages. All are `@MainActor`, so UI state only changes on the main thread.
- **Views**: SwiftUI screens built from small reusable components (`PrimaryButton`, `LabeledFormField`, `PasswordField`, `TaskCardView`, `StatusBadge`, `TaskSummaryCard`, `ErrorBanner`).
- **Navigation**: `RootView` watches `SessionViewModel.state` (`loading → signedOut → signedIn`). Firebase's auth listener drives it, so login, registration, sign-out and restored sessions all switch screens automatically.

### Data flow example: completing a task
1. The user taps the circle on a `TaskCardView`.
2. `TaskListViewModel.toggleCompletion(of:)` calls `TaskServicing.setCompletion(...)`.
3. `FirestoreTaskService` runs `updateData(["isCompleted": true, "updatedAt": serverTimestamp()])`.
4. Firestore's snapshot listener fires straight away (latency compensation), the view model gets the new list, and SwiftUI redraws.

---

## Project structure

```
Mobile_Comp_Todo-List/
├── project.yml                     # XcodeGen spec (generates FirebaseTodoApp.xcodeproj)
├── firebase.json / .firebaserc     # Firebase CLI config (rules deploy + emulator)
├── README.md
├── MAC_SETUP.md                    # Step-by-step guide for a Mac
├── run_command.md                  # Quick run commands
├── .gitignore                      # Keeps secrets and stray config copies out of git
├── FirebaseTodoApp/
│   ├── App/
│   │   ├── FirebaseTodoApp.swift   # @main entry; configures Firebase
│   │   └── RootView.swift          # Splash / Auth / Dashboard switch
│   ├── Models/
│   │   ├── TodoTask.swift          # Task model + Firestore field names
│   │   ├── AppUser.swift
│   │   └── TaskFilter.swift
│   ├── Services/
│   │   ├── ServiceProtocols.swift  # AuthServicing, TaskServicing, AppServices
│   │   ├── FirebaseBootstrap.swift # Safe FirebaseApp.configure()
│   │   ├── FirebaseAuthService.swift
│   │   └── FirestoreTaskService.swift
│   ├── ViewModels/
│   │   ├── SessionViewModel.swift
│   │   ├── LoginViewModel.swift
│   │   ├── RegisterViewModel.swift
│   │   ├── TaskListViewModel.swift
│   │   └── TaskEditorViewModel.swift
│   ├── Views/
│   │   ├── Auth/                   # LoginView, RegisterView, AuthFlowView, AuthHeaderView
│   │   ├── Tasks/                  # TaskListView (dashboard), AddTaskView, EditTaskView, TaskEditorView
│   │   ├── Components/             # Reusable UI pieces
│   │   ├── SplashView.swift
│   │   └── MissingConfigurationView.swift
│   ├── Utilities/
│   │   ├── InputValidator.swift
│   │   ├── ErrorMessageMapper.swift
│   │   ├── Theme.swift             # Colors, spacing, radii
│   │   └── View+Alerts.swift
│   └── Resources/
│       ├── Assets.xcassets         # AppIcon, AccentColor, status colors (light + dark)
│       └── GoogleService-Info.plist   # Firebase client config (included)
├── FirebaseTodoAppTests/           # XCTest unit tests + test-only mocks
├── Firestore/
│   ├── firestore.rules             # Security rules
│   ├── firestore.indexes.json
│   └── rules-tests/                # Emulator tests for the rules (Node.js)
└── scripts/
    └── linux-check.sh              # Syntax check + unit tests on Linux via Docker
```

> The structure in the assignment brief was kept, with two changes: unit tests live in `FirebaseTodoAppTests/` (the name Xcode expects for a test target), and `project.yml`, the docs and the Firebase config sit at the repository root, next to the app folder.

---

## Firebase setup

These steps are done once, in the [Firebase Console](https://console.firebase.google.com). The project used here is **`fir-todo-app-489dc`**.

### 1. Register the iOS app
1. Open the project → **Project settings** (gear icon) → **Your apps** → **Add app** → **iOS**.
2. **Apple bundle ID:** `com.saikat.firebasetodo` (must match exactly).
3. Download **GoogleService-Info.plist** (see [below](#googleservice-infoplist)).
4. Skip the "Add Firebase SDK" and "Add initialization code" steps. This project already does both.

### 2. Enable Email/Password sign-in
1. **Build → Authentication → Get started**.
2. **Sign-in method** tab → **Email/Password** → turn on **Enable** → **Save**.
   (Leave "Email link (passwordless sign-in)" off.)

### 3. Create the Firestore database
1. **Build → Firestore Database → Create database**.
2. Choose a location near you (for example `asia-south1`). This can't be changed later.
3. Start in **production mode**. Then publish this project's rules (next section).

### Firestore data structure
```
users (collection)
└── {uid} (document: the Firebase Auth user ID)
    └── tasks (sub-collection)
        └── {taskId} (document)
            ├── id:          string     same as the document ID
            ├── ownerId:     string     same as {uid}
            ├── title:       string     1–120 characters
            ├── description: string     0–1000 characters
            ├── isCompleted: bool
            ├── createdAt:   timestamp  set by the server
            └── updatedAt:   timestamp  set by the server on every edit
```
Tasks are ordered by `createdAt` (newest first). A single-field index is enough, so no composite index is needed.

---

## Firestore security rules

The rules are in [`Firestore/firestore.rules`](Firestore/firestore.rules). In short:

- **Only the signed-in owner** (`request.auth.uid == uid`) can read, create, update or delete documents in `users/{uid}/tasks`.
- Everything else is **denied**, including signed-out access, other users' data, `users/{uid}` profile documents and other collections.
- **Create** must include exactly the allowed fields. `id` must equal the document ID, `ownerId` must equal the user, `title` must be 1–120 characters and not blank, `description` up to 1000 characters, `isCompleted` a boolean, and `createdAt` the server time.
- **Update** may only change `title`, `description`, `isCompleted` and `updatedAt`. It can never change `id`, `ownerId` or `createdAt`, and must set `updatedAt` to the server time.

### Publish the rules
**Option A: Console (easiest):** Firestore Database → **Rules** tab → replace everything with the contents of `Firestore/firestore.rules` → **Publish**.

**Option B: Firebase CLI** (works on Linux or Mac):
```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules --project fir-todo-app-489dc
```

### Testing the security rules
The rules have **25 automated tests** that run against the local Firestore emulator. They need Node.js 20+ and Java 21+, and work on Ubuntu:
```bash
cd Firestore/rules-tests
npm install
npm test
```

---

## GoogleService-Info.plist

This file connects the app to the Firebase project `fir-todo-app-489dc`. **It is included in the repository** at `FirebaseTodoApp/Resources/GoogleService-Info.plist`, so the app builds and runs right after cloning, with no Firebase setup.

It contains client identifiers (project ID, app ID, API key), not passwords. Firebase is designed for these to ship inside the app. Data is protected by Firebase Authentication and the Firestore security rules, which only let each signed-in user access their own tasks.

To point the app at a **different** Firebase project instead:
1. Firebase Console → **Project settings** → **Your apps** → add an iOS app with bundle ID `com.saikat.firebasetodo`.
2. Download its **GoogleService-Info.plist** and replace the file above (keep that exact name).
3. Enable Email/Password sign-in, create Firestore, publish `Firestore/firestore.rules`, then run `xcodegen generate`.

`project.yml` lists the file as a bundled resource, and a build step **stops the build with a clear error** if it is missing. If the app somehow runs without it, it shows a "Firebase isn't configured" screen instead of crashing.

---

## Requirements

- A Mac running **macOS 14.5 or newer**
- **Xcode 16.2 or newer** (required by Firebase iOS SDK 12). Install it from the Mac App Store.
- **XcodeGen** (`brew install xcodegen`)
- An internet connection (to download the Firebase packages the first time)
- An iOS 17+ Simulator (included with Xcode). A physical iPhone also works with a free Apple ID for signing.

---

## Generate the Xcode project (XcodeGen)

The `.xcodeproj` is **generated** from `project.yml` and is not stored in git.
```bash
cd Mobile_Comp_Todo-List
xcodegen generate
open FirebaseTodoApp.xcodeproj
```
Run `xcodegen generate` again whenever you add or remove files.

## Resolve Firebase packages

Xcode downloads the Firebase SDK automatically when the project opens (watch the progress in the left sidebar under **Package Dependencies**). To do it manually:
- In Xcode: **File → Packages → Resolve Package Versions**, or
- From Terminal:
  ```bash
  xcodebuild -resolvePackageDependencies -project FirebaseTodoApp.xcodeproj -scheme FirebaseTodoApp
  ```
The first download takes a few minutes.

## Run the app

1. Select the **FirebaseTodoApp** scheme and an iPhone simulator (for example *iPhone 16*) in the Xcode toolbar.
2. Press **⌘R**.

Running on a real iPhone: select the **FirebaseTodoApp** target → **Signing & Capabilities** → choose your **Team** (a free Apple ID works). If the bundle ID is taken by another team, Xcode asks you to change it. In that case also register the new bundle ID in Firebase and download a new plist.

---

## How to test every feature

| # | Feature | Steps | Expected result |
|---|---------|-------|-----------------|
| 1 | Validation | On Login, tap **Sign In** with empty fields | Red messages under Email and Password; no network call |
| 2 | Register | **Create one** → fill name, email, password `secret123` ×2 → **Create Account** | Dashboard opens with "Hello, *name*"; user appears in Firebase Console → Authentication → Users |
| 3 | Duplicate email | Sign out, register again with the same email | "An account with this email already exists…" |
| 4 | Login error | Sign in with a wrong password | "Incorrect email or password." |
| 5 | Login | Sign in with the correct password | Dashboard opens |
| 6 | Persistent login | Stop the app (⌘.) and run it again | Goes straight to the dashboard |
| 7 | Empty state | New account | "No tasks yet" with an **Add Task** button |
| 8 | **Create** | Tap **+** → title + description → **Add** | Task appears at the top; Firestore Console shows `users/{uid}/tasks/{id}` with all fields |
| 9 | **Read (real-time)** | Edit the task's `title` in the Firestore Console | The app updates within a second, without refreshing |
| 10 | **Update status** | Tap the circle on a task | Checkmark + strikethrough + "Completed" badge; progress bar moves; `isCompleted: true` in Firestore |
| 11 | **Update text** | Tap a task → change title/description → **Save** | Card shows the new text; "Last updated" appears in the editor |
| 12 | **Delete** | Swipe left → **Delete** → confirm (or Edit → **Delete Task**) | Task disappears from the app and from Firestore |
| 13 | Filter & search | Use All / Pending / Completed, then pull down to search | List filters correctly |
| 14 | Data isolation | Register a second account | It sees none of the first account's tasks |
| 15 | Dark mode | Simulator: **Features → Toggle Appearance** (⇧⌘A) | All screens adapt and stay readable |
| 16 | Sign out | Account icon (top left) → **Sign Out** → confirm | Back to Login |
| 17 | Offline error | Turn off the Mac's Wi-Fi, then try to sign in | Friendly network error message |

---

## Automated tests

| Suite | What it covers | How to run |
|-------|----------------|-----------|
| **Unit tests** (`FirebaseTodoAppTests`, 39 tests) | Validation, error messages, filters, and the Login, Register, Session, Task List and Task Editor view models (with mock services, no network) | Xcode: **⌘U**, or `xcodebuild test` (see MAC_SETUP.md). On Linux: `./scripts/linux-check.sh` |
| **Security rules** (25 tests) | Owner-only access, field validation, immutable fields, server timestamps | `cd Firestore/rules-tests && npm install && npm test` |

`scripts/linux-check.sh` uses Docker with the official `swift` image. It parses every Swift file and runs all unit tests on Linux, so you can check logic changes without a Mac. SwiftUI views and the Firebase services can only be compiled on macOS.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Build error: *GoogleService-Info.plist is missing* | Download it ([steps](#googleservice-infoplist)) into `FirebaseTodoApp/Resources/`, then run `xcodegen generate` |
| App shows *Firebase isn't configured* | Same as above, then **Product → Clean Build Folder** (⇧⌘K) and run again |
| *Email sign-in is not enabled* | Enable Email/Password in Firebase Console → Authentication → Sign-in method |
| *You don't have permission to do that* | Publish `Firestore/firestore.rules` and make sure the Firestore database exists |
| Package resolution fails or hangs | **File → Packages → Reset Package Caches**, check your internet, try again |
| *No such module 'FirebaseAuth'* | Wait for packages to finish resolving, then build again |
| Signing error on a real device | Pick your Team under Signing & Capabilities |
| `xcodegen: command not found` | `brew install xcodegen` (see MAC_SETUP.md) |
