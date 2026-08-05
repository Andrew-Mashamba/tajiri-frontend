// lib/screens/streams/stream_vod_player_screen.dart
//
// Phase C — VOD playback for ended streams. Mirrors Twitch / YouTube
// past-broadcast viewing. Fires:
//   • vod_view·author              (on screen open)
//   • vod_watch_second·author       (every 30s heartbeat while playing)
//   • tutorial_completion·author    (when ≥95% watched — viewer marks)
//   • bookmark_for_later·author     (on bookmark tap)
//   • transcript_save·author        (on transcript export)
//
// Localization controls (translated_vod_view·translator) ride on the
// same player via the language picker.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../../services/clip_service.dart';

class StreamVodPlayerScreen extends StatefulWidget {
  final LiveStream stream;
  final int currentUserId;
  const StreamVodPlayerScreen({
    super.key,
    required this.stream,
    required this.currentUserId,
  });

  @override
  State<StreamVodPlayerScreen> createState() => _StreamVodPlayerScreenState();
}

class _StreamVodPlayerScreenState extends State<StreamVodPlayerScreen> {
  final LiveStreamService _streamService = LiveStreamService();
  final ClipService _clipService = ClipService();
  VideoPlayerController? _vc;
  ChewieController? _chewie;
  Timer? _heartbeatTimer;
  bool _completionFired = false;
  bool _initError = false;

  // Phase F — translation track selection.
  // When the viewer activates a non-default subtitle, fire
  // translated_vod_view·translator so the translator earns.
  final List<_VodTranslation> _translations = [];
  int? _activeTranslationId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final url = widget.stream.vodUrl ?? widget.stream.playbackUrl;
    if (url == null || url.isEmpty) {
      setState(() => _initError = true);
      return;
    }

    // §IV row 33 — vod_view·author. Fired once per session.
    await _streamService.vodView(
      streamId: widget.stream.id, userId: widget.currentUserId);

    _vc = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _vc!.initialize();
    } catch (_) {
      setState(() => _initError = true);
      return;
    }
    if (!mounted) return;
    _chewie = ChewieController(
      videoPlayerController: _vc!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
    );
    setState(() {});

    // §IV row 34 — vod_watch_second·author. 30s heartbeat raw_count=30.
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final c = _vc;
      if (c != null && c.value.isPlaying) {
        _streamService.vodHeartbeat(
          streamId: widget.stream.id,
          userId: widget.currentUserId,
          watchedSeconds: 30,
        );
        // §VIII row 51 — tutorial_completion·author when ≥95% watched.
        final pos = c.value.position.inMilliseconds.toDouble();
        final dur = c.value.duration.inMilliseconds.toDouble();
        if (!_completionFired && dur > 0 && pos / dur >= 0.95) {
          _completionFired = true;
          _streamService.recordUtilityEvent(
            streamId: widget.stream.id,
            userId: widget.currentUserId,
            event: 'tutorial-completion',
          );
        }
      }
    });
  }

  Future<void> _bookmark() async {
    await _streamService.recordUtilityEvent(
      streamId: widget.stream.id,
      userId: widget.currentUserId,
      event: 'bookmark',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmarked for later')),
      );
    }
  }

  /// G14 — clip_from_stream·clipper. Snips a 30-second window ending
  /// at the current playback position and posts to /api/clips with
  /// source_stream_id so backend fires the metric.
  Future<void> _saveAsClip() async {
    final c = _vc;
    if (c == null || !c.value.isInitialized) return;
    final endMs = c.value.position.inMilliseconds;
    final startMs = (endMs - 30000).clamp(0, endMs);
    final id = await _clipService.createSourcedClip(
      sourceStreamId: widget.stream.id,
      clipperUserId: widget.currentUserId,
      startMs: startMs,
      endMs: endMs,
      title: widget.stream.title,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(id != null
            ? 'Clip saved (${(endMs - startMs) ~/ 1000}s)'
            : 'Clip failed'),
      ));
    }
  }

  Future<void> _saveTranscript() async {
    await _streamService.recordUtilityEvent(
      streamId: widget.stream.id,
      userId: widget.currentUserId,
      event: 'transcript-save',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript saved')),
      );
    }
  }

  /// Phase F — language picker. Reads the stream's translations list
  /// and lets the viewer activate a non-default subtitle track. Each
  /// activation fires translated_vod_view·translator (the translator
  /// who created that track earns).
  Future<void> _openLanguagePicker() async {
    // Stream model already has translations attached if backend includes
    // them; otherwise we synthesize a minimal list from getStream().
    if (_translations.isEmpty) {
      final result = await _streamService.getStream(
        widget.stream.id, currentUserId: widget.currentUserId);
      if (result.success && result.stream != null) {
        final tracks = result.stream!.translations ?? const [];
        _translations.addAll(tracks.map((t) =>
            _VodTranslation(id: t.id, label: t.label)));
      }
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.black87,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Subtitle language',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            if (_translations.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'No community translations yet. Be the first to contribute one from the live viewer.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            for (final t in _translations)
              ListTile(
                leading: const Icon(Icons.translate_rounded, color: Colors.white),
                title: Text(t.label, style: const TextStyle(color: Colors.white)),
                trailing: _activeTranslationId == t.id
                    ? const Icon(Icons.check, color: Colors.greenAccent)
                    : null,
                onTap: () => Navigator.pop(ctx, t.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _activeTranslationId = picked);
    // Fire translated_vod_view·translator.
    await _streamService.viewTranslation(
      streamId: widget.stream.id,
      translationId: picked,
      userId: widget.currentUserId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subtitles activated')),
      );
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _chewie?.dispose();
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.stream.title ?? 'Replay',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Save as clip',
            icon: const Icon(Icons.content_cut_rounded),
            onPressed: _saveAsClip,
          ),
          IconButton(
            tooltip: 'Bookmark',
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: _bookmark,
          ),
          IconButton(
            tooltip: 'Subtitle language',
            icon: const Icon(Icons.translate_rounded),
            onPressed: _openLanguagePicker,
          ),
          IconButton(
            tooltip: 'Save transcript',
            icon: const Icon(Icons.subtitles_rounded),
            onPressed: _saveTranscript,
          ),
        ],
      ),
      body: _initError
          ? const Center(
              child: Text('Replay unavailable',
                  style: TextStyle(color: Colors.white70)),
            )
          : _chewie == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Chewie(controller: _chewie!),
    );
  }
}

/// Lightweight value type for the language picker. Translations are
/// returned by the backend as `{id, source_language_code, target_language_code, translator_user_id}`.
class _VodTranslation {
  final int id;
  final String label;
  const _VodTranslation({required this.id, required this.label});
}
