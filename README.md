# TerraLink

> **Work in progress** — This project is under active development. Features, UI, and hardware integration may change.

A Flutter mobile app for monitoring and controlling a terrarium ecosystem. TerraLink connects to microcontroller hardware (e.g. HC-05/HC-06 Bluetooth modules) to display live sensor data and manage automation rules.

## Features (current)

- **Dashboard** — Real-time temperature, humidity, soil NPK, and soil moisture readings
- **Demo mode** — Simulated sensor data so you can explore the UI without hardware
- **Bluetooth** — Connect to paired SPP Bluetooth serial devices
- **Alerts** — Configurable threshold warnings per sensor
- **Analytics** — 5-hour historical trend views
- **Automation rules** — UI for mist triggers, overheating protection, and night mode (logic in progress)

## Planned

- Full automation rule engine (hardware control)
- Persistent data storage
- Improved charts and export

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.12)
- Android device/emulator (Bluetooth features require a physical device)
- Optional: HC-05/HC-06 module paired with your phone for live data

## Getting started

```bash
git clone https://github.com/YOUR_USERNAME/terrarium_app.git
cd terrarium_app
flutter pub get
flutter run
```

## Hardware data format

When connected via Bluetooth, the app expects newline-terminated CSV:

```
temperature,humidity,npk,soil_moisture
```

Example: `24.5,58.0,420,280`

## Tech stack

- Flutter / Dart
- `flutter_bluetooth_serial` — Bluetooth SPP communication
- `permission_handler` — Bluetooth and location permissions

## License

TBD

## Status

This repository is public for portfolio and collaboration purposes. Expect breaking changes until v1.0.
