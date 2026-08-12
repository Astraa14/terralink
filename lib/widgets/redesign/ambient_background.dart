import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF08130F),
            Color(0xFF0B1510),
            Color(0xFF16140E),
            Color(0xFF23180F),
          ],
          stops: [0.0, 0.42, 0.62, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _FieldTexturePainter()),
          child,
        ],
      ),
    );
  }
}

class _FieldTexturePainter extends CustomPainter {
  const _FieldTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.43;
    final horizonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x3322C55E),
          Color(0x228B5E34),
          Color(0x0038BDF8),
        ],
      ).createShader(Rect.fromLTWH(0, horizonY - 70, size.width, 150));

    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 70, size.width, 150),
      horizonPaint,
    );

    final soilWash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.richSoil.withValues(alpha: 0.08),
          AppColors.earthBrown.withValues(alpha: 0.18),
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY));
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      soilWash,
    );

    final rowPaint = Paint()
      ..color = AppColors.softTan.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    final cropRowPaint = Paint()
      ..color = AppColors.cropGreen.withValues(alpha: 0.04)
      ..strokeWidth = 1.2;

    for (var i = 0; i < 9; i++) {
      final startX = size.width * (i / 8);
      final path = Path()
        ..moveTo(size.width / 2, horizonY + 12)
        ..quadraticBezierTo(
          startX,
          size.height * 0.72,
          startX + (startX - size.width / 2) * 0.62,
          size.height + 40,
        );
      canvas.drawPath(path, i.isEven ? rowPaint : cropRowPaint);
    }

    final contourPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;

    for (var i = 0; i < 10; i++) {
      final y = horizonY + 34 + i * 34.0;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 56) {
        path.quadraticBezierTo(
          x + 28,
          y + (i.isEven ? 6 : -5),
          x + 56,
          y,
        );
      }
      canvas.drawPath(path, contourPaint);
    }

    final speckPaint = Paint()..color = AppColors.softTan.withValues(alpha: 0.055);
    for (var i = 0; i < 90; i++) {
      final x = ((i * 73) % size.width.toInt()).toDouble();
      final y = horizonY + 24 + ((i * 37) % (size.height - horizonY).toInt()).toDouble();
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 0.9 : 0.55, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FieldTexturePainter oldDelegate) => false;
}
