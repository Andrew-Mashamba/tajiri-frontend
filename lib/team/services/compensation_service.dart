// lib/team/services/compensation_service.dart
import '../../business/models/business_models.dart' show TanzaniaPAYE;
import '../models/team_models.dart' show Allowance;

class CompensationService {
  CompensationService._();

  /// NSSF employee contribution: 10% of gross, capped at TZS 20,000.
  static double computeNSSF(double gross) =>
      (gross * 0.10).clamp(0.0, 20000.0);

  /// NHIF employee contribution (2026 tiered rates).
  static double computeNHIF(double gross) {
    if (gross <= 100000) return 0;
    if (gross <= 200000) return 5000;
    if (gross <= 300000) return 7500;
    if (gross <= 400000) return 10000;
    if (gross <= 500000) return 12500;
    if (gross <= 1000000) return 15000;
    return 20000;
  }

  static double computePAYE(double gross) =>
      TanzaniaPAYE.calculateMonthlyPAYE(gross);

  static double computeNetPay({
    required double grossSalary,
    required List<Allowance> allowances,
    required bool applyPAYE,
    required bool applyNSSF,
    required bool applyNHIF,
  }) {
    final totalAllowances = allowances.fold(0.0, (s, a) => s + a.amount);
    final paye = applyPAYE ? computePAYE(grossSalary) : 0.0;
    final nssf = applyNSSF ? computeNSSF(grossSalary) : 0.0;
    final nhif = applyNHIF ? computeNHIF(grossSalary) : 0.0;
    return grossSalary + totalAllowances - paye - nssf - nhif;
  }
}
