import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_controller.dart';

/// Drop this into any AppBar's actions to let the user switch
/// between light and dark mode.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return IconButton(
      tooltip: themeController.isDark ? 'Light mode' : 'Dark mode',
      icon: Icon(
        themeController.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: themeController.toggle,
    );
  }
}
