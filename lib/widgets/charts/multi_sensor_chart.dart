import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'sensor_line_chart.dart' show SensorLog;

/// Overlay chart showing all 4 sensors normalized to 0-100% on one chart.
///
/// Each sensor is rendered as a distinct colored line for correlation analysis.
/// Values are normalized: actual_value / sensor_max * 100.
class MultiSensorChart extends StatefulWidget {
  /// Data for each sensor, indexed 0-3.
  /// Each list contains the sensor's history as SensorLog entries.
  final List<List<SensorLog>> sensorData;

  /// Which sensors to show (indices 0-3). Defaults to all.
  final List<int> visibleSensors;

  /// Chart height. Defaults to 260.
  final double height;

  /// Show the legend at the bottom.
  final bool showLegend;

  const MultiSensorChart({
    super.key,
    required this.sensorData,
    this.visibleSensors = const [0, 1, 2, 3],
    this.height = 260,
    this.showLegend = true,
  });

  @override
  State<MultiSensorChart> createState() => _MultiSensorChartState();
}

class _MultiSensorChartState extends State<MultiSensorChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<bool> _sensorVisible;

  static const _sensorColors = [
    Color(0xFFE65100), // Temperature
    Color(0xFF0288D1), // Humidity
    Color(0xFFF57F17), // NPK
    Color(0xFF00796B), // Soil Moisture
  ];

  static const _sensorNames = [
    'Temperature',
    'Humidity',
    'Soil NPK',
    'Soil Moisture',
  ];

  static const _sensorUnits = ['°C', '%', 'mg/kg', 'pts'];

  // Max values for normalization
  static const _sensorMax = [40.0, 100.0, 300.0, 800.0];

  static const _sensorIcons = ['🌡️', '💧', '🧪', '🌱'];

  @override
  void initState() {
    super.initState();
    _sensorVisible = List.generate(
      4,
      (i) => widget.visibleSensors.contains(i),
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant MultiSensorChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sensorData != widget.sensorData) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return LineChart(
                _buildChartData(),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ],
    );
  }

  LineChartData _buildChartData() {
    final animValue = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ).value;

    // Find the maximum number of data points across all sensors.
    int maxLength = 0;
    for (final data in widget.sensorData) {
      if (data.length > maxLength) maxLength = data.length;
    }
    if (maxLength == 0) maxLength = 1;

    // Build a line for each visible sensor.
    final lines = <LineChartBarData>[];
    for (int s = 0; s < 4; s++) {
      if (!_sensorVisible[s]) continue;
      if (s >= widget.sensorData.length) continue;

      final data = widget.sensorData[s];
      if (data.isEmpty) continue;

      final spots = <FlSpot>[];
      for (int i = 0; i < data.length; i++) {
        // Normalize to 0-100
        final normalized =
            (data[i].value / _sensorMax[s] * 100).clamp(0.0, 100.0);
        spots.add(FlSpot(i.toDouble(), normalized * animValue));
      }

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          color: _sensorColors[s],
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false, // Too many dots on multi-line chart
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Use the first visible sensor's data for time labels (or longest).
    List<SensorLog> labelSource = [];
    for (int s = 0; s < 4; s++) {
      if (s < widget.sensorData.length &&
          widget.sensorData[s].length > labelSource.length) {
        labelSource = widget.sensorData[s];
      }
    }

    return LineChartData(
      minY: 0,
      maxY: 105,
      minX: 0,
      maxX: (maxLength - 1).toDouble().clamp(1, double.infinity),
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFECEDF0),
          strokeWidth: 1,
          dashArray: [6, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 25,
            getTitlesWidget: (value, meta) {
              if (value == 0 || value > 100) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA0A5AD),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _xInterval(maxLength),
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= labelSource.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  labelSource[idx].timeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA0A5AD),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1F2E22),
          tooltipRoundedRadius: 10,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          maxContentWidth: 180,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              // Figure out which sensor this line belongs to.
              final lineIdx = spot.barIndex;
              int sensorIdx = -1;
              int counter = 0;
              for (int s = 0; s < 4; s++) {
                if (!_sensorVisible[s]) continue;
                if (s >= widget.sensorData.length) continue;
                if (widget.sensorData[s].isEmpty) continue;
                if (counter == lineIdx) {
                  sensorIdx = s;
                  break;
                }
                counter++;
              }
              if (sensorIdx == -1) return null;

              final dataIdx =
                  spot.x.toInt().clamp(0, widget.sensorData[sensorIdx].length - 1);
              final actualValue = widget.sensorData[sensorIdx][dataIdx].value;

              return LineTooltipItem(
                '${_sensorIcons[sensorIdx]} ${_sensorNames[sensorIdx]}\n',
                TextStyle(
                  color: _sensorColors[sensorIdx],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '${actualValue.toStringAsFixed(1)} ${_sensorUnits[sensorIdx]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((_) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: const Color(0xFFCCCCCC),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: barData.color ?? const Color(0xFF388E3C),
                ),
              ),
            );
          }).toList();
        },
      ),
      lineBarsData: lines,
    );
  }

  double _xInterval(int len) {
    if (len <= 5) return 1;
    if (len <= 10) return 2;
    if (len <= 20) return 4;
    return (len / 5).ceilToDouble();
  }

  // ---------------------------------------------------------------------------
  // Legend
  // ---------------------------------------------------------------------------
  Widget _buildLegend() {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: List.generate(4, (i) {
        final isVisible = _sensorVisible[i];
        return GestureDetector(
          onTap: () {
            setState(() {
              // Require at least 1 visible sensor.
              final visCount = _sensorVisible.where((v) => v).length;
              if (isVisible && visCount <= 1) return;
              _sensorVisible[i] = !_sensorVisible[i];
            });
            _animController.reset();
            _animController.forward();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isVisible
                  ? _sensorColors[i].withOpacity(0.08)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isVisible
                    ? _sensorColors[i].withOpacity(0.25)
                    : const Color(0xFFE8EAED),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isVisible ? _sensorColors[i] : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_sensorIcons[i]} ${_sensorNames[i]}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isVisible
                        ? _sensorColors[i]
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
