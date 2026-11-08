# Mac Setup Guide (friend's Mac or university lab Mac)

Exact steps to build and run the Firebase Todo App on a Mac. It takes about **20–40 minutes** the first time, mostly downloads.
Copy each command into **Terminal** (Applications → Utilities → Terminal).

---

## 0. Check what's already installed

```bash
sw_vers -productVersion
```
```bash
xcodebuild -version
```
```bash
which brew xcodegen git
```
- macOS should be **14.5 or newer**.
- Xcode should be **16.2 or newer**. If it's older or missing, do step 1.
- If `xcodegen` is missing, do steps 2–3.

## 1. Install Xcode (skip if 16.2+ is installed)

1. Open the **App Store**, search **Xcode**, click **Get/Install** (about 10 GB).
2. Open Xcode once, accept the license, and let it install the extra components.
   When it asks which platforms to download, make sure **iOS** is ticked.
3. Point the command-line tools at it:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
   ```bash
   sudo xcodebuild -license accept
   ```

> **Lab Mac without admin rights?** Skip the `sudo` commands. Xcode is usually already set up. If you can't install Homebrew, use the [no-Homebrew option](#no-homebrew-option-for-xcodegen) below.

## 2. Install Homebrew (skip if `which brew` printed a path)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
At the end, run the two `echo ... >> ~/.zprofile` / `eval ...` lines it prints under "Next steps", then check:
```bash
brew --version
```

## 3. Install XcodeGen

```bash
brew install xcodegen
```
```bash
xcodegen --version
```

### No-Homebrew option for XcodeGen
```bash
mkdir -p ~/tools && cd ~/tools
curl -L -o xcodegen.zip https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip
unzip -o xcodegen.zip
export PATH="$HOME/tools/xcodegen/bin:$PATH"
xcodegen --version
```

## 4. Clone the repository

The repository is **private**, so sign in to GitHub first. The easiest way is the GitHub CLI:
```bash
brew install gh
```
```bash
gh auth login
```
(Choose GitHub.com → HTTPS → Login with a web browser.) Then:
```bash
cd ~/Desktop
gh repo clone ShahariarEmon112/Firebase-Todo-App
cd Firebase-Todo-App
```
*Without `gh`:* `git clone https://github.com/ShahariarEmon112/Firebase-Todo-App.git`. When asked for a password, use a GitHub **personal access token**, not your account password.

## 5. Add GoogleService-Info.plist (required)

The Firebase config file is **not in the repository** for security reasons. Get it like this:

1. On the Mac, open <https://console.firebase.google.com> and sign in with the Google account that owns the project.
2. Open project **fir-todo-app-489dc** → gear icon → **Project settings**.
3. Scroll to **Your apps** → select the iOS app **com.saikat.firebasetodo**.
4. Click **GoogleService-Info.plist** to download it.
5. Move it into the project (run from inside `Firebase-Todo-App`):
   ```bash
   cp ~/Downloads/GoogleService-Info.plist FirebaseTodoApp/Resources/GoogleService-Info.plist
   ```
   If the browser saved it as `GoogleService-Info (1).plist`, use that name on the left side of the command.
6. Check it's there:
   ```bash
   ls -l FirebaseTodoApp/Resources/GoogleService-Info.plist
   ```
   ```bash
   /usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" FirebaseTodoApp/Resources/GoogleService-Info.plist
   ```
   The second command must print `com.saikat.firebasetodo`.

> Alternative: copy the file from your own computer with a USB drive, AirDrop or email. It is the same file as `~/Downloads/GoogleService-Info.plist` on your Ubuntu machine.
> **Don't commit it** (`.gitignore` already blocks it), and delete it from the lab Mac when you're done (step 10).

## 6. Generate the Xcode project

```bash
xcodegen generate
```
You should see `Created project at .../FirebaseTodoApp.xcodeproj`.

## 7. Resolve the Firebase packages

```bash
xcodebuild -resolvePackageDependencies -project FirebaseTodoApp.xcodeproj -scheme FirebaseTodoApp
```
This downloads the Firebase iOS SDK (a few minutes the first time). It should end with `resolved source packages: ...` and list `Firebase`.

## 8. Build and run

### Option A: in Xcode (recommended for the demo)
```bash
open FirebaseTodoApp.xcodeproj
```
1. In the toolbar, choose scheme **FirebaseTodoApp** and a simulator such as **iPhone 16**.
2. Press **⌘R** (Product → Run). The simulator starts and the app opens on the Login screen.

### Option B: from Terminal
List the available simulators:
```bash
xcrun simctl list devices available | grep -i iphone
```
Build (replace `iPhone 16` with a name from the list):
```bash
xcodebuild -project FirebaseTodoApp.xcodeproj -scheme FirebaseTodoApp -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Run the unit tests
In Xcode press **⌘U**, or:
```bash
xcodebuild test -project FirebaseTodoApp.xcodeproj -scheme FirebaseTodoApp -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: `** TEST SUCCEEDED **` (39 tests).

### Running on a real iPhone (optional)
1. Connect the iPhone and trust the computer.
2. Xcode → select the **FirebaseTodoApp** target → **Signing & Capabilities** → **Team** → add/select your Apple ID.
3. Select the iPhone as the run destination → **⌘R**.
4. On the iPhone: Settings → General → VPN & Device Management → trust your developer certificate.

## 9. One-time Firebase Console checks

Do these once per Firebase project, from any computer:
- **Authentication → Sign-in method → Email/Password → Enabled**
- **Firestore Database** exists (production mode)
- **Firestore Database → Rules** contains the contents of `Firestore/firestore.rules` → **Publish**

## 10. Clean up the lab Mac afterwards

```bash
rm FirebaseTodoApp/Resources/GoogleService-Info.plist
```
```bash
gh auth logout
```
You can also delete the cloned folder.

---

## Quick reference (all commands in order)

```bash
brew install xcodegen gh
gh auth login
cd ~/Desktop && gh repo clone ShahariarEmon112/Firebase-Todo-App && cd Firebase-Todo-App
cp ~/Downloads/GoogleService-Info.plist FirebaseTodoApp/Resources/GoogleService-Info.plist
xcodegen generate
xcodebuild -resolvePackageDependencies -project FirebaseTodoApp.xcodeproj -scheme FirebaseTodoApp
open FirebaseTodoApp.xcodeproj
```

## Common problems

| Message | Fix |
|---------|-----|
| `GoogleService-Info.plist is missing` (build error) | Step 5, then `xcodegen generate` again |
| `xcodegen: command not found` | Step 3 (or the no-Homebrew option) |
| `requires Xcode 16.2` / Swift version errors | Update Xcode (step 1) |
| Package resolution fails | Xcode → File → Packages → **Reset Package Caches**, then resolve again |
| `Unable to find a destination matching...` | Use a simulator name from `xcrun simctl list devices available` |
| App says *Email sign-in is not enabled* | Step 9 |
| App says *You don't have permission to do that* | Publish the Firestore rules (step 9) |
