import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
class SensorLog {
  final DateTime timestamp;
  final double value;

  SensorLog({required this.timestamp, required this.value});

  String get timeLabel =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
}

class SensorAlert {
  double threshold;
  bool greaterThan; // true = alert when value > threshold
  bool enabled;
  bool triggered;

  SensorAlert({
    required this.threshold,
    this.greaterThan = true,
    this.enabled = true,
    this.triggered = false,
  });

  SensorAlert copyWith({
    double? threshold,
    bool? greaterThan,
    bool? enabled,
    bool? triggered,
  }) {
    return SensorAlert(
      threshold: threshold ?? this.threshold,
      greaterThan: greaterThan ?? this.greaterThan,
      enabled: enabled ?? this.enabled,
      triggered: triggered ?? this.triggered,
    );
  }
}

// ---------------------------------------------------------------------------
// Sensor indices
// ---------------------------------------------------------------------------
class SensorIndex {
  static const int temperature = 0;
  static const int humidity = 1;
  static const int npk = 2;
  static const int soilMoisture = 3;
  static const int count = 4;

  static String label(int index) {
    switch (index) {
      case temperature:
        return 'Temperature';
      case humidity:
        return 'Humidity';
      case npk:
        return 'NPK';
      case soilMoisture:
        return 'Soil Moisture';
      default:
        return 'Unknown';
    }
  }

  static String unit(int index) {
    switch (index) {
      case temperature:
        return '°C';
      case humidity:
        return '%';
      case npk:
        return 'mg/kg';
      case soilMoisture:
        return '%';
      default:
        return '';
    }
  }

  static String key(int index) {
    switch (index) {
      case temperature:
        return 'temperature';
      case humidity:
        return 'humidity';
      case npk:
        return 'npk';
      case soilMoisture:
        return 'soil_moisture';
      default:
        return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------
class SensorService extends ChangeNotifier {
  // Current values
  final List<double> _currentValues = [0, 0, 0, 0];
  List<double> get currentValues => List.unmodifiable(_currentValues);

  double get temperature => _currentValues[SensorIndex.temperature];
  double get humidity => _currentValues[SensorIndex.humidity];
  double get npk => _currentValues[SensorIndex.npk];
  double get soilMoisture => _currentValues[SensorIndex.soilMoisture];

  // History – maps sensor index -> list of SensorLog (5-hour window)
  final Map<int, List<SensorLog>> _history = {
    SensorIndex.temperature: [],
    SensorIndex.humidity: [],
    SensorIndex.npk: [],
    SensorIndex.soilMoisture: [],
  };
  Map<int, List<SensorLog>> get history =>
      Map.unmodifiable(_history.map((k, v) => MapEntry(k, List.unmodifiable(v))));

  // Alerts per sensor
  final List<SensorAlert> _alerts = [
    SensorAlert(threshold: 35, greaterThan: true, enabled: true),
    SensorAlert(threshold: 80, greaterThan: true, enabled: true),
    SensorAlert(threshold: 200, greaterThan: true, enabled: true),
    SensorAlert(threshold: 20, greaterThan: false, enabled: true),
  ];
  List<SensorAlert> get alerts => List.unmodifiable(_alerts);

  bool get hasActiveAlerts => _alerts.any((a) => a.enabled && a.triggered);

  // Demo mode
  bool _demoMode = false;
  bool get demoMode => _demoMode;
  Timer? _demoTimer;
  final Random _rng = Random();

  // ---------------------------------------------------------------------------
  // Init / dispose
  // ---------------------------------------------------------------------------
  SensorService();

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Demo mode
  // ---------------------------------------------------------------------------
  void setDemoMode(bool value) {
    _demoMode = value;
    if (value) {
      generateMockHistory();
      startDemoSimulation();
    } else {
      _demoTimer?.cancel();
      _demoTimer = null;
    }
    notifyListeners();
  }

  void toggleDemoMode() => setDemoMode(!_demoMode);

  void generateMockHistory() {
    final now = DateTime.now();
    for (int s = 0; s < SensorIndex.count; s++) {
      final logs = <SensorLog>[];
      for (int i = 60; i >= 0; i--) {
        final ts = now.subtract(Duration(minutes: i * 5));
        double val;
        switch (s) {
          case SensorIndex.temperature:
            val = 22 + _rng.nextDouble() * 12; // 22-34
            break;
          case SensorIndex.humidity:
            val = 40 + _rng.nextDouble() * 40; // 40-80
            break;
          case SensorIndex.npk:
            val = 80 + _rng.nextDouble() * 150; // 80-230
            break;
          case SensorIndex.soilMoisture:
            val = 20 + _rng.nextDouble() * 60; // 20-80
            break;
          default:
            val = 0;
        }
        logs.add(SensorLog(timestamp: ts, value: double.parse(val.toStringAsFixed(1))));
      }
      _history[s] = logs;
    }
    // Set current values to the last entry in each history
    for (int s = 0; s < SensorIndex.count; s++) {
      if (_history[s]!.isNotEmpty) {
        _currentValues[s] = _history[s]!.last.value;
      }
    }
    checkSensorAlerts();
    notifyListeners();
  }

  void startDemoSimulation() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_demoMode) return;
      _simulateTick();
    });
  }

  void _simulateTick() {
    final now = DateTime.now();
    for (int s = 0; s < SensorIndex.count; s++) {
      double delta = (_rng.nextDouble() - 0.5) * 2;
      double newVal = _currentValues[s] + delta;
      switch (s) {
        case SensorIndex.temperature:
          newVal = newVal.clamp(15.0, 45.0);
          break;
        case SensorIndex.humidity:
          newVal = newVal.clamp(10.0, 99.0);
          break;
        case SensorIndex.npk:
          newVal = newVal.clamp(20.0, 350.0);
          break;
        case SensorIndex.soilMoisture:
          newVal = newVal.clamp(5.0, 99.0);
          break;
      }
      _currentValues[s] = double.parse(newVal.toStringAsFixed(1));
      _history[s]!.add(SensorLog(timestamp: now, value: _currentValues[s]));
    }
    _trimHistory();
    checkSensorAlerts();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Real data from Bluetooth
  // ---------------------------------------------------------------------------
  void _onBluetoothData(Map<String, double> data) {
    final now = DateTime.now();
    for (int s = 0; s < SensorIndex.count; s++) {
      final key = SensorIndex.key(s);
      if (data.containsKey(key)) {
        _currentValues[s] = double.parse(data[key]!.toStringAsFixed(1));
        _history[s]!.add(SensorLog(timestamp: now, value: _currentValues[s]));
      }
    }
    _trimHistory();
    checkSensorAlerts();
    notifyListeners();
  }

  void updateFromMap(Map<String, double> data) => _onBluetoothData(data);

  // ---------------------------------------------------------------------------
  // History management
  // ---------------------------------------------------------------------------
  void _trimHistory() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 5));
    for (int s = 0; s < SensorIndex.count; s++) {
      _history[s]!.removeWhere((log) => log.timestamp.isBefore(cutoff));
    }
  }

  void updateRealTimeHistoryItems() {
    _trimHistory();
    notifyListeners();
  }

  List<SensorLog> historyFor(int sensorIndex) =>
      List.unmodifiable(_history[sensorIndex] ?? []);

  double averageFor(int sensorIndex) {
    final logs = _history[sensorIndex];
    if (logs == null || logs.isEmpty) return 0;
    final sum = logs.fold<double>(0, (s, l) => s + l.value);
    return double.parse((sum / logs.length).toStringAsFixed(1));
  }

  double minFor(int sensorIndex) {
    final logs = _history[sensorIndex];
    if (logs == null || logs.isEmpty) return 0;
    return logs.map((l) => l.value).reduce(min);
  }

  double maxFor(int sensorIndex) {
    final logs = _history[sensorIndex];
    if (logs == null || logs.isEmpty) return 0;
    return logs.map((l) => l.value).reduce(max);
  }

  // ---------------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------------
  void checkSensorAlerts() {
    for (int s = 0; s < SensorIndex.count; s++) {
      final a = _alerts[s];
      if (!a.enabled) {
        if (a.triggered) {
          _alerts[s] = a.copyWith(triggered: false);
        }
        continue;
      }
      final val = _currentValues[s];
      final isTriggered =
          a.greaterThan ? val > a.threshold : val < a.threshold;
      if (isTriggered != a.triggered) {
        _alerts[s] = a.copyWith(triggered: isTriggered);
      }
    }
  }

  void setAlertThreshold(int sensorIndex, double threshold) {
    _alerts[sensorIndex] = _alerts[sensorIndex].copyWith(threshold: threshold);
    checkSensorAlerts();
    notifyListeners();
  }

  void setAlertDirection(int sensorIndex, bool greaterThan) {
    _alerts[sensorIndex] =
        _alerts[sensorIndex].copyWith(greaterThan: greaterThan);
    checkSensorAlerts();
    notifyListeners();
  }

  void setAlertEnabled(int sensorIndex, bool enabled) {
    _alerts[sensorIndex] = _alerts[sensorIndex].copyWith(enabled: enabled);
    checkSensorAlerts();
    notifyListeners();
  }

  bool isAlertTriggered(int sensorIndex) =>
      _alerts[sensorIndex].enabled && _alerts[sensorIndex].triggered;

  String statusLabel(int sensorIndex) {
    if (isAlertTriggered(sensorIndex)) return 'Alert';
    return 'Normal';
  }

  // ---------------------------------------------------------------------------
  // Formatted value helpers
  // ---------------------------------------------------------------------------
  String formattedValue(int sensorIndex) {
    return _currentValues[sensorIndex].toStringAsFixed(1);
  }
}
