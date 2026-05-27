# Nexus Tracker

> A minimal, offline-first personal accountability tracker built with Flutter. Set ground rules, track daily progress, log writeups, and build streaks — no login, no cloud, 100% local. Works on every device.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5-0175C2?logo=dart&logoColor=white)

---

## Features

- **No login required** — opens straight to your dashboard
- **Ground Rules** — create daily / weekly / one-time habits
- **Checklist tracking** — tap to check off, earn XP
- **Streak counter** — never break the chain
- **Writeups** — log progress notes with tags
- **Activity feed** — see your recent actions
- **Analytics** — 60-day heatmap, stats, level progress
- **100% offline** — everything stored locally via embedded database
- **Reset Data** — start fresh anytime from the sidebar menu
- **Cross-platform** — Windows, Linux, macOS, Android, iOS, Web

---

## Screenshots

| Dashboard | Ground Rules | Writeups | Analytics |
|-----------|-------------|----------|-----------|
| Checklist + streaks | Create/manage rules | Notebook | Heatmap + stats |

---

## Table of Contents

1. [Quick Start (All Platforms)](#quick-start-all-platforms)
2. [Windows](#windows)
3. [Linux](#linux)
4. [macOS](#macos)
5. [Android](#android)
6. [iOS](#ios)
7. [Web](#web)
8. [Development](#development)
9. [Reset Your Data](#reset-your-data)
10. [Project Structure](#project-structure)
11. [Upload to GitHub](#upload-to-github)
12. [License](#license)

---

## Quick Start (All Platforms)

### Prerequisites (every OS)

- [Flutter SDK 3.24+](https://docs.flutter.dev/get-started/install) — install for your OS
- [Git](https://git-scm.com/)

Verify Flutter is installed:

```bash
flutter --version
flutter doctor
```

### Clone the repo

```bash
git clone https://github.com/cookiesn1ffer/nexus-tracker.git
cd nexus-tracker
flutter pub get
```

Now pick your platform below.

---

## Windows

### Install from GitHub Release

Download `Nexus Tracker Setup 1.0.0.exe` from [GitHub Releases](https://github.com/cookiesn1ffer/nexus-tracker/releases).

### Build from Source

#### Step 1: Enable Developer Mode

Windows needs Developer Mode so Flutter can create symlinks during the build.

1. Press `Win + I` → `Privacy & security` → `For developers`
2. Toggle **Developer Mode** to **On**
3. Restart your terminal

### Step 2: Install Visual Studio Build Tools

Download and install **Visual Studio 2022** with the **"Desktop development with C++"** workload:
https://visualstudio.microsoft.com/downloads/

### Step 3: Build

```bash
cd nexus-tracker

# Build release executable
flutter build windows --release
```

### Step 4: Run

```bash
# Run without installing
flutter run -d windows

# Or launch the built .exe directly
build/windows/x64/runner/Release/nexus_tracker.exe
```

### Step 5: Create an Installer (optional)

1. Download [Inno Setup](https://jrsoftware.org/isinfo.php)
2. Open `installer/setup.iss`
3. Click **Build**
4. The installer will be at:
   ```
   dist/Nexus Tracker Setup 1.0.0.exe
   ```

### Data Location

```
%APPDATA%\com.nexustracker.app\
```

---

## Linux

### Install from AUR (Arch Linux)

```bash
yay -S nexus-tracker
```

Then run:
```bash
nexus_tracker
```

### Install from GitHub Release

Download the latest release from [GitHub Releases](https://github.com/cookiesn1ffer/nexus-tracker/releases).

### Build from Source

#### Step 1: Install build dependencies

**Ubuntu / Debian:**
```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libblkid-dev liblzma-dev
```

**Fedora:**
```bash
sudo dnf install -y clang cmake ninja-build pkgconfig gtk3-devel libblkid-devel lzma-devel
```

**Arch:**
```bash
sudo pacman -S clang cmake ninja pkgconf gtk3 util-linux-libs
```

#### Step 2: Build

```bash
cd nexus-tracker

# Build release
flutter build linux --release
```

#### Step 3: Run

```bash
# Run directly
flutter run -d linux

# Or run the built binary
build/linux/x64/release/bundle/nexus_tracker
```

### Data Location

```
~/.local/share/com.nexustracker.app/
```

---

## macOS

### Step 1: Install Xcode Command Line Tools

```bash
xcode-select --install
```

### Step 2: Build

```bash
cd nexus-tracker

# Build release
flutter build macos --release
```

### Step 3: Run

```bash
# Run directly
flutter run -d macos

# Or open the built .app
open build/macos/Build/Products/Release/nexus_tracker.app
```

### Data Location

```
~/Library/Application Support/com.nexustracker.app/
```

---

## Android

### Step 1: Install Android Studio

Download and install [Android Studio](https://developer.android.com/studio).

Open Android Studio → SDK Manager → SDK Tools → check:
- Android SDK Command-line Tools (latest)
- Android SDK Build-Tools
- Android Emulator (optional)

### Step 2: Accept licenses

```bash
flutter doctor --android-licenses
```

Press `y` to accept all licenses.

### Step 3: Build APK

```bash
cd nexus-tracker

# Build release APK
flutter build apk --release
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Step 4: Install on device

```bash
# With a phone connected via USB (enable USB debugging first)
flutter run -d <your-device-id>

# Or install the APK manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Data Location

```
Android/data/com.nexustracker.app/files/
```

---

## iOS

**You need a Mac with Xcode to build for iOS.**

### Step 1: Install Xcode

Download from the Mac App Store or [Apple Developer](https://developer.apple.com/download/).

### Step 2: Install CocoaPods

```bash
sudo gem install cocoapods
```

### Step 3: Build

```bash
cd nexus-tracker

# Install iOS pods
cd ios && pod install && cd ..

# Build
flutter build ios --release
```

### Step 4: Run on device or simulator

```bash
# Run on connected iPhone
flutter run -d ios

# Or open in Xcode to sign and deploy
open ios/Runner.xcworkspace
```

### Data Location

```
~/Library/Containers/com.nexustracker.app/
```

---

## Web

### Step 1: Build

```bash
cd nexus-tracker

# Build for web
flutter build web --release
```

### Step 2: Serve locally or deploy

```bash
# Serve locally (requires a simple HTTP server)
cd build/web
python3 -m http.server 8080

# Now open http://localhost:8080 in your browser
```

Or deploy to any static hosting: GitHub Pages, Netlify, Vercel, Firebase Hosting, etc.

> **Note:** Web storage uses the browser's IndexedDB. Data is tied to the browser and domain. Different browsers won't share data.

---

## Development

```bash
# Run in debug mode with hot reload
flutter run

# Hot reload: press `r` in the terminal
# Hot restart: press `R`
# Quit: press `q`

# Check for issues
flutter analyze

# Format code
flutter format lib/
```

---

## Reset Your Data

You can reset all app data without touching files manually:

1. Click **Reset Data** in the desktop sidebar, or the **⋮ menu** on mobile
2. Confirm the dialog
3. All rules, checklists, writeups, and progress are wiped
4. The app restarts with a clean empty database

**To manually delete data:**

| OS | Path |
|---|---|
| Windows | `%APPDATA%\com.nexustracker.app\` |
| Linux | `~/.local/share/com.nexustracker.app/` |
| macOS | `~/Library/Application Support/com.nexustracker.app/` |
| Android | `Android/data/com.nexustracker.app/files/` |
| iOS | `~/Library/Containers/com.nexustracker.app/` |
| Web | Browser DevTools → Application → IndexedDB → Delete |

---

## Project Structure

```
nexus-tracker/
├── android/              # Android runner
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/com/nexustracker/app/MainActivity.kt
│   │       └── res/
│   └── build.gradle
├── ios/                  # iOS runner (generated on Mac)
├── linux/                # Linux runner
│   ├── CMakeLists.txt
│   ├── main.cc
│   ├── my_application.cc
│   └── my_application.h
├── macos/                # macOS runner
│   ├── CMakeLists.txt
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   └── MainFlutterWindow.swift
│   └── Flutter/
├── web/                  # Web runner
│   ├── index.html
│   └── manifest.json
├── windows/              # Windows runner
│   ├── CMakeLists.txt
│   └── runner/
│       └── resources/app_icon.ico
├── lib/                  # All Dart source code
│   ├── main.dart
│   ├── database/
│   │   └── db_helper.dart
│   ├── models/
│   │   └── models.dart
│   ├── providers/
│   │   └── app_state.dart
│   ├── screens/
│   │   ├── dashboard.dart
│   │   ├── rules_manager.dart
│   │   ├── writeups_board.dart
│   │   └── analytics.dart
│   └── widgets/
│       ├── layout.dart
│       └── progress_ring.dart
├── installer/
│   └── setup.iss         # Inno Setup script (Windows)
├── pubspec.yaml          # Dependencies
├── LICENSE
└── README.md
```

---

## Upload to GitHub

### Step 1: Initialize Git (if not already)

```bash
cd nexus-tracker

# Initialize git repo
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: Nexus Tracker Flutter app"
```

### Step 2: Create a GitHub repo

1. Go to [github.com/new](https://github.com/new)
2. Repository name: `nexus-tracker`
3. Description: `Personal accountability tracker built with Flutter`
4. Choose **Public** or **Private**
5. **Do NOT** initialize with README, .gitignore, or License (we already have those)
6. Click **Create repository**

### Step 3: Push your code

Copy the commands from the GitHub page, or run:

```bash
# Replace with your actual username
git remote add origin https://github.com/YOUR_USERNAME/nexus-tracker.git

# Push to main branch
git branch -M main
git push -u origin main
```

If you use SSH:

```bash
git remote add origin git@github.com:YOUR_USERNAME/nexus-tracker.git
git branch -M main
git push -u origin main
```

### Step 4: Add a release (optional)

After building:

1. On GitHub, go to **Releases** → **Create a new release**
2. Tag version: `v1.0.0`
3. Title: `Nexus Tracker 1.0.0`
4. Description: paste your release notes
5. Attach your built files:
   - `dist/Nexus Tracker Setup 1.0.0.exe` (Windows installer)
   - `build/app/outputs/flutter-apk/app-release.apk` (Android APK)
6. Click **Publish release**

---

## License

[MIT License](LICENSE)

---

## Troubleshooting

### `flutter` command not found

Add Flutter to your PATH:

**Windows:**
- `Win + I` → System → About → Advanced system settings
- Environment Variables → Path → Edit → New
- Add: `C:\dev\flutter\bin`

**Linux / macOS:**
Add to `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Windows build fails with "symlink support"

Developer Mode is not enabled. See [Windows section](#windows) Step 1.

### Android build fails with "license" error

Run:
```bash
flutter doctor --android-licenses
```

Accept all licenses.

### iOS build fails with CocoaPods

```bash
cd ios
pod install --repo-update
cd ..
flutter build ios
```

### Data not clearing after reinstall

Flutter stores data in the OS user data directory, not the app bundle. Delete the data folder for your OS from the [Reset Your Data](#reset-your-data) table.
