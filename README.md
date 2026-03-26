# Infinite Files

Infinite Files is a full Flutter + Dart desktop file manager with an M3 expressive UI inspired by the vibe of end-4's illogical-impulse Hyprland setup.

## Features

- Material 3 expressive dark desktop UI.
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

`flutter build windows` already emits an `.exe` in the release folder. If you want a single installer EXE, package with an installer tool (Inno Setup / NSIS / WiX) using the release directory.
