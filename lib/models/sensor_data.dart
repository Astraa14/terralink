import 'package:terralink/core/constants.dart';

class SensorReading {
  final SensorType type;
  final double value;
  final DateTime timestamp;

  const SensorReading({
    required this.type,
    required this.value,
    required this.timestamp,
  });

  SensorReading copyWith({
    SensorType? type,
    double? value,
    DateTime? timestamp,
  }) {
    return SensorReading(
      type: type ?? this.type,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String get formattedValue {
    final config = SensorConfigs.getConfig(type);
    return '${value.toStringAsFixed(1)}${config.unit}';
  }

  String get statusLabel => SensorConfigs.getStatusLabel(type, value);

  bool get isInIdealRange {
    final config = SensorConfigs.getConfig(type);
    return value >= config.idealMin && value <= config.idealMax;
  }

  double get normalizedValue => SensorConfigs.getNormalizedValue(type, value);

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      type: SensorType.values[json['type'] as int],
      value: (json['value'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'SensorReading(type: $type, value: $value, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorReading &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(type, value, timestamp);
}

class SensorLog {
  final double temperature;
  final double humidity;
  final double soilNitrogen;
  final double soilPhosphorus;
  final double soilPotassium;
  final double soilMoisture;
  final DateTime timestamp;

  const SensorLog({
    required this.temperature,
    required this.humidity,
    required this.soilNitrogen,
    required this.soilPhosphorus,
    required this.soilPotassium,
    required this.soilMoisture,
    required this.timestamp,
  });

  factory SensorLog.fromRawData(String rawData) {
    final parts = rawData.split(AppConstants.sensorDataSeparator);
    if (parts.length < AppConstants.expectedSensorFieldCount) {
      throw FormatException(
        'Invalid sensor data: expected ${AppConstants.expectedSensorFieldCount} '
        'fields but got ${parts.length}',
        rawData,
      );
    }
    return SensorLog(
      temperature: double.tryParse(parts[0].trim()) ?? 0.0,
      humidity: double.tryParse(parts[1].trim()) ?? 0.0,
      soilNitrogen: double.tryParse(parts[2].trim()) ?? 0.0,
      soilPhosphorus: double.tryParse(parts[3].trim()) ?? 0.0,
      soilPotassium: double.tryParse(parts[4].trim()) ?? 0.0,
      soilMoisture: double.tryParse(parts[5].trim()) ?? 0.0,
      timestamp: DateTime.now(),
    );
  }

  factory SensorLog.empty() {
    return SensorLog(
      temperature: 0,
      humidity: 0,
      soilNitrogen: 0,
      soilPhosphorus: 0,
      soilPotassium: 0,
      soilMoisture: 0,
      timestamp: DateTime.now(),
    );
  }

  double getValue(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return temperature;
      case SensorType.humidity:
        return humidity;
      case SensorType.soilNitrogen:
        return soilNitrogen;
      case SensorType.soilPhosphorus:
        return soilPhosphorus;
      case SensorType.soilPotassium:
        return soilPotassium;
      case SensorType.soilMoisture:
        return soilMoisture;
    }
  }

  List<SensorReading> toReadings() {
    return SensorType.values.map((type) {
      return SensorReading(
        type: type,
        value: getValue(type),
        timestamp: timestamp,
      );
    }).toList();
  }

  SensorLog copyWith({
    double? temperature,
    double? humidity,
    double? soilNitrogen,
    double? soilPhosphorus,
    double? soilPotassium,
    double? soilMoisture,
    DateTime? timestamp,
  }) {
    return SensorLog(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      soilNitrogen: soilNitrogen ?? this.soilNitrogen,
      soilPhosphorus: soilPhosphorus ?? this.soilPhosphorus,
      soilPotassium: soilPotassium ?? this.soilPotassium,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'soilNitrogen': soilNitrogen,
      'soilPhosphorus': soilPhosphorus,
      'soilPotassium': soilPotassium,
      'soilMoisture': soilMoisture,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorLog.fromJson(Map<String, dynamic> json) {
    return SensorLog(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      soilNitrogen: (json['soilNitrogen'] as num).toDouble(),
      soilPhosphorus: (json['soilPhosphorus'] as num).toDouble(),
      soilPotassium: (json['soilPotassium'] as num).toDouble(),
      soilMoisture: (json['soilMoisture'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'SensorLog(temp: $temperature, humid: $humidity, N: $soilNitrogen, '
      'P: $soilPhosphorus, K: $soilPotassium, moist: $soilMoisture, '
      'time: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorLog &&
          runtimeType == other.runtimeType &&
          temperature == other.temperature &&
          humidity == other.humidity &&
          soilNitrogen == other.soilNitrogen &&
          soilPhosphorus == other.soilPhosphorus &&
          soilPotassium == other.soilPotassium &&
          soilMoisture == other.soilMoisture &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        temperature,
        humidity,
        soilNitrogen,
        soilPhosphorus,
        soilPotassium,
        soilMoisture,
        timestamp,
      );
}
