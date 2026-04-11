// lib/business/services/business_service.dart
// API service for the Biashara Yangu (My Business) module.
// Pattern: static methods, auth token as parameter.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api_config.dart';
import '../models/business_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String msg) => debugPrint('[BusinessService] $msg');

class BusinessService {
  // ==========================================================================
  // Business CRUD
  // ==========================================================================

  /// Get all businesses for a user.
  static Future<BusinessListResult<Business>> getMyBusinesses(
      String token, int userId) async {
    try {
      final url = '$_baseUrl/business?user_id=$userId';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Business.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list, total: list.length);
      }
      return BusinessListResult(
          success: false,
          message: 'Failed to load businesses: ${res.statusCode}');
    } catch (e) {
      _log('Error getMyBusinesses: $e');
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  /// Create a new business.
  static Future<BusinessResult<Business>> createBusiness(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Business.fromJson(data['data'] ?? data),
            message: 'Business created');
      }
      return BusinessResult(
          success: false,
          message: 'Failed to create business: ${res.statusCode}');
    } catch (e) {
      _log('Error createBusiness: $e');
      return BusinessResult(success: false, message: e.toString());
    }
  }

  /// Update an existing business.
  static Future<BusinessResult<Business>> updateBusiness(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId';
      _log('PUT $url');
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Business.fromJson(data['data'] ?? data),
            message: 'Biashara imesasishwa');
      }
      return BusinessResult(
          success: false,
          message: 'Failed to update: ${res.statusCode}');
    } catch (e) {
      _log('Error updateBusiness: $e');
      return BusinessResult(success: false, message: e.toString());
    }
  }

  /// Switch active business context.
  static Future<BusinessResult<void>> switchBusiness(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/switch';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(success: res.statusCode == 200);
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Documents
  // ==========================================================================

  static Future<BusinessListResult<BusinessDocument>> getDocuments(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/documents';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => BusinessDocument.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<BusinessDocument>> uploadDocument(
      String token, int businessId, String typeName, File file) async {
    try {
      final url = '$_baseUrl/business/$businessId/documents';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(ApiConfig.authHeaders(token));
      request.fields['type'] = typeName;
      request.fields['name'] = typeName;
      final ext = file.path.split('.').last.toLowerCase();
      String mimeType = 'application/octet-stream';
      if (ext == 'pdf') mimeType = 'application/pdf';
      if (ext == 'jpg' || ext == 'jpeg') mimeType = 'image/jpeg';
      if (ext == 'png') mimeType = 'image/png';
      request.files.add(await http.MultipartFile.fromPath('file', file.path,
          contentType: MediaType.parse(mimeType)));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: BusinessDocument.fromJson(data['data'] ?? data),
            message: 'Hati imepakiwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> deleteDocument(
      String token, int documentId) async {
    try {
      final url = '$_baseUrl/business/documents/$documentId';
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Hati imefutwa');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Customers
  // ==========================================================================

  static Future<BusinessListResult<Customer>> getCustomers(
      String token, int businessId, {String? search}) async {
    try {
      var url = '$_baseUrl/business/$businessId/customers';
      if (search != null && search.isNotEmpty) url += '?search=$search';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Customer.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Customer>> addCustomer(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/customers';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Customer.fromJson(data['data'] ?? data),
            message: 'Mteja ameongezwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Customer>> updateCustomer(
      String token, int customerId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/customers/$customerId';
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true, data: Customer.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> deleteCustomer(
      String token, int customerId) async {
    try {
      final url = '$_baseUrl/business/customers/$customerId';
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(success: res.statusCode == 200);
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Debts (Deni)
  // ==========================================================================

  static Future<BusinessListResult<Debt>> getDebts(
      String token, int businessId, {String? status}) async {
    try {
      var url = '$_baseUrl/business/$businessId/debts';
      if (status != null && status.isNotEmpty) url += '?status=$status';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Debt.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Debt>> createDebt(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/debts';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Debt.fromJson(data['data'] ?? data),
            message: 'Deni limeongezwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Debt>> recordDebtPayment(
      String token, int debtId, double amount) async {
    try {
      final url = '$_baseUrl/business/debts/$debtId/pay';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'amount': amount}));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Debt.fromJson(data['data'] ?? data),
            message: 'Malipo yamerekodwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<DebtSummary>> getDebtSummary(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/debts/summary';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: DebtSummary.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Invoices
  // ==========================================================================

  static Future<BusinessListResult<Invoice>> getInvoices(
      String token, int businessId, {String? status}) async {
    try {
      var url = '$_baseUrl/business/$businessId/invoices';
      if (status != null && status.isNotEmpty) url += '?status=$status';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Invoice>> createInvoice(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/invoices';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Invoice.fromJson(data['data'] ?? data),
            message: 'Invoice created');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> sendInvoice(
      String token, int invoiceId) async {
    try {
      final url = '$_baseUrl/business/invoices/$invoiceId/send';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Invoice sent');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> markInvoicePaid(
      String token, int invoiceId) async {
    try {
      final url = '$_baseUrl/business/invoices/$invoiceId/paid';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Invoice paid');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<String>> getInvoicePdf(
      String token, int invoiceId) async {
    try {
      final url = '$_baseUrl/business/invoices/$invoiceId/pdf';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true, data: data['url']?.toString() ?? '');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Employees
  // ==========================================================================

  static Future<BusinessListResult<Employee>> getEmployees(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/employees';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Employee.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Employee>> addEmployee(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/employees';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Employee.fromJson(data['data'] ?? data),
            message: 'Mfanyakazi ameongezwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Employee>> updateEmployee(
      String token, int employeeId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/employees/$employeeId';
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true, data: Employee.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> removeEmployee(
      String token, int employeeId) async {
    try {
      final url = '$_baseUrl/business/employees/$employeeId';
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(success: res.statusCode == 200);
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Payroll
  // ==========================================================================

  static Future<BusinessResult<PayrollRun>> calculatePayroll(
      String token, int businessId, int month, int year) async {
    try {
      final url = '$_baseUrl/business/$businessId/payroll/calculate';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'month': month, 'year': year}));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: PayrollRun.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> approvePayroll(
      String token, int payrollId) async {
    try {
      final url = '$_baseUrl/business/payroll/$payrollId/approve';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Mishahara imeidhinishwa');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessListResult<PayrollRun>> getPayrollHistory(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/payroll';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => PayrollRun.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Tax
  // ==========================================================================

  static Future<BusinessResult<TaxCalculation>> calculateTax(
      String token, int businessId, String period) async {
    try {
      final url = '$_baseUrl/business/$businessId/tax/calculate';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'period': period}));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: TaxCalculation.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Registration Guide
  // ==========================================================================

  static Future<BusinessListResult<RegistrationStep>> getRegistrationGuide(
      String token) async {
    try {
      final url = '$_baseUrl/business/registration-guide';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) =>
                RegistrationStep.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Email Service
  // ==========================================================================

  /// Set up email service for a business.
  /// [domainType]: 'tajiri' (uses @tajiri.co.tz) or 'custom' (user provides domain).
  /// [customDomain]: required if domainType is 'custom', e.g. 'zima.co.tz'.
  static Future<BusinessResult<Business>> setupEmailService(
    String token,
    int businessId, {
    required String domainType,
    String? customDomain,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/business/$businessId/email/setup'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'domain_type': domainType,
          if (customDomain != null) 'custom_domain': customDomain,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return BusinessResult(success: true, data: Business.fromJson(data['data']));
      }
      return BusinessResult(success: false, message: data['message']?.toString() ?? 'Imeshindwa kuweka barua pepe');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  /// Create an email account under the business domain.
  static Future<BusinessResult<BusinessEmail>> createEmailAccount(
    String token,
    int businessId, {
    required String username,
    required String displayName,
    required String password,
    String? role,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/business/$businessId/email/accounts'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'username': username,
          'display_name': displayName,
          'password': password,
          if (role != null) 'role': role,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return BusinessResult(success: true, data: BusinessEmail.fromJson(data['data']));
      }
      return BusinessResult(success: false, message: data['message']?.toString() ?? 'Imeshindwa kuunda akaunti');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  /// List email accounts for a business.
  static Future<BusinessListResult<BusinessEmail>> getEmailAccounts(
    String token,
    int businessId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/$businessId/email/accounts'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final list = (data['data'] as List)
            .map((e) => BusinessEmail.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false);
    } catch (e) {
      return BusinessListResult(success: false);
    }
  }

  /// Delete an email account.
  static Future<BusinessResult<void>> deleteEmailAccount(
    String token,
    int businessId,
    int emailAccountId,
  ) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/business/$businessId/email/accounts/$emailAccountId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return BusinessResult(success: true);
      }
      return BusinessResult(success: false, message: data['message']?.toString() ?? 'Imeshindwa');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Quotes / Estimates (Makadirio)
  // ==========================================================================

  static Future<BusinessResult<Quote>> createQuote(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId/quotes';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Quote.fromJson(data['data'] ?? data),
            message: 'Quote created');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      _log('Error createQuote: $e');
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessListResult<Quote>> getQuotes(
      String token, int businessId, {String? status}) async {
    try {
      var url = '$_baseUrl/business/$businessId/quotes';
      if (status != null && status.isNotEmpty) url += '?status=$status';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Quote.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> sendQuote(
      String token, int quoteId) async {
    try {
      final url = '$_baseUrl/business/quotes/$quoteId/send';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Quote sent');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Invoice>> convertQuoteToInvoice(
      String token, int quoteId) async {
    try {
      final url = '$_baseUrl/business/quotes/$quoteId/convert';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Invoice.fromJson(data['data'] ?? data),
            message: 'Kadirio limebadilishwa kuwa ankara');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> updateQuoteStatus(
      String token, int quoteId, String status) async {
    try {
      final url = '$_baseUrl/business/quotes/$quoteId';
      final res = await http.patch(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'status': status}));
      return BusinessResult(success: res.statusCode == 200);
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Expenses (Matumizi)
  // ==========================================================================

  static Future<BusinessListResult<Expense>> getExpenses(
      String token, int businessId,
      {int? month, int? year, String? category}) async {
    try {
      var url = '$_baseUrl/business/$businessId/expenses';
      final params = <String>[];
      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');
      if (category != null && category.isNotEmpty) params.add('category=$category');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Expense>> addExpense(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId/expenses';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Expense.fromJson(data['data'] ?? data),
            message: 'Matumizi yameongezwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Expense>> uploadReceipt(
      String token, int expenseId, File file) async {
    try {
      final url = '$_baseUrl/business/expenses/$expenseId/receipt';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(ApiConfig.authHeaders(token));
      final ext = file.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') mimeType = 'image/png';
      if (ext == 'pdf') mimeType = 'application/pdf';
      request.files.add(await http.MultipartFile.fromPath('receipt', file.path,
          contentType: MediaType.parse(mimeType)));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Expense.fromJson(data['data'] ?? data),
            message: 'Risiti imepakiwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> deleteExpense(
      String token, int expenseId) async {
    try {
      final url = '$_baseUrl/business/expenses/$expenseId';
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Matumizi yamefutwa');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<ExpenseSummary>> getExpenseSummary(
      String token, int businessId, {int? month, int? year}) async {
    try {
      var url = '$_baseUrl/business/$businessId/expenses/summary';
      final params = <String>[];
      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: ExpenseSummary.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // TRA VFD Integration (Risiti za TRA)
  // ==========================================================================

  static Future<BusinessResult<VfdConfig>> getVfdConfig(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/vfd';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true, data: VfdConfig.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<VfdConfig>> registerVfd(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId/vfd/register';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: VfdConfig.fromJson(data['data'] ?? data),
            message: 'VFD imesajiliwa kwa TRA');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<FiscalReceipt>> issueFiscalReceipt(
      String token, int invoiceId) async {
    try {
      final url = '$_baseUrl/business/invoices/$invoiceId/fiscal-receipt';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: FiscalReceipt.fromJson(data['data'] ?? data),
            message: 'Risiti ya TRA imetolewa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessListResult<FiscalReceipt>> getFiscalReceipts(
      String token, int businessId, {int? page}) async {
    try {
      var url = '$_baseUrl/business/$businessId/fiscal-receipts';
      if (page != null) url += '?page=$page';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => FiscalReceipt.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Recurring Invoices
  // ==========================================================================

  static Future<BusinessResult<RecurringInvoice>> createRecurringInvoice(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId/recurring-invoices';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: RecurringInvoice.fromJson(data['data'] ?? data),
            message: 'Recurring invoice created');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessListResult<RecurringInvoice>> getRecurringInvoices(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/recurring-invoices';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => RecurringInvoice.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> cancelRecurringInvoice(
      String token, int recurringId) async {
    try {
      final url = '$_baseUrl/business/recurring-invoices/$recurringId/cancel';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Recurring invoice paused');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<RecurringInvoice>> updateRecurringInvoice(
      String token, int recurringId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/recurring-invoices/$recurringId';
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: RecurringInvoice.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // CRB Credit Report & Score (Ripoti ya Mkopo)
  // ==========================================================================

  static Future<BusinessResult<CreditReport>> getCreditReport(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/credit-report';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: CreditReport.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<CreditScore>> getCreditScore(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/credit-score';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: CreditScore.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<CreditReport>> requestCreditReport(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/credit-report/request';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: CreditReport.fromJson(data['data'] ?? data),
            message: 'Ripoti mpya imeombwa kutoka CreditInfo Tanzania');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Business Card / QR Code (Kadi ya Biashara)
  // ==========================================================================

  static Future<BusinessResult<Map<String, dynamic>>> getBusinessCard(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/card';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: data['data'] is Map<String, dynamic>
                ? data['data'] as Map<String, dynamic>
                : <String, dynamic>{});
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<String>> shareBusinessCard(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/card/share';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true, data: data['url']?.toString() ?? '');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Payment Reminders (Vikumbusho vya Malipo)
  // ==========================================================================

  static Future<BusinessResult<ReminderConfig>> getReminderConfig(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/reminders';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: ReminderConfig.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<ReminderConfig>> updateReminderConfig(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId/reminders';
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: ReminderConfig.fromJson(data['data'] ?? data),
            message: 'Vikumbusho vimesasishwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> sendManualReminder(
      String token, int debtOrInvoiceId, String channel) async {
    try {
      final url = '$_baseUrl/business/reminders/send';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'target_id': debtOrInvoiceId, 'channel': channel}));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Reminder sent');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Suppliers (Wasambazaji)
  // ==========================================================================

  static Future<BusinessListResult<Supplier>> getSuppliers(
      String token, int businessId, {String? search}) async {
    try {
      var url = '$_baseUrl/business/$businessId/suppliers';
      if (search != null && search.isNotEmpty) url += '?search=$search';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Supplier>> addSupplier(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId/suppliers';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: Supplier.fromJson(data['data'] ?? data),
            message: 'Msambazaji ameongezwa');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Supplier>> updateSupplier(
      String token, int supplierId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/suppliers/$supplierId';
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true, data: Supplier.fromJson(data['data'] ?? data));
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> deleteSupplier(
      String token, int supplierId) async {
    try {
      final url = '$_baseUrl/business/suppliers/$supplierId';
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(success: res.statusCode == 200);
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Purchase Orders (Maagizo ya Manunuzi)
  // ==========================================================================

  static Future<BusinessResult<PurchaseOrder>> createPurchaseOrder(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId/purchase-orders';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: PurchaseOrder.fromJson(data['data'] ?? data),
            message: 'Purchase order created');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessListResult<PurchaseOrder>> getPurchaseOrders(
      String token, int businessId, {String? status}) async {
    try {
      var url = '$_baseUrl/business/$businessId/purchase-orders';
      if (status != null && status.isNotEmpty) url += '?status=$status';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> markPOReceived(
      String token, int poId) async {
    try {
      final url = '$_baseUrl/business/purchase-orders/$poId/received';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Agizo limepokelewa');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> cancelPO(
      String token, int poId) async {
    try {
      final url = '$_baseUrl/business/purchase-orders/$poId/cancel';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Agizo limefutwa');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Appointments (Miadi ya Wateja)
  // ==========================================================================

  static Future<BusinessListResult<BusinessAppointment>> getAppointments(
      String token, int businessId, {String? date, String? status}) async {
    try {
      var url = '$_baseUrl/business/$businessId/appointments';
      final params = <String>[];
      if (date != null) params.add('date=$date');
      if (status != null && status.isNotEmpty) params.add('status=$status');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => BusinessAppointment.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<BusinessAppointment>> createAppointment(
      String token, int businessId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/$businessId/appointments';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return BusinessResult(
            success: true,
            data: BusinessAppointment.fromJson(data['data'] ?? data),
            message: 'Appointment created');
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> updateAppointmentStatus(
      String token, int appointmentId, String status) async {
    try {
      final url = '$_baseUrl/business/appointments/$appointmentId';
      final res = await http.patch(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'status': status}));
      return BusinessResult(success: res.statusCode == 200);
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> cancelAppointment(
      String token, int appointmentId) async {
    try {
      final url = '$_baseUrl/business/appointments/$appointmentId/cancel';
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      return BusinessResult(
          success: res.statusCode == 200, message: 'Appointment cancelled');
    } catch (e) {
      return BusinessResult(success: false, message: e.toString());
    }
  }

  // ==========================================================================
  // Legal Services — Quote Request
  // ==========================================================================

  /// Request a quote for legal / registration services.
  static Future<BusinessResult<void>> requestLegalQuote(
    String token, {
    required String name,
    required String phone,
    String? businessName,
    String? notes,
    String packageType = 'complete',
  }) async {
    try {
      final url = '$_baseUrl/business/legal-quote';
      _log('POST $url');
      final body = {
        'name': name,
        'phone': phone,
        'business_name': businessName ?? '',
        'notes': notes ?? '',
        'package_type': packageType,
      };
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      return BusinessResult(
          success: res.statusCode == 200 || res.statusCode == 201,
          message: 'Quote request submitted');
    } catch (e) {
      _log('Error requestLegalQuote: $e');
      return BusinessResult(success: false, message: e.toString());
    }
  }
}
