// lib/investments/services/investment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/investment_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class InvestmentService {
  // ─── Portfolio ──────────────────────────────────────────────────

  Future<InvestmentResult<PortfolioSummary>> getPortfolio(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/portfolio?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return InvestmentResult(
            success: true,
            data: PortfolioSummary.fromJson(data['data']),
          );
        }
      }
      return InvestmentResult(success: false, message: 'Imeshindwa kupakia kundi la uwekezaji');
    } catch (e) {
      return InvestmentResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Government Bonds ──────────────────────────────────────────

  Future<InvestmentListResult<BondProduct>> getBondProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/bonds/products'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => BondProduct.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia bondi');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InvestmentListResult<BondHolding>> getMyBonds(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/bonds/holdings?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => BondHolding.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia bondi zako');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InvestmentResult<BondHolding>> investInBond({
    required int userId,
    required int bondProductId,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/investments/bonds/invest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'bond_product_id': bondProductId,
          'amount': amount,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return InvestmentResult(
          success: true,
          data: BondHolding.fromJson(data['data']),
        );
      }
      return InvestmentResult(success: false, message: data['message'] ?? 'Imeshindwa kuwekeza');
    } catch (e) {
      return InvestmentResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Unit Trusts ───────────────────────────────────────────────

  Future<InvestmentListResult<UnitTrustFund>> getUnitTrustFunds() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/unit-trusts/funds'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => UnitTrustFund.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia mifuko');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InvestmentListResult<UnitTrustHolding>> getMyUnitTrusts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/unit-trusts/holdings?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => UnitTrustHolding.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia mifuko yako');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InvestmentResult<UnitTrustHolding>> investInUnitTrust({
    required int userId,
    required int fundId,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/investments/unit-trusts/invest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'fund_id': fundId,
          'amount': amount,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return InvestmentResult(
          success: true,
          data: UnitTrustHolding.fromJson(data['data']),
        );
      }
      return InvestmentResult(success: false, message: data['message'] ?? 'Imeshindwa kuwekeza');
    } catch (e) {
      return InvestmentResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── DSE Stocks ────────────────────────────────────────────────

  Future<InvestmentListResult<Stock>> getStocks({String? sector}) async {
    try {
      String url = '$_baseUrl/investments/stocks';
      if (sector != null) url += '?sector=$sector';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Stock.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia hisa');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InvestmentListResult<StockHolding>> getMyStocks(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/stocks/holdings?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => StockHolding.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia hisa zako');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<InvestmentResult<StockHolding>> buyStock({
    required int userId,
    required int stockId,
    required int shares,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/investments/stocks/buy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'stock_id': stockId,
          'shares': shares,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return InvestmentResult(
          success: true,
          data: StockHolding.fromJson(data['data']),
        );
      }
      return InvestmentResult(success: false, message: data['message'] ?? 'Imeshindwa kununua');
    } catch (e) {
      return InvestmentResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Real Estate ───────────────────────────────────────────────

  Future<InvestmentListResult<RealEstateProject>> getRealEstateProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/real-estate/projects'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => RealEstateProject.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia miradi');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Agriculture ───────────────────────────────────────────────

  Future<InvestmentListResult<AgricultureProject>> getAgricultureProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/agriculture/projects'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => AgricultureProject.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia miradi ya kilimo');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Savings Products ──────────────────────────────────────────

  Future<InvestmentListResult<SavingsProduct>> getSavingsProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/investments/savings/products'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => SavingsProduct.fromJson(j))
              .toList();
          return InvestmentListResult(success: true, items: items);
        }
      }
      return InvestmentListResult(success: false, message: 'Imeshindwa kupakia akiba');
    } catch (e) {
      return InvestmentListResult(success: false, message: 'Kosa: $e');
    }
  }
}
