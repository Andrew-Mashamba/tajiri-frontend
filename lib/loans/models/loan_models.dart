// lib/loans/models/loan_models.dart
import 'package:flutter/material.dart';

// ─── Creator Credit Score ───────────────────────────────────────

class CreatorCreditScore {
  final int score; // 0-100
  final double monthlyEarningsAvg;
  final int platformTenureMonths;
  final int streakDays;
  final double earningsGrowthPercent;
  final int revenueSources;
  final double repaymentRate; // 0-1, historical
  final List<ScoreBreakdown> breakdown;

  CreatorCreditScore({
    required this.score,
    required this.monthlyEarningsAvg,
    required this.platformTenureMonths,
    this.streakDays = 0,
    this.earningsGrowthPercent = 0,
    this.revenueSources = 0,
    this.repaymentRate = 1.0,
    this.breakdown = const [],
  });

  factory CreatorCreditScore.fromJson(Map<String, dynamic> json) {
    return CreatorCreditScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      monthlyEarningsAvg: (json['monthly_earnings_avg'] as num?)?.toDouble() ?? 0,
      platformTenureMonths: (json['platform_tenure_months'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      earningsGrowthPercent: (json['earnings_growth_percent'] as num?)?.toDouble() ?? 0,
      revenueSources: (json['revenue_sources'] as num?)?.toInt() ?? 0,
      repaymentRate: (json['repayment_rate'] as num?)?.toDouble() ?? 1.0,
      breakdown: (json['breakdown'] as List?)
              ?.map((b) => ScoreBreakdown.fromJson(b))
              .toList() ??
          [],
    );
  }

  String get grade {
    if (score >= 80) return 'A';
    if (score >= 65) return 'B';
    if (score >= 50) return 'C';
    if (score >= 35) return 'D';
    return 'E';
  }

  Color get gradeColor {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 65) return const Color(0xFF8BC34A);
    if (score >= 50) return Colors.orange;
    if (score >= 35) return Colors.deepOrange;
    return Colors.red;
  }

  LoanTier? get maxEligibleTier {
    if (score >= 75 && platformTenureMonths >= 12 && monthlyEarningsAvg >= 350000) {
      return LoanTier.nguvu;
    }
    if (score >= 60 && platformTenureMonths >= 6 && monthlyEarningsAvg >= 100000) {
      return LoanTier.msaada;
    }
    if (score >= 40 && platformTenureMonths >= 3 && monthlyEarningsAvg > 0) {
      return LoanTier.chanzo;
    }
    return null;
  }
}

class ScoreBreakdown {
  final String factor;
  final double weight;
  final double score;
  final double maxScore;

  ScoreBreakdown({
    required this.factor,
    required this.weight,
    required this.score,
    required this.maxScore,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      factor: json['factor'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 100,
    );
  }

  String get factorLabel {
    switch (factor) {
      case 'earnings_stability': return 'Utulivu wa Mapato';
      case 'content_consistency': return 'Uthabiti wa Maudhui';
      case 'engagement_quality': return 'Ubora wa Mwitikio';
      case 'community_score': return 'Alama ya Jamii';
      case 'revenue_diversification': return 'Mseto wa Mapato';
      case 'earnings_growth': return 'Ukuaji wa Mapato';
      case 'platform_tenure': return 'Muda kwenye Jukwaa';
      case 'repayment_history': return 'Historia ya Malipo';
      default: return factor;
    }
  }
}

// ─── Loan Tiers ─────────────────────────────────────────────────

enum LoanTier {
  chanzo,
  msaada,
  nguvu;

  String get displayName {
    switch (this) {
      case LoanTier.chanzo: return 'Chanzo';
      case LoanTier.msaada: return 'Msaada';
      case LoanTier.nguvu: return 'Nguvu';
    }
  }

  String get subtitle {
    switch (this) {
      case LoanTier.chanzo: return 'Starter';
      case LoanTier.msaada: return 'Growth';
      case LoanTier.nguvu: return 'Power';
    }
  }

  double get minAmount {
    switch (this) {
      case LoanTier.chanzo: return 25000;
      case LoanTier.msaada: return 200000;
      case LoanTier.nguvu: return 1000000;
    }
  }

  double get maxAmount {
    switch (this) {
      case LoanTier.chanzo: return 200000;
      case LoanTier.msaada: return 1000000;
      case LoanTier.nguvu: return 5000000;
    }
  }

  int get earningsMultiple {
    switch (this) {
      case LoanTier.chanzo: return 1;
      case LoanTier.msaada: return 2;
      case LoanTier.nguvu: return 3;
    }
  }

  double get feePercent {
    switch (this) {
      case LoanTier.chanzo: return 5;
      case LoanTier.msaada: return 7;
      case LoanTier.nguvu: return 10;
    }
  }

  double get repaymentPercent {
    switch (this) {
      case LoanTier.chanzo: return 10;
      case LoanTier.msaada: return 12;
      case LoanTier.nguvu: return 15;
    }
  }

  int get termDays {
    switch (this) {
      case LoanTier.chanzo: return 90;
      case LoanTier.msaada: return 180;
      case LoanTier.nguvu: return 365;
    }
  }

  int get minScore {
    switch (this) {
      case LoanTier.chanzo: return 40;
      case LoanTier.msaada: return 60;
      case LoanTier.nguvu: return 75;
    }
  }

  int get minTenureMonths {
    switch (this) {
      case LoanTier.chanzo: return 3;
      case LoanTier.msaada: return 6;
      case LoanTier.nguvu: return 12;
    }
  }

  Color get color {
    switch (this) {
      case LoanTier.chanzo: return const Color(0xFF4CAF50);
      case LoanTier.msaada: return Colors.blue;
      case LoanTier.nguvu: return Colors.deepPurple;
    }
  }

  IconData get icon {
    switch (this) {
      case LoanTier.chanzo: return Icons.eco_rounded;
      case LoanTier.msaada: return Icons.rocket_launch_rounded;
      case LoanTier.nguvu: return Icons.bolt_rounded;
    }
  }
}

// ─── Loan Application & Active Loan ─────────────────────────────

enum BoostLoanStatus {
  pending,
  approved,
  disbursed,
  active,
  repaying,
  paused,
  completed,
  overdue,
  defaulted,
  rejected;

  String get displayName {
    switch (this) {
      case BoostLoanStatus.pending: return 'Inasubiri';
      case BoostLoanStatus.approved: return 'Imekubaliwa';
      case BoostLoanStatus.disbursed: return 'Imetolewa';
      case BoostLoanStatus.active: return 'Hai';
      case BoostLoanStatus.repaying: return 'Inalipwa';
      case BoostLoanStatus.paused: return 'Imesimamishwa';
      case BoostLoanStatus.completed: return 'Imekamilika';
      case BoostLoanStatus.overdue: return 'Imechelewa';
      case BoostLoanStatus.defaulted: return 'Imeshindwa';
      case BoostLoanStatus.rejected: return 'Imekataliwa';
    }
  }

  Color get color {
    switch (this) {
      case BoostLoanStatus.pending: return Colors.orange;
      case BoostLoanStatus.approved: return Colors.blue;
      case BoostLoanStatus.disbursed:
      case BoostLoanStatus.active:
      case BoostLoanStatus.repaying: return const Color(0xFF4CAF50);
      case BoostLoanStatus.paused: return Colors.amber;
      case BoostLoanStatus.completed: return const Color(0xFF4CAF50);
      case BoostLoanStatus.overdue: return Colors.deepOrange;
      case BoostLoanStatus.defaulted: return Colors.red;
      case BoostLoanStatus.rejected: return Colors.red;
    }
  }

  static BoostLoanStatus fromString(String? s) {
    switch (s) {
      case 'pending': return BoostLoanStatus.pending;
      case 'approved': return BoostLoanStatus.approved;
      case 'disbursed': return BoostLoanStatus.disbursed;
      case 'active': return BoostLoanStatus.active;
      case 'repaying': return BoostLoanStatus.repaying;
      case 'paused': return BoostLoanStatus.paused;
      case 'completed': return BoostLoanStatus.completed;
      case 'overdue': return BoostLoanStatus.overdue;
      case 'defaulted': return BoostLoanStatus.defaulted;
      case 'rejected': return BoostLoanStatus.rejected;
      default: return BoostLoanStatus.pending;
    }
  }
}

class BoostLoan {
  final int id;
  final int userId;
  final String loanId;
  final LoanTier tier;
  final double principalAmount;
  final double feeAmount;
  final double totalRepayable;
  final double amountRepaid;
  final double repaymentPercent;
  final BoostLoanStatus status;
  final DateTime applicationDate;
  final DateTime? disbursementDate;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final int? graceDaysRemaining;
  final bool canRequestPause;
  final String? rejectionReason;

  BoostLoan({
    required this.id,
    required this.userId,
    required this.loanId,
    required this.tier,
    required this.principalAmount,
    required this.feeAmount,
    required this.totalRepayable,
    this.amountRepaid = 0,
    required this.repaymentPercent,
    required this.status,
    required this.applicationDate,
    this.disbursementDate,
    this.dueDate,
    this.completedDate,
    this.graceDaysRemaining,
    this.canRequestPause = false,
    this.rejectionReason,
  });

  factory BoostLoan.fromJson(Map<String, dynamic> json) {
    return BoostLoan(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      loanId: json['loan_id'] ?? '',
      tier: LoanTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => LoanTier.chanzo,
      ),
      principalAmount: (json['principal_amount'] as num?)?.toDouble() ?? 0,
      feeAmount: (json['fee_amount'] as num?)?.toDouble() ?? 0,
      totalRepayable: (json['total_repayable'] as num?)?.toDouble() ?? 0,
      amountRepaid: (json['amount_repaid'] as num?)?.toDouble() ?? 0,
      repaymentPercent: (json['repayment_percent'] as num?)?.toDouble() ?? 10,
      status: BoostLoanStatus.fromString(json['status']),
      applicationDate: DateTime.parse(json['application_date'] ?? DateTime.now().toIso8601String()),
      disbursementDate: json['disbursement_date'] != null ? DateTime.tryParse(json['disbursement_date']) : null,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      completedDate: json['completed_date'] != null ? DateTime.tryParse(json['completed_date']) : null,
      graceDaysRemaining: (json['grace_days_remaining'] as num?)?.toInt(),
      canRequestPause: json['can_request_pause'] ?? false,
      rejectionReason: json['rejection_reason'],
    );
  }

  double get remainingAmount => totalRepayable - amountRepaid;
  double get repaidPercent => totalRepayable > 0 ? (amountRepaid / totalRepayable) * 100 : 0;
  bool get isActive => [
        BoostLoanStatus.disbursed,
        BoostLoanStatus.active,
        BoostLoanStatus.repaying,
        BoostLoanStatus.paused,
        BoostLoanStatus.overdue,
      ].contains(status);
  int get daysToMaturity => dueDate?.difference(DateTime.now()).inDays ?? 0;
}

class LoanRepaymentEvent {
  final int id;
  final int loanId;
  final double amount;
  final String earningType; // subscription, tip, gift, shop, creator_fund
  final DateTime date;

  LoanRepaymentEvent({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.earningType,
    required this.date,
  });

  factory LoanRepaymentEvent.fromJson(Map<String, dynamic> json) {
    return LoanRepaymentEvent(
      id: json['id'] ?? 0,
      loanId: json['loan_id'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      earningType: json['earning_type'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get earningTypeLabel {
    switch (earningType) {
      case 'subscription': return 'Usajili';
      case 'tip': return 'Zawadi';
      case 'gift': return 'Tuzo';
      case 'shop': return 'Duka';
      case 'creator_fund': return 'Mfuko';
      default: return earningType;
    }
  }
}

// ─── Result wrappers ────────────────────────────────────────────

class LoanResult<T> {
  final bool success;
  final T? data;
  final String? message;

  LoanResult({required this.success, this.data, this.message});
}

class LoanListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  LoanListResult({required this.success, this.items = const [], this.message});
}
