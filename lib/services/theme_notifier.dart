import 'package:flutter/material.dart';

/// Global theme mode notifier so Settings can update app theme without Provider.
class ThemeNotifier {
  static ValueNotifier<ThemeMode>? _instance;

  static ValueNotifier<ThemeMode> get instance {
    _instance ??= ValueNotifier<ThemeMode>(ThemeMode.light);
    return _instance!;
  }

  static void init(ThemeMode mode) {
    _instance ??= ValueNotifier<ThemeMode>(ThemeMode.light);
    _instance!.value = mode;
  }

  static void setThemeMode(ThemeMode mode) {
    instance.value = mode;
  }
}
