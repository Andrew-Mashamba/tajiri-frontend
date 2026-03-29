import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/registration_models.dart';
import '../models/profile_tab_config.dart';

class LocalStorageService {
  static const String _userBoxName = 'user_box';
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _profileTabsKey = 'profile_tabs';
  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _authTokenKey = 'auth_token';

  static LocalStorageService? _instance;
  late Box _userBox;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// Synchronous access to the already-initialized instance (null if not yet ready).
  static LocalStorageService? get instanceSync => _instance;

  Future<void> _init() async {
    _userBox = await Hive.openBox(_userBoxName);
    await Hive.openBox('ad_settings');
  }

  // Save user data after registration
  Future<void> saveUser(RegistrationState user) async {
    final jsonData = user.toJson();
    await _userBox.put(_userKey, jsonEncode(jsonData));
    await _userBox.put(_isLoggedInKey, true);
  }

  // Get current user
  RegistrationState? getUser() {
    final jsonString = _userBox.get(_userKey);
    if (jsonString == null) return null;

    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return RegistrationState.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _userBox.get(_isLoggedInKey, defaultValue: false) == true;
  }

  // Check if user exists
  bool hasUser() {
    return _userBox.containsKey(_userKey) && getUser() != null;
  }

  // Logout - clear user session but keep data
  Future<void> logout() async {
    await _userBox.put(_isLoggedInKey, false);
  }

  // Clear all user data
  Future<void> clearUser() async {
    await _userBox.delete(_userKey);
    await _userBox.delete(_isLoggedInKey);
  }

  // Update user data
  Future<void> updateUser(RegistrationState user) async {
    await saveUser(user);
  }

  // Save profile tab configurations
  Future<void> saveProfileTabs(List<ProfileTabConfig> tabs) async {
    final jsonList = tabs.map((tab) => tab.toJson()).toList();
    await _userBox.put(_profileTabsKey, jsonEncode(jsonList));
  }

  // Get profile tab configurations
  List<ProfileTabConfig> getProfileTabs() {
    final jsonString = _userBox.get(_profileTabsKey);
    if (jsonString == null) {
      return ProfileTabDefaults.getDefaults();
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      final tabs = jsonList
          .map((json) => ProfileTabConfig.fromJson(json as Map<String, dynamic>))
          .toList();

      // Ensure we have all tabs (in case new ones were added)
      final existingIds = tabs.map((t) => t.id).toSet();
      for (final defaultTab in ProfileTabDefaults.defaultTabs) {
        if (!existingIds.contains(defaultTab.id)) {
          tabs.add(defaultTab.copyWith(order: tabs.length));
        }
      }

      // Sort by order
      tabs.sort((a, b) => a.order.compareTo(b.order));
      return tabs;
    } catch (e) {
      return ProfileTabDefaults.getDefaults();
    }
  }

  // Reset profile tabs to defaults
  Future<void> resetProfileTabs() async {
    await _userBox.delete(_profileTabsKey);
  }

  ThemeMode getThemeMode() {
    final value = _userBox.get(_themeModeKey, defaultValue: 'light') as String?;
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _userBox.put(_themeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  /// Language: 'en' = English (default), 'sw' = Kiswahili (street/spoken).
  String getLanguageCode() {
    return _userBox.get(_languageKey, defaultValue: 'en') as String;
  }

  Future<void> saveLanguageCode(String code) async {
    await _userBox.put(_languageKey, code == 'sw' ? 'sw' : 'en');
  }

  /// Auth token (e.g. Laravel Sanctum). Set after login for API/WebSocket auth.
  String? getAuthToken() {
    return _userBox.get(_authTokenKey) as String?;
  }

  Future<void> saveAuthToken(String? token) async {
    if (token == null) {
      await _userBox.delete(_authTokenKey);
    } else {
      await _userBox.put(_authTokenKey, token);
    }
  }

  /// Generic bool getter for preference keys.
  bool? getBool(String key) {
    final value = _userBox.get(key);
    if (value is bool) return value;
    return null;
  }

  /// Generic bool setter for preference keys.
  Future<void> saveBool(String key, bool value) async {
    await _userBox.put(key, value);
  }

  /// Generic string getter for preference keys.
  String? getString(String key) {
    final value = _userBox.get(key);
    if (value is String) return value;
    return null;
  }

  /// Generic string setter for preference keys.
  Future<void> setString(String key, String value) async {
    await _userBox.put(key, value);
  }

  // ── Ad Settings Cache ──────────────────────────────────────────────────────

  Future<void> saveAdSettings(Map<String, dynamic> settings) async {
    final box = await Hive.openBox('ad_settings');
    await box.put('settings', settings);
    await box.put('lastFetchedAt', DateTime.now().toIso8601String());
  }

  Map<String, dynamic>? getAdSettings() {
    final box = Hive.box('ad_settings');
    final data = box.get('settings');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  int getAdFrequency(String key, int defaultValue) {
    final settings = getAdSettings();
    if (settings == null) return defaultValue;
    return int.tryParse(settings[key]?.toString() ?? '') ?? defaultValue;
  }

  String? getAdMobUnitId(String key) {
    final settings = getAdSettings();
    if (settings == null) return null;
    return settings[key]?.toString();
  }

  bool shouldRefreshAdSettings() {
    try {
      final box = Hive.box('ad_settings');
      final lastFetched = box.get('lastFetchedAt') as String?;
      if (lastFetched == null) return true;
      final lastDate = DateTime.parse(lastFetched);
      return DateTime.now().difference(lastDate).inHours >= 24;
    } catch (_) {
      return true;
    }
  }
}
