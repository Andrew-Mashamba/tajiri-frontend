// test/team/compensation_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/team/models/team_models.dart';
import 'package:tajiri/team/services/compensation_service.dart';

void main() {
  group('CompensationService.computeNSSF', () {
    test('10% of gross up to 20000 cap', () {
      expect(CompensationService.computeNSSF(100000), 10000.0);
      expect(CompensationService.computeNSSF(300000), 20000.0);
      expect(CompensationService.computeNSSF(50000), 5000.0);
    });
  });

  group('CompensationService.computeNHIF', () {
    test('tiered by gross salary', () {
      expect(CompensationService.computeNHIF(50000), 0.0);
      expect(CompensationService.computeNHIF(150000), 5000.0);
      expect(CompensationService.computeNHIF(250000), 7500.0);
      expect(CompensationService.computeNHIF(350000), 10000.0);
      expect(CompensationService.computeNHIF(450000), 12500.0);
      expect(CompensationService.computeNHIF(750000), 15000.0);
      expect(CompensationService.computeNHIF(1500000), 20000.0);
    });
  });

  group('CompensationService.computePAYE', () {
    test('zero below threshold', () {
      expect(CompensationService.computePAYE(270000), 0.0);
    });
    test('positive above threshold', () {
      expect(CompensationService.computePAYE(400000), greaterThan(0));
    });
  });

  group('CompensationService.computeNetPay', () {
    test('all deductions off: net = gross + allowances', () {
      final net = CompensationService.computeNetPay(
        grossSalary: 300000,
        allowances: [const Allowance(name: 'Transport', amount: 50000)],
        applyPAYE: false,
        applyNSSF: false,
        applyNHIF: false,
      );
      expect(net, 350000.0);
    });

    test('all deductions on: net = gross - PAYE - NSSF - NHIF', () {
      const gross = 500000.0;
      final expected = gross
          - CompensationService.computePAYE(gross)
          - CompensationService.computeNSSF(gross)
          - CompensationService.computeNHIF(gross);
      final net = CompensationService.computeNetPay(
        grossSalary: gross,
        allowances: const [],
        applyPAYE: true,
        applyNSSF: true,
        applyNHIF: true,
      );
      expect(net, closeTo(expected, 0.01));
    });
  });
}
