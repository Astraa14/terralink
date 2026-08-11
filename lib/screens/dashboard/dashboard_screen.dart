import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../services/automation_engine.dart';
import '../../services/bluetooth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/redesign/ambient_background.dart';
import '../../widgets/redesign/terra_bottom_nav.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/automation_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/settings_tab.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;
  const DashboardScreen({super.key, required this.authService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeNavIndex = 0;

  late final BluetoothManagerService _btService;
  late final AutomationEngineService _automationEngine;

  bool _isDemoMode = true;
  Timer? _demoTimer;
  final Random _random = Random();

  double _currentTemp = 28.4;
  double _currentHumidity = 62.0;
  double _currentNPK = 430.0;
  double _currentMoisture = 310.0;
  double _currentPH = 6.5;
  double _currentEC = 1.8;

  int _quickChartIndex = 0;
  int _analyticsRangeIndex = 2;

  Map<int, List<SensorLog>> _sensorHistory = {};

  @override
  void initState() {
    super.initState();
    _btService = BluetoothManagerService();
    _automationEngine = AutomationEngineService(bluetoothService: _btService);

    _btService.addListener(() => setState(() {}));
    _automationEngine.addListener(() => setState(() {}));

    _btService.onDataReceivedCallback = (temp, hum, npk, moisture) {
      setState(() {
        _currentTemp = temp;
        _currentHumidity = hum;
        _currentNPK = npk.toDouble();
        _currentMoisture = moisture.toDouble();
        _isDemoMode = false;
        _updateRealTimeHistory();
        _automationEngine.evaluateRules(
          currentTemp: _currentTemp,
          currentHumidity: _currentHumidity,
          currentSoilMoisture: _currentMoisture,
        );
      });
    };

    _generateMockHistory();
    _startDemoSimulation();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _btService.disconnect();
    super.dispose();
  }

  void _generateMockHistory() {
    final now = DateTime.now();
    _sensorHistory = {
      0: _genHistory(6, now, 26.0, 4.0, (v) => v > 30 ? 'High' : 'Optimal'),
      1: _genHistory(6, now, 55.0, 15.0, (v) => v > 70 ? 'High' : 'Optimal'),
      2: _genHistory(6, now, 270.0, 100.0, (v) => v < 200 ? 'Dry' : 'Good'),
      3: _genHistory(6, now, 380.0, 120.0, (v) => 'Good'),
      4: _genHistory(6, now, 6.2, 0.6, (v) => v < 5.5 ? 'Acidic' : 'Optimal'),
      5: _genHistory(6, now, 1.6, 0.6, (v) => v > 3.0 ? 'High' : 'Good'),
    };
  }

  List<SensorLog> _genHistory(
    int count,
    DateTime now,
    double base,
    double range,
    String Function(double) statusFn,
  ) {
    return List.generate(count, (i) {
      final hr = now.subtract(Duration(hours: count - 1 - i));
      final val = base + (_random.nextDouble() - 0.5) * range;
      final rounded = double.parse(val.toStringAsFixed(2));
      return SensorLog(
        timeLabel: _formatHour(hr.hour),
        value: rounded,
        status: statusFn(rounded),
      );
    });
  }

  String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  void _startDemoSimulation() {
    _demoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isDemoMode && !_btService.isConnected) {
        setState(() {
          _currentTemp = (_currentTemp + (_random.nextDouble() - 0.5) * 0.4).clamp(18.0, 38.0);
          _currentHumidity = (_currentHumidity + (_random.nextDouble() - 0.5) * 2.0).clamp(30.0, 95.0);
          _currentMoisture = (_currentMoisture + (_random.nextDouble() - 0.5) * 8.0).clamp(50.0, 800.0);
          _currentNPK = (_currentNPK + (_random.nextDouble() - 0.5) * 10.0).clamp(100.0, 900.0);
          _currentPH = (_currentPH + (_random.nextDouble() - 0.5) * 0.05).clamp(4.0, 9.0);
          _currentEC = (_currentEC + (_random.nextDouble() - 0.5) * 0.05).clamp(0.1, 5.0);

          _currentTemp = double.parse(_currentTemp.toStringAsFixed(1));
          _currentHumidity = double.parse(_currentHumidity.toStringAsFixed(1));
          _currentMoisture = double.parse(_currentMoisture.toStringAsFixed(1));
          _currentNPK = double.parse(_currentNPK.toStringAsFixed(1));
          _currentPH = double.parse(_currentPH.toStringAsFixed(2));
          _currentEC = double.parse(_currentEC.toStringAsFixed(2));

          _updateRealTimeHistory();
          _automationEngine.evaluateRules(
            currentTemp: _currentTemp,
            currentHumidity: _currentHumidity,
            currentSoilMoisture: _currentMoisture,
          );
        });
      }
    });
  }

  void _updateRealTimeHistory() {
    final vals = [
      _currentTemp,
      _currentHumidity,
      _currentMoisture,
      _currentNPK,
      _currentPH,
      _currentEC,
    ];
    for (int i = 0; i < vals.length; i++) {
      if (_sensorHistory[i]?.isEmpty ?? true) continue;
      _sensorHistory[i]!.last = SensorLog(
        timeLabel: 'Now',
        value: vals[i],
        status: 'Live',
      );
    }
  }

  int get _healthScore {
    int score = 100;
    if (_currentMoisture < 200 || _currentMoisture > 650) score -= 20;
    if (_currentPH < 5.5 || _currentPH > 7.5) score -= 20;
    if (_currentEC > 3.0) score -= 15;
    if (_currentNPK < 200) score -= 15;
    if (_currentTemp > 35 || _currentTemp < 10) score -= 15;
    return score.clamp(0, 100);
  }

  String get _healthLabel {
    final s = _healthScore;
    if (s >= 80) return 'Excellent';
    if (s >= 60) return 'Good';
    if (s >= 40) return 'Fair';
    return 'Poor';
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  String get _connectionStatus {
    if (_btService.isConnected) return 'Connected';
    if (_isDemoMode) return 'Connected • Demo Mode';
    return 'Offline / Simulation';
  }

  void _refreshHistory() {
    setState(_generateMockHistory);
  }

  void _showDevicesSheet() {
    _btService.getPairedDevices();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedForeground.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select TerraLink Module',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Paired HC-05 / HC-06 Bluetooth modules',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ..._btService.devicesList.map(
              (d) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bluetooth, color: AppColors.primary),
                title: Text(
                  d.name ?? 'Unknown Module',
                  style: const TextStyle(color: AppColors.foreground),
                ),
                subtitle: Text(
                  d.address,
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
                onTap: () {
                  _btService.connectToDevice(d);
                  Navigator.pop(context);
                },
              ),
            ),
            if (_btService.devicesList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No paired devices found.\nPair your module in system settings first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_activeNavIndex) {
                  0 => HomeTab(
                      key: const ValueKey('home'),
                      greeting: _timeGreeting(),
                      userName: user?.displayName ?? 'Guest',
                      isConnected: _btService.isConnected,
                      isDemoMode: _isDemoMode,
                      healthScore: _healthScore,
                      healthLabel: _healthLabel,
                      connectionStatus: _connectionStatus,
                      moisture: _currentMoisture,
                      temperature: _currentTemp,
                      ph: _currentPH,
                      npk: _currentNPK,
                      humidity: _currentHumidity,
                      ec: _currentEC,
                      quickChartIndex: _quickChartIndex,
                      sensorHistory: _sensorHistory,
                      onBluetoothTap: _showDevicesSheet,
                      onRefresh: _refreshHistory,
                      onQuickChartChanged: (i) => setState(() => _quickChartIndex = i),
                    ),
                  1 => AnalyticsTab(
                      key: const ValueKey('analytics'),
                      sensorHistory: _sensorHistory,
                      rangeIndex: _analyticsRangeIndex,
                      onRangeChanged: (i) => setState(() => _analyticsRangeIndex = i),
                    ),
                  2 => AutomationTab(
                      key: const ValueKey('automation'),
                      engine: _automationEngine,
                      commandLogs: _btService.sentCommandLogs,
                    ),
                  _ => SettingsTab(
                      key: const ValueKey('settings'),
                      authService: widget.authService,
                      btService: _btService,
                      isDemoMode: _isDemoMode,
                      onDemoModeChanged: (v) => setState(() => _isDemoMode = v),
                      onConnectDevice: _showDevicesSheet,
                    ),
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TerraBottomNav(
                  selectedIndex: _activeNavIndex,
                  onSelected: (i) => setState(() => _activeNavIndex = i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
