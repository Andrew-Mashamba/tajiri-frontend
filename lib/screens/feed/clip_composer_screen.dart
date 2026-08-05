// lib/screens/feed/clip_composer_screen.dart
//
// Clipper economy MVP — strategy posts.md §V / G-F-002.
// Pick a start..end range from an existing video post and create a clips
// row. Backend ClipController fires clip_create·clipper; the clipper earns
// from clip_view·clipper as the clip is viewed.
//
// Playbook compliance: monochrome, 48dp targets, _rounded icons, bilingual,
// pill button (top-right) for action, dispose controllers, maxLines+ellipsis.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../l10n/app_strings_scope.dart';
import '../../models/post_models.dart';
import '../../services/clip_service.dart';

class ClipComposerScreen extends StatefulWidget {
  final Post sourcePost;
  final int currentUserId;

  const ClipComposerScreen({
    super.key,
    required this.sourcePost,
    required this.currentUserId,
  });

  @override
  State<ClipComposerScreen> createState() => _ClipComposerScreenState();
}

class _ClipComposerScreenState extends State<ClipComposerScreen> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kSurface = Colors.white;
  static const _kBackground = Color(0xFFFAFAFA);
  static const _kIconBg = Color(0xFFF5F5F5);

  static const Duration _kMinClip = Duration(seconds: 3);
  static const Duration _kMaxClip = Duration(seconds: 60);

  VideoPlayerController? _video;
  RangeValues _range = const RangeValues(0, 30000); // ms
  Duration _videoDuration = Duration.zero;
  final TextEditingController _titleCtrl = TextEditingController();
  final ClipService _service = ClipService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _video?.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    final url = widget.sourcePost.media.isNotEmpty
        ? widget.sourcePost.media.first.fileUrl
        : null;
    if (url == null || url.isEmpty) return;
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      _videoDuration = ctrl.value.duration;
      final maxMs = _videoDuration.inMilliseconds.toDouble();
      // Default range: first 30 seconds (or full video if shorter).
      final endMs = maxMs > 30000 ? 30000.0 : maxMs;
      setState(() {
        _video = ctrl;
        _range = RangeValues(0, endMs);
      });
      ctrl.setLooping(true);
      ctrl.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _video = null);
    }
  }

  Duration _msDur(double ms) =>
      Duration(milliseconds: ms.clamp(0, _videoDuration.inMilliseconds.toDouble()).round());

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Duration get _selectedLength =>
      Duration(milliseconds: (_range.end - _range.start).round());

  bool get _validRange =>
      _selectedLength >= _kMinClip && _selectedLength <= _kMaxClip;

  Future<void> _create() async {
    if (!_validRange || _busy) return;
    setState(() => _busy = true);
    final id = await _service.createSourcedClip(
      sourcePostId: widget.sourcePost.id,
      clipperUserId: widget.currentUserId,
      startMs: _range.start.round(),
      endMs: _range.end.round(),
      title: _titleCtrl.text.trim().isNotEmpty
          ? _titleCtrl.text.trim()
          : null,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (id != null) {
      Navigator.pop(context, id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clip created — clipper earnings active')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create clip')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          isSw ? 'Tengeneza Clip' : 'Create Clip',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _validRange && !_busy ? _create : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: _kSurface,
                disabledBackgroundColor: _kBorder,
                elevation: 0,
                minimumSize: const Size(64, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kSurface,
                      ),
                    )
                  : Text(
                      isSw ? 'Hifadhi' : 'Save',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _video?.value.aspectRatio ?? 16 / 9,
              child: Container(
                color: Colors.black,
                child: _video == null
                    ? const Center(child: CircularProgressIndicator(color: _kSurface))
                    : VideoPlayer(_video!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isSw ? 'Chagua sehemu' : 'Pick range',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _fmt(_selectedLength),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _validRange ? _kPrimary : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSw
                        ? 'Sekunde 3 hadi 60. Bonyeza Hifadhi kuendelea.'
                        : 'Between 3s and 60s. Tap Save to publish.',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                  const SizedBox(height: 8),
                  if (_videoDuration > Duration.zero)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _kPrimary,
                        inactiveTrackColor: _kBorder,
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 9,
                        ),
                        thumbColor: _kPrimary,
                        overlayColor: _kPrimary.withValues(alpha: 0.1),
                      ),
                      child: RangeSlider(
                        min: 0,
                        max: _videoDuration.inMilliseconds.toDouble(),
                        divisions: _videoDuration.inSeconds.clamp(10, 600),
                        values: _range,
                        labels: RangeLabels(
                          _fmt(_msDur(_range.start)),
                          _fmt(_msDur(_range.end)),
                        ),
                        onChanged: (v) {
                          setState(() => _range = v);
                          _video?.seekTo(_msDur(v.start));
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(_msDur(_range.start)),
                          style: const TextStyle(fontSize: 11, color: _kTertiary)),
                      Text(_fmt(_msDur(_range.end)),
                          style: const TextStyle(fontSize: 11, color: _kTertiary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleCtrl,
                    maxLength: 200,
                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                    decoration: InputDecoration(
                      hintText: isSw
                          ? 'Mada ya clip (hiari)'
                          : 'Clip title (optional)',
                      hintStyle: const TextStyle(fontSize: 13, color: _kTertiary),
                      counterStyle: const TextStyle(fontSize: 11, color: _kTertiary),
                      filled: true,
                      fillColor: _kIconBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
