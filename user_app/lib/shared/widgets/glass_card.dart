import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Glass-style card — crisp design, NO blur (performance + clarity).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? height;
  final double? width;
  final Color? tintColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.height,
    this.width,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: tintColor ??
            (isDark
                ? const Color(0xFF1E1E1E).withValues(alpha: 0.95)
                : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
