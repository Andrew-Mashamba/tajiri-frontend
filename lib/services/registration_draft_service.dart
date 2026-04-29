import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/registration_models.dart';

/// Crash-tolerant draft store for in-progress onboarding.
///
/// The onboarding flow used to keep [RegistrationState] in memory only — if
/// the app died mid-flow the user retyped everything. This service mirrors
/// the in-memory state to a Hive box after each step so we can restore on
/// next launch, and clears the draft on completion.
class RegistrationDraftService {
  static const String _boxName = 'registration_draft';
  static const String _draftKey = 'draft';

  static RegistrationDraftService? _instance;
  Box? _box;

  RegistrationDraftService._();

  static Future<RegistrationDraftService> getInstance() async {
    if (_instance == null) {
      _instance = RegistrationDraftService._();
      _instance!._box = await Hive.openBox(_boxName);
    }
    return _instance!;
  }

  Future<void> save(RegistrationState state) async {
    try {
      await _box?.put(_draftKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[RegistrationDraft] save error: $e');
    }
  }

  RegistrationState? load() {
    try {
      final raw = _box?.get(_draftKey);
      if (raw == null) return null;
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return RegistrationState.fromJson(json);
    } catch (e) {
      debugPrint('[RegistrationDraft] load error: $e');
      return null;
    }
  }

  bool hasDraft() {
    final raw = _box?.get(_draftKey);
    return raw != null && (raw is String) && raw.isNotEmpty;
  }

  Future<void> clear() async {
    try {
      await _box?.delete(_draftKey);
    } catch (e) {
      debugPrint('[RegistrationDraft] clear error: $e');
    }
  }
}
