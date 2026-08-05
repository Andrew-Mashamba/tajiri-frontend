// lib/screens/feed/subtitle_composer_screen.dart
//
// UN-007 / posts.md row 51 (subtitle_addition·editor). Lets a user
// add timed subtitle/caption lines to a video post. On submit, sends
// the lines as `metadata` to /posts/{id}/editor-action with
// action_type=subtitle_addition. Each line: {start_ms, end_ms, text}.
//
// Engineering playbook: monochrome (#1A1A1A primary), 48dp targets,
// _rounded icons, AppStringsScope bilingual, maxLines+ellipsis,
// dispose controllers, no FAB — pill button top-right.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../l10n/app_strings_scope.dart';
import '../../models/post_models.dart';
import '../../services/editor_action_service.dart';

class _Line {
  int startMs;
  int endMs;
  TextEditingController text;
  _Line({required this.startMs, required this.endMs, String text = ''})
      : text = TextEditingController(text: text);
}

class SubtitleComposerScreen extends StatefulWidget {
  final Post post;
  final int currentUserId;

  const SubtitleComposerScreen({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  @override
  State<SubtitleComposerScreen> createState() => _SubtitleComposerScreenState();
}

class _SubtitleComposerScreenState extends State<SubtitleComposerScreen> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kSurface = Colors.white;
  static const _kBackground = Color(0xFFFAFAFA);
  static const _kIconBg = Color(0xFFF5F5F5);

  final EditorActionService _service = EditorActionService();
  VideoPlayerController? _video;
  String _locale = 'en';
  final List<_Line> _lines = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _video?.dispose();
    for (final l in _lines) {
      l.text.dispose();
    }
    super.dispose();
  }

  Future<void> _initVideo() async {
    final url = widget.post.media.isNotEmpty
        ? widget.post.media.first.fileUrl
        : null;
    if (url == null || url.isEmpty) return;
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _video = ctrl);
    } catch (_) {
      // No video — still allow editing if author wants to caption an image.
    }
  }

  void _addLine() {
    final lastEnd = _lines.isEmpty ? 0 : _lines.last.endMs;
    setState(() => _lines.add(_Line(
          startMs: lastEnd,
          endMs: lastEnd + 3000,
        )));
  }

  void _removeLine(int idx) {
    setState(() {
      _lines[idx].text.dispose();
      _lines.removeAt(idx);
    });
  }

  Future<void> _submit() async {
    if (_busy || _lines.isEmpty) return;
    final cleaned = _lines
        .where((l) => l.text.text.trim().isNotEmpty && l.endMs > l.startMs)
        .map((l) => {
              'start_ms': l.startMs,
              'end_ms': l.endMs,
              'text': l.text.text.trim(),
            })
        .toList();
    if (cleaned.isEmpty) return;

    setState(() => _busy = true);
    final id = await _service.submit(
      postId: widget.post.id,
      editorUserId: widget.currentUserId,
      actionType: 'subtitle_addition',
      metadata: {
        'locale': _locale,
        'lines': cleaned,
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (id != null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subtitles submitted — earnings will accrue on each view.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit subtitles')),
      );
    }
  }

  String _fmt(int ms) {
    final s = (ms / 1000).floor();
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    final cs = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$mm:$ss.$cs';
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
        scrolledUnderElevation: 1,
        title: Text(
          isSw ? 'Ongeza maelezo' : 'Add subtitles',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _busy || _lines.isEmpty ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: _kSurface,
                elevation: 0,
                disabledBackgroundColor: _kBorder,
                minimumSize: const Size(72, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kSurface),
                    )
                  : Text(
                      isSw ? 'Tuma' : 'Submit',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_video != null)
              AspectRatio(
                aspectRatio: _video!.value.aspectRatio,
                child: Container(color: Colors.black, child: VideoPlayer(_video!)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isSw ? 'Lugha ya maelezo' : 'Subtitle language',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  _LocalePill(
                    locale: _locale,
                    onChanged: (v) => setState(() => _locale = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _lines.isEmpty
                  ? _EmptyView(isSw: isSw, onAdd: _addLine)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _lines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _LineCard(
                        index: i,
                        line: _lines[i],
                        videoDurationMs: _video?.value.duration.inMilliseconds ?? 600000,
                        fmt: _fmt,
                        onChange: () => setState(() {}),
                        onRemove: () => _removeLine(i),
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add_rounded, size: 20, color: _kPrimary),
                    label: Text(
                      isSw ? 'Ongeza mstari' : 'Add line',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalePill extends StatelessWidget {
  final String locale;
  final ValueChanged<String> onChanged;
  const _LocalePill({required this.locale, required this.onChanged});

  static const _locales = [
    ('en', 'English'),
    ('sw', 'Kiswahili'),
    ('fr', 'Français'),
    ('ar', 'العربية'),
    ('pt', 'Português'),
  ];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ..._locales.map(
                  (l) => ListTile(
                    title: Text(l.$2,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A))),
                    trailing: locale == l.$1
                        ? const Icon(Icons.check_rounded, color: Color(0xFF1A1A1A))
                        : null,
                    onTap: () => Navigator.pop(ctx, l.$1),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locale.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: Color(0xFF1A1A1A)),
          ],
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final int index;
  final _Line line;
  final int videoDurationMs;
  final String Function(int) fmt;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  const _LineCard({
    required this.index,
    required this.line,
    required this.videoDurationMs,
    required this.fmt,
    required this.onChange,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${fmt(line.startMs)}  →  ${fmt(line.endMs)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: Color(0xFF666666)),
                tooltip: 'Remove',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            min: 0,
            max: videoDurationMs.toDouble(),
            values: RangeValues(line.startMs.toDouble(), line.endMs.toDouble()),
            activeColor: const Color(0xFF1A1A1A),
            inactiveColor: const Color(0xFFE5E5E5),
            onChanged: (v) {
              line.startMs = v.start.round();
              line.endMs = v.end.round();
              onChange();
            },
          ),
          TextField(
            controller: line.text,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: 'Subtitle text…',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isSw;
  final VoidCallback onAdd;
  const _EmptyView({required this.isSw, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.subtitles_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            isSw ? 'Hakuna mistari bado' : 'No subtitle lines yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            isSw
                ? 'Bonyeza Ongeza kuanza'
                : 'Tap Add line to start',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
