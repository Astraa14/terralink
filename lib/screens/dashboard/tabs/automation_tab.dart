import 'package:flutter/material.dart';
import '../../../services/automation_engine.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/redesign/glass_card.dart';
import '../../../widgets/redesign/section_header.dart';
import '../../../widgets/redesign/terra_badge.dart';
import '../../../widgets/redesign/terra_switch.dart';

class AutomationTab extends StatelessWidget {
  final AutomationEngineService engine;
  final List<String> commandLogs;

  const AutomationTab({
    super.key,
    required this.engine,
    required this.commandLogs,
  });

  @override
  Widget build(BuildContext context) {
    final master = engine.isSmartAutomationEnabled;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm Automation',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Rules shaped around water, climate, nutrients, and power.',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _MasterControl(
              enabled: master,
              onChanged: engine.toggleSmartAutomation,
            ),
          ],
        ),
        if (!master) ...[
          const SizedBox(height: 16),
          const _PausedBanner(),
        ],
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Preset Practices',
          subtitle: 'Quick templates farmers commonly start from',
          icon: Icons.bookmark_add_outlined,
        ),
        const SizedBox(height: 12),
        const _PresetTemplates(),
        const SizedBox(height: 24),
        _RuleCard(
          category: 'Water Management',
          title: 'Irrigation Pump',
          description:
              'When soil moisture drops below ${_fmt(engine.soilMoistureMinThreshold)} pts, activate irrigation.',
          reasoning:
              'Typical loam holds usable water for several days above this band; below it, roots can stress quickly in heat.',
          command: 'PUMP:ON',
          equipmentIcon: Icons.water_drop_outlined,
          accentColor: AppColors.moisture,
          enabled: engine.isIrrigationTriggerEnabled && master,
          value: engine.soilMoistureMinThreshold,
          min: 50,
          max: 600,
          unit: 'pts',
          onToggle: (v) => engine.updateIrrigationRule(enabled: v),
          onValueChanged: (v) => engine.updateIrrigationRule(threshold: v),
        ),
        const SizedBox(height: 16),
        _RuleCard(
          category: 'Climate Control',
          title: 'Ventilation Fans',
          description:
              'When temperature rises above ${_fmt(engine.overheatTempThreshold)}°C, run fans.',
          reasoning:
              'Moving air reduces heat stress and keeps leaf and root-zone conditions steadier through afternoon peaks.',
          command: 'FAN:ON',
          equipmentIcon: Icons.air_outlined,
          accentColor: AppColors.temperature,
          enabled: engine.isOverheatingProtectionEnabled && master,
          value: engine.overheatTempThreshold,
          min: 25,
          max: 45,
          unit: '°C',
          onToggle: (v) => engine.updateOverheatRule(enabled: v),
          onValueChanged: (v) => engine.updateOverheatRule(threshold: v),
        ),
        const SizedBox(height: 16),
        _RuleCard(
          category: 'Climate Control',
          title: 'Mist Sprinklers',
          description:
              'When humidity falls below ${_fmt(engine.mistHumidityThreshold)}%, activate misting.',
          reasoning:
              'Seedlings and tender crops benefit from short humidity boosts when dry air pulls moisture too fast.',
          command: 'MIST:ON',
          equipmentIcon: Icons.grain_outlined,
          accentColor: AppColors.humidity,
          enabled: engine.isMistTriggerEnabled && master,
          value: engine.mistHumidityThreshold,
          min: 20,
          max: 90,
          unit: '%',
          onToggle: (v) => engine.updateMistRule(enabled: v),
          onValueChanged: (v) => engine.updateMistRule(threshold: v),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.softTan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  border: Border.all(
                    color: AppColors.softTan.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.nightlight_outlined,
                  color: AppColors.softTan,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Power Efficiency',
                      style: TextStyle(
                        color: AppColors.softTan,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Night Sensor Optimization',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Reduces sensor polling between 10 PM and 6 AM when the field is stable.',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TerraSwitch(
                value: engine.isNightOptimizationEnabled && master,
                onChanged: master ? (v) => engine.updateNightRule(enabled: v) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Simulation',
          subtitle: 'What these rules would have done yesterday',
          icon: Icons.play_circle_outline,
        ),
        const SizedBox(height: 12),
        _SimulationCard(engine: engine, master: master),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Farm Activity Log',
          subtitle: 'Readable equipment actions from Bluetooth commands',
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 12),
        _ActivityLog(commandLogs: commandLogs),
      ],
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(0);
}

class _MasterControl extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _MasterControl({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          TerraSwitch(value: enabled, onChanged: onChanged),
          const SizedBox(height: 6),
          Text(
            enabled ? 'Active' : 'Paused',
            style: TextStyle(
              color: enabled ? AppColors.primary : AppColors.statusOrange,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.statusOrange.withValues(alpha: 0.26)),
      ),
      child: const Row(
        children: [
          Icon(Icons.pause_circle_outline, color: AppColors.statusOrange, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Automation is paused. Field rules will not activate equipment until the master control is active.',
              style: TextStyle(
                color: AppColors.statusOrange,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetTemplates extends StatelessWidget {
  const _PresetTemplates();

  @override
  Widget build(BuildContext context) {
    const presets = [
      ('Standard Irrigation', Icons.water_drop_outlined, AppColors.moisture),
      ('Cold Protection', Icons.ac_unit_outlined, AppColors.skyCyan),
      ('Seedling Humidity', Icons.grain_outlined, AppColors.humidity),
      ('Night Energy Save', Icons.nightlight_outlined, AppColors.softTan),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: presets.map((preset) {
        return Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: preset.$3.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(color: preset.$3.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(preset.$2, color: preset.$3, size: 18),
              const SizedBox(width: 8),
              Text(
                preset.$1,
                style: TextStyle(
                  color: preset.$3,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String category;
  final String title;
  final String description;
  final String reasoning;
  final String command;
  final IconData equipmentIcon;
  final Color accentColor;
  final bool enabled;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onValueChanged;

  const _RuleCard({
    required this.category,
    required this.title,
    required this.description,
    required this.reasoning,
    required this.command,
    required this.equipmentIcon,
    required this.accentColor,
    required this.enabled,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onToggle,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    border: Border.all(color: accentColor.withValues(alpha: 0.28)),
                  ),
                  child: Icon(equipmentIcon, color: accentColor, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                TerraSwitch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reasoning,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TerraBadge(
                      label: command.replaceAll(':', ' '),
                      variant: TerraBadgeVariant.outline,
                      icon: Icons.settings_input_component_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${value.toStringAsFixed(0)} $unit',
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: value,
                        min: min,
                        max: max,
                        divisions: ((max - min) / 5).round(),
                        onChanged: enabled ? onValueChanged : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationCard extends StatelessWidget {
  final AutomationEngineService engine;
  final bool master;

  const _SimulationCard({
    required this.engine,
    required this.master,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Irrigation',
        engine.isIrrigationTriggerEnabled && master ? 'Would run 2 short passes' : 'No action',
        AppColors.moisture,
        Icons.water_drop_outlined
      ),
      (
        'Fans',
        engine.isOverheatingProtectionEnabled && master ? 'Would cool afternoon peak' : 'No action',
        AppColors.temperature,
        Icons.air_outlined
      ),
      (
        'Misting',
        engine.isMistTriggerEnabled && master ? 'Would boost humidity once' : 'No action',
        AppColors.humidity,
        Icons.grain_outlined
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.$3.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                    border: Border.all(color: item.$3.withValues(alpha: 0.24)),
                  ),
                  child: Icon(item.$4, color: item.$3, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: item.$3,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActivityLog extends StatelessWidget {
  final List<String> commandLogs;

  const _ActivityLog({required this.commandLogs});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 190,
        child: commandLogs.isEmpty
            ? const Center(
                child: Text(
                  'No equipment actions recorded today',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: commandLogs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final line = commandLogs[i];
                  final event = _farmEvent(line);
                  return Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          _extractTime(line),
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: event.$2.withValues(alpha: 0.13),
                          shape: BoxShape.circle,
                          border: Border.all(color: event.$2.withValues(alpha: 0.24)),
                        ),
                        child: Icon(event.$3, color: event.$2, size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.$1,
                          style: const TextStyle(
                            color: AppColors.foreground,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const TerraBadge(
                        label: 'Done',
                        variant: TerraBadgeVariant.primary,
                        icon: Icons.check_rounded,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  static String _extractTime(String line) {
    final match = RegExp(r'\[(\d{2}:\d{2}:\d{2})\]').firstMatch(line);
    return match?.group(1)?.substring(0, 5) ?? '--:--';
  }

  static (String, Color, IconData) _farmEvent(String line) {
    if (line.contains('PUMP:ON')) {
      return ('Irrigation activated', AppColors.moisture, Icons.water_drop_outlined);
    }
    if (line.contains('PUMP:OFF')) {
      return ('Irrigation stopped', AppColors.moisture, Icons.water_drop_outlined);
    }
    if (line.contains('FAN:ON')) {
      return ('Ventilation fan started', AppColors.temperature, Icons.air_outlined);
    }
    if (line.contains('FAN:OFF')) {
      return ('Ventilation fan stopped', AppColors.temperature, Icons.air_outlined);
    }
    if (line.contains('MIST:ON')) {
      return ('Mist sprinklers activated', AppColors.humidity, Icons.grain_outlined);
    }
    if (line.contains('MIST:OFF')) {
      return ('Mist sprinklers stopped', AppColors.humidity, Icons.grain_outlined);
    }
    if (line.contains('NIGHT:ON')) {
      return ('Night efficiency mode started', AppColors.softTan, Icons.nightlight_outlined);
    }
    if (line.contains('NIGHT:OFF')) {
      return ('Night efficiency mode ended', AppColors.softTan, Icons.nightlight_outlined);
    }
    return ('System command recorded', AppColors.primary, Icons.settings_input_component_outlined);
  }
}
