import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TerraBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TerraBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.show_chart_outlined, Icons.show_chart_rounded, 'Analytics'),
    (Icons.tune_outlined, Icons.tune_rounded, 'Automation'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.95),
                AppColors.background.withValues(alpha: 0),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = selectedIndex == index;
              return GestureDetector(
                onTap: () => onSelected(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  height: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isActive)
                        Container(
                          width: 32,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                      Icon(
                        isActive ? item.$2 : item.$1,
                        size: 24,
                        color: isActive ? AppColors.primary : AppColors.mutedForeground,
                      ),
                      const SizedBox(height: 2),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isActive ? 1 : 0,
                        child: Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color: isActive ? AppColors.primary : AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
