// lib/creator/models/stream_type_earnings_taxonomy.dart
//
// Sister taxonomy to lib/creator/models/post_type_earnings_taxonomy.dart,
// for live streams. Reads the live (server-served) taxonomy from
// EarningsTaxonomyService.instance.current; falls back to the
// hardcoded constants below when the cache is empty AND the network
// is unreachable on first launch.
//
// Source of truth (backend): app/Services/Earnings/EarningsTaxonomy.php
// Source of truth (doc):    docs/creators/streams/strategies/streams.md

import 'package:flutter/material.dart';

import '../services/earnings_taxonomy_service.dart';

class _Caps {
  static const String visual = 'visual';
  static const String audio = 'audio';
  static const String clippable = 'clippable';
  static const String shoppable = 'shoppable';
  static const String multiHost = 'multi_host';
  static const String paywalled = 'paywalled';
  static const String original = 'original';
  static const String timeBased = 'time_based';
}

const Map<String, Set<String>> _kStreamTypeCaps = {
  'live_video': {
    _Caps.visual, _Caps.audio, _Caps.clippable, _Caps.shoppable,
    _Caps.original, _Caps.timeBased,
  },
  'audio_only': {
    _Caps.audio, _Caps.clippable, _Caps.shoppable, _Caps.original,
    _Caps.timeBased,
  },
  'simulcast': {
    _Caps.visual, _Caps.audio, _Caps.shoppable, _Caps.timeBased,
  },
  'subscriber_only': {
    _Caps.visual, _Caps.audio, _Caps.clippable, _Caps.paywalled,
    _Caps.original, _Caps.timeBased,
  },
  'paid_attendance': {
    _Caps.visual, _Caps.audio, _Caps.clippable, _Caps.shoppable,
    _Caps.paywalled, _Caps.original, _Caps.timeBased,
  },
  'co_streaming': {
    _Caps.visual, _Caps.audio, _Caps.clippable, _Caps.shoppable,
    _Caps.multiHost, _Caps.original, _Caps.timeBased,
  },
};

const Map<String, Set<String>> _kStreamRowRequiredCaps = {
  // §I — universal except where noted
  'live_view|author': <String>{},
  'live_watch_minute|author': {_Caps.timeBased},
  'live_reaction|author': <String>{},
  'live_chat|author': <String>{},
  'live_super_chat|author': <String>{},
  'live_gift|author': <String>{},
  'live_tip|author': <String>{},
  'follow_from_live|author': <String>{},
  'subscribe_from_live|author': <String>{},
  'resub_during_live|author': <String>{},
  'notify_live_optin|author': <String>{},
  'peak_concurrent_milestone|author': <String>{},
  'stream_duration_bonus|author': {_Caps.timeBased},
  'consistency_bonus|author': <String>{},
  'profile_visit_from_live|author': <String>{},
  'screenshot_during_live|author': {_Caps.visual},
  'notify_followers_optin|author': <String>{},
  // §II
  'chat_reaction|chat_author': <String>{},
  'chat_pin|author': <String>{},
  'q_and_a_upvote|question_author': <String>{},
  'q_and_a_answered|question_author': <String>{},
  'unique_chatter_bonus|author': <String>{},
  'cross_lingual_chat_bonus|author': <String>{},
  'mod_action_quality_bonus|moderator': <String>{},
  // §III
  'stream_share|sharer': <String>{},
  'view_from_share|sharer': <String>{},
  'follow_from_stream_share|sharer': <String>{},
  'raid_in|raid_streamer': <String>{},
  'host_in|host_streamer': <String>{},
  'external_link_click|author': {_Caps.shoppable},
  'profile_visit_from_stream_share|sharer': <String>{},
  'cross_post_view|sharer': <String>{},
  // §IV
  'vod_view|author': <String>{},
  'vod_watch_second|author': {_Caps.timeBased},
  'clip_from_stream|clipper': {_Caps.clippable},
  'clip_view|clipper': {_Caps.clippable},
  'clip_conversion|clipper': {_Caps.clippable},
  'highlight_compilation|editor': {_Caps.clippable},
  'derivative_royalty|author': <String>{},
  // §V
  'live_caption_create|captioner': <String>{},
  'subtitle_localization|translator': {_Caps.timeBased},
  'dub_overlay|voice_actor': {_Caps.audio},
  'translated_vod_view|translator': <String>{},
  // §VI
  'category_feature|curator': <String>{},
  'collection_add|curator': <String>{},
  'recommendation_bonus|author': <String>{},
  // §VII (multi-host gated)
  'cohost_split|cohost': {_Caps.multiHost},
  'battle_winner_bonus|author': {_Caps.multiHost},
  'battle_participation|author': {_Caps.multiHost},
  'guest_appearance|guest': <String>{},
  // §VIII
  'tutorial_completion|author': <String>{},
  'bookmark_for_later|author': <String>{},
  'transcript_save|author': <String>{},
  // §IX (shoppable gated)
  'live_product_show|author': {_Caps.shoppable},
  'live_product_expand|author': {_Caps.shoppable},
  'live_wishlist_add|author': {_Caps.shoppable},
  'live_purchase|author': {_Caps.shoppable},
  'affiliate_conversion|author': {_Caps.shoppable},
  'local_business_booking|author': {_Caps.shoppable},
  // §XI AI
  'ai_clip_generation|author': <String>{},
  'ai_voice_clone_usage|author': {_Caps.audio},
  'ai_assisted_remix|remixer': <String>{},
  'synthetic_avatar_disclosed|author': <String>{},
  // §XII community
  'moderation_quality|moderator': <String>{},
  'retention_loop|author': <String>{},
  'mentorship_to_smaller_streamer|author': <String>{},
  'community_retention_bonus|author': <String>{},
};

class StreamTypeEarningsConfig {
  final String wire;
  final String labelEn;
  final String labelSw;
  final IconData icon;
  final String routeId;
  const StreamTypeEarningsConfig({
    required this.wire,
    required this.labelEn,
    required this.labelSw,
    required this.icon,
    required this.routeId,
  });
}

const Map<String, StreamTypeEarningsConfig> kStreamTypeEarningsConfigs = {
  'live_video': StreamTypeEarningsConfig(
    wire: 'live_video',
    labelEn: 'Live video',
    labelSw: 'Video ya moja kwa moja',
    icon: Icons.live_tv_rounded,
    routeId: 'live_video_earnings',
  ),
  'audio_only': StreamTypeEarningsConfig(
    wire: 'audio_only',
    labelEn: 'Audio room',
    labelSw: 'Chumba cha sauti',
    icon: Icons.mic_rounded,
    routeId: 'audio_only_earnings',
  ),
  'simulcast': StreamTypeEarningsConfig(
    wire: 'simulcast',
    labelEn: 'Simulcast',
    labelSw: 'Mtiririko wa pamoja',
    icon: Icons.cast_connected_rounded,
    routeId: 'simulcast_earnings',
  ),
  'subscriber_only': StreamTypeEarningsConfig(
    wire: 'subscriber_only',
    labelEn: 'Subscriber-only',
    labelSw: 'Wanachama tu',
    icon: Icons.workspace_premium_rounded,
    routeId: 'subscriber_only_earnings',
  ),
  'paid_attendance': StreamTypeEarningsConfig(
    wire: 'paid_attendance',
    labelEn: 'Paid attendance',
    labelSw: 'Tikiti ya kuingia',
    icon: Icons.confirmation_number_rounded,
    routeId: 'paid_attendance_earnings',
  ),
  'co_streaming': StreamTypeEarningsConfig(
    wire: 'co_streaming',
    labelEn: 'Co-streaming',
    labelSw: 'Pamoja na wenzio',
    icon: Icons.groups_rounded,
    routeId: 'co_streaming_earnings',
  ),
};

IconData _iconForKey(String key) {
  switch (key) {
    case 'live_tv_rounded':            return Icons.live_tv_rounded;
    case 'mic_rounded':                return Icons.mic_rounded;
    case 'cast_connected_rounded':     return Icons.cast_connected_rounded;
    case 'workspace_premium_rounded':  return Icons.workspace_premium_rounded;
    case 'confirmation_number_rounded':return Icons.confirmation_number_rounded;
    case 'groups_rounded':             return Icons.groups_rounded;
    default:                           return Icons.live_tv_rounded;
  }
}

/// Service-first config accessor — UI callers should use this helper.
StreamTypeEarningsConfig? streamTypeEarningsConfigFor(String streamType) {
  final live = EarningsTaxonomyService.instance.current;
  if (live != null) {
    final cfg = live.streamTypes[streamType];
    if (cfg != null) {
      return StreamTypeEarningsConfig(
        wire: cfg.wire,
        labelEn: cfg.labelEn,
        labelSw: cfg.labelSw,
        icon: _iconForKey(cfg.iconKey),
        routeId: '${streamType}_earnings',
      );
    }
  }
  return kStreamTypeEarningsConfigs[streamType];
}

Set<String> _capsFor(String streamType) {
  final live = EarningsTaxonomyService.instance.current;
  if (live != null) {
    final cfg = live.streamTypes[streamType];
    if (cfg != null) return cfg.caps;
  }
  return _kStreamTypeCaps[streamType] ?? const <String>{};
}

/// Returns true if the given (metric, actor_role) row is relevant
/// for the given stream_type.
bool isStreamRowRelevantForStreamType({
  required String streamType,
  required String metric,
  required String actorRole,
}) {
  final live = EarningsTaxonomyService.instance.current;
  if (live != null) {
    return live.isStreamRowRelevantForStreamType(streamType, metric, actorRole);
  }
  final caps = _capsFor(streamType);
  final required =
      _kStreamRowRequiredCaps['$metric|$actorRole'] ?? const <String>{};
  if (required.isEmpty) return true;
  return required.every(caps.contains);
}

bool shouldShowStreamMultiHostSection(String streamType) =>
    _capsFor(streamType).contains(_Caps.multiHost);

bool shouldShowStreamCommerceSection(String streamType) =>
    _capsFor(streamType).contains(_Caps.shoppable);

bool shouldShowStreamClipperSection(String streamType) =>
    _capsFor(streamType).contains(_Caps.clippable);
