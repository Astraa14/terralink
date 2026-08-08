import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/sensor_service.dart';

// ---------------------------------------------------------------------------
// Design tokens (mirrored from dashboard)
// ---------------------------------------------------------------------------
class _C {
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E2022);
  static const Color textMuted = Color(0xFF8A9099);
  static const Color primaryGreen = Color(0xFF388E3C);

  static const List<Color> bgColors = [
    Color(0xFFFFF7F2),
    Color(0xFFF0F5FA),
    Color(0xFFFFFBEA),
    Color(0xFFEAF8F6),
  ];
  static const List<Color> textColors = [
    Color(0xFFE65100),
    Color(0xFF0288D1),
    Color(0xFFF57F17),
    Color(0xFF00796B),
  ];
  static const List<IconData> icons = [
    Icons.thermostat_rounded,
    Icons.water_drop_rounded,
    Icons.grass_rounded,
    Icons.opacity_rounded,
  ];
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedSensor = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: SensorIndex.count, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedSensor = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorService>();
    final logs = sensor.historyFor(_selectedSensor);
    final avg = sensor.averageFor(_selectedSensor);
    final mn = sensor.minFor(_selectedSensor);
    final mx = sensor.maxFor(_selectedSensor);
    final unit = SensorIndex.unit(_selectedSensor);
    final color = _C.textColors[_selectedSensor];
    final bgColor = _C.bgColors[_selectedSensor];

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _C.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${logs.length} readings',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '5-hour sensor history',
              style: TextStyle(
                fontSize: 13,
                color: _C.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sensor tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: _C.textMuted,
                indicator: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                tabs: List.generate(SensorIndex.count, (i) {
                  return Tab(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_C.icons[i], size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            SensorIndex.label(i).split(' ').first,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatChip(
                  label: 'Avg',
                  value: '${avg.toStringAsFixed(1)}$unit',
                  color: color,
                  bgColor: bgColor,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Min',
                  value: '${mn.toStringAsFixed(1)}$unit',
                  color: const Color(0xFF0288D1),
                  bgColor: const Color(0xFFF0F5FA),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Max',
                  value: '${mx.toStringAsFixed(1)}$unit',
                  color: const Color(0xFFE65100),
                  bgColor: const Color(0xFFFFF7F2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chart placeholder area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_C.icons[_selectedSensor],
                              size: 36, color: color.withValues(alpha: 0.3)),
                          const SizedBox(height: 8),
                          Text(
                            'No data yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: color.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enable demo mode or connect a sensor',
                            style: TextStyle(
                              fontSize: 11,
                              color: _C.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _MiniChart(
                      logs: logs,
                      color: color,
                      unit: unit,
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // History list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  'Last 5 hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: _C.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // History list
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'No readings recorded',
                      style: TextStyle(
                        fontSize: 14,
                        color: _C.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    physics: const BouncingScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, i) {
                      // Show most recent first
                      final log = logs[logs.length - 1 - i];
                      final alert = sensor.alerts[_selectedSensor];
                      final isBreached = alert.enabled &&
                          (alert.greaterThan
                              ? log.value > alert.threshold
                              : log.value < alert.threshold);

                      return _HistoryTile(
                        time: log.timeLabel,
                        value: log.value.toStringAsFixed(1),
                        unit: unit,
                        color: color,
                        isAlert: isBreached,
                        index: i,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat chip
// ---------------------------------------------------------------------------
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini chart — simple custom-painted sparkline
// ---------------------------------------------------------------------------
class _MiniChart extends StatelessWidget {
  final List<SensorLog> logs;
  final Color color;
  final String unit;

  const _MiniChart({
    required this.logs,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: const Size(double.infinity, 168),
        painter: _SparklinePainter(
          values: logs.map((l) => l.value).toList(),
          color: color,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final mn = values.reduce((a, b) => a < b ? a : b);
    final mx = values.reduce((a, b) => a > b ? a : b);
    final range = mx - mn == 0 ? 1.0 : mx - mn;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - mn) / range) * (size.height - 20) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Smooth curve using cubic bezier
        final prevX =
            ((i - 1) / (values.length - 1)) * size.width;
        final prevY = size.height -
            ((values[i - 1] - mn) / range) * (size.height - 20) -
            10;
        final cpx = (prevX + x) / 2;
        path.cubicTo(cpx, prevY, cpx, y, x, y);
        fillPath.cubicTo(cpx, prevY, cpx, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw last point
    if (values.isNotEmpty) {
      final lastX = size.width;
      final lastY = size.height -
          ((values.last - mn) / range) * (size.height - 20) -
          10;
      canvas.drawCircle(
        Offset(lastX, lastY),
        4,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        6,
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// History tile
// ---------------------------------------------------------------------------
class _HistoryTile extends StatelessWidget {
  final String time;
  final String value;
  final String unit;
  final Color color;
  final bool isAlert;
  final int index;

  const _HistoryTile({
    required this.time,
    required this.value,
    required this.unit,
    required this.color,
    required this.isAlert,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isAlert
            ? Colors.red.withOpacity(0.04)
            : _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: isAlert
            ? Border.all(color: Colors.red.withOpacity(0.12))
            : null,
        boxShadow: [
          if (!isAlert)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        children: [
          // Time
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Value
          Expanded(
            child: Text(
              '$value $unit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isAlert ? Colors.red : _C.textDark,
              ),
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAlert
                  ? Colors.red.withOpacity(0.1)
                  : _C.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAlert) ...[
                  const Icon(Icons.warning_amber_rounded,
                      size: 12, color: Colors.red),
                  const SizedBox(width: 3),
                ],
                Text(
                  isAlert ? 'Alert' : 'Normal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAlert ? Colors.red : _C.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
