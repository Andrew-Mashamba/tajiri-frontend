// lib/zaka/models/zaka_models.dart

// ─── Asset Category ───────────────────────────────────────────
enum AssetCategory {
  cash,
  gold,
  silver,
  business,
  investments,
  livestock,
  agriculture,
  rental;

  String get label {
    switch (this) {
      case AssetCategory.cash: return 'Fedha Taslimu';
      case AssetCategory.gold: return 'Dhahabu';
      case AssetCategory.silver: return 'Fedha (Silver)';
      case AssetCategory.business: return 'Biashara';
      case AssetCategory.investments: return 'Uwekezaji';
      case AssetCategory.livestock: return 'Mifugo';
      case AssetCategory.agriculture: return 'Mazao';
      case AssetCategory.rental: return 'Mapato ya Kodi';
    }
  }

  String get labelEn {
    switch (this) {
      case AssetCategory.cash: return 'Cash/Bank';
      case AssetCategory.gold: return 'Gold';
      case AssetCategory.silver: return 'Silver';
      case AssetCategory.business: return 'Business';
      case AssetCategory.investments: return 'Investments';
      case AssetCategory.livestock: return 'Livestock';
      case AssetCategory.agriculture: return 'Agriculture';
      case AssetCategory.rental: return 'Rental Income';
    }
  }
}

// ─── Asset Entry ──────────────────────────────────────────────
class AssetEntry {
  final AssetCategory category;
  final double amount;
  final String? description;

  AssetEntry({
    required this.category,
    required this.amount,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'amount': amount,
        if (description != null) 'description': description,
      };

  factory AssetEntry.fromJson(Map<String, dynamic> json) {
    return AssetEntry(
      category: _parseCategory(json['category']),
      amount: _parseDouble(json['amount']),
      description: json['description']?.toString(),
    );
  }
}

// ─── Zakat Calculation Result ─────────────────────────────────
class ZakatCalculation {
  final double totalAssets;
  final double totalDebts;
  final double netWealth;
  final double nisabThreshold;
  final double nisabGold;
  final double nisabSilver;
  final bool aboveNisab;
  final double zakatDue;
  final String currency;
  final List<AssetEntry> assets;

  ZakatCalculation({
    required this.totalAssets,
    required this.totalDebts,
    required this.netWealth,
    required this.nisabThreshold,
    this.nisabGold = 0,
    this.nisabSilver = 0,
    required this.aboveNisab,
    required this.zakatDue,
    this.currency = 'TZS',
    this.assets = const [],
  });

  factory ZakatCalculation.fromJson(Map<String, dynamic> json) {
    return ZakatCalculation(
      totalAssets: _parseDouble(json['total_assets']),
      totalDebts: _parseDouble(json['total_debts']),
      netWealth: _parseDouble(json['net_wealth']),
      nisabThreshold: _parseDouble(json['nisab_threshold']),
      nisabGold: _parseDouble(json['nisab_gold']),
      nisabSilver: _parseDouble(json['nisab_silver']),
      aboveNisab: _parseBool(json['above_nisab']),
      zakatDue: _parseDouble(json['zakat_due']),
      currency: json['currency']?.toString() ?? 'TZS',
      assets: (json['assets'] as List?)
              ?.map((j) => AssetEntry.fromJson(j))
              .toList() ??
          [],
    );
  }
}

// ─── Payment Record ───────────────────────────────────────────
class ZakatPayment {
  final int id;
  final double amount;
  final String recipientName;
  final String recipientType;
  final String paymentMethod;
  final String status;
  final DateTime paidAt;

  ZakatPayment({
    required this.id,
    required this.amount,
    required this.recipientName,
    required this.recipientType,
    required this.paymentMethod,
    required this.status,
    required this.paidAt,
  });

  factory ZakatPayment.fromJson(Map<String, dynamic> json) {
    return ZakatPayment(
      id: _parseInt(json['id']),
      amount: _parseDouble(json['amount']),
      recipientName: json['recipient_name']?.toString() ?? '',
      recipientType: json['recipient_type']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'M-Pesa',
      status: json['status']?.toString() ?? 'pending',
      paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── Nisab Info ───────────────────────────────────────────────
class NisabInfo {
  final double goldPricePerGram;
  final double silverPricePerGram;
  final double nisabGold; // 85g gold value
  final double nisabSilver; // 595g silver value
  final String currency;
  final DateTime updatedAt;

  NisabInfo({
    required this.goldPricePerGram,
    required this.silverPricePerGram,
    required this.nisabGold,
    required this.nisabSilver,
    this.currency = 'TZS',
    required this.updatedAt,
  });

  factory NisabInfo.fromJson(Map<String, dynamic> json) {
    return NisabInfo(
      goldPricePerGram: _parseDouble(json['gold_price_per_gram']),
      silverPricePerGram: _parseDouble(json['silver_price_per_gram']),
      nisabGold: _parseDouble(json['nisab_gold']),
      nisabSilver: _parseDouble(json['nisab_silver']),
      currency: json['currency']?.toString() ?? 'TZS',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── Result Wrappers ──────────────────────────────────────────
class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? message;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message,
  });
}

// ─── Parse Helpers ────────────────────────────────────────────
int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

AssetCategory _parseCategory(dynamic v) {
  final s = v?.toString().toLowerCase() ?? '';
  for (final c in AssetCategory.values) {
    if (c.name == s) return c;
  }
  return AssetCategory.cash;
}
