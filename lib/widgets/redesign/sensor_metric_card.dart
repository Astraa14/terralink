import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'glass_card.dart';
import 'terra_badge.dart';

class SensorMetricCard extends StatelessWidget {
  final String name;
  final String value;
  final String status;
  final IconData icon;
  final Color accentColor;

  const SensorMetricCard({
    super.key,
    required this.name,
    required this.value,
    required this.status,
    required this.icon,
    required this.accentColor,
  });

  TerraBadgeVariant get _badgeVariant {
    if (status == 'Optimal' || status == 'Good' || status == 'Live') {
      return TerraBadgeVariant.primary;
    }
    return TerraBadgeVariant.warning;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              TerraBadge(label: status, variant: _badgeVariant),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
