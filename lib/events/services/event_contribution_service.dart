// lib/events/services/event_contribution_service.dart
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/contribution.dart';
import '../../services/authenticated_dio.dart';

class EventContributionService {
  Dio get _dio => AuthenticatedDio.instance;

  // ── Setup ──

  Future<SingleResult<void>> setupMichango({
    required int eventId,
    double? goalAmount,
    String currency = 'TZS',
    List<String>? categories,
    bool allowAnonymous = true,
    double? minimumAmount,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/michango/setup', data: {
        if (goalAmount != null) 'goal_amount': goalAmount,
        'currency': currency,
        if (categories != null) 'categories': categories,
        'allow_anonymous': allowAnonymous,
        if (minimumAmount != null) 'minimum_amount': minimumAmount,
      });
      return SingleResult(
        success: response.data['success'] == true,
        message: response.data['message']?.toString(),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Contributions ──

  Future<PaginatedResult<Contribution>> getContributions({
    required int eventId,
    ContributionStatus? status,
    ContributorCategory? category,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'per_page': perPage};
      if (status != null) params['status'] = status.name;
      if (category != null) params['category'] = category.name;

      final response = await _dio.get('/events/$eventId/michango', queryParameters: params);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        final List rawItems = data is List
            ? data
            : (data is Map && data['data'] is List ? data['data'] : []);
        final items = rawItems.map((e) => Contribution.fromJson(e)).toList();
        final meta = response.data['meta'] as Map<String, dynamic>?;
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: meta?['current_page'] ?? page,
          lastPage: meta?['last_page'] ?? 1,
          total: meta?['total'] ?? items.length,
        );
      }
      return PaginatedResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ── Record Contribution (cash or manual) ──

  Future<SingleResult<Contribution>> recordContribution({
    required int eventId,
    required String contributorName,
    String? contributorPhone,
    int? userId,
    required double amount,
    ContributorCategory category = ContributorCategory.wengine,
    String paymentMethod = 'cash',
    String? paymentReference,
    bool isAnonymous = false,
    String? message,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/michango', data: {
        'contributor_name': contributorName,
        if (contributorPhone != null) 'contributor_phone': contributorPhone,
        if (userId != null) 'user_id': userId,
        'amount': amount,
        'category': category.name,
        'payment_method': paymentMethod,
        if (paymentReference != null) 'payment_reference': paymentReference,
        'is_anonymous': isAnonymous,
        if (message != null) 'message': message,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Contribution.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Record Pledge ──

  Future<SingleResult<Contribution>> recordPledge({
    required int eventId,
    required String contributorName,
    String? contributorPhone,
    int? userId,
    required double amount,
    ContributorCategory category = ContributorCategory.wengine,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/michango/pledge', data: {
        'contributor_name': contributorName,
        if (contributorPhone != null) 'contributor_phone': contributorPhone,
        if (userId != null) 'user_id': userId,
        'amount_pledged': amount,
        'category': category.name,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Contribution.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Record Payment Against Pledge ──

  Future<SingleResult<Contribution>> recordPayment({
    required int contributionId,
    required double amount,
    String paymentMethod = 'mpesa',
    String? paymentReference,
  }) async {
    try {
      final response = await _dio.post('/michango/$contributionId/pay', data: {
        'amount': amount,
        'payment_method': paymentMethod,
        if (paymentReference != null) 'payment_reference': paymentReference,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Contribution.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Summary / Dashboard ──

  Future<SingleResult<ContributionSummary>> getSummary({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/michango/summary');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: ContributionSummary.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Follow-up ──

  Future<SingleResult<void>> assignFollowUp({
    required int contributionId,
    required int userId,
  }) async {
    try {
      final response = await _dio.post('/michango/$contributionId/follow-up', data: {'user_id': userId});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> sendFollowUpReminder({required int contributionId}) async {
    try {
      final response = await _dio.post('/michango/$contributionId/remind');
      return SingleResult(
        success: response.data['success'] == true,
        message: response.data['message']?.toString(),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> sendBulkReminder({
    required int eventId,
    ContributionStatus? status,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/michango/bulk-remind', data: {
        if (status != null) 'status': status.name,
      });
      return SingleResult(
        success: response.data['success'] == true,
        message: response.data['message']?.toString(),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Reciprocity ──

  Future<List<Contribution>> getReciprocityHistory({required int userId}) async {
    try {
      final response = await _dio.get('/users/$userId/michango/history');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => Contribution.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
