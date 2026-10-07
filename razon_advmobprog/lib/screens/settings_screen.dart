import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await UserService().logout();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(UserService.errorMessage(e))),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    messenger.showSnackBar(
      const SnackBar(content: Text('You have been logged out.')),
    );
  }

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

          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              subtitle: const Text('Sign out and return to the login screen'),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}