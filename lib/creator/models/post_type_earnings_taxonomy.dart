// lib/creator/models/post_type_earnings_taxonomy.dart
//
// Per-post-type configuration for the strategy renderer screens
// under lib/creator/screens/.
//
// **Runtime source of truth**: GET /api/earnings/taxonomy via
// EarningsTaxonomyService. The constants in this file are kept as
// a fallback only — used when the cache is empty AND the network is
// unreachable on first launch. Once warmup() resolves, every
// accessor below transparently switches to the server-served
// taxonomy.
//
// Bumping `EarningsTaxonomy::VERSION` on the backend invalidates the
// client cache automatically (24h TTL).

import 'package:flutter/material.dart';

import '../services/earnings_taxonomy_service.dart';

/// One (metric × actor_role) pair listed on the strategy screen.
/// Mirrors photo_earnings_screen.dart's `_Pair`. Re-declared here so
/// other earnings screens can share the same shape.
class TaxonomyPair {
  final String metric;
  final String actorRole;
  const TaxonomyPair(this.metric, this.actorRole);
  String get key => '$metric|$actorRole';

  @override
  bool operator ==(Object other) =>
      other is TaxonomyPair &&
      other.metric == metric &&
      other.actorRole == actorRole;
  @override
  int get hashCode => Object.hash(metric, actorRole);
}

/// Capabilities of a content type — drives row applicability.
/// Each post type sets the bag of capabilities it has; rows in the
/// taxonomy declare which capabilities they require.
class _Caps {
  /// Time-based playback (watch_second, dub_create, etc. apply).
  static const String timeBased = 'time_based';

  /// Has visual frames a viewer can screenshot or color-grade.
  static const String visual = 'visual';

  /// Has narrative audio (narrator/composer roles apply).
  static const String audio = 'audio';

  /// Carries written caption/body text (copy_text, translation apply).
  static const String text = 'text';

  /// Can be clipped to a derivative short form (§V Clipper).
  static const String clippable = 'clippable';

  /// Can carry tagged products / outbound links (§X Commerce).
  static const String shoppable = 'shoppable';

  /// Has photographic / visual-design contributors (§VIII roles).
  static const String visualProduction = 'visual_production';

  /// Pollable interactive surface (votes, results).
  static const String poll = 'poll';
}

/// Per-post-type capability bag.
const Map<String, Set<String>> _kPostTypeCaps = {
  'text': {
    _Caps.text,
    _Caps.shoppable, // links/CTAs
  },
  'photo': {
    _Caps.visual,
    _Caps.text, // photo caption is text
    _Caps.shoppable,
    _Caps.visualProduction,
  },
  'image_text': {
    _Caps.visual,
    _Caps.text,
    _Caps.shoppable,
    _Caps.visualProduction,
  },
  'audio': {
    _Caps.timeBased,
    _Caps.audio,
    _Caps.text, // audio post may have caption
    _Caps.shoppable,
  },
  'audio_text': {
    _Caps.timeBased,
    _Caps.audio,
    _Caps.text,
    _Caps.shoppable,
  },
  'video': {
    _Caps.timeBased,
    _Caps.visual,
    _Caps.audio,
    _Caps.text,
    _Caps.clippable,
    _Caps.shoppable,
    _Caps.visualProduction,
  },
  'short_video': {
    _Caps.timeBased,
    _Caps.visual,
    _Caps.audio,
    _Caps.text,
    _Caps.clippable,
    _Caps.shoppable,
    _Caps.visualProduction,
  },
  'poll': {
    _Caps.text,
    _Caps.poll,
  },
  // 'shared' has no direct earnings — handled separately at the
  // entry-point switch; not given a strategy renderer.
};

/// Required capability(ies) for each canonical (metric × actor_role)
/// row. Empty set ⇒ universally applicable.
const Map<String, Set<String>> _kRowRequiredCaps = {
  // §I direct creation
  'view|author': <String>{},
  'watch_second|author': {_Caps.timeBased},
  'reaction|author': <String>{},
  'comment|author': <String>{},
  'reply|author': <String>{},
  'save|author': <String>{},
  'share|author': <String>{},
  'follow_from_post|author': <String>{},
  'subscribe_from_post|author': <String>{},
  'profile_visit_from_post|author': <String>{},
  'return_session_credit|author': <String>{},
  'retention_day_n|author': <String>{},
  'external_link_click|author': {_Caps.shoppable},
  'purchase_assist|author': {_Caps.shoppable},
  'screenshot|author': {_Caps.visual},
  'revisit_post|author': <String>{},
  'copy_text|author': {_Caps.text},
  // §II conversation & context (always universal)
  'comment_reaction|comment_author': <String>{},
  'reply|comment_author': <String>{},
  'reply_reaction|reply_author': <String>{},
  'comment_reaction|host': <String>{},
  'reply_reaction|host': <String>{},
  'thread_depth_bonus|host': <String>{},
  'unique_participant_bonus|host': <String>{},
  'creator_reply_bonus|author': <String>{},
  // §III distribution (universal)
  'view|sharer': <String>{},
  'reaction|sharer': <String>{},
  'share|sharer': <String>{},
  'follow_from_share|sharer': <String>{},
  'subscribe_from_share|sharer': <String>{},
  'profile_visit_from_share|sharer': <String>{},
  'distribution_retention_credit|sharer': <String>{},
  'high_quality_share_bonus|sharer': <String>{},
  // §IV derivative (universal — anything can be derivatized)
  'derivative_royalty|original_author': <String>{},
  // §V clipper / editor (only clippable types)
  'clip_create|clipper': {_Caps.clippable},
  'clip_view|clipper': {_Caps.clippable},
  'clip_conversion|clipper': {_Caps.clippable},
  'subtitle_addition|editor': {_Caps.timeBased},
  'format_adaptation|editor': {_Caps.clippable},
  'highlight_selection|editor': {_Caps.clippable},
  // §VI localization
  'translation_create|translator': {_Caps.text},
  'translated_view|translator': {_Caps.text},
  'translated_conversion|translator': {_Caps.text},
  'dub_create|voice_actor': {_Caps.audio},
  'subtitle_localization|translator': {_Caps.timeBased},
  // §VII curation (universal)
  'collection_add|curator': <String>{},
  'collection_view|curator': <String>{},
  'collection_follow|curator': <String>{},
  'collection_conversion|curator': <String>{},
  'thematic_feed_bonus|curator': <String>{},
  // §VIII collaboration (single row; the contributor-roles sub-table
  // is gated separately based on visualProduction + audio caps)
  'collaborator_split|contributor': <String>{},
  // §IX educational (universal)
  'reference_revisit|author': <String>{},
  'instructional_completion|author': <String>{},
  'save_to_learning_collection|author': <String>{},
  'external_reference_click|author': {_Caps.shoppable},
  // §X commerce (only shoppable types)
  'product_expand|author': {_Caps.shoppable},
  'wishlist_add|author': {_Caps.shoppable},
  'affiliate_conversion|author': {_Caps.shoppable},
  'local_business_conversion|author': {_Caps.shoppable},
  // §XII AI / synthetic (universal — provenance applies anywhere)
  'ai_style_usage|original_author': <String>{},
  'synthetic_voice_usage|original_author': {_Caps.audio},
  'ai_training_contribution|original_author': <String>{},
  'ai_assisted_remix|remixer': <String>{},
  // §XIII community (universal)
  'mentorship_attribution|mentor': <String>{},
  'collaboration_origin_credit|connector': <String>{},
  'moderation_quality_bonus|moderator': <String>{},
  'community_retention_bonus|host': <String>{},
};

/// Per-post-type display + API config.
class PostTypeEarningsConfig {
  final String wire;       // post_type sent to API
  final String labelEn;
  final String labelSw;
  final IconData icon;
  final String routeId;    // for analytics + navigation guard
  const PostTypeEarningsConfig({
    required this.wire,
    required this.labelEn,
    required this.labelSw,
    required this.icon,
    required this.routeId,
  });
}

/// Resolve the icon for a given backend `iconKey`. Mirrors the
/// constants the EarningsTaxonomy controller emits.
IconData _iconForKey(String key) {
  switch (key) {
    case 'text_fields_rounded':       return Icons.text_fields_rounded;
    case 'image_outlined':            return Icons.image_outlined;
    case 'image_aspect_ratio_rounded':return Icons.image_aspect_ratio_rounded;
    case 'audiotrack_rounded':        return Icons.audiotrack_rounded;
    case 'headphones_rounded':        return Icons.headphones_rounded;
    case 'movie_outlined':            return Icons.movie_outlined;
    case 'video_settings_rounded':    return Icons.video_settings_rounded;
    case 'poll_rounded':              return Icons.poll_rounded;
    default:                          return Icons.image_outlined;
  }
}

/// Service-first config accessor. UI callers should use this helper
/// instead of reading `kPostTypeEarningsConfigs` directly so that the
/// live (server-served) taxonomy wins when available.
PostTypeEarningsConfig? postTypeEarningsConfigFor(String postType) {
  final live = EarningsTaxonomyService.instance.current;
  if (live != null) {
    final cfg = live.postTypes[postType];
    if (cfg != null) {
      return PostTypeEarningsConfig(
        wire: cfg.wire,
        labelEn: cfg.labelEn,
        labelSw: cfg.labelSw,
        icon: _iconForKey(cfg.iconKey),
        routeId: '${postType}_earnings',
      );
    }
  }
  return kPostTypeEarningsConfigs[postType];
}

/// Hardcoded fallback registry. Used only when the
/// EarningsTaxonomyService cache is empty AND the network call
/// hasn't completed (or failed). Keys are `PostType.value` strings.
const Map<String, PostTypeEarningsConfig> kPostTypeEarningsConfigs = {
  'text': PostTypeEarningsConfig(
    wire: 'text',
    labelEn: 'Text',
    labelSw: 'Maandishi',
    icon: Icons.text_fields_rounded,
    routeId: 'text_earnings',
  ),
  'photo': PostTypeEarningsConfig(
    wire: 'photo',
    labelEn: 'Photos',
    labelSw: 'Picha',
    icon: Icons.image_outlined,
    routeId: 'photo_earnings',
  ),
  'image_text': PostTypeEarningsConfig(
    wire: 'image_text',
    labelEn: 'Image + Text',
    labelSw: 'Picha + Maandishi',
    icon: Icons.image_aspect_ratio_rounded,
    routeId: 'image_text_earnings',
  ),
  'audio': PostTypeEarningsConfig(
    wire: 'audio',
    labelEn: 'Audio',
    labelSw: 'Sauti',
    icon: Icons.audiotrack_rounded,
    routeId: 'audio_earnings',
  ),
  'audio_text': PostTypeEarningsConfig(
    wire: 'audio_text',
    labelEn: 'Audio + Text',
    labelSw: 'Sauti + Maandishi',
    icon: Icons.headphones_rounded,
    routeId: 'audio_text_earnings',
  ),
  'video': PostTypeEarningsConfig(
    wire: 'video',
    labelEn: 'Videos',
    labelSw: 'Video',
    icon: Icons.movie_outlined,
    routeId: 'video_earnings',
  ),
  'short_video': PostTypeEarningsConfig(
    wire: 'short_video',
    labelEn: 'Short videos',
    labelSw: 'Video Fupi',
    icon: Icons.video_settings_rounded,
    routeId: 'short_video_earnings',
  ),
  'poll': PostTypeEarningsConfig(
    wire: 'poll',
    labelEn: 'Polls',
    labelSw: 'Kura',
    icon: Icons.poll_rounded,
    routeId: 'poll_earnings',
  ),
};

/// Resolve a post type's capability bag — service first, fallback
/// to the constants above.
Set<String> _capsFor(String postType) {
  final live = EarningsTaxonomyService.instance.current;
  if (live != null) {
    final cfg = live.postTypes[postType];
    if (cfg != null) return cfg.caps;
  }
  return _kPostTypeCaps[postType] ?? const <String>{};
}

/// Returns true if the given (metric, actor_role) row is relevant
/// for the given post_type. Reads the live taxonomy from
/// EarningsTaxonomyService.instance.current when available; otherwise
/// falls back to the hardcoded constants in this file.
bool isRowRelevantForPostType({
  required String postType,
  required String metric,
  required String actorRole,
}) {
  final live = EarningsTaxonomyService.instance.current;
  if (live != null) {
    return live.isRowRelevantForPostType(postType, metric, actorRole);
  }
  final caps = _capsFor(postType);
  final required =
      _kRowRequiredCaps['$metric|$actorRole'] ?? const <String>{};
  if (required.isEmpty) return true;
  return required.every(caps.contains);
}

/// Whether the §VIII contributor-role sub-table should render.
bool shouldShowContributorRoles(String postType) {
  final caps = _capsFor(postType);
  return caps.contains(_Caps.visualProduction) || caps.contains(_Caps.audio);
}

/// Filter the §VIII contributor-role list down to roles that make
/// sense for this post type. Reads the
/// `contributor_roles_by_cap` map from the live response when
/// present; otherwise uses the hardcoded fallback below.
List<String> contributorRolesForPostType(String postType) {
  final caps = _capsFor(postType);
  final live = EarningsTaxonomyService.instance.current;
  if (live != null && live.contributorRolesByCap.isNotEmpty) {
    final out = <String>[];
    for (final cap in caps) {
      final roles = live.contributorRolesByCap[cap];
      if (roles != null) out.addAll(roles);
    }
    return out;
  }
  // Fallback (matches backend's CONTRIBUTOR_ROLES_BY_CAP).
  final out = <String>[];
  if (caps.contains(_Caps.visualProduction)) {
    out.addAll(const [
      'photographer',
      'colorist',
      'thumbnail_designer',
      'creative_director',
    ]);
  }
  if (caps.contains(_Caps.timeBased) || caps.contains(_Caps.visual)) {
    out.add('editor');
  }
  if (caps.contains(_Caps.audio)) {
    out.addAll(const ['narrator', 'composer']);
  }
  if (caps.contains(_Caps.text)) {
    out.add('caption_writer');
  }
  return out;
}

/// Whether §V (Clipper / Editor Economy) should render at all.
bool shouldShowClipperSection(String postType) =>
    _capsFor(postType).contains(_Caps.clippable);

/// Whether §VI (Localization & Translation) should render.
bool shouldShowLocalizationSection(String postType) {
  final caps = _capsFor(postType);
  return caps.contains(_Caps.text) || caps.contains(_Caps.audio);
}

/// Whether §X (Commerce & Intent) should render.
bool shouldShowCommerceSection(String postType) =>
    _capsFor(postType).contains(_Caps.shoppable);
