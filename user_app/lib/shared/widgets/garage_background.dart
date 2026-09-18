import 'package:flutter/material.dart';

/// Background image ya garage - kutumika kwenye pages zote.
class GarageBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const GarageBackground({
    super.key,
    required this.child,
    this.opacity = 0.85,
  });

  static const String backgroundUrl =
      'assets/images/homepage_bg.jpg';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            backgroundUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: isDark ? const Color(0xFF0F1419) : Colors.white,
            ),
          ),
        ),
        // Overlay
        Positioned.fill(
          child: Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: opacity),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}
