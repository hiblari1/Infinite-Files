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

