import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/engagement.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[EngagementService] $m');

String _snippet(String body, [int max = 300]) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

class EngagementService {
  static Future<EngagementResult> create({
    required int userId,
    required int partnerUserId,
    required String title,
    required String scopeBrief,
    required EngagementContractType contractType,
    required DateTime startDate,
    int? partnerId,
    String? skillCategory,
    int? hourlyRateTzs,
    int? retainerTzs,
    int? fixedTotalTzs,
    int? partnerProductId,
    DateTime? endDate,
    bool ndaRequired = false,
    List<Map<String, dynamic>>? milestones,
  }) async {
    final url = '$_baseUrl/engagements';
    _log('POST $url type=${contractType.apiValue}');
    try {
      final body = <String, dynamic>{
        'customer_user_id': userId,
        'partner_user_id': partnerUserId,
        'title': title,
        'scope_brief': scopeBrief,
        'contract_type': contractType.apiValue,
        'start_date': startDate.toIso8601String().split('T').first,
      };
      if (partnerId != null) body['partner_id'] = partnerId;
      if (skillCategory != null && skillCategory.isNotEmpty) body['skill_category'] = skillCategory;
      if (hourlyRateTzs != null) body['hourly_rate_tzs'] = hourlyRateTzs;
      if (retainerTzs != null) body['retainer_tzs'] = retainerTzs;
      if (fixedTotalTzs != null) body['fixed_total_tzs'] = fixedTotalTzs;
      if (partnerProductId != null) body['partner_product_id'] = partnerProductId;
      if (endDate != null) body['end_date'] = endDate.toIso8601String().split('T').first;
      if (ndaRequired) body['nda_required'] = true;
      if (milestones != null && milestones.isNotEmpty) body['milestones'] = milestones;

      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('create status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('create error: $e\n$s');
      return EngagementResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Counter-proposal / partner revision while status=proposed.
  /// Send only the fields you want to change.
  static Future<EngagementResult> counter({
    required int id,
    required int userId,
    String? title,
    String? scopeBrief,
    EngagementContractType? contractType,
    int? hourlyRateTzs,
    int? retainerTzs,
    int? fixedTotalTzs,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final url = '$_baseUrl/engagements/$id';
    final body = <String, dynamic>{'user_id': userId};
    if (title != null) body['title'] = title;
    if (scopeBrief != null) body['scope_brief'] = scopeBrief;
    if (contractType != null) body['contract_type'] = contractType.apiValue;
    if (hourlyRateTzs != null) body['hourly_rate_tzs'] = hourlyRateTzs;
    if (retainerTzs != null) body['retainer_tzs'] = retainerTzs;
    if (fixedTotalTzs != null) body['fixed_total_tzs'] = fixedTotalTzs;
    if (startDate != null) body['start_date'] = startDate.toIso8601String().split('T').first;
    if (endDate != null) body['end_date'] = endDate.toIso8601String().split('T').first;
    _log('PATCH $url body=${jsonEncode(body)}');
    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('counter status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('counter error: $e\n$s');
      return EngagementResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Propose an amendment while status=active|paused. Sends the diff fields
  /// (subset of scope_summary, total_amount_tzs, fee_model, milestones, notes).
  /// Backend stores in `pending_amendment` + records the proposer's approval.
  static Future<EngagementResult> proposeAmendment({
    required int id,
    required int userId,
    String? scopeSummary,
    int? totalAmountTzs,
    String? feeModel,
    List<Map<String, dynamic>>? milestones,
    String? notes,
  }) async {
    final amendment = <String, dynamic>{};
    if (scopeSummary != null) amendment['scope_summary'] = scopeSummary;
    if (totalAmountTzs != null) amendment['total_amount_tzs'] = totalAmountTzs;
    if (feeModel != null) amendment['fee_model'] = feeModel;
    if (milestones != null && milestones.isNotEmpty) amendment['milestones'] = milestones;
    if (notes != null && notes.trim().isNotEmpty) amendment['notes'] = notes.trim();

    final url = '$_baseUrl/engagements/$id';
    final body = <String, dynamic>{'user_id': userId, 'amendment': amendment};
    _log('PATCH $url amendment=${amendment.keys.join(",")}');
    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('proposeAmendment status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('proposeAmendment error: $e\n$s');
      return EngagementResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Approve or reject the pending amendment. Use 'approve' for the non-proposer
  /// to record their timestamp (auto-applies when both sides have approved).
  /// Use 'reject' from either side to clear the pending amendment without applying.
  static Future<EngagementResult> respondToAmendment({
    required int id,
    required int userId,
    required bool approve,
  }) async {
    final url = '$_baseUrl/engagements/$id';
    final body = <String, dynamic>{
      'user_id': userId,
      'amendment_action': approve ? 'approve' : 'reject',
    };
    _log('PATCH $url amendment_action=${body['amendment_action']}');
    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('respondToAmendment status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('respondToAmendment error: $e\n$s');
      return EngagementResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EngagementListResult> list({
    required int userId,
    required String role,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'role': role,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('$_baseUrl/engagements').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => Engagement.fromJson(m.cast<String, dynamic>()))
            .toList();
        return EngagementListResult(success: true, items: items);
      }
      return EngagementListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('list error: $e\n$s');
      return EngagementListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EngagementResult> get({required int id, required int userId}) async {
    final uri = Uri.parse('$_baseUrl/engagements/$id')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('get status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('get error: $e\n$s');
      return EngagementResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EngagementResult> accept({required int id, required int userId}) =>
      _engagementAction(id, 'accept', {'user_id': userId});

  static Future<EngagementResult> reject({required int id, required int userId, String? reason}) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _engagementAction(id, 'reject', body);
  }

  static Future<EngagementResult> start({required int id, required int userId}) =>
      _engagementAction(id, 'start', {'user_id': userId});

  static Future<EngagementResult> pause({required int id, required int userId}) =>
      _engagementAction(id, 'pause', {'user_id': userId});

  static Future<EngagementResult> resume({required int id, required int userId}) =>
      _engagementAction(id, 'resume', {'user_id': userId});

  static Future<EngagementResult> end({required int id, required int userId}) =>
      _engagementAction(id, 'end', {'user_id': userId});

  static Future<EngagementResult> cancel({required int id, required int userId, String? reason}) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _engagementAction(id, 'cancel', body);
  }

  static Future<MilestoneResult> addMilestone({
    required int engagementId,
    required int userId,
    required String title,
    required int amountTzs,
    DateTime? dueDate,
  }) async {
    final url = '$_baseUrl/engagements/$engagementId/milestones';
    final body = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'amount_tzs': amountTzs,
    };
    if (dueDate != null) body['due_date'] = dueDate.toIso8601String().split('T').first;
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _decodeMilestone(res);
    } catch (e, s) {
      _log('addMilestone error: $e\n$s');
      return MilestoneResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Spec line 781 — escrow phase split. Customer funds the milestone
  /// (transitions pending → funded) which places a wallet hold; partner can
  /// then submit; customer approves which captures the held funds.
  static Future<MilestoneResult> fundMilestone({
    required int engagementId,
    required int milestoneId,
    required int userId,
  }) async {
    final url = '$_baseUrl/engagements/$engagementId/milestones/$milestoneId/fund';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return _decodeMilestone(res);
    } catch (e, s) {
      _log('fundMilestone error: $e\n$s');
      return MilestoneResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<MilestoneResult> submitMilestone({
    required int engagementId,
    required int milestoneId,
    required int userId,
    String? deliverableNote,
    String? deliverableUrl,
  }) async {
    final url = '$_baseUrl/engagements/$engagementId/milestones/$milestoneId/submit';
    final body = <String, dynamic>{'user_id': userId};
    if (deliverableNote != null && deliverableNote.isNotEmpty) body['deliverable_note'] = deliverableNote;
    if (deliverableUrl != null && deliverableUrl.isNotEmpty) body['deliverable_url'] = deliverableUrl;
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _decodeMilestone(res);
    } catch (e, s) {
      _log('submitMilestone error: $e\n$s');
      return MilestoneResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<MilestoneResult> approveMilestone({
    required int engagementId,
    required int milestoneId,
    required int userId,
  }) async {
    final url = '$_baseUrl/engagements/$engagementId/milestones/$milestoneId/approve';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return _decodeMilestone(res);
    } catch (e, s) {
      _log('approveMilestone error: $e\n$s');
      return MilestoneResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<MilestoneResult> disputeMilestone({
    required int engagementId,
    required int milestoneId,
    required int userId,
    required String reason,
  }) async {
    final url = '$_baseUrl/engagements/$engagementId/milestones/$milestoneId/dispute';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'reason': reason}),
      );
      return _decodeMilestone(res);
    } catch (e, s) {
      _log('disputeMilestone error: $e\n$s');
      return MilestoneResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<TimeEntryListResult> listTimeEntries({
    required int engagementId,
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/engagements/$engagementId/time-entries')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => EngagementTimeEntry.fromJson(m.cast<String, dynamic>()))
            .toList();
        return TimeEntryListResult(success: true, items: items);
      }
      return TimeEntryListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('listTimeEntries error: $e\n$s');
      return TimeEntryListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<TimeEntryResult> addTimeEntry({
    required int engagementId,
    required int userId,
    required DateTime entryDate,
    required int minutes,
    String? description,
    bool billable = true,
  }) async {
    final url = '$_baseUrl/engagements/$engagementId/time-entries';
    final body = <String, dynamic>{
      'user_id': userId,
      'entry_date': entryDate.toIso8601String().split('T').first,
      'minutes': minutes,
      'billable': billable,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && decoded['success'] == true) {
        return TimeEntryResult(
          success: true,
          entry: EngagementTimeEntry.fromJson((decoded['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return TimeEntryResult(
        success: false,
        message: decoded['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('addTimeEntry error: $e\n$s');
      return TimeEntryResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> deleteTimeEntry({
    required int engagementId,
    required int entryId,
    required int userId,
  }) async {
    final url = '$_baseUrl/engagements/$engagementId/time-entries/$entryId?user_id=$userId';
    _log('DELETE $url');
    try {
      final res = await http.delete(Uri.parse(url));
      final body = jsonDecode(res.body);
      return res.statusCode == 200 && body['success'] == true;
    } catch (e, s) {
      _log('deleteTimeEntry error: $e\n$s');
      return false;
    }
  }

  static Future<EngagementResult> _engagementAction(
    int id,
    String action,
    Map<String, dynamic> body,
  ) async {
    final url = '$_baseUrl/engagements/$id/$action';
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('$action status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('$action error: $e\n$s');
      return EngagementResult(success: false, message: 'Kosa: $e');
    }
  }

  static EngagementResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return EngagementResult(
          success: true,
          engagement: Engagement.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return EngagementResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return EngagementResult(success: false, message: 'Decode error: $e', statusCode: res.statusCode);
    }
  }

  static MilestoneResult _decodeMilestone(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return MilestoneResult(
          success: true,
          milestone: EngagementMilestone.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return MilestoneResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return MilestoneResult(success: false, message: 'Decode error: $e', statusCode: res.statusCode);
    }
  }
}
