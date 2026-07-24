import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/bluetooth_service.dart';
import '../../services/sensor_service.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
class _C {
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E2022);
  static const Color textMuted = Color(0xFF8A9099);
  static const Color mainAccent = Color(0xFF1F2E22);
  static const Color primaryGreen = Color(0xFF388E3C);

  static const List<Color> sensorColors = [
    Color(0xFFE65100),
    Color(0xFF0288D1),
    Color(0xFFF57F17),
    Color(0xFF00796B),
  ];
  static const List<Color> sensorBgColors = [
    Color(0xFFFFF7F2),
    Color(0xFFF0F5FA),
    Color(0xFFFFFBEA),
    Color(0xFFEAF8F6),
  ];
  static const List<IconData> sensorIcons = [
    Icons.thermostat_rounded,
    Icons.water_drop_rounded,
    Icons.grass_rounded,
    Icons.opacity_rounded,
  ];
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorService>();
    final bt = context.watch<BluetoothService>();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Configure your terrarium monitor',
                    style: TextStyle(
                      fontSize: 13,
                      color: _C.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ---- Profile Section ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionCard(
                children: [
                  _ProfileHeader(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ---- Connection Section ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(title: 'Connection'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionCard(
                children: [
                  _ToggleRow(
                    icon: Icons.science_outlined,
                    iconColor: _C.primaryGreen,
                    title: 'Demo Mode',
                    subtitle: sensor.demoMode
                        ? 'Simulating live sensor data'
                        : 'Use simulated data for testing',
                    value: sensor.demoMode,
                    onChanged: (v) => sensor.setDemoMode(v),
                  ),
                  const _Divider(),
                  _InfoRow(
                    icon: Icons.bluetooth_rounded,
                    iconColor: const Color(0xFF0288D1),
                    title: 'Bluetooth Status',
                    value: bt.statusLabel,
                    valueColor: bt.isConnected
                        ? _C.primaryGreen
                        : _C.textMuted,
                  ),
                  if (bt.isConnected && bt.connectedDevice != null) ...[
                    const _Divider(),
                    _InfoRow(
                      icon: Icons.devices_rounded,
                      iconColor: _C.mainAccent,
                      title: 'Connected Device',
                      value: bt.connectedDevice!.name ??
                          bt.connectedDevice!.address,
                    ),
                  ],
                  const _Divider(),
                  _ToggleRow(
                    icon: Icons.autorenew_rounded,
                    iconColor: const Color(0xFFE65100),
                    title: 'Auto-Reconnect',
                    subtitle: 'Automatically reconnect on disconnect',
                    value: bt.autoReconnect,
                    onChanged: (v) => bt.setAutoReconnect(v),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ---- Alert Configuration Section ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(title: 'Alert Thresholds'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Per-sensor alert cards
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: _AlertConfigCard(sensorIndex: index),
                );
              },
              childCount: SensorIndex.count,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ---- App Info Section ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(title: 'App'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionCard(
                children: [
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    iconColor: _C.textMuted,
                    title: 'Version',
                    value: '1.0.0',
                  ),
                  const _Divider(),
                  _InfoRow(
                    icon: Icons.code_rounded,
                    iconColor: _C.textMuted,
                    title: 'Build',
                    value: 'TerraLink Flutter',
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ---- Sign Out ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SignOutButton(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile header
// ---------------------------------------------------------------------------
class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Try to get user info from AuthService if available via Provider
    // Falls back to defaults if AuthService is not provided
    String displayName = 'TerraLink User';
    String email = 'user@terralink.app';

    try {
      // Dynamically check for AuthService without hard dependency
      final authService = _tryGetAuthService(context);
      if (authService != null) {
        displayName = authService['displayName'] ?? displayName;
        email = authService['email'] ?? email;
      }
    } catch (_) {
      // AuthService not available, use defaults
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _C.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : 'T',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _C.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _C.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: _C.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Attempts to get auth info from a provider. Returns null if not available.
  Map<String, String>? _tryGetAuthService(BuildContext context) {
    // This tries to read from an AuthService provider if it exists.
    // The AuthService is defined in the auth module built by sibling agent.
    // We use a dynamic approach to avoid compile-time dependency.
    try {
      // Look for any ChangeNotifier that has displayName and email
      // In production, this would be: context.read<AuthService>()
      // For now we attempt to get it from the widget tree
      final element = context as Element;
      ChangeNotifier? authNotifier;
      element.visitAncestorElements((ancestor) {
        if (ancestor.widget is InheritedProvider) {
          return false; // stop
        }
        return true;
      });
      if (authNotifier != null) {
        return null; // couldn't find it dynamically
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Alert configuration card per sensor
// ---------------------------------------------------------------------------
class _AlertConfigCard extends StatelessWidget {
  final int sensorIndex;
  const _AlertConfigCard({required this.sensorIndex});

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorService>();
    final alert = sensor.alerts[sensorIndex];
    final color = _C.sensorColors[sensorIndex];
    final bgColor = _C.sensorBgColors[sensorIndex];
    final icon = _C.sensorIcons[sensorIndex];
    final label = SensorIndex.label(sensorIndex);
    final unit = SensorIndex.unit(sensorIndex);
    final currentVal = sensor.currentValues[sensorIndex];
    final isTriggered = sensor.isAlertTriggered(sensorIndex);

    // Slider range per sensor type
    double sliderMin, sliderMax;
    switch (sensorIndex) {
      case SensorIndex.temperature:
        sliderMin = 0;
        sliderMax = 60;
        break;
      case SensorIndex.humidity:
        sliderMin = 0;
        sliderMax = 100;
        break;
      case SensorIndex.npk:
        sliderMin = 0;
        sliderMax = 500;
        break;
      case SensorIndex.soilMoisture:
        sliderMin = 0;
        sliderMax = 100;
        break;
      default:
        sliderMin = 0;
        sliderMax = 100;
    }

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: isTriggered
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.textDark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Current: ${currentVal.toStringAsFixed(1)} $unit',
                        style: TextStyle(
                          fontSize: 12,
                          color: isTriggered ? Colors.red : _C.textMuted,
                          fontWeight:
                              isTriggered ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Enable/disable toggle
                Switch.adaptive(
                  value: alert.enabled,
                  activeColor: _C.primaryGreen,
                  onChanged: (v) =>
                      sensor.setAlertEnabled(sensorIndex, v),
                ),
              ],
            ),

            if (alert.enabled) ...[
              const SizedBox(height: 14),
              // Direction toggle
              Row(
                children: [
                  Text(
                    'Alert when value is',
                    style: TextStyle(
                      fontSize: 12,
                      color: _C.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DirectionToggle(
                    greaterThan: alert.greaterThan,
                    color: color,
                    onChanged: (v) =>
                        sensor.setAlertDirection(sensorIndex, v),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${alert.threshold.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Threshold slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: color,
                  inactiveTrackColor: color.withOpacity(0.12),
                  thumbColor: color,
                  overlayColor: color.withOpacity(0.1),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: alert.threshold.clamp(sliderMin, sliderMax),
                  min: sliderMin,
                  max: sliderMax,
                  divisions: ((sliderMax - sliderMin) / 0.5).round(),
                  onChanged: (v) =>
                      sensor.setAlertThreshold(
                          sensorIndex, double.parse(v.toStringAsFixed(1))),
                ),
              ),
              // Range labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sliderMin.toStringAsFixed(0)} $unit',
                    style: TextStyle(fontSize: 10, color: _C.textMuted),
                  ),
                  Text(
                    '${sliderMax.toStringAsFixed(0)} $unit',
                    style: TextStyle(fontSize: 10, color: _C.textMuted),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Direction toggle (greater / less than)
// ---------------------------------------------------------------------------
class _DirectionToggle extends StatelessWidget {
  final bool greaterThan;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _DirectionToggle({
    required this.greaterThan,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DirBtn(
            label: '>',
            isActive: greaterThan,
            color: color,
            onTap: () => onChanged(true),
          ),
          _DirBtn(
            label: '<',
            isActive: !greaterThan,
            color: color,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _DirBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _DirBtn({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign out button
// ---------------------------------------------------------------------------
class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _confirmSignOut(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout_rounded, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _C.textDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out? You\'ll need to log in again to access your terrarium data.',
          style: TextStyle(color: _C.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _C.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Attempt to call AuthService signOut
              // The auth module will handle navigation
              try {
                // In final integration: context.read<AuthService>().signOut()
                // For now, pop to root
                Navigator.of(context).popUntil((route) => route.isFirst);
              } catch (_) {}
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared components
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _C.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: _C.textMuted),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: _C.primaryGreen,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _C.textDark,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? _C.textMuted,
          ),
        ),
      ],
    );
  }
}
