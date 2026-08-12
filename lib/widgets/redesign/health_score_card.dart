import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'glass_card.dart';
import 'terra_badge.dart';

class HealthFactorStatus {
  final String label;
  final String status;
  final IconData icon;
  final Color color;

  const HealthFactorStatus({
    required this.label,
    required this.status,
    required this.icon,
    required this.color,
  });
}

class HealthScoreCard extends StatelessWidget {
  final int score;
  final String label;
  final String statusText;
  final bool isConnected;
  final bool isDemoMode;
  final String insight;
  final String trendLabel;
  final List<HealthFactorStatus> factors;

  const HealthScoreCard({
    super.key,
    required this.score,
    required this.label,
    required this.statusText,
    required this.isConnected,
    required this.isDemoMode,
    this.insight = 'Soil readings are being evaluated.',
    this.trendLabel = 'Stable since last check',
    this.factors = const [],
  });

  Color get _scoreColor {
    if (score >= 80) return AppColors.statusGreen;
    if (score >= 60) return AppColors.statusYellow;
    if (score >= 40) return AppColors.statusOrange;
    return AppColors.statusRed;
  }

  TerraBadgeVariant get _connectionVariant {
    if (isConnected || isDemoMode) return TerraBadgeVariant.primary;
    return TerraBadgeVariant.critical;
  }

  @override
  Widget build(BuildContext context) {
    final shownFactors = factors.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _scoreColor.withValues(alpha: 0.26),
            AppColors.earthBrown.withValues(alpha: 0.12),
            AppColors.richSoil.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: _scoreColor.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: _scoreColor.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: GlassCard(
        gradient: false,
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Soil Health Assessment',
                    style: TextStyle(
                      color: AppColors.softTan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TerraBadge(
                  label: statusText,
                  variant: _connectionVariant,
                  icon: isConnected
                      ? Icons.sensors_rounded
                      : isDemoMode
                          ? Icons.science_outlined
                          : Icons.cloud_off_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ScoreCluster(
                  score: score,
                  color: _scoreColor,
                  factors: shownFactors,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        insight,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            trendLabel.contains('down') || trendLabel.contains('needs')
                                ? Icons.south_east_rounded
                                : Icons.north_east_rounded,
                            color: _scoreColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              trendLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _scoreColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (shownFactors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shownFactors
                    .map(
                      (factor) => _FactorChip(factor: factor),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreCluster extends StatelessWidget {
  final int score;
  final Color color;
  final List<HealthFactorStatus> factors;

  const _ScoreCluster({
    required this.score,
    required this.color,
    required this.factors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(108, 108),
            painter: _HealthRingPainter(
              progress: score / 100,
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Text(
                'score',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          for (var i = 0; i < factors.length; i++)
            Positioned(
              left: i == 0 || i == 2 ? 0 : null,
              right: i == 1 || i == 3 ? 0 : null,
              top: i < 2 ? 4 : null,
              bottom: i >= 2 ? 4 : null,
              child: _FactorDot(factor: factors[i]),
            ),
        ],
      ),
    );
  }
}

class _FactorDot extends StatelessWidget {
  final HealthFactorStatus factor;

  const _FactorDot({required this.factor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: factor.color.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: factor.color.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: factor.color.withValues(alpha: 0.16),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(factor.icon, size: 17, color: factor.color),
    );
  }
}

class _FactorChip extends StatelessWidget {
  final HealthFactorStatus factor;

  const _FactorChip({required this.factor});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: factor.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: factor.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(factor.icon, color: factor.color, size: 14),
          const SizedBox(width: 6),
          Text(
            '${factor.label}: ${factor.status}',
            style: TextStyle(
              color: factor.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HealthRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    const stroke = 5.0;

    final bg = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.28318 * progress.clamp(0.0, 1.0).toDouble(),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
