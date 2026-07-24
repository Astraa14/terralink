import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final int index;
  final String title;
  final String value;
  final String unit;
  final String statusLabel;
  final Color statusColor;
  final Color bgColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback? onAlertTap;

  const MetricCard({
    super.key,
    required this.index,
    required this.title,
    required this.value,
    required this.unit,
    required this.statusLabel,
    required this.statusColor,
    required this.bgColor,
    required this.textColor,
    required this.icon,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAlert = statusLabel == 'Alert';

    return GestureDetector(
      onTap: onAlertTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: isAlert
              ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: icon + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: textColor, size: 22),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAlert
                          ? Colors.red.withOpacity(0.12)
                          : statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAlert) ...[
                          Icon(Icons.warning_amber_rounded,
                              size: 13, color: Colors.red),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAlert ? Colors.red : statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.65),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              // Value + unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
