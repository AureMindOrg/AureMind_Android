# AureMind

A secure, offline notes and task management app built with Flutter.

AureMind keeps everything on-device: notes, tasks, and attachments are stored locally and encrypted, with no account or internet connection required.

## Features

- **Offline-first storage** – all data lives in a local SQLite database (`sqflite`), so the app works fully without a network connection.
- **Encryption** – sensitive note content is encrypted at rest (`encrypt`).
- **Task management with calendar view** – plan and review tasks using an interactive calendar (`table_calendar`).
- **Reminders & notifications** – schedule local notifications for tasks and deadlines (`flutter_local_notifications`, `timezone`).
- **Markdown notes** – write and render formatted notes (`flutter_markdown`).
- **PDF export** – export notes or tasks to PDF and print or share them directly (`pdf`, `printing`).
- **Attachments & sharing** – attach files to notes/tasks and share content with other apps (`file_picker`, `share_plus`).
- **Adaptive theming** – supports Material You dynamic color along with a custom color picker for personalized themes (`dynamic_color`, `flutter_colorpicker`).

## Platforms

This project currently targets android.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with a Dart SDK satisfying `^3.12.0`
- Android Studio / Xcode tooling for Android builds, or a Windows development setup (Visual Studio with the "Desktop development with C++" workload) for the Windows build

### Setup

```bash
# Clone the repository
git clone https://github.com/AureMindOrg/AureMind_Android.git
cd AureMind_Android

# Install dependencies
flutter pub get

# Run on a connected Android device/emulator
flutter run

# Or run the Windows desktop build
flutter run -d windows
```

### Building a release

```bash
# Android APK
flutter build apk --release

# Windows
flutter build windows --release
```

## Project Structure

```
.
├── android/        # Android platform project
├── windows/        # Windows desktop platform project
├── lib/            # Dart application source code
├── test/           # Unit/widget tests
├── assets/icon/    # App icon assets
└── pubspec.yaml    # Dependencies and project metadata
```

## Contributing

Contributions are welcome. Please open an issue to discuss any significant changes before submitting a pull request, and make sure `flutter analyze` and `flutter test` pass before opening one.

## License

No license has been published for this repository yet. Until one is added, all rights are reserved by the author.
