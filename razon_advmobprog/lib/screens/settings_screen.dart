import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/theme_provider.dart';

// displays the settings options for the app
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // gets the current theme state from Provider
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                themeProvider.isDark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),

              title: const Text('Dark Mode'),

              subtitle: Text(
                themeProvider.isDark
                    ? 'Dark theme is enabled'
                    : 'Light theme is enabled',
              ),

              trailing: Switch(
                value: themeProvider.isDark,

                // toggles the global light/dark theme
                onChanged: (_) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}