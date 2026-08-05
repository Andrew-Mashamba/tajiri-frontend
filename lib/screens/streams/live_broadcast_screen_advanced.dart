/// ADVANCED Live Broadcast Screen - Military-Grade Professional Streaming Interface
/// Features: Reactions, Polls, Q&A, Analytics, Super Chat, Battle Mode, Stream Health
/// NOW WITH 🆓 TAJIRI CUSTOM SDK - 100% FREE PROFESSIONAL STREAMING!
/// Zero cost, unlimited streams, all features included!
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../../services/websocket_service.dart';
import '../../services/tajiri_streaming_sdk.dart';
import '../../services/battle_mode_service.dart' show BattleModeService, BattleState, BattleStatus, BattleInvite;

class LiveBroadcastScreenAdvanced extends StatefulWidget {
  final LiveStream stream;
  final int currentUserId;

  const LiveBroadcastScreenAdvanced({
    super.key,
    required this.stream,
    required this.currentUserId,
  });

  @override
  State<LiveBroadcastScreenAdvanced> createState() =>
      _LiveBroadcastScreenAdvancedState();
}

class _LiveBroadcastScreenAdvancedState
    extends State<LiveBroadcastScreenAdvanced>
    with TickerProviderStateMixin {
  final LiveStreamService _streamService = LiveStreamService();
  final WebSocketService _webSocketService = WebSocketService();
  final TajiriStreamingSDK _tajiriSDK = TajiriStreamingSDK();
  late final BattleModeService _battleService;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _commentsScrollController = ScrollController();

  // Stream state
  int _viewersCount = 0;
  int _peakViewers = 0;
  double _earnings = 0.0;
  Duration _duration = Duration.zero;
  Timer? _durationTimer;
  bool _isEnding = false;

  // Comments & Interactions
  final List<StreamComment> _comments = [];
  StreamComment? _pinnedComment;
  final List<SuperChatMessage> _superChats = [];
  StreamSubscription? _commentSubscription;
  StreamSubscription? _viewerCountSubscription;
  StreamSubscription? _giftSubscription;
  StreamSubscription? _tipSubscription;

  // Real-time tip toaster (streams.md §I row 7).
  // Holds the most recently received tip for 3s then clears.
  TipEvent? _activeTipToast;
  Timer? _tipToastDismissTimer;

  // Reactions system
  final List<ReactionBubble> _activeReactions = [];
  Timer? _reactionCleanupTimer;

  // Q&A Mode
  bool _isQAMode = false;
  final List<QuestionItem> _questions = [];

  // Live Poll
  LivePoll? _activePoll;

  // Stream Health
  StreamHealth _streamHealth = StreamHealth(
    networkQuality: NetworkQuality.excellent,
    bitrate: 3500,
    fps: 30,
    droppedFrames: 0,
    latency: 2.5,
  );
  Timer? _healthUpdateTimer;

  // Analytics
  final List<ViewerDataPoint> _viewerHistory = [];
  Timer? _analyticsTimer;

  // UI State
  bool _showAnalytics = false;
  bool _isMuted = false;
  bool _isBeautyOn = false;

  // Battle Mode (PK)
  bool _isInBattle = false;

  // Phase F — host-side dwell heartbeat (mirrors viewer heartbeat).
  // Fires every 60s while broadcasting → host_duration_heartbeat·author.
  Timer? _hostHeartbeatTimer;

  @override
  void initState() {
    super.initState();
    _battleService = BattleModeService(_webSocketService);
    _initializeStream();
    _initializeTajiriStreaming(); // 🆓 Our FREE custom SDK!
    _connectWebSocket();
    _initializeBattleMode();
    _startDurationTimer();
    _startHealthMonitoring();
    _startAnalyticsTracking();
    _startReactionCleanup();
    _startHostHeartbeat();

    // Lock orientation and keep screen on
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _healthUpdateTimer?.cancel();
    _analyticsTimer?.cancel();
    _reactionCleanupTimer?.cancel();
    _hostHeartbeatTimer?.cancel();
    _commentSubscription?.cancel();
    _viewerCountSubscription?.cancel();
    _giftSubscription?.cancel();
    _tipSubscription?.cancel();
    _tipToastDismissTimer?.cancel();
    _webSocketService.disconnect();
    _tajiriSDK.stopStreaming();
    _tajiriSDK.dispose();
    _battleService.dispose();
    _commentController.dispose();
    _commentsScrollController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeStream() async {
    final result = await _streamService.getStream(
      widget.stream.id,
      currentUserId: widget.currentUserId,
    );
    if (result.success && result.stream != null && mounted) {
      setState(() {
        _viewersCount = result.stream!.viewersCount;
        _peakViewers = result.stream!.peakViewers;
        _earnings = result.stream!.giftsValue;
      });
    }
  }

  /// Initialize 🆓 TAJIRI Custom SDK - 100% FREE Professional Streaming!
  Future<void> _initializeTajiriStreaming() async {
    print('[LiveBroadcast] 🆓 Initializing TAJIRI Custom SDK (FREE!)...');

    // Initialize SDK
    final initialized = await _tajiriSDK.initialize();
    if (!initialized) {
      print('[LiveBroadcast] ❌ Failed to initialize TAJIRI SDK');
      _showError('Failed to initialize camera. Please check camera permissions.');
      return;
    }

    print('[LiveBroadcast] ✅ TAJIRI SDK initialized successfully!');

    // Start livestreaming with RTMP push to backend
    final rtmpBaseUrl = 'rtmp://tajiri.zimasystems.com/live';

    final streamStarted = await _tajiriSDK.startStreaming(
      streamId: widget.stream.id,
      rtmpBaseUrl: rtmpBaseUrl,
    );

    if (streamStarted) {
      print('[LiveBroadcast] ✅ TAJIRI streaming started successfully!');
      print('[LiveBroadcast] 🎥 RTMP URL: $rtmpBaseUrl/${widget.stream.id}');
      print('[LiveBroadcast] 💰 Cost: \$0 (FREE FOREVER!)');
    } else {
      print('[LiveBroadcast] ❌ Failed to start TAJIRI streaming');
      _showError('Failed to start livestream. Please try again.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Initialize battle mode and listen to invites
  void _initializeBattleMode() {
    print('[LiveBroadcast] Initializing battle mode...');
    _battleService.initialize();

    // Listen to battle invites
    _battleService.battleInviteStream.listen((invite) {
      if (mounted) {
        _showBattleInvite(invite);
      }
    });

    // Listen to battle state changes
    _battleService.battleStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isInBattle = state.status == BattleStatus.active;
        });

        // Show battle result dialog when ended
        if (state.status == BattleStatus.ended) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _showBattleResult(state);
            }
          });
        }
      }
    });
  }

  Future<void> _connectWebSocket() async {
    await _webSocketService.connectToStream(widget.stream.id, widget.currentUserId);

    _viewerCountSubscription = _webSocketService.viewerCountStream.listen((update) {
      if (mounted) {
        setState(() {
          _viewersCount = update['current_viewers'] as int? ?? _viewersCount;
          if (_viewersCount > _peakViewers) {
            _peakViewers = _viewersCount;
          }
        });
      }
    });

    _commentSubscription = _webSocketService.commentStream.listen((comment) {
      if (mounted) {
        setState(() => _comments.add(comment));
        _autoScrollComments();
      }
    });

    _giftSubscription = _webSocketService.giftStream.listen((giftEvent) {
      if (mounted) {
        setState(() {
          _earnings += giftEvent.gift.price * giftEvent.quantity;
        });
        _showGiftAnimation(giftEvent);
      }
    });

    // Real-time tips on this stream — update ticker + animate toaster.
    _tipSubscription = _webSocketService.tipStream.listen((tipEvent) {
      if (!mounted) return;
      if (tipEvent.streamId != widget.stream.id) return;
      setState(() {
        _earnings += tipEvent.amount;
        _activeTipToast = tipEvent;
      });
      _tipToastDismissTimer?.cancel();
      _tipToastDismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _activeTipToast = null);
      });
    });
  }

  void _startDurationTimer() {
    final startTime = widget.stream.startedAt ?? DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _duration = DateTime.now().difference(startTime));
      }
    });
  }

  void _startHealthMonitoring() {
    _healthUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        // Simulate health metrics (replace with real data from streaming SDK)
        final random = Random();
        setState(() {
          _streamHealth = StreamHealth(
            networkQuality: NetworkQuality.values[random.nextInt(3)],
            bitrate: 2500 + random.nextInt(2000),
            fps: 28 + random.nextInt(3),
            droppedFrames: random.nextInt(10),
            latency: 2.0 + random.nextDouble() * 2.0,
          );
        });
      }
    });
  }

  void _startAnalyticsTracking() {
    _analyticsTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _viewerHistory.add(ViewerDataPoint(
            time: _duration,
            viewers: _viewersCount,
          ));
          // Keep only last 50 data points
          if (_viewerHistory.length > 50) {
            _viewerHistory.removeAt(0);
          }
        });
      }
    });
  }

  void _startReactionCleanup() {
    _reactionCleanupTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _activeReactions.isNotEmpty) {
        setState(() {
          _activeReactions.removeWhere((r) => r.isExpired);
        });
      }
    });
  }

  void _autoScrollComments() {
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

  void _showGiftAnimation(GiftEvent giftEvent) {
    // Show animated gift (implementation from previous version)
  }

  /// Show battle invite dialog
  void _showBattleInvite(BattleInvite invite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Battle Invite! 🎮'),
        content: Text('${invite.opponentName} has challenged you to a battle!'),
        actions: [
          TextButton(
            onPressed: () {
              _battleService.declineBattle(invite.battleId);
              Navigator.pop(context);
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () {
              _battleService.acceptBattle(invite.battleId);
              Navigator.pop(context);
            },
            child: const Text('Accept! 🔥'),
          ),
        ],
      ),
    );
  }

  /// Show battle result dialog
  void _showBattleResult(BattleState state) {
    final isWinner = state.winnerId == widget.currentUserId;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWinner ? '🏆 You Won!' : '😔 Battle Ended'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score:'),
            const SizedBox(height: 8),
            Text('You: ${state.myScore}'),
            Text('${state.opponentName}: ${state.opponentScore}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ==================== REACTIONS SYSTEM ====================

  void _sendReaction(ReactionType type) {
    final random = Random();
    final reaction = ReactionBubble(
      type: type,
      startX: 20.0 + random.nextDouble() * 200,
      createdAt: DateTime.now(),
    );
    setState(() => _activeReactions.add(reaction));

    // TODO: Send reaction to WebSocket
    // _webSocketService.sendReaction(widget.stream.id, type);
  }

  // ==================== PHASE B — STREAMER TOOLS SHEET ====================
  // Single bottom-sheet that surfaces every streamer-side action that
  // emits a Phase 1+ earnings event. Wraps the existing Phase A backend
  // endpoints (chat-pin, Q&A, raid, host, products, notify, ext-link,
  // AI-avatar disclosure).

  void _openStreamerTools() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Text(
              'Streamer tools',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _toolsTile(ctx, Icons.live_help_rounded,
              'Q&A panel',
              'Answer questions to credit askers',
              () { Navigator.pop(ctx); _toggleQAMode(); }),
            _toolsTile(ctx, Icons.poll_rounded,
              'Create poll',
              'Engage chat with a 60s poll',
              () { Navigator.pop(ctx); _createPoll(); }),
            _toolsTile(ctx, Icons.notifications_active_rounded,
              'Notify followers',
              'Alert followers you are live',
              () { Navigator.pop(ctx); _notifyFollowers(); }),
            _toolsTile(ctx, Icons.inventory_2_rounded,
              'Pin product',
              'Show a product overlay (live commerce)',
              () { Navigator.pop(ctx); _pinProduct(); }),
            _toolsTile(ctx, Icons.link_rounded,
              'Pin external link',
              'Drive outbound clicks',
              () { Navigator.pop(ctx); _pinExternalLink(); }),
            _toolsTile(ctx, Icons.compare_arrows_rounded,
              'Raid another stream',
              'Send your viewers to another live stream',
              () { Navigator.pop(ctx); _raidPicker(); }),
            _toolsTile(ctx, Icons.podcasts_rounded,
              'Host another streamer',
              'Broadcast another channel during downtime',
              () { Navigator.pop(ctx); _hostPicker(); }),
            _toolsTile(ctx, Icons.face_retouching_natural_rounded,
              'AI avatar disclosure',
              'Disclose synthetic avatar (earns full rate)',
              () { Navigator.pop(ctx); _aiAvatarDisclose(); }),
            // ─── Phase F — collaboration + AI provenance ──────────
            _toolsTile(ctx, Icons.group_add_rounded,
              'Invite co-host',
              'Add a 2nd streamer to share tip pool',
              () { Navigator.pop(ctx); _cohostInvitePicker(); }),
            _toolsTile(ctx, Icons.person_add_alt_1_rounded,
              'Add guest',
              'Drop-in / panel / interview',
              () { Navigator.pop(ctx); _guestPicker(); }),
            _toolsTile(ctx, Icons.auto_awesome_rounded,
              'Generate AI clip',
              'Auto-clip current moment for posts',
              () { Navigator.pop(ctx); _aiClipGenerate(); }),
            _toolsTile(ctx, Icons.mic_rounded,
              'Voice clone consent',
              'Allow AI dubs of your voice (you earn)',
              () { Navigator.pop(ctx); _aiVoiceCloneConsent(); }),
            _toolsTile(ctx, Icons.shuffle_rounded,
              'AI-assisted remix',
              'Log derivative AI remix attestation',
              () { Navigator.pop(ctx); _aiAssistedRemix(); }),
            _toolsTile(ctx, Icons.movie_filter_rounded,
              'Compile highlights (AI)',
              'Trigger AI auto-clip pipeline for this stream',
              () { Navigator.pop(ctx); _highlightCompilation(); }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _toolsTile(BuildContext ctx, IconData icon, String label, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      onTap: onTap,
    );
  }

  Future<void> _notifyFollowers() async {
    final ok = await _streamService.notifyFollowers(widget.stream.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Notifying followers' : 'Failed')),
      );
    }
  }

  Future<void> _pinProduct() async {
    final urlController = TextEditingController();
    final labelController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pin product'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: urlController, decoration: const InputDecoration(labelText: 'External URL')),
          TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pin')),
        ],
      ),
    );
    if (result == true && urlController.text.isNotEmpty) {
      // Wired to Phase 3d StreamCommerceController::pinProduct via direct HTTP.
      await _streamService.pinStreamProduct(
        streamId: widget.stream.id,
        streamerUserId: widget.currentUserId,
        externalUrl: urlController.text.trim(),
        label: labelController.text.trim().isEmpty ? null : labelController.text.trim(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product pinned')),
      );
    }
  }

  Future<void> _pinExternalLink() async {
    final urlCtl = TextEditingController();
    final labelCtl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pin outbound link'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: urlCtl,
            decoration: const InputDecoration(labelText: 'URL')),
          TextField(controller: labelCtl,
            decoration: const InputDecoration(labelText: 'Label (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pin')),
        ],
      ),
    );
    if (result != true) return;
    final url = urlCtl.text.trim();
    if (url.isEmpty) return;
    // Phase G — persist via /streams/{id}/pinned-link so the viewer's
    // overlay shows it. Backend self-fires external_link_click·author.
    final ok = await _streamService.setPinnedLink(
      streamId: widget.stream.id,
      streamerUserId: widget.currentUserId,
      url: url,
      label: labelCtl.text.trim().isEmpty ? null : labelCtl.text.trim(),
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Link pinned — viewers will see the overlay'
          : 'Pin failed'),
    ));
  }

  Future<void> _raidPicker() async {
    final controller = TextEditingController();
    final id = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raid target stream'),
        content: TextField(controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target stream ID')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Raid'),
          ),
        ],
      ),
    );
    if (id == null) return;
    final ok = await _streamService.raidStream(
      sourceStreamId: widget.stream.id,
      raidStreamerId: widget.currentUserId,
      targetStreamId: id,
      viewerCount: 0,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Raid sent' : 'Failed to raid')),
    );
  }

  Future<void> _hostPicker() async {
    final controller = TextEditingController();
    final id = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Host another streamer'),
        content: TextField(controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stream to host')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Host'),
          ),
        ],
      ),
    );
    if (id == null) return;
    final ok = await _streamService.hostStream(
      hostStreamId: widget.stream.id,
      hostStreamerId: widget.currentUserId,
      hostedStreamId: id,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Hosting started' : 'Failed to host')),
    );
  }

  Future<void> _aiAvatarDisclose() async {
    final ok = await _streamService.disclosesyntheticAvatar(
      streamId: widget.stream.id,
      subjectUserId: widget.currentUserId,
      avatarProvider: 'manual_disclosure',
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'AI avatar disclosed — full rate active' : 'Failed')),
    );
  }

  // ═══════════ Phase F — host-side dwell heartbeat ═══════════════════
  // Mirrors viewer-side heartbeat: every 60s while broadcasting, fire
  // host_duration_heartbeat·author. Backend dedupes per minute-bucket.
  void _startHostHeartbeat() {
    _hostHeartbeatTimer?.cancel();
    _hostHeartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isEnding) return;
      _streamService.hostHeartbeat(
        streamId: widget.stream.id,
        streamerUserId: widget.currentUserId,
      );
    });
  }

  // ═══════════ Phase F — co-host invite ════════════════════════════
  Future<void> _cohostInvitePicker() async {
    final controller = TextEditingController();
    final id = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite co-host'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'User ID to invite'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
    if (id == null) return;
    final ok = await _streamService.cohostInvite(
      streamId: widget.stream.id, userId: id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Co-host invitation sent' : 'Failed')),
    );
  }

  // ═══════════ Phase F — guest appearance ══════════════════════════
  Future<void> _guestPicker() async {
    final controller = TextEditingController();
    String role = 'guest';
    final result = await showDialog<({int id, String role})?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add guest'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Guest user ID'),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: role,
              onChanged: (v) => setLocal(() => role = v ?? 'guest'),
              items: const [
                DropdownMenuItem(value: 'guest', child: Text('Guest')),
                DropdownMenuItem(value: 'panelist', child: Text('Panelist')),
                DropdownMenuItem(value: 'interview', child: Text('Interview')),
              ],
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final id = int.tryParse(controller.text.trim());
                if (id != null) Navigator.pop(ctx, (id: id, role: role));
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final ok = await _streamService.guestAppearance(
      streamId: widget.stream.id,
      guestUserId: result.id,
      role: result.role,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Guest appearance recorded' : 'Failed')),
    );
  }

  // ═══════════ Phase F — AI auto-clip generation ═══════════════════
  Future<void> _aiClipGenerate() async {
    // Fire ai_clip_generation·author. The actor (clipper) is the streamer
    // themselves in the manual-trigger case; subject is the streamer.
    final ok = await _streamService.aiClipGeneration(
      streamId: widget.stream.id,
      subjectUserId: widget.currentUserId,
      actorUserId: widget.currentUserId,
      modelId: 'manual_trigger',
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'AI clip generation logged' : 'Failed')),
    );
  }

  // ═══════════ Phase F — voice clone consent ═══════════════════════
  Future<void> _aiVoiceCloneConsent() async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Voice clone consent'),
        content: const Text(
          'Allow AI services to use your voice in derivative content. '
          'You will earn a share of any earnings from voice-clone-based work.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Decline')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('I consent')),
        ],
      ),
    );
    if (agreed != true) return;
    final ok = await _streamService.aiVoiceCloneUsage(
      streamId: widget.stream.id,
      subjectUserId: widget.currentUserId,
      actorUserId: widget.currentUserId,
      licenseId: 'self_consent',
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Voice clone consent recorded' : 'Failed')),
    );
  }

  // ═══════════ Phase F — AI-assisted remix ═════════════════════════
  Future<void> _aiAssistedRemix() async {
    final ok = await _streamService.aiAssistedRemix(
      streamId: widget.stream.id,
      remixerUserId: widget.currentUserId,
      modelId: 'manual_trigger',
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'AI remix logged' : 'Failed')),
    );
  }

  // ═══════════ Phase G — AI highlight compilation ══════════════════
  Future<void> _highlightCompilation() async {
    final ok = await _streamService.highlightCompilation(
      streamId: widget.stream.id,
      editorUserId: widget.currentUserId,
      modelId: 'manual_trigger',
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        ok ? 'Highlight compilation queued' : 'Failed')),
    );
  }

  // ==================== LIVE POLL SYSTEM ====================

  void _createPoll() {
    showDialog(
      context: context,
      builder: (context) => _PollCreatorDialog(
        onPollCreated: (poll) {
          setState(() => _activePoll = poll);
          // TODO: Send poll to WebSocket
          Navigator.pop(context);
        },
      ),
    );
  }

  void _closePoll() {
    setState(() => _activePoll = null);
  }

  // ==================== Q&A MODE ====================

  void _toggleQAMode() {
    setState(() {
      _isQAMode = !_isQAMode;
      if (_isQAMode) {
        // Load questions
        _loadQuestions();
      }
    });
  }

  Future<void> _loadQuestions() async {
    // TODO: Load questions from backend
    // For now, mock data
    setState(() {
      _questions.addAll([
        QuestionItem(
          id: 1,
          userId: 1,
          username: "John Doe",
          question: "What's your favorite topic?",
          upvotes: 5,
          timestamp: DateTime.now(),
        ),
      ]);
    });
  }

  void _answerQuestion(QuestionItem question) {
    setState(() {
      question.isAnswered = true;
    });
    // G2 — fire q_and_a_answered·question_author. Backend credits the
    // asker (postAuthorId = question.user_id) when the streamer marks
    // their question answered.
    _streamService.answerQuestion(
      widget.stream.id, widget.currentUserId, question.id);
  }

  // ==================== SUPER CHAT ====================

  // ==================== COMMENT MANAGEMENT ====================

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    _commentController.clear();
    final result = await _streamService.addComment(
      widget.stream.id,
      widget.currentUserId,
      content,
    );

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imeshindwa: ${result.message ?? "Kosa"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _pinComment(StreamComment comment) {
    setState(() => _pinnedComment = comment);
    // G1 — fire chat_pin·author. Backend credits the streamer for
    // pinning a community message; frequency-clamped server-side.
    _streamService.pinComment(widget.stream.id, comment.id);
  }

  void _unpinComment() {
    setState(() => _pinnedComment = null);
  }

  // ==================== STREAM CONTROLS ====================

  Future<void> _endStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maliza Tangazo?'),
        content: const Text(
          'Una uhakika unataka kumaliza tangazo lako?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Endelea'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ndiyo, Maliza'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isEnding = true);
      final result = await _streamService.endStream(widget.stream.id);

      if (mounted) {
        if (result.success) {
          _showStreamSummary(result.stream);
        } else {
          setState(() => _isEnding = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imeshindwa: ${result.message ?? "Kosa"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showStreamSummary(LiveStream? endedStream) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _StreamSummaryDialog(
        stream: endedStream,
        duration: _duration,
        peakViewers: _peakViewers,
        totalEarnings: _earnings,
      ),
    );
  }

  // ==================== UI BUILDERS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            _buildCameraPreview(),

            // Top Bar with all controls
            _buildTopBar(),

            // Pinned Comment
            if (_pinnedComment != null) _buildPinnedComment(),

            // Super Chat Messages
            ..._superChats.map((sc) => _buildSuperChatOverlay(sc)).toList(),

            // Active Poll
            if (_activePoll != null) _buildPollOverlay(),

            // Stream Health Monitor
            if (_showAnalytics) _buildHealthMonitor(),

            // Live Analytics Panel
            if (_showAnalytics) _buildAnalyticsPanel(),

            // Q&A Panel
            if (_isQAMode) _buildQAPanel(),

            // Right Side - Actions & Controls
            Positioned(
              right: 12,
              top: 100,
              bottom: 200,
              child: _buildRightControls(),
            ),

            // Bottom - Comments & Reactions
            Positioned(
              left: 0,
              right: 60,
              bottom: 0,
              child: _buildBottomSection(),
            ),

            // Floating Reactions
            ..._activeReactions.map((r) => _buildReactionBubble(r)).toList(),

            // Real-time tip toaster (auto-dismisses after 3s)
            if (_activeTipToast != null) _buildTipToast(_activeTipToast!),

            // Loading overlay
            if (_isEnding) _buildLoadingOverlay(),

            // Battle Mode UI
            if (_isInBattle) _buildBattleOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Show actual camera feed from our FREE TAJIRI SDK! 🎥
    if (_tajiriSDK.isInitialized && _tajiriSDK.cameraController != null) {
      final controller = _tajiriSDK.cameraController!;

      if (controller.value.isInitialized) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize!.height,
              height: controller.value.previewSize!.width,
              child: CameraPreview(controller),
            ),
          ),
        );
      }
    }

    // Loading state
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              '🆓 Initializing FREE TAJIRI SDK...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Professional streaming at \$0 cost!',
              style: TextStyle(
                color: Colors.green.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Live indicator with pulse
              _buildLiveIndicator(),
              const SizedBox(width: 12),

              // Viewer count
              _buildViewerCountBadge(),
              const SizedBox(width: 12),

              // Duration
              _buildDurationBadge(),

              const Spacer(),

              // Phase B — Streamer tools sheet (Q&A, chat-pin, raid, host,
              // products, notify-followers, AI-disclosure, external link).
              IconButton(
                onPressed: _openStreamerTools,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                ),
              ),

              // Analytics toggle
              IconButton(
                onPressed: () => setState(() => _showAnalytics = !_showAnalytics),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showAnalytics
                        ? Colors.blue.withOpacity(0.8)
                        : Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 20),
                ),
              ),

              // End stream
              IconButton(
                onPressed: _endStream,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Earnings ticker
          _buildEarningsTicker(),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewerCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            _formatNumber(_viewersCount),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (_viewersCount == _peakViewers && _peakViewers > 0) ...[
            const SizedBox(width: 4),
            const Icon(Icons.trending_up, color: Colors.green, size: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _formatDuration(_duration),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEarningsTicker() {
    if (_earnings == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.amber.shade900],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'TZS ${_earnings.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 3-second animated banner shown when a viewer tips during the live
  /// stream (subscribed to Reverb event `tip.received` on `stream.{id}`).
  /// Slides in from the top, dwells, and fades out via the auto-dismiss
  /// timer in [_tipSubscription].
  Widget _buildTipToast(TipEvent tip) {
    final sender = tip.sender;
    final displayName = sender == null
        ? 'Mtumiaji'
        : '${sender.firstName} ${sender.lastName}'.trim();
    final shownName = displayName.isEmpty ? 'Mtumiaji' : displayName;
    final amountStr = 'TZS ${tip.amount.toStringAsFixed(0)}';

    // L12 — safe-zone placement. The HUD packs widgets at known offsets:
    //   top: 80  → stream-health monitor (when _showAnalytics)
    //   top: 100 → analytics panel (when _showAnalytics)
    //   top: 120 → pinned comment
    //   top: 180 → super-chat overlay
    //   top: 200 → poll overlay
    // The tip toaster needs to sit BELOW all of those if any is visible.
    // We probe each potential collider in priority order and pick the
    // nearest safe slot below it. Default is top: 80 when the HUD is clean.
    double topOffset = 80.0;
    if (_showAnalytics) {
      // Both health monitor + analytics panel can be on simultaneously;
      // their stack extends roughly to top: 240. Drop below.
      topOffset = 260.0;
    } else if (_pinnedComment != null) {
      // Pinned comment is ~50dp tall starting at top:120 → safe slot at 180.
      // Super-chat starts at top:180+ so if there's also super chat, push
      // further down.
      topOffset = _superChats.isNotEmpty ? 260.0 : 200.0;
    } else if (_superChats.isNotEmpty) {
      // Super-chats already at top: 180+. Sit above the next free row.
      topOffset = 80.0;
    }

    return Positioned(
      top: topOffset,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        // Key on tip_id so the slide-in animation re-runs for each new
        // tip (TweenAnimationBuilder caches its tween otherwise — without
        // a key, a back-to-back tip would not show the animation).
        child: TweenAnimationBuilder<double>(
          key: ValueKey<int>(tip.tipId),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * -12),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$shownName · $amountStr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tip.message != null && tip.message!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            tip.message!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedComment() {
    return Positioned(
      top: 120,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade700.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_pinnedComment!.user?.displayName ?? "User"}: ${_pinnedComment!.content}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: _unpinComment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperChatOverlay(SuperChatMessage superChat) {
    final Color bgColor = superChat.tier == SuperChatTier.high
        ? Colors.red.shade700
        : superChat.tier == SuperChatTier.medium
            ? Colors.amber.shade700
            : Colors.blue.shade700;

    return Positioned(
      top: 180 + (_superChats.indexOf(superChat) * 60.0),
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor, bgColor.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TZS ${superChat.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  superChat.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              superChat.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollOverlay() {
    return Positioned(
      top: 200,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade300, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.poll, color: Colors.purple, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activePoll!.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: _closePoll,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activePoll!.options.map((option) {
              final percentage = _activePoll!.totalVotes > 0
                  ? (option.votes / _activePoll!.totalVotes * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPollOption(option, percentage),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPollOption(PollOption option, double percentage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Progress bar
          FractionallySizedBox(
            widthFactor: percentage / 100,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMonitor() {
    return Positioned(
      top: 80,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _streamHealth.networkQuality.color,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stream Health',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildHealthItem('Network', _streamHealth.networkQuality.label,
                _streamHealth.networkQuality.color),
            _buildHealthItem(
                'Bitrate', '${_streamHealth.bitrate} kbps', Colors.white),
            _buildHealthItem('FPS', '${_streamHealth.fps}', Colors.white),
            _buildHealthItem(
                'Dropped', '${_streamHealth.droppedFrames}', Colors.white),
            _buildHealthItem('Latency',
                '${_streamHealth.latency.toStringAsFixed(1)}s', Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPanel() {
    return Positioned(
      bottom: 250,
      left: 12,
      right: 12,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Analytics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _viewerHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'Collecting data...',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : CustomPaint(
                      painter: ViewerGraphPainter(_viewerHistory),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQAPanel() {
    return Positioned(
      top: 100,
      left: 12,
      right: 12,
      bottom: 200,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.question_answer, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Q&A Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleQAMode,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _questions.isEmpty
                  ? const Center(
                      child: Text(
                        'No questions yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        return _buildQuestionCard(question);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionItem question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: question.isAnswered
            ? Colors.green.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: question.isAnswered ? Colors.green : Colors.blue,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade700,
                child: Text(
                  question.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${question.upvotes}',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 8),
          if (!question.isAnswered)
            ElevatedButton.icon(
              onPressed: () => _answerQuestion(question),
              icon: const Icon(Icons.mic, size: 18),
              label: const Text('Answer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRightControls() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: () async {
              await _tajiriSDK.flipCamera();
            },
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Muted' : 'Mic',
            color: _isMuted ? Colors.red : null,
            onTap: () async {
              await _tajiriSDK.toggleMute();
              setState(() => _isMuted = _tajiriSDK.isMuted);
            },
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            icon: Icons.face_retouching_natural,
            label: 'Beauty',
            color: _isBeautyOn ? Colors.pink : null,
            onTap: () async {
              await _tajiriSDK.toggleBeauty();
              setState(() => _isBeautyOn = _tajiriSDK.beautyEnabled);
            },
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            icon: Icons.poll,
            label: 'Poll',
            onTap: _createPoll,
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            icon: Icons.question_answer,
            label: 'Q&A',
            color: _isQAMode ? Colors.blue : null,
            onTap: _toggleQAMode,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color ?? Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildReactionButton('❤️', ReactionType.heart),
              _buildReactionButton('🔥', ReactionType.fire),
              _buildReactionButton('👏', ReactionType.clap),
              _buildReactionButton('😮', ReactionType.wow),
              _buildReactionButton('😂', ReactionType.laugh),
              _buildReactionButton('😢', ReactionType.sad),
            ],
          ),
          const SizedBox(height: 12),

          // Comments list
          if (_comments.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                controller: _commentsScrollController,
                shrinkWrap: true,
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  return _buildCommentBubble(_comments[index]);
                },
              ),
            ),
          const SizedBox(height: 12),

          // Comment input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Andika maoni...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendComment,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(String emoji, ReactionType type) {
    return GestureDetector(
      onTap: () => _sendReaction(type),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentBubble(StreamComment comment) {
    return GestureDetector(
      onLongPress: () => _pinComment(comment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${comment.user?.displayName ?? "User"}: ',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              TextSpan(
                text: comment.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionBubble(ReactionBubble reaction) {
    final progress = reaction.progress;
    return Positioned(
      left: reaction.startX,
      bottom: 100 + (progress * 400),
      child: Opacity(
        opacity: 1.0 - progress,
        child: Transform.scale(
          scale: 0.5 + (progress * 0.5),
          child: Text(
            reaction.type.emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Inamaliza tangazo...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleOverlay() {
    // TODO: Implement battle mode overlay
    return const SizedBox.shrink();
  }

  // Helper methods
  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ==================== DATA MODELS ====================

enum ReactionType {
  heart,
  fire,
  clap,
  wow,
  laugh,
  sad;

  String get emoji {
    switch (this) {
      case ReactionType.heart:
        return '❤️';
      case ReactionType.fire:
        return '🔥';
      case ReactionType.clap:
        return '👏';
      case ReactionType.wow:
        return '😮';
      case ReactionType.laugh:
        return '😂';
      case ReactionType.sad:
        return '😢';
    }
  }
}

class ReactionBubble {
  final ReactionType type;
  final double startX;
  final DateTime createdAt;

  ReactionBubble({
    required this.type,
    required this.startX,
    required this.createdAt,
  });

  bool get isExpired =>
      DateTime.now().difference(createdAt).inMilliseconds > 3000;

  double get progress {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds;
    return (elapsed / 3000).clamp(0.0, 1.0);
  }
}

class LivePoll {
  final String question;
  final List<PollOption> options;
  int totalVotes = 0;

  LivePoll({
    required this.question,
    required this.options,
  });
}

class PollOption {
  final String text;
  int votes = 0;

  PollOption({required this.text});
}

class QuestionItem {
  final int id;
  final int userId;
  final String username;
  final String question;
  int upvotes;
  final DateTime timestamp;
  bool isAnswered;

  QuestionItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.question,
    required this.upvotes,
    required this.timestamp,
    this.isAnswered = false,
  });
}

enum SuperChatTier { low, medium, high }

class SuperChatMessage {
  final String username;
  final String message;
  final double amount;
  final SuperChatTier tier;
  final int duration; // seconds to display

  SuperChatMessage({
    required this.username,
    required this.message,
    required this.amount,
    required this.tier,
    required this.duration,
  });
}

enum NetworkQuality {
  excellent,
  good,
  poor;

  String get label {
    switch (this) {
      case NetworkQuality.excellent:
        return 'Excellent';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.poor:
        return 'Poor';
    }
  }

  Color get color {
    switch (this) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.yellow;
      case NetworkQuality.poor:
        return Colors.red;
    }
  }
}

class StreamHealth {
  final NetworkQuality networkQuality;
  final int bitrate; // kbps
  final int fps;
  final int droppedFrames;
  final double latency; // seconds

  StreamHealth({
    required this.networkQuality,
    required this.bitrate,
    required this.fps,
    required this.droppedFrames,
    required this.latency,
  });
}

class ViewerDataPoint {
  final Duration time;
  final int viewers;

  ViewerDataPoint({required this.time, required this.viewers});
}

enum PanelType { none, analytics, qa, battle }

// BattleState is now imported from battle_mode_service.dart

// ==================== CUSTOM PAINTERS ====================

class ViewerGraphPainter extends CustomPainter {
  final List<ViewerDataPoint> data;

  ViewerGraphPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxViewers =
        data.map((d) => d.viewers).reduce((a, b) => a > b ? a : b).toDouble();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].viewers / maxViewers * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==================== DIALOGS ====================

class _PollCreatorDialog extends StatefulWidget {
  final Function(LivePoll) onPollCreated;

  const _PollCreatorDialog({required this.onPollCreated});

  @override
  State<_PollCreatorDialog> createState() => __PollCreatorDialogState();
}

class __PollCreatorDialogState extends State<_PollCreatorDialog> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Poll'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(labelText: 'Question'),
          ),
          const SizedBox(height: 16),
          ..._optionControllers.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(labelText: 'Option ${entry.key + 1}'),
              ),
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final poll = LivePoll(
              question: _questionController.text,
              options: _optionControllers
                  .map((c) => PollOption(text: c.text))
                  .toList(),
            );
            widget.onPollCreated(poll);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _StreamSummaryDialog extends StatelessWidget {
  final LiveStream? stream;
  final Duration duration;
  final int peakViewers;
  final double totalEarnings;

  const _StreamSummaryDialog({
    this.stream,
    required this.duration,
    required this.peakViewers,
    required this.totalEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          SizedBox(width: 12),
          Text('Stream Ended!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryItem(Icons.timer, 'Duration',
              '${duration.inMinutes} minutes'),
          const SizedBox(height: 12),
          _buildSummaryItem(
              Icons.people, 'Peak Viewers', peakViewers.toString()),
          const SizedBox(height: 12),
          _buildSummaryItem(Icons.favorite, 'Total Likes',
              (stream?.likesCount ?? 0).toString()),
          const SizedBox(height: 12),
          _buildSummaryItem(Icons.card_giftcard, 'Earnings',
              'TZS ${totalEarnings.toStringAsFixed(0)}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close broadcast screen
          },
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
