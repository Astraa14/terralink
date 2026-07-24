import 'package:flutter/foundation.dart';

/// Condition types for automation rule evaluation.
enum RuleCondition {
  greaterThan,
  lessThan,
  equalTo,
  between;

  String get label {
    switch (this) {
      case RuleCondition.greaterThan:
        return 'Greater Than';
      case RuleCondition.lessThan:
        return 'Less Than';
      case RuleCondition.equalTo:
        return 'Equal To';
      case RuleCondition.between:
        return 'Between';
    }
  }

  String get symbol {
    switch (this) {
      case RuleCondition.greaterThan:
        return '>';
      case RuleCondition.lessThan:
        return '<';
      case RuleCondition.equalTo:
        return '=';
      case RuleCondition.between:
        return '↔';
    }
  }
}

/// Actions that can be triggered when a rule condition is met.
enum RuleAction {
  sendCommand,
  triggerAlert,
  enableDevice,
  disableDevice;

  String get label {
    switch (this) {
      case RuleAction.sendCommand:
        return 'Send Bluetooth Command';
      case RuleAction.triggerAlert:
        return 'Trigger Alert';
      case RuleAction.enableDevice:
        return 'Enable Device';
      case RuleAction.disableDevice:
        return 'Disable Device';
    }
  }

  String get icon {
    switch (this) {
      case RuleAction.sendCommand:
        return '📡';
      case RuleAction.triggerAlert:
        return '🔔';
      case RuleAction.enableDevice:
        return '✅';
      case RuleAction.disableDevice:
        return '⛔';
    }
  }
}

/// Sensor metadata helper for display purposes.
class SensorMeta {
  final String name;
  final String unit;
  final String icon;
  final int colorBg;
  final int colorText;

  const SensorMeta({
    required this.name,
    required this.unit,
    required this.icon,
    required this.colorBg,
    required this.colorText,
  });

  static const List<SensorMeta> sensors = [
    SensorMeta(
      name: 'Temperature',
      unit: '°C',
      icon: '🌡️',
      colorBg: 0xFFFFF7F2,
      colorText: 0xFFE65100,
    ),
    SensorMeta(
      name: 'Humidity',
      unit: '%',
      icon: '💧',
      colorBg: 0xFFF0F5FA,
      colorText: 0xFF0288D1,
    ),
    SensorMeta(
      name: 'Soil NPK',
      unit: 'mg/kg',
      icon: '🧪',
      colorBg: 0xFFFFFBEA,
      colorText: 0xFFF57F17,
    ),
    SensorMeta(
      name: 'Soil Moisture',
      unit: 'pts',
      icon: '🌱',
      colorBg: 0xFFEAF8F6,
      colorText: 0xFF00796B,
    ),
  ];

  static SensorMeta get(int index) => sensors[index.clamp(0, 3)];
}

/// A single automation rule that evaluates sensor data and triggers an action.
class AutomationRule {
  final String id;
  String name;
  int sensorIndex;
  RuleCondition condition;
  double thresholdValue;
  double thresholdMax;
  RuleAction action;
  String commandString;
  bool isEnabled;
  int cooldownSeconds;
  DateTime? lastTriggered;
  String description;

  AutomationRule({
    required this.id,
    required this.name,
    required this.sensorIndex,
    required this.condition,
    required this.thresholdValue,
    this.thresholdMax = 0.0,
    required this.action,
    this.commandString = '',
    this.isEnabled = true,
    this.cooldownSeconds = 60,
    this.lastTriggered,
    this.description = '',
  });

  /// The sensor metadata for this rule's sensor.
  SensorMeta get sensor => SensorMeta.get(sensorIndex);

  /// Human-readable condition string, e.g. "Temperature > 30°C"
  String get conditionText {
    final s = sensor;
    switch (condition) {
      case RuleCondition.greaterThan:
        return '${s.name} > ${thresholdValue.toStringAsFixed(1)}${s.unit}';
      case RuleCondition.lessThan:
        return '${s.name} < ${thresholdValue.toStringAsFixed(1)}${s.unit}';
      case RuleCondition.equalTo:
        return '${s.name} = ${thresholdValue.toStringAsFixed(1)}${s.unit}';
      case RuleCondition.between:
        return '${s.name} ${thresholdValue.toStringAsFixed(1)} – ${thresholdMax.toStringAsFixed(1)}${s.unit}';
    }
  }

  /// Human-readable action string.
  String get actionText {
    switch (action) {
      case RuleAction.sendCommand:
        return 'Send: $commandString';
      case RuleAction.triggerAlert:
        return 'Trigger Alert';
      case RuleAction.enableDevice:
        return 'Enable: $commandString';
      case RuleAction.disableDevice:
        return 'Disable: $commandString';
    }
  }

  /// Whether the rule is currently in cooldown.
  bool get isInCooldown {
    if (lastTriggered == null) return false;
    final elapsed = DateTime.now().difference(lastTriggered!).inSeconds;
    return elapsed < cooldownSeconds;
  }

  /// Remaining cooldown time in seconds.
  int get cooldownRemaining {
    if (lastTriggered == null) return 0;
    final elapsed = DateTime.now().difference(lastTriggered!).inSeconds;
    final remaining = cooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Status label for display.
  String get statusLabel {
    if (!isEnabled) return 'Disabled';
    if (isInCooldown) return 'Cooldown (${cooldownRemaining}s)';
    return 'Active';
  }

  /// Evaluate this rule against a sensor value. Returns true if condition met.
  bool evaluate(double sensorValue) {
    if (!isEnabled || isInCooldown) return false;
    switch (condition) {
      case RuleCondition.greaterThan:
        return sensorValue > thresholdValue;
      case RuleCondition.lessThan:
        return sensorValue < thresholdValue;
      case RuleCondition.equalTo:
        return (sensorValue - thresholdValue).abs() < 0.5;
      case RuleCondition.between:
        return sensorValue >= thresholdValue && sensorValue <= thresholdMax;
    }
  }

  /// Mark this rule as just triggered.
  void markTriggered() {
    lastTriggered = DateTime.now();
  }

  /// Create a copy of this rule with optional overrides.
  AutomationRule copyWith({
    String? id,
    String? name,
    int? sensorIndex,
    RuleCondition? condition,
    double? thresholdValue,
    double? thresholdMax,
    RuleAction? action,
    String? commandString,
    bool? isEnabled,
    int? cooldownSeconds,
    DateTime? lastTriggered,
    String? description,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      sensorIndex: sensorIndex ?? this.sensorIndex,
      condition: condition ?? this.condition,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      thresholdMax: thresholdMax ?? this.thresholdMax,
      action: action ?? this.action,
      commandString: commandString ?? this.commandString,
      isEnabled: isEnabled ?? this.isEnabled,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      description: description ?? this.description,
    );
  }

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sensorIndex': sensorIndex,
      'condition': condition.index,
      'thresholdValue': thresholdValue,
      'thresholdMax': thresholdMax,
      'action': action.index,
      'commandString': commandString,
      'isEnabled': isEnabled,
      'cooldownSeconds': cooldownSeconds,
      'lastTriggered': lastTriggered?.toIso8601String(),
      'description': description,
    };
  }

  /// Deserialize from JSON map.
  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'] as String,
      name: json['name'] as String,
      sensorIndex: json['sensorIndex'] as int,
      condition: RuleCondition.values[json['condition'] as int],
      thresholdValue: (json['thresholdValue'] as num).toDouble(),
      thresholdMax: (json['thresholdMax'] as num?)?.toDouble() ?? 0.0,
      action: RuleAction.values[json['action'] as int],
      commandString: json['commandString'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      cooldownSeconds: json['cooldownSeconds'] as int? ?? 60,
      lastTriggered: json['lastTriggered'] != null
          ? DateTime.tryParse(json['lastTriggered'] as String)
          : null,
      description: json['description'] as String? ?? '',
    );
  }
}
