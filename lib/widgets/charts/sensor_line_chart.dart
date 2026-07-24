import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Data model matching the app's SensorLog.
class SensorLog {
  final String timeLabel;
  final double value;
  final String status;

  const SensorLog({
    required this.timeLabel,
    required this.value,
    this.status = 'Normal',
  });
}

/// Reusable line chart for a single sensor's history.
///
/// Uses fl_chart with a smooth curved line, gradient fill beneath,
/// touch tooltips, and proper axis scaling per sensor type.
class SensorLineChart extends StatefulWidget {
  /// The sensor history data points.
  final List<SensorLog> data;

  /// Sensor index: 0=Temperature, 1=Humidity, 2=NPK, 3=Soil Moisture.
  final int sensorIndex;

  /// Show subtle grid lines.
  final bool showGrid;

  /// Show dots on data points.
  final bool showDots;

  /// Enable touch-to-inspect tooltip.
  final bool enableTouch;

  /// Chart height. Defaults to 220.
  final double height;

  const SensorLineChart({
    super.key,
    required this.data,
    required this.sensorIndex,
    this.showGrid = true,
    this.showDots = true,
    this.enableTouch = true,
    this.height = 220,
  });

  @override
  State<SensorLineChart> createState() => _SensorLineChartState();
}

class _SensorLineChartState extends State<SensorLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Sensor config: [minY, maxY, interval, Color lineColor]
  static const _sensorConfig = {
    0: _SensorChartConfig(
      minY: 15, maxY: 40, interval: 5,
      lineColor: Color(0xFFE65100),
      gradientTop: Color(0x40E65100),
      gradientBottom: Color(0x00E65100),
      name: 'Temperature', unit: '°C',
    ),
    1: _SensorChartConfig(
      minY: 20, maxY: 100, interval: 20,
      lineColor: Color(0xFF0288D1),
      gradientTop: Color(0x400288D1),
      gradientBottom: Color(0x000288D1),
      name: 'Humidity', unit: '%',
    ),
    2: _SensorChartConfig(
      minY: 0, maxY: 300, interval: 50,
      lineColor: Color(0xFFF57F17),
      gradientTop: Color(0x40F57F17),
      gradientBottom: Color(0x00F57F17),
      name: 'Soil NPK', unit: 'mg/kg',
    ),
    3: _SensorChartConfig(
      minY: 0, maxY: 800, interval: 200,
      lineColor: Color(0xFF00796B),
      gradientTop: Color(0x4000796B),
      gradientBottom: Color(0x0000796B),
      name: 'Soil Moisture', unit: 'pts',
    ),
  };

  _SensorChartConfig get _config =>
      _sensorConfig[widget.sensorIndex] ?? _sensorConfig[0]!;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant SensorLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.sensorIndex != widget.sensorIndex) {
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
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: LineChart(
            _buildChartData(),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        );
      },
    );
  }

  LineChartData _buildChartData() {
    final config = _config;
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.data.length; i++) {
      final animatedValue = widget.data[i].value *
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutCubic,
          ).value;
      spots.add(FlSpot(i.toDouble(), animatedValue));
    }

    return LineChartData(
      minY: config.minY,
      maxY: config.maxY,
      minX: 0,
      maxX: (widget.data.length - 1).toDouble().clamp(1, double.infinity),
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: widget.showGrid,
        drawVerticalLine: false,
        horizontalInterval: config.interval,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFECEDF0),
          strokeWidth: 1,
          dashArray: [6, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: config.interval,
            getTitlesWidget: (value, meta) {
              if (value == config.minY || value == config.maxY) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 11,
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
            interval: _xInterval(),
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= widget.data.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.data[idx].timeLabel,
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
        enabled: widget.enableTouch,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1F2E22),
          tooltipRoundedRadius: 10,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final idx = spot.x.toInt().clamp(0, widget.data.length - 1);
              final log = widget.data[idx];
              return LineTooltipItem(
                '${log.value.toStringAsFixed(1)} ${config.unit}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: log.timeLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((i) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: config.lineColor.withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 6,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: config.lineColor,
                ),
              ),
            );
          }).toList();
        },
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: config.lineColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: widget.showDots,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: config.lineColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [config.gradientTop, config.gradientBottom],
            ),
          ),
        ),
      ],
    );
  }

  double _xInterval() {
    final len = widget.data.length;
    if (len <= 5) return 1;
    if (len <= 10) return 2;
    if (len <= 20) return 4;
    return (len / 5).ceilToDouble();
  }
}

/// Internal config per sensor type.
class _SensorChartConfig {
  final double minY;
  final double maxY;
  final double interval;
  final Color lineColor;
  final Color gradientTop;
  final Color gradientBottom;
  final String name;
  final String unit;

  const _SensorChartConfig({
    required this.minY,
    required this.maxY,
    required this.interval,
    required this.lineColor,
    required this.gradientTop,
    required this.gradientBottom,
    required this.name,
    required this.unit,
  });
}
