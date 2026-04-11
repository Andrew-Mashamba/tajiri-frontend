// lib/loans/services/loan_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/loan_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class BoostLoanService {
  // ─── Credit Score ──────────────────────────────────────────────

  Future<LoanResult<CreatorCreditScore>> getCreditScore(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/loans/credit-score?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return LoanResult(
            success: true,
            data: CreatorCreditScore.fromJson(data['data']),
          );
        }
      }
      return LoanResult(success: false, message: 'Imeshindwa kupakia alama ya mkopo');
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Loan Application ─────────────────────────────────────────

  Future<LoanResult<BoostLoan>> applyForLoan({
    required int userId,
    required LoanTier tier,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/loans/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'tier': tier.name,
          'amount': amount,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return LoanResult(
          success: true,
          data: BoostLoan.fromJson(data['data']),
        );
      }
      return LoanResult(success: false, message: data['message'] ?? 'Imeshindwa kuomba mkopo');
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Active Loans ──────────────────────────────────────────────

  Future<LoanListResult<BoostLoan>> getMyLoans(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/loans/my-loans?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => BoostLoan.fromJson(j))
              .toList();
          return LoanListResult(success: true, items: items);
        }
      }
      return LoanListResult(success: false, message: 'Imeshindwa kupakia mikopo');
    } catch (e) {
      return LoanListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<LoanResult<BoostLoan>> getLoanDetail(int loanId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/loans/$loanId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return LoanResult(
            success: true,
            data: BoostLoan.fromJson(data['data']),
          );
        }
      }
      return LoanResult(success: false, message: 'Imeshindwa kupakia mkopo');
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Repayment History ─────────────────────────────────────────

  Future<LoanListResult<LoanRepaymentEvent>> getRepaymentHistory(int loanId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/loans/$loanId/repayments'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => LoanRepaymentEvent.fromJson(j))
              .toList();
          return LoanListResult(success: true, items: items);
        }
      }
      return LoanListResult(success: false, message: 'Imeshindwa kupakia historia');
    } catch (e) {
      return LoanListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Loan Actions ──────────────────────────────────────────────

  Future<LoanResult<BoostLoan>> requestPause(int loanId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/loans/$loanId/pause'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return LoanResult(success: true, data: BoostLoan.fromJson(data['data']));
      }
      return LoanResult(success: false, message: data['message'] ?? 'Imeshindwa kusimamisha');
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<LoanResult<void>> makeManualRepayment({
    required int loanId,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/loans/$loanId/repay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return LoanResult(success: true);
      }
      return LoanResult(success: false, message: data['message'] ?? 'Imeshindwa kulipa');
    } catch (e) {
      return LoanResult(success: false, message: 'Kosa: $e');
    }
  }
}
