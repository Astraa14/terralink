import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'terra_badge.dart';

enum FarmMetricSeverity { thriving, healthy, monitor, attention, critical }

enum SensorTrendDirection { rising, falling, steady }

class SensorMetricCard extends StatefulWidget {
  final String name;
  final String value;
  final String status;
  final IconData icon;
  final Color accentColor;
  final FarmMetricSeverity severity;
  final String optimalRangeLabel;
  final double referencePosition;
  final String trendLabel;
  final SensorTrendDirection trendDirection;
  final List<String> detailLines;

  const SensorMetricCard({
    super.key,
    required this.name,
    required this.value,
    required this.status,
    required this.icon,
    required this.accentColor,
    this.severity = FarmMetricSeverity.healthy,
    this.optimalRangeLabel = '',
    this.referencePosition = 0.5,
    this.trendLabel = 'Stable',
    this.trendDirection = SensorTrendDirection.steady,
    this.detailLines = const [],
  });

  @override
  State<SensorMetricCard> createState() => _SensorMetricCardState();
}

class _SensorMetricCardState extends State<SensorMetricCard> {
  bool _expanded = false;

  TerraBadgeVariant get _badgeVariant {
    return switch (widget.severity) {
      FarmMetricSeverity.thriving || FarmMetricSeverity.healthy =>
        TerraBadgeVariant.primary,
      FarmMetricSeverity.monitor => TerraBadgeVariant.warning,
      FarmMetricSeverity.attention => TerraBadgeVariant.warning,
      FarmMetricSeverity.critical => TerraBadgeVariant.critical,
    };
  }

  IconData get _badgeIcon {
    return switch (widget.severity) {
      FarmMetricSeverity.thriving => Icons.trending_up_rounded,
      FarmMetricSeverity.healthy => Icons.check_circle_outline_rounded,
      FarmMetricSeverity.monitor => Icons.visibility_outlined,
      FarmMetricSeverity.attention => Icons.report_problem_outlined,
      FarmMetricSeverity.critical => Icons.priority_high_rounded,
    };
  }

  IconData get _trendIcon {
    return switch (widget.trendDirection) {
      SensorTrendDirection.rising => Icons.north_east_rounded,
      SensorTrendDirection.falling => Icons.south_east_rounded,
      SensorTrendDirection.steady => Icons.trending_flat_rounded,
    };
  }

  Color get _severityColor {
    return switch (widget.severity) {
      FarmMetricSeverity.thriving || FarmMetricSeverity.healthy =>
        AppColors.statusGreen,
      FarmMetricSeverity.monitor => AppColors.statusYellow,
      FarmMetricSeverity.attention => AppColors.statusOrange,
      FarmMetricSeverity.critical => AppColors.statusRed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.referencePosition.clamp(0.0, 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _expanded = true),
      onExit: (_) => setState(() => _expanded = false),
      child: GestureDetector(
        onLongPressStart: (_) => setState(() => _expanded = true),
        onLongPressEnd: (_) => setState(() => _expanded = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: _expanded ? 1.015 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              color: AppColors.instrument,
              border: Border.all(
                color: _expanded
                    ? widget.accentColor.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.09),
                width: _expanded ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: _expanded ? 20 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(AppColors.radiusSm),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(widget.icon, size: 21, color: widget.accentColor),
                      ),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TerraBadge(
                            label: widget.status,
                            variant: _badgeVariant,
                            icon: _badgeIcon,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ReferenceBar(
                    accentColor: widget.accentColor,
                    severityColor: _severityColor,
                    position: position,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(_trendIcon, color: _severityColor, size: 15),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.trendLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.optimalRangeLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.optimalRangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: _expanded && widget.detailLines.isNotEmpty
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.detailLines
                            .map((line) => _DetailChip(label: line))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceBar extends StatelessWidget {
  final Color accentColor;
  final Color severityColor;
  final double position;

  const _ReferenceBar({
    required this.accentColor,
    required this.severityColor,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerLeft = (constraints.maxWidth * position - 4)
              .clamp(0.0, constraints.maxWidth - 8)
              .toDouble();

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.statusOrange.withValues(alpha: 0.45),
                      accentColor.withValues(alpha: 0.7),
                      AppColors.statusYellow.withValues(alpha: 0.45),
                    ],
                    stops: const [0.0, 0.58, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: markerLeft,
                child: Container(
                  width: 8,
                  height: 12,
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.foreground, width: 1.2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;

  const _DetailChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
