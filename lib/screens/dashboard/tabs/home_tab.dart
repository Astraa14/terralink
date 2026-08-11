import 'package:flutter/material.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/redesign/glass_card.dart';
import '../../../widgets/redesign/health_score_card.dart';
import '../../../widgets/redesign/section_header.dart';
import '../../../widgets/redesign/sensor_metric_card.dart';
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

  String _statusFor(String type) {
    switch (type) {
      case 'moisture':
        if (moisture < 200) return 'Dry';
        if (moisture > 650) return 'High';
        return 'Good';
      case 'temp':
        if (temperature > 30) return 'High';
        if (temperature < 18) return 'Low';
        return 'Optimal';
      case 'ph':
        if (ph < 5.5 || ph > 7.5) return 'High';
        return 'Optimal';
      case 'npk':
        return npk < 200 ? 'Low' : 'Good';
      case 'humidity':
        return humidity > 70 ? 'High' : 'Optimal';
      case 'ec':
        return ec > 3.0 ? 'High' : 'Good';
      default:
        return 'Good';
    }
  }

  @override
  Widget build(BuildContext context) {
    const quickOptions = ['Moisture', 'Temp'];
    const quickIndices = [2, 0];
    const quickColors = [AppColors.moisture, AppColors.temperature];
    const quickUnits = [' pts', '°C'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your terrarium is doing great.',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onBluetoothTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        HealthScoreCard(
          score: healthScore,
          label: healthLabel,
          statusText: connectionStatus,
          isConnected: isConnected,
          isDemoMode: isDemoMode,
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'Live Sensors', actionLabel: 'Refresh', onAction: onRefresh),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.05,
          children: [
            SensorMetricCard(
              name: 'Soil Moisture',
              value: '${moisture.toStringAsFixed(0)} pts',
              status: _statusFor('moisture'),
              icon: Icons.water_drop_outlined,
              accentColor: AppColors.moisture,
            ),
            SensorMetricCard(
              name: 'Temperature',
              value: '${temperature.toStringAsFixed(1)}°C',
              status: _statusFor('temp'),
              icon: Icons.thermostat_outlined,
              accentColor: AppColors.temperature,
            ),
            SensorMetricCard(
              name: 'Soil pH',
              value: ph.toStringAsFixed(2),
              status: _statusFor('ph'),
              icon: Icons.science_outlined,
              accentColor: AppColors.ph,
            ),
            SensorMetricCard(
              name: 'NPK Level',
              value: '${npk.toStringAsFixed(0)} mg/kg',
              status: _statusFor('npk'),
              icon: Icons.eco_outlined,
              accentColor: AppColors.npk,
            ),
            SensorMetricCard(
              name: 'Humidity',
              value: '${humidity.toStringAsFixed(1)}%',
              status: _statusFor('humidity'),
              icon: Icons.air_outlined,
              accentColor: AppColors.humidity,
            ),
            SensorMetricCard(
              name: 'Conductivity',
              value: '${ec.toStringAsFixed(2)} mS/cm',
              status: _statusFor('ec'),
              icon: Icons.bolt_outlined,
              accentColor: AppColors.conductivity,
            ),
          ],
        ),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Trend (6h)',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  PillSelector(
                    compact: true,
                    options: quickOptions,
                    selectedIndex: quickChartIndex,
                    onSelected: onQuickChartChanged,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HighTechSensorChart(
                title: '',
                bare: true,
                logs: sensorHistory[quickIndices[quickChartIndex]] ?? [],
                primaryColor: quickColors[quickChartIndex],
                unit: quickUnits[quickChartIndex],
                height: 160,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
