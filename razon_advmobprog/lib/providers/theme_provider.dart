import 'package:flutter/material.dart';

// holds the app state for light/dark mode
class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  // defines the light theme 
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      );

  // defines the dark theme 
  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      );

  // Enhancement 3
  // switches the current theme 
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}