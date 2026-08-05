// lib/creator/services/earnings_taxonomy_service.dart
//
// Single source of truth for the per-post-type earnings UI gating.
// Fetches GET /api/earnings/taxonomy at app launch (or on first
// need), caches the response in Hive for 24h, and falls back to a
// baked-in default when the network is unreachable on first load.
//
// All UI code (lib/creator/models/post_type_earnings_taxonomy.dart)
// reads through this service via accessors — never directly from
// network or hardcoded constants.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/graphql/graphql_earnings_taxonomy_service.dart';

/// One canonical (metric × actor_role) row from the taxonomy.
class TaxonomyRow {
  final String metric;
  final String actorRole;
  final String section;
  final Set<String> requiredCaps;

  const TaxonomyRow({
    required this.metric,
    required this.actorRole,
    required this.section,
    required this.requiredCaps,
  });

  String get key => '$metric|$actorRole';

  factory TaxonomyRow.fromJson(Map<String, dynamic> j) => TaxonomyRow(
        metric: j['metric'] as String,
        actorRole: j['actor_role'] as String,
        section: j['section'] as String,
        requiredCaps:
            ((j['required_caps'] as List?)?.cast<String>() ?? const [])
                .toSet(),
      );
}

/// Per-post-type display config + capability bag.
class PostTypeConfig {
  final String wire;
  final String labelEn;
  final String labelSw;
  final String iconKey;
  final Set<String> caps;

  const PostTypeConfig({
    required this.wire,
    required this.labelEn,
    required this.labelSw,
    required this.iconKey,
    required this.caps,
  });

  factory PostTypeConfig.fromJson(String wire, Map<String, dynamic> j) =>
      PostTypeConfig(
        wire: wire,
        labelEn: (j['label_en'] as String?) ?? wire,
        labelSw: (j['label_sw'] as String?) ?? wire,
        iconKey: (j['icon'] as String?) ?? 'image_outlined',
        caps: ((j['caps'] as List?)?.cast<String>() ?? const []).toSet(),
      );
}

class EarningsTaxonomyResponse {
  final String version;
  // Posts side
  final Map<String, PostTypeConfig> postTypes;
  final List<TaxonomyRow> rows;
  final Map<String, List<String>> contributorRolesByCap;
  final Map<String, List<String>> xiMultipliers; // bonuses / engagement_penalties / system_clamps
  final Map<String, Map<String, String>> sectionLabels; // sectionId → {en, sw}
  // Streams side
  final Map<String, PostTypeConfig> streamTypes;
  final List<TaxonomyRow> streamRows;
  final Map<String, List<String>> streamXMultipliers;
  final Map<String, Map<String, String>> streamSectionLabels;

  const EarningsTaxonomyResponse({
    required this.version,
    required this.postTypes,
    required this.rows,
    required this.contributorRolesByCap,
    required this.xiMultipliers,
    required this.sectionLabels,
    required this.streamTypes,
    required this.streamRows,
    required this.streamXMultipliers,
    required this.streamSectionLabels,
  });

  factory EarningsTaxonomyResponse.fromJson(Map<String, dynamic> j) {
    final ptRaw = (j['post_types'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rowsRaw = (j['rows'] as List?) ?? const [];
    final crRaw =
        (j['contributor_roles_by_cap'] as Map?)?.cast<String, dynamic>() ??
            const {};
    final xiRaw = (j['xi_multipliers'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final slRaw = (j['section_labels'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final stRaw = (j['stream_types'] as Map?)?.cast<String, dynamic>() ?? const {};
    final stRowsRaw = (j['stream_rows'] as List?) ?? const [];
    final stXRaw = (j['stream_x_multipliers'] as Map?)?.cast<String, dynamic>() ?? const {};
    final stSlRaw = (j['stream_section_labels'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EarningsTaxonomyResponse(
      version: (j['version'] as String?) ?? 'unknown',
      postTypes: ptRaw.map(
        (wire, v) => MapEntry(
            wire, PostTypeConfig.fromJson(wire, v as Map<String, dynamic>)),
      ),
      rows: rowsRaw
          .whereType<Map<String, dynamic>>()
          .map(TaxonomyRow.fromJson)
          .toList(growable: false),
      contributorRolesByCap: crRaw.map(
        (cap, v) => MapEntry(cap, (v as List).cast<String>()),
      ),
      xiMultipliers: xiRaw.map(
        (group, v) => MapEntry(group, (v as List).cast<String>()),
      ),
      sectionLabels: slRaw.map(
        (sec, v) => MapEntry(sec, (v as Map).cast<String, String>()),
      ),
      streamTypes: stRaw.map(
        (wire, v) => MapEntry(
            wire, PostTypeConfig.fromJson(wire, v as Map<String, dynamic>)),
      ),
      streamRows: stRowsRaw
          .whereType<Map<String, dynamic>>()
          .map(TaxonomyRow.fromJson)
          .toList(growable: false),
      streamXMultipliers: stXRaw.map(
        (group, v) => MapEntry(group, (v as List).cast<String>()),
      ),
      streamSectionLabels: stSlRaw.map(
        (sec, v) => MapEntry(sec, (v as Map).cast<String, String>()),
      ),
    );
  }

  /// Synchronous lookup used by the post-type UI gate.
  bool isRowRelevantForPostType(String postType, String metric, String actorRole) {
    final caps = postTypes[postType]?.caps ?? const <String>{};
    final row = rows.firstWhere(
      (r) => r.metric == metric && r.actorRole == actorRole,
      orElse: () => const TaxonomyRow(
          metric: '', actorRole: '', section: '', requiredCaps: <String>{}),
    );
    if (row.requiredCaps.isEmpty) return true;
    return row.requiredCaps.every(caps.contains);
  }

  /// Synchronous lookup used by the stream-type UI gate.
  bool isStreamRowRelevantForStreamType(
      String streamType, String metric, String actorRole) {
    final caps = streamTypes[streamType]?.caps ?? const <String>{};
    final row = streamRows.firstWhere(
      (r) => r.metric == metric && r.actorRole == actorRole,
      orElse: () => const TaxonomyRow(
          metric: '', actorRole: '', section: '', requiredCaps: <String>{}),
    );
    if (row.requiredCaps.isEmpty) return true;
    return row.requiredCaps.every(caps.contains);
  }
}

/// Singleton service. Wraps Hive cache + network fetch with graceful
/// fallback to a baked-in default.
class EarningsTaxonomyService {
  EarningsTaxonomyService._();
  static final EarningsTaxonomyService instance = EarningsTaxonomyService._();

  static const String _boxName = 'earnings_taxonomy';
  static const String _payloadKey = 'payload_json';
  static const String _fetchedAtKey = 'fetched_at';
  static const Duration _ttl = Duration(hours: 24);

  EarningsTaxonomyResponse? _cached;
  Future<EarningsTaxonomyResponse>? _inflight;

  /// Synchronous accessor — returns the in-memory cache. May be null
  /// before [warmup] resolves; UI callers should use the fallback in
  /// `lib/creator/models/post_type_earnings_taxonomy.dart` when null.
  EarningsTaxonomyResponse? get current => _cached;

  /// Load from Hive (if fresh), else fetch from network, else null.
  /// Safe to call repeatedly; in-flight requests dedupe.
  Future<EarningsTaxonomyResponse?> warmup({bool force = false}) async {
    if (!force && _cached != null) return _cached;
    if (_inflight != null) return _inflight;
    _inflight = _resolve(force: force);
    try {
      final r = await _inflight;
      _cached = r;
      return r;
    } finally {
      _inflight = null;
    }
  }

  Future<EarningsTaxonomyResponse> _resolve({required bool force}) async {
    final box = await Hive.openBox(_boxName);
    if (!force) {
      final cached = box.get(_payloadKey) as String?;
      final fetchedAt = box.get(_fetchedAtKey) as int?;
      if (cached != null && fetchedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
        if (age < _ttl.inMilliseconds) {
          try {
            return EarningsTaxonomyResponse.fromJson(
                jsonDecode(cached) as Map<String, dynamic>);
          } catch (_) {/* fall through to refetch */}
        }
      }
    }
    return _fetchAndCache(box);
  }

  Future<EarningsTaxonomyResponse> _fetchAndCache(Box box) async {
    if (ApiConfig.useGraphqlBackend) {
      final data = await GraphqlEarningsTaxonomyService.fetch();
      if (data == null) {
        throw Exception('taxonomy graphql failed');
      }
      await box.put(_payloadKey, jsonEncode(data));
      await box.put(_fetchedAtKey, DateTime.now().millisecondsSinceEpoch);
      if (kDebugMode) {
        debugPrint(
            '[EarningsTaxonomy] cached version=${data['version']} rows=${(data['rows'] as List).length}');
      }
      return EarningsTaxonomyResponse.fromJson(data);
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/earnings/taxonomy');
    final resp = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('taxonomy http=${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception('taxonomy success=false');
    }
    final data = body['data'] as Map<String, dynamic>;
    await box.put(_payloadKey, jsonEncode(data));
    await box.put(_fetchedAtKey, DateTime.now().millisecondsSinceEpoch);
    if (kDebugMode) {
      debugPrint(
          '[EarningsTaxonomy] cached version=${data['version']} rows=${(data['rows'] as List).length}');
    }
    return EarningsTaxonomyResponse.fromJson(data);
  }
}
