# Firebase setup for this project

This project includes a Firestore-backed Library Book Manager app (`lib/main.dart`).
To run it locally you must register your app with Firebase and add the platform config files.

Android (required files and steps):
1. Go to https://console.firebase.google.com and create a project (or open an existing one).
2. Click Add app → Android.
3. Enter your Android package name (check `android/app/src/main/AndroidManifest.xml` for `package="..."`).
4. Download the generated `google-services.json` and place it at `android/app/google-services.json`.

Gradle Setup (usually automatic via Firebase console instructions):
- In `android/build.gradle.kts` ensure you have the Google services classpath in buildscript dependencies:

  buildscript {
    repositories {
      google()
      mavenCentral()
    }
    dependencies {
      classpath("com.google.gms:google-services:4.4.1")
    }
  }

- In `android/app/build.gradle.kts` apply the plugin near the top of the file:

  plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
  }

- Add the Firebase BOM in `dependencies` if needed:

  dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
  }

Dart/Flutter dependencies:
- This project already has `firebase_core` and `cloud_firestore` entries in `pubspec.yaml`.
- Run:

```bash
# cmd.exe (Windows)
cd "c:\Users\shanu.Nustartz\Desktop\Flutter\flutter1"
flutter pub get
```

Running the app:
- Make sure an Android emulator is authorized (run `adb devices` and confirm `device` not `unauthorized`).
- Run:

```bash
flutter run
```

Notes:
- If you only test on Android, `google-services.json` is sufficient for initial testing.
- For iOS/macOS/web you must follow the platform-specific steps in the Firebase console and add the corresponding config files.
- If Firebase initialization fails at runtime, the app will show an instruction message telling you to add the platform config file.

If you want, I can also patch Gradle files for you once you confirm the exact Android Gradle plugin setup in your repo.
