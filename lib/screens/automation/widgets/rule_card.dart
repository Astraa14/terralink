import 'package:flutter/material.dart';
import '../../../models/automation_rule.dart';

/// A card widget displaying a single automation rule with toggle and status.
class RuleCard extends StatelessWidget {
  final AutomationRule rule;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const RuleCard({
    super.key,
    required this.rule,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sensor = rule.sensor;
    final bgColor = Color(sensor.colorBg);
    final fgColor = Color(sensor.colorText);
    final isActive = rule.isEnabled && !rule.isInCooldown;

    return Dismissible(
      key: Key(rule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Rule'),
            content: Text('Remove "${rule.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rule.isEnabled
                  ? fgColor.withOpacity(0.15)
                  : const Color(0xFFE8EAED),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                // Top row: sensor icon, name, status, toggle
                Row(
                  children: [
                    // Sensor icon badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(sensor.icon, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    // Name and sensor
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: rule.isEnabled
                                  ? const Color(0xFF1E2022)
                                  : const Color(0xFF8A9099),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sensor.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: fgColor.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _StatusBadge(rule: rule),
                    const SizedBox(width: 8),
                    // Toggle switch
                    SizedBox(
                      height: 28,
                      child: Switch.adaptive(
                        value: rule.isEnabled,
                        onChanged: (_) => onToggle(),
                        activeColor: const Color(0xFF388E3C),
                        activeTrackColor: const Color(0xFF388E3C).withOpacity(0.3),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Divider
                Container(
                  height: 1,
                  color: const Color(0xFFF0F1F3),
                ),
                const SizedBox(height: 12),
                // Condition row
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: rule.isEnabled ? fgColor : const Color(0xFFB0B5BD),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'When ${rule.conditionText}',
                        style: TextStyle(
                          fontSize: 13,
                          color: rule.isEnabled
                              ? const Color(0xFF3D4249)
                              : const Color(0xFFB0B5BD),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Action row
                Row(
                  children: [
                    Icon(
                      _actionIcon(rule.action),
                      size: 16,
                      color: rule.isEnabled ? fgColor : const Color(0xFFB0B5BD),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rule.actionText,
                        style: TextStyle(
                          fontSize: 13,
                          color: rule.isEnabled
                              ? const Color(0xFF3D4249)
                              : const Color(0xFFB0B5BD),
                        ),
                      ),
                    ),
                    // Cooldown indicator
                    if (rule.cooldownSeconds > 0) ...[
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCooldown(rule.cooldownSeconds),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
                // Description (if present)
                if (rule.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    rule.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _actionIcon(RuleAction action) {
    switch (action) {
      case RuleAction.sendCommand:
        return Icons.bluetooth_rounded;
      case RuleAction.triggerAlert:
        return Icons.notifications_active_outlined;
      case RuleAction.enableDevice:
        return Icons.power_settings_new_rounded;
      case RuleAction.disableDevice:
        return Icons.power_off_rounded;
    }
  }

  String _formatCooldown(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    return '${(seconds / 3600).round()}h';
  }
}

/// Small status badge showing Active / Cooldown / Disabled.
class _StatusBadge extends StatelessWidget {
  final AutomationRule rule;

  const _StatusBadge({required this.rule});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    if (!rule.isEnabled) {
      bg = const Color(0xFFF0F1F3);
      fg = const Color(0xFF8A9099);
      label = 'OFF';
    } else if (rule.isInCooldown) {
      bg = const Color(0xFFFFF7F2);
      fg = const Color(0xFFE65100);
      label = '${rule.cooldownRemaining}s';
    } else {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF388E3C);
      label = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
