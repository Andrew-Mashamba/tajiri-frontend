import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/services/gossip_service.dart';

void main() {
  group('GossipService', () {
    test('instance can be created', () {
      final service = GossipService();
      expect(service, isNotNull);
    });
  });
}
