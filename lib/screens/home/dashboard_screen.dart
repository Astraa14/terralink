import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/bluetooth_service.dart';
import '../../services/sensor_service.dart';
import 'widgets/metric_card.dart';
import 'widgets/connection_card.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
class AppColors {
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E2022);
  static const Color textMuted = Color(0xFF8A9099);
  static const Color mainAccent = Color(0xFF1F2E22);
  static const Color primaryGreen = Color(0xFF388E3C);

  static const Color orangeBg = Color(0xFFFFF7F2);
  static const Color orangeText = Color(0xFFE65100);
  static const Color blueBg = Color(0xFFF0F5FA);
  static const Color blueText = Color(0xFF0288D1);
  static const Color yellowBg = Color(0xFFFFFBEA);
  static const Color yellowText = Color(0xFFF57F17);
  static const Color tealBg = Color(0xFFEAF8F6);
  static const Color tealText = Color(0xFF00796B);
}

// ---------------------------------------------------------------------------
// Main Dashboard Screen — holds bottom nav and page switching
// ---------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Pages for each tab (lazy-built)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeBody(),
      const AnalyticsScreen(),
      const _RulesPlaceholder(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Transparent system bars
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final sensor = context.watch<SensorService>();
    final hasAlerts = sensor.hasActiveAlerts;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentIndex == 0,
                showBadge: hasAlerts && _currentIndex != 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.auto_fix_high_rounded,
                label: 'Rules',
                isActive: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isActive: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav item
// ---------------------------------------------------------------------------
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool showBadge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? AppColors.primaryGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? AppColors.primaryGreen : AppColors.textMuted,
                ),
                if (showBadge)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primaryGreen : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME BODY — the actual dashboard content
// ---------------------------------------------------------------------------
class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorService>();
    final bt = context.watch<BluetoothService>();
    final isLive = bt.isConnected || sensor.demoMode;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TerraLink',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Terrarium Monitor',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Alert badge
                      if (sensor.hasActiveAlerts)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                '${sensor.alerts.where((a) => a.enabled && a.triggered).length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Connection card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const ConnectionCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Sensor Readings',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Metric cards grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildListDelegate([
                _buildMetric(sensor, SensorIndex.temperature),
                _buildMetric(sensor, SensorIndex.humidity),
                _buildMetric(sensor, SensorIndex.npk),
                _buildMetric(sensor, SensorIndex.soilMoisture),
              ]),
            ),
          ),

          // Alert summary (if any)
          if (sensor.hasActiveAlerts)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _AlertSummaryCard(sensor: sensor),
              ),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildMetric(SensorService sensor, int index) {
    final configs = _metricConfigs();
    final cfg = configs[index];
    final isTriggered = sensor.isAlertTriggered(index);

    return MetricCard(
      index: index,
      title: SensorIndex.label(index),
      value: sensor.formattedValue(index),
      unit: SensorIndex.unit(index),
      statusLabel: isTriggered ? 'Alert' : 'Normal',
      statusColor: isTriggered ? Colors.red : cfg['textColor'] as Color,
      bgColor: cfg['bgColor'] as Color,
      textColor: cfg['textColor'] as Color,
      icon: cfg['icon'] as IconData,
    );
  }

  List<Map<String, dynamic>> _metricConfigs() => [
        {
          'bgColor': AppColors.orangeBg,
          'textColor': AppColors.orangeText,
          'icon': Icons.thermostat_rounded,
        },
        {
          'bgColor': AppColors.blueBg,
          'textColor': AppColors.blueText,
          'icon': Icons.water_drop_rounded,
        },
        {
          'bgColor': AppColors.yellowBg,
          'textColor': AppColors.yellowText,
          'icon': Icons.grass_rounded,
        },
        {
          'bgColor': AppColors.tealBg,
          'textColor': AppColors.tealText,
          'icon': Icons.opacity_rounded,
        },
      ];
}

// ---------------------------------------------------------------------------
// Alert summary card
// ---------------------------------------------------------------------------
class _AlertSummaryCard extends StatelessWidget {
  final SensorService sensor;
  const _AlertSummaryCard({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final triggeredIndices = <int>[];
    for (int i = 0; i < SensorIndex.count; i++) {
      if (sensor.isAlertTriggered(i)) triggeredIndices.add(i);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                '${triggeredIndices.length} Alert${triggeredIndices.length > 1 ? 's' : ''} Active',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...triggeredIndices.map((idx) {
            final alert = sensor.alerts[idx];
            final val = sensor.currentValues[idx];
            final dir = alert.greaterThan ? '>' : '<';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${SensorIndex.label(idx)}: ${val.toStringAsFixed(1)} ${SensorIndex.unit(idx)} '
                      '($dir ${alert.threshold.toStringAsFixed(1)})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E2022),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rules placeholder — will be replaced by sibling agent's build
// ---------------------------------------------------------------------------
class _RulesPlaceholder extends StatelessWidget {
  const _RulesPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Attempt to load the rules screen if available, otherwise show placeholder
    try {
      // The automation screen will be provided by another sibling agent
      // This will be replaced during final integration
      return _RulesPlaceholderBody();
    } catch (_) {
      return _RulesPlaceholderBody();
    }
  }
}

class _RulesPlaceholderBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Automation Rules',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set up rules to automate your terrarium',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(Icons.auto_fix_high_rounded,
                      size: 64, color: AppColors.primaryGreen.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Automation rules will appear here',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
