/// VICOBA Loan System - Data Models
///
/// Comprehensive models for loan applications, schedules, payments, and guarantors.

import 'package:flutter/material.dart';
import 'voting_models.dart';

/// Loan application status enum with all possible states
enum LoanStatus {
  draft,
  guarantorPending,
  pendingApproval,
  approved,
  rejected,
  guarantorRejected,
  disbursing,
  disbursed,
  failed,
  active,
  defaulted,
  closed,
  cancelled,
  expired;

  /// Parse status from API string
  static LoanStatus fromString(String? status) {
    if (status == null) return LoanStatus.draft;

    // Handle snake_case from API
    final normalized = status.toLowerCase().replaceAll('_', '');

    return LoanStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized || e.toApiString().toLowerCase().replaceAll('_', '') == normalized,
      orElse: () => LoanStatus.draft,
    );
  }

  /// Convert to API string format (snake_case)
  String toApiString() {
    switch (this) {
      case LoanStatus.guarantorPending:
        return 'guarantor_pending';
      case LoanStatus.pendingApproval:
        return 'pending_approval';
      case LoanStatus.guarantorRejected:
        return 'guarantor_rejected';
      default:
        return name;
    }
  }

  /// Display name in Swahili
  String get displayName {
    switch (this) {
      case LoanStatus.draft:
        return 'Rasimu';
      case LoanStatus.guarantorPending:
        return 'Inasubiri Wadhamini';
      case LoanStatus.pendingApproval:
        return 'Inasubiri Kura';
      case LoanStatus.approved:
        return 'Imeidhinishwa';
      case LoanStatus.rejected:
        return 'Imekataliwa';
      case LoanStatus.guarantorRejected:
        return 'Mdhamini Amekataa';
      case LoanStatus.disbursing:
        return 'Inatumwa';
      case LoanStatus.disbursed:
        return 'Imetumwa';
      case LoanStatus.failed:
        return 'Imeshindikana';
      case LoanStatus.active:
        return 'Inalipwa';
      case LoanStatus.defaulted:
        return 'Imechelewa';
      case LoanStatus.closed:
        return 'Imekamilika';
      case LoanStatus.cancelled:
        return 'Imefutwa';
      case LoanStatus.expired:
        return 'Imeisha Muda';
    }
  }

  /// Status color for UI
  Color get statusColor {
    switch (this) {
      case LoanStatus.draft:
        return Colors.grey;
      case LoanStatus.guarantorPending:
      case LoanStatus.pendingApproval:
      case LoanStatus.disbursing:
        return Colors.orange;
      case LoanStatus.approved:
      case LoanStatus.disbursed:
      case LoanStatus.active:
        return Colors.green;
      case LoanStatus.rejected:
      case LoanStatus.guarantorRejected:
      case LoanStatus.failed:
      case LoanStatus.defaulted:
      case LoanStatus.cancelled:
      case LoanStatus.expired:
        return Colors.red;
      case LoanStatus.closed:
        return Colors.blue;
    }
  }

  /// Status icon for UI
  IconData get statusIcon {
    switch (this) {
      case LoanStatus.draft:
        return Icons.edit;
      case LoanStatus.guarantorPending:
        return Icons.people_outline;
      case LoanStatus.pendingApproval:
        return Icons.how_to_vote;
      case LoanStatus.approved:
        return Icons.check_circle;
      case LoanStatus.rejected:
      case LoanStatus.guarantorRejected:
        return Icons.cancel;
      case LoanStatus.disbursing:
        return Icons.sync;
      case LoanStatus.disbursed:
        return Icons.send;
      case LoanStatus.failed:
        return Icons.error;
      case LoanStatus.active:
        return Icons.payments;
      case LoanStatus.defaulted:
        return Icons.warning;
      case LoanStatus.closed:
        return Icons.done_all;
      case LoanStatus.cancelled:
        return Icons.block;
      case LoanStatus.expired:
        return Icons.timer_off;
    }
  }
}

/// Loan product definition
class LoanProduct {
  final String id;
  final String name;
  final String? description;
  final double? minAmount;
  final double? maxAmount;
  final double? interestRate;
  final int? minTenure;
  final int? maxTenure;
  final String? repaymentFrequency;
  final bool fixedInterestRate;
  final bool fixedRepaymentFrequency;
  final List<ProductCharge> charges;

  LoanProduct({
    required this.id,
    required this.name,
    this.description,
    this.minAmount,
    this.maxAmount,
    this.interestRate,
    this.minTenure,
    this.maxTenure,
    this.repaymentFrequency,
    this.fixedInterestRate = false,
    this.fixedRepaymentFrequency = false,
    this.charges = const [],
  });

  factory LoanProduct.fromJson(Map<String, dynamic> json) {
    return LoanProduct(
      id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['productName']?.toString() ?? '',
      description: json['description']?.toString(),
      minAmount: _parseDouble(json['minAmount']),
      maxAmount: _parseDouble(json['maxAmount']),
      interestRate: _parseDouble(json['interestRate']),
      minTenure: _parseInt(json['minTenure']),
      maxTenure: _parseInt(json['maxTenure']),
      repaymentFrequency: json['repaymentFrequency']?.toString(),
      fixedInterestRate: json['fixedInterestRate'] == true || json['fixedInterestRate'] == 'true',
      fixedRepaymentFrequency: json['fixedRepaymentFrequency'] == true || json['fixedRepaymentFrequency'] == 'true',
      charges: (json['charges'] as List?)
              ?.map((c) => ProductCharge.fromJson(c))
              .toList() ??
          [],
    );
  }
}

/// Product charge definition
class ProductCharge {
  final String name;
  final double amount;
  final String? type; // 'fixed' or 'percentage'
  final bool isProductCharge;

  ProductCharge({
    required this.name,
    required this.amount,
    this.type,
    this.isProductCharge = true,
  });

  factory ProductCharge.fromJson(Map<String, dynamic> json) {
    return ProductCharge(
      name: json['name']?.toString() ?? '',
      amount: _parseDouble(json['amount']) ?? 0,
      type: json['type']?.toString(),
      isProductCharge: json['isProductCharge'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'type': type,
        'isProductCharge': isProductCharge,
      };
}

/// Loan details (principal, tenure, etc.)
class LoanDetails {
  final double principalAmount;
  final double interestRate;
  final int tenure;
  final String repaymentFrequency;
  final int gracePeriod;

  LoanDetails({
    required this.principalAmount,
    required this.interestRate,
    required this.tenure,
    required this.repaymentFrequency,
    this.gracePeriod = 0,
  });

  factory LoanDetails.fromJson(Map<String, dynamic> json) {
    return LoanDetails(
      principalAmount: _parseDouble(json['principalAmount']) ??
                       _parseDouble(json['principal_amount']) ??
                       _parseDouble(json['amount']) ?? 0,
      interestRate: _parseDouble(json['interestRate']) ??
                    _parseDouble(json['interest_rate']) ?? 0,
      tenure: _parseInt(json['tenure']) ??
              _parseInt(json['loan_tenure']) ?? 1,
      repaymentFrequency: json['repaymentFrequency']?.toString() ??
                          json['repayment_frequency']?.toString() ?? 'Monthly',
      gracePeriod: _parseInt(json['gracePeriod']) ??
                   _parseInt(json['grace_period']) ?? 0,
    );
  }
}

/// Loan calculations (totals, installments)
class LoanCalculations {
  final double grossLoanAmount;
  final double totalCharges;
  final double netDisbursement;
  final double totalInterest;
  final double totalRepayment;
  final double monthlyInstallment;
  final double totalExposure;
  final DateTime? firstPaymentDate;
  final DateTime? maturityDate;

  LoanCalculations({
    required this.grossLoanAmount,
    required this.totalCharges,
    required this.netDisbursement,
    required this.totalInterest,
    required this.totalRepayment,
    required this.monthlyInstallment,
    required this.totalExposure,
    this.firstPaymentDate,
    this.maturityDate,
  });

  factory LoanCalculations.fromJson(Map<String, dynamic> json) {
    return LoanCalculations(
      grossLoanAmount: _parseDouble(json['grossLoanAmount']) ??
                       _parseDouble(json['gross_loan_amount']) ?? 0,
      totalCharges: _parseDouble(json['totalCharges']) ??
                    _parseDouble(json['total_charges']) ?? 0,
      netDisbursement: _parseDouble(json['netDisbursement']) ??
                       _parseDouble(json['net_disbursement']) ?? 0,
      totalInterest: _parseDouble(json['totalInterest']) ??
                     _parseDouble(json['total_interest']) ?? 0,
      totalRepayment: _parseDouble(json['totalRepayment']) ??
                      _parseDouble(json['total_repayment']) ?? 0,
      monthlyInstallment: _parseDouble(json['monthlyInstallment']) ??
                          _parseDouble(json['monthly_installment']) ??
                          _parseDouble(json['installment']) ?? 0,
      totalExposure: _parseDouble(json['totalExposure']) ??
                     _parseDouble(json['total_exposure']) ?? 0,
      firstPaymentDate: _parseDateTime(json['firstPaymentDate'] ?? json['first_payment_date']),
      maturityDate: _parseDateTime(json['maturityDate'] ?? json['maturity_date']),
    );
  }

  factory LoanCalculations.empty() => LoanCalculations(
        grossLoanAmount: 0,
        totalCharges: 0,
        netDisbursement: 0,
        totalInterest: 0,
        totalRepayment: 0,
        monthlyInstallment: 0,
        totalExposure: 0,
      );
}

/// Guarantor model
class Guarantor {
  final String guarantorUserId;
  final String guarantorName;
  final String guarantorPhone;
  final double guaranteedAmount;
  final String status; // pending, approved, rejected, defaulted
  final DateTime? approvedDate;
  final String? rejectionReason;
  final String? role;

  Guarantor({
    required this.guarantorUserId,
    required this.guarantorName,
    required this.guarantorPhone,
    required this.guaranteedAmount,
    required this.status,
    this.approvedDate,
    this.rejectionReason,
    this.role,
  });

  factory Guarantor.fromJson(Map<String, dynamic> json) {
    return Guarantor(
      guarantorUserId: json['guarantorUserId']?.toString() ??
                       json['userId']?.toString() ??
                       json['guarantor_user_id']?.toString() ?? '',
      guarantorName: json['guarantorName']?.toString() ??
                     json['name']?.toString() ??
                     json['guarantor_name']?.toString() ?? '',
      guarantorPhone: json['guarantorPhone']?.toString() ??
                      json['phone']?.toString() ??
                      json['guarantor_phone']?.toString() ?? '',
      guaranteedAmount: _parseDouble(json['guaranteedAmount']) ??
                        _parseDouble(json['guaranteed_amount']) ?? 0,
      status: json['status']?.toString() ?? 'pending',
      approvedDate: _parseDateTime(json['approvedDate'] ?? json['approved_date']),
      rejectionReason: json['rejectionReason']?.toString() ?? json['rejection_reason']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': guarantorUserId,
        'name': guarantorName,
        'phone': guarantorPhone,
        if (role != null) 'role': role,
      };

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved' || status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected' || status.toLowerCase() == 'declined';

  /// Status color for UI
  Color get statusColor {
    if (isApproved) return const Color(0xFF2E7D32);
    if (isRejected) return const Color(0xFFC62828);
    return Colors.orange;
  }

  /// Status display name in Swahili
  String get statusDisplayName {
    if (isApproved) return 'Ameidhinisha';
    if (isRejected) return 'Amekataa';
    return 'Anasubiri';
  }

  /// Status icon
  IconData get statusIcon {
    if (isApproved) return Icons.check_circle;
    if (isRejected) return Icons.cancel;
    return Icons.hourglass_empty;
  }
}

/// Loan charge (fees associated with loan)
class LoanCharge {
  final String name;
  final double amount;
  final String? type;
  final bool isProductCharge;

  LoanCharge({
    required this.name,
    required this.amount,
    this.type,
    this.isProductCharge = false,
  });

  factory LoanCharge.fromJson(Map<String, dynamic> json) {
    return LoanCharge(
      name: json['name']?.toString() ?? '',
      amount: _parseDouble(json['amount']) ?? 0,
      type: json['type']?.toString(),
      isProductCharge: json['isProductCharge'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'type': type,
        'isProductCharge': isProductCharge,
      };
}

/// Loan voting summary (extends existing VotingSummary)
class LoanVotingSummary {
  final int totalVotes;
  final int yesVotes;
  final int noVotes;
  final int abstainVotes;
  final double approvalPercentage;
  final double rejectionPercentage;
  final double threshold;
  final bool hasReachedThreshold;
  final bool hasMinimumVotes;

  LoanVotingSummary({
    required this.totalVotes,
    required this.yesVotes,
    required this.noVotes,
    required this.abstainVotes,
    required this.approvalPercentage,
    required this.rejectionPercentage,
    required this.threshold,
    required this.hasReachedThreshold,
    required this.hasMinimumVotes,
  });

  factory LoanVotingSummary.fromJson(Map<String, dynamic> json) {
    return LoanVotingSummary(
      totalVotes: _parseInt(json['totalVotes']) ?? _parseInt(json['total_votes']) ?? 0,
      yesVotes: _parseInt(json['yesVotes']) ?? _parseInt(json['yes_count']) ?? 0,
      noVotes: _parseInt(json['noVotes']) ?? _parseInt(json['no_count']) ?? 0,
      abstainVotes: _parseInt(json['abstainVotes']) ?? _parseInt(json['abstain_count']) ?? 0,
      approvalPercentage: _parseDouble(json['approvalPercentage']) ??
                          _parseDouble(json['approval_percentage']) ?? 0,
      rejectionPercentage: _parseDouble(json['rejectionPercentage']) ??
                           _parseDouble(json['rejection_percentage']) ?? 0,
      threshold: _parseDouble(json['threshold']) ??
                 _parseDouble(json['approval_threshold']) ?? 66.67,
      hasReachedThreshold: json['hasReachedThreshold'] ??
                           json['has_reached_approval'] ?? false,
      hasMinimumVotes: json['hasMinimumVotes'] ??
                       json['has_minimum_votes'] ?? false,
    );
  }

  factory LoanVotingSummary.empty() => LoanVotingSummary(
        totalVotes: 0,
        yesVotes: 0,
        noVotes: 0,
        abstainVotes: 0,
        approvalPercentage: 0,
        rejectionPercentage: 0,
        threshold: 66.67,
        hasReachedThreshold: false,
        hasMinimumVotes: false,
      );

  /// Create from existing VotingSummary
  factory LoanVotingSummary.fromVotingSummary(VotingSummary vs, {double threshold = 66.67}) {
    return LoanVotingSummary(
      totalVotes: vs.totalVotes,
      yesVotes: vs.yesCount,
      noVotes: vs.noCount,
      abstainVotes: vs.abstainCount,
      approvalPercentage: vs.approvalPercentage,
      rejectionPercentage: vs.rejectionPercentage,
      threshold: threshold,
      hasReachedThreshold: vs.hasReachedApproval,
      hasMinimumVotes: vs.hasMinimumVotes,
    );
  }
}

/// Main loan application model
class LoanApplication {
  final String applicationId;
  final String kikobaId;
  final String userId;
  final String applicantName;
  final String applicantPhone;
  final LoanProduct? loanProduct;
  final String loanType; // 'new' or 'topup'
  final LoanDetails loanDetails;
  final LoanCalculations calculations;
  final LoanStatus status;
  final List<Guarantor> guarantors;
  final List<LoanCharge> charges;
  final LoanVotingSummary? voting;

  // Audit fields
  final DateTime? applicationDate;
  final DateTime? approvedDate;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectedByName;
  final String? rejectionReason;
  final DateTime? failedAt;
  final String? failureReason;
  final DateTime? disbursedDate;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  // Additional fields
  final String? purpose;
  final String? comments;

  LoanApplication({
    required this.applicationId,
    required this.kikobaId,
    required this.userId,
    required this.applicantName,
    required this.applicantPhone,
    this.loanProduct,
    required this.loanType,
    required this.loanDetails,
    required this.calculations,
    required this.status,
    required this.guarantors,
    required this.charges,
    this.voting,
    this.applicationDate,
    this.approvedDate,
    this.approvedBy,
    this.approvedByName,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectedByName,
    this.rejectionReason,
    this.failedAt,
    this.failureReason,
    this.disbursedDate,
    this.cancelledAt,
    this.cancellationReason,
    this.purpose,
    this.comments,
  });

  factory LoanApplication.fromJson(Map<String, dynamic> json) {
    // Parse loan details - may be nested or flat
    LoanDetails details;
    if (json['loanDetails'] != null) {
      details = LoanDetails.fromJson(json['loanDetails']);
    } else {
      details = LoanDetails.fromJson(json);
    }

    // Parse calculations - may be nested or flat
    LoanCalculations calcs;
    if (json['calculations'] != null) {
      calcs = LoanCalculations.fromJson(json['calculations']);
    } else {
      calcs = LoanCalculations.fromJson(json);
    }

    return LoanApplication(
      applicationId: json['applicationId']?.toString() ??
                     json['application_id']?.toString() ??
                     json['id']?.toString() ?? '',
      kikobaId: json['kikobaId']?.toString() ??
                json['kikoba_id']?.toString() ?? '',
      userId: json['userId']?.toString() ??
              json['user_id']?.toString() ?? '',
      applicantName: json['applicantName']?.toString() ??
                     json['applicant_name']?.toString() ??
                     json['memberName']?.toString() ?? '',
      applicantPhone: json['applicantPhone']?.toString() ??
                      json['applicant_phone']?.toString() ??
                      json['memberPhone']?.toString() ?? '',
      loanProduct: json['loanProduct'] != null
          ? LoanProduct.fromJson(json['loanProduct'])
          : json['product'] != null
              ? LoanProduct.fromJson(json['product'])
              : null,
      loanType: json['loanType']?.toString() ??
                json['loan_type']?.toString() ?? 'new',
      loanDetails: details,
      calculations: calcs,
      status: LoanStatus.fromString(json['status']?.toString()),
      guarantors: _parseGuarantors(json['guarantors']),
      charges: _parseCharges(json['charges']),
      voting: json['voting'] != null
          ? LoanVotingSummary.fromJson(json['voting'])
          : json['voting_summary'] != null
              ? LoanVotingSummary.fromJson(json['voting_summary'])
              : null,
      applicationDate: _parseDateTime(json['applicationDate'] ?? json['application_date'] ?? json['created_at']),
      approvedDate: _parseDateTime(json['approvedDate'] ?? json['approved_date']),
      approvedBy: json['approvedBy']?.toString() ?? json['approved_by']?.toString(),
      approvedByName: json['approvedByName']?.toString() ?? json['approved_by_name']?.toString(),
      rejectedAt: _parseDateTime(json['rejectedAt'] ?? json['rejected_at']),
      rejectedBy: json['rejectedBy']?.toString() ?? json['rejected_by']?.toString(),
      rejectedByName: json['rejectedByName']?.toString() ?? json['rejected_by_name']?.toString(),
      rejectionReason: json['rejectionReason']?.toString() ?? json['rejection_reason']?.toString(),
      failedAt: _parseDateTime(json['failedAt'] ?? json['failed_at']),
      failureReason: json['failureReason']?.toString() ?? json['failure_reason']?.toString(),
      disbursedDate: _parseDateTime(json['disbursedDate'] ?? json['disbursed_date']),
      cancelledAt: _parseDateTime(json['cancelledAt'] ?? json['cancelled_at']),
      cancellationReason: json['cancellationReason']?.toString() ?? json['cancellation_reason']?.toString(),
      purpose: json['purpose']?.toString(),
      comments: json['comments']?.toString(),
    );
  }

  // Helper getters
  bool get canCancel => [
        LoanStatus.guarantorPending,
        LoanStatus.pendingApproval,
        LoanStatus.approved,
      ].contains(status);

  bool get isActive => status == LoanStatus.active;

  bool get isRejected => [
        LoanStatus.rejected,
        LoanStatus.guarantorRejected,
      ].contains(status);

  bool get isPending => [
        LoanStatus.guarantorPending,
        LoanStatus.pendingApproval,
      ].contains(status);

  bool get isDisbursed => [
        LoanStatus.disbursed,
        LoanStatus.active,
        LoanStatus.closed,
      ].contains(status);

  int get approvedGuarantorsCount => guarantors.where((g) => g.isApproved).length;

  int get pendingGuarantorsCount => guarantors.where((g) => g.isPending).length;

  int get rejectedGuarantorsCount => guarantors.where((g) => g.isRejected).length;

  double get guarantorProgressPercent =>
      guarantors.isEmpty ? 0 : approvedGuarantorsCount / guarantors.length;

  bool get allGuarantorsApproved =>
      guarantors.isNotEmpty && guarantors.every((g) => g.isApproved);

  bool get anyGuarantorRejected => guarantors.any((g) => g.isRejected);
}

/// Loan repayment schedule item
class LoanSchedule {
  final int id;
  final int installmentNumber;
  final DateTime dueDate;
  final double principalAmount;
  final double interestAmount;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final String status; // pending, paid, partial, overdue
  final DateTime? paidDate;

  LoanSchedule({
    required this.id,
    required this.installmentNumber,
    required this.dueDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.status,
    this.paidDate,
  });

  factory LoanSchedule.fromJson(Map<String, dynamic> json) {
    return LoanSchedule(
      id: _parseInt(json['id']) ?? 0,
      installmentNumber: _parseInt(json['installmentNumber']) ??
                         _parseInt(json['installment_number']) ??
                         _parseInt(json['number']) ?? 1,
      dueDate: _parseDateTime(json['dueDate'] ?? json['due_date']) ?? DateTime.now(),
      principalAmount: _parseDouble(json['principalAmount']) ??
                       _parseDouble(json['principal_amount']) ??
                       _parseDouble(json['principal']) ?? 0,
      interestAmount: _parseDouble(json['interestAmount']) ??
                      _parseDouble(json['interest_amount']) ??
                      _parseDouble(json['interest']) ?? 0,
      totalAmount: _parseDouble(json['totalAmount']) ??
                   _parseDouble(json['total_amount']) ??
                   _parseDouble(json['amount']) ?? 0,
      paidAmount: _parseDouble(json['paidAmount']) ??
                  _parseDouble(json['paid_amount']) ?? 0,
      balance: _parseDouble(json['balance']) ??
               _parseDouble(json['outstanding']) ?? 0,
      status: json['status']?.toString() ?? 'pending',
      paidDate: _parseDateTime(json['paidDate'] ?? json['paid_date']),
    );
  }

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
  bool get isPartial => status.toLowerCase() == 'partial';
  bool get isPending => status.toLowerCase() == 'pending' && !isOverdue;

  /// Days overdue (0 if not overdue)
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }
}

/// Loan payment record
class LoanPayment {
  final int id;
  final String applicationId;
  final double amount;
  final String paymentMethod;
  final String reference;
  final DateTime paymentDate;
  final String status; // pending, completed, failed
  final double? principalAllocation;
  final double? interestAllocation;
  final double? penaltyAllocation;

  LoanPayment({
    required this.id,
    required this.applicationId,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    required this.paymentDate,
    required this.status,
    this.principalAllocation,
    this.interestAllocation,
    this.penaltyAllocation,
  });

  factory LoanPayment.fromJson(Map<String, dynamic> json) {
    return LoanPayment(
      id: _parseInt(json['id']) ?? 0,
      applicationId: json['applicationId']?.toString() ??
                     json['application_id']?.toString() ?? '',
      amount: _parseDouble(json['amount']) ?? 0,
      paymentMethod: json['paymentMethod']?.toString() ??
                     json['payment_method']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      paymentDate: _parseDateTime(json['paymentDate'] ?? json['payment_date'] ?? json['created_at']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'completed',
      principalAllocation: _parseDouble(json['principalAllocation'] ?? json['principal_allocation']),
      interestAllocation: _parseDouble(json['interestAllocation'] ?? json['interest_allocation']),
      penaltyAllocation: _parseDouble(json['penaltyAllocation'] ?? json['penalty_allocation']),
    );
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
}

/// Loan arrears summary
class LoanArrears {
  final double totalOverdue;
  final int overdueInstallments;
  final int daysOverdue;
  final bool isDefaulted;
  final double penaltyAmount;
  final DateTime? oldestOverdueDate;

  LoanArrears({
    required this.totalOverdue,
    required this.overdueInstallments,
    required this.daysOverdue,
    required this.isDefaulted,
    this.penaltyAmount = 0,
    this.oldestOverdueDate,
  });

  factory LoanArrears.fromJson(Map<String, dynamic> json) {
    return LoanArrears(
      totalOverdue: _parseDouble(json['totalOverdue']) ??
                    _parseDouble(json['total_overdue']) ?? 0,
      overdueInstallments: _parseInt(json['overdueInstallments']) ??
                           _parseInt(json['overdue_installments']) ?? 0,
      daysOverdue: _parseInt(json['daysOverdue']) ??
                   _parseInt(json['days_overdue']) ?? 0,
      isDefaulted: json['isDefaulted'] ?? json['is_defaulted'] ?? false,
      penaltyAmount: _parseDouble(json['penaltyAmount']) ??
                     _parseDouble(json['penalty_amount']) ?? 0,
      oldestOverdueDate: _parseDateTime(json['oldestOverdueDate'] ?? json['oldest_overdue_date']),
    );
  }

  factory LoanArrears.empty() => LoanArrears(
        totalOverdue: 0,
        overdueInstallments: 0,
        daysOverdue: 0,
        isDefaulted: false,
      );

  bool get hasArrears => totalOverdue > 0;
}

/// Eligibility check result
class EligibilityResult {
  final bool isEligible;
  final double maxAmount;
  final double currentDebt;
  final double availableCapacity;
  final List<String> issues;
  final String? message;

  EligibilityResult({
    required this.isEligible,
    required this.maxAmount,
    required this.currentDebt,
    required this.availableCapacity,
    required this.issues,
    this.message,
  });

  factory EligibilityResult.fromJson(Map<String, dynamic> json) {
    return EligibilityResult(
      isEligible: json['eligible'] ?? json['isEligible'] ?? false,
      maxAmount: _parseDouble(json['maxAmount']) ?? _parseDouble(json['max_amount']) ?? 0,
      currentDebt: _parseDouble(json['currentDebt']) ?? _parseDouble(json['current_debt']) ?? 0,
      availableCapacity: _parseDouble(json['availableCapacity']) ?? _parseDouble(json['available_capacity']) ?? 0,
      issues: (json['issues'] as List?)?.map((e) => e.toString()).toList() ?? [],
      message: json['message']?.toString(),
    );
  }
}

/// Guarantor limit information
class GuarantorLimit {
  final double maxGuaranteeAmount;
  final double currentGuaranteeAmount;
  final double availableAmount;
  final int maxActiveLoans;
  final int currentActiveLoans;
  final double utilizationPercentage;

  GuarantorLimit({
    required this.maxGuaranteeAmount,
    required this.currentGuaranteeAmount,
    required this.availableAmount,
    required this.maxActiveLoans,
    required this.currentActiveLoans,
    required this.utilizationPercentage,
  });

  factory GuarantorLimit.fromJson(Map<String, dynamic> json) {
    return GuarantorLimit(
      maxGuaranteeAmount: _parseDouble(json['maxGuaranteeAmount']) ??
                          _parseDouble(json['max_guarantee_amount']) ?? 0,
      currentGuaranteeAmount: _parseDouble(json['currentGuaranteeAmount']) ??
                              _parseDouble(json['current_guarantee_amount']) ?? 0,
      availableAmount: _parseDouble(json['availableAmount']) ??
                       _parseDouble(json['available_amount']) ?? 0,
      maxActiveLoans: _parseInt(json['maxActiveLoans']) ??
                      _parseInt(json['max_active_loans']) ?? 5,
      currentActiveLoans: _parseInt(json['currentActiveLoans']) ??
                          _parseInt(json['current_active_loans']) ?? 0,
      utilizationPercentage: _parseDouble(json['utilizationPercentage']) ??
                             _parseDouble(json['utilization_percentage']) ?? 0,
    );
  }

  bool get hasCapacity => availableAmount > 0 && currentActiveLoans < maxActiveLoans;
}

/// Payment result from making a payment
class PaymentResult {
  final int paymentId;
  final double amountPaid;
  final double newBalance;
  final double principalPaid;
  final double interestPaid;
  final double penaltyPaid;
  final int installmentsPaid;
  final bool loanFullyPaid;

  PaymentResult({
    required this.paymentId,
    required this.amountPaid,
    required this.newBalance,
    required this.principalPaid,
    required this.interestPaid,
    required this.penaltyPaid,
    required this.installmentsPaid,
    required this.loanFullyPaid,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      paymentId: _parseInt(json['paymentId']) ?? _parseInt(json['payment_id']) ?? 0,
      amountPaid: _parseDouble(json['amountPaid']) ?? _parseDouble(json['amount_paid']) ?? 0,
      newBalance: _parseDouble(json['newBalance']) ?? _parseDouble(json['new_balance']) ?? 0,
      principalPaid: _parseDouble(json['principalPaid']) ?? _parseDouble(json['principal_paid']) ?? 0,
      interestPaid: _parseDouble(json['interestPaid']) ?? _parseDouble(json['interest_paid']) ?? 0,
      penaltyPaid: _parseDouble(json['penaltyPaid']) ?? _parseDouble(json['penalty_paid']) ?? 0,
      installmentsPaid: _parseInt(json['installmentsPaid']) ?? _parseInt(json['installments_paid']) ?? 0,
      loanFullyPaid: json['loanFullyPaid'] ?? json['loan_fully_paid'] ?? false,
    );
  }
}

// Helper functions
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<Guarantor> _parseGuarantors(dynamic value) {
  if (value == null) return [];
  if (value is! List) return [];
  return value.map((g) => Guarantor.fromJson(g as Map<String, dynamic>)).toList();
}

List<LoanCharge> _parseCharges(dynamic value) {
  if (value == null) return [];
  if (value is! List) return [];
  return value.map((c) => LoanCharge.fromJson(c as Map<String, dynamic>)).toList();
}
