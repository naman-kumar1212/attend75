import 'package:flutter/material.dart';
import 'attendance_ring.dart';

/// A card wrapper for AttendanceRing with tap interaction and theme styling
class SubjectRingCard extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final double size; // Restored
  final bool showCheckmark; // Restored
  final String? centerTextOverride; // Restored
  final double? padding;

  const SubjectRingCard({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
    this.subtitle,
    this.onTap,
    this.size = 220, // Default to main ring size
    this.showCheckmark = false,
    this.centerTextOverride,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Softer corners
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(
            padding ?? 24.0, // Reduced default from 32.0
          ),
          child: Center(
            child: AttendanceRing(
              value: value,
              maxValue: maxValue,
              label: label,
              color: color,
              size: size,
              subtitle: subtitle,
              showCheckmark: showCheckmark,
              centerTextOverride: centerTextOverride,
            ),
          ),
        ),
      ),
    );
  }
}
