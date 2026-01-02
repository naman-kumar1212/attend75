import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AuthCard({super.key, required this.child, this.maxWidth = 420});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(padding: const EdgeInsets.all(32.0), child: child),
        ),
      ),
    );
  }
}
