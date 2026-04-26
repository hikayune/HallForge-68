# HallForge 68

[![Platform](https://img.shields.io/badge/platform-Windows-0078D4?style=for-the-badge&labelColor=21262D&logo=windows)](https://www.microsoft.com/windows)
[![Framework](https://img.shields.io/badge/framework-Flutter-02569B?style=for-the-badge&labelColor=21262D&logo=flutter)](https://flutter.dev)
[![Device](https://img.shields.io/badge/device-WIN68HE-2563EB?style=for-the-badge&labelColor=21262D&logo=keyboard)](#)
[![Status](https://img.shields.io/badge/status-early%20development-6E7681?style=for-the-badge&labelColor=21262D)](#current-status)
[![Focus](https://img.shields.io/badge/focus-HID%20integration-238636?style=for-the-badge&labelColor=21262D)](#current-status)

HallForge 68 is a desktop utility for the AULA WIN68 HE keyboard.

The goal is simple: replace the vendor web app with a native desktop app that feels cleaner, clearer, and easier to trust for everyday use. The project is being built in Flutter with a Windows HID bridge, starting from protocol research based on the original web driver.

## Current Status

The project is still early, but the foundation is already in place:

- Desktop-first shell with sidebar navigation
- Light and dark themes designed for a system utility feel
- Native Windows HID bridge
- HID device scan, connect, and disconnect flow
- Initial protocol notes for WIN68HE calibration

Right now the focus is on making the device communication solid first. After that, the app can grow into the actual keyboard tools: calibration, actuation, rapid trigger, lighting, profiles, and settings.

## Planned Sections

- Device
- Keys
- Actuation
- Rapid Trigger
- Lighting
- Profiles
- Settings

## Project Direction

HallForge 68 is meant to feel more like Windows Settings, GNOME Settings, or macOS System Settings than a flashy gaming dashboard. The interface is desktop-first, compact, and practical. RGB belongs in lighting preview, not all over the app theme.

## Scope

The first target is the WIN68HE and its vendor HID interface.

The current protocol work in this repository comes from:

- reverse engineering the vendor web app JavaScript
- studying the layout data used by the site
- validating packets against HID captures

Related notes live in:

- [docs/win68he_calibration_protocol.md](docs/win68he_calibration_protocol.md)

## Running

From the project folder:

```bash
flutter analyze
flutter run -d windows
```

## Short-Term Goals

- make HID communication reliable on real hardware
- validate the exact device filter and report flow
- wire the Device page into live HID actions
- start the first working calibration flow

## Notes

- Windows is the main target right now.
- The app is intentionally starting with the communication layer first.
- A lot of the UI sections already exist as structure, but not all of them are functional yet.

## License

See [LICENSE](LICENSE).
