import 'package:flutter/material.dart';
import 'package:terralink/core/theme.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'TerraLink';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart Terrarium Monitoring';

  // Bluetooth
  static const Duration bluetoothScanTimeout = Duration(seconds: 10);
  static const Duration bluetoothConnectionTimeout = Duration(seconds: 15);
  static const Duration sensorPollInterval = Duration(seconds: 2);
  static const String bluetoothDevicePrefix = 'TerraLink';

  // Sensor data parsing
  static const String sensorDataSeparator = ',';
  static const int expectedSensorFieldCount = 6;

  // Chart
  static const int maxChartDataPoints = 50;
  static const Duration chartAnimationDuration = Duration(milliseconds: 600);

  // UI
  static const double cardBorderRadius = 16.0;
  static const double inputBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  // Automation
  static const int maxAutomationRules = 20;
  static const Duration automationCheckInterval = Duration(seconds: 5);
}

enum SensorType {
  temperature,
  humidity,
  soilNitrogen,
  soilPhosphorus,
  soilPotassium,
  soilMoisture,
}

class SensorConfig {
  final String name;
  final String shortName;
  final String unit;
  final double minValue;
  final double maxValue;
  final double idealMin;
  final double idealMax;
  final Color color;
  final IconData icon;

  const SensorConfig({
    required this.name,
    required this.shortName,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.idealMin,
    required this.idealMax,
    required this.color,
    required this.icon,
  });
}

class SensorConfigs {
  SensorConfigs._();

  static const Map<SensorType, SensorConfig> configs = {
    SensorType.temperature: SensorConfig(
      name: 'Temperature',
      shortName: 'Temp',
      unit: '°C',
      minValue: 0,
      maxValue: 50,
      idealMin: 20,
      idealMax: 30,
      color: AppColors.temperatureColor,
      icon: Icons.thermostat,
    ),
    SensorType.humidity: SensorConfig(
      name: 'Humidity',
      shortName: 'Humid',
      unit: '%',
      minValue: 0,
      maxValue: 100,
      idealMin: 50,
      idealMax: 80,
      color: AppColors.humidityColor,
      icon: Icons.water_drop,
    ),
    SensorType.soilNitrogen: SensorConfig(
      name: 'Soil Nitrogen',
      shortName: 'N',
      unit: 'mg/kg',
      minValue: 0,
      maxValue: 200,
      idealMin: 20,
      idealMax: 80,
      color: AppColors.soilNitrogenColor,
      icon: Icons.grass,
    ),
    SensorType.soilPhosphorus: SensorConfig(
      name: 'Soil Phosphorus',
      shortName: 'P',
      unit: 'mg/kg',
      minValue: 0,
      maxValue: 200,
      idealMin: 15,
      idealMax: 60,
      color: AppColors.soilPhosphorusColor,
      icon: Icons.scatter_plot,
    ),
    SensorType.soilPotassium: SensorConfig(
      name: 'Soil Potassium',
      shortName: 'K',
      unit: 'mg/kg',
      minValue: 0,
      maxValue: 300,
      idealMin: 50,
      idealMax: 150,
      color: AppColors.soilPotassiumColor,
      icon: Icons.hexagon,
    ),
    SensorType.soilMoisture: SensorConfig(
      name: 'Soil Moisture',
      shortName: 'Moist',
      unit: '%',
      minValue: 0,
      maxValue: 100,
      idealMin: 30,
      idealMax: 70,
      color: AppColors.soilMoistureColor,
      icon: Icons.opacity,
    ),
  };

  static SensorConfig getConfig(SensorType type) => configs[type]!;

  static List<SensorType> get allTypes => SensorType.values;

  static String getStatusLabel(SensorType type, double value) {
    final config = getConfig(type);
    if (value < config.idealMin) return 'Low';
    if (value > config.idealMax) return 'High';
    return 'Optimal';
  }

  static Color getStatusColor(SensorType type, double value) {
    final config = getConfig(type);
    if (value < config.idealMin) return AppColors.info;
    if (value > config.idealMax) return AppColors.error;
    return AppColors.success;
  }

  static double getNormalizedValue(SensorType type, double value) {
    final config = getConfig(type);
    return ((value - config.minValue) / (config.maxValue - config.minValue))
        .clamp(0.0, 1.0);
  }
}
