/// Live Broadcast Screen - Active streaming view for broadcasters
/// Shows camera feed, viewers, comments, gifts in real-time
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../../services/websocket_service.dart';

class LiveBroadcastScreen extends StatefulWidget {
  final LiveStream stream;
  final int currentUserId;

  const LiveBroadcastScreen({
    super.key,
    required this.stream,
    required this.currentUserId,
  });

  @override
  State<LiveBroadcastScreen> createState() => _LiveBroadcastScreenState();
}

class _LiveBroadcastScreenState extends State<LiveBroadcastScreen>
    with TickerProviderStateMixin {
  final LiveStreamService _streamService = LiveStreamService();
  final WebSocketService _webSocketService = WebSocketService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _commentsScrollController = ScrollController();

  // Stream state
  int _viewersCount = 0;
  Duration _duration = Duration.zero;
  Timer? _durationTimer;
  bool _isEnding = false;

  // Comments
  final List<StreamComment> _comments = [];
  StreamSubscription? _commentSubscription;
  StreamSubscription? _viewerCountSubscription;
  StreamSubscription? _giftSubscription;

  // Gift animations
  final List<GiftAnimationData> _activeGiftAnimations = [];

  // Camera controls
  bool _isCameraFlipped = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _connectWebSocket();
    _startDurationTimer();
    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // Keep screen on
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _commentSubscription?.cancel();
    _viewerCountSubscription?.cancel();
    _giftSubscription?.cancel();
    _webSocketService.disconnect();
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
    // Load initial stream data
    final result = await _streamService.getStream(
      widget.stream.id,
      currentUserId: widget.currentUserId,
    );
    if (result.success && result.stream != null && mounted) {
      setState(() {
        _viewersCount = result.stream!.viewersCount;
      });
    }
  }

  Future<void> _connectWebSocket() async {
    await _webSocketService.connectToStream(widget.stream.id, widget.currentUserId);

    // Listen to viewer count updates
    _viewerCountSubscription =
        _webSocketService.viewerCountStream.listen((update) {
      if (mounted) {
        setState(() => _viewersCount = (update['current_viewers'] as int?) ?? 0);
      }
    });

    // Listen to comments
    _commentSubscription = _webSocketService.commentStream.listen((comment) {
      if (mounted) {
        setState(() => _comments.add(comment));
        // Auto-scroll to bottom
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
    });

    // Listen to gifts
    _giftSubscription = _webSocketService.giftStream.listen((giftEvent) {
      if (mounted) {
        _showGiftAnimation(giftEvent);
      }
    });
  }

  void _startDurationTimer() {
    final startTime = widget.stream.startedAt ?? DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = DateTime.now().difference(startTime);
        });
      }
    });
  }

  void _showGiftAnimation(GiftEvent giftEvent) {
    final animationData = GiftAnimationData(
      gift: giftEvent.gift,
      sender: giftEvent.sender,
      quantity: giftEvent.quantity,
      message: giftEvent.message,
    );
    setState(() => _activeGiftAnimations.add(animationData));

    // Remove after animation completes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _activeGiftAnimations.remove(animationData));
      }
    });
  }

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
          content: Text('Imeshindwa kutuma: ${result.message ?? "Kosa"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maliza Tangazo?'),
        content: const Text(
          'Una uhakika unataka kumaliza tangazo lako?\n\nWatazamaji wataona tangazo limekamilika.',
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
          // Show summary before exiting
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
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Tangazo Limekamilika!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryItem(
              icon: Icons.timer,
              label: 'Muda',
              value: _formatDuration(_duration),
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
              icon: Icons.people,
              label: 'Watazamaji',
              value: (endedStream?.totalViewers ?? 0).toString(),
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
              icon: Icons.favorite,
              label: 'Likes',
              value: (endedStream?.likesCount ?? 0).toString(),
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
              icon: Icons.card_giftcard,
              label: 'Zawadi',
              value: 'TZS ${(endedStream?.giftsValue ?? 0).toStringAsFixed(0)}',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close broadcast screen
            },
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue.shade700),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview (placeholder - will integrate camera later)
            _buildCameraPreview(),

            // Top Bar
            _buildTopBar(),

            // Right Side - Viewer Avatars
            Positioned(
              right: 12,
              top: 100,
              bottom: 200,
              child: _buildViewerList(),
            ),

            // Bottom - Comments & Input
            Positioned(
              left: 0,
              right: 60,
              bottom: 0,
              child: _buildCommentsSection(),
            ),

            // Gift Animations Overlay
            ..._activeGiftAnimations
                .map((data) => _buildGiftAnimation(data))
                .toList(),

            // Camera Controls
            Positioned(
              right: 12,
              bottom: 120,
              child: _buildCameraControls(),
            ),

            // Loading overlay when ending
            if (_isEnding)
              Container(
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Placeholder for camera feed
    // TODO: Integrate camera package and RTMP streaming
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, size: 80, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Kamera ya Tangazo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(Itaunganishwa na kamera halisi)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
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
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
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
          ),
          const SizedBox(width: 12),

          // Viewer count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
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
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
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
          ),

          const Spacer(),

          // End stream button
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
    );
  }

  Widget _buildViewerList() {
    // Placeholder for viewer avatars
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Show first few viewer avatars
          ...List.generate(
            (_viewersCount > 5 ? 5 : _viewersCount),
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade700,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
          if (_viewersCount > 5)
            Text(
              '+${_viewersCount - 5}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Comments list
          if (_comments.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                controller: _commentsScrollController,
                shrinkWrap: true,
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return _buildCommentBubble(comment);
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

  Widget _buildCommentBubble(StreamComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${comment.user?.displayName ?? "Anonymous"}: ',
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
    );
  }

  Widget _buildCameraControls() {
    return Column(
      children: [
        // Flip camera
        IconButton(
          onPressed: () {
            setState(() => _isCameraFlipped = !_isCameraFlipped);
            // TODO: Implement camera flip
          },
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 12),

        // Mute/Unmute
        IconButton(
          onPressed: () {
            setState(() => _isMuted = !_isMuted);
            // TODO: Implement audio mute
          },
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isMuted
                  ? Colors.red.withOpacity(0.8)
                  : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(
              _isMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftAnimation(GiftAnimationData data) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Positioned(
          right: 20 + (value * 100),
          top: 200 + (value * 100),
          child: Opacity(
            opacity: 1.0 - value,
            child: Transform.scale(
              scale: 0.5 + (value * 1.5),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.pink.shade400],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      '${data.sender?.displayName ?? "Someone"} sent ${data.gift?.name ?? "gift"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
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

// Helper class for gift animations
class GiftAnimationData {
  final VirtualGift? gift;
  final StreamUser? sender;
  final int quantity;
  final String? message;

  GiftAnimationData({
    this.gift,
    this.sender,
    this.quantity = 1,
    this.message,
  });
}
