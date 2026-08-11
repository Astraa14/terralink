import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum TerraBadgeVariant { primary, warning, critical, info, outline }

class TerraBadge extends StatelessWidget {
  final String label;
  final TerraBadgeVariant variant;

  const TerraBadge({
    super.key,
    required this.label,
    this.variant = TerraBadgeVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      TerraBadgeVariant.primary => (
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.3),
        ),
      TerraBadgeVariant.warning => (
          AppColors.warning.withValues(alpha: 0.2),
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.3),
        ),
      TerraBadgeVariant.critical => (
          AppColors.critical.withValues(alpha: 0.2),
          AppColors.critical,
          AppColors.critical.withValues(alpha: 0.3),
        ),
      TerraBadgeVariant.info => (
          AppColors.info.withValues(alpha: 0.2),
          AppColors.info,
          AppColors.info.withValues(alpha: 0.3),
        ),
      TerraBadgeVariant.outline => (
          Colors.transparent,
          AppColors.mutedForeground,
          AppColors.border,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
