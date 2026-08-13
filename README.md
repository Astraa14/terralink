<div align="center">

<img src="assets/terralink.png" alt="TerraLink" width="120" height="120" />

# TerraLink

**Smart soil monitoring for modern farms.**

Live soil intelligence — moisture, pH, NPK, conductivity, temperature and humidity — streamed from field sensors to a beautiful dark dashboard, with automated irrigation and fertigation rules.

[![Live demo](https://img.shields.io/badge/-Live%20Demo-22C55E?style=for-the-badge&logo=vercel&logoColor=white)](https://terralink-monitor.vercel.app)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

</div>

---

## What it does

TerraLink pairs a soil sensor module (e.g. HC-05 / HC-06 Bluetooth) with your phone to turn raw field readings into decisions you can act on.

- **Soil Chemistry** — moisture, NPK, pH and electrical conductivity (EC) with reference bands and per-factor health status.
- **Environment** — ambient temperature and humidity for crop canopy conditions.
- **Health Score** — a single 0–100 soil-health score derived from your live readings, with clear factor breakdowns.
- **Automation engine** — configurable rules (irrigation, extraction fan, night optimization) that send real commands to equipment over Bluetooth (`MIST:ON`, `FAN:ON`, `NIGHT:ON`).
- **Analytics** — historical trend charts with 1H / 6H / 24H / 7D ranges.
- **Demo mode** — explore the full experience with simulated field data, no hardware required.
- **Auth** — sign in with Google, email, or as a guest (Supabase).

## Try it

`https://terralink-monitor.vercel.app` — the fully responsive web build. The full app also runs on Android, iOS, Windows, macOS and Linux from the Flutter SDK.

## How data flows

```
Soil sensors ──► MCU (Arduino/ESP) ──► HC-05/HC-06 ──► TerraLink
   moisture                                              │
   NPK / pH / EC                                         │  dashboard + health score
   temperature / humidity ── CSV line ───────────────────┤  automation rules
                                                         ▼
                                              Equipment commands (MIST/FAN/NIGHT)
```

Data arrives as newline-terminated CSV over Bluetooth SPP:

```
temperature,humidity,npk,soil_moisture      # e.g. 24.5,58.0,420,280
```

## Tech stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter / Dart |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Bluetooth | [flutter_bluetooth_serial](https://pub.dev/packages/flutter_bluetooth_serial) |
| Permissions | `permission_handler` |
| Auth | Supabase (email, Google, guest) |
| Web hosting | Vercel |

## Getting started

```bash
git clone https://github.com/Astraa14/terralink.git
cd terrarium_app
flutter pub get
flutter run
```

To pair with real hardware: connect the HC-05/HC-06 module in your system Bluetooth settings first (default PIN is usually `1234` or `0000`), then tap the Bluetooth indicator in the app. Web builds run in demo mode (Bluetooth is unavailable in browsers).

## License

Released under the [MIT License](LICENSE).