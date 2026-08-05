/// Story 58: Watch Live Stream
/// Full-screen video, overlay chat, reactions, gifts, share, tips.
/// Navigation: Home → Feed → Live tab → Tap stream OR Profile → Live tab → Tap.
///
/// Phase A wiring (streams.md §I-§IX):
///  - reactions, heartbeat, screenshot, share, super-chat, Q&A
///  - share_uid deep-link plumbing (view_from_share·sharer)
///  - viewer overflow menu (4 negative-attribution signals)
///  - rapid_leave + session_exit_after_join detection
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_capture_event/screen_capture_event.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../../services/friend_service.dart';
import '../../services/profile_service.dart';
import '../../services/websocket_service.dart';
import '../../services/battle_mode_service.dart' show BattleModeService, BattleState, BattleInvite, BattleStatus;
import '../../widgets/battle_mode_overlay.dart';
import '../../config/api_config.dart';
import '../../services/local_storage_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../wallet/send_tip_screen.dart';
import '../wallet/subscribe_to_creator_screen.dart';
import 'battlemodeoverlay_screen.dart';
import '../../models/ad_models.dart';
import '../../services/ad_service.dart';
import '../../widgets/story_ad_overlay.dart';
import '../../widgets/stream_sponsor_badge.dart';

/// Minimum touch target per DOCS/DESIGN.md (48dp)
const double _kMinTouchTarget = 48.0;

class StreamViewerScreen extends StatefulWidget {
  final LiveStream stream;
  final int currentUserId;
  /// A.6 — when viewer arrives via a shared link, pass through so backend
  /// fires `view_from_share·sharer` for the original sharer.
  final String? shareUid;
  /// Phase F — when viewer arrives from an external cross-post link
  /// (TikTok / IG / YT / FB / X / WhatsApp), the deep-link parser passes
  /// the originating sharer's user_id and platform so backend fires
  /// `cross_post_view·sharer` (Lever 4 attribution).
  final int? crossPostSharerId;
  final String? crossPostPlatform;

  const StreamViewerScreen({
    super.key,
    required this.stream,
    required this.currentUserId,
    this.shareUid,
    this.crossPostSharerId,
    this.crossPostPlatform,
  });

  @override
  State<StreamViewerScreen> createState() => _StreamViewerScreenState();
}

class _StreamViewerScreenState extends State<StreamViewerScreen>
    with WidgetsBindingObserver {
  final LiveStreamService _streamService = LiveStreamService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _commentsScrollController = ScrollController();

  List<StreamComment> _comments = [];
  List<VirtualGift> _gifts = [];
  int _viewersCount = 0;
  bool _isLiked = false;
  bool _showGifts = false;
  bool _overlayVisible = true;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  String? _videoError;

  /// When true, user has no session or session ended; show "Please log in again" and go to login.
  bool _sessionInvalid = false;
  JoinStreamResult? _joinResult;
  String? _streamUnavailableReason; // 'not_found' | 'scheduled' | 'ended'
  StreamSubscription<String>? _connectionErrorSubscription;

  final WebSocketService _webSocketService = WebSocketService();
  late final BattleModeService _battleModeService;
  StreamSubscription<Map<String, dynamic>>? _viewerCountSubscription;
  StreamSubscription<StreamComment>? _commentSubscription;
  StreamSubscription<GiftEvent>? _giftSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<BattleState>? _battleStateSubscription;
  StreamSubscription<BattleInvite>? _battleInviteSubscription;
  StreamSubscription<Map<String, dynamic>>? _streamStatusSubscription;
  BattleState? _battleState;

  /// Pre-stream ad shown before joining.
  ServedAd? _streamAd;
  /// Whether the pre-stream ad overlay is currently showing.
  bool _showPreStreamAd = false;

  // ─── Phase A — viewer earnings plumbing ─────────────────────────────
  /// Timestamp of viewer join — drives rapid_leave / session_exit signals.
  DateTime? _joinedAt;
  /// 1-minute heartbeat firing live_watch_minute·author.
  Timer? _heartbeatTimer;
  /// iOS/Android screenshot listener — fires screenshot_during_live.
  ScreenCaptureEvent? _screenCaptureEvent;
  /// Whether app entered background within 60s — fires session_exit_after_join.
  bool _sessionExitFired = false;
  final FriendService _friendService = FriendService();

  // ─── Phase F — cohost invite detection (invitee-side) ──────────────
  /// True when this viewer has a pending co-host invite for this stream.
  bool _hasPendingCohostInvite = false;

  // ─── Phase G — follow CTA on top bar ───────────────────────────────
  /// Tracks whether the current viewer follows the streamer.
  /// Updated optimistically when the viewer taps Follow.
  bool _isFollowing = false;
  bool _followBusy = false;
  /// Lazy import for ProfileService — used by tap-on-avatar to record
  /// `profile_visit_from_live·author`.
  final ProfileService _profileService = ProfileService();
  /// Phase G — per-viewer "notify me on go-live" subscription state.
  bool _notifyOnLive = false;
  /// Phase G — broadcaster's pinned outbound link (refreshed on join).
  String? _pinnedLinkUrl;
  String? _pinnedLinkLabel;

  @override
  void initState() {
    super.initState();
    _battleModeService = BattleModeService(_webSocketService);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WakelockPlus.enable();

    // A.7 — Screenshot listener. Fires screenshot_during_live·author.
    _screenCaptureEvent = ScreenCaptureEvent();
    _screenCaptureEvent!.addScreenShotListener((path) {
      _streamService.screenshotFeedback(widget.stream.id, widget.currentUserId);
    });
    _screenCaptureEvent!.watch();

    _checkSessionAndStart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // A.10 — session_exit_after_join. Fire once if app backgrounds within
    // 60s of join (signals viewer abandoned the stream very quickly).
    if (state == AppLifecycleState.paused
        && !_sessionExitFired
        && _joinedAt != null
        && DateTime.now().difference(_joinedAt!).inSeconds < 60) {
      _sessionExitFired = true;
      _streamService.negativeFeedback(
        widget.stream.id, widget.currentUserId, 'session_exit_after_join',
        metadata: {'dwell_ms': DateTime.now().difference(_joinedAt!).inMilliseconds},
      );
    }
  }

  /// If user has ended session or there is no session (e.g. forgot to end), show proper response and do not connect.
  Future<void> _checkSessionAndStart() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    final hasValidSession = storage.hasUser() &&
        storage.isLoggedIn() &&
        user != null &&
        user.userId != null &&
        user.userId == widget.currentUserId;

    if (!hasValidSession) {
      if (mounted) {
        setState(() => _sessionInvalid = true);
      }
      return;
    }

    // Fetch a pre-stream ad before joining
    final token = storage.getAuthToken();
    try {
      final ads = await AdService.getServedAds(token, 'live_stream', 1);
      if (ads.isNotEmpty && mounted) {
        setState(() {
          _streamAd = ads.first;
          _showPreStreamAd = true;
        });
        // Record impression
        AdService.recordAdEvent(
          token, _streamAd!.campaignId, _streamAd!.creativeId,
          widget.currentUserId, 'live_stream', 'impression',
        );
        // Wait for ad completion or skip (handled in build via callbacks)
        return;
      }
    } catch (e) {
      debugPrint('[StreamViewer] Pre-stream ad error: $e');
    }

    await _proceedToJoinStream();
  }

  /// Actually join the stream (called after pre-stream ad completes or directly).
  Future<void> _proceedToJoinStream() async {
    // A.6 — pass shareUid through so backend fires view_from_share·sharer.
    final joinResult = await _streamService.joinStream(
      widget.stream.id, widget.currentUserId,
      shareUid: widget.shareUid,
    );
    if (!mounted) return;

    setState(() {
      _joinResult = joinResult;
      if (joinResult.isNotFound) {
        _streamUnavailableReason = 'not_found';
      } else if (joinResult.isScheduled) {
        _streamUnavailableReason = 'scheduled';
      } else if (joinResult.isGone) {
        _streamUnavailableReason = 'ended';
      } else {
        _streamUnavailableReason = null;
      }
    });

    if (_streamUnavailableReason != null) {
      return;
    }

    // A.5 — record join time + start 1-minute heartbeat that fires
    // live_watch_minute·author. Skips when video controller is not playing
    // (idle stream avoids ghost-credits).
    _joinedAt = DateTime.now();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final c = _videoPlayerController;
      if (c != null && c.value.isPlaying) {
        _streamService.heartbeat(widget.stream.id, widget.currentUserId);
      }
    });

    // Phase F — cross_post_view·sharer (Lever 4). One-shot fire on join
    // when viewer arrived from an external platform deep-link.
    if (widget.crossPostSharerId != null && widget.crossPostPlatform != null) {
      _streamService.crossPostView(
        streamId: widget.stream.id,
        sharerUserId: widget.crossPostSharerId!,
        externalPlatform: widget.crossPostPlatform!,
        viewerUserId: widget.currentUserId,
      );
    }

    final playbackUrl = joinResult.playbackUrl;
    final websocket = joinResult.websocket;
    if (joinResult.currentViewers != null) {
      _viewersCount = joinResult.currentViewers!;
    }

    _initializeVideoPlayer(playbackUrl);
    _loadData();
    _checkPendingCohostInvite();
    _refreshNotifyLiveState();
    if (websocket != null && websocket.url.isNotEmpty && websocket.channel.isNotEmpty) {
      _connectWebSocket(websocket.url, websocket.channel);
    }
  }

  /// Phase F+G — fetch fresh stream and surface:
  ///  - Co-host accept banner (when status='invited' for this viewer)
  ///  - Pinned outbound link overlay (when broadcaster has pinned one)
  Future<void> _checkPendingCohostInvite() async {
    final result = await _streamService.getStream(
      widget.stream.id, currentUserId: widget.currentUserId);
    if (!mounted) return;
    final stream = result.stream;
    final cohosts = stream?.cohosts ?? const [];
    final pending = cohosts.any((c) =>
        c.userId == widget.currentUserId && c.status == 'invited');
    setState(() {
      if (pending) _hasPendingCohostInvite = true;
      _pinnedLinkUrl = stream?.pinnedLinkUrl;
      _pinnedLinkLabel = stream?.pinnedLinkLabel;
    });
  }

  /// B5 — viewer taps the pinned link overlay. Fires
  /// external_link_click·author and opens the URL externally.
  Future<void> _onPinnedLinkTap() async {
    final url = _pinnedLinkUrl;
    if (url == null || url.isEmpty) return;
    _streamService.externalLinkClick(
      widget.stream.id, widget.currentUserId, url);
    final uri = Uri.tryParse(url);
    if (uri != null) {
      // Use share_plus to surface the URL — gives the user the
      // platform's native "Open in..." picker without an extra dep.
      await SharePlus.instance.share(ShareParams(uri: uri, text: url));
    }
  }

  // ─── Phase G — follow / profile-visit with stream attribution ────
  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    setState(() => _followBusy = true);
    final wasFollowing = _isFollowing;
    final ok = wasFollowing
        ? await _friendService.unfollowUser(
            widget.currentUserId, widget.stream.userId)
        : await _friendService.followUser(
            widget.currentUserId, widget.stream.userId,
            originStreamId: widget.stream.id,
            shareUid: widget.shareUid,
          );
    if (!mounted) return;
    setState(() {
      _followBusy = false;
      if (ok) _isFollowing = !wasFollowing;
    });
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isSw ? 'Imeshindikana' : 'Failed'),
      ));
    }
  }

  Future<void> _refreshNotifyLiveState() async {
    if (widget.currentUserId == widget.stream.userId) return;
    final on = await _streamService.notifyLiveStatus(
      streamerUserId: widget.stream.userId, userId: widget.currentUserId);
    if (mounted) setState(() => _notifyOnLive = on);
  }

  Future<void> _toggleNotifyOnLive() async {
    final newVal = !_notifyOnLive;
    setState(() => _notifyOnLive = newVal);
    final ok = await _streamService.notifyLiveToggle(
      streamerUserId: widget.stream.userId,
      userId: widget.currentUserId,
      enabled: newVal,
    );
    if (!ok && mounted) {
      // revert on failure
      setState(() => _notifyOnLive = !newVal);
    }
  }

  void _openStreamerProfile() {
    // Fire profile_visit_from_live·author + profile_visit_from_stream_share
    // (when share_uid is in flight). This records the visit; the calling
    // route below opens the actual profile screen.
    _profileService.recordProfileVisit(
      targetUserId: widget.stream.userId,
      viewerUserId: widget.currentUserId,
      originStreamId: widget.stream.id,
      shareUid: widget.shareUid,
    );
    Navigator.of(context).pushNamed('/profile/${widget.stream.userId}');
  }

  Future<void> _respondToCohostInvite(bool accept) async {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    final ok = await _streamService.cohostRespond(
      streamId: widget.stream.id,
      userId: widget.currentUserId,
      accept: accept,
    );
    if (!mounted) return;
    setState(() => _hasPendingCohostInvite = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (accept
              ? (isSw ? 'Umejiunga kama mwenyeji-wa-pamoja' : 'Joined as co-host')
              : (isSw ? 'Umekataa' : 'Declined'))
          : (isSw ? 'Imeshindikana' : 'Failed')),
    ));
  }

  Future<void> _connectWebSocket(String wsUrl, String channel) async {
    await _webSocketService.connectToPusher(wsUrl, channel);

    _battleModeService.initialize();
    _battleStateSubscription = _battleModeService.battleStateStream.listen((state) {
      if (mounted) {
        setState(() => _battleState = state);
        if (state.status == BattleStatus.ended) {
          _showBattleResultDialog(state);
        }
      }
    });
    _battleInviteSubscription = _battleModeService.battleInviteStream.listen((invite) {
      if (mounted) _showBattleInviteDialog(invite);
    });

    _viewerCountSubscription = _webSocketService.viewerCountStream.listen((update) {
      if (mounted) {
        setState(() {
          _viewersCount = update['current_viewers'] as int? ?? _viewersCount;
        });
      }
    });

    _commentSubscription = _webSocketService.commentStream.listen((comment) {
      if (mounted) {
        setState(() {
          _comments.add(comment);
        });
        _scrollToBottom();
      }
    });

    _giftSubscription = _webSocketService.giftStream.listen((giftEvent) {
      if (mounted) {
        _showGiftAnimation(giftEvent);
      }
    });

    _connectionSubscription = _webSocketService.connectionStream.listen((isConnected) {
      if (!isConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Muunganisho umepotea. Inajaribu kuunganisha tena...'),
            duration: Duration(seconds: 2),
          ),
        );
        // Reconnection is handled by WebSocketService._scheduleReconnect; do not call connectToStream again here to avoid duplicate connections.
      }
    });

    _connectionErrorSubscription = _webSocketService.connectionErrorStream.listen((errorKey) {
      if (!mounted) return;
      _showConnectionErrorResponse(errorKey);
    });

    _streamStatusSubscription = _webSocketService.streamStatusStream.listen(_onStreamStatusChanged);
  }

  /// On status_changed from WebSocket: start player when live+playback_url, or show ended.
  void _onStreamStatusChanged(Map<String, dynamic> data) {
    final streamId = data['stream_id'];
    if (streamId != null && streamId != widget.stream.id) return;

    final status = data['status'] as String?;
    final playbackUrl = data['playback_url'] as String?;

    if (status == 'live' && playbackUrl != null && playbackUrl.isNotEmpty) {
      _startPlaybackFromStatus(playbackUrl);
    } else if (status == 'ended' || status == 'ending') {
      if (mounted) {
        setState(() {
          _streamUnavailableReason = 'ended';
        });
      }
    }
  }

  /// Start player with URL from status_changed (no extra API call).
  Future<void> _startPlaybackFromStatus(String playbackUrl) async {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
    if (mounted) {
      setState(() {
        _isVideoInitialized = false;
        _videoError = null;
      });
    }
    await _initializeVideoPlayer(playbackUrl);
  }

  /// Show a proper response when connection fails (e.g. not upgraded, max retries). Hint: session may have ended.
  void _showConnectionErrorResponse(String errorKey) {
    const sessionHint = 'Ikiwa muda wako umekwisha au umeondoka, tafadhali ingia tena.';
    const sessionHintEn = 'If your session has ended or you logged out elsewhere, please log in again.';
    String message;
    if (errorKey == 'session_invalid') {
      message = 'Muda wako umekwisha. $sessionHint';
    } else if (errorKey == 'max_reconnect_reached') {
      message = 'Hatuwezi kuunganisha. $sessionHint';
    } else {
      message = 'Muunganisho umeshindwa. $sessionHint';
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tatizo la Muunganisho'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Funga'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLogin();
            },
            child: const Text('Ingia tena'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() async {
    await _webSocketService.disconnect();
    if (!mounted) return;
    Navigator.of(context).pop(); // leave stream viewer
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showGiftAnimation(GiftEvent giftEvent) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: 20,
        right: 20,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value < 0.8 ? value : (1.0 - value) * 5,
              child: Transform.scale(
                scale: 0.5 + (value * 0.5),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.9),
                        Colors.pink.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (giftEvent.sender != null) ...[
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: giftEvent.sender!.avatarUrl.isNotEmpty
                              ? NetworkImage(giftEvent.sender!.avatarUrl)
                              : null,
                          child: giftEvent.sender!.avatarUrl.isEmpty
                              ? Text(giftEvent.sender!.firstName[0])
                              : null,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (giftEvent.sender != null)
                              Text(
                                giftEvent.sender!.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${giftEvent.gift.name} ${giftEvent.quantity > 1 ? 'x${giftEvent.quantity}' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 2000), () {
      overlayEntry.remove();
    });
  }

  /// Build stream URL: prefer join result playback_url, then stream.playbackUrl, else legacy HLS path.
  /// When join explicitly returned null playback_url (pre_live), return empty so we show "Waiting for streamer...".
  String _getStreamUrl(String? playbackUrl) {
    if (playbackUrl != null && playbackUrl.isNotEmpty) return playbackUrl;
    if (widget.stream.playbackUrl != null && widget.stream.playbackUrl!.isNotEmpty) {
      return widget.stream.playbackUrl!;
    }
    if (_joinResult != null && _joinResult!.playbackUrl == null) {
      return '';
    }
    return '${ApiConfig.baseUrl.replaceAll('/api', '')}/hls/${widget.stream.id}.m3u8';
  }

  Future<void> _initializeVideoPlayer(String? playbackUrlFromJoin) async {
    final streamUrl = _getStreamUrl(playbackUrlFromJoin);
    if (streamUrl.isEmpty) {
      if (mounted) setState(() => _videoError = 'Waiting for streamer...');
      return;
    }
    try {

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: false,
        allowFullScreen: false,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        showOptions: false,
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.grey[900],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Tatizo la Mtiririko',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _videoPlayerController?.dispose();
                      _chewieController?.dispose();
                      _initializeVideoPlayer(_joinResult?.playbackUrl);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Jaribu Tena'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }

      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError) {
          setState(() {
            _videoError = _videoPlayerController!.value.errorDescription;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = e.toString();
        });
      }
    }
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _streamService.getComments(widget.stream.id),
      _streamService.getAvailableGifts(),
    ]);

    if (!mounted) return;
    setState(() {
      _comments = (results[0] as CommentsResult).comments;
      _gifts = (results[1] as GiftsResult).gifts;
      _viewersCount = widget.stream.viewersCount;
      _isLiked = widget.stream.isLiked == true;
    });
  }

  Future<void> _sendComment() async {
    if (_commentController.text.isEmpty) return;

    final result = await _streamService.addComment(
      widget.stream.id,
      widget.currentUserId,
      _commentController.text,
    );

    if (result.success && result.comment != null) {
      setState(() {
        _comments.add(result.comment!);
      });
      _commentController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_commentsScrollController.hasClients) {
        _commentsScrollController.animateTo(
          _commentsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// A.2 — open the 6-emoji reaction picker. Each reaction fires
  /// `live_reaction·author` (rate 1.50 TZS/event) via `/streams/{id}/reaction`.
  /// 👎 fires `negative_reaction_during_live` instead of a positive reaction.
  void _openReactionPicker() {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                isSw ? 'Onyesha hisia zako' : 'React',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12, runSpacing: 8, alignment: WrapAlignment.center,
                children: [
                  _reactionTile(ctx, 'heart', '❤️'),
                  _reactionTile(ctx, 'fire', '🔥'),
                  _reactionTile(ctx, 'love', '😍'),
                  _reactionTile(ctx, 'wow', '😮'),
                  _reactionTile(ctx, 'clap', '👏'),
                  _reactionTile(ctx, 'laugh', '😂'),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),
              // A.9 — 👎 negative_reaction_during_live (low severity).
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _streamService.negativeFeedback(
                    widget.stream.id, widget.currentUserId,
                    'negative_reaction_during_live',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isSw
                            ? 'Asante kwa maoni'
                            : 'Thanks for the feedback'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👎', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        isSw ? 'Si vyema' : 'Dislike',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// G19 — chat_reaction·chat_author. 6-emoji picker on a chat message.
  void _openChatReactionPicker(StreamComment comment) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Wrap(
            spacing: 12, alignment: WrapAlignment.center,
            children: [
              for (final pair in const [
                ['heart', '❤️'], ['fire', '🔥'], ['clap', '👏'],
                ['wow', '😮'], ['laugh', '😂'], ['sad', '😢'],
              ])
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _streamService.reactToComment(
                      streamId: widget.stream.id,
                      commentId: comment.id,
                      userId: widget.currentUserId,
                      reactionType: pair[0],
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(pair[1], style: const TextStyle(fontSize: 28)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reactionTile(BuildContext sheetCtx, String type, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(sheetCtx);
        _streamService.sendReaction(widget.stream.id, widget.currentUserId, type);
        setState(() => _isLiked = type == 'heart');
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Future<void> _sendGift(VirtualGift gift) async {
    // L1 — generate a stable per-tap idempotency key so network retries
    // short-circuit on the server instead of double-charging the wallet.
    final transactionId = const Uuid().v4();
    final success = await _streamService.sendGift(
      widget.stream.id,
      widget.currentUserId,
      gift.id,
      transactionId: transactionId,
    );

    if (success) {
      setState(() => _showGifts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Umetuma ${gift.name}!')),
        );
      }
    }
  }

  /// A.3 — tip in stream context. Forwards stream_id so backend fires
  /// `live_tip·author` (95% net) instead of generic `tip·author`.
  void _openSendTip() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SendTipScreen(
          creatorId: widget.stream.userId,
          currentUserId: widget.currentUserId,
          creatorDisplayName: widget.stream.user?.displayName,
          streamId: widget.stream.id,
        ),
      ),
    );
  }

  /// A.4 — wire the share button. Calls /streams/{id}/share to obtain a
  /// share_uid, then opens the native share sheet with the attribution URL.
  /// Backend fires `stream_share·sharer`; downstream views/follows via that
  /// URL fire `view_from_share·sharer` and `follow_from_stream_share·sharer`.
  Future<void> _shareStream() async {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;

    // B4 — surface intent picker first. Critique-shares fire
    // negative_share_during_stream so the integrity pipeline can
    // separate genuine recommendations from "look at this trainwreck".
    final intent = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.thumb_up_alt_rounded, color: Colors.greenAccent),
              title: Text(isSw ? 'Pendekeza' : 'Recommend',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                isSw ? 'Unapenda — wawasilishe kwa marafiki' : 'You like it — share with friends',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () => Navigator.pop(ctx, 'recommend'),
            ),
            ListTile(
              leading: const Icon(Icons.thumb_down_alt_rounded, color: Colors.orange),
              title: Text(isSw ? 'Kosoa' : 'Critique',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                isSw
                    ? 'Hupendi — usambaze kama tahadhari'
                    : "You don't like it — share as a warning",
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () => Navigator.pop(ctx, 'critique'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (intent == null) return;

    final result = await _streamService.shareStream(
      widget.stream.id, widget.currentUserId);
    if (!mounted) return;
    if (!result.success || result.shareUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSw ? 'Imeshindikana kushiriki' : 'Failed to share')),
      );
      return;
    }
    if (intent == 'critique') {
      _streamService.negativeFeedback(
        widget.stream.id, widget.currentUserId,
        'negative_share_during_stream',
        metadata: {'share_uid': result.shareUid},
      );
    }
    final title = widget.stream.title ?? (widget.stream.user?.displayName ?? 'TAJIRI live');
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        text: '$title\n${result.shareUrl}',
        uri: Uri.tryParse(result.shareUrl!),
      ),
    );
  }

  /// A.5 (companion) — open super-chat composer. Tier picker → /super-chats.
  void _openSuperChat() {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    final controller = TextEditingController();
    int amount = 1000;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16,
              16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSw ? 'Tuma Super Chat' : 'Send Super Chat',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [500, 1000, 2500, 5000, 10000].map((v) =>
                  ChoiceChip(
                    label: Text('TSh $v'),
                    selected: amount == v,
                    onSelected: (_) => setSheetState(() => amount = v),
                  )
                ).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 200,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isSw ? 'Andika ujumbe (hiari)' : 'Optional message',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await _streamService.sendSuperChat(
                      widget.stream.id, widget.currentUserId, amount,
                      message: controller.text.trim().isEmpty ? null : controller.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok
                            ? (isSw ? 'Super Chat imetumwa' : 'Super Chat sent')
                            : (isSw ? 'Imeshindikana' : 'Failed'))),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isSw ? 'Tuma TSh $amount' : 'Send TSh $amount'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A.8 — overflow menu (3-dot). Surfaces 4 negative-attribution signals:
  /// report_stream · not_interested · mute_streamer · chat_disable_for_creator.
  void _openOverflowMenu() {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // G9/G10 — Subscribe with stream attribution. Routes to
            // SubscribeToCreatorScreen with originStreamId so backend
            // fires subscribe_from_live·author (or resub_during_live).
            if (widget.currentUserId != widget.stream.userId)
              ListTile(
                leading: const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
                title: Text(
                  isSw ? 'Jisajili kwa muundaji' : 'Subscribe to creator',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubscribeToCreatorScreen(
                        creatorId: widget.stream.userId,
                        currentUserId: widget.currentUserId,
                        creatorDisplayName: widget.stream.user?.displayName,
                        originStreamId: widget.stream.id,
                        shareUid: widget.shareUid,
                      ),
                    ),
                  );
                },
              ),
            // Phase F — community contribute (captions / translations / dubs).
            // Routes to a single bottom sheet that picks the contribution
            // type and submits to the §V endpoints.
            ListTile(
              leading: const Icon(Icons.translate_rounded, color: Colors.white),
              title: Text(
                isSw ? 'Changia: manukuu / tafsiri / dub'
                     : 'Contribute: captions / translation / dub',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openContributeSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_rounded, color: Colors.white),
              title: Text(
                isSw ? 'Sipendi mitiririko kama hii' : 'Hide streams like this',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _streamService.negativeFeedback(
                  widget.stream.id, widget.currentUserId,
                  'not_interested_in_streams_like_this',
                );
                _showNegFeedbackToast(isSw);
                Navigator.of(context).pop(); // leave viewer
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_rounded, color: Colors.white),
              title: Text(
                isSw ? 'Nyamazisha mtumiaji' : 'Mute streamer',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                _streamService.negativeFeedback(
                  widget.stream.id, widget.currentUserId, 'mute_streamer',
                );
                await _friendService.muteUser(
                  userId: widget.currentUserId,
                  mutedUserId: widget.stream.userId,
                );
                _showNegFeedbackToast(isSw);
                if (mounted) Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
              title: Text(
                isSw ? 'Zima gumzo la mtumiaji huyu' : "Disable chat for this streamer",
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _streamService.negativeFeedback(
                  widget.stream.id, widget.currentUserId, 'chat_disable_for_creator',
                );
                _showNegFeedbackToast(isSw);
              },
            ),
            // §A — block_streamer. Blocks the user via FriendService AND
            // tags this stream context so the integrity pipeline sees it.
            ListTile(
              leading: Icon(Icons.block_rounded, color: Colors.red.shade400),
              title: Text(
                isSw ? 'Zuia mtumiaji' : 'Block streamer',
                style: TextStyle(color: Colors.red.shade400),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: Text(isSw ? 'Zuia mtumiaji?' : 'Block streamer?'),
                    content: Text(isSw
                        ? 'Hutaona machapisho au mitiririko yao tena.'
                        : "You won't see their posts or streams again."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: Text(isSw ? 'Ghairi' : 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        child: Text(isSw ? 'Zuia' : 'Block',
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                _streamService.negativeFeedback(
                  widget.stream.id, widget.currentUserId, 'block_streamer',
                );
                await _friendService.blockUser(
                    widget.currentUserId, widget.stream.userId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isSw ? 'Mtumiaji amezuiwa' : 'Streamer blocked'),
                ));
                Navigator.of(context).pop(); // leave viewer
              },
            ),
            ListTile(
              leading: Icon(Icons.flag_rounded, color: Colors.red.shade400),
              title: Text(
                isSw ? 'Ripoti mtiririko' : 'Report stream',
                style: TextStyle(color: Colors.red.shade400),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final reason = await showDialog<String>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: Text(isSw ? 'Sababu ya kuripoti' : 'Report reason'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final r in const [
                          'inappropriate', 'harassment', 'misinformation',
                          'adult_content', 'spam_scam', 'other',
                        ])
                          ListTile(
                            title: Text(r),
                            onTap: () => Navigator.pop(dctx, r),
                          ),
                      ],
                    ),
                  ),
                );
                if (reason == null) return;
                _streamService.negativeFeedback(
                  widget.stream.id, widget.currentUserId, 'report_stream',
                  metadata: {'reason': reason},
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isSw ? 'Ripoti imetumwa' : 'Report submitted')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Phase F — community contribution sheet (§V localization) ───
  // Single bottom-sheet that branches into 3 contribution flows:
  //   • Live caption (captioner_user_id earns live_caption_create)
  //   • VOD subtitle (translator earns subtitle_localization)
  //   • Audio dub (voice_actor earns dub_overlay)
  void _openContributeSheet() {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                isSw ? 'Changia mtiririko huu' : 'Contribute to this stream',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.subtitles_rounded, color: Colors.white),
              title: Text(isSw ? 'Andika manukuu (live)' : 'Live captions',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                isSw ? 'Kuwa nukuzi — pata mapato kwa kila nukuu'
                     : 'Become a captioner — earn per caption',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () { Navigator.pop(ctx); _submitCaption(); },
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded, color: Colors.white),
              title: Text(isSw ? 'Tafsiri (subtitles)' : 'Translation (subtitles)',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                isSw ? 'Toa subtitle kwa lugha nyingine'
                     : 'Submit subtitles in another language',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () { Navigator.pop(ctx); _submitTranslation(); },
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over_rounded, color: Colors.white),
              title: Text(isSw ? 'Dub ya sauti' : 'Voice dub',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                isSw ? 'Tuma URL ya sauti iliyodubiwa'
                     : 'Submit a dubbed audio URL',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              onTap: () { Navigator.pop(ctx); _submitDub(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCaption() async {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    final urlCtl = TextEditingController();
    final langCtl = TextEditingController(text: 'sw');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Tuma manukuu' : 'Submit captions'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: langCtl,
            decoration: InputDecoration(
              labelText: isSw ? 'Lugha (mfano: sw, en)' : 'Language (e.g. sw, en)')),
          TextField(controller: urlCtl,
            decoration: InputDecoration(
              labelText: isSw ? 'URL ya manukuu (vtt/srt)' : 'Caption URL (vtt/srt)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(isSw ? 'Ghairi' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(isSw ? 'Tuma' : 'Submit')),
        ],
      ),
    );
    if (ok != true) return;
    final lang = langCtl.text.trim();
    final url = urlCtl.text.trim();
    if (lang.length != 2) {
      _toastError(isSw ? 'Lugha lazima iwe herufi 2' : 'Language must be 2 chars');
      return;
    }
    final id = await _streamService.createCaption(
      streamId: widget.stream.id,
      captionerUserId: widget.currentUserId,
      languageCode: lang,
      captionUrl: url.isEmpty ? null : url,
      isLive: true,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(id != null
            ? (isSw ? 'Asante — manukuu yamesajiliwa' : 'Captions recorded')
            : (isSw ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  Future<void> _submitTranslation() async {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    final srcCtl = TextEditingController(text: 'sw');
    final tgtCtl = TextEditingController(text: 'en');
    final urlCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Tuma tafsiri' : 'Submit translation'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: srcCtl,
            decoration: InputDecoration(
              labelText: isSw ? 'Lugha asili' : 'Source language')),
          TextField(controller: tgtCtl,
            decoration: InputDecoration(
              labelText: isSw ? 'Lugha lengwa' : 'Target language')),
          TextField(controller: urlCtl,
            decoration: InputDecoration(
              labelText: isSw ? 'URL ya subtitle' : 'Subtitle URL')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(isSw ? 'Ghairi' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(isSw ? 'Tuma' : 'Submit')),
        ],
      ),
    );
    if (ok != true) return;
    final src = srcCtl.text.trim();
    final tgt = tgtCtl.text.trim();
    if (src.length != 2 || tgt.length != 2) {
      _toastError(isSw ? 'Lugha lazima ziwe herufi 2' : 'Languages must be 2 chars');
      return;
    }
    final id = await _streamService.createTranslation(
      streamId: widget.stream.id,
      translatorUserId: widget.currentUserId,
      sourceLanguageCode: src,
      targetLanguageCode: tgt,
      subtitleUrl: urlCtl.text.trim().isEmpty ? null : urlCtl.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(id != null
            ? (isSw ? 'Asante — tafsiri imehifadhiwa' : 'Translation saved')
            : (isSw ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  Future<void> _submitDub() async {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    final langCtl = TextEditingController(text: 'sw');
    final urlCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Tuma dub' : 'Submit dub'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: langCtl,
            decoration: InputDecoration(
              labelText: isSw ? 'Lugha' : 'Language')),
          TextField(controller: urlCtl,
            decoration: InputDecoration(
              labelText: isSw ? 'URL ya sauti' : 'Audio URL')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(isSw ? 'Ghairi' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(isSw ? 'Tuma' : 'Submit')),
        ],
      ),
    );
    if (ok != true) return;
    final lang = langCtl.text.trim();
    if (lang.length != 2) {
      _toastError(isSw ? 'Lugha lazima iwe herufi 2' : 'Language must be 2 chars');
      return;
    }
    final id = await _streamService.createDub(
      streamId: widget.stream.id,
      voiceActorUserId: widget.currentUserId,
      languageCode: lang,
      audioUrl: urlCtl.text.trim().isEmpty ? null : urlCtl.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(id != null
            ? (isSw ? 'Asante — dub imehifadhiwa' : 'Dub saved')
            : (isSw ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  void _toastError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── B1 — Q&A panel (viewer-side) ──────────────────────────────
  // Bottom sheet shows current questions sorted by upvotes; viewer can
  // submit a new question (submit_question·question_author) or upvote
  // existing ones (q_and_a_upvote·question_author — the asker earns).
  Future<void> _openQuestionsPanel() async {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    final upvoted = <int>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scroll) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    const Icon(Icons.live_help_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      isSw ? 'Maswali' : 'Q&A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(isSw ? 'Uliza' : 'Ask',
                          style: const TextStyle(color: Colors.white)),
                      onPressed: () => _submitQuestion(setLocal),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<StreamQuestion>>(
                    future: _streamService.getQuestions(widget.stream.id),
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white));
                      }
                      final qs = snap.data ?? const [];
                      if (qs.isEmpty) {
                        return Center(
                          child: Text(
                            isSw
                                ? 'Hakuna swali bado. Kuwa wa kwanza.'
                                : 'No questions yet. Be the first.',
                            style: const TextStyle(color: Colors.white60),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: qs.length,
                        itemBuilder: (ctx, i) {
                          final q = qs[i];
                          final hasUpvoted = upvoted.contains(q.id);
                          return Card(
                            color: Colors.white10,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(q.question,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(q.username,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      hasUpvoted
                                          ? Icons.thumb_up_alt_rounded
                                          : Icons.thumb_up_alt_outlined,
                                      color: hasUpvoted
                                          ? Colors.orange
                                          : Colors.white70,
                                    ),
                                    onPressed: hasUpvoted
                                        ? null
                                        : () async {
                                            setLocal(() => upvoted.add(q.id));
                                            await _streamService.upvoteQuestion(
                                              widget.stream.id,
                                              widget.currentUserId,
                                              q.id,
                                            );
                                          },
                                  ),
                                  Text('${q.upvotes + (hasUpvoted ? 1 : 0)}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _submitQuestion(void Function(void Function()) setLocal) async {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Uliza swali' : 'Ask a question'),
        content: TextField(
          controller: ctl,
          maxLength: 200,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isSw ? 'Swali lako...' : 'Your question...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(isSw ? 'Ghairi' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(isSw ? 'Tuma' : 'Submit')),
        ],
      ),
    );
    if (ok != true) return;
    final text = ctl.text.trim();
    if (text.isEmpty) return;
    final result = await _streamService.submitQuestion(
      widget.stream.id, widget.currentUserId, text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? (isSw ? 'Swali limetumwa' : 'Question submitted')
            : (isSw ? 'Imeshindikana' : 'Failed')),
      ));
      // Force the bottom sheet to refresh its FutureBuilder.
      setLocal(() {});
    }
  }

  void _showNegFeedbackToast(bool isSw) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSw ? 'Asante kwa maoni' : 'Thanks for the feedback'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBattleInviteDialog(BattleInvite invite) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BattleInviteDialog(
        invite: invite,
        onAccept: () {
          _battleModeService.acceptBattle(invite.battleId);
        },
        onDecline: () {
          _battleModeService.declineBattle(invite.battleId);
        },
      ),
    );
  }

  void _showBattleResultDialog(BattleState state) {
    final myName = widget.stream.user?.displayName ?? 'Mtumiaji';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BattleResultDialog(
        battleState: state,
        myName: myName,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  Widget _buildStreamUnavailableBody() {
    final reason = _streamUnavailableReason!;
    final j = _joinResult;
    String title;
    String subtitle;
    if (reason == 'not_found') {
      title = 'Mtiririko haupatikani';
      subtitle = j?.message ?? 'Mtiririko umefutwa au haujapatikana.';
    } else if (reason == 'scheduled') {
      title = 'Mtiririko haujaanza';
      subtitle = j?.scheduledAt != null
          ? 'Utakuja: ${j!.scheduledAt!.toLocal()}'
          : (j?.message ?? 'Tangazo limepangwa.');
    } else {
      title = 'Mtiririko umekwisha';
      subtitle = j?.message ?? 'Tangazo limeisha.';
      if (j?.duration != null) subtitle += ' Muda: ${j!.duration! ~/ 60} dakika.';
      if (j?.totalViewers != null) subtitle += ' Watazamaji: ${j!.totalViewers}.';
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                reason == 'not_found' ? Icons.search_off : (reason == 'scheduled' ? Icons.schedule : Icons.stop_circle_outlined),
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leaveStream() async {
    await _streamService.leaveStream(widget.stream.id, widget.currentUserId);
    WakelockPlus.disable();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Exit confirmation per story: show dialog before leaving.
  Future<bool> _onExitRequested() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAFA),
        title: const Text('Toka Mtiririko'),
        content: const Text(
          'Unahitaji kutoka matangazo ya moja kwa moja?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ndio, toka'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _leaveStream();
      return true;
    }
    return false;
  }

  void _onPreStreamAdComplete() {
    if (mounted) {
      setState(() => _showPreStreamAd = false);
      _proceedToJoinStream();
    }
  }

  void _onPreStreamAdSkip() {
    if (mounted) {
      setState(() => _showPreStreamAd = false);
      _proceedToJoinStream();
    }
  }

  void _recordStreamAdClick() async {
    if (_streamAd == null) return;
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    AdService.recordAdEvent(
      token, _streamAd!.campaignId, _streamAd!.creativeId,
      widget.currentUserId, 'live_stream', 'click',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show full-screen pre-stream ad overlay
    if (_showPreStreamAd && _streamAd != null) {
      return StoryAdOverlay(
        servedAd: _streamAd,
        onComplete: _onPreStreamAdComplete,
        onSkip: _onPreStreamAdSkip,
        onClick: _recordStreamAdClick,
      );
    }
    if (_sessionInvalid) {
      return _buildSessionEndedBody();
    }
    if (_streamUnavailableReason != null) {
      return _buildStreamUnavailableBody();
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onExitRequested();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoLayer(),
            if (_overlayVisible) ...[
              _buildGradientOverlays(),
              _buildTopBar(),
              if (_battleState != null) _buildPKBattleOverlay(),
              _buildCommentsOverlay(),
              _buildRightActions(),
              _buildCommentInput(),
              if (_showGifts) _buildGiftsPanel(),
            ],
            // Sponsor badge — always visible (non-intrusive)
            if (_streamAd != null)
              Positioned(
                bottom: 16,
                left: 16,
                child: StreamSponsorBadge(
                  servedAd: _streamAd!,
                  onTap: _recordStreamAdClick,
                ),
              ),
            // Phase F — co-host invite banner (invitee-side accept UI)
            if (_hasPendingCohostInvite) _buildCohostInviteBanner(),
            // B5 — pinned outbound link overlay (viewer tap fires
            // external_link_click·author).
            if (_pinnedLinkUrl != null && _pinnedLinkUrl!.isNotEmpty)
              _buildPinnedLinkOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedLinkOverlay() {
    return Positioned(
      left: 12,
      bottom: MediaQuery.of(context).padding.bottom + 80,
      child: Material(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _onPinnedLinkTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    _pinnedLinkLabel?.isNotEmpty == true
                        ? _pinnedLinkLabel!
                        : (Uri.tryParse(_pinnedLinkUrl!)?.host ?? 'Open link'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new_rounded,
                    color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCohostInviteBanner() {
    final isSw = AppStringsScope.of(context)?.isSwahili == true;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.deepPurple.shade700,
        borderRadius: BorderRadius.circular(12),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              const Icon(Icons.group_add_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSw
                      ? 'Umekaribishwa kuwa mwenyeji-wa-pamoja'
                      : 'You were invited to co-host',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _respondToCohostInvite(false),
                child: Text(isSw ? 'Kataa' : 'Decline',
                    style: const TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => _respondToCohostInvite(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple.shade700,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(isSw ? 'Kubali' : 'Accept'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tap to focus: tap on video toggles overlay visibility.
  Widget _buildVideoLayer() {
    return GestureDetector(
      onTap: () {
        setState(() => _overlayVisible = !_overlayVisible);
      },
      behavior: HitTestBehavior.opaque,
      child: _isVideoInitialized && _chewieController != null
          ? Chewie(controller: _chewieController!)
          : _videoError != null
              ? _buildErrorState()
              : _buildLoadingState(),
    );
  }

  Widget _buildErrorState() {
    final isWaitingForStreamer = _videoError == 'Waiting for streamer...';
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWaitingForStreamer ? Icons.schedule : Icons.error_outline,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isWaitingForStreamer ? 'Subiri mtangazaji' : 'Tatizo la Mtiririko',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _videoError!,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isWaitingForStreamer) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _videoError = null);
                  _initializeVideoPlayer(_joinResult?.playbackUrl);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Jaribu Tena'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Inapakia mtiririko...',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-screen when session has ended or there is no session (e.g. user forgot to end). Return a proper response.
  Widget _buildSessionEndedBody() {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, color: Colors.white54, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Muda wako umekwisha',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tafadhali ingia tena kwenye akaunti yako ili kuendelea kutazama mtiririko.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Ingia tena'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(0, _kMinTouchTarget),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Rudi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPKBattleOverlay() {
    final myName = widget.stream.user?.displayName ?? 'Mtumiaji';
    final isStreamer = widget.stream.userId == widget.currentUserId;
    return BattleModeOverlayScreen(
      battleState: _battleState!,
      myName: myName,
      currentUserId: widget.currentUserId,
      onForfeit: isStreamer ? _battleModeService.forfeitBattle : null,
    );
  }

  Widget _buildGradientOverlays() {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // G11/G12 — tap streamer info → record profile_visit_from_live
              // (and profile_visit_from_stream_share when share_uid present).
              onTap: widget.currentUserId == widget.stream.userId
                  ? null
                  : _openStreamerProfile,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.stream.user?.avatarUrl.isNotEmpty == true
                        ? NetworkImage(widget.stream.user!.avatarUrl)
                        : null,
                    child: widget.stream.user?.avatarUrl.isEmpty == true
                        ? Text(widget.stream.user!.firstName[0])
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.stream.user?.displayName ?? 'Mtumiaji',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.stream.title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // G22 — per-viewer "notify when this streamer goes live" bell.
          if (widget.currentUserId != widget.stream.userId)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                _notifyOnLive
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: _notifyOnLive ? Colors.amber : Colors.white,
                size: 22,
              ),
              tooltip: _notifyOnLive ? 'Notifications on' : 'Notify me on go-live',
              onPressed: _toggleNotifyOnLive,
            ),
          // G8/G13 — Follow CTA. Hidden when viewing your own stream or
          // already following. Pressing fires follow_from_live·author
          // (origin_stream_id) and follow_from_stream_share·sharer
          // (share_uid). Backend wires both inside FollowController::follow.
          if (widget.currentUserId != widget.stream.userId && !_isFollowing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: _followBusy ? null : _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _followBusy
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : Text(
                        AppStringsScope.of(context)?.isSwahili == true
                            ? 'Fuata' : 'Follow',
                        style: const TextStyle(fontSize: 12),
                      ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$_viewersCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.close,
            color: Colors.white,
            onTap: _onExitRequested,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsOverlay() {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 80,
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          controller: _commentsScrollController,
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            final comment = _comments[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              // G19 — long-press a chat message → reaction picker.
              // Backend fires chat_reaction·chat_author crediting the
              // viewer who wrote the message.
              child: GestureDetector(
                onLongPress: comment.userId == widget.currentUserId
                    ? null
                    : () => _openChatReactionPicker(comment),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: comment.user?.avatarUrl.isNotEmpty == true
                          ? NetworkImage(comment.user!.avatarUrl)
                          : null,
                      child: comment.user?.avatarUrl.isEmpty == true
                          ? Text(
                              comment.user!.firstName[0],
                              style: const TextStyle(fontSize: 10),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              comment.user?.displayName ?? 'Mtumiaji',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              comment.content,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRightActions() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          // A.2 — reaction picker (replaces likeStream heart-toggle)
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
            onTap: _openReactionPicker,
          ),
          const SizedBox(height: 16),
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.card_giftcard,
            color: Colors.white,
            onTap: () => setState(() => _showGifts = true),
          ),
          const SizedBox(height: 16),
          // A.3 — tip with stream context
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.volunteer_activism,
            color: Colors.white,
            onTap: _openSendTip,
          ),
          const SizedBox(height: 16),
          // Super-chat (paid pinned chat — live_super_chat·author)
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.star_rate_rounded,
            color: Colors.amber,
            onTap: _openSuperChat,
          ),
          const SizedBox(height: 16),
          // B1 — Q&A panel (submit + upvote questions)
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.live_help_rounded,
            color: Colors.white,
            onTap: _openQuestionsPanel,
          ),
          const SizedBox(height: 16),
          // A.4 — share now actually shares
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.share,
            color: Colors.white,
            onTap: _shareStream,
          ),
          const SizedBox(height: 16),
          // A.8 — overflow (report / hide / mute / disable-chat)
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.more_horiz_rounded,
            color: Colors.white,
            onTap: _openOverflowMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 8,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Andika ujumbe...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _kMinTouchTarget,
            height: _kMinTouchTarget,
            child: Material(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(_kMinTouchTarget / 2),
              child: InkWell(
                onTap: _sendComment,
                borderRadius: BorderRadius.circular(_kMinTouchTarget / 2),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _GiftsPanel(
        gifts: _gifts,
        onGiftSelected: _sendGift,
        onClose: () => setState(() => _showGifts = false),
      ),
    );
  }

  @override
  void dispose() {
    // A.10 — rapid_leave detection. If viewer dwelled <30s, fire signal.
    if (_joinedAt != null) {
      final dwellMs = DateTime.now().difference(_joinedAt!).inMilliseconds;
      if (dwellMs < 30000) {
        _streamService.negativeFeedback(
          widget.stream.id, widget.currentUserId, 'rapid_leave',
          metadata: {'dwell_ms': dwellMs},
        );
      }
    }

    _heartbeatTimer?.cancel();
    _screenCaptureEvent?.dispose();
    WidgetsBinding.instance.removeObserver(this);

    _commentController.dispose();
    _commentsScrollController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    _connectionErrorSubscription?.cancel();
    _viewerCountSubscription?.cancel();
    _commentSubscription?.cancel();
    _giftSubscription?.cancel();
    _connectionSubscription?.cancel();
    _streamStatusSubscription?.cancel();
    _battleStateSubscription?.cancel();
    _battleInviteSubscription?.cancel();
    _battleModeService.dispose();
    _webSocketService.dispose();

    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}

/// Action button with minimum 48dp touch target (DOCS/DESIGN.md).
class SemanticButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double minSize;
  final VoidCallback onTap;

  const SemanticButton({
    super.key,
    required this.icon,
    this.color = Colors.white,
    this.minSize = _kMinTouchTarget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(minSize / 2),
        child: Container(
          width: minSize,
          height: minSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}

class _GiftsPanel extends StatelessWidget {
  final List<VirtualGift> gifts;
  final void Function(VirtualGift) onGiftSelected;
  final VoidCallback onClose;

  const _GiftsPanel({
    required this.gifts,
    required this.onGiftSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tuma Zawadi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: _kMinTouchTarget,
                  height: _kMinTouchTarget,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                final gift = gifts[index];
                return GestureDetector(
                  onTap: () => onGiftSelected(gift),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: gift.iconUrl.isNotEmpty
                            ? Image.network(gift.iconUrl, fit: BoxFit.cover)
                            : const Icon(Icons.card_giftcard, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gift.name,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'TSH ${gift.price.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
