import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'models/app_models.dart';
import 'services/auth_service.dart';
import 'services/bluetooth_service.dart';
import 'services/automation_engine.dart';
import 'screens/terra_link_login_screen.dart';
import 'widgets/sensor_chart.dart';

void main() => runApp(const TerraLinkApp());

// ─────────────────────────────────────────────────────────────
//  App-wide colour palette
// ─────────────────────────────────────────────────────────────
class AppColors {
  static const Color background  = Color(0xFFF4F6F3);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color textDark    = Color(0xFF1A2118);
  static const Color textMuted   = Color(0xFF6B726A);

  static const Color mainAccent   = Color(0xFF1F3325);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen  = Color(0xFF4CAF50);

  static const Color orangeBg   = Color(0xFFFFF3E0);
  static const Color orangeText = Color(0xFFE65100);

  static const Color blueBg   = Color(0xFFE3F2FD);
  static const Color blueText = Color(0xFF0277BD);

  static const Color yellowBg   = Color(0xFFFFFDE7);
  static const Color yellowText = Color(0xFFF9A825);

  static const Color tealBg   = Color(0xFFE0F2F1);
  static const Color tealText = Color(0xFF00695C);

  static const Color brownBg   = Color(0xFFFBE9E7);
  static const Color brownText = Color(0xFF4E342E);
}

// ─────────────────────────────────────────────────────────────
//  Root app
// ─────────────────────────────────────────────────────────────
class TerraLinkApp extends StatefulWidget {
  const TerraLinkApp({super.key});

  @override
  State<TerraLinkApp> createState() => _TerraLinkAppState();
}

class _TerraLinkAppState extends State<TerraLinkApp> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerraLink — Farm Soil Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Helvetica',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          surface: AppColors.background,
        ),
      ),
      home: _authService.isAuthenticated
          ? DashboardScreen(authService: _authService)
          : TerraLinkLoginScreen(authService: _authService),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Dashboard shell
// ─────────────────────────────────────────────────────────────
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

  // Live sensor values
  double _currentTemp        = 28.4;
  double _currentHumidity    = 62.0;
  double _currentNPK         = 430.0;   // mg/kg composite
  double _currentMoisture    = 310.0;   // raw ADC / capacitive units
  double _currentPH          = 6.5;     // pH
  double _currentEC          = 1.8;     // mS/cm electrical conductivity

  // Analytics chart tab selector
  int _analyticsTabIndex = 0;

  // 6-point rolling history per sensor channel
  // 0=Temp 1=Humidity 2=Moisture 3=NPK 4=pH 5=EC
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
        _currentTemp     = temp;
        _currentHumidity = hum;
        _currentNPK      = npk.toDouble();
        _currentMoisture = moisture.toDouble();
        _isDemoMode      = false;
        _updateRealTimeHistory();
        _automationEngine.evaluateRules(
          currentTemp:          _currentTemp,
          currentHumidity:      _currentHumidity,
          currentSoilMoisture:  _currentMoisture,
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

  // ── Mock Data ──────────────────────────────────────────────
  void _generateMockHistory() {
    final now = DateTime.now();
    _sensorHistory = {
      0: _genHistory(6, now, 26.0, 4.0,  (v) => v > 30 ? 'High' : 'Optimal'),
      1: _genHistory(6, now, 55.0, 15.0, (v) => v > 70 ? 'Wet' : 'Optimal'),
      2: _genHistory(6, now, 270.0,100.0,(v) => v < 200 ? 'Dry' : 'Optimal'),
      3: _genHistory(6, now, 380.0,120.0,(v) => 'Optimal'),
      4: _genHistory(6, now, 6.2,  0.6,  (v) => v < 5.5 ? 'Acidic' : v > 7.5 ? 'Alkaline' : 'Optimal'),
      5: _genHistory(6, now, 1.6,  0.6,  (v) => v > 3.0 ? 'High' : 'Optimal'),
    };
  }

  List<SensorLog> _genHistory(int count, DateTime now, double base, double range,
      String Function(double) statusFn) {
    return List.generate(count, (i) {
      final hr  = now.subtract(Duration(hours: count - 1 - i));
      final val = base + (_random.nextDouble() - 0.5) * range;
      final rounded = double.parse(val.toStringAsFixed(2));
      return SensorLog(
        timeLabel: _formatHour(hr.hour),
        value:     rounded,
        status:    statusFn(rounded),
      );
    });
  }

  String _formatHour(int h) {
    if (h == 0)  return '12 AM';
    if (h < 12)  return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  void _startDemoSimulation() {
    _demoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isDemoMode && !_btService.isConnected) {
        setState(() {
          _currentTemp     = (_currentTemp     + (_random.nextDouble() - 0.5) * 0.4).clamp(18.0, 38.0);
          _currentHumidity = (_currentHumidity + (_random.nextDouble() - 0.5) * 2.0).clamp(30.0, 95.0);
          _currentMoisture = (_currentMoisture + (_random.nextDouble() - 0.5) * 8.0).clamp(50.0, 800.0);
          _currentNPK      = (_currentNPK      + (_random.nextDouble() - 0.5) * 10.0).clamp(100.0, 900.0);
          _currentPH       = (_currentPH       + (_random.nextDouble() - 0.5) * 0.05).clamp(4.0, 9.0);
          _currentEC       = (_currentEC       + (_random.nextDouble() - 0.5) * 0.05).clamp(0.1, 5.0);

          _currentTemp     = double.parse(_currentTemp.toStringAsFixed(1));
          _currentHumidity = double.parse(_currentHumidity.toStringAsFixed(1));
          _currentMoisture = double.parse(_currentMoisture.toStringAsFixed(1));
          _currentNPK      = double.parse(_currentNPK.toStringAsFixed(1));
          _currentPH       = double.parse(_currentPH.toStringAsFixed(2));
          _currentEC       = double.parse(_currentEC.toStringAsFixed(2));

          _updateRealTimeHistory();
          _automationEngine.evaluateRules(
            currentTemp:         _currentTemp,
            currentHumidity:     _currentHumidity,
            currentSoilMoisture: _currentMoisture,
          );
        });
      }
    });
  }

  void _updateRealTimeHistory() {
    final vals = [_currentTemp, _currentHumidity, _currentMoisture, _currentNPK, _currentPH, _currentEC];
    for (int i = 0; i < vals.length; i++) {
      if (_sensorHistory[i]?.isEmpty ?? true) continue;
      _sensorHistory[i]!.last = SensorLog(timeLabel: 'Now', value: vals[i], status: 'Live');
    }
  }

  // ── Soil Health Score ──────────────────────────────────────
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

  Color get _healthColor {
    final s = _healthScore;
    if (s >= 80) return AppColors.primaryGreen;
    if (s >= 60) return AppColors.accentGreen;
    if (s >= 40) return AppColors.yellowText;
    return AppColors.orangeText;
  }

  // ─────────────────────────────────────────────────────────
  //  Shell build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildPageBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activeNavIndex,
        onDestinationSelected: (i) => setState(() => _activeNavIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentGreen.withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded),       label: 'Home'),
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.autorenew_rounded),  label: 'Automation'),
          NavigationDestination(icon: Icon(Icons.settings_rounded),   label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildPageBody() {
    switch (_activeNavIndex) {
      case 0: return _buildHomeDashboard();
      case 1: return _buildAnalyticsTab();
      case 2: return _buildAutomationTab();
      case 3: return _buildSettingsTab();
      default: return _buildHomeDashboard();
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  HOME TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildHomeDashboard() {
    final user = widget.authService.currentUser;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_timeGreeting()},',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    Text(
                      user?.displayName ?? 'Farmer',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_isDemoMode)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.yellowBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.yellowText.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'DEMO',
                          style: TextStyle(
                            color: AppColors.yellowText,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: _showDevicesSheet,
                      icon: Icon(
                        _btService.isConnected
                            ? Icons.bluetooth_connected_rounded
                            : Icons.bluetooth_rounded,
                        color: _btService.isConnected
                            ? AppColors.primaryGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Soil Health Banner ────────────────────────
            _buildSoilHealthBanner(),

            const SizedBox(height: 20),

            // ── Sensor Grid ───────────────────────────────
            const Text(
              'Live Sensors',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _metricCard('Soil Moisture', '${_currentMoisture.toStringAsFixed(0)} pts', Icons.water_drop_outlined, AppColors.blueBg, AppColors.blueText),
                _metricCard('Temperature',   '${_currentTemp.toStringAsFixed(1)}°C',       Icons.thermostat_rounded,  AppColors.orangeBg, AppColors.orangeText),
                _metricCard('Soil pH',        _currentPH.toStringAsFixed(2),               Icons.science_outlined,    AppColors.yellowBg, AppColors.yellowText),
                _metricCard('NPK Level',      '${_currentNPK.toStringAsFixed(0)} mg/kg',   Icons.grass_rounded,       AppColors.tealBg,   AppColors.tealText),
                _metricCard('Humidity',       '${_currentHumidity.toStringAsFixed(1)}%',   Icons.air_rounded,         AppColors.tealBg,   AppColors.tealText),
                _metricCard('Conductivity',   '${_currentEC.toStringAsFixed(2)} mS/cm',    Icons.bolt_rounded,        AppColors.brownBg,  AppColors.brownText),
              ],
            ),

            const SizedBox(height: 24),

            // ── Quick-View Chart ──────────────────────────
            _buildQuickChartSelector(),
          ],
        ),
      ),
    );
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildSoilHealthBanner() {
    final score = _healthScore;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.mainAccent, _healthColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Farm Health Score',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _healthLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _btService.isConnected
                      ? '🟢  Sensor connected · Live data'
                      : '🟡  Demo mode · Connect sensor',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text(value,  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChartSelector() {
    final sensors = [
      ('Moisture',      AppColors.blueText,   '%'),
      ('Temperature',   AppColors.orangeText, '°C'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Trend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            Row(
              children: sensors.asMap().entries.map((e) {
                final selected = _analyticsTabIndex == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _analyticsTabIndex = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? e.value.$2.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? e.value.$2 : AppColors.textMuted.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      e.value.$1,
                      style: TextStyle(
                        color: selected ? e.value.$2 : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        HighTechSensorChart(
          title: sensors[_analyticsTabIndex].$1,
          logs:  _sensorHistory[_analyticsTabIndex] ?? [],
          primaryColor: sensors[_analyticsTabIndex].$2,
          unit: sensors[_analyticsTabIndex].$3,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ANALYTICS TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildAnalyticsTab() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soil Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text('6-hour rolling sensor history', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart 1: Soil Moisture
          HighTechSensorChart(
            title: 'Soil Moisture',
            logs:  _sensorHistory[0] ?? [],
            primaryColor: AppColors.blueText,
            unit:  ' pts',
          ),
          const SizedBox(height: 20),

          // Chart 2: Soil Temperature
          HighTechSensorChart(
            title: 'Soil Temperature',
            logs:  _sensorHistory[1] ?? [],
            primaryColor: AppColors.orangeText,
            unit:  '°C',
          ),
          const SizedBox(height: 20),

          // Chart 3: NPK Composite
          HighTechSensorChart(
            title: 'NPK Level',
            logs:  _sensorHistory[3] ?? [],
            primaryColor: AppColors.tealText,
            unit:  ' mg/kg',
          ),
          const SizedBox(height: 20),

          // Chart 4: Soil pH
          HighTechSensorChart(
            title: 'Soil pH',
            logs:  _sensorHistory[4] ?? [],
            primaryColor: AppColors.yellowText,
            unit:  '',
          ),
          const SizedBox(height: 20),

          // Chart 5: Electrical Conductivity
          HighTechSensorChart(
            title: 'Electrical Conductivity (EC)',
            logs:  _sensorHistory[5] ?? [],
            primaryColor: AppColors.brownText,
            unit:  ' mS/cm',
          ),
          const SizedBox(height: 20),

          // Chart 6: Ambient Humidity
          HighTechSensorChart(
            title: 'Ambient Humidity',
            logs:  _sensorHistory[1] ?? [],
            primaryColor: AppColors.primaryGreen,
            unit:  '%',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  AUTOMATION TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildAutomationTab() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header + master toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Automation Engine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text('Smart farm control rules', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              Switch(
                value: _automationEngine.isSmartAutomationEnabled,
                activeThumbColor: AppColors.primaryGreen,
                onChanged: (v) => _automationEngine.toggleSmartAutomation(v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _automationEngine.isSmartAutomationEnabled
                  ? AppColors.tealBg
                  : AppColors.orangeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _automationEngine.isSmartAutomationEnabled
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
                  color: _automationEngine.isSmartAutomationEnabled
                      ? AppColors.tealText
                      : AppColors.orangeText,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _automationEngine.isSmartAutomationEnabled
                      ? 'Automation active — rules are evaluating in real-time'
                      : 'Automation paused — all actuators held in current state',
                  style: TextStyle(
                    fontSize: 12,
                    color: _automationEngine.isSmartAutomationEnabled
                        ? AppColors.tealText
                        : AppColors.orangeText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rule 1: Irrigation Pump
          _ruleTile(
            title:    'Irrigation Pump',
            subtitle: 'Activates when soil moisture falls below threshold',
            commandOn:  'PUMP:ON',
            commandOff: 'PUMP:OFF',
            enabled: _automationEngine.isIrrigationTriggerEnabled,
            active:  _automationEngine.isIrrigationActive,
            onToggle: (v) => _automationEngine.updateIrrigationRule(enabled: v),
            icon:       Icons.water_drop_rounded,
            iconColor:  AppColors.blueText,
            threshold:  _automationEngine.soilMoistureMinThreshold,
            threshLabel: 'Min moisture threshold',
            threshUnit:  ' pts',
            min: 50,
            max: 600,
            onThreshChanged: (v) => _automationEngine.updateIrrigationRule(threshold: v),
          ),

          // Rule 2: Cooling / Ventilation Fan
          _ruleTile(
            title:    'Ventilation Fan',
            subtitle: 'Triggers when soil/air temperature exceeds threshold',
            commandOn:  'FAN:ON',
            commandOff: 'FAN:OFF',
            enabled: _automationEngine.isOverheatingProtectionEnabled,
            active:  _automationEngine.isCoolingFanActive,
            onToggle: (v) => _automationEngine.updateOverheatRule(enabled: v),
            icon:       Icons.air_rounded,
            iconColor:  AppColors.orangeText,
            threshold:  _automationEngine.overheatTempThreshold,
            threshLabel: 'Max temperature threshold',
            threshUnit:  '°C',
            min: 25,
            max: 45,
            onThreshChanged: (v) => _automationEngine.updateOverheatRule(threshold: v),
          ),

          // Rule 3: Mist / Humidity booster
          _ruleTile(
            title:    'Mist Sprinkler',
            subtitle: 'Boosts humidity when ambient level drops too low',
            commandOn:  'MIST:ON',
            commandOff: 'MIST:OFF',
            enabled: _automationEngine.isMistTriggerEnabled,
            active:  _automationEngine.isMistPumpActive,
            onToggle: (v) => _automationEngine.updateMistRule(enabled: v),
            icon:       Icons.grain_rounded,
            iconColor:  AppColors.primaryGreen,
            threshold:  _automationEngine.mistHumidityThreshold,
            threshLabel: 'Min humidity threshold',
            threshUnit:  '%',
            min: 20,
            max: 90,
            onThreshChanged: (v) => _automationEngine.updateMistRule(threshold: v),
          ),

          // Rule 4: Fertilizer alert
          _nightModeTile(),

          const SizedBox(height: 20),

          // BT Transmit Log
          Row(
            children: [
              const Icon(Icons.terminal_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              const Text('Bluetooth Transmit Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
              const Spacer(),
              Text('${_btService.sentCommandLogs.length} cmd', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1B10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _btService.sentCommandLogs.isEmpty
                ? const Center(
                    child: Text(
                      'No commands sent yet',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: _btService.sentCommandLogs.length,
                    itemBuilder: (_, i) => Text(
                      _btService.sentCommandLogs[i],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _ruleTile({
    required String title,
    required String subtitle,
    required String commandOn,
    required String commandOff,
    required bool   enabled,
    required bool   active,
    required void Function(bool) onToggle,
    required IconData icon,
    required Color    iconColor,
    required double   threshold,
    required String   threshLabel,
    required String   threshUnit,
    required double   min,
    required double   max,
    required void Function(double) onThreshChanged,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (active)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              Switch(
                                value: enabled,
                                activeThumbColor: AppColors.primaryGreen,
                                onChanged: onToggle,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '⌘  $commandOn  /  $commandOff',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(threshLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const Spacer(),
                Text(
                  '${threshold.toStringAsFixed(0)}$threshUnit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: iconColor),
                ),
              ],
            ),
            Slider(
              value: threshold,
              min: min,
              max: max,
              divisions: ((max - min) / 5).round(),
              activeColor: iconColor,
              inactiveColor: iconColor.withValues(alpha: 0.2),
              label: '${threshold.toStringAsFixed(0)}$threshUnit',
              onChanged: enabled ? onThreshChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nightModeTile() {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.nightlight_round, color: Colors.deepPurple, size: 20),
        ),
        title: const Text('Low-Light Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
        subtitle: const Text('Reduces sensor polling rate between 10 PM – 6 AM to save power', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: Switch(
          value: _automationEngine.isNightOptimizationEnabled,
          activeThumbColor: Colors.deepPurple,
          onChanged: (v) => _automationEngine.updateNightRule(enabled: v),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SETTINGS TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildSettingsTab() {
    final user = widget.authService.currentUser;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Account & System', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 20),

          // Profile card
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.mainAccent,
                    child: Text(
                      (user?.displayName.isNotEmpty == true)
                          ? user!.displayName[0].toUpperCase()
                          : 'F',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(user?.email ?? 'Guest Session', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Device', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 10),

          // Bluetooth card
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.bluetooth_rounded, color: AppColors.tealText, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Bluetooth Sensor Module', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _btService.isConnected ? AppColors.primaryGreen : Colors.redAccent,
                            ),
                          ),
                          Text(
                            _btService.isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: _btService.isConnected ? AppColors.primaryGreen : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _btService.isConnected
                            ? () => _btService.disconnect()
                            : _showDevicesSheet,
                        child: Text(_btService.isConnected ? 'Disconnect' : 'Connect Device'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('About', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 10),

          // App Info card
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.eco_rounded, color: AppColors.tealText, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('TerraLink', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _InfoRow(label: 'App Name',    value: 'TerraLink — Farm Soil Monitor'),
                  const _InfoRow(label: 'Version',     value: '1.0.0 (Build 1)'),
                  const _InfoRow(label: 'Platform',    value: 'Flutter · Android / iOS'),
                  const _InfoRow(label: 'Protocol',    value: 'Bluetooth SPP (HC-05/HC-06)'),
                  const _InfoRow(label: 'Sensors',     value: 'Moisture · Temp · NPK · pH · EC'),
                  const _InfoRow(label: 'Developer',   value: 'TerraLink Engineering'),
                  const _InfoRow(label: 'Description', value: 'Real-time farm soil monitoring & smart irrigation automation via Bluetooth-connected soil sensors.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade200,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => widget.authService.signOut(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // BT pairing sheet
  void _showDevicesSheet() {
    _btService.getPairedDevices();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Text('Select Bluetooth Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Paired HC-05 / HC-06 modules', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            ..._btService.devicesList.map(
              (d) => ListTile(
                leading: const Icon(Icons.sensors_rounded, color: AppColors.primaryGreen),
                title: Text(d.name ?? 'Unknown Module'),
                subtitle: Text(d.address),
                onTap: () {
                  _btService.connectToDevice(d);
                  Navigator.pop(context);
                },
              ),
            ),
            if (_btService.devicesList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No paired devices found.\nPair your soil sensor module in system settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Reusable info row for settings
// ─────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
