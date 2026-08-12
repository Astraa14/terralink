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
  final double? referenceMin;
  final double? referenceMax;
  final String? referenceLabel;
  final List<int> eventMarkerIndices;

  const HighTechSensorChart({
    super.key,
    required this.logs,
    required this.primaryColor,
    required this.unit,
    required this.title,
    this.subtitle,
    this.height = 160,
    this.bare = false,
    this.referenceMin,
    this.referenceMax,
    this.referenceLabel,
    this.eventMarkerIndices = const [],
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
    final chartMinY = (minVal - padding).clamp(0, double.infinity).toDouble();
    final chartMaxY = maxVal + padding;

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
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 0,
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.22)),
                    ),
                    child: Text(
                      'Now: ${logs.last.value.toStringAsFixed(logs.last.value.abs() < 10 ? 2 : 1)}$unit',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (referenceLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      referenceLabel!,
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        if (title.isNotEmpty || subtitle != null) const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: Stack(
            children: [
              if (referenceMin != null && referenceMax != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ReferenceZonePainter(
                      minY: chartMinY,
                      maxY: chartMaxY,
                      referenceMin: referenceMin!,
                      referenceMax: referenceMax!,
                      color: primaryColor,
                    ),
                  ),
                ),
              if (eventMarkerIndices.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EventMarkerPainter(
                      count: logs.length,
                      indices: eventMarkerIndices,
                    ),
                  ),
                ),
              LineChart(
                LineChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withValues(alpha: 0.07),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(v.abs() < 10 ? 1 : 0),
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
                                  fontWeight: FontWeight.w600,
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
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.28),
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
                      getTooltipColor: (_) => const Color(0xE6080A07),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _ReferenceZonePainter extends CustomPainter {
  final double minY;
  final double maxY;
  final double referenceMin;
  final double referenceMax;
  final Color color;

  const _ReferenceZonePainter({
    required this.minY,
    required this.maxY,
    required this.referenceMin,
    required this.referenceMax,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final range = maxY - minY;
    if (range <= 0) return;

    final top = size.height *
        (1 - ((referenceMax - minY) / range)).clamp(0.0, 1.0).toDouble();
    final bottom = size.height *
        (1 - ((referenceMin - minY) / range)).clamp(0.0, 1.0).toDouble();

    final paint = Paint()..color = color.withValues(alpha: 0.09);
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(34, top, size.width, bottom),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawLine(Offset(34, top), Offset(size.width, top), borderPaint);
    canvas.drawLine(Offset(34, bottom), Offset(size.width, bottom), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ReferenceZonePainter oldDelegate) {
    return oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.referenceMin != referenceMin ||
        oldDelegate.referenceMax != referenceMax ||
        oldDelegate.color != color;
  }
}

class _EventMarkerPainter extends CustomPainter {
  final int count;
  final List<int> indices;

  const _EventMarkerPainter({
    required this.count,
    required this.indices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 1) return;

    final paint = Paint()
      ..color = AppColors.softTan.withValues(alpha: 0.22)
      ..strokeWidth = 1;

    for (final index in indices) {
      if (index < 0 || index >= count) continue;
      final x = 34 + ((size.width - 34) * index / (count - 1));
      for (var y = 8.0; y < size.height - 24; y += 9) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 4), paint);
      }
      canvas.drawCircle(Offset(x, 8), 3, Paint()..color = AppColors.softTan);
    }
  }

  @override
  bool shouldRepaint(covariant _EventMarkerPainter oldDelegate) {
    return oldDelegate.count != count || oldDelegate.indices != indices;
  }
}

String chartStatsSubtitle(List<SensorLog> logs, String unit) {
  if (logs.isEmpty) return '';
  final values = logs.map((e) => e.value).toList();
  final avg = values.reduce((a, b) => a + b) / values.length;
  final min = values.reduce((a, b) => a < b ? a : b);
  final max = values.reduce((a, b) => a > b ? a : b);
  String fmt(double v) => v.toStringAsFixed(v.abs() < 10 ? 2 : 1);
  return 'Avg ${fmt(avg)}$unit • Min ${fmt(min)}$unit • Max ${fmt(max)}$unit';
}
