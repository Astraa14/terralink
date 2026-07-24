import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/automation_rule.dart';

/// Full-screen editor for creating or editing an automation rule.
class RuleEditorScreen extends StatefulWidget {
  /// Pass an existing rule to edit, or null to create a new one.
  final AutomationRule? existingRule;

  const RuleEditorScreen({super.key, this.existingRule});

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _commandController;
  late TextEditingController _thresholdController;
  late TextEditingController _thresholdMaxController;

  late int _selectedSensor;
  late RuleCondition _selectedCondition;
  late RuleAction _selectedAction;
  late int _cooldownSeconds;
  late bool _isEnabled;

  bool get _isEditing => widget.existingRule != null;

  // Slider ranges per sensor
  static const _sensorRanges = [
    [0.0, 50.0],   // Temperature
    [0.0, 100.0],  // Humidity
    [0.0, 500.0],  // NPK
    [0.0, 1000.0], // Soil Moisture
  ];

  static const _cooldownOptions = [
    (30, '30 seconds'),
    (60, '1 minute'),
    (120, '2 minutes'),
    (300, '5 minutes'),
    (600, '10 minutes'),
    (1800, '30 minutes'),
    (3600, '1 hour'),
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.existingRule;
    _nameController = TextEditingController(text: r?.name ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _commandController = TextEditingController(text: r?.commandString ?? '');
    _thresholdController = TextEditingController(
      text: r != null ? r.thresholdValue.toStringAsFixed(1) : '',
    );
    _thresholdMaxController = TextEditingController(
      text: r != null ? r.thresholdMax.toStringAsFixed(1) : '',
    );
    _selectedSensor = r?.sensorIndex ?? 0;
    _selectedCondition = r?.condition ?? RuleCondition.greaterThan;
    _selectedAction = r?.action ?? RuleAction.sendCommand;
    _cooldownSeconds = r?.cooldownSeconds ?? 60;
    _isEnabled = r?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _commandController.dispose();
    _thresholdController.dispose();
    _thresholdMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1E2022)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Rule' : 'New Rule',
          style: const TextStyle(
            color: Color(0xFF1E2022),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _handleSave,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1F2E22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: Text(
                _isEditing ? 'Update' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rule Name
              _buildSectionLabel('Rule Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g. Overheating Protection',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a rule name'
                    : null,
              ),
              const SizedBox(height: 24),

              // Sensor Selector
              _buildSectionLabel('Sensor'),
              const SizedBox(height: 10),
              _buildSensorSelector(),
              const SizedBox(height: 24),

              // Condition
              _buildSectionLabel('Condition'),
              const SizedBox(height: 10),
              _buildConditionSelector(),
              const SizedBox(height: 16),

              // Threshold Value
              _buildSectionLabel('Threshold Value'),
              const SizedBox(height: 8),
              _buildThresholdInput(),
              const SizedBox(height: 24),

              // Action
              _buildSectionLabel('Action'),
              const SizedBox(height: 10),
              _buildActionSelector(),
              const SizedBox(height: 16),

              // Command String (visible for relevant actions)
              if (_selectedAction == RuleAction.sendCommand ||
                  _selectedAction == RuleAction.enableDevice ||
                  _selectedAction == RuleAction.disableDevice) ...[
                _buildSectionLabel('Command / Device ID'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _commandController,
                  hint: 'e.g. FAN_ON, MIST_OFF, PUMP_1',
                  validator: (v) {
                    if (_selectedAction != RuleAction.triggerAlert &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Please enter a command';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Cooldown
              _buildSectionLabel('Cooldown Period'),
              const SizedBox(height: 10),
              _buildCooldownSelector(),
              const SizedBox(height: 24),

              // Description
              _buildSectionLabel('Description (optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Describe what this rule does...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Enabled toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isEnabled
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _isEnabled
                          ? const Color(0xFF388E3C)
                          : Colors.grey.shade400,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Enable this rule immediately',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _isEnabled,
                      onChanged: (v) => setState(() => _isEnabled = v),
                      activeColor: const Color(0xFF388E3C),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section Label
  // ---------------------------------------------------------------------------
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8A9099),
        letterSpacing: 0.3,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text Field
  // ---------------------------------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E2022)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF388E3C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sensor Selector (4-grid)
  // ---------------------------------------------------------------------------
  Widget _buildSensorSelector() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: List.generate(4, (index) {
        final sensor = SensorMeta.get(index);
        final isSelected = _selectedSensor == index;
        final bg = Color(sensor.colorBg);
        final fg = Color(sensor.colorText);
        return GestureDetector(
          onTap: () => setState(() {
            _selectedSensor = index;
            // Reset threshold when switching sensor
            _thresholdController.clear();
            _thresholdMaxController.clear();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? bg : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? fg.withOpacity(0.4) : const Color(0xFFE8EAED),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              children: [
                Text(sensor.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sensor.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? fg : const Color(0xFF3D4249),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: fg, size: 18),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Condition Selector
  // ---------------------------------------------------------------------------
  Widget _buildConditionSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RuleCondition.values.map((cond) {
        final isSelected = _selectedCondition == cond;
        return GestureDetector(
          onTap: () => setState(() => _selectedCondition = cond),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1F2E22) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1F2E22)
                    : const Color(0xFFE8EAED),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cond.symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF3D4249),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cond.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF3D4249),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Threshold Input (with slider)
  // ---------------------------------------------------------------------------
  Widget _buildThresholdInput() {
    final range = _sensorRanges[_selectedSensor];
    final sensor = SensorMeta.get(_selectedSensor);
    final currentVal = double.tryParse(_thresholdController.text) ?? range[0];
    final clampedVal = currentVal.clamp(range[0], range[1]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _thresholdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2022),
                  ),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    hintStyle: TextStyle(color: Colors.grey.shade300),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    suffixText: sensor.unit,
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      color: Color(sensor.colorText),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null) return 'Invalid number';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_selectedCondition == RuleCondition.between) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '—',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _thresholdMaxController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2022),
                    ),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      hintStyle: TextStyle(color: Colors.grey.shade300),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      suffixText: sensor.unit,
                      suffixStyle: TextStyle(
                        fontSize: 14,
                        color: Color(sensor.colorText),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    validator: (v) {
                      if (_selectedCondition != RuleCondition.between) return null;
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Color(sensor.colorText),
              inactiveTrackColor: Color(sensor.colorText).withOpacity(0.12),
              thumbColor: Color(sensor.colorText),
              overlayColor: Color(sensor.colorText).withOpacity(0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              min: range[0],
              max: range[1],
              value: clampedVal,
              onChanged: (v) {
                setState(() {
                  _thresholdController.text = v.toStringAsFixed(1);
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${range[0].toStringAsFixed(0)} ${sensor.unit}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                '${range[1].toStringAsFixed(0)} ${sensor.unit}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Selector
  // ---------------------------------------------------------------------------
  Widget _buildActionSelector() {
    return Column(
      children: RuleAction.values.map((action) {
        final isSelected = _selectedAction == action;
        return GestureDetector(
          onTap: () => setState(() => _selectedAction = action),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF388E3C).withOpacity(0.3)
                    : const Color(0xFFE8EAED),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _actionIconData(action),
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF388E3C)
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1E2022)
                          : const Color(0xFF3D4249),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF388E3C),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _actionIconData(RuleAction action) {
    switch (action) {
      case RuleAction.sendCommand:
        return Icons.bluetooth_rounded;
      case RuleAction.triggerAlert:
        return Icons.notifications_active_outlined;
      case RuleAction.enableDevice:
        return Icons.power_settings_new_rounded;
      case RuleAction.disableDevice:
        return Icons.power_off_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // Cooldown Selector
  // ---------------------------------------------------------------------------
  Widget _buildCooldownSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cooldownOptions.map((opt) {
        final isSelected = _cooldownSeconds == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _cooldownSeconds = opt.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1F2E22) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1F2E22)
                    : const Color(0xFFE8EAED),
              ),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF3D4249),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Save Handler
  // ---------------------------------------------------------------------------
  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final threshold = double.tryParse(_thresholdController.text) ?? 0.0;
    final thresholdMax = double.tryParse(_thresholdMaxController.text) ?? 0.0;

    final rule = AutomationRule(
      id: widget.existingRule?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      sensorIndex: _selectedSensor,
      condition: _selectedCondition,
      thresholdValue: threshold,
      thresholdMax: thresholdMax,
      action: _selectedAction,
      commandString: _commandController.text.trim(),
      isEnabled: _isEnabled,
      cooldownSeconds: _cooldownSeconds,
      lastTriggered: widget.existingRule?.lastTriggered,
      description: _descriptionController.text.trim(),
    );

    Navigator.pop(context, rule);
  }
}
