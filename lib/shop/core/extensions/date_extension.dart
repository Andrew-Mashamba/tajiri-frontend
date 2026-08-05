// Generated for docs/shop/shop.md — see core/extensions/date_extension.dart
extension ShopDateUi on DateTime {
  String get shopShort => toIso8601String().substring(0, 10);
}
