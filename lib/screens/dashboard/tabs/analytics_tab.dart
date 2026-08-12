import 'dart:math';
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
    final tempLogs = sensorHistory[0] ?? [];
    final humidityLogs = sensorHistory[1] ?? [];
    final moistureLogs = sensorHistory[2] ?? [];
    final npkLogs = sensorHistory[3] ?? [];
    final phLogs = sensorHistory[4] ?? [];
    final ecLogs = sensorHistory[5] ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        const Text(
          'Farm Analytics',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Crop-ready interpretation of soil and field trends.',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        PillSelector(
          options: const ['1H', '6H', '24H', '7D', 'Custom'],
          selectedIndex: rangeIndex,
          onSelected: onRangeChanged,
        ),
        const SizedBox(height: 22),
        _DecisionCard(
          moisture: _lastValue(moistureLogs),
          temperature: _lastValue(tempLogs),
          npk: _lastValue(npkLogs),
          ph: _lastValue(phLogs),
        ),
        const SizedBox(height: 18),
        _SoilRadarCard(
          moisture: _lastValue(moistureLogs),
          ph: _lastValue(phLogs),
          npk: _lastValue(npkLogs),
          ec: _lastValue(ecLogs),
        ),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Soil Health',
          subtitle: 'Moisture, chemistry, conductivity, nutrients',
          icon: Icons.layers_outlined,
        ),
        const SizedBox(height: 14),
        HighTechSensorChart(
          title: 'Soil Moisture History',
          subtitle: '${chartStatsSubtitle(moistureLogs, ' pts')} - irrigation can wait when the line stays inside the blue band.',
          logs: moistureLogs,
          primaryColor: AppColors.moisture,
          unit: ' pts',
          referenceMin: 300,
          referenceMax: 640,
          referenceLabel: 'Target 300-640 pts',
          eventMarkerIndices: const [2, 4],
          height: 190,
        ),
        const SizedBox(height: 16),
        HighTechSensorChart(
          title: 'Soil pH',
          subtitle: '${chartStatsSubtitle(phLogs, '')} - most crops prefer a steady 5.8-7.2 band.',
          logs: phLogs,
          primaryColor: AppColors.ph,
          unit: '',
          referenceMin: 5.8,
          referenceMax: 7.2,
          referenceLabel: 'Common crop range',
          eventMarkerIndices: const [4],
          height: 160,
        ),
        const SizedBox(height: 16),
        HighTechSensorChart(
          title: 'NPK Nutrients',
          subtitle: '${chartStatsSubtitle(npkLogs, ' mg/kg')} - declining nutrient trend suggests a feeding review.',
          logs: npkLogs,
          primaryColor: AppColors.npk,
          unit: ' mg/kg',
          referenceMin: 230,
          referenceMax: 520,
          referenceLabel: 'Nutrient target',
          height: 160,
        ),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Environmental Factors',
          subtitle: 'Air movement, heat, and humidity pressure',
          icon: Icons.wb_sunny_outlined,
        ),
        const SizedBox(height: 14),
        HighTechSensorChart(
          title: 'Temperature Profile',
          subtitle: '${chartStatsSubtitle(tempLogs, '°C')} - watch afternoon peaks above crop comfort.',
          logs: tempLogs,
          primaryColor: AppColors.temperature,
          unit: '°C',
          referenceMin: 18,
          referenceMax: 30,
          referenceLabel: 'Crop comfort band',
          height: 170,
        ),
        const SizedBox(height: 16),
        HighTechSensorChart(
          title: 'Humidity Profile',
          subtitle: '${chartStatsSubtitle(humidityLogs, '%')} - canopy humidity is in range when held inside the cyan band.',
          logs: humidityLogs,
          primaryColor: AppColors.humidity,
          unit: '%',
          referenceMin: 40,
          referenceMax: 75,
          referenceLabel: 'Canopy target',
          eventMarkerIndices: const [3],
          height: 160,
        ),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Soil Health Timeline',
          subtitle: 'Actions and notable field events',
          icon: Icons.event_note_outlined,
        ),
        const SizedBox(height: 14),
        const _TimelineCard(),
        const SizedBox(height: 18),
        const _FieldNoteCard(),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'CSV',
                icon: Icons.table_chart_outlined,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Email',
                icon: Icons.mail_outline,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  static double _lastValue(List<SensorLog> logs) {
    return logs.isEmpty ? 0 : logs.last.value;
  }
}

class _DecisionCard extends StatelessWidget {
  final double moisture;
  final double temperature;
  final double npk;
  final double ph;

  const _DecisionCard({
    required this.moisture,
    required this.temperature,
    required this.npk,
    required this.ph,
  });

  @override
  Widget build(BuildContext context) {
    final message = _message;
    final color = _color;

    return GlassCard(
      gradient: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.agriculture_outlined, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Field Decision',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _message {
    if (moisture > 0 && moisture < 240) {
      return 'Soil moisture is low. At current temperature, irrigation should be planned soon.';
    }
    if (temperature > 32) {
      return 'Temperature is putting pressure on the root zone. Check cooling or shade timing.';
    }
    if (npk > 0 && npk < 230) {
      return 'NPK is trending light. Consider nutrient application during the next field pass.';
    }
    if (ph > 0 && (ph < 5.5 || ph > 7.5)) {
      return 'pH sits outside a common crop range. Review amendment needs before planting.';
    }
    return 'Moisture, temperature, pH, and nutrient levels support normal field operations.';
  }

  Color get _color {
    if (moisture > 0 && moisture < 240) return AppColors.moisture;
    if (temperature > 32) return AppColors.temperature;
    if (npk > 0 && npk < 230) return AppColors.npk;
    if (ph > 0 && (ph < 5.5 || ph > 7.5)) return AppColors.ph;
    return AppColors.primary;
  }
}

class _SoilRadarCard extends StatelessWidget {
  final double moisture;
  final double ph;
  final double npk;
  final double ec;

  const _SoilRadarCard({
    required this.moisture,
    required this.ph,
    required this.npk,
    required this.ec,
  });

  @override
  Widget build(BuildContext context) {
    final values = [
      _score(moisture, 300, 640, 50, 800),
      _score(ph, 5.8, 7.2, 4, 9),
      _score(npk, 230, 520, 100, 900),
      _score(ec, 0.8, 2.4, 0.1, 5),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: CustomPaint(
              painter: _RadarPainter(values: values),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soil Balance Radar',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Moisture, pH, nutrients, and conductivity are normalized against common crop targets.',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double _score(
    double value,
    double targetMin,
    double targetMax,
    double min,
    double max,
  ) {
    if (value <= 0) return 0.45;
    if (value >= targetMin && value <= targetMax) return 1;
    final distance = value < targetMin ? targetMin - value : value - targetMax;
    final span = value < targetMin ? targetMin - min : max - targetMax;
    return (1 - distance / span).clamp(0.15, 1.0).toDouble();
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;

  const _RadarPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 12;
    final labels = ['H2O', 'pH', 'NPK', 'EC'];
    final colors = [
      AppColors.moisture,
      AppColors.ph,
      AppColors.npk,
      AppColors.conductivity,
    ];

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final scale in [0.35, 0.7, 1.0]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final angle = -1.5708 + i * 1.5708;
        final point = center + Offset(radius * scale * cos(angle), radius * scale * sin(angle));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final dataPath = Path();
    for (var i = 0; i < 4; i++) {
      final angle = -1.5708 + i * 1.5708;
      final value = values[i].clamp(0.0, 1.0).toDouble();
      final point = center + Offset(radius * value * cos(angle), radius * value * sin(angle));
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
      canvas.drawLine(center, center + Offset(radius * cos(angle), radius * sin(angle)), gridPaint);
      canvas.drawCircle(point, 3.5, Paint()..color = colors[i]);
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i],
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelPoint = center + Offset((radius + 10) * cos(angle), (radius + 10) * sin(angle));
      textPainter.paint(
        canvas,
        labelPoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('08:30', 'Irrigation pass recorded', Icons.water_drop_outlined, AppColors.moisture),
      ('12:10', 'Moisture stabilized in target band', Icons.check_circle_outline, AppColors.primary),
      ('15:45', 'Temperature peak marked for review', Icons.thermostat_outlined, AppColors.temperature),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 14),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.$4.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: item.$4.withValues(alpha: 0.28)),
                  ),
                  child: Icon(item.$3, color: item.$4, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FieldNoteCard extends StatelessWidget {
  const _FieldNoteCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_outlined, color: AppColors.softTan, size: 20),
              SizedBox(width: 8),
              Text(
                'Field Note',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Applied fertilizer, heavy rain, pest pressure...',
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        gradient: false,
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
