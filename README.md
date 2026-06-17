# AureMind Offline

A secure, offline-first notes and task management application built with Flutter. AureMind is designed for complete privacy, storing all your data locally on your device with military-grade AES encryption for your written thoughts.

##  Features

* **Encrypted Notes:** All note content is secured using AES encryption with uniquely generated Initialization Vectors (IV) stored safely in a local SQLite database.
* **Task Management:** Create, track, and complete tasks with due dates and custom local notifications (alarms).
* **Calendar Integration:** A dedicated calendar view to visualize your schedule and tap into specific days to see upcoming deadlines.
* **Local Attachments:** Add files to your notes without relying on cloud storage.
* **Multi-Select & Bulk Actions:** Long-press to select multiple notes or tasks for quick bulk deletion.
* **100% Offline:** Zero cloud dependency, zero trackers, and zero accounts required. Your data never leaves your phone.

##  Tech Stack

* **Framework:** Flutter (Dart)
* **Local Database:** `sqflite`
* **Security:** `encrypt` (AES Encryption)
* **Background Processes:** `flutter_local_notifications`, `timezone`
* **UI Components:** `table_calendar`, Material 3

##  Getting Started

### Prerequisites
* Flutter SDK (v3.0.0 or higher)
* Android Studio / Command-line Android SDK tools

### Building from Source
1. Clone the repository:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/auremind_offline.git](https://github.com/YOUR_USERNAME/auremind_offline.git)
   cd auremind_offline```

2. Install dependencies:
   ```bash
flutter pub get```


3. Build the Release APK (Windows):
   ```bash
flutter build apk --release```


4. The generated APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

##  Privacy & Permissions

This application requires permission to post notifications and set exact alarms to ensure task reminders trigger reliably. It does not request internet access, ensuring your data remains completely isolated and secure on your device.
