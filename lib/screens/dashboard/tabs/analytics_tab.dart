import 'package:flutter/material.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/redesign/glass_card.dart';
import '../../../widgets/redesign/section_header.dart';
import '../../../widgets/sensor_chart.dart';

class AnalyticsTab extends StatelessWidget {
  final Map<int, List<SensorLog>> sensorHistory;
  final int rangeIndex;
  final ValueChanged<int> onRangeChanged;

  const AnalyticsTab({
    super.key,
    required this.sensorHistory,
    required this.rangeIndex,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final moistureLogs = sensorHistory[2] ?? [];
    final tempLogs = sensorHistory[0] ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        const Text(
          'Analytics',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        PillSelector(
          options: const ['1H', '6H', '24H', '7D', 'Custom'],
          selectedIndex: rangeIndex,
          onSelected: onRangeChanged,
        ),
        const SizedBox(height: 24),
        HighTechSensorChart(
          title: 'Soil Moisture History',
          subtitle: chartStatsSubtitle(moistureLogs, ' pts'),
          logs: moistureLogs,
          primaryColor: AppColors.moisture,
          unit: ' pts',
          height: 180,
        ),
        const SizedBox(height: 16),
        HighTechSensorChart(
          title: 'Temperature Profile',
          subtitle: chartStatsSubtitle(tempLogs, '°C'),
          logs: tempLogs,
          primaryColor: AppColors.temperature,
          unit: '°C',
          height: 180,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(label: 'Export CSV', onTap: () {}),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionButton(label: 'Advanced Options', onTap: () {}),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        gradient: false,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
