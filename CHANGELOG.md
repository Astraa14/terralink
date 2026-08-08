# Changelog

All notable changes to the TerraLink project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-08

### Added
- **Real-Time Sensor Monitoring**: Support for temperature, humidity, soil moisture, NPK composition, soil pH, and electrical conductivity (EC).
- **Bluetooth SPP Hardware Connectivity**: Automatic device discovery, paired device management, auto-reconnect, and stream decoding for HC-05/HC-06 microcontrollers.
- **Hardware Automation Engine**: Real-time rule evaluation triggering misting pumps (`MIST:ON/OFF`), ventilation fans (`FAN:ON/OFF`), and power state management.
- **Analytics & Visualizations**: Interactive historical trends and sparklines for 5-hour rolling telemetry data windows.
- **Demo Mode**: Interactive hardware simulator generating synthetic sensor values for demonstration and offline testing.
- **Authentication**: Flexible authentication options including Google Sign-In, Email/Password, and Guest access.
- **Platform Support**: Production-configured Android package (`com.astral.terralink`) and iOS bundle configuration with full Bluetooth permission disclosures.

### Changed
- Updated production application package identifiers and bundle metadata.
- Standardized design system colors, typography, and card layouts.

### Fixed
- Fixed Bluetooth service reference issues and resolved deprecation warnings across UI screens.
