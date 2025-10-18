import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart'; // Ensure this path is correct

class ToggleButton extends StatelessWidget {
  const ToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    ThemeMode mode = themeProvider.themeMode;
    Brightness brightness = Theme.of(context).brightness;

    IconData icon;
    if (mode == ThemeMode.system) {
      icon = brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode;
    } else {
      icon = mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode;
    }

    return IconButton(
      icon: Icon(icon),
      onPressed: () {
        themeProvider.toggleTheme();
      },
      color: Theme.of(context).colorScheme.onPrimary,
      iconSize: 30,
      tooltip: 'Toggle Theme',
    );
  }
}
