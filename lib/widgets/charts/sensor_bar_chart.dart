import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'sensor_line_chart.dart' show SensorLog;

/// Bar chart variant for comparing recent sensor readings side-by-side.
///
/// Displays the last N data points as rounded bars with value labels on top
/// and touch interaction for detailed tooltips.
class SensorBarChart extends StatefulWidget {
  /// The sensor history data points (shows up to last 8).
  final List<SensorLog> data;

  /// Sensor index: 0=Temperature, 1=Humidity, 2=NPK, 3=Soil Moisture.
  final int sensorIndex;

  /// Chart height. Defaults to 220.
  final double height;

  /// Show value labels on top of bars.
  final bool showValueLabels;

  const SensorBarChart({
    super.key,
    required this.data,
    required this.sensorIndex,
    this.height = 220,
    this.showValueLabels = true,
  });

  @override
  State<SensorBarChart> createState() => _SensorBarChartState();
}

class _SensorBarChartState extends State<SensorBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _touchedIndex = -1;

  static const _barColors = [
    Color(0xFFE65100), // Temperature - orange
    Color(0xFF0288D1), // Humidity - blue
    Color(0xFFF57F17), // NPK - yellow
    Color(0xFF00796B), // Soil Moisture - teal
  ];

  static const _barBgColors = [
    Color(0xFFFFF7F2),
    Color(0xFFF0F5FA),
    Color(0xFFFFFBEA),
    Color(0xFFEAF8F6),
  ];

  static const _maxValues = [40.0, 100.0, 300.0, 800.0];
  static const _units = ['°C', '%', 'mg/kg', 'pts'];

  Color get _barColor => _barColors[widget.sensorIndex.clamp(0, 3)];
  Color get _barBgColor => _barBgColors[widget.sensorIndex.clamp(0, 3)];
  double get _maxY => _maxValues[widget.sensorIndex.clamp(0, 3)];
  String get _unit => _units[widget.sensorIndex.clamp(0, 3)];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant SensorBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
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
    // Take up to 8 most recent entries.
    final displayData = widget.data.length > 8
        ? widget.data.sublist(widget.data.length - 8)
        : widget.data;

    if (displayData.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: BarChart(
            _buildChartData(displayData),
            duration: const Duration(milliseconds: 300),
          ),
        );
      },
    );
  }

  BarChartData _buildChartData(List<SensorLog> displayData) {
    final animValue = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ).value;

    return BarChartData(
      maxY: _maxY * 1.15, // Extra space for value labels
      minY: 0,
      barTouchData: BarTouchData(
        enabled: true,
        touchCallback: (event, response) {
          setState(() {
            if (response == null || response.spot == null) {
              _touchedIndex = -1;
            } else {
              _touchedIndex = response.spot!.touchedBarGroupIndex;
            }
          });
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1F2E22),
          tooltipRoundedRadius: 10,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final idx = group.x;
            if (idx < 0 || idx >= displayData.length) return null;
            final log = displayData[idx];
            return BarTooltipItem(
              '${log.value.toStringAsFixed(1)} $_unit\n',
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
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _maxY / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFECEDF0),
          strokeWidth: 1,
          dashArray: [6, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: widget.showValueLabels,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= displayData.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  displayData[idx].value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _barColor.withOpacity(0.7),
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _maxY / 4,
            getTitlesWidget: (value, meta) {
              if (value == 0 || value >= _maxY * 1.1) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value.toInt().toString(),
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
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= displayData.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  displayData[idx].timeLabel,
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
      barGroups: List.generate(displayData.length, (i) {
        final isTouched = i == _touchedIndex;
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: displayData[i].value * animValue,
              width: displayData.length <= 5 ? 28 : 18,
              color: isTouched ? _barColor : _barColor.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _maxY,
                color: _barBgColor.withOpacity(0.5),
              ),
            ),
          ],
        );
      }),
    );
  }
}
