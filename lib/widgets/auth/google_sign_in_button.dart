import 'package:flutter/material.dart';

/// A styled "Continue with Google" button for OAuth authentication.
/// Matches official Google Sign-In branding guidelines.
/// Used on both sign-in and sign-up pages.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Sign in with Google',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Official Google button colors
    final bgColor = isDark ? const Color(0xFF131314) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final borderColor = isDark
        ? const Color(0xFF8E918F)
        : const Color(0xFF747775);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Official Google "G" Logo
                      const _GoogleLogo(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontFamily: 'Roboto',
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Official Google "G" logo using CustomPainter
/// Based on Google's brand guidelines
class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(size: Size(size, size), painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24;

    // Google colors
    const googleBlue = Color(0xFF4285F4);
    const googleRed = Color(0xFFEA4335);
    const googleYellow = Color(0xFFFBBC05);
    const googleGreen = Color(0xFF34A853);

    final paint = Paint()..style = PaintingStyle.fill;

    // Blue section (right arc)
    paint.color = googleBlue;
    final bluePath = Path()
      ..moveTo(23.52 * scale, 12.27 * scale)
      ..cubicTo(
        23.52 * scale,
        11.48 * scale,
        23.45 * scale,
        10.73 * scale,
        23.32 * scale,
        10 * scale,
      )
      ..lineTo(12 * scale, 10 * scale)
      ..lineTo(12 * scale, 14.26 * scale)
      ..lineTo(18.48 * scale, 14.26 * scale)
      ..cubicTo(
        18.21 * scale,
        15.63 * scale,
        17.44 * scale,
        16.79 * scale,
        16.28 * scale,
        17.57 * scale,
      )
      ..lineTo(16.28 * scale, 20.34 * scale)
      ..lineTo(20.06 * scale, 20.34 * scale)
      ..cubicTo(
        22.24 * scale,
        18.35 * scale,
        23.52 * scale,
        15.56 * scale,
        23.52 * scale,
        12.27 * scale,
      )
      ..close();
    canvas.drawPath(bluePath, paint);

    // Green section (bottom arc)
    paint.color = googleGreen;
    final greenPath = Path()
      ..moveTo(12 * scale, 24 * scale)
      ..cubicTo(
        14.97 * scale,
        24 * scale,
        17.46 * scale,
        23.02 * scale,
        19.28 * scale,
        21.4 * scale,
      )
      ..lineTo(16.28 * scale, 17.57 * scale)
      ..cubicTo(
        15.28 * scale,
        18.23 * scale,
        14.03 * scale,
        18.63 * scale,
        12 * scale,
        18.63 * scale,
      )
      ..cubicTo(
        9.14 * scale,
        18.63 * scale,
        6.71 * scale,
        16.64 * scale,
        5.84 * scale,
        13.96 * scale,
      )
      ..lineTo(1.96 * scale, 13.96 * scale)
      ..lineTo(1.96 * scale, 16.82 * scale)
      ..cubicTo(
        4.19 * scale,
        21.24 * scale,
        7.77 * scale,
        24 * scale,
        12 * scale,
        24 * scale,
      )
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow section (left bottom arc)
    paint.color = googleYellow;
    final yellowPath = Path()
      ..moveTo(5.84 * scale, 13.96 * scale)
      ..cubicTo(
        5.59 * scale,
        13.26 * scale,
        5.45 * scale,
        12.51 * scale,
        5.45 * scale,
        11.73 * scale,
      )
      ..cubicTo(
        5.45 * scale,
        10.95 * scale,
        5.59 * scale,
        10.21 * scale,
        5.84 * scale,
        9.5 * scale,
      )
      ..lineTo(5.84 * scale, 6.65 * scale)
      ..lineTo(1.96 * scale, 6.65 * scale)
      ..cubicTo(
        1.18 * scale,
        8.18 * scale,
        0.73 * scale,
        9.9 * scale,
        0.73 * scale,
        11.73 * scale,
      )
      ..cubicTo(
        0.73 * scale,
        13.56 * scale,
        1.18 * scale,
        15.28 * scale,
        1.96 * scale,
        16.82 * scale,
      )
      ..lineTo(5.84 * scale, 13.96 * scale)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Red section (top left arc)
    paint.color = googleRed;
    final redPath = Path()
      ..moveTo(12 * scale, 4.84 * scale)
      ..cubicTo(
        13.89 * scale,
        4.84 * scale,
        15.6 * scale,
        5.49 * scale,
        16.94 * scale,
        6.76 * scale,
      )
      ..lineTo(20.15 * scale, 3.55 * scale)
      ..cubicTo(
        17.95 * scale,
        1.49 * scale,
        15.18 * scale,
        0.24 * scale,
        12 * scale,
        0.24 * scale,
      )
      ..cubicTo(
        7.77 * scale,
        0.24 * scale,
        4.19 * scale,
        3 * scale,
        1.96 * scale,
        6.65 * scale,
      )
      ..lineTo(5.84 * scale, 9.5 * scale)
      ..cubicTo(
        6.71 * scale,
        6.83 * scale,
        9.14 * scale,
        4.84 * scale,
        12 * scale,
        4.84 * scale,
      )
      ..close();
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A divider with "or" text in the center.
/// Used to separate email/password form from social login options.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = theme.colorScheme.onSurface.withValues(alpha: 0.15);
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [dividerColor.withValues(alpha: 0), dividerColor],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    )
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.8,
                    ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'or',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [dividerColor, dividerColor.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
