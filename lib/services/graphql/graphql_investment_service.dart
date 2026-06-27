import '../../investments/models/investment_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL investments module (Phase 61).
class GraphqlInvestmentService {
  static const _portfolioFields = r'''
    totalValue
    totalInvested
    totalReturns
    returnPercent
    currency
    allocations {
      category
      value
      percent
    }
  ''';

  static const _bondProductFields = r'''
    id
    name
    type
    tenorDays
    couponRate
    minInvestment
    nextAuction
    description
  ''';

  static const _bondHoldingFields = r'''
    id
    bondProductId
    bondName
    faceValue
    purchasePrice
    couponRate
    purchaseDate
    maturityDate
    accruedInterest
    status
  ''';

  static const _unitTrustFundFields = r'''
    id
    name
    provider
    fundType
    navPerUnit
    minInitialInvestment
    minSubsequentInvestment
    returnRate1y
    riskLevel
    description
    objective
  ''';

  static const _unitTrustHoldingFields = r'''
    id
    fundId
    fundName
    provider
    units
    navPerUnit
    totalInvested
    currentValue
    returns
  ''';

  static const _stockFields = r'''
    id
    symbol
    name
    sector
    lastPrice
    change
    changePercent
    dayHigh
    dayLow
    volume
    marketCap
  ''';

  static const _stockHoldingFields = r'''
    id
    stockId
    symbol
    name
    shares
    avgPrice
    currentPrice
    totalInvested
    currentValue
    returns
  ''';

  static const _realEstateFields = r'''
    id
    name
    type
    location
    targetAmount
    raisedAmount
    minInvestment
    expectedReturn
    durationMonths
    status
    imageUrl
    description
  ''';

  static const _agricultureFields = r'''
    id
    name
    crop
    location
    targetAmount
    raisedAmount
    minInvestment
    expectedReturn
    durationMonths
    season
    status
    imageUrl
    description
  ''';

  static const _savingsFields = r'''
    id
    name
    provider
    type
    interestRate
    termDays
    minAmount
    description
  ''';

  static Map<String, dynamic> _portfolioToLegacy(Map<String, dynamic> row) {
    final allocations = row['allocations'] as List<dynamic>? ?? [];
    return {
      'total_value': row['totalValue'],
      'total_invested': row['totalInvested'],
      'total_returns': row['totalReturns'],
      'return_percent': row['returnPercent'],
      'currency': row['currency'],
      'allocations': allocations.map((item) {
        final a = item as Map<String, dynamic>;
        return {
          'category': a['category'],
          'value': a['value'],
          'percent': a['percent'],
        };
      }).toList(),
    };
  }

  static Map<String, dynamic> _bondProductToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'type': row['type'],
      'tenor_days': row['tenorDays'],
      'coupon_rate': row['couponRate'],
      'min_investment': row['minInvestment'],
      'next_auction': row['nextAuction'],
      'description': row['description'],
    };
  }

  static Map<String, dynamic> _bondHoldingToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'bond_product_id': int.parse(row['bondProductId'].toString()),
      'bond_name': row['bondName'],
      'face_value': row['faceValue'],
      'purchase_price': row['purchasePrice'],
      'coupon_rate': row['couponRate'],
      'purchase_date': row['purchaseDate'],
      'maturity_date': row['maturityDate'],
      'accrued_interest': row['accruedInterest'],
      'status': row['status'],
    };
  }

  static Map<String, dynamic> _unitTrustFundToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'provider': row['provider'],
      'fund_type': row['fundType'],
      'nav_per_unit': row['navPerUnit'],
      'min_initial_investment': row['minInitialInvestment'],
      'min_subsequent_investment': row['minSubsequentInvestment'],
      'return_rate_1y': row['returnRate1y'],
      'risk_level': row['riskLevel'],
      'description': row['description'],
      'objective': row['objective'],
    };
  }

  static Map<String, dynamic> _unitTrustHoldingToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'fund_id': int.parse(row['fundId'].toString()),
      'fund_name': row['fundName'],
      'provider': row['provider'],
      'units': row['units'],
      'nav_per_unit': row['navPerUnit'],
      'total_invested': row['totalInvested'],
      'current_value': row['currentValue'],
      'returns': row['returns'],
    };
  }

  static Map<String, dynamic> _stockToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'symbol': row['symbol'],
      'name': row['name'],
      'sector': row['sector'],
      'last_price': row['lastPrice'],
      'change': row['change'],
      'change_percent': row['changePercent'],
      'day_high': row['dayHigh'],
      'day_low': row['dayLow'],
      'volume': row['volume'],
      'market_cap': row['marketCap'],
    };
  }

  static Map<String, dynamic> _stockHoldingToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'stock_id': int.parse(row['stockId'].toString()),
      'symbol': row['symbol'],
      'name': row['name'],
      'shares': row['shares'],
      'avg_price': row['avgPrice'],
      'current_price': row['currentPrice'],
      'total_invested': row['totalInvested'],
      'current_value': row['currentValue'],
      'returns': row['returns'],
    };
  }

  static Map<String, dynamic> _realEstateToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'type': row['type'],
      'location': row['location'],
      'target_amount': row['targetAmount'],
      'raised_amount': row['raisedAmount'],
      'min_investment': row['minInvestment'],
      'expected_return': row['expectedReturn'],
      'duration_months': row['durationMonths'],
      'status': row['status'],
      'image_url': row['imageUrl'],
      'description': row['description'],
    };
  }

  static Map<String, dynamic> _agricultureToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'crop': row['crop'],
      'location': row['location'],
      'target_amount': row['targetAmount'],
      'raised_amount': row['raisedAmount'],
      'min_investment': row['minInvestment'],
      'expected_return': row['expectedReturn'],
      'duration_months': row['durationMonths'],
      'season': row['season'],
      'status': row['status'],
      'image_url': row['imageUrl'],
      'description': row['description'],
    };
  }

  static Map<String, dynamic> _savingsToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'provider': row['provider'],
      'type': row['type'],
      'interest_rate': row['interestRate'],
      'term_days': row['termDays'],
      'min_amount': row['minAmount'],
      'description': row['description'],
    };
  }

  static Future<InvestmentResult<PortfolioSummary>> getPortfolio() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyInvestmentPortfolio {
          myInvestmentPortfolio {
            $_portfolioFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['myInvestmentPortfolio'] as Map<String, dynamic>;
      return InvestmentResult(
        success: true,
        data: PortfolioSummary.fromJson(_portfolioToLegacy(row)),
      );
    } catch (e) {
      return InvestmentResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<BondProduct>> getBondProducts() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BondProducts {
          bondProducts {
            $_bondProductFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['bondProducts'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) => BondProduct.fromJson(
                _bondProductToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<BondHolding>> getMyBonds() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBondHoldings {
          myBondHoldings {
            $_bondHoldingFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myBondHoldings'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) => BondHolding.fromJson(
                _bondHoldingToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentResult<BondHolding>> investInBond({
    required int bondProductId,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation InvestInBond(\$input: InvestInBondInput!) {
          investInBond(input: \$input) {
            $_bondHoldingFields
          }
        }
        ''',
        variables: {
          'input': {
            'bondProductId': bondProductId.toString(),
            'amount': amount,
            'paymentMethod': paymentMethod,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
          },
        },
        auth: true,
      );
      final row = data['investInBond'] as Map<String, dynamic>;
      return InvestmentResult(
        success: true,
        data: BondHolding.fromJson(_bondHoldingToLegacy(row)),
      );
    } catch (e) {
      return InvestmentResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<UnitTrustFund>> getUnitTrustFunds() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query UnitTrustFunds {
          unitTrustFunds {
            $_unitTrustFundFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['unitTrustFunds'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) => UnitTrustFund.fromJson(
                _unitTrustFundToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<UnitTrustHolding>> getMyUnitTrusts() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyUnitTrustHoldings {
          myUnitTrustHoldings {
            $_unitTrustHoldingFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myUnitTrustHoldings'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) => UnitTrustHolding.fromJson(
                _unitTrustHoldingToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentResult<UnitTrustHolding>> investInUnitTrust({
    required int fundId,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation InvestInUnitTrust(\$input: InvestInUnitTrustInput!) {
          investInUnitTrust(input: \$input) {
            $_unitTrustHoldingFields
          }
        }
        ''',
        variables: {
          'input': {
            'fundId': fundId.toString(),
            'amount': amount,
            'paymentMethod': paymentMethod,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
          },
        },
        auth: true,
      );
      final row = data['investInUnitTrust'] as Map<String, dynamic>;
      return InvestmentResult(
        success: true,
        data: UnitTrustHolding.fromJson(_unitTrustHoldingToLegacy(row)),
      );
    } catch (e) {
      return InvestmentResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<Stock>> getStocks({String? sector}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query DseStocks(\$sector: String) {
          dseStocks(sector: \$sector) {
            $_stockFields
          }
        }
        ''',
        variables: {if (sector != null) 'sector': sector},
        auth: false,
      );
      final rows = data['dseStocks'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) =>
                Stock.fromJson(_stockToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<StockHolding>> getMyStocks() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyStockHoldings {
          myStockHoldings {
            $_stockHoldingFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myStockHoldings'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) => StockHolding.fromJson(
                _stockHoldingToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentResult<StockHolding>> buyStock({
    required int stockId,
    required int shares,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation BuyStock(\$input: BuyStockInput!) {
          buyStock(input: \$input) {
            $_stockHoldingFields
          }
        }
        ''',
        variables: {
          'input': {
            'stockId': stockId.toString(),
            'shares': shares,
            'paymentMethod': paymentMethod,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
          },
        },
        auth: true,
      );
      final row = data['buyStock'] as Map<String, dynamic>;
      return InvestmentResult(
        success: true,
        data: StockHolding.fromJson(_stockHoldingToLegacy(row)),
      );
    } catch (e) {
      return InvestmentResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<RealEstateProject>> getRealEstateProjects() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query RealEstateProjects {
          realEstateProjects {
            $_realEstateFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['realEstateProjects'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) => RealEstateProject.fromJson(
                _realEstateToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<AgricultureProject>> getAgricultureProjects() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query AgricultureProjects {
          agricultureProjects {
            $_agricultureFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['agricultureProjects'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) => AgricultureProject.fromJson(
                _agricultureToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InvestmentListResult<SavingsProduct>> getSavingsProducts() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query SavingsProducts {
          savingsProducts {
            $_savingsFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['savingsProducts'] as List<dynamic>? ?? [];
      return InvestmentListResult(
        success: true,
        items: rows
            .map((row) => SavingsProduct.fromJson(
                _savingsToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }
}
