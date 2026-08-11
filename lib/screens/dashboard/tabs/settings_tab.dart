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
          'Settings',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.info],
                  ),
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
                      fontWeight: FontWeight.bold,
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
                      user?.displayName ?? 'Guest User',
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? 'Guest session',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 14,
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
              child: _OutlineButton(label: 'Edit Profile', onTap: () {}),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineButton(
                label: 'Sign Out',
                destructive: true,
                onTap: () => widget.authService.signOut(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _sectionTitle('App Preferences'),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsRow(
                label: 'Dark Theme',
                trailing: TerraSwitch(
                  value: _darkTheme,
                  onChanged: (v) => setState(() => _darkTheme = v),
                ),
              ),
              _divider(),
              _SettingsRow(
                label: 'Demo Mode',
                trailing: TerraSwitch(
                  value: widget.isDemoMode,
                  onChanged: widget.onDemoModeChanged,
                ),
              ),
              _divider(),
              _SettingsRow(
                label: 'Temperature Unit',
                trailing: DropdownButton<String>(
                  value: _tempUnit,
                  underline: const SizedBox.shrink(),
                  dropdownColor: const Color(0xFF18181B),
                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                  items: const [
                    DropdownMenuItem(value: 'Celsius (°C)', child: Text('Celsius (°C)')),
                    DropdownMenuItem(value: 'Fahrenheit (°F)', child: Text('Fahrenheit (°F)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _tempUnit = v);
                  },
                ),
              ),
              _divider(),
              _SettingsRow(
                label: 'Push Notifications',
                trailing: TerraSwitch(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _sectionTitle('Hardware'),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bluetooth, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'TerraNode Alpha',
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TerraBadge(
                          label: widget.btService.isConnected ? 'Connected' : 'Offline',
                          variant: widget.btService.isConnected
                              ? TerraBadgeVariant.primary
                              : TerraBadgeVariant.outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.btService.isConnected
                          ? 'Live feed active • Signal strong'
                          : 'Not linked • Tap to connect',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _divider(),
              _SettingsLink(
                label: widget.btService.isConnected ? 'Disconnect Device' : '+ Connect Device',
                onTap: widget.btService.isConnected
                    ? widget.btService.disconnect
                    : widget.onConnectDevice,
              ),
              _divider(),
              _SettingsLink(label: 'Calibrate Sensors', onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _sectionTitle('About & Support'),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsLink(label: 'Help Center & FAQ', onTap: () {}),
              _divider(),
              _SettingsLink(label: 'Report a Bug', onTap: () {}),
              _divider(),
              _SettingsLink(label: 'Privacy Policy', onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'TerraLink App v1.0.0 (Build 1)',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget trailing;

  const _SettingsRow({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SettingsLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              color: label.startsWith('+') || label.contains('Connect')
                  ? AppColors.primary
                  : AppColors.foreground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _OutlineButton({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.critical.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: destructive
                ? AppColors.critical.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: destructive ? AppColors.critical : AppColors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
