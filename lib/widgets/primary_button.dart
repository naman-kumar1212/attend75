import 'package:flutter/material.dart';
import '../widgets/animated_interactions.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingText;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on Theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Default to Primary color, or disabled color
    final isEnabled = onPressed != null && !isLoading;
    final backgroundColor = isEnabled
        ? colorScheme.primary
        : theme.disabledColor;

    // We use ScaleTap to provide the scale effect.
    // We use Material+InkWell to provide the Visuals + Ripple.
    // ScaleTap handles the scaling on press. InkWell handles the Color splash.
    // They can coexist if ScaleTap wraps Material.

    // Note: InkWell needs to handle the tap for the ripple to show.
    // And ScaleTap needs to detect the tap to scale.
    // If InkWell handles onTap, ScaleTap (GestureDetector) might assume child handled it?
    // ScaleTap typically uses Listener or generic hit test.
    // Our ScaleTap implementation uses GestureDetector.
    // If inner InkWell handles onTap, outer ScaleTap might not trigger depending on behavior.
    // But usually bubling works or we use behavior.
    // The ScaleTap class I wrote uses `HitTestBehavior.opaque` by default.

    // Let's rely on ScaleTap having `onTap`, and InkWell existing PURELY for decoration (onTap: null?)
    // No, if InkWell onTap is null, it doesn't ripple.
    // If I pass the SAME onTap to both, they both fire?
    // Let's Try: Outer ScaleTap handles the functional `onTap`. Inner InkWell has an empty `(){}` just for visual ripple?
    // That triggers double tap logic potentially.

    // Safe bet: ScaleTap wraps everything. Inner Container just has static style.
    // User constraint: "Animation style... Optional color or opacity shift".
    // I will simplify: ScaleTap -> Material -> Container (with color).
    // I won't worry about the Ripple if it complicates the Scale. The Scale IS the feedback.

    return ScaleTap(
      onTap: isEnabled ? () => onPressed?.call() : () {},
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 0, // Flat
        child: Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // We can add a subtle border if needed likely not for Primary
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    if (loadingText != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        loadingText!,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: theme.colorScheme.onPrimary),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
