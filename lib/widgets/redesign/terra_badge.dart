import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum TerraBadgeVariant { primary, warning, critical, info, outline }

class TerraBadge extends StatelessWidget {
  final String label;
  final TerraBadgeVariant variant;
  final IconData? icon;

  const TerraBadge({
    super.key,
    required this.label,
    this.variant = TerraBadgeVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = switch (variant) {
      TerraBadgeVariant.primary => AppColors.primary,
      TerraBadgeVariant.warning => AppColors.statusYellow,
      TerraBadgeVariant.critical => AppColors.statusRed,
      TerraBadgeVariant.info => AppColors.info,
      TerraBadgeVariant.outline => AppColors.mutedForeground,
    };
    final isOutline = variant == TerraBadgeVariant.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isOutline ? AppColors.border : fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isOutline ? AppColors.mutedForeground : AppColors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
