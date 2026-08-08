# TerraLink

> **Work in progress** — This project is under active development. Features, UI, and hardware integration may change.

A Flutter mobile app for monitoring and analyzing farm soil status and crop environment health. TerraLink connects to soil sensor microcontrollers (e.g. HC-05/HC-06 Bluetooth modules) to display live soil moisture, NPK composition, pH, electrical conductivity (EC), ambient temperature, and humidity data while executing automated irrigation and fertigation rules.

## Features (current)

- **Dashboard** — Real-time temperature, humidity, soil NPK, and soil moisture readings
- **Demo mode** — Simulated sensor data so you can explore the UI without hardware
- **Bluetooth** — Connect to paired SPP Bluetooth serial devices
- **Alerts** — Configurable threshold warnings per sensor
- **Analytics** — 5-hour historical trend views with CSV telemetry export functionality
- **Automation rules** — Full hardware rule engine (Automated Mist Pump, Overheating Extraction Fan, Night Mode) with outbound Bluetooth command transmission (`MIST:ON`, `FAN:ON`, `NIGHT:ON`) and manual relay overrides.

## Planned

- Persistent database log storage (SQLite / Hive)
- Advanced customizable chart graphing & PDF reporting

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.12)
- Android device/emulator (Bluetooth features require a physical device)
- Optional: HC-05/HC-06 module paired with your phone for live data

## Getting started

```bash
git clone https://github.com/Astraa14/terralink.git
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

## Bluetooth Pairing & Troubleshooting

1. **Initial Pairing**: Pair your HC-05 / HC-06 Bluetooth module in your Android system Bluetooth settings before opening TerraLink (default PIN is usually `1234` or `0000`).
2. **Permissions**: Ensure Bluetooth and Location permissions are granted when prompted by the app.
3. **Disconnections**: If connection drops, tap the Bluetooth icon in the top app bar to initiate re-pairing or enable "Auto-Reconnect" in Settings.

## Tech stack

- Flutter / Dart
- `flutter_bluetooth_serial` — Bluetooth SPP communication
- `permission_handler` — Bluetooth and location permissions
- `fl_chart` — Analytics data charting

## License

This project is licensed under the [MIT License](LICENSE).

## Status

TerraLink is pre-configured for publication (v1.0.0).
