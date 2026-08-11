import 'package:flutter/material.dart';
import '../../../services/automation_engine.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/redesign/glass_card.dart';
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Automation',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Master',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                TerraSwitch(
                  value: master,
                  onChanged: engine.toggleSmartAutomation,
                ),
              ],
            ),
          ],
        ),
        if (!master) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Text('⚠️', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All automation rules are currently paused.',
                    style: TextStyle(color: AppColors.warning, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _RuleCard(
          title: 'Auto-Irrigation',
          description: 'Activate pump when moisture < ${_fmt(engine.soilMoistureMinThreshold)} pts',
          command: 'PUMP:ON',
          enabled: engine.isIrrigationTriggerEnabled && master,
          value: engine.soilMoistureMinThreshold,
          min: 50,
          max: 600,
          onToggle: (v) => engine.updateIrrigationRule(enabled: v),
          onValueChanged: (v) => engine.updateIrrigationRule(threshold: v),
        ),
        const SizedBox(height: 16),
        _RuleCard(
          title: 'Cooling Fans',
          description: 'Turn on fans when temp > ${_fmt(engine.overheatTempThreshold)}°C',
          command: 'FAN:ON',
          enabled: engine.isOverheatingProtectionEnabled && master,
          value: engine.overheatTempThreshold,
          min: 25,
          max: 45,
          onToggle: (v) => engine.updateOverheatRule(enabled: v),
          onValueChanged: (v) => engine.updateOverheatRule(threshold: v),
        ),
        const SizedBox(height: 16),
        _RuleCard(
          title: 'Mist Sprinklers',
          description: 'Activate mist when humidity < ${_fmt(engine.mistHumidityThreshold)}%',
          command: 'MIST:ON',
          enabled: engine.isMistTriggerEnabled && master,
          value: engine.mistHumidityThreshold,
          min: 20,
          max: 90,
          onToggle: (v) => engine.updateMistRule(enabled: v),
          onValueChanged: (v) => engine.updateMistRule(threshold: v),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Night Mode Optimization',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Reduces sensor polling between 10 PM – 6 AM',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TerraSwitch(
                value: engine.isNightOptimizationEnabled,
                onChanged: (v) => engine.updateNightRule(enabled: v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'TRANSMISSION LOG',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 180,
            child: commandLogs.isEmpty
                ? const Center(
                    child: Text(
                      'No commands sent yet',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    itemCount: commandLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final line = commandLogs[i];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              _extractTime(line),
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              line,
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const Text(
                            'SUCCESS',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(0);

  static String _extractTime(String line) {
    if (line.length >= 8 && line.contains(':')) {
      return line.substring(0, 8);
    }
    return '--:--:--';
  }
}

class _RuleCard extends StatelessWidget {
  final String title;
  final String description;
  final String command;
  final bool enabled;
  final double value;
  final double min;
  final double max;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onValueChanged;

  const _RuleCard({
    required this.title,
    required this.description,
    required this.command,
    required this.enabled,
    required this.value,
    required this.min,
    required this.max,
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TerraSwitch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Threshold Configuration',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Text(
                        command,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
