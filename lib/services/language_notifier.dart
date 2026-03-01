import 'package:flutter/material.dart';

/// Global app language notifier. Default is English ('en'); 'sw' = Spoken/Street Swahili.
/// Settings screen saves to LocalStorageService and calls setLanguage so the app rebuilds.
class LanguageNotifier {
  static ValueNotifier<String>? _instance;

  static ValueNotifier<String> get instance {
    _instance ??= ValueNotifier<String>('en');
    return _instance!;
  }

  static void init(String languageCode) {
    _instance ??= ValueNotifier<String>('en');
    _instance!.value = languageCode == 'sw' ? 'sw' : 'en';
  }

  static void setLanguage(String languageCode) {
    instance.value = languageCode == 'sw' ? 'sw' : 'en';
  }

  static bool get isSwahili => instance.value == 'sw';
}
