// Spec wave-H — consolidated Dart clients for the 23 controllers shipped in
// the agent-directive mega-batch. One file to keep imports manageable; split
// later if any individual surface grows.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'http_retry.dart';
import '../config/api_config.dart';

class _Api {
  static Uri _u(String path) =>
      Uri.parse(ApiConfig.sanitizeUrl('${ApiConfig.baseUrl}/api$path')!);

  static Future<Map<String, dynamic>?> get(String path,
      {Map<String, String>? query}) async {
    var uri = _u(path);
    if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);
    final res = await httpGetWithRetry(uri);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    return body is Map<String, dynamic> ? body : null;
  }

  static Future<Map<String, dynamic>?> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_u(path),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  static Future<bool> delete(String path) async {
    final res = await http.delete(_u(path));
    return res.statusCode == 200;
  }
}

// === #3 Service dependencies ===
class ServiceDependencyService {
  static Future<List<Map<String, dynamic>>> list(int productId) async {
    final body = await _Api.get('/service-dependencies/$productId');
    final list = body?['dependencies'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<bool> save({
    required int parentProductId,
    required int prerequisiteProductId,
    required int processingMinutes,
    int validDays = 30,
  }) async {
    final res = await _Api.post('/service-dependencies', {
      'parent_product_id': parentProductId,
      'prerequisite_product_id': prerequisiteProductId,
      'processing_minutes': processingMinutes,
      'valid_days': validDays,
    });
    return res?['ok'] == true;
  }
  static Future<bool> remove(int depId) => _Api.delete('/service-dependencies/$depId');
}

// === #12 Support tickets ===
class SupportTicketsService {
  static Future<int?> open({required int userId, required String subject, required String message, String? topic}) async {
    final res = await _Api.post('/support-tickets', {
      'user_id': userId, 'subject': subject, 'message': message,
      if (topic != null) 'topic': topic,
    });
    return (res?['ticket_id'] as num?)?.toInt();
  }
  static Future<bool> send({required int ticketId, required int userId, required String role, required String body}) async {
    final res = await _Api.post('/support-tickets/$ticketId/send', {
      'user_id': userId, 'role': role, 'body': body,
    });
    return res?['ok'] == true;
  }
  static Future<Map<String, dynamic>?> thread(int ticketId) =>
      _Api.get('/support-tickets/$ticketId');
  static Future<List<Map<String, dynamic>>> mine(int userId) async {
    final body = await _Api.get('/support-tickets/mine', query: {'user_id': '$userId'});
    final list = body?['tickets'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
}

// === #28 Supplier catalog ===
class SupplierCatalogService {
  static Future<List<Map<String, dynamic>>> search(String q) async {
    final body = await _Api.get('/supplier-catalog/search', query: {'q': q});
    final list = body?['items'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<Map<String, dynamic>?> placeOrder({
    required int partnerUserId,
    required String supplierCode,
    required List<Map<String, dynamic>> lines,
  }) =>
      _Api.post('/supplier-orders', {
        'partner_user_id': partnerUserId,
        'supplier_code': supplierCode,
        'lines': lines,
      });
}

// === #29 Body shop bids ===
class BodyShopBidsService {
  static Future<int?> create({
    required int serviceRequestId,
    required int partnerUserId,
    required int bidTzs,
    int? estimatedDays,
    String? notes,
    List<String>? photos,
  }) async {
    final res = await _Api.post('/body-shop-bids', {
      'service_request_id': serviceRequestId,
      'partner_user_id': partnerUserId,
      'bid_tzs': bidTzs,
      if (estimatedDays != null) 'estimated_days': estimatedDays,
      if (notes != null) 'notes': notes,
      if (photos != null) 'photos': photos,
    });
    return (res?['bid_id'] as num?)?.toInt();
  }
  static Future<List<Map<String, dynamic>>> listForRequest(int requestId) async {
    final body = await _Api.get('/body-shop-bids/$requestId');
    final list = body?['bids'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<bool> award(int bidId, {required int userId}) async {
    final res = await _Api.post('/body-shop-bids/$bidId/award', {'user_id': userId});
    return res?['ok'] == true;
  }
}

// === #31 Multi-staff cart ===
class MultiStaffCartService {
  static Future<int?> create({
    required int cartOwnerUserId,
    required int partnerId,
    required List<Map<String, dynamic>> participants,
    required DateTime blockStartsAt,
    required int blockMinutes,
  }) async {
    final res = await _Api.post('/multi-staff-bookings', {
      'cart_owner_user_id': cartOwnerUserId,
      'partner_id': partnerId,
      'participants': participants,
      'block_starts_at': blockStartsAt.toUtc().toIso8601String(),
      'block_minutes': blockMinutes,
    });
    return (res?['cart_id'] as num?)?.toInt();
  }
}

// === #35 Skin quiz ===
class SkinQuizService {
  static Future<Map<String, dynamic>?> submit({
    required int userId,
    required Map<String, dynamic> answers,
  }) =>
      _Api.post('/skin-quiz', {'user_id': userId, 'answers': answers});
  static Future<Map<String, dynamic>?> selfie({
    required int userId,
    required String photoUrl,
  }) =>
      _Api.post('/skin-selfie-analysis', {'user_id': userId, 'photo_url': photoUrl});
}

// === #37/#106 Waitlist ===
class AppointmentWaitlistService {
  static Future<int?> join({
    required int userId,
    required int partnerUserId,
    int? partnerProductId,
    String mode = 'fifo',
    DateTime? preferredDate,
    String? preferredWindow,
  }) async {
    final res = await _Api.post('/appointment-waitlist', {
      'user_id': userId,
      'partner_user_id': partnerUserId,
      if (partnerProductId != null) 'partner_product_id': partnerProductId,
      'mode': mode,
      if (preferredDate != null)
        'preferred_date': preferredDate.toIso8601String().substring(0, 10),
      if (preferredWindow != null) 'preferred_window': preferredWindow,
    });
    return (res?['entry_id'] as num?)?.toInt();
  }
  static Future<List<Map<String, dynamic>>> partnerList(int partnerUserId) async {
    final body = await _Api.get('/appointment-waitlist/partner', query: {'partner_user_id': '$partnerUserId'});
    final list = body?['waitlist'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<bool> promote(int entryId) async {
    final res = await _Api.post('/appointment-waitlist/$entryId/promote', {});
    return res?['ok'] == true;
  }
}

// === #42 Studio layouts + spot reserve ===
class StudioLayoutService {
  static Future<Map<String, dynamic>?> show(int partnerId) async {
    final body = await _Api.get('/studio-layouts/$partnerId');
    final raw = body?['layout'];
    return raw is Map<String, dynamic> ? raw : null;
  }
  static Future<bool> save({
    required int partnerUserId,
    required Map<String, dynamic> layout,
  }) async {
    final res = await _Api.post('/studio-layouts', {
      'partner_user_id': partnerUserId, 'layout': layout,
    });
    return res?['ok'] == true;
  }
  static Future<bool> reserveSpot({required int classSessionBookingId, required int spotNumber}) async {
    final res = await _Api.post('/studio-layouts/reserve-spot', {
      'class_session_booking_id': classSessionBookingId,
      'spot_number': spotNumber,
    });
    return res?['ok'] == true;
  }
}

// === #45 Class streams ===
class ClassStreamService {
  static Future<List<Map<String, dynamic>>> list(int sessionId) async {
    final body = await _Api.get('/class-streams/$sessionId');
    final list = body?['streams'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<int?> attach({
    required int classSessionId,
    required String mode,
    String? hlsUrl,
    String? vodUrl,
    int? durationMinutes,
    DateTime? availableUntil,
  }) async {
    final res = await _Api.post('/class-streams', {
      'class_session_id': classSessionId,
      'mode': mode,
      if (hlsUrl != null) 'hls_url': hlsUrl,
      if (vodUrl != null) 'vod_url': vodUrl,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (availableUntil != null)
        'available_until': availableUntil.toUtc().toIso8601String(),
    });
    return (res?['id'] as num?)?.toInt();
  }
}

// === #47 Triage ===
class TriageService {
  static Future<Map<String, dynamic>?> turn({
    required int userId,
    int? conversationId,
    required String message,
  }) =>
      _Api.post('/triage/turn', {
        'user_id': userId,
        if (conversationId != null) 'conversation_id': conversationId,
        'message': message,
      });
}

// === #50 Pre-visit intake ===
class PreVisitIntakeService {
  static Future<int?> submit({
    required int userId,
    required int consultationId,
    required Map<String, dynamic> answers,
  }) async {
    final res = await _Api.post('/pre-visit-intake', {
      'user_id': userId, 'consultation_id': consultationId, 'answers': answers,
    });
    return (res?['intake_id'] as num?)?.toInt();
  }
  static Future<Map<String, dynamic>?> show(int consultationId) async {
    final body = await _Api.get('/pre-visit-intake/$consultationId');
    final raw = body?['intake'];
    return raw is Map<String, dynamic> ? raw : null;
  }
}

// === #51 Derm intake ===
class DermIntakeService {
  static Future<Map<String, dynamic>?> submit({
    required int userId,
    required int consultationId,
    required List<String> photoUrls,
    String? history,
  }) =>
      _Api.post('/derm-intake', {
        'user_id': userId,
        'consultation_id': consultationId,
        'photo_urls': photoUrls,
        if (history != null) 'history': history,
      });
}

// === #52 Pre-call test ===
class PreCallTestService {
  static Future<bool> submit({
    required int userId,
    required int consultationId,
    required bool micOk,
    required bool cameraOk,
    int? bandwidthKbps,
  }) async {
    final res = await _Api.post('/precall-device-test', {
      'user_id': userId,
      'consultation_id': consultationId,
      'mic_ok': micOk,
      'camera_ok': cameraOk,
      if (bandwidthKbps != null) 'bandwidth_kbps': bandwidthKbps,
    });
    return res?['passed'] == true;
  }
}

// === #53 Waiting room ===
class WaitingRoomService {
  static Future<Map<String, dynamic>?> join({required int userId, required int consultationId}) =>
      _Api.post('/waiting-room/join', {'user_id': userId, 'consultation_id': consultationId});
  static Future<List<Map<String, dynamic>>> queue(int consultationId) async {
    final body = await _Api.get('/waiting-room/$consultationId');
    final list = body?['queue'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<bool> admit(int entryId) async {
    final res = await _Api.post('/waiting-room/$entryId/admit', {});
    return res?['ok'] == true;
  }
}

// === #56 Visit notes ===
class VisitNotesService {
  static Future<Map<String, dynamic>?> generate({
    required int partnerUserId,
    required int consultationId,
    required String transcript,
  }) =>
      _Api.post('/visit-notes/generate', {
        'partner_user_id': partnerUserId,
        'consultation_id': consultationId,
        'transcript': transcript,
      });
  static Future<Map<String, dynamic>?> show(int consultationId) async {
    final body = await _Api.get('/visit-notes/$consultationId');
    final raw = body?['note'];
    return raw is Map<String, dynamic> ? raw : null;
  }
  static Future<bool> approve(int noteId) async {
    final res = await _Api.post('/visit-notes/$noteId/approve', {});
    return res?['ok'] == true;
  }
}

// === #60 Legal draft ===
class LegalDraftService {
  static Future<Map<String, dynamic>?> order({
    required int userId,
    required String documentType,
    required Map<String, dynamic> answers,
    required int draftPriceTzs,
    int? reviewPriceTzs,
  }) =>
      _Api.post('/legal-draft/order', {
        'user_id': userId,
        'document_type': documentType,
        'answers': answers,
        'draft_price_tzs': draftPriceTzs,
        if (reviewPriceTzs != null) 'review_price_tzs': reviewPriceTzs,
      });
  static Future<bool> purchaseReview({required int userId, required int orderId}) async {
    final res = await _Api.post('/legal-draft/$orderId/purchase-review', {'user_id': userId});
    return res?['ok'] == true;
  }
}

// === #62 Retainer ===
class RetainerService {
  static Future<Map<String, dynamic>?> show(int engagementId) =>
      _Api.get('/retainers/$engagementId');
  static Future<bool> logTime({required int engagementId, required int userId, required int minutes}) async {
    final res = await _Api.post('/retainers/$engagementId/log-time', {
      'user_id': userId, 'minutes': minutes,
    });
    return res?['ok'] == true;
  }
  static Future<bool> configure({
    required int engagementId,
    required int userId,
    required bool isRetainer,
    int? hoursPerMonth,
    required bool rollsOver,
  }) async {
    final res = await _Api.post('/retainers/$engagementId/configure', {
      'user_id': userId,
      'is_retainer': isRetainer,
      if (hoursPerMonth != null) 'hours_per_month': hoursPerMonth,
      'rolls_over': rollsOver,
    });
    return res?['ok'] == true;
  }
}

// === #68 SoW templates ===
class SowTemplateService {
  static Future<List<Map<String, dynamic>>> list({String? skillCategory}) async {
    final body = await _Api.get('/sow-templates',
        query: skillCategory != null ? {'skill_category': skillCategory} : null);
    final list = body?['templates'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<int?> save({
    required int userId,
    int? id,
    required String name,
    String? skillCategory,
    required Map<String, dynamic> schema,
  }) async {
    final res = await _Api.post('/sow-templates', {
      'user_id': userId,
      if (id != null) 'id': id,
      'name': name,
      if (skillCategory != null) 'skill_category': skillCategory,
      'schema': schema,
    });
    return (res?['id'] as num?)?.toInt();
  }
  static Future<Map<String, dynamic>?> show(int id) async {
    final body = await _Api.get('/sow-templates/$id');
    final raw = body?['template'];
    return raw is Map<String, dynamic> ? raw : null;
  }
}

// === #71 Talent matching ===
class TalentMatchService {
  static Future<Map<String, dynamic>?> brief({
    required int userId,
    required String skillCategory,
    required Map<String, dynamic> requirements,
    int? budgetTzs,
  }) =>
      _Api.post('/talent-match/brief', {
        'user_id': userId,
        'skill_category': skillCategory,
        'requirements': requirements,
        if (budgetTzs != null) 'budget_tzs': budgetTzs,
      });
  static Future<Map<String, dynamic>?> show(int briefId) =>
      _Api.get('/talent-match/$briefId');
}

// === #79 Property tours ===
class PropertyTourService {
  static Future<int?> request({
    required int userId,
    required int propertyListingId,
    int? agentUserId,
    required DateTime requestedAt,
    required String mode,
    List<int>? routeListingIds,
  }) async {
    final res = await _Api.post('/property-tours', {
      'user_id': userId,
      'property_listing_id': propertyListingId,
      if (agentUserId != null) 'agent_user_id': agentUserId,
      'requested_at': requestedAt.toUtc().toIso8601String(),
      'mode': mode,
      if (routeListingIds != null) 'route_listing_ids': routeListingIds,
    });
    return (res?['tour_id'] as num?)?.toInt();
  }
  static Future<bool> confirm(int tourId) async {
    final res = await _Api.post('/property-tours/$tourId/confirm', {});
    return res?['ok'] == true;
  }
  static Future<List<Map<String, dynamic>>> mine(int userId) async {
    final body = await _Api.get('/property-tours/mine', query: {'user_id': '$userId'});
    final list = body?['tours'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
}

// === #96 Per-stop reviews ===
class TourStopReviewsService {
  static Future<int?> add({
    required int userId,
    required int eventBookingId,
    required int stopIndex,
    required int stars,
    String? comment,
  }) async {
    final res = await _Api.post('/tour-stop-reviews', {
      'user_id': userId,
      'event_booking_id': eventBookingId,
      'stop_index': stopIndex,
      'stars': stars,
      if (comment != null) 'comment': comment,
    });
    return (res?['review_id'] as num?)?.toInt();
  }
  static Future<List<Map<String, dynamic>>> listForBooking(int bookingId) async {
    final body = await _Api.get('/tour-stop-reviews/$bookingId');
    final list = body?['reviews'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
}

// === #98 Events moderation ===
class EventShowcaseModerationService {
  static Future<List<Map<String, dynamic>>> queue() async {
    final body = await _Api.get('/event-showcase-moderation/queue');
    final list = body?['queue'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
  static Future<bool> decide({
    required int entryId,
    required int moderatorUserId,
    required String decision,
    String? rejectionReason,
  }) async {
    final res = await _Api.post('/event-showcase-moderation/$entryId/decide', {
      'moderator_user_id': moderatorUserId,
      'decision': decision,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    });
    return res?['ok'] == true;
  }
}

// === #110 Cross-persona dashboard ===
class CrossPersonaDashboardService {
  static Future<bool> rebuild(int partnerUserId) async {
    final res = await _Api.post('/cross-persona/rebuild', {'partner_user_id': partnerUserId});
    return res?['ok'] == true;
  }
  static Future<List<Map<String, dynamic>>> show(int partnerUserId) async {
    final body = await _Api.get('/cross-persona', query: {'partner_user_id': '$partnerUserId'});
    final list = body?['metrics'];
    return list is List
        ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : const [];
  }
}
