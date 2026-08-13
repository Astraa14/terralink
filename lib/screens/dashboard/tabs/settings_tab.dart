import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/bluetooth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/redesign/glass_card.dart';
import '../../../widgets/redesign/terra_badge.dart';
import '../../../widgets/redesign/terra_switch.dart';

class SettingsTab extends StatefulWidget {
  final AuthService authService;
  final BluetoothManagerService btService;
  final bool isDemoMode;
  final ValueChanged<bool> onDemoModeChanged;
  final VoidCallback onConnectDevice;

  const SettingsTab({
    super.key,
    required this.authService,
    required this.btService,
    required this.isDemoMode,
    required this.onDemoModeChanged,
    required this.onConnectDevice,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _darkTheme = true;
  bool _notifications = true;
  String _tempUnit = 'Celsius (°C)';
  String _cropType = 'Leafy greens';
  String _soilType = 'Loam';
  String _irrigation = 'Drip';
  String _climate = 'Warm humid';

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final initial = (user?.displayName.isNotEmpty == true)
        ? user!.displayName[0].toUpperCase()
        : 'G';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        const Text(
          'Farm Settings',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tune TerraLink to your crop, soil, and field equipment.',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.cropGreen, AppColors.earthBrown],
                  ),
                  border: Border.all(color: AppColors.softTan.withValues(alpha: 0.22)),
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Guest Farmer',
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? 'Guest field session',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OutlineButton(
                label: 'Farm Profile',
                icon: Icons.agriculture_outlined,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineButton(
                label: 'Sign Out',
                icon: Icons.logout_rounded,
                destructive: true,
                onTap: () => widget.authService.signOut(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _sectionTitle('Farm Details', Icons.map_outlined),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.eco_outlined,
                label: 'Crop Type',
                subtitle: 'Used for contextual target ranges',
                trailing: _Dropdown(
                  value: _cropType,
                  values: const ['Leafy greens', 'Tomato', 'Corn', 'Herbs'],
                  onChanged: (v) => setState(() => _cropType = v),
                ),
              ),
              _divider(),
              _SettingsRow(
                icon: Icons.layers_outlined,
                label: 'Soil Type',
                subtitle: 'Clay holds water longer than sandy soil',
                trailing: _Dropdown(
                  value: _soilType,
                  values: const ['Loam', 'Clay', 'Sandy', 'Silt'],
                  onChanged: (v) => setState(() => _soilType = v),
                ),
              ),
              _divider(),
              _SettingsRow(
                icon: Icons.water_drop_outlined,
                label: 'Irrigation',
                subtitle: 'Helps frame watering advice',
                trailing: _Dropdown(
                  value: _irrigation,
                  values: const ['Drip', 'Sprinkler', 'Flood', 'Manual'],
                  onChanged: (v) => setState(() => _irrigation = v),
                ),
              ),
              _divider(),
              _SettingsRow(
                icon: Icons.wb_sunny_outlined,
                label: 'Climate Zone',
                subtitle: 'Adjusts how alerts are interpreted',
                trailing: _Dropdown(
                  value: _climate,
                  values: const ['Warm humid', 'Dry heat', 'Temperate', 'Cool'],
                  onChanged: (v) => setState(() => _climate = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle('Equipment', Icons.sensors_outlined),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.sensors_outlined,
                        color: AppColors.primary,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TerraNode Field Module',
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.btService.isConnected
                                ? 'Live feed active • signal strong'
                                : 'Not linked • tap to connect',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TerraBadge(
                      label: widget.btService.isConnected ? 'Connected' : 'Offline',
                      variant: widget.btService.isConnected
                          ? TerraBadgeVariant.primary
                          : TerraBadgeVariant.critical,
                      icon: widget.btService.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                    ),
                  ],
                ),
              ),
              _divider(),
              _SettingsLink(
                icon: widget.btService.isConnected
                    ? Icons.link_off_rounded
                    : Icons.bluetooth_searching_rounded,
                label: widget.btService.isConnected ? 'Disconnect Module' : 'Connect Module',
                color: widget.btService.isConnected ? AppColors.statusOrange : AppColors.primary,
                onTap: widget.btService.isConnected
                    ? widget.btService.disconnect
                    : widget.onConnectDevice,
              ),
              _divider(),
              _SettingsLink(
                icon: Icons.tune_rounded,
                label: 'Quick Sensor Calibration',
                color: AppColors.softTan,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle('Preferences', Icons.notifications_active_outlined),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.dark_mode_outlined,
                label: 'Outdoor Dark Theme',
                subtitle: 'High-contrast glass surfaces for field use',
                trailing: TerraSwitch(
                  value: _darkTheme,
                  onChanged: (v) => setState(() => _darkTheme = v),
                ),
              ),
              _divider(),
              _SettingsRow(
                icon: Icons.science_outlined,
                label: 'Demo Field',
                subtitle: 'Use simulated sensor data',
                trailing: TerraSwitch(
                  value: widget.isDemoMode,
                  onChanged: widget.onDemoModeChanged,
                ),
              ),
              _divider(),
              _SettingsRow(
                icon: Icons.thermostat_outlined,
                label: 'Temperature Unit',
                subtitle: 'Displayed across charts and alerts',
                trailing: _Dropdown(
                  value: _tempUnit,
                  values: const ['Celsius (°C)', 'Fahrenheit (°F)'],
                  onChanged: (v) => setState(() => _tempUnit = v),
                ),
              ),
              _divider(),
              _SettingsRow(
                icon: Icons.notification_important_outlined,
                label: 'Critical Alerts',
                subtitle: 'Persistent alerts for dry soil or equipment failure',
                trailing: TerraSwitch(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle('Data', Icons.cloud_sync_outlined),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsLink(
                icon: Icons.backup_outlined,
                label: 'Back Up Field Data',
                color: AppColors.primary,
                onTap: () {},
              ),
              _divider(),
              _SettingsLink(
                icon: Icons.file_download_outlined,
                label: 'Export Soil Records',
                color: AppColors.npk,
                onTap: () {},
              ),
              _divider(),
              _SettingsLink(
                icon: Icons.sync_outlined,
                label: 'Cloud Sync',
                color: AppColors.info,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle('Calibration & Support', Icons.handyman_outlined),
        const SizedBox(height: 12),
        const _CalibrationGuide(),
        const SizedBox(height: 16),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsLink(
                icon: Icons.help_outline_rounded,
                label: 'Agronomy Help',
                color: AppColors.softTan,
                onTap: () {},
              ),
              _divider(),
              _SettingsLink(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                color: AppColors.mutedForeground,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'TerraLink App v1.0.0 (Build 1)',
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.softTan, size: 16),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      dropdownColor: AppColors.instrument,
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      style: const TextStyle(
        color: AppColors.foreground,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.softTan, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SettingsLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.statusRed : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalibrationGuide extends StatelessWidget {
  const _CalibrationGuide();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Place probe', 'Insert sensors into firm soil near active roots.'),
      ('Settle reading', 'Wait one minute before recording a baseline.'),
      ('Check water', 'Compare moisture after a small irrigation pass.'),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.softTan.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.softTan.withValues(alpha: 0.24)),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.softTan,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$1,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.$2,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
