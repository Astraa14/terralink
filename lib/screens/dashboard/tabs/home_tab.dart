import 'package:flutter/material.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/redesign/glass_card.dart';
import '../../../widgets/redesign/health_score_card.dart';
import '../../../widgets/redesign/section_header.dart';
import '../../../widgets/redesign/sensor_metric_card.dart';
import '../../../widgets/redesign/terra_badge.dart';
import '../../../widgets/sensor_chart.dart';

class HomeTab extends StatelessWidget {
  final String greeting;
  final String userName;
  final bool isConnected;
  final bool isDemoMode;
  final int healthScore;
  final String healthLabel;
  final String connectionStatus;
  final double moisture;
  final double temperature;
  final double ph;
  final double npk;
  final double humidity;
  final double ec;
  final int quickChartIndex;
  final Map<int, List<SensorLog>> sensorHistory;
  final VoidCallback onBluetoothTap;
  final VoidCallback onRefresh;
  final ValueChanged<int> onQuickChartChanged;

  const HomeTab({
    super.key,
    required this.greeting,
    required this.userName,
    required this.isConnected,
    required this.isDemoMode,
    required this.healthScore,
    required this.healthLabel,
    required this.connectionStatus,
    required this.moisture,
    required this.temperature,
    required this.ph,
    required this.npk,
    required this.humidity,
    required this.ec,
    required this.quickChartIndex,
    required this.sensorHistory,
    required this.onBluetoothTap,
    required this.onRefresh,
    required this.onQuickChartChanged,
  });

  _MetricState _stateFor(String type) {
    switch (type) {
      case 'moisture':
        if (moisture < 170) {
          return _MetricState('Critical', FarmMetricSeverity.critical);
        }
        if (moisture < 240 || moisture > 720) {
          return _MetricState('Attention', FarmMetricSeverity.attention);
        }
        if (moisture < 300 || moisture > 640) {
          return _MetricState('Monitor', FarmMetricSeverity.monitor);
        }
        return _MetricState('Healthy', FarmMetricSeverity.healthy);
      case 'temp':
        if (temperature < 12 || temperature > 36) {
          return _MetricState('Critical', FarmMetricSeverity.critical);
        }
        if (temperature < 16 || temperature > 32) {
          return _MetricState('Attention', FarmMetricSeverity.attention);
        }
        if (temperature < 18 || temperature > 30) {
          return _MetricState('Monitor', FarmMetricSeverity.monitor);
        }
        return _MetricState('Healthy', FarmMetricSeverity.healthy);
      case 'ph':
        if (ph < 5.0 || ph > 8.0) {
          return _MetricState('Critical', FarmMetricSeverity.critical);
        }
        if (ph < 5.5 || ph > 7.5) {
          return _MetricState('Attention', FarmMetricSeverity.attention);
        }
        if (ph < 5.8 || ph > 7.2) {
          return _MetricState('Monitor', FarmMetricSeverity.monitor);
        }
        return _MetricState('Healthy', FarmMetricSeverity.healthy);
      case 'npk':
        if (npk < 150) return _MetricState('Attention', FarmMetricSeverity.attention);
        if (npk < 230) return _MetricState('Monitor', FarmMetricSeverity.monitor);
        if (npk > 520) return _MetricState('Thriving', FarmMetricSeverity.thriving);
        return _MetricState('Healthy', FarmMetricSeverity.healthy);
      case 'humidity':
        if (humidity < 28 || humidity > 88) {
          return _MetricState('Attention', FarmMetricSeverity.attention);
        }
        if (humidity < 40 || humidity > 75) {
          return _MetricState('Monitor', FarmMetricSeverity.monitor);
        }
        return _MetricState('Healthy', FarmMetricSeverity.healthy);
      case 'ec':
        if (ec > 4.0) return _MetricState('Critical', FarmMetricSeverity.critical);
        if (ec > 3.0 || ec < 0.4) {
          return _MetricState('Attention', FarmMetricSeverity.attention);
        }
        if (ec > 2.4 || ec < 0.8) {
          return _MetricState('Monitor', FarmMetricSeverity.monitor);
        }
        return _MetricState('Healthy', FarmMetricSeverity.healthy);
      default:
        return _MetricState('Healthy', FarmMetricSeverity.healthy);
    }
  }

  String get _soilInsight {
    if (!isConnected && !isDemoMode) {
      return 'Sensor module offline. Reconnect before making field decisions.';
    }
    if (moisture < 240) return 'Moisture is low. Irrigation is needed soon.';
    if (ph < 5.5) return 'Soil is acidic. Review lime plan for this plot.';
    if (ph > 7.5) return 'Soil is alkaline. Check crop-specific pH targets.';
    if (npk < 230) return 'Nutrients are declining. Plan feeding within the week.';
    if (temperature > 32) return 'Root-zone heat is rising. Watch afternoon stress.';
    return 'Soil is well-balanced and ready for the next field pass.';
  }

  String get _healthTrend {
    final logs = sensorHistory[2] ?? [];
    if (logs.length < 2) return 'Stable since last check';
    final delta = logs.last.value - logs[logs.length - 2].value;
    if (delta < -8) return 'Moisture trending down';
    if (delta > 8) return 'Moisture recovering';
    return 'Stable since last check';
  }

  List<_FarmAlert> get _alerts {
    final alerts = <_FarmAlert>[];
    if (!isConnected && !isDemoMode) {
      alerts.add(
        const _FarmAlert(
          title: 'Sensor module offline',
          action: 'Reconnect before field work',
          icon: Icons.cloud_off_outlined,
          color: AppColors.statusRed,
        ),
      );
    }
    if (moisture < 240) {
      alerts.add(
        const _FarmAlert(
          title: 'Soil moisture low',
          action: 'Water in next 2 hours',
          icon: Icons.water_drop_outlined,
          color: AppColors.moisture,
        ),
      );
    }
    if (ph < 5.5 || ph > 7.5) {
      alerts.add(
        const _FarmAlert(
          title: 'pH outside crop range',
          action: 'Review amendment plan',
          icon: Icons.science_outlined,
          color: AppColors.ph,
        ),
      );
    }
    if (temperature > 32) {
      alerts.add(
        const _FarmAlert(
          title: 'Temperature stress rising',
          action: 'Check shade or ventilation',
          icon: Icons.thermostat_outlined,
          color: AppColors.temperature,
        ),
      );
    }
    if (npk < 230) {
      alerts.add(
        const _FarmAlert(
          title: 'Nutrients declining',
          action: 'Plan nutrient application',
          icon: Icons.eco_outlined,
          color: AppColors.npk,
        ),
      );
    }
    return alerts;
  }

  List<HealthFactorStatus> get _healthFactors {
    return [
      HealthFactorStatus(
        label: 'Moisture',
        status: _stateFor('moisture').label,
        icon: Icons.water_drop_outlined,
        color: _statusColor(_stateFor('moisture').severity, AppColors.moisture),
      ),
      HealthFactorStatus(
        label: 'pH',
        status: _stateFor('ph').label,
        icon: Icons.science_outlined,
        color: _statusColor(_stateFor('ph').severity, AppColors.ph),
      ),
      HealthFactorStatus(
        label: 'Nutrients',
        status: _stateFor('npk').label,
        icon: Icons.eco_outlined,
        color: _statusColor(_stateFor('npk').severity, AppColors.npk),
      ),
      HealthFactorStatus(
        label: 'Temp',
        status: _stateFor('temp').label,
        icon: Icons.thermostat_outlined,
        color: _statusColor(_stateFor('temp').severity, AppColors.temperature),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const quickOptions = ['Moisture', 'Temp', 'pH', 'NPK'];
    const quickIndices = [2, 0, 4, 3];
    const quickColors = [
      AppColors.moisture,
      AppColors.temperature,
      AppColors.ph,
      AppColors.npk,
    ];
    const quickUnits = [' pts', '°C', '', ' mg/kg'];
    final safeQuickIndex = quickChartIndex.clamp(0, quickOptions.length - 1).toInt();
    final chartRange = _chartReferenceFor(quickOptions[safeQuickIndex]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good $greeting, $userName',
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Field soil readings are ready for review.',
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
            _ConnectionButton(
              isConnected: isConnected,
              isDemoMode: isDemoMode,
              onTap: onBluetoothTap,
            ),
          ],
        ),
        const SizedBox(height: 20),
        HealthScoreCard(
          score: healthScore,
          label: healthLabel,
          statusText: connectionStatus,
          isConnected: isConnected,
          isDemoMode: isDemoMode,
          insight: _soilInsight,
          trendLabel: _healthTrend,
          factors: _healthFactors,
        ),
        const SizedBox(height: 18),
        _AlertBanner(alerts: _alerts),
        const SizedBox(height: 26),
        SectionHeader(
          title: 'Soil Conditions',
          subtitle: 'Root zone, chemistry, and nutrients',
          icon: Icons.layers_outlined,
          actionLabel: 'Refresh',
          onAction: onRefresh,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.74,
          children: [
            _metricCard(
              type: 'moisture',
              name: 'Soil Moisture',
              value: '${moisture.toStringAsFixed(0)} pts',
              icon: Icons.water_drop_outlined,
              accentColor: AppColors.moisture,
              range: 'Target 300-640 pts',
              position: _position(moisture, 50, 800),
              logs: sensorHistory[2],
              unit: ' pts',
            ),
            _metricCard(
              type: 'ph',
              name: 'Soil pH',
              value: ph.toStringAsFixed(2),
              icon: Icons.science_outlined,
              accentColor: AppColors.ph,
              range: 'Target pH 5.8-7.2',
              position: _position(ph, 4, 9),
              logs: sensorHistory[4],
              unit: '',
            ),
            _metricCard(
              type: 'ec',
              name: 'Conductivity',
              value: '${ec.toStringAsFixed(2)} mS/cm',
              icon: Icons.bolt_outlined,
              accentColor: AppColors.conductivity,
              range: 'Target 0.8-2.4 mS/cm',
              position: _position(ec, 0.1, 5),
              logs: sensorHistory[5],
              unit: ' mS/cm',
            ),
            _metricCard(
              type: 'npk',
              name: 'NPK Level',
              value: '${npk.toStringAsFixed(0)} mg/kg',
              icon: Icons.eco_outlined,
              accentColor: AppColors.npk,
              range: 'Target 230-520 mg/kg',
              position: _position(npk, 100, 900),
              logs: sensorHistory[3],
              unit: ' mg/kg',
            ),
          ],
        ),
        const SizedBox(height: 26),
        const SectionHeader(
          title: 'Environmental',
          subtitle: 'Air and canopy conditions',
          icon: Icons.wb_sunny_outlined,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.74,
          children: [
            _metricCard(
              type: 'temp',
              name: 'Temperature',
              value: '${temperature.toStringAsFixed(1)}°C',
              icon: Icons.thermostat_outlined,
              accentColor: AppColors.temperature,
              range: 'Target 18-30°C',
              position: _position(temperature, 10, 40),
              logs: sensorHistory[0],
              unit: '°C',
            ),
            _metricCard(
              type: 'humidity',
              name: 'Humidity',
              value: '${humidity.toStringAsFixed(1)}%',
              icon: Icons.air_outlined,
              accentColor: AppColors.humidity,
              range: 'Target 40-75%',
              position: _position(humidity, 20, 95),
              logs: sensorHistory[1],
              unit: '%',
            ),
          ],
        ),
        const SizedBox(height: 26),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Field Trend',
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Moisture first, with crop target bands.',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PillSelector(
                    compact: true,
                    options: quickOptions,
                    selectedIndex: safeQuickIndex,
                    onSelected: onQuickChartChanged,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              HighTechSensorChart(
                title: '',
                bare: true,
                logs: sensorHistory[quickIndices[safeQuickIndex]] ?? [],
                primaryColor: quickColors[safeQuickIndex],
                unit: quickUnits[safeQuickIndex],
                referenceMin: chartRange.$1,
                referenceMax: chartRange.$2,
                referenceLabel: chartRange.$3,
                eventMarkerIndices: const [4],
                height: 178,
              ),
            ],
          ),
        ),
      ],
    );
  }

  SensorMetricCard _metricCard({
    required String type,
    required String name,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String range,
    required double position,
    required List<SensorLog>? logs,
    required String unit,
  }) {
    final state = _stateFor(type);
    return SensorMetricCard(
      name: name,
      value: value,
      status: state.label,
      icon: icon,
      accentColor: accentColor,
      severity: state.severity,
      optimalRangeLabel: range,
      referencePosition: position,
      trendDirection: _trendDirection(logs),
      trendLabel: _trendLabel(logs, unit),
      detailLines: _detailLines(logs, unit),
    );
  }

  static Color _statusColor(FarmMetricSeverity severity, Color fallback) {
    return switch (severity) {
      FarmMetricSeverity.thriving || FarmMetricSeverity.healthy => fallback,
      FarmMetricSeverity.monitor => AppColors.statusYellow,
      FarmMetricSeverity.attention => AppColors.statusOrange,
      FarmMetricSeverity.critical => AppColors.statusRed,
    };
  }

  static double _position(double value, double min, double max) {
    return ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
  }

  static SensorTrendDirection _trendDirection(List<SensorLog>? logs) {
    if (logs == null || logs.length < 2) return SensorTrendDirection.steady;
    final delta = logs.last.value - logs[logs.length - 2].value;
    if (delta.abs() < 0.5) return SensorTrendDirection.steady;
    return delta > 0 ? SensorTrendDirection.rising : SensorTrendDirection.falling;
  }

  static String _trendLabel(List<SensorLog>? logs, String unit) {
    if (logs == null || logs.length < 2) return 'Stable';
    final delta = logs.last.value - logs[logs.length - 2].value;
    final absDelta = delta.abs();
    if (absDelta < 0.5) return 'Stable';
    final label = delta > 0 ? 'Rising' : 'Declining';
    return '$label ${absDelta.toStringAsFixed(absDelta < 10 ? 1 : 0)}$unit';
  }

  static List<String> _detailLines(List<SensorLog>? logs, String unit) {
    if (logs == null || logs.isEmpty) return const ['No history'];
    final values = logs.map((e) => e.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    String fmt(double value) => value.toStringAsFixed(value.abs() < 10 ? 2 : 1);
    return ['Avg ${fmt(avg)}$unit', 'Min ${fmt(min)}$unit', 'Max ${fmt(max)}$unit'];
  }

  static (double, double, String) _chartReferenceFor(String metric) {
    return switch (metric) {
      'Temp' => (18, 30, 'Crop comfort band'),
      'pH' => (5.8, 7.2, 'Common crop range'),
      'NPK' => (230, 520, 'Nutrient target'),
      _ => (300, 640, 'Irrigation target'),
    };
  }
}

class _MetricState {
  final String label;
  final FarmMetricSeverity severity;

  const _MetricState(this.label, this.severity);
}

class _FarmAlert {
  final String title;
  final String action;
  final IconData icon;
  final Color color;

  const _FarmAlert({
    required this.title,
    required this.action,
    required this.icon,
    required this.color,
  });
}

class _ConnectionButton extends StatelessWidget {
  final bool isConnected;
  final bool isDemoMode;
  final VoidCallback onTap;

  const _ConnectionButton({
    required this.isConnected,
    required this.isDemoMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected
        ? AppColors.primary
        : isDemoMode
            ? AppColors.softTan
            : AppColors.statusRed;
    final label = isConnected
        ? 'Live'
        : isDemoMode
            ? 'Demo'
            : 'Offline';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: 76, minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: color,
              size: 19,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final List<_FarmAlert> alerts;

  const _AlertBanner({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final alert = alerts.isEmpty
        ? const _FarmAlert(
            title: 'No urgent field actions',
            action: 'Keep monitoring soil trend',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.primary,
          )
        : alerts.first;

    return GlassCard(
      gradient: false,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(color: alert.color.withValues(alpha: 0.28)),
            ),
            child: Icon(alert.icon, color: alert.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.action,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (alerts.length > 1)
            TerraBadge(
              label: '+${alerts.length - 1}',
              variant: TerraBadgeVariant.warning,
              icon: Icons.priority_high_rounded,
            ),
        ],
      ),
    );
  }
}
