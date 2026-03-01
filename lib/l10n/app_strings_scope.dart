import 'package:flutter/material.dart';
import 'app_strings.dart';

export 'app_strings.dart' show AppStrings;

/// Provides [AppStrings] to the widget tree and rebuilds when app language changes.
/// Wrap your app (e.g. under [MaterialApp]) with [ListenableBuilder] on [LanguageNotifier.instance]
/// and this widget so [AppStringsScope.of(context)] works everywhere.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  static AppStrings? of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppStringsScope>();
    return scope?.strings;
  }

  static AppStrings? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AppStringsScope>()?.strings;
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) {
    return oldWidget.strings.languageCode != strings.languageCode;
  }
}
