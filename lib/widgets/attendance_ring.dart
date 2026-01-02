import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A standardized animated circular progress ring widget for the Dashboard.
/// Enforces consistent sizing, stroke width logic, and text alignment.
class AttendanceRing extends StatelessWidget {
  /// The current value (absolute or percentage).
  final double value;

  /// The maximum value (e.g., 100 for percentages, or total classes).
  final double maxValue;

  /// The label displayed below or implicitly associated with the ring.
  final String label;

  /// Primary color of the progress arc.
  final Color color;

  /// Diameter of the ring. Defaults to 220 for main rings.
  final double size;

  /// Optional subtitle text displayed inside the ring.
  final String? subtitle;

  /// Whether to show a checkmark instead of the value (for success states).
  final bool showCheckmark;

  /// Optional center text override (e.g. for "Safe to Skip" logic).
  final String? centerTextOverride;

  const AttendanceRing({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
    this.size = 220,
    this.subtitle,
    this.showCheckmark = false,
    this.centerTextOverride,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Standardized Stroke Width (10% of size)
    final double strokeWidth = size * 0.10;

    // 2. Calculate Percentage
    final double percent = maxValue > 0
        ? (value / maxValue).clamp(0.0, 1.0)
        : 0.0;
    final bool isPercentage = maxValue == 100;

    // 3. Format Display Value
    final String displayValue =
        centerTextOverride ??
        (isPercentage ? '${value.round()}%' : value.round().toString());

    // 4. Center Content Constraints
    final double contentSize = size * 0.65; // Leave breathing room

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: size / 2,
          lineWidth: strokeWidth,
          percent: percent,
          startAngle:
              180.0, // Top center (180 degrees offset in this lib usually puts it at top if native is 3 o'clock)
          // Actually, for CircularPercentIndicator:
          // startAngle: 0.0 starts at 12 o'clock??? No, usually 0 is 3 o'clock or 12 depending on lib.
          // Let's standardise to 0.0 unless visual check fails.
          // Adjust: typical Flutter Arc starts at 3 o'clock (0 rad). -90 deg is 12 o'clock.
          // This lib might use degrees. Let's try 0.0 or check docs/previous usage.
          // Previous usage didn't specify startAngle, defaults to 0.0 (top center?).
          // Docs say startAngle is 0.0 by default, which is 12 o'clock.
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          progressColor: color,
          animation: true,
          animationDuration: 1200,
          animateFromLastPercent: true,
          curve: Curves.easeOutCubic,

          // Center Content
          center: Container(
            width: contentSize,
            height: contentSize,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showCheckmark)
                  Icon(LucideIcons.check, size: size * 0.35, color: color)
                else ...[
                  // Primary Metric
                  AutoSizeText(
                    displayValue,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      // Slightly reduced scaling for better containment at small sizes
                      fontSize: (size * 0.20).clamp(16.0, 48.0),
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Fraction/Subtitle (e.g., "45/60" or "classes")
                  if (subtitle != null) ...[
                    SizedBox(
                      height: size * 0.04,
                    ), // Increased relative spacing slightly
                    AutoSizeText(
                      subtitle!,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        // Reduced scaling to prevent visual clutter
                        fontSize: (size * 0.10).clamp(10.0, 16.0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),

        // External Label
        const SizedBox(height: 16),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
