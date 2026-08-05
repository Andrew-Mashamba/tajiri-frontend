// Generated for docs/shop/shop.md — see offline/persistence/draft_storage.dart
import 'package:hive_flutter/hive_flutter.dart';

class DraftStorage {
  static const String boxName = 'shop_drafts';
  Future<Box<dynamic>> open() async => Hive.openBox(boxName);
}
