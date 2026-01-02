import 'package:flutter/material.dart';

class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Smoother curve
    const curve = Curves.easeOutCubic;

    // Combined animation:
    // 1. Fade In
    // 2. Slide Up (very subtle, ~10px)
    // 3. Scale Up (0.98 -> 1.00)
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(
          0,
          0.02,
        ), // Reduced from 0.05 to ~0.02 (approx 12-16px on mobile)
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.98,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve)),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        ),
      ),
    );
  }
}
