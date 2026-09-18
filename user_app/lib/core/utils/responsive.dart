import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static bool isMobile(BuildContext c) =>
      MediaQuery.of(c).size.width < 600;

  static bool isTablet(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    return w >= 600 && w < 1024;
  }

  static bool isDesktop(BuildContext c) =>
      MediaQuery.of(c).size.width >= 1024;

  /// Max width ya content (kwa PC kubwa).
  static double maxContentWidth(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    if (w >= 1400) return 1200;
    if (w >= 1024) return 960;
    return w;
  }

  /// Padding ya page kulingana na device.
  static EdgeInsets pagePadding(BuildContext c) {
    if (isDesktop(c)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (isTablet(c)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  /// Grid count kwa products/cards.
  static int gridCount(BuildContext c) {
    if (isDesktop(c)) return 4;
    if (isTablet(c)) return 3;
    return 2;
  }
}

/// Widget ya kuweka content katikati kwa max width.
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
