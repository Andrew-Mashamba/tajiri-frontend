import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    test('instance can be created', () {
      final service = PaymentService();
      expect(service, isNotNull);
    });
  });
}
