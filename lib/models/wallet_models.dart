class Wallet {
  final double balance;
  final double pendingBalance;
  final String currency;
  final bool isActive;
  final bool hasPin;

  Wallet({
    required this.balance,
    this.pendingBalance = 0,
    this.currency = 'TZS',
    this.isActive = true,
    this.hasPin = false,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: (json['balance'] ?? 0).toDouble(),
      pendingBalance: (json['pending_balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'TZS',
      isActive: json['is_active'] ?? true,
      hasPin: json['has_pin'] ?? false,
    );
  }

  String get balanceFormatted => '${currency} ${_formatAmount(balance)}';
  String get pendingFormatted => '${currency} ${_formatAmount(pendingBalance)}';

  static String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class WalletTransaction {
  final int id;
  final String transactionId;
  final int userId;
  final String type;
  final double amount;
  final double fee;
  final double balanceBefore;
  final double balanceAfter;
  final String status;
  final String? paymentMethod;
  final String? provider;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;

  WalletTransaction({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.type,
    required this.amount,
    this.fee = 0,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    this.paymentMethod,
    this.provider,
    this.description,
    required this.createdAt,
    this.completedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      transactionId: json['transaction_id'] ?? '',
      userId: json['user_id'],
      type: json['type'] ?? 'deposit',
      amount: (json['amount'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      balanceBefore: (json['balance_before'] ?? 0).toDouble(),
      balanceAfter: (json['balance_after'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      provider: json['provider'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }

  bool get isCredit => ['deposit', 'transfer_in', 'refund'].contains(type);
  bool get isDebit => ['withdrawal', 'transfer_out', 'payment'].contains(type);
  double get total => amount + fee;

  String get typeName {
    switch (type) {
      case 'deposit': return 'Uingizaji';
      case 'withdrawal': return 'Uondoaji';
      case 'transfer_in': return 'Upokeaji';
      case 'transfer_out': return 'Ulipaji';
      case 'payment': return 'Malipo';
      case 'refund': return 'Rudisho';
      default: return type;
    }
  }

  String get providerName {
    switch (provider) {
      case 'mpesa': return 'M-Pesa';
      case 'tigopesa': return 'Tigo Pesa';
      case 'airtelmoney': return 'Airtel Money';
      case 'halopesa': return 'Halo Pesa';
      default: return provider ?? '';
    }
  }
}

class MobileMoneyAccount {
  final int id;
  final int userId;
  final String provider;
  final String phoneNumber;
  final String accountName;
  final bool isVerified;
  final bool isPrimary;

  MobileMoneyAccount({
    required this.id,
    required this.userId,
    required this.provider,
    required this.phoneNumber,
    required this.accountName,
    this.isVerified = false,
    this.isPrimary = false,
  });

  factory MobileMoneyAccount.fromJson(Map<String, dynamic> json) {
    return MobileMoneyAccount(
      id: json['id'],
      userId: json['user_id'],
      provider: json['provider'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      accountName: json['account_name'] ?? '',
      isVerified: json['is_verified'] ?? false,
      isPrimary: json['is_primary'] ?? false,
    );
  }

  String get providerName {
    switch (provider) {
      case 'mpesa': return 'M-Pesa';
      case 'tigopesa': return 'Tigo Pesa';
      case 'airtelmoney': return 'Airtel Money';
      case 'halopesa': return 'Halo Pesa';
      default: return provider;
    }
  }

  String get maskedPhone {
    if (phoneNumber.length <= 6) return phoneNumber;
    return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(phoneNumber.length - 3)}';
  }
}

class PaymentRequest {
  final int id;
  final String requestId;
  final int requesterId;
  final int payerId;
  final double amount;
  final String? description;
  final String status;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final DateTime createdAt;
  final PaymentUser? requester;
  final PaymentUser? payer;

  PaymentRequest({
    required this.id,
    required this.requestId,
    required this.requesterId,
    required this.payerId,
    required this.amount,
    this.description,
    required this.status,
    this.expiresAt,
    this.paidAt,
    required this.createdAt,
    this.requester,
    this.payer,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'],
      requestId: json['request_id'] ?? '',
      requesterId: json['requester_id'],
      payerId: json['payer_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'],
      status: json['status'] ?? 'pending',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      requester: json['requester'] != null ? PaymentUser.fromJson(json['requester']) : null,
      payer: json['payer'] != null ? PaymentUser.fromJson(json['payer']) : null,
    );
  }

  bool get isPending => status == 'pending' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
}

class PaymentUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePhotoPath;

  PaymentUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhotoPath,
  });

  factory PaymentUser.fromJson(Map<String, dynamic> json) {
    return PaymentUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName';
}
