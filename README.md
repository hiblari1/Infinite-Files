# Infinite Files

Infinite Files is a full Flutter + Dart desktop file manager with an M3 expressive UI inspired by the vibe of end-4's illogical-impulse Hyprland setup.

## Features

- Material 3 expressive dark desktop UI with an illogical-impulse-inspired shell layout (left rail, path chips, floating command/search bar).
- Sidebar favorites for Home/Documents/Downloads/Desktop.
- Folder navigation by clicking directory cards.
- Search/filter in current directory.
- Sort by modified date, name, or size.
- Create folder flow.
- Works on Linux, macOS, and Windows from the same Dart codebase.

## Prerequisites

- Flutter SDK (stable)
- Dart SDK (bundled with Flutter)
- Platform toolchains:
  - Linux: `clang`, `cmake`, `ninja`, GTK dev libs
  - macOS: Xcode command line tools
  - Windows: Visual Studio C++ desktop workload

## First-time desktop setup (required)

If your repo was created without desktop folders, run this once before building:

```bash
flutter config --enable-linux-desktop --enable-macos-desktop --enable-windows-desktop
flutter create --platforms=linux,macos,windows .
```

This generates `linux/`, `macos/`, and `windows/` project files needed by `flutter build`.

## Run locally

```bash
flutter pub get
flutter run -d linux     # or -d macos / -d windows
```

## Build artifacts

```bash
flutter build linux
flutter build macos
flutter build windows
```

- Linux binary output: `build/linux/x64/release/bundle/`
- macOS app bundle output: `build/macos/Build/Products/Release/infinite_files.app`
- Windows executable output: `build/windows/x64/runner/Release/`

## Package targets

### Linux AppImage

Use the helper script:

```bash
bash scripts/package_appimage.sh
```

This wraps the Linux release bundle into `dist/InfiniteFiles-x86_64.AppImage`.

### macOS DMG

Use the helper script:

```bash
bash scripts/package_dmg.sh
```

This creates `dist/InfiniteFiles.dmg` using `hdiutil`.

### Windows EXE

`flutter build windows` emits an `.exe` in the release folder, but target machines also need the Microsoft Visual C++ runtime.

If users see `VCRUNTIME140.dll` missing, install the official `vc_redist.x64.exe` (Visual C++ Redistributable) first, then run `infinite_files.exe`.

The GitHub Actions Windows artifact now bundles `vc_redist.x64.exe` next to the app to avoid this issue for testers.

## Build in GitHub (GitHub Actions)

This repository includes a workflow at `.github/workflows/build-desktop.yml` for all target desktop OSes.

It builds and uploads:

- `infinite-files-linux-bundle` (Linux build bundle)
- `infinite-files-windows-portable` (Windows EXE + `vc_redist.x64.exe`)
- `infinite-files-macos-dmg` (macOS DMG)

### Run it

1. Push your branch to GitHub.
2. Open **Actions** tab.
3. Run **Build Infinite Files Desktop** with **Run workflow** (or let it run automatically on push/PR).
4. Download needed artifacts from the workflow run summary.

### Notes

- If Windows shows missing `VCRUNTIME140.dll`, run `vc_redist.x64.exe` from the Windows artifact.
- For public macOS release, add code signing + notarization in a release workflow.
