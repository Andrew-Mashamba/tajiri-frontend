// lib/widgets/editor_action_sheet.dart
//
// UN-007/8/9 — strategy posts.md §V rows 51-53. Bottom sheet that
// routes to the 3 editor actions:
//   - Subtitle addition  → SubtitleComposerScreen (full screen)
//   - Format adaptation  → inline aspect-ratio picker
//   - Highlight selection → inline range slider
//
// Each fires POST /posts/{id}/editor-action with the matching action_type
// so the editor earns subtitle_addition / format_adaptation /
// highlight_selection per the spec.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_strings_scope.dart';
import '../models/post_models.dart';
import '../screens/feed/subtitle_composer_screen.dart';
import '../services/editor_action_service.dart';

class EditorActionSheet extends StatelessWidget {
  final Post post;
  final int currentUserId;

  const EditorActionSheet({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  static Future<void> show(
    BuildContext context, {
    required Post post,
    required int currentUserId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditorActionSheet(
        post: post,
        currentUserId: currentUserId,
      ),
    );
  }

  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kIconBg = Color(0xFFF5F5F5);

  void _openSubtitleComposer(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubtitleComposerScreen(
          post: post,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  Future<void> _openFormatPicker(BuildContext context) async {
    Navigator.pop(context); // close routing sheet
    await _FormatAdaptationSheet.show(
      context,
      post: post,
      currentUserId: currentUserId,
    );
  }

  Future<void> _openHighlightPicker(BuildContext context) async {
    Navigator.pop(context); // close routing sheet
    await _HighlightPickerSheet.show(
      context,
      post: post,
      currentUserId: currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isSw ? 'Hariri chapisho' : 'Editor tools',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              isSw
                  ? 'Pata mapato kwa kazi yako kama mhariri.'
                  : 'Earn as an editor when viewers engage with your edits.',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ),
          _ActionTile(
            icon: Icons.subtitles_rounded,
            label: isSw ? 'Ongeza maelezo' : 'Add subtitles',
            subtitle: isSw
                ? 'Andika mistari ya muda kwenye video'
                : 'Write timed lines for the video',
            onTap: () => _openSubtitleComposer(context),
          ),
          const Divider(height: 1, color: _kBorder),
          _ActionTile(
            icon: Icons.aspect_ratio_rounded,
            label: isSw ? 'Geuza umbo' : 'Adapt format',
            subtitle: isSw
                ? 'Pendekeza uwiano mpya wa picha'
                : 'Suggest a new aspect ratio',
            onTap: () => _openFormatPicker(context),
          ),
          const Divider(height: 1, color: _kBorder),
          _ActionTile(
            icon: Icons.auto_awesome_motion_rounded,
            label: isSw ? 'Chagua sehemu kuu' : 'Pick a highlight',
            subtitle: isSw
                ? 'Onyesha sehemu bora kwa watazamaji'
                : 'Mark the best moment for viewers',
            onTap: () => _openHighlightPicker(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EditorActionSheet._kIconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: EditorActionSheet._kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: EditorActionSheet._kPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EditorActionSheet._kSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: EditorActionSheet._kSecondary),
          ],
        ),
      ),
    );
  }
}

// ── UN-008 Format adaptation ─────────────────────────────────────────

class _FormatAdaptationSheet extends StatefulWidget {
  final Post post;
  final int currentUserId;
  const _FormatAdaptationSheet({
    required this.post,
    required this.currentUserId,
  });

  static Future<void> show(
    BuildContext context, {
    required Post post,
    required int currentUserId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FormatAdaptationSheet(
        post: post,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  State<_FormatAdaptationSheet> createState() => _FormatAdaptationSheetState();
}

class _FormatAdaptationSheetState extends State<_FormatAdaptationSheet> {
  final EditorActionService _service = EditorActionService();
  String _ratio = '9:16';
  String _platform = 'tiktok';
  bool _busy = false;

  static const _ratios = ['9:16', '1:1', '4:5', '16:9', '4:3'];
  static const _platforms = ['tiktok', 'instagram', 'youtube_shorts', 'twitter', 'general'];

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final id = await _service.submit(
      postId: widget.post.id,
      editorUserId: widget.currentUserId,
      actionType: 'format_adaptation',
      metadata: {'ratio': _ratio, 'platform': _platform},
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (id != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format adaptation submitted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isSw ? 'Geuza umbo' : 'Adapt format',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                isSw ? 'Uwiano' : 'Aspect ratio',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _ratios
                    .map((r) => _Chip(
                          label: r,
                          selected: _ratio == r,
                          onTap: () => setState(() => _ratio = r),
                        ))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                isSw ? 'Jukwaa' : 'Target platform',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _platforms
                    .map((p) => _Chip(
                          label: p.replaceAll('_', ' '),
                          selected: _platform == p,
                          onTap: () => setState(() => _platform = p),
                        ))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isSw ? 'Tuma' : 'Submit',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
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

// ── UN-009 Highlight selection ──────────────────────────────────────

class _HighlightPickerSheet extends StatefulWidget {
  final Post post;
  final int currentUserId;
  const _HighlightPickerSheet({
    required this.post,
    required this.currentUserId,
  });

  static Future<void> show(
    BuildContext context, {
    required Post post,
    required int currentUserId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _HighlightPickerSheet(
        post: post,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  State<_HighlightPickerSheet> createState() => _HighlightPickerSheetState();
}

class _HighlightPickerSheetState extends State<_HighlightPickerSheet> {
  final EditorActionService _service = EditorActionService();
  VideoPlayerController? _video;
  RangeValues _range = const RangeValues(0, 15000);
  Duration _duration = const Duration(seconds: 60);
  final TextEditingController _label = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _video?.dispose();
    _label.dispose();
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
      setState(() {
        _video = ctrl;
        _duration = ctrl.value.duration;
        _range = RangeValues(0, _duration.inMilliseconds.toDouble().clamp(0, 15000));
      });
    } catch (_) {}
  }

  String _fmt(int ms) {
    final s = (ms / 1000).floor();
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final id = await _service.submit(
      postId: widget.post.id,
      editorUserId: widget.currentUserId,
      actionType: 'highlight_selection',
      metadata: {
        'start_ms': _range.start.round(),
        'end_ms': _range.end.round(),
        if (_label.text.trim().isNotEmpty) 'label': _label.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (id != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Highlight submitted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final maxMs = _duration.inMilliseconds == 0 ? 60000 : _duration.inMilliseconds;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isSw ? 'Chagua sehemu kuu' : 'Pick a highlight',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (_video != null)
              AspectRatio(
                aspectRatio: _video!.value.aspectRatio,
                child: Container(color: Colors.black, child: VideoPlayer(_video!)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(_fmt(_range.start.round()),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666))),
                  const Spacer(),
                  Text(
                    '${_fmt((_range.end - _range.start).round())} ${isSw ? "uzito" : "duration"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  Text(_fmt(_range.end.round()),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RangeSlider(
                min: 0,
                max: maxMs.toDouble(),
                values: _range,
                activeColor: const Color(0xFF1A1A1A),
                inactiveColor: const Color(0xFFE5E5E5),
                onChanged: (v) {
                  setState(() => _range = v);
                  _video?.seekTo(Duration(milliseconds: v.start.round()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: isSw ? 'Lebo (hiari)' : 'Label (optional)',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isSw ? 'Tuma' : 'Submit',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFE5E5E5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
