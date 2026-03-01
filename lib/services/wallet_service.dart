import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class WalletService {
  /// Get user's wallet (GET /api/wallet/{userId})
  Future<WalletResult> getWallet(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return WalletResult(
            success: true,
            wallet: Wallet.fromJson(data['data']),
          );
        }
      }
      return WalletResult(success: false, message: 'Imeshindwa kupakia pochi');
    } catch (e) {
      return WalletResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Set wallet PIN
  Future<SimpleResult> setPin({
    required int userId,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return SimpleResult(success: true, message: 'PIN imewekwa');
      }
      return SimpleResult(success: false, message: data['message'] ?? 'Imeshindwa kuweka PIN');
    } catch (e) {
      return SimpleResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get wallet transactions (GET /api/wallet/{userId}/transactions)
  Future<TransactionListResult> getTransactions({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? type,
    String? status,
  }) async {
    try {
      String url = '$_baseUrl/wallet/$userId/transactions?page=$page&per_page=$perPage';
      if (type != null) url += '&type=$type';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final transactions = (data['data'] as List)
              .map((t) => WalletTransaction.fromJson(t))
              .toList();
          return TransactionListResult(
            success: true,
            transactions: transactions,
            meta: data['meta'] != null ? WalletPaginationMeta.fromJson(data['meta']) : null,
          );
        }
      }
      return TransactionListResult(success: false, message: 'Imeshindwa kupakia miamala');
    } catch (e) {
      return TransactionListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Deposit to wallet (M-Pesa, Tigo Pesa, Airtel Money via ClickPesa)
  Future<TransactionResult> deposit({
    required int userId,
    required double amount,
    required String provider,
    required String phoneNumber,
    String? pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/$userId/deposit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'provider': provider,
          'phone_number': phoneNumber,
          if (pin != null) 'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TransactionResult(
          success: true,
          transaction: WalletTransaction.fromJson(data['data']),
        );
      }
      return TransactionResult(success: false, message: data['message'] ?? 'Imeshindwa kuingiza pesa');
    } catch (e) {
      return TransactionResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Withdraw from wallet (M-Pesa, Tigo Pesa, Airtel Money via ClickPesa)
  Future<TransactionResult> withdraw({
    required int userId,
    required double amount,
    required String provider,
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/$userId/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'provider': provider,
          'phone_number': phoneNumber,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TransactionResult(
          success: true,
          transaction: WalletTransaction.fromJson(data['data']),
        );
      }
      return TransactionResult(success: false, message: data['message'] ?? 'Imeshindwa kutoa pesa');
    } catch (e) {
      return TransactionResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Transfer to another user (P2P). Recipient by user ID or phone number.
  /// POST /api/wallet/{userId}/transfer
  Future<TransactionResult> transfer({
    required int userId,
    int? recipientId,
    String? recipientPhone,
    required double amount,
    required String pin,
    String? description,
  }) async {
    assert(
      (recipientId != null) != (recipientPhone != null && recipientPhone.isNotEmpty),
      'Provide either recipientId or recipientPhone',
    );
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'pin': pin,
        if (description != null && description.isNotEmpty) 'description': description,
      };
      if (recipientId != null) {
        body['recipient_id'] = recipientId;
      } else if (recipientPhone != null && recipientPhone.isNotEmpty) {
        body['recipient_phone'] = recipientPhone.trim();
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/$userId/transfer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TransactionResult(
          success: true,
          transaction: WalletTransaction.fromJson(data['data']),
        );
      }
      return TransactionResult(success: false, message: data['message'] ?? 'Imeshindwa kutuma pesa');
    } catch (e) {
      return TransactionResult(success: false, message: 'Kosa: $e');
    }
  }

  // ========== MOBILE MONEY ACCOUNTS ==========

  /// Get saved mobile money accounts
  Future<MobileAccountListResult> getMobileAccounts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/mobile-accounts?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final accounts = (data['data'] as List)
              .map((a) => MobileMoneyAccount.fromJson(a))
              .toList();
          return MobileAccountListResult(success: true, accounts: accounts);
        }
      }
      return MobileAccountListResult(success: false, message: 'Imeshindwa kupakia akaunti');
    } catch (e) {
      return MobileAccountListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Add a mobile money account
  Future<MobileAccountResult> addMobileAccount({
    required int userId,
    required String provider,
    required String phoneNumber,
    required String accountName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/mobile-accounts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'provider': provider,
          'phone_number': phoneNumber,
          'account_name': accountName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return MobileAccountResult(
          success: true,
          account: MobileMoneyAccount.fromJson(data['data']),
        );
      }
      return MobileAccountResult(success: false, message: data['message'] ?? 'Imeshindwa kuongeza akaunti');
    } catch (e) {
      return MobileAccountResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Delete a mobile money account
  Future<bool> deleteMobileAccount({
    required int userId,
    required int accountId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/wallet/mobile-accounts/$accountId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Set primary mobile account
  Future<bool> setPrimaryAccount({
    required int userId,
    required int accountId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/wallet/mobile-accounts/$accountId/primary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ========== PAYMENT REQUESTS ==========

  /// Create a payment request
  Future<PaymentRequestResult> createPaymentRequest({
    required int userId,
    required int payerId,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/payment-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'payer_id': payerId,
          'amount': amount,
          if (description != null) 'description': description,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return PaymentRequestResult(
          success: true,
          request: PaymentRequest.fromJson(data['data']),
        );
      }
      return PaymentRequestResult(success: false, message: data['message'] ?? 'Imeshindwa kutuma ombi');
    } catch (e) {
      return PaymentRequestResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get payment requests
  Future<PaymentRequestListResult> getPaymentRequests({
    required int userId,
    String direction = 'received', // received, sent
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/payment-requests?user_id=$userId&direction=$direction&page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final requests = (data['data'] as List)
              .map((r) => PaymentRequest.fromJson(r))
              .toList();
          return PaymentRequestListResult(
            success: true,
            requests: requests,
            meta: data['meta'] != null ? WalletPaginationMeta.fromJson(data['meta']) : null,
          );
        }
      }
      return PaymentRequestListResult(success: false, message: 'Imeshindwa kupakia maombi');
    } catch (e) {
      return PaymentRequestListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Pay a payment request
  Future<TransactionResult> payRequest({
    required int userId,
    required String requestId,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/payment-requests/$requestId/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TransactionResult(
          success: true,
          transaction: WalletTransaction.fromJson(data['data']),
        );
      }
      return TransactionResult(success: false, message: data['message'] ?? 'Imeshindwa kulipa');
    } catch (e) {
      return TransactionResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Decline a payment request
  Future<bool> declineRequest({
    required int userId,
    required String requestId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/payment-requests/$requestId/decline'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Calculate transfer fee
  Future<FeeCalculationResult> calculateFee({
    required double amount,
    required String type, // transfer, withdrawal
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/calculate-fee?amount=$amount&type=$type'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FeeCalculationResult(
            success: true,
            fee: (data['data']['fee'] ?? 0).toDouble(),
            total: (data['data']['total'] ?? 0).toDouble(),
          );
        }
      }
      return FeeCalculationResult(success: false, message: 'Imeshindwa kukokotoa ada');
    } catch (e) {
      return FeeCalculationResult(success: false, message: 'Kosa: $e');
    }
  }
}

// Result classes
class WalletResult {
  final bool success;
  final Wallet? wallet;
  final String? message;

  WalletResult({required this.success, this.wallet, this.message});
}

class SimpleResult {
  final bool success;
  final String? message;

  SimpleResult({required this.success, this.message});
}

class TransactionListResult {
  final bool success;
  final List<WalletTransaction> transactions;
  final WalletPaginationMeta? meta;
  final String? message;

  TransactionListResult({
    required this.success,
    this.transactions = const [],
    this.meta,
    this.message,
  });
}

class TransactionResult {
  final bool success;
  final WalletTransaction? transaction;
  final String? message;

  TransactionResult({required this.success, this.transaction, this.message});
}

class MobileAccountListResult {
  final bool success;
  final List<MobileMoneyAccount> accounts;
  final String? message;

  MobileAccountListResult({required this.success, this.accounts = const [], this.message});
}

class MobileAccountResult {
  final bool success;
  final MobileMoneyAccount? account;
  final String? message;

  MobileAccountResult({required this.success, this.account, this.message});
}

class PaymentRequestResult {
  final bool success;
  final PaymentRequest? request;
  final String? message;

  PaymentRequestResult({required this.success, this.request, this.message});
}

class PaymentRequestListResult {
  final bool success;
  final List<PaymentRequest> requests;
  final WalletPaginationMeta? meta;
  final String? message;

  PaymentRequestListResult({
    required this.success,
    this.requests = const [],
    this.meta,
    this.message,
  });
}

class FeeCalculationResult {
  final bool success;
  final double fee;
  final double total;
  final String? message;

  FeeCalculationResult({
    required this.success,
    this.fee = 0,
    this.total = 0,
    this.message,
  });
}

class WalletPaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  WalletPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory WalletPaginationMeta.fromJson(Map<String, dynamic> json) {
    return WalletPaginationMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}
