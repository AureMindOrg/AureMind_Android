import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;
  Color _customColor = const Color(0xFF3B82F6); // Default Blue

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;
  Color get customColor => _customColor;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0; // 0: system, 1: light, 2: dark
    _themeMode = ThemeMode.values[themeIndex];
    _useDynamicColor = prefs.getBool('useDynamicColor') ?? true;
    final colorValue = prefs.getInt('customColor');
    if (colorValue != null) _customColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setUseDynamicColor(bool useDynamic) async {
    _useDynamicColor = useDynamic;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDynamicColor', useDynamic);
  }

  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('customColor', color.value);
  }
}