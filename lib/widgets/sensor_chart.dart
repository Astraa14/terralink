import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import 'redesign/glass_card.dart';

class HighTechSensorChart extends StatelessWidget {
  final List<SensorLog> logs;
  final Color primaryColor;
  final String unit;
  final String title;
  final String? subtitle;
  final double height;
  final bool bare;

  const HighTechSensorChart({
    super.key,
    required this.logs,
    required this.primaryColor,
    required this.unit,
    required this.title,
    this.subtitle,
    this.height = 160,
    this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (bare) return body;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: body,
    );
  }

  Widget _buildBody() {
    if (logs.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No sensor data available',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
          ),
        ),
      );
    }

    final minVal = logs.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxVal = logs.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final padding = (maxVal - minVal) == 0 ? 5.0 : (maxVal - minVal) * 0.25;

    final spots = logs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty || subtitle != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Now: ${logs.last.value.toStringAsFixed(logs.last.value.abs() < 10 ? 2 : 1)}$unit',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        if (title.isNotEmpty || subtitle != null) const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: (minVal - padding).clamp(0, double.infinity),
              maxY: maxVal + padding,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(v.abs() < 10 ? 1 : 0),
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx >= 0 && idx < logs.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            logs[idx].timeLabel,
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: primaryColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.3),
                        primaryColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xCC09090B),
                  getTooltipItems: (spots) => spots.map((s) {
                    return LineTooltipItem(
                      '${s.y.toStringAsFixed(s.y.abs() < 10 ? 2 : 1)}$unit',
                      const TextStyle(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String chartStatsSubtitle(List<SensorLog> logs, String unit) {
  if (logs.isEmpty) return '';
  final values = logs.map((e) => e.value).toList();
  final avg = values.reduce((a, b) => a + b) / values.length;
  final min = values.reduce((a, b) => a < b ? a : b);
  final max = values.reduce((a, b) => a > b ? a : b);
  final fmt = (double v) => v.toStringAsFixed(v.abs() < 10 ? 2 : 1);
  return 'Average: ${fmt(avg)}$unit • Min: ${fmt(min)}$unit • Max: ${fmt(max)}$unit';
}
