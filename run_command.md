# Run Commands: Firebase Todo App (iOS)

How to build and run this project on a Mac. Everything needed is in the repository, including the Firebase configuration, so **no Firebase setup is required**.

**Requirements:** a Mac with **macOS 14.5+** and **Xcode 16.2 or newer** (Xcode 26 also works), plus an internet connection for the first build (Xcode downloads the Firebase SDK).

---

## 1. Install XcodeGen (one time)

The Xcode project is generated from `project.yml` by XcodeGen.

```bash
brew install xcodegen
```

No Homebrew? Use this instead:
```bash
mkdir -p ~/tools && cd ~/tools && curl -L -o xcodegen.zip https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip && unzip -o xcodegen.zip && export PATH="$HOME/tools/xcodegen/bin:$PATH" && cd -
```

## 2. Get the code

```bash
git clone https://github.com/ShahariarEmon112/Mobile_Comp_Todo-List.git
```
```bash
cd Mobile_Comp_Todo-List
```

## 3. Generate the Xcode project

```bash
xcodegen generate
```

## 4. Run the app

### Option A: Xcode (recommended)
```bash
open FirebaseTodoApp.xcodeproj
```
1. Wait for **Package Dependencies** (left sidebar) to finish downloading Firebase. This takes 2–5 minutes the first time.
2. At the top of the window, select scheme **FirebaseTodoApp** and any **iPhone simulator** (for example *iPhone 16*).
3. Press **⌘R** (Product → Run).

### Option B: Terminal only
Find a simulator name:
```bash
xcrun simctl list devices available | grep -i iphone
```
Build. Replace `iPhone 16` with a name from the list above:
```bash
xcodebuild -project FirebaseTodoApp.xcodeproj -scheme FirebaseTodoApp -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath build build
```
Start the simulator, install and launch the app:
```bash
xcrun simctl boot "iPhone 16"; open -a Simulator
```
```bash
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/FirebaseTodoApp.app
```
```bash
xcrun simctl launch booted com.saikat.firebasetodo
```

## 5. Run the unit tests (optional)

In Xcode press **⌘U**, or:
```bash
xcodebuild test -project FirebaseTodoApp.xcodeproj -scheme FirebaseTodoApp -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: `** TEST SUCCEEDED **` (39 tests).

---

## Using the app

1. On the Login screen tap **Create one**, then register with any email (it doesn't need to be real) and a password like `secret123`.
2. Tap **+** to add a task (title + description).
3. Tap the circle to mark it completed, and tap again to set it back to pending.
4. Tap a task to edit its title, description or status.
5. Swipe a task left → **Delete** (asks for confirmation).
6. Use the **All / Pending / Completed** filter and pull down to **search**.
7. Account icon (top left) → **Sign Out**. Sign in again and your tasks are still there.

Each account only sees its own tasks (stored in Cloud Firestore at `users/{uid}/tasks/{taskId}`).

---

## If something goes wrong

| Problem | Fix |
|---------|-----|
| `xcodegen: command not found` | Do step 1 |
| Errors mentioning Xcode / Swift version | Update Xcode to 16.2 or newer |
| `No such module 'FirebaseAuth'` | Wait for package download to finish, then build again |
| Package download fails | Xcode → File → Packages → **Reset Package Caches**, then build again |
| `Unable to find a destination matching…` | Use a simulator name from `xcrun simctl list devices available` |
| Signing error | Use a **simulator**, not a physical iPhone (no Apple developer team is needed for the simulator) |

More detail: [README.md](README.md) and [MAC_SETUP.md](MAC_SETUP.md).
