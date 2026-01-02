import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/theme_provider.dart';

class ColorCustomizerDialog extends StatelessWidget {
  const ColorCustomizerDialog({super.key});

  static const List<Map<String, dynamic>> _colorPresets = [
    {'name': 'Teal', 'color': Color(0xFF1CB5AD)}, // HSL(175, 75%, 45%)
    {'name': 'Orange', 'color': Color(0xFFFA6432)}, // HSL(25, 95%, 53%)
    {'name': 'Blue', 'color': Color(0xFF3B82F6)}, // HSL(217, 91%, 60%)
    {'name': 'Red', 'color': Color(0xFFEB5757)}, // HSL(0, 84%, 60%)
    {'name': 'Green', 'color': Color(0xFF22C55E)}, // HSL(142, 71%, 45%)
    {'name': 'Purple', 'color': Color(0xFFA855F7)}, // HSL(262, 83%, 58%)
    {'name': 'Black', 'color': Color(0xFF171717)}, // HSL(0, 0%, 9%)
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customize Colors',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your accent color:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                // 2 columns
                final width = (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorPresets.map((preset) {
                    final color = preset['color'] as Color;
                    final name = preset['name'] as String;
                    final isSelected =
                        themeProvider.accentColor.toARGB32() ==
                        color.toARGB32();

                    return _buildColorOption(
                      context,
                      name: name,
                      color: color,
                      isSelected: isSelected,
                      onTap: () => themeProvider.setAccentColor(color),
                      width: width,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context, {
    required String name,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required double width,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: name == 'Black' && isDark
                    ? Border.all(color: Colors.white24, width: 1)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
