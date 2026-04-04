import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'DataStore.dart';
import 'paymentModal.dart';
import 'bankServicesModal.dart';
import 'vicoba.dart';
import 'KatibaModal.dart';
import 'kikoba.dart';

/// Data for manually sending invitation via SMS
class ManualSendData {
  final String recipientPhone;
  final String recipientName;
  final String message;

  ManualSendData({
    required this.recipientPhone,
    required this.recipientName,
    required this.message,
  });

  factory ManualSendData.fromJson(Map<String, dynamic> json) {
    return ManualSendData(
      recipientPhone: json['recipient_phone'] as String? ?? '',
      recipientName: json['recipient_name'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'ManualSendData(recipientPhone: $recipientPhone, recipientName: $recipientName)';
  }
}

/// Response model for register-mobile API
class RegisterMobileResponse {
  final String message;
  final String? userId;
  final int? otp;
  final bool? whatsappSent;
  final String? otpExpiresAt;
  final bool isSuccess;
  final ManualSendData? manualSend;

  RegisterMobileResponse({
    required this.message,
    this.userId,
    this.otp,
    this.whatsappSent,
    this.otpExpiresAt,
    required this.isSuccess,
    this.manualSend,
  });

  /// Returns true if manual SMS sending is required
  bool get requiresManualSend => isSuccess && whatsappSent == false && manualSend != null;

  factory RegisterMobileResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message'] as String? ?? 'error';
    final manualSendJson = json['manual_send'] as Map<String, dynamic>?;

    return RegisterMobileResponse(
      message: message,
      userId: json['userId'] as String?,
      otp: json['otp'] as int?,
      whatsappSent: json['whatsapp_sent'] as bool?,
      otpExpiresAt: json['otp_expires_at'] as String?,
      isSuccess: message == 'registered' || message == 'added_to_kikoba',
      manualSend: manualSendJson != null ? ManualSendData.fromJson(manualSendJson) : null,
    );
  }

  factory RegisterMobileResponse.error(String errorMessage) {
    return RegisterMobileResponse(
      message: errorMessage,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    return 'RegisterMobileResponse(message: $message, userId: $userId, otp: $otp, whatsappSent: $whatsappSent, otpExpiresAt: $otpExpiresAt, isSuccess: $isSuccess, manualSend: $manualSend)';
  }
}

class HttpService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );


  // Base URL configuration
  static const String _baseUrl = "https://zima-uat.site:8001/api/";
  static const String _esbBaseUrl = "https://zima.services/esb/public/api/";
  static const String baseUrl = "https://zima-uat.site:8001/api/";

  /// Extract numeric value from either a plain value or an object like {amount: 5000}
  static String _extractNumericValue(dynamic value) {
    if (value == null) return '';

    // If it's a Map (object), try to get 'amount' or first numeric value
    if (value is Map) {
      if (value.containsKey('amount')) {
        return value['amount']?.toString() ?? '';
      }
      // Try to find any numeric value in the map
      for (var v in value.values) {
        if (v is num) return v.toString();
        if (v is String && double.tryParse(v) != null) return v;
      }
      return '';
    }

    // If it's already a number or string, just convert
    return value.toString();
  }

  /// Device preparation no longer needed with new API
  @Deprecated('Device preparation not required with new API')
  static Future<String> prepareDevice() async {
    _logger.i('Device preparation not required with new API');
    return 'ok';
  }

  /// Retrieves Vikundi data for the current user
  Future<List<vicoba>> getData2xp() async {
    _logger.i('Fetching Vikundi data...');
    try {
      final url = "${_baseUrl}vicoba?userId=${DataStore.currentUserId ?? ''}";
      _logger.d('Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 30));

      _logger.d('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final restx = data["vicoba"] as List? ?? [];
        final list = restx.map<vicoba>((json) => vicoba.fromJson(json)).toList();
        _logger.i('Fetched ${list.length} Vikundi items');
        return list;
      } else {
        _logger.e('Failed to fetch Vikundi data: ${response.statusCode}');
        throw HttpException('Failed to fetch data', uri: Uri.parse(url));
      }
    } on TimeoutException {
      _logger.e('Vikundi data fetch timed out');
      throw TimeoutException('Connection timed out');
    } catch (e, stackTrace) {
      _logger.e('Error fetching Vikundi data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Processes a membership request
  static Future<String> membershipRequest() async {
    _logger.i('Processing membership request...');
    try {
      final url = "${_baseUrl}membership-request";
      final body = {
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'mobileNumber': DataStore.userNumber ?? '',
        'visitedKikobaId': DataStore.visitedKikobaId ?? '',
        'currentUserName': DataStore.currentUserName ?? '',
      };

      _logger.d('Request body: $body');
      final response = await http.post(
        Uri.parse(url),
        body: body,
      ).timeout(const Duration(seconds: 30));

      _logger.d('Membership request response: ${response.body}');
      if (response.statusCode == 200) {
        return response.body;
      } else {
        _logger.e('Membership request failed: ${response.statusCode}');
        throw HttpException('Membership request failed', uri: Uri.parse(url));
      }
    } on TimeoutException {
      _logger.e('Membership request timed out');
      throw TimeoutException('Request timed out');
    } catch (e, stackTrace) {
      _logger.e('Error in membership request', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Creates a payment intent for MNO payments
  static Future<String> createPaymentIntentMNO(
      String amount,
      String currency,
      String userNumber,
      String userNumberMNO,
      ) async {
    _logger.i('Creating MNO payment intent...');
    try {
      final url = "${_baseUrl}payment";
      List<dynamic> ww = [];

      if (DataStore.paymentService == "ada") {
        ww = DataStore.adaPaymentMap ?? [];
      } else if (DataStore.paymentService == "hisa") {
        ww = DataStore.adaPaymentMapx ?? [];
      } else if (DataStore.paymentService == "mkopo") {
        ww = ["1", "2"];
      }

      final body = {
        'amount': DataStore.paymentAmount?.toString() ?? '0',
        'currency': currency,
        'paymentService': DataStore.paymentService ?? '',
        'paymentChanel': DataStore.paymentChanel ?? '',
        'paymentInstitution': DataStore.paymentInstitution ?? '',
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'paidServiceId': DataStore.paidServiceId ?? '',
        'personPaidId': DataStore.personPaidId ?? '',
        'mobileNumber': userNumber,
        'paymentDistribution': jsonEncode(ww),
        'PAN': "",
        'CVV': "",
        'expiringDate': "",
        'cardHolderName': "",
        'paymentMethodTypes': 'mno',
      };

      _logger.d('URL: $url');
      _logger.d('Payment request body: $body');
      final response = await http.post(
        Uri.parse(url),
        body: body,
      ).timeout(const Duration(seconds: 30));

      _logger.d('Payment response: ${response.body}');
      return response.body;
    } on TimeoutException {
      _logger.e('Payment request timed out');
      throw TimeoutException('Payment processing timed out');
    } catch (e, stackTrace) {
      _logger.e('Error creating payment intent', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Registers a mobile number with first name and last name
  static Future<String> registerMobileNo(
    String mobileNo, {
    String firstName = '',
    String lastName = '',
  }) async {
    _logger.i('Registering mobile number: $mobileNo, firstName: $firstName, lastName: $lastName');
    try {
      final url = "${_baseUrl}register-mobile";
      final udid = await _getDeviceUdid();

      final body = {
        'udid': udid ?? '',
        'mobileNo': mobileNo,
        'firstName': firstName,
        'lastName': lastName,
        'currentUserId': '',
      };

      _logger.d('Registration body: $body');
      final response = await http.post(
        Uri.parse(url),
        body: body,
      ).timeout(const Duration(seconds: 30));

      _logger.d('Registration response: ${response.body}');
      return response.body;
    } on TimeoutException {
      _logger.e('Registration timed out');
      return "Device Offline";
    } on SocketException {
      _logger.e('No internet connection');
      return "Network Error";
    } on FormatException {
      _logger.e('Invalid server response format');
      return "Server Error";
    } catch (e, stackTrace) {
      _logger.e('Error registering mobile number', error: e, stackTrace: stackTrace);
      return "error";
    }
  }

  /// Gets the device UDID
  static Future<String?> _getDeviceUdid() async {
    _logger.i('Getting device UDID...');
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor;
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error getting device UDID', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Submits OTP for verification
  static Future<String> submitOTP(String otp) async {
    _logger.i('Submitting OTP...');
    try {
      final url = "${_baseUrl}submit-otp";
      final udid = await _getDeviceUdid();

      final body = {
        'otp': otp,
        'mobileNo': DataStore.userNumber,
      };

      _logger.d('OTP submission body: $body');
      final response = await http.post(
        Uri.parse(url),
        body: body,
      ).timeout(const Duration(seconds: 30));

      _logger.d('OTP response: ${response.body}');
      return response.body;
    } on TimeoutException {
      _logger.e('OTP submission timed out');
      return "Device Offline";
    } on SocketException {
      _logger.e('No internet connection');
      return "Network Error";
    } on FormatException {
      _logger.e('Invalid server response format');
      return "Server Error";
    } catch (e, stackTrace) {
      _logger.e('Error submitting OTP', error: e, stackTrace: stackTrace);
      return "error";
    }
  }

  /// Processes a loan payment via MNO
  static Future<String> closeloanPaymentIntentMNO(
      String paymentAmount,
      String currency,
      String userNumber,
      String paymentService,
      String paidServiceId,
      String personPaidId,
      String maelezoYaMalipo,
      ) async {
    _logger.i('Processing loan payment via MNO...');
    try {
      final url = "${_baseUrl}loan";
      final body = {
        'amount': paymentAmount,
        'currency': currency,
        'paymentService': paymentService,
        'paymentChanel': "",
        'paymentInstitution': "",
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'paidServiceId': paidServiceId,
        'personPaidId': personPaidId,
        'mobileNumber': userNumber,
        'paymentDistribution': "",
        'paymentDescription': maelezoYaMalipo,
        'PAN': "",
        'CVV': "",
        'expiringDate': "",
        'cardHolderName': "",
        'paymentMethodTypes': 'mno',
      };

      _logger.d('Loan payment request: $body');
      final response = await http.post(
        Uri.parse(url),
        body: body,
      ).timeout(const Duration(seconds: 30));

      _logger.d('Loan payment response: ${response.body}');
      return response.body;
    } on TimeoutException {
      _logger.e('Loan payment timed out');
      throw TimeoutException('Payment processing timed out');
    } catch (e, stackTrace) {
      _logger.e('Error processing loan payment', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Verifies a phone number
  static Future<String> verifyNumber(String userNumber) async {
    // Normalize phone number - add +255 if not present
    String normalizedNumber = userNumber.trim();
    if (!normalizedNumber.startsWith('+')) {
      // Remove leading zero if present
      if (normalizedNumber.startsWith('0')) {
        normalizedNumber = normalizedNumber.substring(1);
      }
      normalizedNumber = '+255$normalizedNumber';
    }

    _logger.i('Verifying number: $normalizedNumber');
    try {
      final url = "${_baseUrl}user?number=$normalizedNumber";

      _logger.d('Verification request: GET $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 30));

      _logger.d('Verification response: ${response.body}');
      return response.body;
    } on TimeoutException {
      _logger.e('Number verification timed out');
      throw TimeoutException('Verification timed out');
    } catch (e, stackTrace) {
      _logger.e('Error verifying number', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Requests bank authorization
  static Future<String> bankAuthorization(String userNumber) async {
    _logger.i('Requesting bank authorization...');
    try {
      final url = "${_esbBaseUrl}auth-request?userNumber=$userNumber&oauthcallback=https://zima.services/esb/public/api/nmb-oauth-callback";

      _logger.d('Authorization URL: $url');
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 30));

      _logger.d('Authorization response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return response.body;
      } else {
        _logger.e('Bank authorization failed: ${response.statusCode}');
        throw HttpException('Bank authorization failed', uri: Uri.parse(url));
      }
    } on TimeoutException {
      _logger.e('Bank authorization timed out');
      throw TimeoutException('Authorization timed out');
    } catch (e, stackTrace) {
      _logger.e('Error in bank authorization', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

// Additional methods would follow the same pattern with:
// 1. Logging at start/end
// 2. Proper error handling
// 3. Timeout management
// 4. Null safety checks
// 5. Consistent response handling


  static Future<String> topuploanPaymentIntentMNO(
      String paymentAmount,
      String currency,
      String userNumber,
      String paymentService,
      String paidServiceId,
      String personPaidId,
      String maelezoYaMalipo,
      String paymentTopUpAmount,
      ) async {
    final String url = "${_baseUrl}loan";
    String res = "";

    try {
      final Map<String, dynamic> body = {
        'amount': paymentAmount,
        'paymentTopUpAmount': paymentTopUpAmount,
        'currency': currency,
        'paymentService': paymentService,
        'paymentChanel': "",
        'paymentInstitution': "",
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'paidServiceId': paidServiceId,
        'personPaidId': personPaidId,
        'mobileNumber': userNumber,
        'paymentDistribution': "",
        'paymentDescription': maelezoYaMalipo,
        'PAN': "",
        'CVV': "",
        'expiringDate': "",
        'cardHolderName': "",
        'paymentMethodTypes': 'mno',
      };

      _logger.i("Sending topup loan payment request: $body");
      final response = await http.post(Uri.parse(url), body: body);
      _logger.i("Received response: ${response.body}");

      res = response.body;
    } catch (e, stackTrace) {
      _logger.e('Exception during topuploanPaymentIntentMNO $e');
      res = "";
    }

    return res;
  }

  static Future<String> topupRequestHttp(
      double amount,
      double maxValue,
      String mdhaminiId,
      String loanID,
      List<paymentModal> ratibaYaMkopo,
      double paymentAmount,
      String currency,
      String userNumber,
      String paymentService,
      String paidServiceId,
      String personPaidId,
      String maelezoYaMalipo,
      ) async {
    final String url = "${_baseUrl}loan";
    String res = "";

    try {
      final List<Map<String, dynamic>> paymentSchedule = ratibaYaMkopo.map((item) => item.toJson()).toList();

      final Map<String, dynamic> body = {
        'amount': amount.toString(),
        'currency': currency,
        'tenure': maxValue.toString(),
        'mdhaminiId': mdhaminiId,
        'paymentInstitution': DataStore.paymentInstitution ?? '',
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'currentUserName': DataStore.currentUserName ?? '',
        'disbursementNumber': DataStore.userNumber ?? '',
        'loanID': loanID,
        'ratibaYaMkopo': jsonEncode(paymentSchedule),
        'interest': DataStore.riba ?? '',
        'amounttoclose': paymentAmount.toString(),
        'paymentService': paymentService,
        'paymentChanel': "",
        'paidServiceId': paidServiceId,
        'personPaidId': personPaidId,
        'mobileNumber': userNumber,
        'paymentDistribution': "",
        'paymentDescription': maelezoYaMalipo,
        'PAN': "",
        'CVV': "",
        'expiringDate': "",
        'cardHolderName': "",
        'paymentMethodTypes': 'mno',
      };

      _logger.i("Sending topup request HTTP: $body");
      final response = await http.post(Uri.parse(url), body: body);
      _logger.i("Received response: ${response.body}");

      res = response.body;
    } catch (e, stackTrace) {
      _logger.e('Exception during topupRequestHttp $e');
      res = "";
    }

    return res;
  }

  static Future<String> fungaMchango() async {
    final String url = "${_baseUrl}mchango";
    String res = "";

    try {
      final Map<String, dynamic> body = {
        'amount': DataStore.paymentAmount?.toString() ?? '',
        'currency': "TZS",
        'paidServiceId': DataStore.paidServiceId ?? '',
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'mobileNumber': DataStore.userNumber ?? '',
      };

      _logger.i("Sending close contribution request: $body");
      final response = await http.post(Uri.parse(url), body: body);
      _logger.i("Received response: ${response.body}");

      res = response.body;
    } catch (e, stackTrace) {
      _logger.e('Exception during fungaMchango $e');
      res = "";
    }

    return res;
  }

  static Future<String> pigaFaini(
      String sababu,
      String amount,
      String userId,
      String name,
      ) async {
    final String url = "${_baseUrl}fine";
    String res = "";

    try {
      final Map<String, dynamic> body = {
        'name': name,
        'amount': amount,
        'sababu': sababu,
        'affectedUserId': userId,
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
      };

      _logger.i("Sending fine request: $body");
      final response = await http.post(Uri.parse(url), body: body);
      _logger.i("Received response: ${response.body}");

      res = response.body;
    } catch (e, stackTrace) {
      _logger.e('Exception during pigaFaini $e');
      res = "";
    }

    return res;
  }

  static Future<String> futaMtu(
      String sababu,
      String userId,
      String name,
      ) async {
    final String url = "${_baseUrl}remove-member";
    String res = "";

    try {
      final Map<String, dynamic> body = {
        'currentUserName': DataStore.currentUserName ?? '',
        'name': name,
        'sababu': sababu,
        'affectedUserId': userId,
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
      };

      _logger.i("Sending delete member request: $body");
      final response = await http.post(Uri.parse(url), body: body);
      _logger.i("Received response: ${response.body}");

      res = response.body;
    } catch (e, stackTrace) {
      _logger.e('Exception during futaMtu $e');
      res = "";
    }

    return res;
  }

  /// Remove a member from kikoba (creates a membership removal request)
  /// Uses POST /api/membership-removals
  static Future<Map<String, dynamic>?> removeMember({
    required String kikobaId,
    required String memberId,
    required String removalType, // voluntary, disciplinary, inactive, deceased, other
    required String reason, // Must be at least 10 characters
  }) async {
    logger.i('📝 [POST /api/membership-removals] Creating removal request for: $memberId');

    // Validate reason length
    if (reason.length < 10) {
      return {
        'success': false,
        'message': 'Sababu lazima iwe na angalau herufi 10',
      };
    }

    try {
      final url = Uri.parse('${_baseUrl}membership-removals');
      final body = {
        'kikoba_id': kikobaId,
        'member_id': memberId,
        'requested_by': DataStore.currentUserId ?? '',
        'removal_type': removalType,
        'reason': reason,
      };

      logger.d('Request URL: $url');
      logger.d('Request body: $body');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      // Check if response is HTML (likely a 404 page)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Endpoint haipatikani (${response.statusCode}). Wasiliana na msimamizi.',
        };
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ombi la kuondoa mwanachama limetumwa',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kutuma ombi',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception creating removal request', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  static Future<String> ombaMchangoKwaniaba(
      String ainayaMchango,
      String maelezo,
      String tarehe,
      String targetAmount,
      String amountPerPerson,
      ) async {
    final String url = "${_baseUrl}mchango";
    String res = "";

    try {
      final Map<String, dynamic> body = {
        'kwaniabaUserId': DataStore.kwaniabaId ?? '',
        'kwaniabaUserName': DataStore.kwaniabaName ?? '',
        'userName': DataStore.currentUserName ?? '',
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'mobileNumber': DataStore.userNumber ?? '',
        'ainayaMchango': ainayaMchango,
        'maelezo': maelezo,
        'tarehe': tarehe,
        'targetAmount': targetAmount,
        'amountPerPerson': amountPerPerson,
      };

      _logger.i("Sending contribution request on behalf: $body");
      final response = await http.post(Uri.parse(url), body: body);
      _logger.i("Received response: ${response.body}");

      res = response.body;
    } catch (e, stackTrace) {
      _logger.e('Exception during ombaMchangoKwaniaba $e');
      res = "";
    }

    return res;
  }

  static Future<String> itishaKikao(
      String location,
      String maelezo,
      String datex,
      String timex,
      String reminder,
      ) async {
    final String url = "${_baseUrl}meeting";
    String res = "";

    try {
      final Map<String, dynamic> body = {
        'location': location,
        'KikobaId': DataStore.currentKikobaId ?? '',
        'maelezo': maelezo,
        'datex': datex,
        'timex': timex,
        'reminder': reminder,
        'currentUserId': DataStore.currentUserId ?? '',
        'userName': DataStore.currentUserName ?? '',
      };

      _logger.i("Sending meeting request: $body");
      final response = await http.post(Uri.parse(url), body: body);
      _logger.i("Received response: ${response.body}");

      res = response.body;
    } catch (e, stackTrace) {
      _logger.e('Exception during itishaKikao $e');
      res = "";
    }

    return res;
  }





  static Future<String> rejectInvitation(String requestId) async {
    String result = "error";

    try {
      final deviceInfo = await _getDeviceInfo();
      final String? udid = await _getDeviceUdid();

      final body = {'requestId': requestId};
      logger.i('Reject Invitation Request: $body');

      final response = await http.post(Uri.parse('${baseUrl}invitation/reject'), body: body);
      logger.i('Reject Invitation Response: ${response.body}');

      result = response.body;
    } on SocketException catch (e) {
      logger.e('Network Error: ${e.toString()}');
      result = "Network Error";
    } on TimeoutException catch (e) {
      logger.e('Timeout Error: ${e.toString()}');
      result = "Device Offline";
    } on FormatException catch (e) {
      logger.e('Format Error: ${e.toString()}');
      result = "Server Error";
    } catch (e) {
      logger.e('Unexpected Error: ${e.toString()}');
    }

    return result;
  }

  static Future<String> acceptInvitation(String requestId) async {
    String result = "error";

    try {
      final deviceInfo = await _getDeviceInfo();
      final String? udid = await _getDeviceUdid();

      final body = {'requestId': requestId};
      logger.i('Accept Invitation Request: $body');

      final response = await http.post(Uri.parse('${baseUrl}invitation/accept'), body: body);
      logger.i('Accept Invitation Response: ${response.body}');

      result = response.body;
    } on SocketException catch (e) {
      logger.e('Network Error: ${e.toString()}');
      result = "Network Error";
    } on TimeoutException catch (e) {
      logger.e('Timeout Error: ${e.toString()}');
      result = "Device Offline";
    } on FormatException catch (e) {
      logger.e('Format Error: ${e.toString()}');
      result = "Server Error";
    } catch (e) {
      logger.e('Unexpected Error: ${e.toString()}');
    }

    return result;
  }

  static Future<String> updateAvatar(String localImage, String remoteImage) async {
    String result = "error";

    try {
      final body = {
        'currentUserId': DataStore.currentUserId ?? '',
        'remotepostImage': remoteImage,
        'localpostImage': localImage,
      };
      logger.i('Update Avatar Request: $body');

      final response = await http.post(Uri.parse('${baseUrl}member/profile-image'), body: body);
      logger.i('Update Avatar Response: ${response.body}');

      result = response.body;
    } catch (e) {
      logger.e('Error in updateAvatar: ${e.toString()}');
    }

    return result;
  }

  static Future<String> futaMkopo(String loanID) async {
    String result = "error";

    try {
      final body = {
        'currentUserId': DataStore.currentUserId ?? '',
      };
      logger.i('Futa Mkopo Request: $body');

      final response = await http.post(Uri.parse('${baseUrl}loan/delete'), body: body);
      logger.i('Futa Mkopo Response: ${response.body}');

      result = response.body;
    } catch (e) {
      logger.e('Error in futaMkopo: ${e.toString()}');
    }

    return result;
  }

  static Future<String> saveRiba(String riba, String ribaStatus) async {
    final url = Uri.parse('${baseUrl}katiba/riba');
    final statusString = ribaStatus == '1' ? 'inactive' : 'active';
    logger.i('Saving Riba: rate=$riba, status=$statusString');

    try {
      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'kikobaId': DataStore.currentKikobaId,
          'rate': double.tryParse(riba) ?? 0,
          'status': statusString,
          'RibaStatus': statusString,
        }),
      );

      logger.i('Save Riba Response: ${res.statusCode} - ${res.body}');

      if (res.statusCode == 200) {
        return res.body;
      } else {
        logger.e('Failed to save Riba: ${res.statusCode}');
        return 'Error: Save failed - ${res.statusCode}';
      }
    } catch (e) {
      logger.e('Error in saveRiba: ${e.toString()}');
      return 'Error';
    }
  }

  static Future<String> loanPrincipalInterest(String loanID) async {
    String url = '${baseUrl}loan/principal-interest?loanID=$loanID';
    logger.i('Loan Principal Interest URL: $url');

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        logger.i('Loan Principal Interest Response: ${res.body}');
        return res.body;
      } else {
        logger.e('Failed to get Principal Interest: ${res.statusCode}');
        return 'Server Error';
      }
    } catch (e) {
      logger.e('Error in loanPrincipalInterest: ${e.toString()}');
      return 'Error';
    }
  }

  static Future<String> closeloanPaymentIntentMNOx(
      String paymentAmount,
      String currency,
      String userNumber,
      String paymentService,
      String paidServiceId,
      String personPaidId,
      String paymentDescription,
      ) async {
    String result = "error";

    try {
      final body = {
        'amount': paymentAmount,
        'currency': currency,
        'paymentService': paymentService,
        'paymentChanel': "",
        'paymentInstitution': "",
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'paidServiceId': paidServiceId,
        'personPaidId': personPaidId,
        'mobileNumber': userNumber,
        'paymentDistribution': "",
        'paymentDescription': paymentDescription,
        'PAN': "",
        'CVV': "",
        'expiringDate': "",
        'cardHolderName': "",
        'paymentMethodTypes': 'mno',
      };
      logger.i('Close Loan Payment Request: $body');

      final response = await http.post(Uri.parse('${baseUrl}loan'), body: body);
      logger.i('Close Loan Payment Response: ${response.body}');

      result = response.body;
    } catch (e) {
      logger.e('Error in closeloanPaymentIntentMNO: ${e.toString()}');
    }

    return result;
  }

  static Future<String> loanInfo(String loanID) async {
    String url = '${baseUrl}loan/info?loanID=$loanID';
    logger.i('Loan Info URL: $url');

    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        logger.i('Loan Info Response: ${res.body}');
        return res.body;
      } else {
        logger.e('Failed to fetch Loan Info: ${res.statusCode}');
        return 'Server Error';
      }
    } catch (e) {
      logger.e('Error in loanInfo: ${e.toString()}');
      return 'Error';
    }
  }

  static Future<String> rejeshoPaymentIntentMNO(
      String paymentAmount,
      String currency,
      String userNumber,
      String paymentService,
      String paidServiceId,
      String personPaidId,
      String paymentDescription,
      ) async {
    String result = "error";

    try {
      final body = {
        'amount': paymentAmount,
        'currency': currency,
        'paymentService': paymentService,
        'paymentChanel': "",
        'paymentInstitution': "",
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'paidServiceId': paidServiceId,
        'personPaidId': personPaidId,
        'mobileNumber': userNumber,
        'paymentDistribution': "",
        'paymentDescription': paymentDescription,
        'PAN': "",
        'CVV': "",
        'expiringDate': "",
        'cardHolderName': "",
        'paymentMethodTypes': 'mno',
      };
      logger.i('Rejesho Payment Request: $body');

      final response = await http.post(Uri.parse('${baseUrl}payment'), body: body);
      logger.i('Rejesho Payment Response: ${response.body}');

      result = response.body;
    } catch (e) {
      logger.e('Error in rejeshoPaymentIntentMNO: ${e.toString()}');
    }

    return result;
  }

  static Future<BaseDeviceInfo> _getDeviceInfo() async {
    if (Platform.isAndroid) {
      return await DeviceInfoPlugin().androidInfo;
    } else if (Platform.isIOS) {
      return await DeviceInfoPlugin().iosInfo;
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }



// Device Info Helper
  static Future<BaseDeviceInfo> _getDeviceInfox() async {
    if (Platform.isAndroid) {
      return await DeviceInfoPlugin().androidInfo;
    } else if (Platform.isIOS) {
      return await DeviceInfoPlugin().iosInfo;
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static Future<String> updateProfileImage(String localpostImage, String remotepostImage) async {
    String res = "error";
    try {
      final deviceInfo = await _getDeviceInfo();
      final udid = await _getDeviceUdid();

      final body = {
        'currentUserId': DataStore.currentUserId ?? '',
        'localpostImage': localpostImage,
        'remotepostImage': remotepostImage,
      };
      logger.i('Update Profile Image Request: $body');

      final response = await http.post(Uri.parse('${_baseUrl}member/profile-image'), body: body);
      logger.i('Update Profile Image Response: ${response.body}');

      res = response.body;
    } catch (e) {
      logger.e('Error in updateProfileImage', error: e);
    }
    return res;
  }

  static Future<String> updateUserData(String encrypted, String jina) async {
    String res = "error";
    try {
      final body = {
        'currentUserId': DataStore.currentUserId ?? '',
        'psw': encrypted,
        'invitingKikobaId': DataStore.invitingKikobaId ?? '',
        'jina': jina,
      };
      logger.i('Update User Data Request: $body');

      final response = await http.post(
        Uri.parse('${_baseUrl}member/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
      logger.i('Update User Data Response: ${response.body}');

      // Parse response to check for success
      try {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          res = 'success';
        } else {
          // Return error message if available
          res = jsonResponse['message']?.toString() ?? response.body;
        }
      } catch (_) {
        res = response.body;
      }
    } catch (e) {
      logger.e('Error in updateUserData', error: e);
    }
    return res;
  }

  static Future<String> login(String userNumber, String pin) async {
    String res = "error";
    try {
      final deviceInfo = await _getDeviceInfo();
      final udid = await _getDeviceUdid();
      var uuid = Uuid();
      DataStore.currentUserId = uuid.v1();

      final body = {
        'mobileNo': userNumber,
        'psw': pin,
      };
      logger.i('Login Request: $body');

      final response = await http.post(Uri.parse('${_baseUrl}login'), body: body);
      logger.i('Login Response: ${response.body}');

      res = response.body;
    } catch (e) {
      logger.e('Error in login', error: e);
    }
    return res;
  }

  static Future<String> login2(String pin) async {
    String res = "error";
    try {
      final deviceInfo = await _getDeviceInfo();
      final udid = await _getDeviceUdid();
      var uuid = Uuid();
      DataStore.currentUserId = uuid.v1();

      final body = {'psw': pin};
      logger.i('Login2 Request: $body');

      final response = await http.post(Uri.parse('${_baseUrl}login'), body: body);
      logger.i('Login2 Response: ${response.body}');

      res = response.body;
    } catch (e) {
      logger.e('Error in login2', error: e);
    }
    return res;
  }

  static Future<String> createKikoba(String imageUrl, String cheo) async {
    String res = "error";
    try {
      final deviceInfo = await _getDeviceInfo();
      final udid = await _getDeviceUdid();

      final body = {
        'kikobaid': DataStore.currentKikobaId ?? '',
        'kikobaname': DataStore.createKikobaName ?? '',
        'creatorid': DataStore.currentUserId ?? '',
        'creatorname': DataStore.currentUserName ?? '',
        'creatorphone': DataStore.userNumber ?? '',
        'maelezokuhusukikoba': DataStore.createKikobaMaelezo ?? '',
        'kikobaImage': imageUrl,
        'cheo': cheo,
        'location': DataStore.createKikobaEneo ?? '',
      };
      logger.i('Create Kikoba Request: $body');

      final response = await http.post(Uri.parse('${_baseUrl}kikoba'), body: body);
      logger.i('Create Kikoba Response: ${response.body}');

      res = response.body;
    } catch (e) {
      logger.e('Error in createKikoba', error: e);
    }
    return res;
  }

  static Future<String> addNewMember(String imageUrl, String userId) async {
    String res = "error";
    try {
      final deviceInfo = await _getDeviceInfo();
      final udid = await _getDeviceUdid();

      final body = {
        'kikobaid': DataStore.currentKikobaId ?? '',
        'kikobaname': DataStore.createKikobaName ?? '',
        'creatorid': DataStore.currentUserId ?? '',
        'creatorname': DataStore.currentUserName ?? '',
        'creatorphone': DataStore.userNumber ?? '',
        'maelezokuhusukikoba': DataStore.createKikobaMaelezo ?? '',
        'kikobaImage': imageUrl,
        'location': DataStore.createKikobaEneo ?? '',
      };
      logger.i('Add New Member Request: $body');

      final response = await http.post(Uri.parse('${_baseUrl}member/add'), body: body);
      logger.i('Add New Member Response: ${response.body}');

      res = response.body;
    } catch (e) {
      logger.e('Error in addNewMember', error: e);
    }
    return res;
  }

  Future<List<bankServicesModal>> getBankServices() async {
    List<bankServicesModal> list = [];

    try {
      final link = '${_baseUrl}bank-services?userId=${DataStore.currentUserId ?? ''}';
      logger.i('Getting Bank Services from: $link');

      final res = await http.get(Uri.parse(link), headers: {"Accept": "application/json"});

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        logger.i('Bank Services Data: $data');

        final services = data['services'] as List<dynamic>;
        list = services.map<bankServicesModal>((json) => bankServicesModal.fromJson(json)).toList();
      } else {
        logger.w('Failed to fetch bank services: HTTP ${res.statusCode}');
      }
    } catch (e) {
      logger.e('Error in getBankServices', error: e);
    }

    return list;
  }

  static Future<String> reportBug(String errorText, String operation, String bodyz, String responsex, dynamic deviceInfo) async {
    String res = "error";
    try {
      final body = {
        'userName': DataStore.currentUserName ?? '',
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'mobileNumber': DataStore.userNumber ?? '',
        'operation': operation,
        'body': bodyz,
        'response': responsex,
        'deviceInfo': deviceInfo.toString(),
        'error': errorText,
      };
      logger.i('Reporting Bug: $body');

      final response = await http.post(Uri.parse('${_baseUrl}bug-report'), body: body);
      logger.i('Bug Report Response: ${response.body}');

      res = response.body;
    } catch (e) {
      logger.e('Error in reportBug', error: e);
    }
    return res;
  }







  static Future<Map<String, dynamic>?> createPaymentIntentFromBankAcc(String amount, String currency) async {
    logger.i("Starting payment intent creation...");

    try {
      final Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'paymentService': DataStore.paymentService,
        'paymentChanel': DataStore.paymentChanel,
        'paymentInstitution': DataStore.paymentInstitution,
        'KikobaId': DataStore.currentKikobaId,
        'currentUserId': DataStore.currentUserId,
        'mobileNumber': DataStore.userNumber,
        'payingBIN': DataStore.payingBIN,
        'payingBank': DataStore.payingBank,
        'payingAccount': DataStore.payingAccount,
        'paymentDistribution': jsonEncode(DataStore.paymentService == "ada" ? DataStore.adaPaymentMap : []),
        'PAN': "",
        'CVV': "",
        'expiringDate': "",
        'cardHolderName': "",
        'paymentMethodTypes': 'bank'
      };

      logger.d("Request body: $body");

      final response = await http.post(
        Uri.parse("${_baseUrl}payment"),
        body: body,
      );

      logger.d("Response status: ${response.statusCode}");
      logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.w("Unexpected status code: ${response.statusCode}");
        return null;
      }
    } catch (e, stacktrace) {
      logger.e("Failed to create payment intent $e");
      return null;
    }
  }

  static Future<String> getBalance() async {
    logger.i("Fetching running balance... ${_baseUrl}kikoba/${DataStore.currentKikobaId}/balance");
    try {
      final response = await http.get(Uri.parse("${_baseUrl}kikoba/${DataStore.currentKikobaId}/balance"));

      if (response.statusCode == 200) {
        logger.d("Balance fetched successfully");
        return response.body;
      } else {
        logger.w("Failed to fetch balance: ${response.statusCode}");
        throw Exception("Unable to retrieve balance.");
      }
    } catch (e, stacktrace) {
      logger.e("Error while fetching balance $e");
      throw Exception("Balance retrieval failed");
    }
  }

  static Future<String> loanRequestHttp(double amount, double maxValue, String mdhaminiId, String loanID, List<paymentModal> ratibaYaMkopo) async {
    logger.i("Starting loan request...");

    try {
      List<Map<String, dynamic>> schedule = ratibaYaMkopo.map((e) => e.toJson()).toList();

      final Map<String, dynamic> body = {
        'amount': amount.toString(),
        'currency': "TZS",
        'tenure': maxValue.toString(),
        'mdhaminiId': mdhaminiId,
        'paymentInstitution': DataStore.paymentInstitution,
        'KikobaId': DataStore.currentKikobaId,
        'currentUserId': DataStore.currentUserId,
        'currentUserName': DataStore.currentUserName,
        'disbursementNumber': DataStore.userNumber,
        'loanID': loanID,
        'ratibaYaMkopo': jsonEncode(schedule),
        'interest': DataStore.riba
      };

      logger.d("Loan request body: $body");

      final response = await http.post(
        Uri.parse("${_baseUrl}loan"),
        body: body,
      );

      logger.d("Loan request response: ${response.body}");

      return response.body;
    } catch (e, stacktrace) {
      logger.e("Loan request failed $e");
      return "7";
    }
  }

  static Future<String> vote(String type, String vote, String caseID, String position, String userID) async {
    logger.i("Voting...");
    try {
      final Map<String, dynamic> body = {
        'KikobaId': DataStore.currentKikobaId,
        'currentUserId': DataStore.currentUserId,
        'mobileNumber': DataStore.userNumber,
        'type': type,
        'vote': vote,
        'caseID': caseID,
        'userCheo': DataStore.userCheo,
        'position': position,
        'userID': userID
      };

      logger.d("Vote request body: $body");

      final response = await http.post(
        Uri.parse("${_baseUrl}vote"),
        body: body,
      );

      logger.d("Vote response: ${response.body}");

      return response.body;
    } catch (e, stacktrace) {
      logger.e("Voting failed $e");
      return "error";
    }
  }

  // ========== Unified Voting System APIs ==========
  // Based on docs/VOTING.md API specification

  /// Cast a vote on any voteable item using unified voting API
  /// POST /api/voting/vote
  static Future<Map<String, dynamic>> castVote({
    required String voteableType,
    required String voteableId,
    required String vote, // 'yes', 'no', 'abstain'
    String? comment,
  }) async {
    _logger.i('Casting vote: $vote on $voteableType #$voteableId');
    try {
      final body = {
        'voteable_type': voteableType,
        'voteable_id': voteableId,
        'voter_id': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        'vote': vote,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      _logger.d('Cast vote request: $body');

      final response = await http.post(
        Uri.parse('${_baseUrl}voting/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      _logger.d('Cast vote response: ${response.statusCode} - ${response.body}');

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'code': jsonData['code'] ?? '',
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
        'statusCode': response.statusCode,
      };
    } on TimeoutException {
      _logger.e('Cast vote timeout');
      return {'success': false, 'message': 'Connection timed out', 'code': 'TIMEOUT'};
    } catch (e) {
      _logger.e('Cast vote error: $e');
      return {'success': false, 'message': e.toString(), 'code': 'ERROR'};
    }
  }

  /// Get voting status for a specific item
  /// GET /api/voting/{voteableType}/{voteableId}
  static Future<Map<String, dynamic>> getVotingStatus({
    required String voteableType,
    required int voteableId,
    String? userId,
  }) async {
    _logger.i('Getting voting status for $voteableType #$voteableId');
    try {
      final queryParams = {
        if (userId != null) 'user_id': userId,
      };
      final queryString = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
          : '';

      final response = await http.get(
        Uri.parse('${_baseUrl}voting/$voteableType/$voteableId$queryString'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      _logger.d('Voting status response: ${response.statusCode}');

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
        'statusCode': response.statusCode,
      };
    } catch (e) {
      _logger.e('Get voting status error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Revoke a previously cast vote
  /// POST /api/voting/{voteableType}/{voteableId}/revoke
  static Future<Map<String, dynamic>> revokeVote({
    required String voteableType,
    required int voteableId,
  }) async {
    _logger.i('Revoking vote on $voteableType #$voteableId');
    try {
      final body = {
        'voter_id': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}voting/$voteableType/$voteableId/revoke'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'code': jsonData['code'] ?? '',
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Revoke vote error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get all pending voteable items for a kikoba
  /// GET /api/voting/kikoba/{kikobaId}/pending
  static Future<Map<String, dynamic>> getPendingVoteItems({
    String? kikobaId,
    String? type, // Optional: filter by voteable type
  }) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    _logger.i('Getting pending vote items for kikoba: $kId');
    try {
      final queryParams = {
        'user_id': DataStore.currentUserId ?? '',
        if (type != null) 'type': type,
      };
      final queryString = '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await http.get(
        Uri.parse('${_baseUrl}voting/kikoba/$kId/pending$queryString'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      _logger.d('Pending items response: ${response.statusCode}');
      _logger.d('Pending items body: ${response.body}');

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
        'pagination': jsonData['pagination'],
      };
    } catch (e) {
      _logger.e('Get pending items error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Get user's vote history for a kikoba
  /// GET /api/voting/kikoba/{kikobaId}/user/{userId}/history
  static Future<Map<String, dynamic>> getVoteHistory({
    String? kikobaId,
    String? userId,
  }) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    final uId = userId ?? DataStore.currentUserId;
    _logger.i('Getting vote history for user: $uId in kikoba: $kId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}voting/kikoba/$kId/user/$uId/history'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
        'pagination': jsonData['pagination'],
      };
    } catch (e) {
      _logger.e('Get vote history error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Get voting configuration for a kikoba
  /// GET /api/voting/kikoba/{kikobaId}/config
  static Future<Map<String, dynamic>> getVotingConfig({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    _logger.i('Getting voting config for kikoba: $kId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}voting/kikoba/$kId/config'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Get voting config error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update voting configuration for a kikoba (admin only)
  /// PUT /api/voting/kikoba/{kikobaId}/config
  static Future<Map<String, dynamic>> updateVotingConfig({
    required Map<String, dynamic> config,
    String? kikobaId,
  }) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    _logger.i('Updating voting config for kikoba: $kId');
    try {
      final body = {
        'admin_id': DataStore.currentUserId,
        ...config,
      };

      final response = await http.put(
        Uri.parse('${_baseUrl}voting/kikoba/$kId/config'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Update voting config error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get all supported voteable types
  /// GET /api/voting/types
  static Future<Map<String, dynamic>> getVoteableTypes() async {
    _logger.i('Getting voteable types');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}voting/types'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get voteable types error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Admin: Force approve a voteable item
  /// POST /api/voting/{voteableType}/{voteableId}/approve
  static Future<Map<String, dynamic>> forceApprove({
    required String voteableType,
    required int voteableId,
    String? reason,
  }) async {
    _logger.i('Force approving $voteableType #$voteableId');
    try {
      final body = {
        'admin_id': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        if (reason != null) 'reason': reason,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}voting/$voteableType/$voteableId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'code': jsonData['code'] ?? '',
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Force approve error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Admin: Force reject a voteable item
  /// POST /api/voting/{voteableType}/{voteableId}/reject
  static Future<Map<String, dynamic>> forceReject({
    required String voteableType,
    required int voteableId,
    String? reason,
  }) async {
    _logger.i('Force rejecting $voteableType #$voteableId');
    try {
      final body = {
        'admin_id': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        if (reason != null) 'reason': reason,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}voting/$voteableType/$voteableId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'code': jsonData['code'] ?? '',
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Force reject error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========== Katiba APIs ==========

  /// Get katiba data from dedicated endpoint
  /// GET /api/katiba?kikobaId={kikobaId}
  static Future<Map<String, dynamic>> getKatibaData({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId ?? "";
    _logger.i('[getKatibaData] Fetching katiba for kikoba: $kId');

    try {
      final url = Uri.parse('${_baseUrl}katiba?kikobaId=$kId');
      _logger.d('[getKatibaData] API URL: $url');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      _logger.d('[getKatibaData] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          _logger.d('[getKatibaData] Data received: $data');

          // Update DataStore with katiba values
          updateKatibaDataStore(data);

          _logger.i('[getKatibaData] ✓ Katiba data fetched successfully');
          return {'success': true, 'data': data};
        } else {
          _logger.w('[getKatibaData] API returned success=false or no data');
          return {'success': false, 'message': json['message'] ?? 'No data'};
        }
      } else {
        _logger.w('[getKatibaData] Server error: ${response.statusCode}');
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e, stackTrace) {
      _logger.e('[getKatibaData] Error: $e', error: e, stackTrace: stackTrace);
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update DataStore with katiba data from API response
  /// Public so it can be called when loading from cache
  static void updateKatibaDataStore(Map<String, dynamic> data) {
    DataStore.katiba = data;
    DataStore.kiingilio = _extractNumericValue(data["kiingilio"]);
    DataStore.kiingilioStatus = data["kiingilioStatus"]?.toString() ?? '';
    DataStore.ada = _extractNumericValue(data["ada"]);
    DataStore.adaStatus = data["adaStatus"]?.toString() ?? '';
    DataStore.Hisa = _extractNumericValue(data["hisa"]);
    DataStore.hisaStatus = data["hisaStatus"]?.toString() ?? '';
    DataStore.faini_ada = _extractNumericValue(data["faini_ada"]);
    DataStore.faini_adaStatus = data["faini_adaStatus"]?.toString() ?? '';
    DataStore.fainiVikao = _extractNumericValue(data["fainiVikao"]);
    DataStore.fainiVikaoStatus = data["fainiVikaoStatus"]?.toString() ?? '';
    DataStore.faini_hisa = _extractNumericValue(data["faini_hisa"]);
    DataStore.faini_hisaStatus = data["faini_hisaStatus"]?.toString() ?? '';
    DataStore.faini_michango = _extractNumericValue(data["faini_michango"]);
    DataStore.faini_michangoStatus = data["faini_michangoStatus"]?.toString() ?? '';
    DataStore.chini = data["chini"]?.toString() ?? '';
    DataStore.mikopo = data["mikopo"]?.toString() ?? '';
    DataStore.riba = double.tryParse(data["riba"]?.toString() ?? '0') ?? 0.0;
    DataStore.ribaStatus = data["ribaStatus"]?.toString() ?? '';
    DataStore.tenure = data["tenure"]?.toString() ?? '';
    DataStore.fainiyamikopo = data["fainiyamikopo"]?.toString() ?? '';
    DataStore.mikopoStatus = data["mikopoStatus"]?.toString() ?? '';

    // Update loan products if available (check both snake_case and camelCase)
    if (data["loan_products"] != null) {
      DataStore.loanProducts = data["loan_products"];
      _logger.d('[updateKatibaDataStore] Loaded ${(data["loan_products"] as List).length} loan products (snake_case)');
    } else if (data["loanProducts"] != null) {
      DataStore.loanProducts = data["loanProducts"];
      _logger.d('[updateKatibaDataStore] Loaded ${(data["loanProducts"] as List).length} loan products (camelCase)');
    }
  }

  /// Refresh all katiba data from the server (legacy - uses general data endpoint)
  /// GET /api/data?kikobaId={kikobaId}&userID={userID}
  @Deprecated('Use getKatibaData() instead for dedicated katiba endpoint')
  static Future<bool> refreshKatibaData() async {
    _logger.i('[refreshKatibaData] Refreshing katiba data...');
    try {
      final userID = DataStore.currentUserId ?? "";
      final kikobaId = DataStore.currentKikobaId ?? "";

      final url = Uri.parse('${_baseUrl}data?kikobaId=$kikobaId&userID=$userID');
      _logger.d('[refreshKatibaData] API URL: $url');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      _logger.d('[refreshKatibaData] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Process katiba data
        if (data['katiba'] != null) {
          final katibaList = data['katiba'] is List ? data['katiba'] : [];
          if (katibaList.isNotEmpty) {
            final katibaItem = katibaList[0];
            _logger.d('[refreshKatibaData] Updating katiba values from: $katibaItem');

            DataStore.katiba = katibaItem;
            DataStore.kiingilio = _extractNumericValue(katibaItem["kiingilio"]);
            DataStore.kiingilioStatus = katibaItem["kiingilioStatus"]?.toString() ?? '';
            DataStore.ada = _extractNumericValue(katibaItem["ada"]);
            DataStore.adaStatus = katibaItem["adaStatus"]?.toString() ?? '';
            DataStore.Hisa = _extractNumericValue(katibaItem["hisa"]);
            DataStore.hisaStatus = katibaItem["hisaStatus"]?.toString() ?? '';
            DataStore.faini_ada = _extractNumericValue(katibaItem["faini_ada"]);
            DataStore.faini_adaStatus = katibaItem["faini_adaStatus"]?.toString() ?? '';
            DataStore.fainiVikao = _extractNumericValue(katibaItem["fainiVikao"]);
            DataStore.fainiVikaoStatus = katibaItem["fainiVikaoStatus"]?.toString() ?? '';
            DataStore.faini_hisa = _extractNumericValue(katibaItem["faini_hisa"]);
            DataStore.faini_hisaStatus = katibaItem["faini_hisaStatus"]?.toString() ?? '';
            DataStore.faini_michango = _extractNumericValue(katibaItem["faini_michango"]);
            DataStore.faini_michangoStatus = katibaItem["faini_michangoStatus"]?.toString() ?? '';
            DataStore.chini = katibaItem["chini"]?.toString() ?? '';
            DataStore.mikopo = katibaItem["mikopo"]?.toString() ?? '';
            DataStore.riba = double.tryParse(katibaItem["riba"]?.toString() ?? '0') ?? 0.0;
            DataStore.ribaStatus = katibaItem["ribaStatus"]?.toString() ?? '';
            DataStore.tenure = katibaItem["tenure"]?.toString() ?? '';
            DataStore.fainiyamikopo = katibaItem["fainiyamikopo"]?.toString() ?? '';
            DataStore.mikopoStatus = katibaItem["mikopoStatus"]?.toString() ?? '';

            // Update loan products if available (check both snake_case and camelCase)
            if (katibaItem["loan_products"] != null) {
              DataStore.loanProducts = katibaItem["loan_products"];
            } else if (katibaItem["loanProducts"] != null) {
              DataStore.loanProducts = katibaItem["loanProducts"];
            }

            _logger.i('[refreshKatibaData] ✓ Katiba data refreshed successfully');
          }
        }

        return true;
      } else {
        _logger.w('[refreshKatibaData] Server error: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('[refreshKatibaData] Error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all changeable katiba fields
  /// GET /api/katiba-changes-fields
  static Future<Map<String, dynamic>> getKatibaChangeFields() async {
    _logger.i('Getting katiba change fields');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}katiba-changes-fields'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get katiba fields error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Create a katiba change request (requires voting)
  /// POST /api/katiba-changes
  static Future<Map<String, dynamic>> createKatibaChangeRequest({
    required String changeType,
    required Map<String, dynamic> proposedValue,
    required String reason,
    String? description,
    String? effectiveDate,
  }) async {
    _logger.i('╔════════════════════════════════════════════════════════════');
    _logger.i('║ [createKatibaChangeRequest] START - HTTP REQUEST');
    _logger.i('╚════════════════════════════════════════════════════════════');
    _logger.d('[createKatibaChangeRequest] Input parameters:');
    _logger.d('  - changeType: $changeType');
    _logger.d('  - proposedValue: $proposedValue');
    _logger.d('  - reason: $reason');
    _logger.d('  - description: $description');
    _logger.d('  - effectiveDate: $effectiveDate');

    try {
      final body = {
        'requested_by': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        'change_type': changeType,
        'proposed_value': proposedValue,
        'reason': reason,
        if (description != null) 'description': description,
        if (effectiveDate != null) 'effective_date': effectiveDate,
      };

      final url = '${_baseUrl}katiba-changes';
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      _logger.i('[createKatibaChangeRequest] ══════ HTTP REQUEST ══════');
      _logger.i('[createKatibaChangeRequest] POST $url');
      _logger.i('[createKatibaChangeRequest] Headers: $headers');
      _logger.i('[createKatibaChangeRequest] Body: ${jsonEncode(body)}');

      final stopwatch = Stopwatch()..start();

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();

      _logger.i('[createKatibaChangeRequest] ══════ HTTP RESPONSE ══════');
      _logger.i('[createKatibaChangeRequest] Status Code: ${response.statusCode}');
      _logger.i('[createKatibaChangeRequest] Response Time: ${stopwatch.elapsedMilliseconds}ms');
      _logger.i('[createKatibaChangeRequest] Response Body: ${response.body}');

      final jsonData = jsonDecode(response.body);
      final result = {
        'success': jsonData['success'] ?? (response.statusCode == 200 || response.statusCode == 201),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
        'statusCode': response.statusCode,
      };

      _logger.i('[createKatibaChangeRequest] Parsed result:');
      _logger.i('  - success: ${result['success']}');
      _logger.i('  - message: ${result['message']}');
      _logger.i('  - statusCode: ${result['statusCode']}');
      _logger.i('  - data: ${result['data']}');
      _logger.i('[createKatibaChangeRequest] ════════════════ END ════════════════');

      return result;
    } catch (e, stackTrace) {
      _logger.e('[createKatibaChangeRequest] ✗ ERROR: $e');
      _logger.e('[createKatibaChangeRequest] Stack trace: $stackTrace');
      _logger.i('[createKatibaChangeRequest] ════════════════ END (ERROR) ════════════════');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get pending katiba change requests
  /// GET /api/katiba-changes/kikoba/{kikobaId}/pending?user_id={userId}
  static Future<Map<String, dynamic>> getPendingKatibaChanges({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    final userId = DataStore.currentUserId;
    _logger.i('Getting pending katiba changes for kikoba: $kId');
    try {
      final uri = Uri.parse('${_baseUrl}katiba-changes/kikoba/$kId/pending').replace(
        queryParameters: {
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get pending katiba changes error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Get katiba change request details
  /// GET /api/katiba-changes/{requestId}
  static Future<Map<String, dynamic>> getKatibaChangeDetails({
    required String requestId,
  }) async {
    _logger.i('Getting katiba change details: $requestId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}katiba-changes/$requestId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Get katiba change details error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get membership removal request details
  /// GET /api/membership-removals/{requestId}
  static Future<Map<String, dynamic>> getMembershipRemovalDetails({
    required String requestId,
  }) async {
    _logger.i('Getting membership removal details: $requestId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}membership-removals/$requestId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      // Check for HTML response (404 page)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Ombi halipatikani',
        };
      }

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
        'message': jsonData['message'],
      };
    } catch (e) {
      _logger.e('Get membership removal details error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get expense request details
  /// GET /api/expense-requests/{requestId}
  static Future<Map<String, dynamic>> getExpenseRequestDetails({
    required String requestId,
  }) async {
    _logger.i('Getting expense request details: $requestId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}expense-requests/$requestId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      // Check for HTML response (404 page)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Ombi halipatikani',
        };
      }

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
        'message': jsonData['message'],
      };
    } catch (e) {
      _logger.e('Get expense request details error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get fine approval request details
  /// GET /api/fine-approvals/{requestId}
  static Future<Map<String, dynamic>> getFineApprovalDetails({
    required String requestId,
  }) async {
    _logger.i('Getting fine approval details: $requestId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}fine-approvals/$requestId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      // Check for HTML response (404 page)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Ombi halipatikani',
        };
      }

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
        'message': jsonData['message'],
      };
    } catch (e) {
      _logger.e('Get fine approval details error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get loan application details for voting
  /// GET /api/loan-applications/{applicationId}
  ///
  /// API Response:
  /// {
  ///   "status": "success",
  ///   "data": {
  ///     "application_id": "LA_xxx",
  ///     "kikoba_id": "...",
  ///     "user_id": "...",
  ///     "applicant_name": "...",
  ///     "principal_amount": 2400000,
  ///     "interest_rate": 10,
  ///     "tenure": 12,
  ///     "total_repayment": 2640000,
  ///     "monthly_installment": 220000,
  ///     "status": "pending_approval",
  ///     "charges": [...],
  ///     "guarantors": [...],
  ///     "metadata": {...},
  ///     "loan_product": {...}
  ///   }
  /// }
  static Future<Map<String, dynamic>> getLoanApplicationDetails({
    required String applicationId,
  }) async {
    _logger.i('Getting loan application details: $applicationId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}loan-applications/$applicationId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      _logger.d('Loan application response: ${response.statusCode}');

      // Check for HTML response (404 page)
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Ombi la mkopo halipatikani',
        };
      }

      final jsonData = jsonDecode(response.body);
      _logger.d('Loan application data: $jsonData');

      // API returns status: "success" not success: true
      final isSuccess = jsonData['status'] == 'success' || response.statusCode == 200;

      // Normalize the data field names for UI compatibility
      // API uses camelCase and nested objects (loanDetails, calculations)
      final rawData = jsonData['data'];
      Map<String, dynamic>? data;
      if (rawData is Map<String, dynamic>) {
        data = Map<String, dynamic>.from(rawData);

        // Extract nested loanDetails
        final loanDetails = data['loanDetails'] as Map<String, dynamic>?;
        if (loanDetails != null) {
          data['principal_amount'] = loanDetails['principalAmount'];
          data['amount'] = loanDetails['principalAmount'];
          data['interest_rate'] = loanDetails['interestRate'];
          data['tenure'] = loanDetails['tenure'];
        }

        // Extract nested calculations
        final calculations = data['calculations'] as Map<String, dynamic>?;
        if (calculations != null) {
          data['total_repayment'] = calculations['totalRepayment'];
          data['monthly_installment'] = calculations['monthlyInstallment'];
          data['monthly_payment'] = calculations['monthlyInstallment'];
          data['total_interest'] = calculations['totalInterest'];
          data['net_disbursement'] = calculations['netDisbursement'];
          data['first_payment_date'] = calculations['firstPaymentDate'];
          data['maturity_date'] = calculations['maturityDate'];
        }

        // Extract nested loanProduct
        final loanProduct = data['loanProduct'] as Map<String, dynamic>?;
        if (loanProduct != null) {
          data['loan_product'] = {
            'name': loanProduct['productName'],
            'id': loanProduct['productId'],
          };
        }

        // Map camelCase to snake_case for UI compatibility
        data['id'] = data['applicationId'] ?? applicationId;
        data['application_id'] = data['applicationId'];
        data['applicant_name'] = data['applicantName'];
        data['member_name'] = data['applicantName'];
        data['applicant_phone'] = data['applicantPhone'];
        data['kikoba_id'] = data['kikobaId'];
        data['user_id'] = data['userId'];
        data['loan_type'] = data['loanType'];
        data['application_date'] = data['applicationDate'];

        // Normalize status for UI (pending_approval -> pending)
        final rawStatus = data['status']?.toString().toLowerCase() ?? '';
        if (rawStatus.contains('pending')) {
          data['status'] = 'pending';
        }
      }

      return {
        'success': isSuccess,
        'data': data,
        'message': jsonData['message'],
      };
    } catch (e) {
      _logger.e('Get loan application details error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Alias for getPendingVoteItems for consistency
  static Future<Map<String, dynamic>> getPendingVotingItems({
    String? kikobaId,
    String? type,
  }) => getPendingVoteItems(kikobaId: kikobaId, type: type);

  // ========== Membership Join Request APIs ==========

  /// Create a membership join request (requires voting)
  /// POST /api/membership-request
  /// This creates a request for someone to join the kikoba that requires voting
  static Future<Map<String, dynamic>> createMembershipJoinRequest({
    required String userId,
    required String userName,
    required String phone,
    String? role, // Not used by backend but kept for compatibility
    String? reason, // Not used by backend but kept for compatibility
  }) async {
    _logger.i('Creating membership join request for: $userName ($phone)');
    try {
      // Backend uses different field names
      final body = {
        'visitedKikobaId': DataStore.currentKikobaId,
        'currentUserId': userId,
        'currentUserName': userName,
        'mobileNumber': phone,
      };

      _logger.d('Membership join request body: $body');

      final response = await http.post(
        Uri.parse('${_baseUrl}membership-request'),
        body: body, // Backend expects form data, not JSON
      ).timeout(const Duration(seconds: 30));

      _logger.d('Membership join response: ${response.statusCode} - ${response.body}');

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200 || response.statusCode == 201),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
        'statusCode': response.statusCode,
      };
    } catch (e) {
      _logger.e('Create membership join request error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get pending membership join requests for a kikoba
  /// GET /api/kikoba/{kikobaId}/membership-requests
  static Future<Map<String, dynamic>> getPendingMembershipRequests({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    _logger.i('Getting pending membership requests for kikoba: $kId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}kikoba/$kId/membership-requests'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get pending membership requests error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Get details of a single membership join request
  /// GET /api/membership-request/{requestId}
  static Future<Map<String, dynamic>> getMembershipRequestDetails({
    required String requestId,
  }) async {
    _logger.i('Getting membership request details: $requestId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}membership-request/$requestId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
        'message': jsonData['message'] ?? '',
      };
    } catch (e) {
      _logger.e('Get membership request details error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Vote on a membership request (legacy endpoint - prefer castVote)
  /// POST /api/membership-request/{requestId}/vote
  static Future<Map<String, dynamic>> voteOnMembershipRequest({
    required String requestId,
    required String vote,
    String? comment,
  }) async {
    _logger.i('Voting on membership request: $requestId with vote: $vote');
    try {
      final body = {
        'voter_id': DataStore.currentUserId,
        'vote': vote,
        if (comment != null) 'comment': comment,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}membership-request/$requestId/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Vote on membership request error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========== Membership Removal APIs ==========

  /// Get membership removal types
  /// GET /api/membership-removal-types
  static Future<Map<String, dynamic>> getMembershipRemovalTypes() async {
    _logger.i('Getting membership removal types');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}membership-removal-types'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get removal types error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Create membership removal request
  /// POST /api/membership-removals
  static Future<Map<String, dynamic>> createMembershipRemovalRequest({
    required String targetMemberId,
    required String removalType,
    required String reason,
    String? evidence,
  }) async {
    _logger.i('Creating membership removal request for: $targetMemberId');
    try {
      final body = {
        'requested_by': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        'member_id': targetMemberId, // Backend uses member_id not target_member_id
        'removal_type': removalType, // voluntary|disciplinary|inactive|deceased|other
        'reason': reason, // min 10 chars
        if (evidence != null) 'evidence': evidence,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}membership-removals'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200 || response.statusCode == 201),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Create removal request error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get pending membership removal requests
  /// GET /api/membership-removals/kikoba/{kikobaId}/pending?user_id={userId}
  static Future<Map<String, dynamic>> getPendingMembershipRemovals({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    final userId = DataStore.currentUserId;
    _logger.i('Getting pending removal requests for kikoba: $kId');
    try {
      final uri = Uri.parse('${_baseUrl}membership-removals/kikoba/$kId/pending').replace(
        queryParameters: {
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get pending removals error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  // ========== Expense Request APIs ==========

  /// Get expense categories
  /// GET /api/expense-categories
  static Future<Map<String, dynamic>> getExpenseCategories() async {
    _logger.i('Getting expense categories');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}expense-categories'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get expense categories error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Create expense request
  /// POST /api/expense-requests
  static Future<Map<String, dynamic>> createExpenseRequest({
    required String category,
    required double amount,
    required String title,
    required String description,
    required String payeeName,
    String? currency,
    String? justification,
    String? payeeAccount,
    String? payeeBank,
    String? payeePhone,
    bool? isBudgeted,
    String? budgetLine,
    List<String>? attachments,
  }) async {
    _logger.i('Creating expense request: $category - $amount');
    try {
      final body = {
        'requested_by': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        'category': category,
        'amount': amount,
        'title': title, // REQUIRED
        'description': description, // min 10 chars
        'payee_name': payeeName, // REQUIRED
        if (currency != null) 'currency': currency,
        if (justification != null) 'justification': justification,
        if (payeeAccount != null) 'payee_account': payeeAccount,
        if (payeeBank != null) 'payee_bank': payeeBank,
        if (payeePhone != null) 'payee_phone': payeePhone,
        if (isBudgeted != null) 'is_budgeted': isBudgeted,
        if (budgetLine != null) 'budget_line': budgetLine,
        if (attachments != null && attachments.isNotEmpty) 'attachments': attachments,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}expense-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200 || response.statusCode == 201),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Create expense request error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Mark expense as paid
  /// POST /api/expense-requests/{requestId}/pay
  static Future<Map<String, dynamic>> markExpensePaid({
    required String requestId,
    required String paymentMethod,
    String? receiptNumber,
  }) async {
    _logger.i('Marking expense as paid: $requestId');
    try {
      final body = {
        'paid_by': DataStore.currentUserId,
        'payment_method': paymentMethod,
        'payment_date': DateTime.now().toIso8601String(),
        if (receiptNumber != null) 'receipt_number': receiptNumber,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}expense-requests/$requestId/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Mark expense paid error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========== Proxy Mchango APIs ==========

  /// Get mchango types for proxy contributions
  /// GET /api/proxy-mchango-types
  static Future<Map<String, dynamic>> getProxyMchangoTypes() async {
    _logger.i('Getting proxy mchango types');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}proxy-mchango-types'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get proxy mchango types error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Create proxy mchango (contribution on behalf of another)
  /// POST /api/proxy-mchango
  static Future<Map<String, dynamic>> createProxyMchango({
    required String beneficiaryId,
    required String beneficiaryName, // REQUIRED
    required String mchangoType,
    required double targetAmount, // Backend uses target_amount not amount
    required String reason, // min 10 chars
    required String deadline, // REQUIRED - format: YYYY-MM-DD
    String? beneficiaryPhone,
    String? description,
    double? minimumContribution,
  }) async {
    _logger.i('Creating proxy mchango for: $beneficiaryId');
    try {
      final body = {
        'requested_by': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        'beneficiary_id': beneficiaryId,
        'beneficiary_name': beneficiaryName, // REQUIRED
        'mchango_type': mchangoType,
        'target_amount': targetAmount, // Backend uses target_amount
        'reason': reason, // min 10 chars
        'deadline': deadline, // REQUIRED
        if (beneficiaryPhone != null) 'beneficiary_phone': beneficiaryPhone,
        if (description != null) 'description': description,
        if (minimumContribution != null) 'minimum_contribution': minimumContribution,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}proxy-mchango'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200 || response.statusCode == 201),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Create proxy mchango error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ========== Fine Approval APIs ==========

  /// Get fine types
  /// GET /api/fine-approval-types
  static Future<Map<String, dynamic>> getFineApprovalTypes() async {
    _logger.i('Getting fine approval types');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}fine-approval-types'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get fine types error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Create fine approval request
  /// POST /api/fine-approvals
  static Future<Map<String, dynamic>> createFineApprovalRequest({
    required String memberId,
    required String fineType,
    required double amount,
    required String reason,
  }) async {
    _logger.i('Creating fine approval for: $memberId - $fineType');
    try {
      final body = {
        'requested_by': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        'member_id': memberId,
        'fine_type': fineType,
        'amount': amount,
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}fine-approvals'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200 || response.statusCode == 201),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Create fine approval error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calculate fine amount
  /// POST /api/fine-approvals/calculate
  static Future<Map<String, dynamic>> calculateFine({
    required String memberId,
    required String fineType,
    String? relatedId, // e.g., loan_id for loan fines
  }) async {
    _logger.i('Calculating fine for: $memberId - $fineType');
    try {
      final body = {
        'kikoba_id': DataStore.currentKikobaId,
        'member_id': memberId,
        'fine_type': fineType,
        if (relatedId != null) 'related_id': relatedId,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}fine-approvals/calculate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Calculate fine error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Mark fine as paid
  /// POST /api/fine-approvals/{requestId}/pay
  static Future<Map<String, dynamic>> markFinePaid({
    required String requestId,
    required String paymentMethod,
  }) async {
    _logger.i('Marking fine as paid: $requestId');
    try {
      final body = {
        'paid_by': DataStore.currentUserId,
        'received_by': DataStore.currentUserId,
        'payment_method': paymentMethod,
        'payment_date': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}fine-approvals/$requestId/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Mark fine paid error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Waive fine
  /// POST /api/fine-approvals/{requestId}/waive
  static Future<Map<String, dynamic>> waiveFine({
    required String requestId,
    required String reason,
  }) async {
    _logger.i('Waiving fine: $requestId');
    try {
      final body = {
        'waived_by': DataStore.currentUserId,
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}fine-approvals/$requestId/waive'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Waive fine error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get unpaid fines for a member
  /// GET /api/fine-approvals/kikoba/{kikobaId}/member/{memberId}/unpaid
  static Future<Map<String, dynamic>> getUnpaidFines({
    required String memberId,
    String? kikobaId,
  }) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    _logger.i('Getting unpaid fines for member: $memberId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}fine-approvals/kikoba/$kId/member/$memberId/unpaid'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get unpaid fines error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  // ========== Loan Application APIs (Voting Flow) ==========

  /// Simplified loan application request - wraps submitLoanApplication
  /// POST /api/submitLoanApplication
  static Future<Map<String, dynamic>> createLoanApplicationRequest({
    required String loanProductId,
    required double amount,
    required int repaymentPeriod,
    required String purpose,
    String? guarantorId,
    String? collateralDescription,
  }) async {
    _logger.i('Creating loan application: $amount for $purpose');

    // Build the application structure expected by submitLoanApplication
    final application = {
      'loanProduct': {
        'id': loanProductId,
      },
      'loanDetails': {
        'principalAmount': amount,
        'tenure': repaymentPeriod,
        'tenureType': 'months',
        'purpose': purpose,
        if (collateralDescription != null) 'collateral': collateralDescription,
      },
      if (guarantorId != null) 'guarantors': [
        {'userId': guarantorId}
      ],
      'metadata': {
        'source': 'mobile_app',
        'kikobaId': DataStore.currentKikobaId,
        'userId': DataStore.currentUserId,
      },
    };

    final result = await submitLoanApplication(application);

    if (result == null) {
      return {'success': false, 'message': 'Ombi la mkopo limeshindwa kutumwa'};
    }

    return {
      'success': result['status'] == 'success' || result['success'] == true,
      'message': result['message'] ?? '',
      'data': result['data'],
    };
  }

  /// Get pending loan applications for voting
  /// GET /api/loan-applications/kikoba/{kikobaId}/pending?user_id={userId}
  static Future<Map<String, dynamic>> getPendingLoanApplications({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    final userId = DataStore.currentUserId;
    _logger.i('Getting pending loan applications for kikoba: $kId');
    try {
      final uri = Uri.parse('${_baseUrl}loan-applications/kikoba/$kId/pending').replace(
        queryParameters: {
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
        'pagination': jsonData['pagination'],
      };
    } catch (e) {
      _logger.e('Get pending loan applications error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  // ========== Akiba Withdrawal APIs (Voting Flow) ==========

  /// Akiba withdrawal request - wraps requestAkibaWithdrawal
  /// POST /api/akiba/withdrawal
  static Future<Map<String, dynamic>> createAkibaWithdrawalRequest({
    required double amount,
    required String reason,
    required String destinationType, // 'bank' or 'mobile_money'
    required String destinationAccount,
    required String destinationName,
    String? destinationFspId,
    String? destinationBankName,
  }) async {
    _logger.i('Creating akiba withdrawal request: $amount');

    final result = await requestAkibaWithdrawal(
      userId: DataStore.currentUserId ?? '',
      kikobaId: DataStore.currentKikobaId ?? '',
      amount: amount,
      destinationType: destinationType,
      destinationAccount: destinationAccount,
      destinationFspId: destinationFspId ?? '',
      destinationName: destinationName,
      destinationBankName: destinationBankName,
      description: reason,
    );

    if (result == null) {
      return {'success': false, 'message': 'Ombi la kutoa akiba limeshindwa kutumwa'};
    }

    return {
      'success': result['status'] == 'success' || result['success'] == true,
      'message': result['message'] ?? '',
      'data': result['data'],
      'requires_approval': result['requires_approval'] ?? true,
    };
  }

  /// Get pending akiba withdrawals for voting
  /// GET /api/akiba-withdrawals/kikoba/{kikobaId}/pending?user_id={userId}
  static Future<Map<String, dynamic>> getPendingAkibaWithdrawals({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    final userId = DataStore.currentUserId;
    _logger.i('Getting pending akiba withdrawals for kikoba: $kId');
    try {
      final uri = Uri.parse('${_baseUrl}akiba-withdrawals/kikoba/$kId/pending').replace(
        queryParameters: {
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
        'pagination': jsonData['pagination'],
      };
    } catch (e) {
      _logger.e('Get pending akiba withdrawals error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  // ========== Mchango Request APIs (Voting Flow) ==========

  /// Mchango request - wraps createMchango
  /// POST /api/mchango
  static Future<Map<String, dynamic>> createMchangoRequest({
    required String title,
    required String description,
    required double targetAmount,
    required double amountPerPerson,
    required String deadline,
    String? beneficiaryId,
    String? beneficiaryName,
  }) async {
    _logger.i('Creating mchango request: $title');

    final result = await createMchango(
      ainayaMchango: title,
      maelezo: description,
      tarehe: deadline,
      targetAmount: targetAmount,
      amountPerPerson: amountPerPerson,
    );

    if (result == null) {
      return {'success': false, 'message': 'Ombi la mchango limeshindwa kutumwa'};
    }

    return {
      'success': result['success'] == true || result['status'] == 'success',
      'message': result['message'] ?? '',
      'data': result['data'],
    };
  }

  /// Get pending mchango requests for voting
  /// GET /api/mchango-requests/kikoba/{kikobaId}/pending?user_id={userId}
  static Future<Map<String, dynamic>> getPendingMchangoRequests({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    final userId = DataStore.currentUserId;
    _logger.i('Getting pending mchango requests for kikoba: $kId');
    try {
      final uri = Uri.parse('${_baseUrl}mchango-requests/kikoba/$kId/pending').replace(
        queryParameters: {
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
        'pagination': jsonData['pagination'],
      };
    } catch (e) {
      _logger.e('Get pending mchango requests error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  // ========== General Voting Case APIs ==========

  /// Create a general voting case
  /// POST /api/voting-cases
  ///
  /// [votingType] - 'yes_no' (default) or 'multiple_choice'
  /// [options] - Required if votingType is 'multiple_choice' (2-10 options)
  /// [minimumVotes] - Override kikoba default minimum votes
  /// [approvalThreshold] - Override default threshold (1-100 percentage)
  static Future<Map<String, dynamic>> createVotingCase({
    required String title,
    required String description,
    String? category, // general|policy|event|financial|membership|other
    String? votingType, // yes_no|multiple_choice
    List<String>? options, // Required for multiple_choice (2-10 options)
    int? minimumVotes, // Override kikoba default
    double? approvalThreshold, // 1-100 percentage
    String? deadline, // Format: YYYY-MM-DD
  }) async {
    _logger.i('Creating voting case: $title (type: ${votingType ?? 'yes_no'})');
    try {
      final body = {
        'created_by': DataStore.currentUserId,
        'kikoba_id': DataStore.currentKikobaId,
        'title': title,
        'description': description,
        if (category != null) 'category': category,
        if (votingType != null) 'voting_type': votingType,
        if (options != null && options.isNotEmpty) 'options': options,
        if (minimumVotes != null) 'minimum_votes': minimumVotes,
        if (approvalThreshold != null) 'approval_threshold': approvalThreshold,
        if (deadline != null) 'deadline': deadline,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}voting-cases'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200 || response.statusCode == 201),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Create voting case error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Vote on a multiple choice option
  /// POST /api/voting-cases/{caseId}/vote-option
  static Future<Map<String, dynamic>> voteOnVotingCaseOption({
    required String caseId,
    required String option,
  }) async {
    _logger.i('Voting on option "$option" for case: $caseId');
    try {
      final body = {
        'voter_id': DataStore.currentUserId,
        'option': option,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}voting-cases/$caseId/vote-option'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Vote on option error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get pending voting cases for a kikoba
  /// GET /api/voting-cases/kikoba/{kikobaId}/pending?user_id={userId}
  static Future<Map<String, dynamic>> getPendingVotingCases({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    final userId = DataStore.currentUserId;
    _logger.i('Getting pending voting cases for kikoba: $kId');
    try {
      final uri = Uri.parse('${_baseUrl}voting-cases/kikoba/$kId/pending').replace(
        queryParameters: {
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
        'pagination': jsonData['pagination'],
      };
    } catch (e) {
      _logger.e('Get pending voting cases error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Close a voting case (admin only)
  /// POST /api/voting-cases/{caseId}/close
  static Future<Map<String, dynamic>> closeVotingCase({
    required String caseId,
    String? resolution,
  }) async {
    _logger.i('Closing voting case: $caseId');
    try {
      final body = {
        'closed_by': DataStore.currentUserId,
        if (resolution != null) 'resolution': resolution,
      };

      final response = await http.post(
        Uri.parse('${_baseUrl}voting-cases/$caseId/close'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'message': jsonData['message'] ?? '',
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Close voting case error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get voting case categories
  /// GET /api/voting-case-categories
  static Future<Map<String, dynamic>> getVotingCaseCategories() async {
    _logger.i('Getting voting case categories');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}voting-case-categories'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
      };
    } catch (e) {
      _logger.e('Get voting case categories error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Get all voting cases for a kikoba
  /// GET /api/voting-cases/kikoba/{kikobaId}
  static Future<Map<String, dynamic>> getVotingCases({String? kikobaId}) async {
    final kId = kikobaId ?? DataStore.currentKikobaId;
    _logger.i('Getting all voting cases for kikoba: $kId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}voting-cases/kikoba/$kId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'] ?? [],
        'pagination': jsonData['pagination'],
      };
    } catch (e) {
      _logger.e('Get voting cases error: $e');
      return {'success': false, 'data': [], 'message': e.toString()};
    }
  }

  /// Get specific voting case details
  /// GET /api/voting-cases/{caseId}
  static Future<Map<String, dynamic>> getVotingCaseDetails({required String caseId}) async {
    _logger.i('Getting voting case details: $caseId');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}voting-cases/$caseId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      final jsonData = jsonDecode(response.body);
      return {
        'success': jsonData['success'] ?? (response.statusCode == 200),
        'data': jsonData['data'],
      };
    } catch (e) {
      _logger.e('Get voting case details error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<String> ombaMchango(String ainayaMchango, String maelezo, String tarehe, String targetAmount, String amountPerPerson) async {
    logger.i("Requesting contribution...");

    try {
      final Map<String, dynamic> body = {
        'userName': DataStore.currentUserName,
        'KikobaId': DataStore.currentKikobaId,
        'currentUserId': DataStore.currentUserId,
        'mobileNumber': DataStore.userNumber,
        'ainayaMchango': ainayaMchango,
        'maelezo': maelezo,
        'tarehe': tarehe,
        'targetAmount': targetAmount,
        'amountPerPerson': amountPerPerson
      };

      logger.d("Contribution request body: $body");

      final response = await http.post(
        Uri.parse("${_baseUrl}mchango"),
        body: body,
      );

      logger.d("Contribution response: ${response.body}");

      return response.body;
    } catch (e, stacktrace) {
      logger.e("Requesting contribution failed $e");
      return "error";
    }
  }



  static Future<String> submitOTPx(String otp) async {
    logger.i("Submitting OTP...");

    try {
      final Map<String, dynamic> body = {
        'otp': otp,
        'currentUserId': DataStore.currentUserId,
      };

      logger.d("Submit OTP body: $body");

      final response = await http.post(
        Uri.parse("${_baseUrl}submit-otp"),
        body: body,
      );

      logger.d("Submit OTP response: ${response.body}");

      return response.body;
    } catch (e, stacktrace) {
      logger.e("Submitting OTP failed $e");
      return "error";
    }
  }





  static Future<String> prepareDevicex() async {
    final url = "${baseUrl}status"; // Health check endpoint
    logger.i("Preparing device, URL: $url");

    try {
      final res = await http.get(Uri.parse(url), headers: {"Accept": "application/json"});

      logger.i("prepareDevice Response Status: ${res.statusCode}");
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        logger.i("prepareDevice Response Body: ${res.body}");
        return res.body;
      }
      logger.w("prepareDevice failed: ${res.statusCode}");
      return "Error: Failed to prepare device";
    } catch (e, st) {
      logger.e("Error in prepareDevice", error: e, stackTrace: st);
      return "Error: Exception during device preparation";
    }
  }

  Future<List<vicoba>> getData2xpx() async {
    final url = "${baseUrl}vicoba?userId=${DataStore.currentUserId ?? ''}";
    logger.i("Getting Vikundi, URL: $url");

    try {
      final res = await http.get(Uri.parse(url), headers: {"Accept": "application/json"});
      logger.i("getData2xp Response Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = (data["vicoba"] as List)
            .map<vicoba>((json) => vicoba.fromJson(json))
            .toList();

        logger.i("Vikundi List Size: ${list.length}");
        return list;
      } else {
        logger.w("getData2xp failed: ${res.statusCode}");
        return [];
      }
    } catch (e, st) {
      logger.e("Error in getData2xp", error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<vicoba>> getPosts() async {
    logger.i("Fetching posts...");

    try {
      final res = await http.get(Uri.parse("${baseUrl}posts")); // Assuming this was meant to fetch posts

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as List;
        final posts = body.map((item) => vicoba.fromJson(item)).toList();
        logger.i("Fetched ${posts.length} posts");
        return posts;
      } else {
        logger.w("getPosts failed: ${res.statusCode}");
        return [];
      }
    } catch (e, st) {
      logger.e("Error in getPosts", error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Kikoba>> getKikoba() async {
    final url = "${baseUrl}kikoba/${DataStore.visitedKikobaId}";
    logger.i("Fetching Kikoba, URL: $url");

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as List;
        final posts = body.map((item) => Kikoba.fromJson(item)).toList();
        logger.i("Fetched ${posts.length} Kikoba entries");
        return posts;
      } else {
        logger.w("getKikoba failed: ${res.statusCode}");
        return [];
      }
    } catch (e, st) {
      logger.e("Error in getKikoba", error: e, stackTrace: st);
      return [];
    }
  }

  static Future<String> membershipRequestx() async {
    const url = "${baseUrl}membership-request";
    logger.i("Sending membership request...");

    try {
      final body = {
        'KikobaId': DataStore.currentKikobaId,
        'currentUserId': DataStore.currentUserId,
        'mobileNumber': DataStore.userNumber,
        'visitedKikobaId': DataStore.visitedKikobaId,
        'currentUserName': DataStore.currentUserName,
      };
      logger.i("Request Body: $body");

      final response = await http.post(Uri.parse(url), body: body);
      logger.i("Response: ${response.body}");

      return response.body;
    } catch (e, st) {
      logger.e("Error in membershipRequest", error: e, stackTrace: st);
      return "Error: Membership request failed";
    }
  }

  Future<List<Katiba>> getKatiba() async {
    final url = "${baseUrl}kikoba/${DataStore.currentKikobaId}/katiba";
    logger.i("Fetching Katiba, URL: $url");

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as List;
        final posts = body.map((item) => Katiba.fromJson(item)).toList();
        logger.i("Fetched ${posts.length} Katiba entries");
        return posts;
      } else {
        logger.w("getKatiba failed: ${res.statusCode}");
        return [];
      }
    } catch (e, st) {
      logger.e("Error in getKatiba", error: e, stackTrace: st);
      return [];
    }
  }

  // --- Generalized save method using PUT with JSON body ---
  static Future<String> _saveKatibaSetting(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse("${baseUrl}katiba/$endpoint");
    logger.i("Saving Katiba Setting, URL: $url, Body: $body");

    try {
      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      logger.i("Save Response: ${res.statusCode} - ${res.body}");

      if (res.statusCode == 200) {
        return res.body;
      } else {
        logger.w("Save failed: ${res.statusCode}");
        return "Error: Save failed - ${res.statusCode}";
      }
    } catch (e, st) {
      logger.e("Error during saveKatibaSetting", error: e, stackTrace: st);
      return "Error: Save setting exception";
    }
  }

  /// Convert status: '0' -> 'inactive', '1' or other -> 'active'
  static String _toStatusString(String status) {
    return status == '1' ? 'inactive' : 'active';
  }

  static Future<String> saveKiingilio(String kiingilio, String status) async {
    _logger.i('Saving Kiingilio: amount=$kiingilio, status=$status');
    final statusValue = _toStatusString(status);

    return _saveKatibaSetting('kiingilio', {
      'kikobaId': DataStore.currentKikobaId,
      'amount': int.tryParse(kiingilio) ?? 0,
      'status': statusValue,
      'kiingilioStatus': statusValue,
    });
  }

  static Future<String> saveAda(String ada, String status) async {
    _logger.i('Saving Ada: amount=$ada, status=$status');
    final statusValue = _toStatusString(status);

    return _saveKatibaSetting('ada', {
      'kikobaId': DataStore.currentKikobaId,
      'amount': int.tryParse(ada) ?? 0,
      'status': statusValue,
      'adaStatus': statusValue,
    });
  }

  static Future<String> saveHisa(String hisa, String status) async {
    _logger.i('Saving Hisa: amount=$hisa, status=$status');
    final statusValue = _toStatusString(status);

    return _saveKatibaSetting('hisa', {
      'kikobaId': DataStore.currentKikobaId,
      'amount': int.tryParse(hisa) ?? 0,
      'status': statusValue,
      'HisaStatus': statusValue,
    });
  }

  /// Save fine with fixed amount (default)
  /// fineType: vikao, ada, hisa, michango (which fine)
  /// fine_type: fixed or percentage (how it's charged)
  static Future<String> saveFainiVikao(String faini, String status, {String fineCalculationType = 'fixed'}) async {
    _logger.i('Saving Faini Vikao: amount=$faini, status=$status, type=$fineCalculationType');

    return _saveKatibaSetting('fines', {
      'kikobaId': DataStore.currentKikobaId,
      'fineType': 'vikao',
      'fine_type': fineCalculationType,  // 'fixed' or 'percentage'
      'amount': int.tryParse(faini) ?? 0,
      'status': _toStatusString(status),
    });
  }

  static Future<String> saveFainiAda(String faini, String status, {String fineCalculationType = 'fixed'}) async {
    _logger.i('Saving Faini Ada: amount=$faini, status=$status, type=$fineCalculationType');

    return _saveKatibaSetting('fines', {
      'kikobaId': DataStore.currentKikobaId,
      'fineType': 'ada',
      'fine_type': fineCalculationType,  // 'fixed' or 'percentage'
      'amount': int.tryParse(faini) ?? 0,
      'status': _toStatusString(status),
    });
  }

  static Future<String> saveFainiHisa(String faini, String status, {String fineCalculationType = 'fixed'}) async {
    _logger.i('Saving Faini Hisa: amount=$faini, status=$status, type=$fineCalculationType');

    return _saveKatibaSetting('fines', {
      'kikobaId': DataStore.currentKikobaId,
      'fineType': 'hisa',
      'fine_type': fineCalculationType,  // 'fixed' or 'percentage'
      'amount': int.tryParse(faini) ?? 0,
      'status': _toStatusString(status),
    });
  }

  static Future<String> saveFainiMichango(String faini, String status, {String fineCalculationType = 'fixed'}) async {
    _logger.i('Saving Faini Michango: amount=$faini, status=$status, type=$fineCalculationType');

    return _saveKatibaSetting('fines', {
      'kikobaId': DataStore.currentKikobaId,
      'fineType': 'michango',
      'fine_type': fineCalculationType,  // 'fixed' or 'percentage'
      'amount': int.tryParse(faini) ?? 0,
      'status': _toStatusString(status),
    });
  }

  // --- Katiba Change Request (Voteable) ---

  /// Create a katiba change request that requires voting
  /// Valid change_type values:
  /// - kiingilio, ada, hisa, akiba, riba
  /// - faini_vikao, faini_ada, faini_hisa, faini_michango
  /// - loan_product_create, loan_product_update, loan_limits, meeting_config
  /// changeData: The proposed new values
  /// description: Human readable description of the change
  static Future<Map<String, dynamic>> requestKatibaChange({
    required String changeType,
    required Map<String, dynamic> changeData,
    required String description,
  }) async {
    _logger.i('╔════════════════════════════════════════════════════════════');
    _logger.i('║ [requestKatibaChange] START');
    _logger.i('╚════════════════════════════════════════════════════════════');
    _logger.d('[requestKatibaChange] Input parameters:');
    _logger.d('  - changeType: $changeType');
    _logger.d('  - changeData: $changeData');
    _logger.d('  - description: $description');

    // Map old change type format to new API format
    String apiChangeType = changeType;
    if (changeType.startsWith('katiba_')) {
      apiChangeType = changeType.replaceFirst('katiba_', '');
      _logger.d('[requestKatibaChange] Stripped "katiba_" prefix: $changeType -> $apiChangeType');
    }

    _logger.i('[requestKatibaChange] ➤ Calling createKatibaChangeRequest with:');
    _logger.i('  - changeType (API format): $apiChangeType');
    _logger.i('  - proposedValue: $changeData');
    _logger.i('  - reason: $description');

    // Use the new unified voting API
    final result = await createKatibaChangeRequest(
      changeType: apiChangeType,
      proposedValue: changeData,
      reason: description,
    );

    _logger.d('[requestKatibaChange] Raw result from createKatibaChangeRequest: $result');

    // Return in compatible format
    final formattedResult = {
      'success': result['success'] ?? false,
      'message': result['message'] ?? (result['success'] == true
          ? 'Ombi limetumwa kwa kupiga kura'
          : 'Tatizo limetokea'),
      'caseId': result['data']?['request_id'] ?? result['data']?['id'],
      'data': result['data'],
    };

    _logger.i('[requestKatibaChange] Formatted result:');
    _logger.i('  - success: ${formattedResult['success']}');
    _logger.i('  - message: ${formattedResult['message']}');
    _logger.i('  - caseId: ${formattedResult['caseId']}');
    _logger.i('[requestKatibaChange] ════════════════ END ════════════════');

    return formattedResult;
  }

  /// Helper methods for specific katiba change requests
  static Future<Map<String, dynamic>> requestKiingilioChange(String amount, String status) async {
    final statusValue = _toStatusString(status);
    final amountNum = int.tryParse(amount) ?? 0;

    return requestKatibaChange(
      changeType: 'katiba_kiingilio',
      changeData: {
        'amount': amountNum,
        'status': statusValue,
      },
      description: statusValue == 'active'
          ? 'Kubadili kiingilio kuwa TZS ${_formatAmount(amountNum)}'
          : 'Kuzima kiingilio',
    );
  }

  static Future<Map<String, dynamic>> requestAdaChange(String amount, String status) async {
    final statusValue = _toStatusString(status);
    final amountNum = int.tryParse(amount) ?? 0;

    return requestKatibaChange(
      changeType: 'katiba_ada',
      changeData: {
        'amount': amountNum,
        'status': statusValue,
      },
      description: statusValue == 'active'
          ? 'Kubadili ada kuwa TZS ${_formatAmount(amountNum)} kwa mwezi'
          : 'Kuzima ada',
    );
  }

  static Future<Map<String, dynamic>> requestHisaChange(String amount, String status) async {
    final statusValue = _toStatusString(status);
    final amountNum = int.tryParse(amount) ?? 0;

    return requestKatibaChange(
      changeType: 'katiba_hisa',
      changeData: {
        'amount': amountNum,
        'status': statusValue,
      },
      description: statusValue == 'active'
          ? 'Kubadili hisa kuwa TZS ${_formatAmount(amountNum)} kwa mwezi'
          : 'Kuzima hisa',
    );
  }

  static Future<Map<String, dynamic>> requestRibaChange(String rate, String status) async {
    final statusValue = _toStatusString(status);
    final rateNum = double.tryParse(rate) ?? 0;

    return requestKatibaChange(
      changeType: 'katiba_riba',
      changeData: {
        'rate': rateNum,
        'status': statusValue,
      },
      description: statusValue == 'active'
          ? 'Kubadili riba kuwa $rateNum% kwa mwezi'
          : 'Kuzima riba',
    );
  }

  static Future<Map<String, dynamic>> requestFainiChange({
    required String fineCategory, // vikao, ada, hisa, michango
    required String amount,
    required String status,
    String fineCalculationType = 'fixed',
  }) async {
    _logger.i('╔════════════════════════════════════════════════════════════');
    _logger.i('║ [requestFainiChange] START');
    _logger.i('╚════════════════════════════════════════════════════════════');
    _logger.d('[requestFainiChange] Input parameters:');
    _logger.d('  - fineCategory: $fineCategory');
    _logger.d('  - amount: $amount');
    _logger.d('  - status: $status');
    _logger.d('  - fineCalculationType: $fineCalculationType');

    final statusValue = _toStatusString(status);
    final amountNum = int.tryParse(amount) ?? 0;

    _logger.d('[requestFainiChange] Converted values:');
    _logger.d('  - statusValue: $statusValue (from _toStatusString)');
    _logger.d('  - amountNum: $amountNum (parsed int)');

    String fineLabel;
    switch (fineCategory) {
      case 'vikao':
        fineLabel = 'Vikao';
        break;
      case 'ada':
        fineLabel = 'Ada';
        break;
      case 'hisa':
        fineLabel = 'Hisa';
        break;
      case 'michango':
        fineLabel = 'Michango';
        break;
      default:
        fineLabel = fineCategory;
    }

    final changeData = {
      'fineCategory': fineCategory,
      'fineType': fineCalculationType,
      'amount': amountNum,
      'status': statusValue,
    };

    final description = statusValue == 'active'
        ? 'Kubadili faini ya $fineLabel kuwa ${fineCalculationType == 'percentage' ? '$amountNum%' : 'TZS ${_formatAmount(amountNum)}'}'
        : 'Kuzima faini ya $fineLabel';

    // Use faini_vikao, faini_ada, faini_hisa, faini_michango as change_type
    final changeType = 'faini_$fineCategory';

    _logger.i('[requestFainiChange] Calling requestKatibaChange with:');
    _logger.i('  - changeType: $changeType');
    _logger.i('  - changeData: $changeData');
    _logger.i('  - description: $description');

    final result = await requestKatibaChange(
      changeType: changeType,
      changeData: changeData,
      description: description,
    );

    _logger.i('[requestFainiChange] Result from requestKatibaChange: $result');
    _logger.i('[requestFainiChange] ════════════════ END ════════════════');

    return result;
  }

  static Future<Map<String, dynamic>> requestLoanProductChange({
    required String action, // create, update
    required Map<String, dynamic> productData,
    String? productId,
  }) async {
    _logger.i('╔════════════════════════════════════════════════════════════');
    _logger.i('║ [requestLoanProductChange] START');
    _logger.i('╚════════════════════════════════════════════════════════════');
    _logger.i('[requestLoanProductChange] ══════ INPUT PARAMETERS ══════');
    _logger.i('[requestLoanProductChange] Action: $action');
    _logger.i('[requestLoanProductChange] Product ID: $productId');
    _logger.i('[requestLoanProductChange] Product Data: $productData');
    _logger.i('[requestLoanProductChange] ══════════════════════════════');

    String description;
    String changeType;
    final productName = productData['name'] ?? 'Bidhaa';

    switch (action) {
      case 'create':
        changeType = 'loan_product_create';
        description = 'Kuongeza bidhaa mpya ya mkopo: $productName';
        _logger.i('[requestLoanProductChange] Action type: CREATE new loan product');
        break;
      case 'update':
        changeType = 'loan_product_update';
        description = 'Kubadili bidhaa ya mkopo: $productName';
        _logger.i('[requestLoanProductChange] Action type: UPDATE existing loan product (ID: $productId)');
        break;
      default:
        changeType = 'loan_product_update';
        description = 'Kubadili bidhaa ya mkopo';
        _logger.w('[requestLoanProductChange] Unknown action: $action, defaulting to update');
    }

    _logger.i('[requestLoanProductChange] ══════ PREPARED REQUEST ══════');
    _logger.i('[requestLoanProductChange] Change Type: $changeType');
    _logger.i('[requestLoanProductChange] Description: $description');
    _logger.i('[requestLoanProductChange] Current Kikoba ID: ${DataStore.currentKikobaId}');
    _logger.i('[requestLoanProductChange] Current User ID: ${DataStore.currentUserId}');

    final changeData = {
      'action': action,
      'productId': productId,
      ...productData,
    };
    _logger.i('[requestLoanProductChange] Change Data to send: $changeData');
    _logger.i('[requestLoanProductChange] ══════════════════════════════');

    _logger.i('[requestLoanProductChange] ➤ Calling requestKatibaChange...');

    final result = await requestKatibaChange(
      changeType: changeType,
      changeData: changeData,
      description: description,
    );

    _logger.i('[requestLoanProductChange] ══════ RESULT FROM requestKatibaChange ══════');
    _logger.i('[requestLoanProductChange] Success: ${result['success']}');
    _logger.i('[requestLoanProductChange] Message: ${result['message']}');
    _logger.i('[requestLoanProductChange] Case ID: ${result['caseId']}');
    _logger.i('[requestLoanProductChange] Full Result: $result');
    _logger.i('[requestLoanProductChange] ════════════════════════════════════════════');
    _logger.i('[requestLoanProductChange] ════════════════ END ════════════════');

    return result;
  }

  static String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // --- Payment related methods ---
  static Future<Map<String, dynamic>?> createPaymentIntent(
      String amount, String currency, String cardNumber, String expiryDate, String cardHolderName, String cvvCode) async {
    final url = "${baseUrl}payment";
    logger.i("Creating payment intent via Card");

    try {
      final body = {
        'amount': amount,
        'currency': currency,
        'paymentService': DataStore.paymentService,
        'paymentChanel': DataStore.paymentChanel,
        'paymentInstitution': DataStore.paymentInstitution,
        'KikobaId': DataStore.currentKikobaId,
        'currentUserId': DataStore.currentUserId,
        'mobileNumber': DataStore.userNumber,
        'PAN': cardNumber,
        'CVV': cvvCode,
        'expiringDate': expiryDate,
        'cardHolderName': cardHolderName,
        'paymentMethodTypes': 'card',
      };

      final res = await http.post(Uri.parse(url), body: body);
      logger.i("Payment Intent Response: ${res.body}");

      return jsonDecode(res.body);
    } catch (e, st) {
      logger.e("Error in createPaymentIntent", error: e, stackTrace: st);
      return null;
    }
  }

  static Future<String> createPaymentIntentMNOx(String amount, String currency, String userNumber, String userNumberMNO) async {
    final url = "${baseUrl}payment";
    logger.i("Creating payment intent via MNO");

    try {
      var paymentDistribution = DataStore.paymentService == "ada"
          ? DataStore.adaPaymentMap
          : DataStore.paymentService == "hisa"
          ? DataStore.adaPaymentMapx
          : ["1", "2"];

      final body = {
        'amount': DataStore.paymentAmount.toString(),
        'currency': currency,
        'paymentService': DataStore.paymentService,
        'paymentChanel': DataStore.paymentChanel,
        'paymentInstitution': DataStore.paymentInstitution,
        'KikobaId': DataStore.currentKikobaId,
        'currentUserId': DataStore.currentUserId,
        'paidServiceId': DataStore.paidServiceId,
        'personPaidId': DataStore.personPaidId,
        'mobileNumber': userNumber,
        'paymentDistribution': jsonEncode(paymentDistribution),
        'paymentMethodTypes': 'mno',
      };

      final res = await http.post(Uri.parse(url), body: body);
      logger.i("MNO Payment Response: ${res.body}");
      return res.body;
    } catch (e, st) {
      logger.e("Error in createPaymentIntentMNO", error: e, stackTrace: st);
      return "Error: Payment intent MNO failed";
    }
  }

  static Future<Map<String, dynamic>?> createPaymentIntentFromBank(String amount, String currency) async {
    final url = "${baseUrl}payment";
    logger.i("Creating payment intent via Bank");

    try {
      final body = {
        'amount': amount,
        'currency': currency,
        'paymentService': DataStore.paymentService,
        'paymentChanel': DataStore.paymentChanel,
        'paymentInstitution': DataStore.paymentInstitution,
        'KikobaId': DataStore.currentKikobaId,
        'currentUserId': DataStore.currentUserId,
        'mobileNumber': DataStore.userNumber,
        'payingBIN': DataStore.payingBIN,
        'payingBank': DataStore.payingBank,
        'payingAccount': DataStore.payingAccount,
        'paymentMethodTypes': 'bank',
      };

      final res = await http.post(Uri.parse(url), body: body);
      logger.i("Bank Payment Intent Response: ${res.body}");

      return jsonDecode(res.body);
    } catch (e, st) {
      logger.e("Error in createPaymentIntentFromBank", error: e, stackTrace: st);
      return null;
    }
  }




  /// Registers a new member to a kikoba
  /// Returns [RegisterMobileResponse] with parsed JSON data
  static Future<RegisterMobileResponse> registerMobileNo2(String mobileNo, String jina, String cheo) async {
    final random = Random();
    final mwalikwaId = 1000 + random.nextInt(9000);
    final String apiUrl = "${_baseUrl}register-mobile";

    try {
      _logger.i("Starting registration for mobileNo: $mobileNo");

      // Get device UDID
      final udid = await _getDeviceUdid();
      _logger.i("Device UDID: ${udid ?? 'not available'}");

      // Prepare request body
      final Map<String, dynamic> body = {
        'udid': udid ?? '',
        'mobileNo': mobileNo,
        'jina': jina,
        'KikobaId': DataStore.currentKikobaId ?? '',
        'currentUserId': DataStore.currentUserId ?? '',
        'cheo': cheo,
        'guestId': mwalikwaId.toString(),
      };

      _logger.i("Request body: $body");

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        body: body,
      ).timeout(const Duration(seconds: 15));

      _logger.i("HTTP response status: ${response.statusCode}");
      _logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final result = RegisterMobileResponse.fromJson(jsonData);
        _logger.i("Parsed response: $result");
        return result;
      } else {
        _logger.e("Server returned status: ${response.statusCode}");
        return RegisterMobileResponse.error("Server Error");
      }

    } on SocketException catch (e) {
      _logger.e("Network Error: $e");
      return RegisterMobileResponse.error("Network Error");
    } on TimeoutException catch (e) {
      _logger.e("Timeout Error: $e");
      return RegisterMobileResponse.error("Device Offline");
    } on FormatException catch (e) {
      _logger.e("JSON Parse Error: $e");
      return RegisterMobileResponse.error("Server Error");
    } catch (e) {
      _logger.e("Unexpected error: $e");
      return RegisterMobileResponse.error("Unexpected Error");
    }
  }

  static Future<String> savefaini_ada(String fainiAda, String fainiAdastatus) async {


    String saveKiingilioURL = "${_baseUrl}katiba/fine-ada?kikobaId=${DataStore.currentKikobaId}&amount=$fainiAda&faini_adaStatus=$fainiAdastatus";

    Response res = await get(Uri.parse(saveKiingilioURL));

    print("save faini_ada called");
    print(saveKiingilioURL);
    if (res.statusCode == 200) {
      print(res.body);

      return res.body;
    } else {
      throw "Unable to retrieve posts.";
    }
  }

  /// Updates the FCM token for the current user
  static Future<String> updateFCMToken(String fcmToken) async {
    String res = "error";
    try {
      final body = {
        'currentUserId': DataStore.currentUserId ?? '',
        'fcm_token': fcmToken,
      };

      logger.i('Update FCM Token Request: $body');

      final response = await http.post(
        Uri.parse('${_baseUrl}member/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      logger.i('Update FCM Token Response: ${response.body}');

      // Parse response to check for success
      try {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          res = 'success';
        } else {
          res = jsonResponse['message']?.toString() ?? response.body;
        }
      } catch (_) {
        res = response.body;
      }
    } catch (e) {
      logger.e('Error in updateFCMToken', error: e);
    }
    return res;
  }

  // ========== Letshego Bank Transfer APIs ==========

  /// Calculate transfer fees and routing (TISS/TIPS)
  static Future<Map<String, dynamic>> calculateTransferFees({
    required double amount,
    required String destinationFspId,
  }) async {
    logger.i('Calculating transfer fees for amount: $amount');
    try {
      final url = "${baseUrl}letshego/transfer/calculate";
      final body = {
        'amount': amount,
        'destination_fsp_id': destinationFspId,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Calculate fees response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          final data = jsonData['data'];
          return {
            'success': true,
            'amount': data['amount'],
            'fee': data['fee'],
            'total': data['total'],
            'currency': data['currency'],
            'routing_system': data['routing_system'], // TIPS or TISS
            'is_mobile_money': data['is_mobile_money'],
            'data': data,
          };
        } else {
          return {
            'success': false,
            'error': jsonData['message'] ?? 'Failed to calculate fees',
          };
        }
      } else {
        logger.e('Calculate fees failed: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to calculate fees',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      logger.e('Error calculating transfer fees', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Initiate bank transfer
  static Future<Map<String, dynamic>> initiateTransfer({
    required String kikobaId,
    required String userId,
    required String destinationAccount,
    required String destinationFspId,
    required String destinationName,
    required double amount,
    required String description,
    String? destinationBankName,
    String transferType = 'TRANSFER',
    String? referenceId,
    // Source account details (member's bank account)
    String? sourceAccount,
    String? sourceBankName,
    String? sourceFspId,
    // Direction: DEPOSIT (Member → Kikoba) or DISBURSEMENT (Kikoba → Member)
    String direction = 'DEPOSIT',
    // Control number for bill payment tracking
    String? controlNumber,
  }) async {
    logger.i('Initiating bank transfer of $amount');
    try {
      final url = "${baseUrl}letshego/transfer";

      final body = {
        'kikoba_id': kikobaId,
        'user_id': userId,
        'direction': direction,
        'destination_account': destinationAccount,
        'destination_fsp_id': destinationFspId,
        'destination_name': destinationName,
        'amount': amount,
        'description': description,
        'transfer_type': transferType,
      };

      // Optional destination fields
      if (destinationBankName != null && destinationBankName.isNotEmpty) {
        body['destination_bank_name'] = destinationBankName;
      }
      if (referenceId != null && referenceId.isNotEmpty) {
        body['reference_id'] = referenceId;
      }

      // Source account details (member's bank account)
      if (sourceAccount != null && sourceAccount.isNotEmpty) {
        body['source_account'] = sourceAccount;
      }
      if (sourceBankName != null && sourceBankName.isNotEmpty) {
        body['source_bank_name'] = sourceBankName;
      }
      if (sourceFspId != null && sourceFspId.isNotEmpty) {
        body['source_fsp_id'] = sourceFspId;
      }

      // Control number for bill payment tracking
      if (controlNumber != null && controlNumber.isNotEmpty) {
        body['control_number'] = controlNumber;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      logger.d('Initiate transfer response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          final data = jsonData['data'];
          return {
            'success': true,
            'payerRef': data['payer_ref'],
            'status': data['status'],
            'amount': data['amount'],
            'routing_system': data['routing_system'],
            'data': data,
            'message': jsonData['message'] ?? 'Transfer initiated successfully',
          };
        } else {
          return {
            'success': false,
            'error': jsonData['message'] ?? 'Failed to initiate transfer',
          };
        }
      } else {
        logger.e('Initiate transfer failed: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorData['message'] ?? errorData['error'] ?? 'Failed to initiate transfer',
            'statusCode': response.statusCode,
            'responseBody': response.body,
            'errorData': errorData,
          };
        } catch (e) {
          // If response body is not JSON
          return {
            'success': false,
            'error': 'Server error: ${response.statusCode}',
            'statusCode': response.statusCode,
            'responseBody': response.body,
          };
        }
      }
    } catch (e) {
      logger.e('Error initiating transfer', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get transfer status
  static Future<Map<String, dynamic>> getTransferStatus(String payerRef) async {
    logger.i('Getting transfer status for: $payerRef');
    try {
      final url = "${baseUrl}letshego/transfer/$payerRef/status";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Transfer status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          final data = jsonData['data'];
          return {
            'success': true,
            'payer_ref': data['payer_ref'],
            'status': data['status'], // PENDING, PROCESSING, COMPLETED, FAILED, REVERSED
            'amount': data['amount'],
            'currency': data['currency'],
            'payee_account': data['payee_account'],
            'payee_name': data['payee_name'],
            'payee_bank_name': data['payee_bank_name'],
            'description': data['description'],
            'transfer_type': data['transfer_type'],
            'transaction_id': data['transaction_id'],
            'initiated_at': data['initiated_at'],
            'completed_at': data['completed_at'],
            'failed_at': data['failed_at'],
            'error_message': data['error_message'],
            'data': data,
          };
        } else {
          return {
            'success': false,
            'error': jsonData['message'] ?? 'Failed to get transfer status',
          };
        }
      } else {
        logger.e('Get transfer status failed: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to get transfer status',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      logger.e('Error getting transfer status', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Reverse a transfer
  static Future<Map<String, dynamic>> reverseTransfer({
    required String payerRef,
    required String reason,
  }) async {
    logger.i('Reversing transfer: $payerRef');
    try {
      final url = "${baseUrl}letshego/transfer/$payerRef/reverse";
      final body = {
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Reverse transfer response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          final data = jsonData['data'];
          return {
            'success': true,
            'payer_ref': data['payer_ref'],
            'status': data['status'], // REVERSED
            'reason': data['reason'],
            'data': data,
            'message': jsonData['message'] ?? 'Transfer reversed successfully',
          };
        } else {
          return {
            'success': false,
            'error': jsonData['message'] ?? 'Failed to reverse transfer',
          };
        }
      } else {
        logger.e('Reverse transfer failed: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to reverse transfer',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      logger.e('Error reversing transfer', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // AKIBA WITHDRAWAL METHODS
  // ============================================================================

  /// Get member's akiba balance
  static Future<Map<String, dynamic>?> getAkibaBalance(String kikobaId, String userId) async {
    try {
      final url = '${_baseUrl}akiba/$kikobaId/withdrawal/balance?userId=$userId';
      logger.i('Getting akiba balance: $url');

      final response = await http.get(Uri.parse(url));
      logger.i('Balance response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e('Failed to get balance: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Error getting akiba balance', error: e);
      return null;
    }
  }

  /// Request akiba withdrawal
  static Future<Map<String, dynamic>?> requestAkibaWithdrawal({
    required String userId,
    required String kikobaId,
    required double amount,
    required String destinationType, // 'bank' or 'mobile_money'
    required String destinationAccount,
    required String destinationFspId,
    required String destinationName,
    String? destinationBankName,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'userId': userId,
        'kikobaId': kikobaId,
        'amount': amount.toString(),
        'destination_type': destinationType,
        'destination_account': destinationAccount,
        'destination_fsp_id': destinationFspId,
        'destination_name': destinationName,
      };

      if (destinationBankName != null) {
        body['destination_bank_name'] = destinationBankName;
      }
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      logger.i('Requesting akiba withdrawal: $body');

      final response = await http.post(
        Uri.parse('${_baseUrl}akiba/withdrawal'),
        body: body,
      );

      logger.i('Withdrawal request response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        logger.e('Withdrawal request failed: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to request withdrawal',
          'errors': errorData['errors'],
          'balance': errorData['balance'],
        };
      }
    } catch (e) {
      logger.e('Error requesting akiba withdrawal', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get withdrawal history
  static Future<Map<String, dynamic>?> getAkibaWithdrawalHistory({
    required String kikobaId,
    String? userId,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      String url = '${_baseUrl}akiba/$kikobaId/withdrawal/history?per_page=$perPage&page=$page';
      if (userId != null && userId.isNotEmpty) {
        url += '&userId=$userId';
      }

      logger.i('Getting withdrawal history: $url');

      final response = await http.get(Uri.parse(url));
      logger.i('Withdrawal history response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e('Failed to get withdrawal history: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Error getting withdrawal history', error: e);
      return null;
    }
  }

  /// Get withdrawal request status
  static Future<Map<String, dynamic>?> getWithdrawalStatus(String requestId) async {
    try {
      final url = '${_baseUrl}akiba/withdrawal/$requestId/status';
      logger.i('Getting withdrawal status: $url');

      final response = await http.get(Uri.parse(url));
      logger.i('Withdrawal status response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e('Failed to get withdrawal status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Error getting withdrawal status', error: e);
      return null;
    }
  }

  /// Get pending withdrawal requests (Admin only)
  static Future<Map<String, dynamic>?> getPendingWithdrawals(String kikobaId) async {
    try {
      final url = '${_baseUrl}akiba/$kikobaId/withdrawal/pending';
      logger.i('Getting pending withdrawals: $url');

      final response = await http.get(Uri.parse(url));
      logger.i('Pending withdrawals response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e('Failed to get pending withdrawals: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Error getting pending withdrawals', error: e);
      return null;
    }
  }

  /// Approve withdrawal request (Admin only)
  static Future<Map<String, dynamic>?> approveWithdrawal({
    required String requestId,
    required String approvedBy,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'approved_by': approvedBy,
      };

      logger.i('Approving withdrawal $requestId by $approvedBy');

      final response = await http.post(
        Uri.parse('${_baseUrl}akiba/withdrawal/$requestId/approve'),
        body: body,
      );

      logger.i('Approve withdrawal response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e('Failed to approve withdrawal: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to approve withdrawal',
        };
      }
    } catch (e) {
      logger.e('Error approving withdrawal', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Reject withdrawal request (Admin only)
  static Future<Map<String, dynamic>?> rejectWithdrawal({
    required String requestId,
    required String rejectedBy,
    String? reason,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'rejected_by': rejectedBy,
      };
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      logger.i('Rejecting withdrawal $requestId by $rejectedBy');

      final response = await http.post(
        Uri.parse('${_baseUrl}akiba/withdrawal/$requestId/reject'),
        body: body,
      );

      logger.i('Reject withdrawal response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e('Failed to reject withdrawal: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to reject withdrawal',
        };
      }
    } catch (e) {
      logger.e('Error rejecting withdrawal', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Update akiba withdrawal settings (Admin only)
  static Future<Map<String, dynamic>?> updateWithdrawalSettings({
    required String kikobaId,
    required bool requiresApproval,
    double? minWithdrawal,
    double? maxWithdrawal,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'kikobaId': kikobaId,
        'requires_approval': requiresApproval.toString(),
      };
      if (minWithdrawal != null) {
        body['min_withdrawal'] = minWithdrawal.toString();
      }
      if (maxWithdrawal != null) {
        body['max_withdrawal'] = maxWithdrawal.toString();
      }

      logger.i('Updating withdrawal settings: $body');

      final response = await http.put(
        Uri.parse('${_baseUrl}katiba/akiba-withdrawal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      logger.i('Update settings response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e('Failed to update settings: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Error updating withdrawal settings', error: e);
      return null;
    }
  }

  // ==================== Loan Products Management ====================

  /// Save/Create loan products to the backend (Bulk operation)
  static Future<bool> saveLoanProducts(List<dynamic> loanProducts) async {
    logger.i('💳 [POST /saveLoanProducts] Saving ${loanProducts.length} loan products');

    try {
      final url = Uri.parse('${baseUrl}saveLoanProducts');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'kikobaId': DataStore.currentKikobaId,
          'loanProducts': loanProducts,
        }),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        logger.i('✅ Loan products saved successfully');
        return data['success'] == true || data['status'] == 'success';
      } else {
        logger.e('Failed to save loan products: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error saving loan products', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get loan products from backend
  static Future<List<dynamic>?> getLoanProducts({String? kikobaId}) async {
    final targetKikobaId = kikobaId ?? DataStore.currentKikobaId;
    logger.i('💳 [GET /getLoanProducts] Fetching loan products for kikoba: $targetKikobaId');

    try {
      final url = Uri.parse('${baseUrl}getLoanProducts?kikobaId=$targetKikobaId');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['loanProducts'] != null) {
          final products = data['loanProducts'] as List<dynamic>;
          logger.i('✅ Fetched ${products.length} loan products');
          return products;
        }
        logger.i('✅ No loan products found (empty array)');
        return [];
      } else {
        logger.e('Failed to fetch loan products: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching loan products', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Add a single loan product
  static Future<Map<String, dynamic>?> addLoanProduct(Map<String, dynamic> product) async {
    logger.i('💳 [POST /saveLoanProducts] Adding single loan product: ${product['name']}');

    try {
      final url = Uri.parse('${baseUrl}saveLoanProducts');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'kikobaId': DataStore.currentKikobaId,
          'product': product,
        }),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        logger.i('✅ Loan product added successfully');
        return data['product'] ?? product;
      } else {
        logger.e('Failed to add loan product: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error adding loan product', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update a single loan product
  static Future<Map<String, dynamic>?> updateLoanProduct(String productId, Map<String, dynamic> product) async {
    logger.i('💳 [PUT /updateLoanProduct] Updating product: $productId');

    try {
      final url = Uri.parse('$baseUrl/api/updateLoanProduct');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'kikobaId': DataStore.currentKikobaId,
          'productId': productId,
          'product': product,
        }),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        logger.i('✅ Loan product updated successfully');
        return data['product'] ?? product;
      } else {
        logger.e('Failed to update loan product: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error updating loan product', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Create a new loan product
  static Future<bool> createLoanProduct(Map<String, dynamic> product) async {
    logger.i('💳 [POST /createLoanProduct] Creating new loan product');

    try {
      final url = Uri.parse('${baseUrl}createLoanProduct');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'kikobaId': DataStore.currentKikobaId,
          'product': product,
        }),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        logger.i('✅ Loan product created successfully');

        // Update local cache
        final products = List<dynamic>.from(DataStore.loanProducts ?? []);
        if (data['product'] != null) {
          products.add(data['product']);
        } else {
          products.add(product);
        }
        DataStore.loanProducts = products;

        return true;
      } else {
        logger.e('Failed to create loan product: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error creating loan product', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete a single loan product
  static Future<bool> deleteLoanProduct(String productId) async {
    logger.i('💳 [DELETE /deleteLoanProduct] Deleting product: $productId');

    try {
      final url = Uri.parse('$baseUrl/api/deleteLoanProduct');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'kikobaId': DataStore.currentKikobaId,
          'productId': productId,
        }),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        logger.i('✅ Loan product deleted successfully');
        return data['success'] == true || data['status'] == 'success';
      } else {
        logger.e('Failed to delete loan product: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error deleting loan product', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // ==================== Loan Applications Management ====================

  /// Submit a new loan application
  static Future<Map<String, dynamic>?> submitLoanApplication(Map<String, dynamic> application) async {
    logger.i('📝 [POST /submitLoanApplication] Submitting loan application');

    try {
      final url = Uri.parse('${baseUrl}submitLoanApplication');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(application),
      ).timeout(const Duration(seconds: 30));

      logger.i('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      // Parse response for both success and error cases
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('✅ Loan application submitted successfully');
        return data;
      } else {
        logger.e('Failed to submit loan application: ${response.statusCode}');
        // Return the parsed error response so UI can display it
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('Error submitting loan application', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get list of loan applications with filters
  static Future<List<dynamic>?> getLoanApplications({
    String? kikobaId,
    String? userId,
    String? status,
  }) async {
    final targetKikobaId = kikobaId ?? DataStore.currentKikobaId;
    final targetUserId = userId ?? DataStore.currentUserId;

    logger.i('📋 [GET /loanApplications] Fetching applications for kikoba: $targetKikobaId, user: $targetUserId, status: $status');

    try {
      final queryParams = <String, String>{};
      if (targetKikobaId != null) queryParams['kikobaId'] = targetKikobaId;
      if (targetUserId != null) queryParams['userId'] = targetUserId;
      if (status != null) queryParams['status'] = status;

      final url = Uri.parse('${baseUrl}loanApplications').replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': targetKikobaId ?? '',
          'X-User-Id': targetUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.d('Decoded data: $data');
        logger.d('Data status: ${data['status']}');
        logger.d('Data content: ${data['data']}');

        if (data['status'] == 'success' && data['data'] != null) {
          final applications = data['data'] as List<dynamic>;
          logger.i('✅ Fetched ${applications.length} loan applications');
          return applications;
        }
        logger.i('✅ No loan applications found (empty array)');
        return [];
      } else {
        logger.e('Failed to fetch loan applications: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching loan applications', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get single loan application by ID
  static Future<Map<String, dynamic>?> getLoanApplication(String applicationId) async {
    logger.i('📄 [GET /loanApplication/$applicationId] Fetching application details');

    try {
      final url = Uri.parse('${baseUrl}loanApplication/$applicationId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          logger.i('✅ Fetched loan application details');
          return data['data'];
        }
      }
      logger.e('Failed to fetch loan application: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      logger.e('Error fetching loan application', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Update loan application status
  static Future<bool> updateLoanApplicationStatus(
    String applicationId,
    String status, {
    String? reason,
    String? approvedBy,
  }) async {
    logger.i('🔄 [PUT /loanApplication/$applicationId/status] Updating status to: $status');

    try {
      final url = Uri.parse('${baseUrl}loanApplication/$applicationId/status');

      final body = {
        'status': status,
        if (reason != null) 'reason': reason,
        if (approvedBy != null) 'approvedBy': approvedBy,
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        logger.i('✅ Loan application status updated successfully');
        return true;
      } else {
        logger.e('Failed to update loan application status: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error updating loan application status', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Approve a loan application (for committee)
  static Future<Map<String, dynamic>?> approveLoanApplication(
    String applicationId, {
    double? approvedAmount,
    int? approvedTenure,
    String? comments,
    String? approverRole,
  }) async {
    logger.i('✅ [POST /loanApplication/$applicationId/approve] Approving loan application');

    try {
      final url = Uri.parse('${baseUrl}loanApplication/$applicationId/approve');

      final body = {
        'approvedBy': DataStore.currentUserId,
        'approvedByName': DataStore.currentUserName,
        'approverRole': approverRole ?? DataStore.currentUserRole ?? 'member',
        if (comments != null) 'comments': comments,
        if (approvedAmount != null) 'approvedAmount': approvedAmount,
        if (approvedTenure != null) 'approvedTenure': approvedTenure,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      // Parse response for both success and error cases
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('✅ Loan application approved successfully');
        return data;
      } else {
        logger.e('Failed to approve loan application: ${response.statusCode}');
        // Return the parsed error response so UI can display it
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('Error approving loan application', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Reject a loan application (for committee)
  static Future<Map<String, dynamic>?> rejectLoanApplication(
    String applicationId, {
    required String reason,
  }) async {
    logger.i('❌ [POST /loanApplication/$applicationId/reject] Rejecting loan application');

    try {
      final url = Uri.parse('${baseUrl}loanApplication/$applicationId/reject');

      final body = {
        'rejectedBy': DataStore.currentUserId,
        'rejectedByName': DataStore.currentUserName,
        'reason': reason,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      // Parse response for both success and error cases
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('✅ Loan application rejected successfully');
        return data;
      } else {
        logger.e('Failed to reject loan application: ${response.statusCode}');
        // Return the parsed error response so UI can display it
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('Error rejecting loan application', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Disburse an approved loan - transfers funds and handles accounting
  /// POST /loanApplication/{applicationId}/disburse
  ///
  /// This endpoint:
  /// 1. Validates the loan is approved and ready for disbursement
  /// 2. Transfers funds from Kikoba account to member's account
  /// 3. Creates accounting entries (debit loan receivable, credit cash)
  /// 4. Updates loan status to 'disbursed'
  /// 5. Notifies the member via SMS/push notification
  /// 6. Returns disbursement details including transaction reference
  static Future<Map<String, dynamic>?> disburseLoan(
    String applicationId, {
    String? paymentMethod, // 'mobile_money', 'bank_transfer', 'cash'
    String? disbursementAccount, // Account to send funds to
    String? notes,
  }) async {
    logger.i('💸 [POST /loanApplication/$applicationId/disburse] Disbursing loan');

    try {
      final url = Uri.parse('${baseUrl}loanApplication/$applicationId/disburse');

      final body = {
        'disbursedBy': DataStore.currentUserId,
        'disbursedByName': DataStore.currentUserName,
        'disbursedByRole': DataStore.currentUserRole ?? 'accountant',
        'kikobaId': DataStore.currentKikobaId,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (disbursementAccount != null) 'disbursementAccount': disbursementAccount,
        if (notes != null) 'notes': notes,
      };

      logger.d('📤 Disburse request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60)); // Longer timeout for financial transactions

      logger.d('📥 Disburse response status: ${response.statusCode}');
      logger.d('📥 Disburse response body: ${response.body}');

      // Parse response for both success and error cases
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('✅ Loan disbursed successfully');
        logger.i('💰 Transaction ref: ${data['transactionReference']}');
        return data;
      } else {
        logger.e('❌ Failed to disburse loan: ${response.statusCode}');
        // Return the parsed error response so UI can display detailed errors
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Error disbursing loan', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get active loans for a user (for top-up/restructure)
  static Future<List<dynamic>?> getUserActiveLoans({String? userId}) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('💰 [GET /loans/active] Fetching active loans for: $targetUserId');

    try {
      final url = Uri.parse('${baseUrl}loans/active?userId=$targetUserId&kikobaId=${DataStore.currentKikobaId}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': targetUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          // Backend might return {status: "success", data: {loans: []}} or {status: "success", data: []}
          final dataObj = data['data'];
          if (dataObj is Map && dataObj['loans'] != null) {
            final loans = dataObj['loans'] as List<dynamic>;
            logger.i('✅ Fetched ${loans.length} active loans');
            return loans;
          } else if (dataObj is List) {
            final loans = dataObj as List<dynamic>;
            logger.i('✅ Fetched ${loans.length} active loans');
            return loans;
          }
        }
        return [];
      } else {
        logger.e('Failed to fetch active loans: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching active loans', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get repayment schedule for a loan application
  static Future<Map<String, dynamic>?> getLoanRepaymentSchedule(String applicationId) async {
    logger.i('📅 [GET /api/loanApplication/{applicationId}/schedules] Fetching repayment schedule for: $applicationId');

    try {
      final url = Uri.parse('${baseUrl}loanApplication/$applicationId/schedules');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched repayment schedule');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        logger.e('Failed to fetch repayment schedule: ${response.statusCode}');
        return errorData;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching repayment schedule', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all loans for a user (active, pending, completed, etc.)
  /// Returns full response with summary and loans array
  static Future<Map<String, dynamic>?> getUserLoans({String? userId, String? kikobaId}) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    final targetKikobaId = kikobaId ?? DataStore.currentKikobaId;
    logger.i('💰 [GET /user/{userId}/loans] Fetching all loans for: $targetUserId');

    try {
      final url = Uri.parse('${baseUrl}user/$targetUserId/loans?kikobaId=$targetKikobaId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': targetKikobaId ?? '',
          'X-User-Id': targetUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched user loans');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        logger.e('Failed to fetch user loans: ${response.statusCode}');
        return errorData;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching user loans', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ==================== Guarantor Management ====================

  /// Approve a loan guarantee
  static Future<Map<String, dynamic>?> approveGuarantee(
    String applicationId, {
    String? comments,
  }) async {
    logger.i('✅ [POST /loan-applications/$applicationId/approve-guarantee] Approving guarantee');

    try {
      final url = Uri.parse('${baseUrl}loan-applications/$applicationId/approve-guarantee');

      final body = {
        'guarantorUserId': DataStore.currentUserId,
        if (comments != null) 'comments': comments,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      // Parse response for both success and error cases
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        logger.i('✅ Guarantee approved successfully');
        return data;
      } else {
        logger.e('Failed to approve guarantee: ${response.statusCode}');
        // Return the parsed error response so UI can display it
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('Error approving guarantee', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Reject a loan guarantee
  static Future<Map<String, dynamic>?> rejectGuarantee(
    String applicationId, {
    required String reason,
  }) async {
    logger.i('❌ [POST /loan-applications/$applicationId/reject-guarantee] Rejecting guarantee');

    try {
      final url = Uri.parse('${baseUrl}loan-applications/$applicationId/reject-guarantee');

      final body = {
        'guarantorUserId': DataStore.currentUserId,
        'reason': reason,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      // Parse response for both success and error cases
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        logger.i('✅ Guarantee rejected successfully');
        return data;
      } else {
        logger.e('Failed to reject guarantee: ${response.statusCode}');
        // Return the parsed error response so UI can display it
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('Error rejecting guarantee', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get loans guaranteed by a user
  static Future<List<dynamic>?> getMyGuaranteedLoans({String? userId}) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('📋 [GET /guarantor/myGuaranteedLoans] Fetching guaranteed loans for: $targetUserId');

    try {
      final url = Uri.parse('${baseUrl}guarantor/myGuaranteedLoans?userId=$targetUserId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': targetUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          // Backend returns: {status: "success", data: {guaranteedLoans: [], summary: {}}}
          final dataObj = data['data'];
          if (dataObj is Map && dataObj['guaranteedLoans'] != null) {
            final loans = dataObj['guaranteedLoans'] as List<dynamic>;
            logger.i('✅ Fetched ${loans.length} guaranteed loans');
            return loans;
          } else if (dataObj is List) {
            // Fallback: if backend returns data as direct list
            final loans = dataObj as List<dynamic>;
            logger.i('✅ Fetched ${loans.length} guaranteed loans');
            return loans;
          }
        }
        logger.w('⚠️ Unexpected response structure: ${response.body}');
        return [];
      } else {
        logger.e('Failed to fetch guaranteed loans: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching guaranteed loans', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get guarantor limits
  static Future<Map<String, dynamic>?> getGuarantorLimit({String? userId}) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('💰 [GET /guarantor/guarantorLimit] Fetching guarantor limits for: $targetUserId');

    try {
      final url = Uri.parse('${baseUrl}guarantor/guarantorLimit?userId=$targetUserId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': targetUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          logger.i('✅ Fetched guarantor limits');
          return data['data'];
        }
      }
      logger.e('Failed to fetch guarantor limits: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      logger.e('Error fetching guarantor limits', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get pending guarantee requests
  static Future<List<dynamic>?> getPendingGuaranteeRequests({String? userId}) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('⏳ [GET /guarantor/pendingRequests] Fetching pending requests for: $targetUserId');

    try {
      final url = Uri.parse('${baseUrl}guarantor/pendingRequests?userId=$targetUserId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': targetUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          // Backend returns: {status: "success", data: {pendingRequests: [], count: 0}}
          final dataObj = data['data'];
          if (dataObj is Map && dataObj['pendingRequests'] != null) {
            final requests = dataObj['pendingRequests'] as List<dynamic>;
            logger.i('✅ Fetched ${requests.length} pending guarantee requests');
            return requests;
          } else if (dataObj is List) {
            // Fallback: if backend returns data as direct list
            final requests = dataObj as List<dynamic>;
            logger.i('✅ Fetched ${requests.length} pending guarantee requests');
            return requests;
          }
        }
        logger.w('⚠️ Unexpected response structure: ${response.body}');
        return [];
      } else {
        logger.e('Failed to fetch pending requests: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching pending requests', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Withdraw a guarantee
  static Future<Map<String, dynamic>?> withdrawGuarantee(String applicationId, {String? reason}) async {
    logger.i('🔙 [POST /loan-applications/$applicationId/withdraw-guarantee] Withdrawing guarantee');

    try {
      final url = Uri.parse('${baseUrl}loan-applications/$applicationId/withdraw-guarantee');

      final body = {
        'guarantorUserId': DataStore.currentUserId,
        if (reason != null) 'reason': reason,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        logger.i('✅ Guarantee withdrawn successfully');
        return data;
      } else {
        logger.e('Failed to withdraw guarantee: ${response.statusCode}');
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('Error withdrawing guarantee', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Cancel a loan application
  static Future<Map<String, dynamic>?> cancelLoanApplication(String applicationId, {String? reason}) async {
    logger.i('❌ [DELETE /loan-applications/$applicationId/cancel] Cancelling loan application');

    try {
      final url = Uri.parse('${baseUrl}loan-applications/$applicationId/cancel');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode({'reason': reason ?? 'Cancelled by applicant'}),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        logger.i('✅ Loan application cancelled successfully');
        return data;
      } else {
        logger.e('Failed to cancel loan application: ${response.statusCode}');
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('Error cancelling loan application', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get loan repayment schedule
  static Future<Map<String, dynamic>?> getLoanSchedule(String applicationId) async {
    logger.i('📅 [GET /loanApplication/$applicationId/schedules] Fetching loan schedule');

    try {
      final url = Uri.parse('${baseUrl}loanApplication/$applicationId/schedules');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched loan schedule');
        return data;
      } else {
        logger.e('Failed to fetch loan schedule: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching loan schedule', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get loan arrears
  static Future<Map<String, dynamic>?> getLoanArrears(String applicationId) async {
    logger.i('⚠️ [GET /loan-applications/$applicationId/arrears] Fetching loan arrears');

    try {
      final url = Uri.parse('${baseUrl}loan-applications/$applicationId/arrears');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched loan arrears');
        return data;
      } else {
        logger.e('Failed to fetch loan arrears: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching loan arrears', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Record a loan payment
  static Future<Map<String, dynamic>?> recordLoanPayment({
    required String applicationId,
    required double amount,
    required String paymentMethod,
    required String reference,
    String? externalReference,
    String? notes,
  }) async {
    logger.i('💰 [POST /loan-payments] Recording loan payment');

    try {
      final url = Uri.parse('${baseUrl}loan-payments');

      final body = {
        'applicationId': applicationId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'reference': reference,
        if (externalReference != null) 'externalReference': externalReference,
        if (notes != null) 'notes': notes,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('✅ Loan payment recorded successfully');
        return data;
      } else {
        logger.e('Failed to record loan payment: ${response.statusCode}');
        return data;
      }
    } catch (e, stackTrace) {
      logger.e('Error recording loan payment', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get loan payment history
  static Future<Map<String, dynamic>?> getLoanPayments(String applicationId) async {
    logger.i('📋 [GET /loan-applications/$applicationId/payments] Fetching payment history');

    try {
      final url = Uri.parse('${baseUrl}loan-applications/$applicationId/payments');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': DataStore.currentKikobaId ?? '',
          'X-User-Id': DataStore.currentUserId ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched payment history');
        return data;
      } else {
        logger.e('Failed to fetch payment history: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching payment history', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Check loan eligibility
  static Future<Map<String, dynamic>?> checkLoanEligibility({
    required String kikobaId,
    required String userId,
    required double amount,
  }) async {
    logger.i('🔍 [POST /loan-applications/check-eligibility] Checking loan eligibility');

    try {
      final url = Uri.parse('${baseUrl}loan-applications/check-eligibility');

      final body = {
        'kikobaId': kikobaId,
        'userId': userId,
        'amount': amount,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Kikoba-Id': kikobaId,
          'X-User-Id': userId,
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Eligibility check completed');
        return data;
      } else {
        logger.e('Failed to check eligibility: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error checking eligibility', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ============================================================================
  // MICHANGO (CONTRIBUTIONS) API METHODS
  // Based on Mchango API Documentation v1.0
  // ============================================================================

  /// 1. Create a new contribution (Omba Mchango)
  /// POST /api/mchango
  ///
  /// Request body:
  /// {
  ///   "KikobaId": "...",
  ///   "currentUserId": "...",
  ///   "userName": "...",
  ///   "mobileNumber": "...",
  ///   "ainayaMchango": "Harusi",
  ///   "maelezo": "...",
  ///   "targetAmount": 50000,
  ///   "amountPerPerson": 5000,
  ///   "tarehe": "2026-01-30"
  /// }
  ///
  /// Success Response (201):
  /// {
  ///   "status": "success",
  ///   "message": "Ombi la mchango limetumwa kikamilifu",
  ///   "data": {
  ///     "mchangoId": "MCH_...",
  ///     "controlNumber": "MCH0010001",
  ///     "ainayaMchango": "Harusi",
  ///     "targetAmount": 50000,
  ///     "amountPerPerson": 5000,
  ///     "deadline": "2026-01-30",
  ///     "membersNotified": 2,
  ///     "status": "active"
  ///   }
  /// }
  static Future<Map<String, dynamic>?> createMchango({
    required String ainayaMchango,
    required String maelezo,
    required String tarehe,
    required double targetAmount,
    required double amountPerPerson,
    String? kikobaId,
    String? userId,
    String? userName,
    String? mobileNumber,
  }) async {
    final targetKikobaId = kikobaId ?? DataStore.currentKikobaId;
    final targetUserId = userId ?? DataStore.currentUserId;
    final targetUserName = userName ?? DataStore.currentUserName;
    final targetMobileNumber = mobileNumber ?? DataStore.userNumber;

    logger.i('📝 [POST /api/mchango] Creating new contribution: $ainayaMchango');

    try {
      final url = Uri.parse('${baseUrl}mchango');

      final body = {
        'KikobaId': targetKikobaId,
        'currentUserId': targetUserId,
        'userName': targetUserName,
        'mobileNumber': targetMobileNumber,
        'ainayaMchango': ainayaMchango,
        'maelezo': maelezo,
        'targetAmount': targetAmount,
        'amountPerPerson': amountPerPerson,
        'tarehe': tarehe,
      };

      logger.d('Request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        logger.i('✅ Contribution created successfully');
        // Normalize: {status: "success", data: {...}} -> {success: true, data: {...}}
        return {
          'success': true,
          'message': data['message'] ?? 'Ombi la mchango limetumwa kikamilifu',
          'data': data['data'],
        };
      } else if (response.statusCode == 400) {
        logger.e('❌ Validation error: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Taarifa ulizojaza si sahihi',
          'errors': data['errors'],
        };
      } else if (response.statusCode == 403) {
        logger.e('❌ Forbidden: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Wewe si mwanachama wa kikoba hiki',
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Not found: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Mtumiaji au Kikoba hajapatikana',
        };
      } else {
        logger.e('❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena baadaye.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception creating contribution', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// 2. Get all contributions for a kikoba (List Michango)
  /// GET /api/kikoba/{kikobaId}/michango
  ///
  /// Success Response (200):
  /// {
  ///   "status": "success",
  ///   "data": [...],
  ///   "summary": {
  ///     "total": 1,
  ///     "active": 1,
  ///     "completed": 0,
  ///     "totalCollected": 15000.00,
  ///     "totalTarget": 50000.00
  ///   }
  /// }
  static Future<Map<String, dynamic>?> getKikobaMichango({String? kikobaId}) async {
    final targetKikobaId = kikobaId ?? DataStore.currentKikobaId;
    logger.i('📋 [GET /api/kikoba/$targetKikobaId/michango] Fetching kikoba contributions');

    try {
      final url = Uri.parse('${baseUrl}kikoba/$targetKikobaId/michango');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched ${(data['data'] as List?)?.length ?? 0} contributions');

        // Normalize: {status: "success", data: [...], summary: {...}}
        // -> {success: true, michango: [...], summary: {...}}
        return {
          'success': true,
          'michango': data['data'] ?? [],
          'summary': data['summary'],
        };
      } else {
        logger.e('❌ Failed to fetch contributions: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching kikoba contributions', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// 3. Get single contribution details (Show Mchango Details)
  /// GET /api/mchango/{mchangoId}
  ///
  /// Success Response (200):
  /// {
  ///   "status": "success",
  ///   "data": {
  ///     "id": 2,
  ///     "mchangoId": "MCH_...",
  ///     "controlNumber": "MCH0010001",
  ///     "paymentUrl": null,
  ///     "ainayaMchango": "Harusi",
  ///     "maelezo": "...",
  ///     "kikoba": {...},
  ///     "requester": {...},
  ///     "targetAmount": 50000.00,
  ///     "amountPerPerson": 5000.00,
  ///     "totalCollected": 15000.00,
  ///     "contributorsCount": 3,
  ///     "progressPercentage": 30.00,
  ///     "remainingAmount": 35000.00,
  ///     "deadline": "2026-01-30",
  ///     "isDeadlineApproaching": false,
  ///     "status": "active",
  ///     "contributions": [...],
  ///     "pendingContributors": [...]
  ///   }
  /// }
  static Future<Map<String, dynamic>?> getMchangoDetails(String mchangoId) async {
    logger.i('📄 [GET /api/mchango/$mchangoId] Fetching contribution details');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched contribution details successfully');

        // Normalize: {status: "success", data: {...}} -> {success: true, mchango: {...}}
        return {
          'success': true,
          'mchango': data['data'],
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to fetch contribution details: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching contribution details', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// 4. Get user's contributions (User Contributions)
  /// GET /api/user/{userId}/michango
  ///
  /// Success Response (200):
  /// {
  ///   "status": "success",
  ///   "data": {
  ///     "contributions": [...],
  ///     "requested": [...],
  ///     "summary": {
  ///       "totalContributed": 15000.00,
  ///       "contributionsCount": 2,
  ///       "requestedCount": 1,
  ///       "activeRequestsCount": 1
  ///     }
  ///   }
  /// }
  static Future<Map<String, dynamic>?> getUserMichango({String? userId}) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('📜 [GET /api/user/$targetUserId/michango] Fetching user contributions');

    try {
      final url = Uri.parse('${baseUrl}user/$targetUserId/michango');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched user contributions successfully');

        // Normalize: {status: "success", data: {...}} -> {success: true, ...data['data']}
        return {
          'success': true,
          'contributions': data['data']?['contributions'] ?? [],
          'requested': data['data']?['requested'] ?? [],
          'summary': data['data']?['summary'],
        };
      } else {
        logger.e('❌ Failed to fetch user contributions: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching user contributions', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// 5. Check user's contribution status for a specific mchango
  /// GET /api/mchango/{mchangoId}/status/{userId}
  ///
  /// Success Response (200):
  /// {
  ///   "status": "success",
  ///   "data": {
  ///     "mchangoId": "MCH_...",
  ///     "controlNumber": "MCH0010001",
  ///     "userId": "USR_...",
  ///     "hasContributed": true/false,
  ///     "amount": 5000.00 or null,
  ///     "paidAt": "2025-12-31T12:00:00+00:00" or null,
  ///     "canContribute": true/false,
  ///     "requiredAmount": 5000.00
  ///   }
  /// }
  static Future<Map<String, dynamic>?> getUserMchangoStatus({
    required String mchangoId,
    String? userId,
  }) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('🔍 [GET /api/mchango/$mchangoId/status/$targetUserId] Checking user contribution status');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/status/$targetUserId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched user contribution status successfully');

        // Normalize: {status: "success", data: {...}} -> {success: true, status: {...}}
        final statusData = data['data'] ?? {};
        return {
          'success': true,
          'status': {
            'mchangoId': statusData['mchangoId'],
            'controlNumber': statusData['controlNumber'],
            'userId': statusData['userId'],
            'hasContributed': statusData['hasContributed'] ?? false,
            'hasPaid': statusData['hasContributed'] ?? false, // Alias for compatibility
            'amount': statusData['amount'],
            'paidAt': statusData['paidAt'],
            'paidDate': statusData['paidAt'], // Alias for compatibility
            'canContribute': statusData['canContribute'] ?? true,
            'requiredAmount': statusData['requiredAmount'],
          },
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to fetch user contribution status: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching user contribution status', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// 6. Lookup mchango by control number
  /// GET /api/mchango/control-number/{controlNumber}
  ///
  /// Success Response (200): Same as getMchangoDetails
  static Future<Map<String, dynamic>?> getMchangoByControlNumber(String controlNumber) async {
    logger.i('🔎 [GET /api/mchango/control-number/$controlNumber] Looking up mchango by control number');

    try {
      final url = Uri.parse('${baseUrl}mchango/control-number/$controlNumber');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Found mchango by control number');

        return {
          'success': true,
          'mchango': data['data'],
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found for control number');
        return {
          'success': false,
          'message': 'Mchango haujapatikana kwa nambari hii',
        };
      } else {
        logger.e('❌ Failed to lookup mchango: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception looking up mchango by control number', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// 7. Generate payment link for mchango
  /// POST /api/mchango/{mchangoId}/generate-payment-link
  ///
  /// Success Response (200):
  /// {
  ///   "status": "success",
  ///   "message": "Link ya malipo imezalishwa kikamilifu",
  ///   "data": {
  ///     "mchangoId": "MCH_...",
  ///     "controlNumber": "MCH0010001",
  ///     "paymentUrl": "https://pay.zimapay.com/link/abc123xyz",
  ///     "paymentLinkId": "pl_abc123xyz789"
  ///   }
  /// }
  static Future<Map<String, dynamic>?> generateMchangoPaymentLink(String mchangoId) async {
    logger.i('🔗 [POST /api/mchango/$mchangoId/generate-payment-link] Generating payment link');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/generate-payment-link');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Payment link generated successfully');

        return {
          'success': true,
          'message': data['message'] ?? 'Link ya malipo imezalishwa kikamilifu',
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to generate payment link: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception generating payment link', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  // ============================================================================
  // LEGACY MICHANGO METHODS (kept for backward compatibility)
  // ============================================================================

  /// Record a contribution payment (internal/callback use)
  /// POST /api/mchango/{mchangoId}/contribute
  static Future<Map<String, dynamic>?> recordMchangoContribution({
    required String mchangoId,
    required double amount,
    String? paymentReference,
    String? paymentChannel,
    String? userId,
  }) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('💰 [POST /api/mchango/$mchangoId/contribute] Recording contribution payment');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/contribute');

      final body = {
        'userId': targetUserId,
        'amount': amount,
        'paymentReference': paymentReference ?? '',
        'paymentChannel': paymentChannel ?? 'MNO',
      };

      logger.d('Request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        logger.i('✅ Contribution payment recorded successfully');
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        logger.e('❌ Failed to record contribution: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kurekodi mchango',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception recording contribution payment', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Update contribution status (admin/committee only)
  /// PUT /api/mchango/{mchangoId}/status
  static Future<Map<String, dynamic>?> updateMchangoStatus({
    required String mchangoId,
    required String status,
  }) async {
    logger.i('🔄 [PUT /api/mchango/$mchangoId/status] Updating contribution status to: $status');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/status');

      final body = {'status': status};

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Contribution status updated successfully');
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        logger.e('❌ Failed to update contribution status: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kubadilisha hali',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception updating contribution status', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  // ============================================================================
  // MICHANGO PROCESSING APIs (with Partial Disbursement Support)
  // ============================================================================

  /// Get all active michango with collected/disbursed amounts
  /// GET /api/kikoba/{kikobaId}/michango/ready
  ///
  /// Response:
  /// {
  ///   "all_active": {
  ///     "count": 5,
  ///     "total_collected": 500000,
  ///     "total_disbursed": 200000,
  ///     "available_for_disbursement": 300000,
  ///     "michango": [
  ///       {
  ///         "mchangoId": "...",
  ///         "collected": 100000,
  ///         "disbursed": 50000,
  ///         "available_for_disbursement": 50000,
  ///         ...
  ///       }
  ///     ]
  ///   }
  /// }
  static Future<Map<String, dynamic>?> getMichangoReadyForProcessing({String? kikobaId}) async {
    final targetKikobaId = kikobaId ?? DataStore.currentKikobaId;
    logger.i('📋 [GET /api/kikoba/$targetKikobaId/michango/ready] Fetching active michango');

    try {
      final url = Uri.parse('${baseUrl}kikoba/$targetKikobaId/michango/ready');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched active michango');

        final responseData = data['data'] ?? data;

        // Handle new structure with all_active
        final allActive = responseData['all_active'] ?? {};
        final michangoList = allActive['michango'] as List<dynamic>? ?? [];

        // Fallback to old structure for backward compatibility
        final readyForProcessing = responseData['ready_for_processing'] ?? {};
        final legacyMichangoList = readyForProcessing['michango'] as List<dynamic>? ?? [];

        final finalMichangoList = michangoList.isNotEmpty ? michangoList : legacyMichangoList;

        return {
          'success': true,
          'data': responseData,
          'michango': finalMichangoList,
          'count': allActive['count'] ?? readyForProcessing['count'] ?? finalMichangoList.length,
          'total_collected': allActive['total_collected'] ?? 0,
          'total_disbursed': allActive['total_disbursed'] ?? 0,
          'available_for_disbursement': allActive['available_for_disbursement'] ?? 0,
          // Legacy fields for backward compatibility
          'total_amount': allActive['total_collected'] ?? readyForProcessing['total_amount'] ?? 0,
          'reached_target': responseData['reached_target'] ?? {},
          'deadline_passed': responseData['deadline_passed'] ?? {},
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Kikoba not found');
        return {
          'success': false,
          'message': 'Kikoba hakijapatikana',
        };
      } else {
        logger.e('❌ Failed to fetch active michango: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching active michango', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Partial disbursement - disburse any amount at any time
  /// POST /api/mchango/{mchangoId}/disburse
  ///
  /// Request body:
  /// {
  ///   "userId": "USR_123",
  ///   "amount": 50000,             // Optional - omit to disburse all available
  ///   "paymentMethod": "cash",     // Optional: cash, bank_transfer, mobile_money
  ///   "paymentReference": "REF",   // Optional
  ///   "notes": "First payment"     // Optional
  /// }
  static Future<Map<String, dynamic>?> disburseMchango({
    required String mchangoId,
    required String userId,
    double? amount,
    String? paymentMethod,
    String? paymentReference,
    String? notes,
  }) async {
    logger.i('💸 [POST /api/mchango/$mchangoId/disburse] Disbursing mchango');
    logger.d('📤 Disbursement: userId=$userId, amount=$amount, method=$paymentMethod');

    try {
      final body = <String, dynamic>{
        'userId': userId,
      };

      if (amount != null) body['amount'] = amount;
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
      if (paymentReference != null) body['paymentReference'] = paymentReference;
      if (notes != null) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('${baseUrl}mchango/$mchangoId/disburse'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Disburse response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        logger.i('✅ Disbursement successful');
        return {
          'success': true,
          'message': data['message'] ?? 'Malipo yametumwa',
          'data': data['data'] ?? data,
          'disbursement': data['disbursement'],
        };
      } else if (response.statusCode == 400) {
        logger.e('❌ Bad request - invalid amount or already fully disbursed');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Kiasi si sahihi au mchango umekwisha sambazwa',
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to disburse: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kusambaza malipo',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception disbursing mchango', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Get disbursement history for a mchango
  /// GET /api/mchango/{mchangoId}/disbursements
  static Future<Map<String, dynamic>?> getMchangoDisbursements(String mchangoId) async {
    logger.i('📜 [GET /api/mchango/$mchangoId/disbursements] Fetching disbursement history');

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}mchango/$mchangoId/disbursements'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Disbursements response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched disbursement history');
        return {
          'success': true,
          'data': data['data'] ?? data,
          'disbursements': data['disbursements'] ?? data['data'] ?? [],
          'total_disbursed': data['total_disbursed'] ?? 0,
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to fetch disbursements: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kupata historia ya malipo',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching disbursements', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Process single completed mchango (disburse or close)
  /// POST /api/mchango/{mchangoId}/process
  ///
  /// Request body:
  /// {
  ///   "userId": "ADMIN001",
  ///   "paymentReference": "PAY_123456",
  ///   "forceDisbursement": false
  /// }
  ///
  /// Response:
  /// {
  ///   "status": "success",
  ///   "message": "Mchango umesindikwa kikamilifu",
  ///   "data": {
  ///     "mchangoId": "MCH_001",
  ///     "action": "disbursed",
  ///     "amount": 500000,
  ///     "disbursedAt": "2025-12-31T10:30:00Z"
  ///   }
  /// }
  static Future<Map<String, dynamic>?> processMchango({
    required String mchangoId,
    String? userId,
    String? paymentReference,
    bool forceDisbursement = false,
  }) async {
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('⚙️ [POST /api/mchango/$mchangoId/process] Processing mchango');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/process');

      final body = {
        'userId': targetUserId,
        'forceDisbursement': forceDisbursement,
      };

      if (paymentReference != null && paymentReference.isNotEmpty) {
        body['paymentReference'] = paymentReference;
      }

      logger.d('Request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Mchango processed successfully');

        final responseData = data['data'] ?? {};
        return {
          'success': true,
          'message': data['message'] ?? 'Mchango umesindikwa kikamilifu',
          'data': responseData,
          'mchangoId': responseData['mchangoId'],
          'action': responseData['action'], // 'disbursed' or 'closed'
          'amount': responseData['amount'],
          'disbursedAt': responseData['disbursedAt'],
        };
      } else if (response.statusCode == 400) {
        logger.e('❌ Bad request: ${response.body}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Mchango hauko tayari kusindikwa',
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to process mchango: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kusindika mchango',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception processing mchango', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Bulk process all ready michango for a kikoba
  /// POST /api/kikoba/{kikobaId}/michango/process-all
  ///
  /// Request body:
  /// {
  ///   "userId": "ADMIN001"
  /// }
  ///
  /// Response:
  /// {
  ///   "status": "success",
  ///   "message": "Michango 3 imesindikwa, 0 imeshindikana",
  ///   "data": {
  ///     "total_found": 3,
  ///     "processed_count": 3,
  ///     "failed_count": 0,
  ///     "processed": [...],
  ///     "failed": []
  ///   }
  /// }
  static Future<Map<String, dynamic>?> processAllMichango({
    String? kikobaId,
    String? userId,
  }) async {
    final targetKikobaId = kikobaId ?? DataStore.currentKikobaId;
    final targetUserId = userId ?? DataStore.currentUserId;
    logger.i('⚙️ [POST /api/kikoba/$targetKikobaId/michango/process-all] Bulk processing all ready michango');

    try {
      final url = Uri.parse('${baseUrl}kikoba/$targetKikobaId/michango/process-all');

      final body = {
        'userId': targetUserId,
      };

      logger.d('Request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60)); // Longer timeout for bulk operation

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Bulk processing completed');

        final responseData = data['data'] ?? {};
        return {
          'success': true,
          'message': data['message'] ?? 'Michango yote imesindikwa',
          'data': responseData,
          'total_found': responseData['total_found'] ?? 0,
          'processed_count': responseData['processed_count'] ?? 0,
          'failed_count': responseData['failed_count'] ?? 0,
          'processed': responseData['processed'] ?? [],
          'failed': responseData['failed'] ?? [],
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Kikoba not found');
        return {
          'success': false,
          'message': 'Kikoba hakijapatikana',
        };
      } else {
        logger.e('❌ Failed to bulk process michango: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kusindika michango',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception bulk processing michango', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  // ============================================================================
  // MCHANGO CONTRIBUTION TRACKING APIs
  // ============================================================================

  /// Get full mchango report with contributors, non-contributors, and summary
  /// GET /api/mchango/{mchangoId}/report
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "mchango_id": "MCH123",
  ///     "title": "Wedding Contribution",
  ///     "requester": {...},
  ///     "target_amount": 1000000,
  ///     "collected_amount": 750000,
  ///     "progress_percentage": 75,
  ///     "deadline": "2025-12-30",
  ///     "contributors": [...],
  ///     "non_contributors": [...],
  ///     "summary": {
  ///       "total_members": 20,
  ///       "total_contributors": 15,
  ///       "total_non_contributors": 5,
  ///       "collection_rate": 75
  ///     }
  ///   }
  /// }
  static Future<Map<String, dynamic>?> getMchangoReport(String mchangoId) async {
    logger.i('📊 [GET /api/mchango/$mchangoId/report] Fetching mchango report');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/report');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched mchango report');

        final reportData = data['data'] ?? data;
        return {
          'success': true,
          'data': reportData,
          'mchangoId': reportData['mchango_id'] ?? reportData['mchangoId'],
          'title': reportData['title'] ?? reportData['ainayaMchango'],
          'requester': reportData['requester'],
          'targetAmount': reportData['target_amount'] ?? reportData['targetAmount'],
          'collectedAmount': reportData['collected_amount'] ?? reportData['collectedAmount'],
          'progressPercentage': reportData['progress_percentage'] ?? reportData['progressPercentage'],
          'deadline': reportData['deadline'],
          'contributors': reportData['contributors'] ?? [],
          'nonContributors': reportData['non_contributors'] ?? reportData['nonContributors'] ?? [],
          'summary': reportData['summary'] ?? {},
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to fetch mchango report: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching mchango report', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Get list of contributors for a mchango
  /// GET /api/mchango/{mchangoId}/contributors
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "mchango_id": "MCH123",
  ///     "title": "Wedding Contribution",
  ///     "contributors": [
  ///       {
  ///         "user_id": "USR001",
  ///         "name": "John Doe",
  ///         "phone": "0712345678",
  ///         "amount_paid": 50000,
  ///         "paid_at": "2025-12-28T10:30:00Z"
  ///       }
  ///     ],
  ///     "total_contributors": 15,
  ///     "total_collected": 750000
  ///   }
  /// }
  static Future<Map<String, dynamic>?> getMchangoContributors(String mchangoId) async {
    logger.i('👥 [GET /api/mchango/$mchangoId/contributors] Fetching mchango contributors');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/contributors');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched mchango contributors');

        final contributorsData = data['data'] ?? data;
        final contributors = contributorsData['contributors'] as List<dynamic>? ?? [];

        return {
          'success': true,
          'data': contributorsData,
          'mchangoId': contributorsData['mchango_id'] ?? contributorsData['mchangoId'],
          'title': contributorsData['title'],
          'contributors': contributors,
          'totalContributors': contributorsData['total_contributors'] ?? contributors.length,
          'totalCollected': contributorsData['total_collected'] ?? contributorsData['totalCollected'] ?? 0,
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to fetch contributors: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching contributors', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Get list of non-contributors for a mchango
  /// GET /api/mchango/{mchangoId}/non-contributors
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "mchango_id": "MCH123",
  ///     "non_contributors": [
  ///       {
  ///         "user_id": "USR002",
  ///         "name": "Jane Smith",
  ///         "phone": "0723456789",
  ///         "expected_amount": 50000
  ///       }
  ///     ],
  ///     "total_pending": 5,
  ///     "amount_pending": 250000
  ///   }
  /// }
  static Future<Map<String, dynamic>?> getMchangoNonContributors(String mchangoId) async {
    logger.i('👤 [GET /api/mchango/$mchangoId/non-contributors] Fetching non-contributors');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/non-contributors');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Fetched non-contributors');

        final nonContributorsData = data['data'] ?? data;
        final nonContributors = nonContributorsData['non_contributors'] as List<dynamic>? ??
                                nonContributorsData['nonContributors'] as List<dynamic>? ?? [];

        return {
          'success': true,
          'data': nonContributorsData,
          'mchangoId': nonContributorsData['mchango_id'] ?? nonContributorsData['mchangoId'],
          'nonContributors': nonContributors,
          'totalPending': nonContributorsData['total_pending'] ?? nonContributors.length,
          'amountPending': nonContributorsData['amount_pending'] ?? nonContributorsData['amountPending'] ?? 0,
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else {
        logger.e('❌ Failed to fetch non-contributors: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Tatizo la seva. Tafadhali jaribu tena.',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching non-contributors', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Send reminders to non-contributors
  /// POST /api/mchango/{mchangoId}/remind
  ///
  /// Request body (optional):
  /// {
  ///   "user_ids": ["USR002", "USR003"],  // Optional: specific users, or omit for all
  ///   "message": "Custom reminder message"  // Optional
  /// }
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "message": "Vikumbusho 5 vimetumwa",
  ///   "data": {
  ///     "sent_count": 5,
  ///     "failed_count": 0,
  ///     "recipients": [...]
  ///   }
  /// }
  static Future<Map<String, dynamic>?> sendMchangoReminders({
    required String mchangoId,
    List<String>? userIds,
    String? customMessage,
  }) async {
    logger.i('📢 [POST /api/mchango/$mchangoId/remind] Sending reminders');

    try {
      final url = Uri.parse('${baseUrl}mchango/$mchangoId/remind');

      final body = <String, dynamic>{};
      if (userIds != null && userIds.isNotEmpty) {
        body['user_ids'] = userIds;
      }
      if (customMessage != null && customMessage.isNotEmpty) {
        body['message'] = customMessage;
      }

      logger.d('Request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body.isNotEmpty ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Reminders sent successfully');

        final responseData = data['data'] ?? {};
        return {
          'success': true,
          'message': data['message'] ?? 'Vikumbusho vimetumwa',
          'data': responseData,
          'sentCount': responseData['sent_count'] ?? responseData['sentCount'] ?? 0,
          'failedCount': responseData['failed_count'] ?? responseData['failedCount'] ?? 0,
          'recipients': responseData['recipients'] ?? [],
        };
      } else if (response.statusCode == 404) {
        logger.e('❌ Mchango not found');
        return {
          'success': false,
          'message': 'Mchango haujapatikana',
        };
      } else if (response.statusCode == 400) {
        logger.e('❌ Bad request');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Hakuna wasiokuwa wamechangia',
        };
      } else {
        logger.e('❌ Failed to send reminders: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kutuma vikumbusho',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception sending reminders', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  // ============================================================================
  // EXPENSE (MATUMIZI) APIs
  // ============================================================================

  // ---------------------------------------------------------------------------
  // Expense Account Management
  // ---------------------------------------------------------------------------

  /// Get expense category codes (alternative endpoint)
  /// GET /api/expenses/categories
  /// Note: Different from getExpenseCategories() which uses /api/expense-categories
  static Future<Map<String, dynamic>?> getExpenseCategoryCodes() async {
    logger.i('📋 [GET /api/expenses/categories] Fetching expense categories');

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}expenses/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Expense categories response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched expense categories');
        return {
          'success': true,
          'data': data['data'] ?? [],
        };
      } else {
        logger.e('❌ Failed to fetch expense categories: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kupata kategoria za matumizi',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching expense categories', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Get all expense accounts (grouped by category)
  /// GET /api/expenses/{kikobaId}/accounts
  static Future<Map<String, dynamic>?> getExpenseAccounts() async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for expense accounts');
      return {'success': false, 'message': 'Kikoba hakijachaguliwa'};
    }

    logger.i('📋 [GET /api/expenses/$kikobaId/accounts] Fetching expense accounts');

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}expenses/$kikobaId/accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Expense accounts response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched expense accounts');
        return {
          'success': true,
          'data': data['data'] ?? [],
        };
      } else {
        logger.e('❌ Failed to fetch expense accounts: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kupata akaunti za matumizi',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching expense accounts', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Get flat list of expense accounts (for dropdowns)
  /// GET /api/expenses/{kikobaId}/accounts/list
  static Future<Map<String, dynamic>?> getExpenseAccountsList() async {
    logger.i('═══════════════════════════════════════════════════════════');
    logger.i('📋 getExpenseAccountsList() - START');
    logger.i('═══════════════════════════════════════════════════════════');

    final kikobaId = DataStore.currentKikobaId;
    logger.d('📌 Current Kikoba ID: $kikobaId');

    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for expense accounts list');
      logger.i('📋 getExpenseAccountsList() - END (no kikoba)');
      return {'success': false, 'message': 'Kikoba hakijachaguliwa'};
    }

    final url = '${baseUrl}expenses/$kikobaId/accounts/list';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    print('');
    print('🔗🔗🔗 FULL API URL: $url');
    print('🔗🔗🔗 KIKOBA ID: $kikobaId');
    print('');
    logger.i('🌐 Request URL: $url');
    logger.d('📤 Request Headers: $headers');

    try {
      logger.d('⏳ Sending GET request...');
      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();
      logger.d('⏱️ Request completed in ${stopwatch.elapsedMilliseconds}ms');
      logger.i('📥 Response Status Code: ${response.statusCode}');
      logger.d('📥 Response Headers: ${response.headers}');
      logger.d('📥 Response Body (raw): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.d('📥 Response Body (parsed): $data');

        final accountsList = data['data'] ?? [];
        logger.i('✅ Successfully fetched expense accounts list');
        logger.i('📊 Total accounts returned: ${accountsList.length}');

        // Log each account for debugging
        if (accountsList is List) {
          for (int i = 0; i < accountsList.length; i++) {
            final account = accountsList[i];
            logger.d('   Account[$i]: code=${account['code']}, name=${account['name']}, id=${account['id']}');
          }
        }

        logger.i('📋 getExpenseAccountsList() - END (success)');
        logger.i('═══════════════════════════════════════════════════════════');

        return {
          'success': true,
          'data': accountsList,
        };
      } else {
        logger.e('❌ Failed to fetch expense accounts list');
        logger.e('   Status Code: ${response.statusCode}');
        logger.e('   Response Body: ${response.body}');

        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Imeshindwa kupata orodha ya akaunti';
        logger.e('   Error Message: $message');
        logger.i('📋 getExpenseAccountsList() - END (error ${response.statusCode})');
        logger.i('═══════════════════════════════════════════════════════════');

        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching expense accounts list');
      logger.e('   Error Type: ${e.runtimeType}');
      logger.e('   Error Message: $e');
      logger.e('   Stack Trace: $stackTrace');
      logger.i('📋 getExpenseAccountsList() - END (exception)');
      logger.i('═══════════════════════════════════════════════════════════');

      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Create new expense account
  /// POST /api/expenses/{kikobaId}/accounts
  static Future<Map<String, dynamic>?> createExpenseAccount({
    required String categoryCode,
    required String code,
    required String name,
    String? description,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for creating expense account');
      return {'success': false, 'message': 'Kikoba hakijachaguliwa'};
    }

    logger.i('📝 [POST /api/expenses/$kikobaId/accounts] Creating expense account');
    logger.d('📤 Account data: category=$categoryCode, code=$code, name=$name');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}expenses/$kikobaId/accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'category_code': categoryCode,
          'code': code,
          'name': name,
          if (description != null) 'description': description,
        }),
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Create expense account response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        logger.i('✅ Expense account created successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Akaunti imeundwa',
          'data': data['data'],
        };
      } else {
        logger.e('❌ Failed to create expense account: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kuunda akaunti',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception creating expense account', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Update expense account
  /// PUT /api/expenses/{kikobaId}/accounts/{id}
  static Future<Map<String, dynamic>?> updateExpenseAccount({
    required String accountId,
    String? name,
    String? description,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for updating expense account');
      return {'success': false, 'message': 'Kikoba hakijachaguliwa'};
    }

    logger.i('📝 [PUT /api/expenses/$kikobaId/accounts/$accountId] Updating expense account');

    try {
      final response = await http.put(
        Uri.parse('${baseUrl}expenses/$kikobaId/accounts/$accountId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        }),
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Update expense account response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Expense account updated successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Akaunti imebadilishwa',
          'data': data['data'],
        };
      } else {
        logger.e('❌ Failed to update expense account: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kubadilisha akaunti',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception updating expense account', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Delete (deactivate) expense account
  /// DELETE /api/expenses/{kikobaId}/accounts/{id}
  static Future<Map<String, dynamic>?> deleteExpenseAccount(String accountId) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for deleting expense account');
      return {'success': false, 'message': 'Kikoba hakijachaguliwa'};
    }

    logger.i('🗑️ [DELETE /api/expenses/$kikobaId/accounts/$accountId] Deleting expense account');

    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}expenses/$kikobaId/accounts/$accountId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Delete expense account response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Expense account deleted successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Akaunti imefutwa',
        };
      } else {
        logger.e('❌ Failed to delete expense account: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kufuta akaunti',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception deleting expense account', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  // ---------------------------------------------------------------------------
  // Expense Payments
  // ---------------------------------------------------------------------------

  /// Record expense payment
  /// POST /api/expenses/{kikobaId}/pay
  static Future<Map<String, dynamic>?> recordExpensePayment({
    required String expenseAccountCode,
    required double amount,
    required String description,
    String? paymentMethod,
    String? paidBy,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for expense payment');
      return {'success': false, 'message': 'Kikoba hakijachaguliwa'};
    }

    logger.i('💰 [POST /api/expenses/$kikobaId/pay] Recording expense payment');
    logger.d('📤 Payment data: account=$expenseAccountCode, amount=$amount, description=$description');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}expenses/$kikobaId/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'expense_account_code': expenseAccountCode,
          'amount': amount,
          'description': description,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (paidBy != null) 'paid_by': paidBy,
        }),
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Expense payment response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        logger.i('✅ Expense payment recorded successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Malipo yamerekodiwa',
          'data': data['data'],
        };
      } else {
        logger.e('❌ Failed to record expense payment: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kurekodi malipo',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception recording expense payment', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  // ---------------------------------------------------------------------------
  // Expense Reports
  // ---------------------------------------------------------------------------

  /// Get expense summary by period
  /// GET /api/expenses/{kikobaId}/summary
  static Future<Map<String, dynamic>?> getExpenseSummary({
    String? startDate,
    String? endDate,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for expense summary');
      return {'success': false, 'message': 'Kikoba hakijachaguliwa'};
    }

    logger.i('📊 [GET /api/expenses/$kikobaId/summary] Fetching expense summary');

    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('${baseUrl}expenses/$kikobaId/summary').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Expense summary response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched expense summary');
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else {
        logger.e('❌ Failed to fetch expense summary: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kupata muhtasari wa matumizi',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching expense summary', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  /// Get expense payment history
  /// GET /api/expenses/{kikobaId}/history
  static Future<Map<String, dynamic>?> getExpenseHistory({
    String? startDate,
    String? endDate,
    String? accountCode,
    int? limit,
    int? offset,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for expense history');
      return {'success': false, 'message': 'Kikoba hakijachaguliwa'};
    }

    logger.i('📜 [GET /api/expenses/$kikobaId/history] Fetching expense history');

    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (accountCode != null) queryParams['account_code'] = accountCode;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('${baseUrl}expenses/$kikobaId/history').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Expense history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched expense history');
        return {
          'success': true,
          'data': data['data'] ?? [],
          'total': data['total'] ?? 0,
        };
      } else {
        logger.e('❌ Failed to fetch expense history: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kupata historia ya matumizi',
        };
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching expense history', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Tatizo la mtandao. Tafadhali jaribu tena.',
      };
    }
  }

  // Legacy method aliases for backward compatibility
  static Future<Map<String, dynamic>?> getMatumiziList() => getExpenseHistory();

  static Future<Map<String, dynamic>?> createMatumizi({
    required String maelezo,
    required double kiasi,
    required String kategoria,
  }) => recordExpensePayment(
    expenseAccountCode: kategoria,
    amount: kiasi,
    description: maelezo,
  );

  // ---------------------------------------------------------------------------
  // Reports API
  // Base URL: https://zima-uat.site:8001/api/reports/{kikobaId}
  // ---------------------------------------------------------------------------

  /// Get Ada (Membership Fees) Report
  /// GET /api/reports/{kikobaId}/ada
  static Future<Map<String, dynamic>?> getAdaReport({
    required String kikobaId,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/ada] Fetching Ada report');
    return _fetchReport(kikobaId, 'ada', startDate: startDate, endDate: endDate);
  }

  /// Get Hisa (Shares) Report
  /// GET /api/reports/{kikobaId}/hisa
  static Future<Map<String, dynamic>?> getHisaReport({
    required String kikobaId,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/hisa] Fetching Hisa report');
    return _fetchReport(kikobaId, 'hisa', startDate: startDate, endDate: endDate);
  }

  /// Get Akiba (Savings) Report
  /// GET /api/reports/{kikobaId}/akiba
  static Future<Map<String, dynamic>?> getAkibaReport({
    required String kikobaId,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/akiba] Fetching Akiba report');
    return _fetchReport(kikobaId, 'akiba', startDate: startDate, endDate: endDate);
  }

  /// Get Mchango (Community Contributions) Summary Report
  /// GET /api/reports/{kikobaId}/mchango
  static Future<Map<String, dynamic>?> getMchangoSummaryReport({
    required String kikobaId,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/mchango] Fetching Mchango report');
    return _fetchReport(kikobaId, 'mchango', startDate: startDate, endDate: endDate);
  }

  /// Get Expenses Report
  /// GET /api/reports/{kikobaId}/expenses
  static Future<Map<String, dynamic>?> getExpensesReport({
    required String kikobaId,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/expenses] Fetching Expenses report');
    return _fetchReport(kikobaId, 'expenses', startDate: startDate, endDate: endDate);
  }

  /// Get Loans Report
  /// GET /api/reports/{kikobaId}/loans
  static Future<Map<String, dynamic>?> getLoansReport({
    required String kikobaId,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/loans] Fetching Loans report');
    return _fetchReport(kikobaId, 'loans', startDate: startDate, endDate: endDate);
  }

  /// Get Trial Balance Report
  /// GET /api/reports/{kikobaId}/trial-balance
  static Future<Map<String, dynamic>?> getTrialBalanceReport({
    required String kikobaId,
    String? asOfDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/trial-balance] Fetching Trial Balance');
    return _fetchReport(kikobaId, 'trial-balance', asOfDate: asOfDate);
  }

  /// Get Income Statement Report
  /// GET /api/reports/{kikobaId}/income-statement
  static Future<Map<String, dynamic>?> getIncomeStatementReport({
    required String kikobaId,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/income-statement] Fetching Income Statement');
    return _fetchReport(kikobaId, 'income-statement', startDate: startDate, endDate: endDate);
  }

  /// Get Balance Sheet Report
  /// GET /api/reports/{kikobaId}/balance-sheet
  static Future<Map<String, dynamic>?> getBalanceSheetReport({
    required String kikobaId,
    String? asOfDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/balance-sheet] Fetching Balance Sheet');
    return _fetchReport(kikobaId, 'balance-sheet', asOfDate: asOfDate);
  }

  /// Get General Ledger Report
  /// GET /api/reports/{kikobaId}/general-ledger/{accountCode}
  static Future<Map<String, dynamic>?> getGeneralLedgerReport({
    required String kikobaId,
    required String accountCode,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/general-ledger/$accountCode] Fetching General Ledger');
    return _fetchReport(kikobaId, 'general-ledger/$accountCode', startDate: startDate, endDate: endDate);
  }

  /// Get Full Statement Report
  /// GET /api/reports/{kikobaId}/full-statement
  static Future<Map<String, dynamic>?> getFullStatementReport({
    required String kikobaId,
    String? startDate,
    String? endDate,
  }) async {
    logger.i('📊 [GET /api/reports/$kikobaId/full-statement] Fetching Full Statement');
    return _fetchReport(kikobaId, 'full-statement', startDate: startDate, endDate: endDate);
  }

  /// Get Dashboard Data for a member
  /// GET /api/dashboard?kikobaId={kikobaId}&visitorId={visitorId}
  ///
  /// Returns member's financial summary including:
  /// - adaList: Ada payments made by member
  /// - hisaList: Hisa contributions made by member
  /// - akibaList: Akiba savings made by member
  /// - mikopoList: Loans taken by member
  /// - michangoList: Special contributions made by member
  /// - fainiList: Fines/penalties for member
  static Future<Map<String, dynamic>?> getDashboardData({
    required String kikobaId,
    required String visitorId,
  }) async {
    logger.i('📊 [GET /api/dashboard] Fetching dashboard data for member: $visitorId');

    try {
      final queryParams = <String, String>{
        'kikobaId': kikobaId,
        'visitorId': visitorId,
      };

      final uri = Uri.parse('${baseUrl}dashboard')
          .replace(queryParameters: queryParams);

      logger.d('🔗 Dashboard URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 60));

      logger.d('📥 Dashboard response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched dashboard data');
        return data['data'] ?? data;
      } else {
        logger.e('❌ Failed to fetch dashboard data: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching dashboard data', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ===========================================================================
  // NEW DASHBOARD ENDPOINTS - Granular data fetching
  // ===========================================================================

  /// Get full member dashboard
  /// GET /api/dashboard/{kikobaId}?memberId={memberId}
  ///
  /// Returns comprehensive member data including:
  /// - kikoba info, member info
  /// - ada, hisa, akiba, loans, michango summaries
  /// - pending voting count
  static Future<Map<String, dynamic>?> getMemberDashboard(
    String kikobaId, {
    required String memberId,
    String? etag, // For caching: If-None-Match header
  }) async {
    logger.i('📊 [GET /api/dashboard/$kikobaId] Fetching full member dashboard');
    return _fetchDashboardEndpoint(kikobaId, '', memberId: memberId, etag: etag);
  }

  /// Get kikoba summary (leadership view)
  /// GET /api/dashboard/{kikobaId}/summary
  ///
  /// Returns aggregated kikoba financial and activity summary
  /// No memberId required - this is a kikoba-wide view
  static Future<Map<String, dynamic>?> getDashboardSummary(
    String kikobaId, {
    String? etag,
  }) async {
    logger.i('📊 [GET /api/dashboard/$kikobaId/summary] Fetching kikoba summary');
    return _fetchDashboardEndpoint(kikobaId, '/summary', etag: etag);
  }

  /// Get Ada summary for a member
  /// GET /api/dashboard/{kikobaId}/ada?memberId={memberId}
  static Future<Map<String, dynamic>?> getDashboardAda(
    String kikobaId, {
    required String memberId,
    String? etag,
  }) async {
    logger.i('📊 [GET /api/dashboard/$kikobaId/ada] Fetching ada summary');
    return _fetchDashboardEndpoint(kikobaId, '/ada', memberId: memberId, etag: etag);
  }

  /// Get Hisa summary for a member
  /// GET /api/dashboard/{kikobaId}/hisa?memberId={memberId}
  static Future<Map<String, dynamic>?> getDashboardHisa(
    String kikobaId, {
    required String memberId,
    String? etag,
  }) async {
    logger.i('📊 [GET /api/dashboard/$kikobaId/hisa] Fetching hisa summary');
    return _fetchDashboardEndpoint(kikobaId, '/hisa', memberId: memberId, etag: etag);
  }

  /// Get Akiba summary for a member
  /// GET /api/dashboard/{kikobaId}/akiba?memberId={memberId}
  static Future<Map<String, dynamic>?> getDashboardAkiba(
    String kikobaId, {
    required String memberId,
    String? etag,
  }) async {
    logger.i('📊 [GET /api/dashboard/$kikobaId/akiba] Fetching akiba summary');
    return _fetchDashboardEndpoint(kikobaId, '/akiba', memberId: memberId, etag: etag);
  }

  /// Get Loans summary for a member
  /// GET /api/dashboard/{kikobaId}/loans?memberId={memberId}
  static Future<Map<String, dynamic>?> getDashboardLoans(
    String kikobaId, {
    required String memberId,
    String? etag,
  }) async {
    logger.i('📊 [GET /api/dashboard/$kikobaId/loans] Fetching loans summary');
    return _fetchDashboardEndpoint(kikobaId, '/loans', memberId: memberId, etag: etag);
  }

  /// Get Michango summary for a member
  /// GET /api/dashboard/{kikobaId}/michango?memberId={memberId}
  static Future<Map<String, dynamic>?> getDashboardMichango(
    String kikobaId, {
    required String memberId,
    String? etag,
  }) async {
    logger.i('📊 [GET /api/dashboard/$kikobaId/michango] Fetching michango summary');
    return _fetchDashboardEndpoint(kikobaId, '/michango', memberId: memberId, etag: etag);
  }

  /// Get Voting count for kikoba
  /// GET /api/dashboard/{kikobaId}/voting
  ///
  /// Returns pending voting items count by type
  /// No memberId required - this is a kikoba-wide count
  static Future<Map<String, dynamic>?> getDashboardVoting(
    String kikobaId, {
    String? etag,
  }) async {
    logger.i('📊 [GET /api/dashboard/$kikobaId/voting] Fetching voting count');
    return _fetchDashboardEndpoint(kikobaId, '/voting', etag: etag);
  }

  /// Internal helper for dashboard endpoints
  /// Handles memberId query param and ETag caching
  static Future<Map<String, dynamic>?> _fetchDashboardEndpoint(
    String kikobaId,
    String subPath, {
    String? memberId,
    String? etag,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (memberId != null) queryParams['memberId'] = memberId;

      final uri = Uri.parse('${baseUrl}dashboard/$kikobaId$subPath')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      logger.d('🔗 Dashboard URL: $uri');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (etag != null) headers['If-None-Match'] = etag;

      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 60));

      logger.d('📥 Dashboard response: ${response.statusCode}');

      // Handle 304 Not Modified (cached response is still valid)
      if (response.statusCode == 304) {
        logger.i('📦 Dashboard$subPath: Using cached data (304 Not Modified)');
        return {'_cached': true, '_etag': etag};
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseEtag = response.headers['etag'];
        final result = data['data'] ?? data;

        // Include ETag in response for caching
        if (responseEtag != null && result is Map<String, dynamic>) {
          result['_etag'] = responseEtag;
        }

        logger.i('✅ Successfully fetched dashboard$subPath');
        return result;
      } else if (response.statusCode == 422) {
        logger.e('❌ Validation error: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message'], 'errors': errorData['errors']};
      } else {
        logger.e('❌ Failed to fetch dashboard$subPath: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching dashboard$subPath', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ===========================================================================
  // NEW UONGOZI (LEADERSHIP) ENDPOINTS
  // ===========================================================================

  /// Get all uongozi data or specific tab
  /// GET /api/uongozi/{kikobaId}?tab=members|loans|michango|voting
  ///
  /// Returns comprehensive leadership/management data:
  /// - members: Member list, leadership, pending approvals
  /// - loans: Loan summary, pending applications, active/overdue loans
  /// - michango: Active/completed michango with progress
  /// - voting: Pending votes, recently completed
  static Future<Map<String, dynamic>?> getUongoziData(
    String kikobaId, {
    String? tab, // 'members', 'loans', 'michango', 'voting'
    String? etag,
  }) async {
    logger.i('👔 [GET /api/uongozi/$kikobaId] Fetching uongozi data${tab != null ? " (tab: $tab)" : ""}');

    try {
      final queryParams = <String, String>{};
      if (tab != null) queryParams['tab'] = tab;

      final uri = Uri.parse('${baseUrl}uongozi/$kikobaId')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      logger.d('🔗 Uongozi URL: $uri');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (etag != null) headers['If-None-Match'] = etag;

      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 60));

      logger.d('📥 Uongozi response: ${response.statusCode}');

      // Handle 304 Not Modified
      if (response.statusCode == 304) {
        logger.i('📦 Uongozi: Using cached data (304 Not Modified)');
        return {'_cached': true, '_etag': etag};
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseEtag = response.headers['etag'];
        final result = data['data'] ?? data;

        if (responseEtag != null && result is Map<String, dynamic>) {
          result['_etag'] = responseEtag;
        }

        logger.i('✅ Successfully fetched uongozi data');
        return result;
      } else if (response.statusCode == 400) {
        logger.e('❌ Invalid tab parameter: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['error']};
      } else {
        logger.e('❌ Failed to fetch uongozi data: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching uongozi data', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get members management data
  /// GET /api/uongozi/{kikobaId}/members
  ///
  /// Returns: summary, leadership list, all members list
  static Future<Map<String, dynamic>?> getUongoziMembers(
    String kikobaId, {
    String? etag,
  }) async {
    logger.i('👔 [GET /api/uongozi/$kikobaId/members] Fetching members management');
    return _fetchUongoziEndpoint(kikobaId, '/members', etag: etag);
  }

  /// Add new member
  /// POST /api/uongozi/{kikobaId}/members
  ///
  /// Required fields: name, phone, role
  /// Optional fields: email
  static Future<Map<String, dynamic>?> addUongoziMember(
    String kikobaId,
    Map<String, dynamic> memberData,
  ) async {
    logger.i('👔 [POST /api/uongozi/$kikobaId/members] Adding new member');

    try {
      final uri = Uri.parse('${baseUrl}uongozi/$kikobaId/members');
      logger.d('🔗 Add member URL: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(memberData),
      ).timeout(const Duration(seconds: 60));

      logger.d('📥 Add member response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully added member');
        return {'success': true, ...data};
      } else if (response.statusCode == 422) {
        logger.e('❌ Validation error: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Validation failed',
          'errors': errorData['errors'],
        };
      } else {
        logger.e('❌ Failed to add member: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message'] ?? errorData['error'] ?? 'Failed to add member'};
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception adding member', error: e, stackTrace: stackTrace);
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get loans management data
  /// GET /api/uongozi/{kikobaId}/loans
  ///
  /// Returns: summary, pending_applications, active_loans, overdue_loans
  static Future<Map<String, dynamic>?> getUongoziLoans(
    String kikobaId, {
    String? etag,
  }) async {
    logger.i('👔 [GET /api/uongozi/$kikobaId/loans] Fetching loans management');
    return _fetchUongoziEndpoint(kikobaId, '/loans', etag: etag);
  }

  /// Get pending loan applications
  /// GET /api/uongozi/{kikobaId}/loans/pending
  ///
  /// Returns array of pending loan applications
  static Future<Map<String, dynamic>?> getUongoziPendingLoans(
    String kikobaId, {
    String? etag,
  }) async {
    logger.i('👔 [GET /api/uongozi/$kikobaId/loans/pending] Fetching pending loans');
    return _fetchUongoziEndpoint(kikobaId, '/loans/pending', etag: etag);
  }

  /// Approve loan application
  /// POST /api/uongozi/{kikobaId}/loans/{loanId}/approve
  ///
  /// Optional body: { "comments": "Approval reason" }
  static Future<Map<String, dynamic>?> approveUongoziLoan(
    String kikobaId,
    String loanId, {
    String? comments,
  }) async {
    logger.i('👔 [POST /api/uongozi/$kikobaId/loans/$loanId/approve] Approving loan');

    try {
      final uri = Uri.parse('${baseUrl}uongozi/$kikobaId/loans/$loanId/approve');
      logger.d('🔗 Approve loan URL: $uri');

      final body = <String, dynamic>{};
      if (comments != null) body['comments'] = comments;

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      logger.d('📥 Approve loan response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully approved loan');
        return {'success': true, ...data};
      } else if (response.statusCode == 500) {
        logger.e('❌ Loan not found: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['error'] ?? 'Loan application not found'};
      } else {
        logger.e('❌ Failed to approve loan: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message'] ?? errorData['error'] ?? 'Failed to approve loan'};
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception approving loan', error: e, stackTrace: stackTrace);
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Reject loan application
  /// POST /api/uongozi/{kikobaId}/loans/{loanId}/reject
  ///
  /// Optional body: { "reason": "Rejection reason" }
  static Future<Map<String, dynamic>?> rejectUongoziLoan(
    String kikobaId,
    String loanId, {
    String? reason,
  }) async {
    logger.i('👔 [POST /api/uongozi/$kikobaId/loans/$loanId/reject] Rejecting loan');

    try {
      final uri = Uri.parse('${baseUrl}uongozi/$kikobaId/loans/$loanId/reject');
      logger.d('🔗 Reject loan URL: $uri');

      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      logger.d('📥 Reject loan response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully rejected loan');
        return {'success': true, ...data};
      } else if (response.statusCode == 500) {
        logger.e('❌ Loan not found: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['error'] ?? 'Loan application not found'};
      } else {
        logger.e('❌ Failed to reject loan: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message'] ?? errorData['error'] ?? 'Failed to reject loan'};
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception rejecting loan', error: e, stackTrace: stackTrace);
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get michango management data
  /// GET /api/uongozi/{kikobaId}/michango
  ///
  /// Returns: summary, active_michango, completed_michango
  static Future<Map<String, dynamic>?> getUongoziMichango(
    String kikobaId, {
    String? etag,
  }) async {
    logger.i('👔 [GET /api/uongozi/$kikobaId/michango] Fetching michango management');
    return _fetchUongoziEndpoint(kikobaId, '/michango', etag: etag);
  }

  /// Get voting management data
  /// GET /api/uongozi/{kikobaId}/voting
  ///
  /// Returns: summary, pending_votes, recently_completed
  static Future<Map<String, dynamic>?> getUongoziVoting(
    String kikobaId, {
    String? etag,
  }) async {
    logger.i('👔 [GET /api/uongozi/$kikobaId/voting] Fetching voting management');
    return _fetchUongoziEndpoint(kikobaId, '/voting', etag: etag);
  }

  /// Internal helper for uongozi endpoints
  /// Handles ETag caching
  static Future<Map<String, dynamic>?> _fetchUongoziEndpoint(
    String kikobaId,
    String subPath, {
    String? etag,
  }) async {
    try {
      final uri = Uri.parse('${baseUrl}uongozi/$kikobaId$subPath');
      logger.d('🔗 Uongozi URL: $uri');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (etag != null) headers['If-None-Match'] = etag;

      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 60));

      logger.d('📥 Uongozi response: ${response.statusCode}');

      // Handle 304 Not Modified
      if (response.statusCode == 304) {
        logger.i('📦 Uongozi$subPath: Using cached data (304 Not Modified)');
        return {'_cached': true, '_etag': etag};
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseEtag = response.headers['etag'];
        final result = data['data'] ?? data;

        if (responseEtag != null && result is Map<String, dynamic>) {
          result['_etag'] = responseEtag;
        }

        logger.i('✅ Successfully fetched uongozi$subPath');
        return result;
      } else {
        logger.e('❌ Failed to fetch uongozi$subPath: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching uongozi$subPath', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Internal helper method to fetch reports
  static Future<Map<String, dynamic>?> _fetchReport(
    String kikobaId,
    String reportType, {
    String? startDate,
    String? endDate,
    String? asOfDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (asOfDate != null) queryParams['as_of_date'] = asOfDate;

      final uri = Uri.parse('${baseUrl}reports/$kikobaId/$reportType')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      logger.d('🔗 Report URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 60));

      logger.d('📥 Report response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched $reportType report');
        return data['data'];
      } else {
        logger.e('❌ Failed to fetch $reportType report: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching $reportType report', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Members API - Enhanced member details and statistics
  // ---------------------------------------------------------------------------

  /// Get all members with details
  /// GET /api/kikoba/{kikobaId}/members/details
  static Future<Map<String, dynamic>?> getMembersWithDetails({
    String? sortBy,
    String? status,
    String? role,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for members details');
      return null;
    }

    logger.i('👥 [GET /api/kikoba/$kikobaId/members/details] Fetching members with details');

    try {
      final queryParams = <String, String>{};
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (status != null && status != 'all') queryParams['status'] = status;
      if (role != null) queryParams['role'] = role;

      final uri = Uri.parse('${baseUrl}kikoba/$kikobaId/members/details')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      logger.d('🔗 Members URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 60));

      logger.d('📥 Members response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched members details');
        return data['data'];
      } else {
        logger.e('❌ Failed to fetch members: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching members details', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get single member details
  /// GET /api/kikoba/{kikobaId}/member/{memberId}/details
  static Future<Map<String, dynamic>?> getMemberDetails(String memberId) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for member details');
      return null;
    }

    logger.i('👤 [GET /api/kikoba/$kikobaId/member/$memberId/details] Fetching member details');

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}kikoba/$kikobaId/member/$memberId/details'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Member details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched member details');
        return data['data'];
      } else {
        logger.e('❌ Failed to fetch member details: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching member details', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get member leaderboard
  /// GET /api/kikoba/{kikobaId}/members/leaderboard
  static Future<Map<String, dynamic>?> getMembersLeaderboard({int limit = 10}) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) {
      logger.w('⚠️ No kikoba ID available for leaderboard');
      return null;
    }

    logger.i('🏆 [GET /api/kikoba/$kikobaId/members/leaderboard] Fetching leaderboard');

    try {
      final uri = Uri.parse('${baseUrl}kikoba/$kikobaId/members/leaderboard')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      logger.d('📥 Leaderboard response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched leaderboard');
        return data['data'];
      } else {
        logger.e('❌ Failed to fetch leaderboard: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💥 Exception fetching leaderboard', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Chat API - Member-to-member messaging
  // ---------------------------------------------------------------------------

  /// Get chattable members (excludes blocked users)
  /// GET /api/chat/{kikobaId}/members?user_id={userId}
  static Future<Map<String, dynamic>?> getChattableMembers(String userId) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return null;

    logger.i('💬 [GET /api/chat/$kikobaId/members] Fetching chattable members');

    try {
      final uri = Uri.parse('${baseUrl}chat/$kikobaId/members')
          .replace(queryParameters: {'user_id': userId});

      final response = await http.get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched chattable members');
        return data['data'];
      }
      logger.e('❌ Failed to fetch chattable members: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('💥 Exception fetching chattable members: $e');
      return null;
    }
  }

  /// Start or get existing conversation
  /// POST /api/chat/conversation
  static Future<Map<String, dynamic>?> startConversation({
    required String senderId,
    required String recipientId,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return null;

    logger.i('💬 [POST /api/chat/conversation] Starting conversation');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}chat/conversation'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'kikoba_id': kikobaId,
          'sender_id': senderId,
          'recipient_id': recipientId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        logger.i('✅ Conversation started/retrieved');
        return data['data'];
      }
      logger.e('❌ Failed to start conversation: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('💥 Exception starting conversation: $e');
      return null;
    }
  }

  /// Get user's conversations
  /// GET /api/chat/{kikobaId}/conversations?user_id={userId}
  static Future<Map<String, dynamic>?> getConversations(String userId) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return null;

    logger.i('💬 [GET /api/chat/$kikobaId/conversations] Fetching conversations');

    try {
      final uri = Uri.parse('${baseUrl}chat/$kikobaId/conversations')
          .replace(queryParameters: {'user_id': userId});

      final response = await http.get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched conversations');
        return data['data'];
      }
      logger.e('❌ Failed to fetch conversations: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('💥 Exception fetching conversations: $e');
      return null;
    }
  }

  /// Send message
  /// POST /api/chat/message
  static Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
  }) async {
    logger.i('💬 [POST /api/chat/message] Sending message');

    try {
      final body = <String, dynamic>{
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
      };

      if (attachmentUrl != null) body['attachment_url'] = attachmentUrl;
      if (attachmentName != null) body['attachment_name'] = attachmentName;
      if (attachmentSize != null) body['attachment_size'] = attachmentSize;

      final response = await http.post(
        Uri.parse('${baseUrl}chat/message'),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        logger.i('✅ Message sent');
        return data['data'];
      }
      logger.e('❌ Failed to send message: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('💥 Exception sending message: $e');
      return null;
    }
  }

  /// Get messages for a conversation
  /// GET /api/chat/conversation/{conversationId}/messages
  static Future<Map<String, dynamic>?> getMessages({
    required String conversationId,
    required String userId,
    int limit = 50,
    String? before,
  }) async {
    logger.i('💬 [GET /api/chat/conversation/$conversationId/messages] Fetching messages');

    try {
      final queryParams = <String, String>{
        'user_id': userId,
        'limit': limit.toString(),
      };
      if (before != null) queryParams['before'] = before;

      final uri = Uri.parse('${baseUrl}chat/conversation/$conversationId/messages')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('✅ Successfully fetched messages');
        return data['data'];
      }
      logger.e('❌ Failed to fetch messages: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('💥 Exception fetching messages: $e');
      return null;
    }
  }

  /// Mark conversation as read
  /// POST /api/chat/conversation/{conversationId}/read
  static Future<bool> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    logger.i('💬 [POST /api/chat/conversation/$conversationId/read] Marking as read');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}chat/conversation/$conversationId/read'),
        headers: _jsonHeaders,
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      logger.e('💥 Exception marking as read: $e');
      return false;
    }
  }

  /// Delete message
  /// DELETE /api/chat/message/{messageId}
  static Future<bool> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    logger.i('💬 [DELETE /api/chat/message/$messageId] Deleting message');

    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}chat/message/$messageId'),
        headers: _jsonHeaders,
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      logger.e('💥 Exception deleting message: $e');
      return false;
    }
  }

  /// Mute/Unmute conversation
  /// POST /api/chat/conversation/{conversationId}/mute
  static Future<bool> toggleMuteConversation({
    required String conversationId,
    required String userId,
  }) async {
    logger.i('💬 [POST /api/chat/conversation/$conversationId/mute] Toggle mute');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}chat/conversation/$conversationId/mute'),
        headers: _jsonHeaders,
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      logger.e('💥 Exception toggling mute: $e');
      return false;
    }
  }

  /// Archive conversation
  /// POST /api/chat/conversation/{conversationId}/archive
  static Future<bool> archiveConversation({
    required String conversationId,
    required String userId,
  }) async {
    logger.i('💬 [POST /api/chat/conversation/$conversationId/archive] Archiving');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}chat/conversation/$conversationId/archive'),
        headers: _jsonHeaders,
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      logger.e('💥 Exception archiving conversation: $e');
      return false;
    }
  }

  /// Block user
  /// POST /api/chat/block
  static Future<bool> blockUser({
    required String blockerId,
    required String blockedId,
    String? reason,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return false;

    logger.i('💬 [POST /api/chat/block] Blocking user');

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}chat/block'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'blocker_id': blockerId,
          'blocked_id': blockedId,
          'kikoba_id': kikobaId,
          if (reason != null) 'reason': reason,
        }),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      logger.e('💥 Exception blocking user: $e');
      return false;
    }
  }

  /// Unblock user
  /// DELETE /api/chat/block
  static Future<bool> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return false;

    logger.i('💬 [DELETE /api/chat/block] Unblocking user');

    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}chat/block'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'blocker_id': blockerId,
          'blocked_id': blockedId,
          'kikoba_id': kikobaId,
        }),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      logger.e('💥 Exception unblocking user: $e');
      return false;
    }
  }

  /// Get blocked users
  /// GET /api/chat/{kikobaId}/blocked?user_id={userId}
  static Future<List<dynamic>?> getBlockedUsers(String userId) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return null;

    logger.i('💬 [GET /api/chat/$kikobaId/blocked] Fetching blocked users');

    try {
      final uri = Uri.parse('${baseUrl}chat/$kikobaId/blocked')
          .replace(queryParameters: {'user_id': userId});

      final response = await http.get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      logger.e('💥 Exception fetching blocked users: $e');
      return null;
    }
  }

  /// Get unread count
  /// GET /api/chat/{kikobaId}/unread-count?user_id={userId}
  static Future<int> getUnreadCount(String userId) async {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return 0;

    try {
      final uri = Uri.parse('${baseUrl}chat/$kikobaId/unread-count')
          .replace(queryParameters: {'user_id': userId});

      final response = await http.get(uri, headers: _jsonHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['total_unread'] ?? 0;
      }
      return 0;
    } catch (e) {
      logger.e('💥 Exception fetching unread count: $e');
      return 0;
    }
  }

  // ============================================================================
  // CONTROL NUMBERS (PAYMENT LINKS) APIs
  // ============================================================================

  /// Fetch control numbers for a specific payment type
  /// GET /api/kikoba/{kikobaId}/control-numbers?type=ada&userId=user456&year=2025
  ///
  /// Parameters:
  /// - [kikobaId]: The kikoba ID
  /// - [type]: Payment type - ada, hisa, akiba, or mchango
  /// - [userId]: Member user ID
  /// - [year]: Year (2020-2100)
  /// - [status]: Optional - pending, paid, expired, cancelled (default: pending)
  ///
  /// Returns a list of control numbers with payment details
  static Future<List<dynamic>> fetchControlNumbers({
    required String kikobaId,
    required String type,
    required String userId,
    required int year,
    String status = 'pending',
  }) async {
    logger.i('💳 ═══════════════════════════════════════════════════════════');
    logger.i('💳 [CONTROL NUMBERS] Fetching payment links');
    logger.i('💳 ───────────────────────────────────────────────────────────');
    logger.i('💳 Endpoint: GET /api/kikoba/$kikobaId/control-numbers');
    logger.i('💳 Parameters:');
    logger.i('💳   - kikobaId: $kikobaId');
    logger.i('💳   - type: $type');
    logger.i('💳   - userId: $userId');
    logger.i('💳   - year: $year');
    logger.i('💳   - status: $status');
    logger.i('💳 ───────────────────────────────────────────────────────────');

    try {
      final uri = Uri.parse('${baseUrl}kikoba/$kikobaId/control-numbers').replace(
        queryParameters: {
          'type': type,
          'userId': userId,
          'year': year.toString(),
          'status': status,
        },
      );

      logger.i('💳 Full URL: $uri');

      final response = await http.get(
        uri,
        headers: _jsonHeaders,
      ).timeout(const Duration(seconds: 30));

      logger.i('💳 Response Status: ${response.statusCode}');
      logger.i('💳 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final controlNumbers = data['controlNumbers'] ?? [];
        logger.i('💳 ✅ SUCCESS: Fetched ${controlNumbers.length} control numbers for $type');
        if (controlNumbers.isNotEmpty) {
          logger.i('💳 Control Numbers:');
          for (var cn in controlNumbers) {
            logger.i('💳   - ${cn['control_number']} | Month: ${cn['month']}/${cn['year']} | Status: ${cn['status']} | Amount: ${cn['amount']}');
          }
        }
        logger.i('💳 ═══════════════════════════════════════════════════════════');
        return controlNumbers;
      } else {
        logger.e('💳 ❌ FAILED: Status ${response.statusCode}');
        logger.e('💳 Response: ${response.body}');
        logger.i('💳 ═══════════════════════════════════════════════════════════');
        return [];
      }
    } catch (e, stackTrace) {
      logger.e('💳 💥 EXCEPTION: $e');
      logger.e('💳 StackTrace: $stackTrace');
      logger.i('💳 ═══════════════════════════════════════════════════════════');
      return [];
    }
  }

  /// Fetch shares summary for a member
  ///
  /// Parameters:
  /// - [kikobaId]: The kikoba ID
  /// - [userId]: Member user ID
  ///
  /// Returns a map with share statistics:
  /// - numberOfShares, numberOfContributions, totalShareValue
  /// - shareUnitValue, sharePercentage, accruedDividend
  /// - maxLoanEligibility, totalPenalties
  static Future<Map<String, dynamic>?> fetchSharesSummary({
    required String kikobaId,
    required String userId,
  }) async {
    logger.i('📊 ═══════════════════════════════════════════════════════════');
    logger.i('📊 [SHARES SUMMARY] Fetching member shares info');
    logger.i('📊 ───────────────────────────────────────────────────────────');
    logger.i('📊 Endpoint: GET /api/kikoba/$kikobaId/shares');
    logger.i('📊 Parameters:');
    logger.i('📊   - kikobaId: $kikobaId');
    logger.i('📊   - userId: $userId');
    logger.i('📊 ───────────────────────────────────────────────────────────');

    try {
      final uri = Uri.parse('${baseUrl}kikoba/$kikobaId/shares').replace(
        queryParameters: {
          'userId': userId,
        },
      );

      logger.i('📊 Full URL: $uri');

      final response = await http.get(
        uri,
        headers: _jsonHeaders,
      ).timeout(const Duration(seconds: 30));

      logger.i('📊 Response Status: ${response.statusCode}');
      logger.i('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final summary = data['data'] as Map<String, dynamic>;
          logger.i('📊 ✅ SUCCESS: Shares summary fetched');
          logger.i('📊   - Number of Shares: ${summary['numberOfShares']}');
          logger.i('📊   - Total Value: ${summary['totalShareValue']}');
          logger.i('📊   - Accrued Dividend: ${summary['accruedDividend']}');
          logger.i('📊   - Max Loan Eligibility: ${summary['maxLoanEligibility']}');
          logger.i('📊 ═══════════════════════════════════════════════════════════');
          return summary;
        } else {
          logger.e('📊 ❌ FAILED: Invalid response format');
          logger.i('📊 ═══════════════════════════════════════════════════════════');
          return null;
        }
      } else {
        logger.e('📊 ❌ FAILED: Status ${response.statusCode}');
        logger.e('📊 Response: ${response.body}');
        logger.i('📊 ═══════════════════════════════════════════════════════════');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('📊 💥 EXCEPTION: $e');
      logger.e('📊 StackTrace: $stackTrace');
      logger.i('📊 ═══════════════════════════════════════════════════════════');
      return null;
    }
  }

  /// Fetch Ada summary for a member
  ///
  /// Parameters:
  /// - [kikobaId]: The kikoba ID
  /// - [userId]: Member user ID
  /// - [year]: Year for the summary
  ///
  /// Returns a map with Ada statistics:
  /// - totalPaid, totalDebt, totalPenalty
  /// - paidMonths, pendingMonths, kipimoKiasi
  static Future<Map<String, dynamic>?> fetchAdaSummary({
    required String kikobaId,
    required String userId,
    int? year,
  }) async {
    final targetYear = year ?? DateTime.now().year;

    logger.i('📊 ═══════════════════════════════════════════════════════════');
    logger.i('📊 [ADA SUMMARY] Fetching member Ada info');
    logger.i('📊 ───────────────────────────────────────────────────────────');
    logger.i('📊 Endpoint: GET /api/kikoba/$kikobaId/ada-summary');
    logger.i('📊 Parameters:');
    logger.i('📊   - kikobaId: $kikobaId');
    logger.i('📊   - userId: $userId');
    logger.i('📊   - year: $targetYear');
    logger.i('📊 ───────────────────────────────────────────────────────────');

    try {
      final uri = Uri.parse('${baseUrl}kikoba/$kikobaId/ada-summary').replace(
        queryParameters: {
          'userId': userId,
          'year': targetYear.toString(),
        },
      );

      logger.i('📊 Full URL: $uri');

      final response = await http.get(
        uri,
        headers: _jsonHeaders,
      ).timeout(const Duration(seconds: 30));

      logger.i('📊 Response Status: ${response.statusCode}');
      logger.i('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final summary = data['data'] as Map<String, dynamic>;
          logger.i('📊 ✅ SUCCESS: Ada summary fetched');
          logger.i('📊   - Total Paid: ${summary['totalPaid']}');
          logger.i('📊   - Total Debt: ${summary['totalDebt']}');
          logger.i('📊   - Total Penalty: ${summary['totalPenalty']}');
          logger.i('📊   - Paid Months: ${summary['paidMonths']}');
          logger.i('📊   - Pending Months: ${summary['pendingMonths']}');
          logger.i('📊 ═══════════════════════════════════════════════════════════');
          return summary;
        } else {
          logger.e('📊 ❌ FAILED: Invalid response format');
          logger.i('📊 ═══════════════════════════════════════════════════════════');
          return null;
        }
      } else {
        logger.e('📊 ❌ FAILED: Status ${response.statusCode}');
        logger.e('📊 Response: ${response.body}');
        logger.i('📊 ═══════════════════════════════════════════════════════════');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('📊 💥 EXCEPTION: $e');
      logger.e('📊 StackTrace: $stackTrace');
      logger.i('📊 ═══════════════════════════════════════════════════════════');
      return null;
    }
  }

  /// Fetch Akiba summary for a member
  ///
  /// Parameters:
  /// - [kikobaId]: The kikoba ID
  /// - [userId]: Member user ID
  ///
  /// Returns a map with Akiba statistics:
  /// - totalSaved, totalWithdrawn, currentBalance, calculatedBalance
  /// - transactionCount, lastTransactionDate, status
  static Future<Map<String, dynamic>?> fetchAkibaSummary({
    required String kikobaId,
    required String userId,
  }) async {
    logger.i('💰 ═══════════════════════════════════════════════════════════');
    logger.i('💰 [AKIBA SUMMARY] Fetching member Akiba info');
    logger.i('💰 ───────────────────────────────────────────────────────────');
    logger.i('💰 Endpoint: GET /api/kikoba/$kikobaId/akiba-summary');
    logger.i('💰 Parameters:');
    logger.i('💰   - kikobaId: $kikobaId');
    logger.i('💰   - userId: $userId');
    logger.i('💰 ───────────────────────────────────────────────────────────');

    try {
      final uri = Uri.parse('${baseUrl}kikoba/$kikobaId/akiba-summary').replace(
        queryParameters: {
          'userId': userId,
        },
      );

      logger.i('💰 Full URL: $uri');

      final response = await http.get(
        uri,
        headers: _jsonHeaders,
      ).timeout(const Duration(seconds: 30));

      logger.i('💰 Response Status: ${response.statusCode}');
      logger.i('💰 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final summary = data['data'] as Map<String, dynamic>;
          logger.i('💰 ✅ SUCCESS: Akiba summary fetched');
          logger.i('💰   - Total Saved: ${summary['totalSaved']}');
          logger.i('💰   - Total Withdrawn: ${summary['totalWithdrawn']}');
          logger.i('💰   - Current Balance: ${summary['currentBalance']}');
          logger.i('💰   - Transaction Count: ${summary['transactionCount']}');
          logger.i('💰   - Status: ${summary['status']}');
          logger.i('💰 ═══════════════════════════════════════════════════════════');
          return summary;
        } else {
          logger.e('💰 ❌ FAILED: Invalid response format');
          logger.i('💰 ═══════════════════════════════════════════════════════════');
          return null;
        }
      } else {
        logger.e('💰 ❌ FAILED: Status ${response.statusCode}');
        logger.e('💰 Response: ${response.body}');
        logger.i('💰 ═══════════════════════════════════════════════════════════');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('💰 💥 EXCEPTION: $e');
      logger.e('💰 StackTrace: $stackTrace');
      logger.i('💰 ═══════════════════════════════════════════════════════════');
      return null;
    }
  }

  // Helper for JSON headers
  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

}