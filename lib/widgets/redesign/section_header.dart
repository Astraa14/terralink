import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.softTan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    border: Border.all(
                      color: AppColors.softTan.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(icon, color: AppColors.softTan, size: 18),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(48, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

class PillSelector extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  const PillSelector({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(options.length, (i) {
            final selected = i == selectedIndex;
            return GestureDetector(
              onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.mutedForeground,
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? AppColors.primaryForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
