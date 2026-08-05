// lib/screens/feed/clip_detail_screen.dart
//
// UN-005 / posts.md row 49 (clip_view·clipper) + UN-006 / row 50
// (clip_conversion·clipper). Plays a §V clipper-economy clip and
// records the view; follow button passes origin_clip_id so the
// clipper earns when a viewer converts.
//
// Engineering playbook: monochrome (#1A1A1A primary), 48dp targets,
// _rounded icons, AppStringsScope bilingual, maxLines+ellipsis,
// dispose controllers, no FAB.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../l10n/app_strings_scope.dart';
import '../../models/clip_models.dart';
import '../../services/clip_service.dart';
import '../../services/friend_service.dart';

class ClipDetailScreen extends StatefulWidget {
  final int clipId;
  final int currentUserId;

  const ClipDetailScreen({
    super.key,
    required this.clipId,
    required this.currentUserId,
  });

  @override
  State<ClipDetailScreen> createState() => _ClipDetailScreenState();
}

class _ClipDetailScreenState extends State<ClipDetailScreen> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kSurface = Colors.white;
  static const _kBackground = Color(0xFFFAFAFA);

  final ClipService _clipService = ClipService();
  final FriendService _friendService = FriendService();
  Clip? _clip;
  VideoPlayerController? _video;
  bool _loading = true;
  bool _following = false;
  bool _followBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final res = await _clipService.getClip(widget.clipId, currentUserId: widget.currentUserId);
    if (!mounted) return;
    if (!res.success || res.clip == null) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Clip not found';
      });
      return;
    }
    // UN-005 / row 49 — clip_view·clipper.
    unawaited(_clipService.viewClip(widget.clipId, userId: widget.currentUserId));

    final clip = res.clip!;
    final url = clip.videoUrl;
    VideoPlayerController? ctrl;
    try {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.play();
    } catch (_) {
      ctrl = null;
    }

    if (!mounted) return;
    setState(() {
      _clip = clip;
      _video = ctrl;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final clip = _clip;
    if (clip == null || _followBusy) return;
    setState(() => _followBusy = true);
    final ok = _following
        ? await _friendService.unfollowUser(widget.currentUserId, clip.userId)
        // UN-006 / row 50: pass originClipId so the clipper earns
        // clip_conversion when this follow originated from a clip view.
        : await _friendService.followUser(
            widget.currentUserId,
            clip.userId,
            originClipId: clip.id,
          );
    if (!mounted) return;
    setState(() {
      _followBusy = false;
      if (ok) _following = !_following;
    });
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
          isSw ? 'Clip' : 'Clip',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              )
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _hydrate)
                : _buildBody(isSw),
      ),
    );
  }

  Widget _buildBody(bool isSw) {
    final clip = _clip!;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _video?.value.aspectRatio ?? 9 / 16,
          child: Container(
            color: Colors.black,
            child: _video == null
                ? const Center(
                    child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                  )
                : VideoPlayer(_video!),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (clip.user != null)
                      Text(
                        '@${clip.user!.username ?? clip.user!.firstName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    if (clip.caption != null && clip.caption!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        clip.caption!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${clip.viewsCount} ${isSw ? "watazamaji" : "views"}',
                      style: const TextStyle(fontSize: 11, color: _kTertiary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _followBusy ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _following ? _kSurface : _kPrimary,
                    foregroundColor: _following ? _kPrimary : _kSurface,
                    elevation: 0,
                    side: BorderSide(color: _kPrimary, width: _following ? 1 : 0),
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _followBusy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _following
                              ? (isSw ? 'Inafuata' : 'Following')
                              : (isSw ? 'Fuata' : 'Follow'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              minimumSize: const Size(120, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
