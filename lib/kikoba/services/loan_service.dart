/// VICOBA Loan Service
///
/// Service layer for loan operations, wrapping HttpService with typed models.

import '../models/loan_models.dart';
import '../HttpService.dart';

class LoanService {
  /// Get user's loan applications
  static Future<List<LoanApplication>> getMyApplications({
    String? userId,
    String? kikobaId,
    String? status,
  }) async {
    final data = await HttpService.getLoanApplications(
      userId: userId,
      kikobaId: kikobaId,
      status: status,
    );

    if (data == null) return [];

    return data.map((json) => LoanApplication.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get a single loan application by ID
  static Future<LoanApplication?> getApplicationDetails(String applicationId) async {
    final data = await HttpService.getLoanApplication(applicationId);

    if (data == null) return null;
    if (data['status'] != 'success') return null;

    final appData = data['data'];
    if (appData == null) return null;

    return LoanApplication.fromJson(appData as Map<String, dynamic>);
  }

  /// Submit a new loan application
  static Future<LoanApplicationResult> submitApplication(Map<String, dynamic> application) async {
    final response = await HttpService.submitLoanApplication(application);

    if (response == null) {
      return LoanApplicationResult(
        success: false,
        message: 'Haikuweza kuwasiliana na seva. Jaribu tena.',
      );
    }

    final success = response['status'] == 'success' || response['success'] == true;

    if (success && response['data'] != null) {
      return LoanApplicationResult(
        success: true,
        message: response['message']?.toString() ?? 'Ombi limewasilishwa kikamilifu',
        application: LoanApplication.fromJson(response['data'] as Map<String, dynamic>),
      );
    }

    return LoanApplicationResult(
      success: false,
      message: response['message']?.toString() ?? 'Imeshindikana kuwasilisha ombi',
      errors: (response['errors'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  /// Cancel a loan application
  static Future<bool> cancelApplication(String applicationId, {String? reason}) async {
    final response = await HttpService.cancelLoanApplication(applicationId, reason: reason);
    return response != null && (response['status'] == 'success' || response['success'] == true);
  }

  /// Get loan repayment schedule
  static Future<List<LoanSchedule>> getSchedule(String applicationId) async {
    final response = await HttpService.getLoanSchedule(applicationId);

    if (response == null) return [];
    if (response['status'] != 'success') return [];

    final data = response['data'];
    if (data == null) return [];

    if (data is List) {
      return data.map((s) => LoanSchedule.fromJson(s as Map<String, dynamic>)).toList();
    }

    if (data is Map && data['schedules'] != null) {
      return (data['schedules'] as List)
          .map((s) => LoanSchedule.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get loan arrears
  static Future<LoanArrears> getArrears(String applicationId) async {
    final response = await HttpService.getLoanArrears(applicationId);

    if (response == null) return LoanArrears.empty();
    if (response['status'] != 'success') return LoanArrears.empty();

    final data = response['data'];
    if (data == null) return LoanArrears.empty();

    return LoanArrears.fromJson(data as Map<String, dynamic>);
  }

  /// Record a loan payment
  static Future<PaymentResult?> recordPayment({
    required String applicationId,
    required double amount,
    required String paymentMethod,
    required String reference,
  }) async {
    final response = await HttpService.recordLoanPayment(
      applicationId: applicationId,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
    );

    if (response == null) return null;
    if (response['status'] != 'success') return null;

    final data = response['data'];
    if (data == null) return null;

    return PaymentResult.fromJson(data as Map<String, dynamic>);
  }

  /// Get payment history for a loan
  static Future<List<LoanPayment>> getPaymentHistory(String applicationId) async {
    final response = await HttpService.getLoanPayments(applicationId);

    if (response == null) return [];
    if (response['status'] != 'success') return [];

    final data = response['data'];
    if (data == null) return [];

    if (data is List) {
      return data.map((p) => LoanPayment.fromJson(p as Map<String, dynamic>)).toList();
    }

    if (data is Map && data['payments'] != null) {
      return (data['payments'] as List)
          .map((p) => LoanPayment.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Check loan eligibility
  static Future<EligibilityResult> checkEligibility({
    required String kikobaId,
    required String userId,
    required double amount,
  }) async {
    final response = await HttpService.checkLoanEligibility(
      kikobaId: kikobaId,
      userId: userId,
      amount: amount,
    );

    if (response == null) {
      return EligibilityResult(
        isEligible: false,
        maxAmount: 0,
        currentDebt: 0,
        availableCapacity: 0,
        issues: ['Haikuweza kuwasiliana na seva'],
      );
    }

    return EligibilityResult.fromJson(response);
  }

  /// Get guarantor limit information
  static Future<GuarantorLimit?> getGuarantorLimit({String? userId}) async {
    // HttpService.getGuarantorLimit returns the data object directly (not wrapped in response)
    final data = await HttpService.getGuarantorLimit(userId: userId);

    if (data == null) return null;

    return GuarantorLimit.fromJson(data as Map<String, dynamic>);
  }

  /// Get loans guaranteed by current user
  static Future<List<LoanApplication>> getMyGuaranteedLoans({String? userId}) async {
    final data = await HttpService.getMyGuaranteedLoans(userId: userId);

    if (data == null) return [];

    return data.map((json) => LoanApplication.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get pending guarantee requests for current user
  static Future<List<LoanApplication>> getPendingGuaranteeRequests({String? userId}) async {
    final data = await HttpService.getPendingGuaranteeRequests(userId: userId);

    if (data == null) return [];

    return data.map((json) => LoanApplication.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Approve a guarantee request
  static Future<GuaranteeActionResult> approveGuarantee(String applicationId, {String? comments}) async {
    final response = await HttpService.approveGuarantee(applicationId, comments: comments);

    if (response == null) {
      return GuaranteeActionResult(
        success: false,
        message: 'Haikuweza kuwasiliana na seva',
      );
    }

    final success = response['status'] == 'success' || response['success'] == true;

    return GuaranteeActionResult(
      success: success,
      message: response['message']?.toString() ?? (success ? 'Umeidhinisha kikamilifu' : 'Imeshindikana'),
    );
  }

  /// Reject a guarantee request
  static Future<GuaranteeActionResult> rejectGuarantee(String applicationId, {required String reason}) async {
    final response = await HttpService.rejectGuarantee(applicationId, reason: reason);

    if (response == null) {
      return GuaranteeActionResult(
        success: false,
        message: 'Haikuweza kuwasiliana na seva',
      );
    }

    final success = response['status'] == 'success' || response['success'] == true;

    return GuaranteeActionResult(
      success: success,
      message: response['message']?.toString() ?? (success ? 'Umekataa kikamilifu' : 'Imeshindikana'),
    );
  }

  /// Withdraw a guarantee
  static Future<GuaranteeActionResult> withdrawGuarantee(String applicationId, {String? reason}) async {
    final response = await HttpService.withdrawGuarantee(applicationId, reason: reason);

    if (response == null) {
      return GuaranteeActionResult(
        success: false,
        message: 'Haikuweza kuwasiliana na seva',
      );
    }

    final success = response['status'] == 'success' || response['success'] == true;

    return GuaranteeActionResult(
      success: success,
      message: response['message']?.toString() ?? (success ? 'Umejiondoa kikamilifu' : 'Imeshindikana'),
    );
  }

  /// Record a loan payment (updated with optional parameters)
  static Future<PaymentResult?> recordPaymentWithDetails({
    required String applicationId,
    required double amount,
    required String paymentMethod,
    required String reference,
    String? externalReference,
    String? notes,
  }) async {
    final response = await HttpService.recordLoanPayment(
      applicationId: applicationId,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      externalReference: externalReference,
      notes: notes,
    );

    if (response == null) return null;
    if (response['status'] != 'success') return null;

    final data = response['data'];
    if (data == null) return null;

    return PaymentResult.fromJson(data as Map<String, dynamic>);
  }
}

/// Result from loan application submission
class LoanApplicationResult {
  final bool success;
  final String message;
  final LoanApplication? application;
  final Map<String, String>? errors;

  LoanApplicationResult({
    required this.success,
    required this.message,
    this.application,
    this.errors,
  });
}

/// Result from guarantee action
class GuaranteeActionResult {
  final bool success;
  final String message;

  GuaranteeActionResult({
    required this.success,
    required this.message,
  });
}
