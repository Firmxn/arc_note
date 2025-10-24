# Project Requirements Document (PRD)

## 1. Project Overview

arc_note is a minimal Flutter application scaffolded to run on Android, iOS, and Windows from a single Dart codebase. In its first version, it implements a basic counter: every time the user taps the floating action button, the on-screen number increases by one. While simple, this example demonstrates Flutter’s core concepts—widget-based UI, state management with `setState()`, theming, and cross-platform embedding.

This project exists to serve as a learning tool and a starting point for more complex multi-platform apps. The key objectives are:

• Build and verify a working Flutter app on Android, iOS, and Windows.  
• Illustrate how native entry points (Kotlin, Swift, C++) integrate the Flutter engine.  
• Provide a clear template for UI composition, basic state handling, and theming.  
• Ensure developers can clone, run, and explore platform-specific code without hurdles.

## 2. In-Scope vs. Out-of-Scope

### In-Scope (Version 1.0)

• **Flutter Core App**: Single screen with an AppBar, counter display, and floating action button.  
• **Basic State Management**: StatefulWidget + `setState()` for counter updates.  
• **Material Theming**: Light theme via `ThemeData` in `lib/main.dart`.  
• **Platform Integration**:
  – Android: `MainActivity.kt`, Gradle build config, `AndroidManifest.xml`.  
  – iOS: `AppDelegate.swift`, Xcode project, `Info.plist`.  
  – Windows: `main.cpp`, `flutter_window.cpp`, `win32_window.cpp`, CMakeLists.  
• **Dark Mode Demo on Windows**: Registry-based theme toggle in `win32_window.cpp`.  
• **Basic Test**: Single widget test verifying counter increments.  

### Out-of-Scope (Phase 2+)

• Advanced state management (e.g., Provider, Riverpod, BLoC).  
• Persistent data storage or local database integration.  
• Networking or API calls.  
• User authentication or backend services.  
• Complex navigation or multi-screen flows.  
• Automated CI/CD pipelines.  
• Internationalization (i18n) or localization.  
• Dependency injection frameworks.  

## 3. User Flow

When a user launches arc_note on any supported platform, the native entry point initializes the Flutter engine and displays the main Dart widget tree. The user sees a top AppBar with the title "arc_note" and a large number in the center of the screen, starting at zero. At the bottom right, a circular button with a plus icon invites interaction.

Each tap on the plus button triggers the `_incrementCounter` method in the `MyHomePage` widget, calling `setState()` and increasing the displayed number by one. The UI updates instantly, reflecting the new count. The user can repeat this action indefinitely. On Windows, the app also adjusts its look between light and dark mode automatically based on system settings.

## 4. Core Features

- **Cross-Platform Scaffold:** Single Dart codebase in `lib/` plus three platform folders.  
- **MaterialApp & ThemeData:** App-wide theming configuration for consistent styling.  
- **Counter UI:** `MyHomePage` StatefulWidget displaying count and handling taps.  
- **Floating Action Button:** Standard FAB triggering state changes.  
- **Native Entry Points:** Kotlin (`android/`), Swift (`ios/`), C++ (`windows/`) integration.  
- **Windows Dark Mode Support:** Reads Windows registry to toggle theme.  
- **Basic Automated Test:** Verifies counter increment logic in `test/widget_test.dart`.  

## 5. Tech Stack & Tools

- **Frontend Framework:** Flutter  (Dart language)  
- **Android Native:** Kotlin, Gradle (`build.gradle.kts`), Android SDK  
- **iOS Native:** Swift, Xcode, iOS SDK, `Info.plist`  
- **Windows Native:** C++ (MSVC), CMake, Win32 API  
- **Testing:** `flutter_test` package  
- **Linting:** `flutter_lints` via `analysis_options.yaml`  
- **IDE/Editors:** Android Studio, Xcode, Visual Studio Code, Visual Studio  

## 6. Non-Functional Requirements

- **Performance:** 60 FPS UI rendering on supported devices.  
- **Startup Time:** Cold launch under 2 seconds on mid-range mobile hardware.  
- **Security:** No user data stored or transmitted; follow platform guidelines.  
- **Usability:** Simple, self-explanatory interface with accessible touch targets.  
- **Maintainability:** Clear code structure, basic linting rules, single responsibility per file.  

## 7. Constraints & Assumptions

- **Flutter SDK:** Must use stable channel (2.x or 3.x).  
- **Dart SDK:** Version ≥2.17  
- **Windows Builds:** Requires Windows 10+ with CMake ≥3.10 and Visual Studio with C++ workload.  
- **Mobile SDKs:** Android SDK 29+; Xcode 12+ for iOS.  
- **Machine Requirements:** Local dev machines must have all native toolchains installed.  
- **Assumption:** No network connectivity or external services needed for Version 1.0.  

## 8. Known Issues & Potential Pitfalls

- **Registry Access on Windows:** Reading theme preference may fail if registry keys are missing or permissions restricted.  
- **Platform SDK Mismatch:** Gradle or Xcode version mismatches can break builds—pin versions in docs.  
- **Limited Error Handling:** No try/catch around native initializations—app may crash on failure.  
- **State Management Scalability:** `setState()` won’t scale beyond trivial examples—plan for refactoring.  
- **Dark Mode Delay:** Windows theme change might not auto-refresh without full window reload.  

**Mitigation Guidelines:**  
- Validate registry key existence and wrap reads in safe checks.  
- Document exact SDK versions and provide sample `sdk` settings in gradle and Xcode.  
- Introduce basic error handling in `main.cpp`, `MainActivity.kt`, and `AppDelegate.swift`.  
- For future phases, evaluate and integrate a state management library.  

---

This PRD captures all essential details for arc_note v1.0. With this as the single source of truth, developers and AI tools can generate detailed technical specs, front-end and back-end guidelines, file structure proposals, and CI/CD pipelines without ambiguity.