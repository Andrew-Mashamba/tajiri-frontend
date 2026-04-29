// Local mirror of pending/successful trace payloads until terminal state (Hive).

import 'package:hive_flutter/hive_flutter.dart';

class TransactionLocalStore {
  static const String _boxName = 'txn_record_local';
  static Box? _box;

  static Future<void> _ensure() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> putSnapshot(String traceId, Map<String, dynamic> snapshot) async {
    await _ensure();
    await _box!.put(traceId, snapshot);
  }

  static Future<void> remove(String traceId) async {
    await _ensure();
    await _box!.delete(traceId);
  }
}
