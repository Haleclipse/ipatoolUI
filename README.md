[中文](README_CN.md)

# ipatoolUI

Native SwiftUI wrapper around [ipatool](https://github.com/majd/ipatool) that keeps every CLI feature one click away.

<img width="901" height="656" alt="Screenshot 2025-11-12 alle 01 02 02" src="https://github.com/user-attachments/assets/d46f1738-c6d2-4df5-b101-802a1d63ff0f" />

## Features

- Authenticate Apple IDs (login, info, revoke) with inline 2FA handling.
- Search for apps, inspect metadata, and initiate purchases directly from results.
- Manually purchase licenses, list all available versions, and inspect version metadata.
- Download IPA files with optional automatic purchasing and destination picker.
- Real-time command log with stdout/stderr capture for debugging.
- Preferences pane to point at a custom `ipatool` binary, toggle verbose/non-interactive flags, and store the keychain passphrase.

## Project structure

- `ipatoolUI.xcodeproj` – macOS SwiftUI app target (minimum macOS 13).
- `ipatoolUI/` – application sources, SwiftUI views, view models, services, and resources.
- `Resources/Assets.xcassets` – placeholder app icon and preview assets.

## Getting started

1. Install `ipatool` (e.g. `brew install ipatool`).
2. Open `ipatoolUI.xcodeproj` in Xcode 15 or newer.
3. Select the *ipatoolUI* scheme and build/run on macOS 13+.
4. On first launch, visit **Settings → ipatool Binary** to confirm the executable path if it is not auto-detected.

## Using the app

- **Authentication**: provide Apple‑ID credentials (password stays local) and sign in. Use *Account Info* to verify the active session or *Revoke* to clear credentials.
- **Search**: look up apps, inspect bundles, and trigger purchases for any result.
- **Purchase**: obtain licenses manually by bundle identifier.
- **Versions**: list every external version identifier for an app; copy IDs for later use.
- **Download**: choose app/bundle, optional version, destination, and whether to auto‑purchase. Progress and results surface in the status area and logs.
- **Version Metadata**: resolve release details for a specific external version.
- **Logs**: inspect every launched `ipatool` command, with sanitized arguments and captured stdout/stderr.
- **Settings**: configure the executable location, passphrase, verbosity, and non-interactive behavior.

## Notes

- The UI always invokes `ipatool` with `--format json` so responses can be parsed automatically.
- Sensitive flags (passwords, OTP codes, keychain passphrases) are masked inside the command log.
- The app delegates complex state (command history, user preferences) to `UserDefaults`, so reruns preserve your setup.