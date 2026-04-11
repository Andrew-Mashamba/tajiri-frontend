// lib/investments/models/investment_models.dart

/// Asset categories available for investment
enum AssetCategory {
  bonds,
  unitTrusts,
  stocks,
  realEstate,
  agriculture,
  savings;

  String get displayName {
    switch (this) {
      case AssetCategory.bonds: return 'Bondi';
      case AssetCategory.unitTrusts: return 'Mifuko';
      case AssetCategory.stocks: return 'Hisa';
      case AssetCategory.realEstate: return 'Nyumba';
      case AssetCategory.agriculture: return 'Kilimo';
      case AssetCategory.savings: return 'Akiba';
    }
  }

  String get subtitle {
    switch (this) {
      case AssetCategory.bonds: return 'Govt Bonds';
      case AssetCategory.unitTrusts: return 'Unit Trusts';
      case AssetCategory.stocks: return 'DSE Stocks';
      case AssetCategory.realEstate: return 'Real Estate';
      case AssetCategory.agriculture: return 'Agriculture';
      case AssetCategory.savings: return 'Savings';
    }
  }
}

/// Portfolio summary across all asset categories
class PortfolioSummary {
  final double totalValue;
  final double totalInvested;
  final double totalReturns;
  final double returnPercent;
  final String currency;
  final List<AssetAllocation> allocations;

  PortfolioSummary({
    required this.totalValue,
    required this.totalInvested,
    required this.totalReturns,
    required this.returnPercent,
    this.currency = 'TZS',
    this.allocations = const [],
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
      totalInvested: (json['total_invested'] as num?)?.toDouble() ?? 0,
      totalReturns: (json['total_returns'] as num?)?.toDouble() ?? 0,
      returnPercent: (json['return_percent'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'TZS',
      allocations: (json['allocations'] as List?)
              ?.map((a) => AssetAllocation.fromJson(a))
              .toList() ??
          [],
    );
  }

  factory PortfolioSummary.empty() => PortfolioSummary(
        totalValue: 0,
        totalInvested: 0,
        totalReturns: 0,
        returnPercent: 0,
      );
}

class AssetAllocation {
  final String category;
  final double value;
  final double percent;

  AssetAllocation({
    required this.category,
    required this.value,
    required this.percent,
  });

  factory AssetAllocation.fromJson(Map<String, dynamic> json) {
    return AssetAllocation(
      category: json['category'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Government Bonds ───────────────────────────────────────────

class BondProduct {
  final int id;
  final String name;
  final String type; // treasury_bill, treasury_bond
  final int tenorDays;
  final double couponRate;
  final double minInvestment;
  final DateTime? nextAuction;
  final String? description;

  BondProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.tenorDays,
    required this.couponRate,
    required this.minInvestment,
    this.nextAuction,
    this.description,
  });

  factory BondProduct.fromJson(Map<String, dynamic> json) {
    return BondProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'treasury_bond',
      tenorDays: json['tenor_days'] ?? 0,
      couponRate: (json['coupon_rate'] as num?)?.toDouble() ?? 0,
      minInvestment: (json['min_investment'] as num?)?.toDouble() ?? 10000,
      nextAuction: json['next_auction'] != null
          ? DateTime.tryParse(json['next_auction'])
          : null,
      description: json['description'],
    );
  }

  bool get isTreasuryBill => type == 'treasury_bill';
  String get tenorLabel {
    if (tenorDays <= 364) return '$tenorDays siku';
    final years = tenorDays ~/ 365;
    return '$years mwaka${years > 1 ? '' : ''}';
  }
}

class BondHolding {
  final int id;
  final int bondProductId;
  final String bondName;
  final double faceValue;
  final double purchasePrice;
  final double couponRate;
  final DateTime purchaseDate;
  final DateTime maturityDate;
  final double accruedInterest;
  final String status; // active, matured, sold

  BondHolding({
    required this.id,
    required this.bondProductId,
    required this.bondName,
    required this.faceValue,
    required this.purchasePrice,
    required this.couponRate,
    required this.purchaseDate,
    required this.maturityDate,
    this.accruedInterest = 0,
    this.status = 'active',
  });

  factory BondHolding.fromJson(Map<String, dynamic> json) {
    return BondHolding(
      id: json['id'] ?? 0,
      bondProductId: json['bond_product_id'] ?? 0,
      bondName: json['bond_name'] ?? '',
      faceValue: (json['face_value'] as num?)?.toDouble() ?? 0,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0,
      couponRate: (json['coupon_rate'] as num?)?.toDouble() ?? 0,
      purchaseDate: DateTime.parse(json['purchase_date']),
      maturityDate: DateTime.parse(json['maturity_date']),
      accruedInterest: (json['accrued_interest'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'active',
    );
  }

  bool get isActive => status == 'active';
  double get currentValue => faceValue + accruedInterest;
  int get daysToMaturity => maturityDate.difference(DateTime.now()).inDays;
}

// ─── Unit Trusts ────────────────────────────────────────────────

class UnitTrustFund {
  final int id;
  final String name;
  final String provider; // e.g. UTT AMIS
  final String fundType; // equity, bond, money_market, balanced
  final double navPerUnit; // Net Asset Value per unit
  final double minInitialInvestment;
  final double minSubsequentInvestment;
  final double returnRate1Year;
  final String riskLevel; // low, medium, high
  final String? description;
  final String? objective;

  UnitTrustFund({
    required this.id,
    required this.name,
    required this.provider,
    required this.fundType,
    required this.navPerUnit,
    required this.minInitialInvestment,
    required this.minSubsequentInvestment,
    required this.returnRate1Year,
    required this.riskLevel,
    this.description,
    this.objective,
  });

  factory UnitTrustFund.fromJson(Map<String, dynamic> json) {
    return UnitTrustFund(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      provider: json['provider'] ?? '',
      fundType: json['fund_type'] ?? 'balanced',
      navPerUnit: (json['nav_per_unit'] as num?)?.toDouble() ?? 0,
      minInitialInvestment: (json['min_initial_investment'] as num?)?.toDouble() ?? 10000,
      minSubsequentInvestment: (json['min_subsequent_investment'] as num?)?.toDouble() ?? 5000,
      returnRate1Year: (json['return_rate_1y'] as num?)?.toDouble() ?? 0,
      riskLevel: json['risk_level'] ?? 'medium',
      description: json['description'],
      objective: json['objective'],
    );
  }

  String get fundTypeName {
    switch (fundType) {
      case 'equity': return 'Hisa';
      case 'bond': return 'Bondi';
      case 'money_market': return 'Soko la Pesa';
      case 'balanced': return 'Mseto';
      default: return fundType;
    }
  }

  String get riskLabel {
    switch (riskLevel) {
      case 'low': return 'Hatari Ndogo';
      case 'medium': return 'Hatari Wastani';
      case 'high': return 'Hatari Kubwa';
      default: return riskLevel;
    }
  }
}

class UnitTrustHolding {
  final int id;
  final int fundId;
  final String fundName;
  final String provider;
  final double units;
  final double navPerUnit;
  final double totalInvested;
  final double currentValue;
  final double returns;

  UnitTrustHolding({
    required this.id,
    required this.fundId,
    required this.fundName,
    required this.provider,
    required this.units,
    required this.navPerUnit,
    required this.totalInvested,
    required this.currentValue,
    required this.returns,
  });

  factory UnitTrustHolding.fromJson(Map<String, dynamic> json) {
    return UnitTrustHolding(
      id: json['id'] ?? 0,
      fundId: json['fund_id'] ?? 0,
      fundName: json['fund_name'] ?? '',
      provider: json['provider'] ?? '',
      units: (json['units'] as num?)?.toDouble() ?? 0,
      navPerUnit: (json['nav_per_unit'] as num?)?.toDouble() ?? 0,
      totalInvested: (json['total_invested'] as num?)?.toDouble() ?? 0,
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
      returns: (json['returns'] as num?)?.toDouble() ?? 0,
    );
  }

  double get returnPercent => totalInvested > 0 ? (returns / totalInvested) * 100 : 0;
}

// ─── DSE Stocks ─────────────────────────────────────────────────

class Stock {
  final int id;
  final String symbol;
  final String name;
  final String sector;
  final double lastPrice;
  final double change;
  final double changePercent;
  final double dayHigh;
  final double dayLow;
  final int volume;
  final double marketCap;

  Stock({
    required this.id,
    required this.symbol,
    required this.name,
    required this.sector,
    required this.lastPrice,
    required this.change,
    required this.changePercent,
    this.dayHigh = 0,
    this.dayLow = 0,
    this.volume = 0,
    this.marketCap = 0,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'] ?? 0,
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      sector: json['sector'] ?? '',
      lastPrice: (json['last_price'] as num?)?.toDouble() ?? 0,
      change: (json['change'] as num?)?.toDouble() ?? 0,
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0,
      dayHigh: (json['day_high'] as num?)?.toDouble() ?? 0,
      dayLow: (json['day_low'] as num?)?.toDouble() ?? 0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
      marketCap: (json['market_cap'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isUp => change > 0;
  bool get isDown => change < 0;
}

class StockHolding {
  final int id;
  final int stockId;
  final String symbol;
  final String name;
  final int shares;
  final double avgPrice;
  final double currentPrice;
  final double totalInvested;
  final double currentValue;
  final double returns;

  StockHolding({
    required this.id,
    required this.stockId,
    required this.symbol,
    required this.name,
    required this.shares,
    required this.avgPrice,
    required this.currentPrice,
    required this.totalInvested,
    required this.currentValue,
    required this.returns,
  });

  factory StockHolding.fromJson(Map<String, dynamic> json) {
    return StockHolding(
      id: json['id'] ?? 0,
      stockId: json['stock_id'] ?? 0,
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      avgPrice: (json['avg_price'] as num?)?.toDouble() ?? 0,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      totalInvested: (json['total_invested'] as num?)?.toDouble() ?? 0,
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
      returns: (json['returns'] as num?)?.toDouble() ?? 0,
    );
  }

  double get returnPercent => totalInvested > 0 ? (returns / totalInvested) * 100 : 0;
}

// ─── Real Estate ────────────────────────────────────────────────

class RealEstateProject {
  final int id;
  final String name;
  final String type; // reit, crowdfunded, direct
  final String location;
  final double targetAmount;
  final double raisedAmount;
  final double minInvestment;
  final double expectedReturn;
  final int durationMonths;
  final String status; // open, funded, closed
  final String? imageUrl;
  final String? description;

  RealEstateProject({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.targetAmount,
    required this.raisedAmount,
    required this.minInvestment,
    required this.expectedReturn,
    required this.durationMonths,
    required this.status,
    this.imageUrl,
    this.description,
  });

  factory RealEstateProject.fromJson(Map<String, dynamic> json) {
    return RealEstateProject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'crowdfunded',
      location: json['location'] ?? '',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0,
      raisedAmount: (json['raised_amount'] as num?)?.toDouble() ?? 0,
      minInvestment: (json['min_investment'] as num?)?.toDouble() ?? 0,
      expectedReturn: (json['expected_return'] as num?)?.toDouble() ?? 0,
      durationMonths: (json['duration_months'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'open',
      imageUrl: json['image_url'],
      description: json['description'],
    );
  }

  double get fundedPercent =>
      targetAmount > 0 ? (raisedAmount / targetAmount) * 100 : 0;
  bool get isOpen => status == 'open';

  String get typeName {
    switch (type) {
      case 'reit': return 'REIT';
      case 'crowdfunded': return 'Uwekezaji wa Pamoja';
      case 'direct': return 'Moja kwa Moja';
      default: return type;
    }
  }
}

// ─── Agriculture ────────────────────────────────────────────────

class AgricultureProject {
  final int id;
  final String name;
  final String crop;
  final String location;
  final double targetAmount;
  final double raisedAmount;
  final double minInvestment;
  final double expectedReturn;
  final int durationMonths;
  final String season; // e.g. 2025/2026
  final String status; // open, funded, growing, harvested, closed
  final String? imageUrl;
  final String? description;

  AgricultureProject({
    required this.id,
    required this.name,
    required this.crop,
    required this.location,
    required this.targetAmount,
    required this.raisedAmount,
    required this.minInvestment,
    required this.expectedReturn,
    required this.durationMonths,
    required this.season,
    required this.status,
    this.imageUrl,
    this.description,
  });

  factory AgricultureProject.fromJson(Map<String, dynamic> json) {
    return AgricultureProject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      crop: json['crop'] ?? '',
      location: json['location'] ?? '',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0,
      raisedAmount: (json['raised_amount'] as num?)?.toDouble() ?? 0,
      minInvestment: (json['min_investment'] as num?)?.toDouble() ?? 0,
      expectedReturn: (json['expected_return'] as num?)?.toDouble() ?? 0,
      durationMonths: (json['duration_months'] as num?)?.toInt() ?? 0,
      season: json['season'] ?? '',
      status: json['status'] ?? 'open',
      imageUrl: json['image_url'],
      description: json['description'],
    );
  }

  double get fundedPercent =>
      targetAmount > 0 ? (raisedAmount / targetAmount) * 100 : 0;
  bool get isOpen => status == 'open';
}

// ─── Savings Products ───────────────────────────────────────────

class SavingsProduct {
  final int id;
  final String name;
  final String provider;
  final String type; // fixed_deposit, savings_bond
  final double interestRate;
  final int termDays;
  final double minAmount;
  final String? description;

  SavingsProduct({
    required this.id,
    required this.name,
    required this.provider,
    required this.type,
    required this.interestRate,
    required this.termDays,
    required this.minAmount,
    this.description,
  });

  factory SavingsProduct.fromJson(Map<String, dynamic> json) {
    return SavingsProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      provider: json['provider'] ?? '',
      type: json['type'] ?? 'fixed_deposit',
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0,
      termDays: (json['term_days'] as num?)?.toInt() ?? 0,
      minAmount: (json['min_amount'] as num?)?.toDouble() ?? 0,
      description: json['description'],
    );
  }

  String get termLabel {
    if (termDays < 30) return '$termDays siku';
    if (termDays < 365) return '${termDays ~/ 30} miezi';
    return '${termDays ~/ 365} mwaka';
  }
}

// ─── Result wrappers ────────────────────────────────────────────

class InvestmentResult<T> {
  final bool success;
  final T? data;
  final String? message;

  InvestmentResult({required this.success, this.data, this.message});
}

class InvestmentListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  InvestmentListResult({
    required this.success,
    this.items = const [],
    this.message,
  });
}
