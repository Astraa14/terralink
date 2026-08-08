# TerraLink Pre-Publication Status & Checklist

## Executive Summary
This document tracks the publication readiness of **TerraLink (Smart Terrarium & Farm Soil Ecosystem Monitor)**.

---

## Completed Pre-Publication Implementation Tasks

### 🔐 Security & Credentials
- [x] **Bundle ID Updated**: Standardized application namespace to `com.astral.terralink` across Android (`build.gradle.kts`) and iOS (`Info.plist`).
- [x] **Code Quality & Privacy**: Verified no production secrets or credentials are exposed. Sensitive logs removed.

### 📋 App Metadata & Store Listings
- [x] **`pubspec.yaml` Audit**: Removed `publish_to: 'none'`, added detailed description, repository URL (`https://github.com/Astraa14/terralink`), homepage link, and issue tracker.
- [x] **License**: Created official [MIT License](LICENSE).
- [x] **Privacy Policy**: Created comprehensive [Privacy Policy](PRIVACY_POLICY.md) detailing Bluetooth SPP scanning, local telemetry storage, and location permission scope.
- [x] **Changelog**: Created [CHANGELOG.md](CHANGELOG.md) documenting v1.0.0 release features.

### 📱 Platform-Specific Configuration
- [x] **Android**: Configured `AndroidManifest.xml` with required Bluetooth permissions (`BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`).
- [x] **iOS**: Configured `Info.plist` with required Bluetooth usage descriptions (`NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`, `NSBluetoothCentralUsageDescription`).

### 📝 Documentation & Technical Guides
- [x] **README Updates**: Updated clone URL to `https://github.com/Astraa14/terralink.git`, specified hardware CSV serial format expectations (`temp,humidity,npk,soil_moisture`), added Bluetooth pairing & troubleshooting steps.

---

## Publication Next Steps & Instructions

1. **Android Build**:
   - Generate release key: `keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key`
   - Build App Bundle: `flutter build aab --release`
2. **iOS Build**:
   - Open project in Xcode, set Development Team and Provisioning Profile.
   - Build Archive: `flutter build ipa --release`
