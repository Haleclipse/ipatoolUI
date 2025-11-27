# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Open `ipatoolUI.xcodeproj` in Xcode 15+ and build/run the **ipatoolUI** scheme. Requires macOS 13+.

No Swift Package Manager dependencies—this is a pure Xcode project.

## Architecture

This is a macOS SwiftUI application that wraps the [ipatool](https://github.com/majd/ipatool) CLI for downloading IPA files from the App Store.

### Core Layers

- **AppState** (`Models/AppState.swift`) – Singleton `@MainActor ObservableObject` injected via `.environmentObject()`. Owns `IpatoolService`, `CommandLogger`, all ViewModels, and user `Preferences`. The `CommandEnvironment` struct bundles these dependencies for passing to ViewModels.

- **IpatoolService** (`Services/IpatoolService.swift`) – Executes `ipatool` CLI commands via `Process`, always with `--format json`. Handles argument sanitization (masks passwords/OTP in logs), captures stdout/stderr, and logs every command to `CommandLogger`.

- **ViewModels** (`ViewModels/*.swift`) – Feature-specific logic (Auth, Search, Download, Purchase, ListVersions, VersionMetadata). Each receives `CommandEnvironment` and calls `IpatoolService.execute()`.

- **Views** (`Views/*.swift`) – SwiftUI views. `MainView` uses `NavigationSplitView` with sidebar listing `Feature` enum cases; detail pane switches views based on `appState.selectedFeature`.

- **Models** (`Models/IpatoolModels.swift`) – Decodable structs for parsing ipatool JSON output (`SearchLogEvent`, `AuthLogEvent`, `DownloadLogEvent`, etc.) plus `IpatoolError` enum.

### Data Flow Pattern

1. User triggers action in View
2. View calls ViewModel method with `appState.environmentSnapshot()`
3. ViewModel builds subcommand array, calls `IpatoolService.execute()`
4. Service runs process, logs to `CommandLogger`, decodes JSON response
5. ViewModel updates `@Published` state, View re-renders

### Preferences

Stored in `UserDefaults` via `PreferencesStore`. Key settings: `ipatoolPath`, `keychainPassphrase`, `verboseLogs`, `nonInteractive`, `outputFormat`.
