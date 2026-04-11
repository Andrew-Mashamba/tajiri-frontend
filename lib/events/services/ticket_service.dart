// lib/events/services/ticket_service.dart
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_ticket.dart';
import '../models/promo_code.dart';
import '../models/waitlist.dart';
import '../models/event_analytics.dart';
import '../../services/authenticated_dio.dart';

class TicketService {
  Dio get _dio => AuthenticatedDio.instance;

  // ── Ticket Tiers (Organizer) ──

  Future<SingleResult<TicketTier>> createTier({
    required int eventId,
    required String name,
    String? description,
    required double price,
    String currency = 'TZS',
    required int totalQuantity,
    int maxPerOrder = 10,
    int minPerOrder = 1,
    String? saleStartDate,
    String? saleEndDate,
    bool isHidden = false,
    String? accessCode,
    bool isTransferable = true,
    bool isRefundable = true,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/tiers', data: {
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'total_quantity': totalQuantity,
        'max_per_order': maxPerOrder,
        'min_per_order': minPerOrder,
        if (saleStartDate != null) 'sale_start_date': saleStartDate,
        if (saleEndDate != null) 'sale_end_date': saleEndDate,
        'is_hidden': isHidden,
        if (accessCode != null) 'access_code': accessCode,
        'is_transferable': isTransferable,
        'is_refundable': isRefundable,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: TicketTier.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<TicketTier>> updateTier({required int tierId, required Map<String, dynamic> fields}) async {
    try {
      final response = await _dio.put('/tiers/$tierId', data: fields);
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: TicketTier.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> deleteTier({required int tierId}) async {
    try {
      final response = await _dio.delete('/tiers/$tierId');
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<List<TicketTier>> getEventTiers({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/tiers');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => TicketTier.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Purchase ──

  Future<TicketPurchaseResult> purchaseTicket({
    required int eventId,
    required int tierId,
    required int quantity,
    required PaymentMethod paymentMethod,
    String? phoneNumber,
    String? promoCode,
    List<GuestInfo>? guests,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/tickets/purchase', data: {
        'tier_id': tierId,
        'quantity': quantity,
        'payment_method': paymentMethod.apiValue,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (promoCode != null) 'promo_code': promoCode,
        if (guests != null) 'guests': guests.map((g) => g.toJson()).toList(),
      });
      return TicketPurchaseResult.fromJson(response.data);
    } catch (e) {
      return TicketPurchaseResult(success: false, message: 'Imeshindwa kununua tiketi: $e');
    }
  }

  Future<TicketPurchaseResult> purchaseFreeTicket({required int eventId, int? tierId}) async {
    try {
      final response = await _dio.post('/events/$eventId/tickets/purchase', data: {
        if (tierId != null) 'tier_id': tierId,
        'quantity': 1,
        'payment_method': 'free',
      });
      return TicketPurchaseResult.fromJson(response.data);
    } catch (e) {
      return TicketPurchaseResult(success: false, message: '$e');
    }
  }

  // ── My Tickets ──

  Future<PaginatedResult<EventTicket>> getMyTickets({TicketFilter? filter, int page = 1, int perPage = 20}) async {
    try {
      final params = <String, dynamic>{'page': page, 'per_page': perPage};
      if (filter != null && filter != TicketFilter.all) params['filter'] = filter.apiValue;

      final response = await _dio.get('/tickets', queryParameters: params);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List rawItems = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
        final items = rawItems.map((e) => EventTicket.fromJson(e)).toList();
        final meta = response.data['meta'] as Map<String, dynamic>?;
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: meta?['current_page'] ?? page,
          lastPage: meta?['last_page'] ?? 1,
          total: meta?['total'] ?? items.length,
          perPage: meta?['per_page'] ?? perPage,
        );
      }
      return PaginatedResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<EventTicket>> getTicket({required int ticketId}) async {
    try {
      final response = await _dio.get('/tickets/$ticketId');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventTicket.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<String?> getTicketQR({required int ticketId}) async {
    try {
      final response = await _dio.get('/tickets/$ticketId/qr');
      if (response.data['success'] == true) {
        return response.data['data']?['qr_code_data']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Transfer & Gift ──

  Future<SingleResult<void>> transferTicket({required int ticketId, required int toUserId}) async {
    try {
      final response = await _dio.post('/tickets/$ticketId/transfer', data: {'to_user_id': toUserId});
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> giftTicket({required int ticketId, required String recipientPhone, String? message}) async {
    try {
      final response = await _dio.post('/tickets/$ticketId/gift', data: {
        'phone': recipientPhone,
        if (message != null) 'message': message,
      });
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Refund ──

  Future<SingleResult<void>> requestRefund({required int ticketId, String? reason}) async {
    try {
      final response = await _dio.post('/tickets/$ticketId/refund', data: {
        if (reason != null) 'reason': reason,
      });
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Waitlist ──

  Future<SingleResult<WaitlistEntry>> joinWaitlist({required int eventId, int? tierId}) async {
    try {
      final response = await _dio.post('/events/$eventId/waitlist', data: {
        if (tierId != null) 'tier_id': tierId,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: WaitlistEntry.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> leaveWaitlist({required int waitlistId}) async {
    try {
      final response = await _dio.delete('/waitlist/$waitlistId');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> acceptWaitlistOffer({required int waitlistId, required PaymentMethod paymentMethod, String? phoneNumber}) async {
    try {
      final response = await _dio.post('/waitlist/$waitlistId/accept', data: {
        'payment_method': paymentMethod.apiValue,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      });
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Promo Codes (Organizer) ──

  Future<SingleResult<PromoCode>> createPromoCode({
    required int eventId,
    required String code,
    required PromoType type,
    required double value,
    int? maxUses,
    String? validFrom,
    String? validUntil,
    List<int>? applicableTierIds,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/promos', data: {
        'code': code,
        'type': type.apiValue,
        'value': value,
        if (maxUses != null) 'max_uses': maxUses,
        if (validFrom != null) 'valid_from': validFrom,
        if (validUntil != null) 'valid_until': validUntil,
        if (applicableTierIds != null) 'applicable_tier_ids': applicableTierIds,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: PromoCode.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<PromoValidation> validatePromoCode({required int eventId, required String code}) async {
    try {
      final response = await _dio.post('/events/$eventId/promos/validate', data: {'code': code});
      return PromoValidation.fromJson(response.data);
    } catch (e) {
      return PromoValidation(isValid: false, message: '$e');
    }
  }

  Future<List<PromoCode>> getPromoCodes({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/promos');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => PromoCode.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Check-In (Organizer) ──

  Future<CheckInResult> checkInTicket({required String qrData}) async {
    try {
      final response = await _dio.post('/tickets/check-in', data: {'qr_data': qrData});
      return CheckInResult.fromJson(response.data);
    } catch (e) {
      return CheckInResult(success: false, message: '$e');
    }
  }

  Future<CheckInResult> manualCheckIn({required int ticketId}) async {
    try {
      final response = await _dio.post('/tickets/$ticketId/manual-check-in');
      return CheckInResult.fromJson(response.data);
    } catch (e) {
      return CheckInResult(success: false, message: '$e');
    }
  }

  Future<List<CheckInRecord>> getCheckInLog({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/check-in-log');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => CheckInRecord.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
