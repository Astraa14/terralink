import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/automation_rule.dart';

/// Holds the result of a triggered automation rule.
class TriggeredAction {
  final AutomationRule rule;
  final double sensorValue;
  final DateTime triggeredAt;

  TriggeredAction({
    required this.rule,
    required this.sensorValue,
    required this.triggeredAt,
  });

  String get summary =>
      '${rule.name}: ${rule.conditionText} → ${rule.actionText} (value: ${sensorValue.toStringAsFixed(1)})';
}

/// Service for managing and evaluating automation rules.
/// Uses ChangeNotifier for reactive UI updates.
class AutomationService extends ChangeNotifier {
  static const String _storageKey = 'terralink_automation_rules';

  List<AutomationRule> _rules = [];
  List<TriggeredAction> _recentTriggers = [];
  bool _isLoaded = false;

  /// All rules, unmodifiable view.
  List<AutomationRule> get rules => List.unmodifiable(_rules);

  /// Only enabled rules.
  List<AutomationRule> get enabledRules =>
      _rules.where((r) => r.isEnabled).toList();

  /// Only active rules (enabled and not in cooldown).
  List<AutomationRule> get activeRules =>
      _rules.where((r) => r.isEnabled && !r.isInCooldown).toList();

  /// Recent triggered actions for display.
  List<TriggeredAction> get recentTriggers =>
      List.unmodifiable(_recentTriggers);

  /// Whether rules have been loaded from storage.
  bool get isLoaded => _isLoaded;

  /// Total rule count.
  int get ruleCount => _rules.length;

  /// Active rule count.
  int get activeCount => activeRules.length;

  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  /// Add a new rule and persist.
  void addRule(AutomationRule rule) {
    _rules.add(rule);
    _save();
    notifyListeners();
  }

  /// Remove a rule by ID and persist.
  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
    _save();
    notifyListeners();
  }

  /// Update an existing rule by replacing it and persist.
  void updateRule(AutomationRule updated) {
    final index = _rules.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _rules[index] = updated;
      _save();
      notifyListeners();
    }
  }

  /// Toggle a rule's enabled state.
  void toggleRule(String ruleId) {
    final index = _rules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      _rules[index].isEnabled = !_rules[index].isEnabled;
      _save();
      notifyListeners();
    }
  }

  /// Reorder rules in the list.
  void reorderRules(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final rule = _rules.removeAt(oldIndex);
    _rules.insert(newIndex, rule);
    _save();
    notifyListeners();
  }

  /// Get a single rule by ID.
  AutomationRule? getRuleById(String id) {
    try {
      return _rules.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Evaluation Engine
  // ---------------------------------------------------------------------------

  /// Evaluate all enabled rules against current sensor values.
  /// [sensorValues] is a list of 4 doubles: [temp, humidity, npk, soilMoisture].
  /// Returns a list of triggered actions with their commands.
  List<TriggeredAction> evaluateRules(List<double> sensorValues) {
    if (sensorValues.length < 4) return [];

    final triggered = <TriggeredAction>[];

    for (final rule in _rules) {
      if (!rule.isEnabled || rule.isInCooldown) continue;

      final sensorIdx = rule.sensorIndex.clamp(0, 3);
      final currentValue = sensorValues[sensorIdx];

      if (rule.evaluate(currentValue)) {
        rule.markTriggered();
        final action = TriggeredAction(
          rule: rule,
          sensorValue: currentValue,
          triggeredAt: DateTime.now(),
        );
        triggered.add(action);
        _recentTriggers.insert(0, action);
      }
    }

    // Keep only last 50 triggers in memory.
    if (_recentTriggers.length > 50) {
      _recentTriggers = _recentTriggers.sublist(0, 50);
    }

    if (triggered.isNotEmpty) {
      _save();
      notifyListeners();
    }

    return triggered;
  }

  /// Clear all recent trigger history.
  void clearTriggerHistory() {
    _recentTriggers.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Load rules from SharedPreferences.
  Future<void> loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _rules = decoded
            .map((e) => AutomationRule.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        // First launch: seed with default rules.
        _rules = _buildDefaultRules();
        _save();
      }
    } catch (e) {
      debugPrint('AutomationService.loadRules error: $e');
      _rules = _buildDefaultRules();
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Save rules to SharedPreferences.
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_rules.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('AutomationService._save error: $e');
    }
  }

  /// Force-save (public, for external callers).
  Future<void> saveRules() => _save();

  /// Delete all rules and clear storage.
  Future<void> clearAll() async {
    _rules.clear();
    _recentTriggers.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Default Rules
  // ---------------------------------------------------------------------------

  /// Build a set of useful default automation rules.
  List<AutomationRule> _buildDefaultRules() {
    return [
      AutomationRule(
        id: 'default-mist-trigger',
        name: 'Mist Trigger',
        sensorIndex: 1, // Humidity
        condition: RuleCondition.lessThan,
        thresholdValue: 40.0,
        action: RuleAction.sendCommand,
        commandString: 'MIST_ON',
        isEnabled: true,
        cooldownSeconds: 300,
        description:
            'Activates the misting system when humidity drops below 40%. Prevents the terrarium from drying out.',
      ),
      AutomationRule(
        id: 'default-overheat-protection',
        name: 'Overheating Protection',
        sensorIndex: 0, // Temperature
        condition: RuleCondition.greaterThan,
        thresholdValue: 32.0,
        action: RuleAction.sendCommand,
        commandString: 'FAN_ON',
        isEnabled: true,
        cooldownSeconds: 120,
        description:
            'Turns on the cooling fan when temperature exceeds 32°C. Protects plants from heat stress.',
      ),
      AutomationRule(
        id: 'default-night-optimization',
        name: 'Low Moisture Alert',
        sensorIndex: 3, // Soil Moisture
        condition: RuleCondition.lessThan,
        thresholdValue: 200.0,
        action: RuleAction.triggerAlert,
        commandString: '',
        isEnabled: true,
        cooldownSeconds: 600,
        description:
            'Sends an alert when soil moisture drops below 200 pts, indicating the terrarium needs watering.',
      ),
      AutomationRule(
        id: 'default-nutrient-watch',
        name: 'Nutrient Deficiency Watch',
        sensorIndex: 2, // NPK
        condition: RuleCondition.lessThan,
        thresholdValue: 50.0,
        action: RuleAction.triggerAlert,
        commandString: '',
        isEnabled: false,
        cooldownSeconds: 1800,
        description:
            'Alerts when soil NPK levels fall below 50 mg/kg. Indicates fertilization may be needed.',
      ),
    ];
  }
}
