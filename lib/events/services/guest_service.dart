// lib/events/services/guest_service.dart
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/guest.dart';
import '../../services/authenticated_dio.dart';

class GuestService {
  Dio get _dio => AuthenticatedDio.instance;

  // ── Guest List ──

  Future<PaginatedResult<EventGuest>> getGuests({
    required int eventId,
    GuestCategory? category,
    String? rsvpStatus,
    InvitationStatus? cardStatus,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'per_page': perPage};
      if (category != null) params['category'] = category.name;
      if (rsvpStatus != null) params['rsvp_status'] = rsvpStatus;
      if (cardStatus != null) params['card_status'] = cardStatus.name;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _dio.get('/events/$eventId/guests', queryParameters: params);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List rawItems = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
        final items = rawItems.map((e) => EventGuest.fromJson(e)).toList();
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

  // ── Add Guests ──

  Future<SingleResult<EventGuest>> addGuest({
    required int eventId,
    required String name,
    String? phone,
    int? userId,
    GuestCategory category = GuestCategory.regular,
    String? customCategory,
    bool isDigitalInvite = false,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/guests', data: {
        'name': name,
        if (phone != null) 'phone': phone,
        if (userId != null) 'user_id': userId,
        'category': category.name,
        if (customCategory != null) 'custom_category': customCategory,
        'is_digital_invite': isDigitalInvite,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventGuest.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> addBulkGuests({
    required int eventId,
    required List<Map<String, dynamic>> guests,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/guests/bulk', data: {'guests': guests});
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Invitation Card Tracking ──

  Future<SingleResult<void>> updateCardStatus({
    required int guestId,
    required InvitationStatus status,
    int? deliveredByUserId,
  }) async {
    try {
      final response = await _dio.put('/guests/$guestId/card-status', data: {
        'card_status': status.name,
        if (deliveredByUserId != null) 'delivered_by': deliveredByUserId,
      });
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> assignCardDelivery({
    required List<int> guestIds,
    required int delivererUserId,
  }) async {
    try {
      final response = await _dio.post('/guests/assign-delivery', data: {
        'guest_ids': guestIds,
        'deliverer_user_id': delivererUserId,
      });
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Guest Category ──

  Future<SingleResult<void>> updateGuestCategory({required int guestId, required GuestCategory category}) async {
    try {
      final response = await _dio.put('/guests/$guestId', data: {'category': category.name});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Seat Assignment ──

  Future<SingleResult<void>> assignSeat({required int guestId, required String seatAssignment}) async {
    try {
      final response = await _dio.put('/guests/$guestId', data: {'seat_assignment': seatAssignment});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Gift/Bahasha Tracking ──

  Future<SingleResult<void>> recordGift({
    required int guestId,
    required String type,
    double? cashAmount,
    String? currency,
    String? itemDescription,
  }) async {
    try {
      final response = await _dio.post('/guests/$guestId/gift', data: {
        'type': type,
        if (cashAmount != null) 'cash_amount': cashAmount,
        'currency': currency ?? 'TZS',
        if (itemDescription != null) 'item_description': itemDescription,
      });
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> markThankYouSent({required int guestId}) async {
    try {
      final response = await _dio.post('/guests/$guestId/thank-you');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Summary ──

  Future<SingleResult<GuestSummary>> getSummary({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/guests/summary');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: GuestSummary.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Remove Guest ──

  Future<SingleResult<void>> removeGuest({required int guestId}) async {
    try {
      final response = await _dio.delete('/guests/$guestId');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
