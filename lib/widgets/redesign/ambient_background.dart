import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -MediaQuery.sizeOf(context).height * 0.1,
          left: -MediaQuery.sizeOf(context).width * 0.1,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.5,
            height: MediaQuery.sizeOf(context).width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 120,
                  spreadRadius: 40,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.sizeOf(context).height * 0.1,
          right: -MediaQuery.sizeOf(context).width * 0.1,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.4,
            height: MediaQuery.sizeOf(context).width * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.info.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.08),
                  blurRadius: 100,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
