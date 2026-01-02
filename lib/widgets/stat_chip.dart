import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/ui_constants.dart';

/// Reusable stat chip widget for displaying counts with icons
/// Used in attendance overview and dashboard for Present/Absent/At Risk badges
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isCompact;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(UIConstants.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: color),
          SizedBox(width: isCompact ? 4 : 6),
          if (!isCompact) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Preset stat chip variants for common use cases
class StatChipPresets {
  static Widget present(int count, {bool isCompact = false}) {
    return StatChip(
      icon: LucideIcons.check,
      label: 'Present',
      count: count,
      color: const Color(0xFF20B566),
      isCompact: isCompact,
    );
  }

  static Widget absent(int count, {bool isCompact = false}) {
    return StatChip(
      icon: LucideIcons.x,
      label: 'Absent',
      count: count,
      color: const Color(0xFFE85D4D),
      isCompact: isCompact,
    );
  }

  static Widget atRisk(int count, {bool isCompact = false}) {
    return StatChip(
      icon: LucideIcons.alertTriangle,
      label: 'At Risk',
      count: count,
      color: const Color(0xFFFFC107),
      isCompact: isCompact,
    );
  }

  static Widget dutyLeave(int count, {bool isCompact = false}) {
    return StatChip(
      icon: LucideIcons.clock,
      label: 'Duty Leave',
      count: count,
      color: const Color(0xFFFFA726),
      isCompact: isCompact,
    );
  }
}
