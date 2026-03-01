/// Story 58: Watch Live Stream
/// Full-screen video, overlay chat, like/hearts, gifts.
/// Navigation: Home → Feed → Live tab → Tap stream OR Profile → Live tab → Tap.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../../services/websocket_service.dart';
import '../../services/battle_mode_service.dart' show BattleModeService, BattleState, BattleInvite, BattleStatus;
import '../../widgets/battle_mode_overlay.dart';
import '../../config/api_config.dart';
import '../../services/local_storage_service.dart';
import '../wallet/send_tip_screen.dart';
import 'battlemodeoverlay_screen.dart';

/// Minimum touch target per DOCS/DESIGN.md (48dp)
const double _kMinTouchTarget = 48.0;

class StreamViewerScreen extends StatefulWidget {
  final LiveStream stream;
  final int currentUserId;

  const StreamViewerScreen({
    super.key,
    required this.stream,
    required this.currentUserId,
  });

  @override
  State<StreamViewerScreen> createState() => _StreamViewerScreenState();
}

class _StreamViewerScreenState extends State<StreamViewerScreen> {
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

  @override
  void initState() {
    super.initState();
    _battleModeService = BattleModeService(_webSocketService);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WakelockPlus.enable();
    _checkSessionAndStart();
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

    final joinResult = await _streamService.joinStream(widget.stream.id, widget.currentUserId);
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

    final playbackUrl = joinResult.playbackUrl;
    final websocket = joinResult.websocket;
    if (joinResult.currentViewers != null) {
      _viewersCount = joinResult.currentViewers!;
    }

    _initializeVideoPlayer(playbackUrl);
    _loadData();
    if (websocket != null && websocket.url.isNotEmpty && websocket.channel.isNotEmpty) {
      _connectWebSocket(websocket.url, websocket.channel);
    }
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

  Future<void> _toggleLike() async {
    await _streamService.likeStream(widget.stream.id, widget.currentUserId);
    setState(() => _isLiked = !_isLiked);
  }

  Future<void> _sendGift(VirtualGift gift) async {
    final success = await _streamService.sendGift(
      widget.stream.id,
      widget.currentUserId,
      gift.id,
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

  void _openSendTip() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SendTipScreen(
          creatorId: widget.stream.userId,
          currentUserId: widget.currentUserId,
          creatorDisplayName: widget.stream.user?.displayName,
        ),
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

  @override
  Widget build(BuildContext context) {
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
          ],
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
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
            onTap: _toggleLike,
          ),
          const SizedBox(height: 16),
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.card_giftcard,
            color: Colors.white,
            onTap: () => setState(() => _showGifts = true),
          ),
          const SizedBox(height: 16),
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.volunteer_activism,
            color: Colors.white,
            onTap: _openSendTip,
          ),
          const SizedBox(height: 16),
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.share,
            color: Colors.white,
            onTap: () {},
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
