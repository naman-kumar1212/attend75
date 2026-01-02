import 'package:flutter/material.dart';

/// A styled "Sign in with Apple" button for OAuth authentication.
/// Matches official Apple Sign-In branding guidelines.
/// Used on both sign-in and sign-up pages.
class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Sign in with Apple',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Apple button colors per official Apple branding guidelines
    // Light mode: white background with black text/icon
    // Dark mode: black background with white text/icon
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark
        ? Colors.transparent
        : const Color(0xFFE5E5E5); // Light gray border for light mode

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
              border: Border.all(color: borderColor, width: 1),
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
                      // Official Apple Logo
                      _AppleLogo(size: 18, color: textColor),
                      const SizedBox(width: 10),
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

/// Official Apple logo using CustomPainter
/// Matches Apple's brand guidelines exactly
class _AppleLogo extends StatelessWidget {
  final double size;
  final Color color;

  const _AppleLogo({this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _AppleLogoPainter(color: color),
      ),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  final Color color;

  _AppleLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor to fit the logo in the given size
    // Original viewBox is approximately 170x170
    final double scale = size.width / 170;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final path = Path();

    // Apple body - the main bitten apple shape
    path.moveTo(150.37 * scale, 130.25 * scale);
    path.cubicTo(
      147.84 * scale,
      135.96 * scale,
      144.83 * scale,
      141.27 * scale,
      141.3 * scale,
      146.17 * scale,
    );
    path.cubicTo(
      136.45 * scale,
      152.99 * scale,
      132.53 * scale,
      157.78 * scale,
      129.58 * scale,
      160.55 * scale,
    );
    path.cubicTo(
      124.99 * scale,
      165.01 * scale,
      120.09 * scale,
      167.29 * scale,
      114.88 * scale,
      167.4 * scale,
    );
    path.cubicTo(
      111.18 * scale,
      167.4 * scale,
      106.74 * scale,
      166.35 * scale,
      101.58 * scale,
      164.21 * scale,
    );
    path.cubicTo(
      96.42 * scale,
      162.08 * scale,
      91.67 * scale,
      161.02 * scale,
      87.31 * scale,
      161.02 * scale,
    );
    path.cubicTo(
      82.74 * scale,
      161.02 * scale,
      77.83 * scale,
      162.08 * scale,
      72.59 * scale,
      164.21 * scale,
    );
    path.cubicTo(
      67.33 * scale,
      166.35 * scale,
      63.11 * scale,
      167.46 * scale,
      59.88 * scale,
      167.56 * scale,
    );
    path.cubicTo(
      54.89 * scale,
      167.78 * scale,
      49.88 * scale,
      165.43 * scale,
      44.86 * scale,
      160.55 * scale,
    );
    path.cubicTo(
      41.68 * scale,
      157.55 * scale,
      37.71 * scale,
      152.59 * scale,
      32.95 * scale,
      145.67 * scale,
    );
    path.cubicTo(
      27.83 * scale,
      138.29 * scale,
      23.65 * scale,
      129.68 * scale,
      20.42 * scale,
      119.84 * scale,
    );
    path.cubicTo(
      16.96 * scale,
      109.25 * scale,
      15.22 * scale,
      98.95 * scale,
      15.22 * scale,
      88.96 * scale,
    );
    path.cubicTo(
      15.22 * scale,
      77.49 * scale,
      17.63 * scale,
      67.57 * scale,
      22.46 * scale,
      59.22 * scale,
    );
    path.cubicTo(
      26.2 * scale,
      52.53 * scale,
      31.34 * scale,
      47.28 * scale,
      37.88 * scale,
      43.46 * scale,
    );
    path.cubicTo(
      44.43 * scale,
      39.64 * scale,
      51.52 * scale,
      37.67 * scale,
      59.16 * scale,
      37.55 * scale,
    );
    path.cubicTo(
      63.08 * scale,
      37.55 * scale,
      68.27 * scale,
      38.77 * scale,
      74.74 * scale,
      41.16 * scale,
    );
    path.cubicTo(
      81.2 * scale,
      43.57 * scale,
      85.47 * scale,
      44.79 * scale,
      87.55 * scale,
      44.79 * scale,
    );
    path.cubicTo(
      89.08 * scale,
      44.79 * scale,
      93.83 * scale,
      43.36 * scale,
      101.47 * scale,
      40.51 * scale,
    );
    path.cubicTo(
      108.71 * scale,
      37.87 * scale,
      114.82 * scale,
      36.8 * scale,
      119.83 * scale,
      37.32 * scale,
    );
    path.cubicTo(
      132.47 * scale,
      38.34 * scale,
      142.01 * scale,
      43.14 * scale,
      148.43 * scale,
      51.75 * scale,
    );
    path.cubicTo(
      137.17 * scale,
      58.58 * scale,
      131.6 * scale,
      68.02 * scale,
      131.72 * scale,
      80.05 * scale,
    );
    path.cubicTo(
      131.82 * scale,
      89.53 * scale,
      135.32 * scale,
      97.43 * scale,
      142.2 * scale,
      103.72 * scale,
    );
    path.cubicTo(
      145.34 * scale,
      106.69 * scale,
      148.84 * scale,
      108.93 * scale,
      152.73 * scale,
      110.45 * scale,
    );
    path.cubicTo(
      151.99 * scale,
      112.61 * scale,
      151.2 * scale,
      114.72 * scale,
      150.37 * scale,
      116.79 * scale,
    );
    path.lineTo(150.37 * scale, 130.25 * scale);
    path.close();

    // Apple leaf - the elegant curved leaf at the top
    path.moveTo(120.8 * scale, 6.6 * scale);
    path.cubicTo(
      120.8 * scale,
      14.06 * scale,
      118.25 * scale,
      21.03 * scale,
      113.16 * scale,
      27.49 * scale,
    );
    path.cubicTo(
      107.02 * scale,
      35.18 * scale,
      99.53 * scale,
      39.6 * scale,
      91.37 * scale,
      38.93 * scale,
    );
    path.cubicTo(
      91.25 * scale,
      37.96 * scale,
      91.18 * scale,
      36.94 * scale,
      91.18 * scale,
      35.87 * scale,
    );
    path.cubicTo(
      91.18 * scale,
      28.72 * scale,
      94.11 * scale,
      21.03 * scale,
      99.32 * scale,
      14.77 * scale,
    );
    path.cubicTo(
      101.92 * scale,
      11.6 * scale,
      105.23 * scale,
      8.98 * scale,
      109.25 * scale,
      6.91 * scale,
    );
    path.cubicTo(
      113.25 * scale,
      4.89 * scale,
      117.02 * scale,
      3.77 * scale,
      120.57 * scale,
      3.55 * scale,
    );
    path.cubicTo(
      120.69 * scale,
      4.58 * scale,
      120.8 * scale,
      5.62 * scale,
      120.8 * scale,
      6.6 * scale,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AppleLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
