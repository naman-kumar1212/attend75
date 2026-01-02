import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A reusable animated circular progress ring widget
/// Displays a metric value with a circular progress indicator
class SubjectProgressRing extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final Color color;
  final double size;
  final String? subtitle;
  final bool showCheckmark;

  const SubjectProgressRing({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
    this.size = 92,
    this.subtitle,
    this.showCheckmark = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage (0.0 to 1.0)
    final percent = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    // Determine if value is a percentage (maxValue == 100)
    final isPercentage = maxValue == 100;

    // Format display value
    final displayValue = isPercentage
        ? '${value.round()}%'
        : value.round().toString();

    // Calculate constraints for center content (70% of ring diameter)
    final maxContentWidth = size * 0.7;

    // Calculate padding proportional to ring size
    final centerPadding = size * 0.1;

    return Semantics(
      label: '$label: $displayValue${subtitle != null ? ", $subtitle" : ""}',
      child: CircularPercentIndicator(
        radius: size / 2,
        lineWidth: 14.0, // Increased from 12.0 for better visual weight
        percent: percent,
        center: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.all(centerPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showCheckmark)
                  Icon(
                    LucideIcons.check,
                    size: size * 0.4,
                    color: color, // Match ring color
                  )
                else
                  AutoSizeText(
                    displayValue,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: size * 0.22, // Scale based on ring size
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (subtitle != null) ...[
                  SizedBox(height: size * 0.02),
                  AutoSizeText(
                    subtitle!,
                    maxLines: 2,
                    minFontSize: 8,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: size * 0.12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: color,
        backgroundColor: color.withValues(alpha: 0.15),
        animation: true,
        animationDuration: 600,
        animateFromLastPercent: true,
        curve: Curves.easeInOut,
      ),
    );
  }
}
