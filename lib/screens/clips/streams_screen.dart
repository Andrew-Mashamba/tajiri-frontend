/// Story 89: Streams Screen — browse live streams.
/// Navigation: Home → Feed → Live tab → StreamsScreen OR Profile → Live → Browse.
/// DESIGN: docs/DESIGN.md — TajiriAppBar, Heroicons, empty/error states, 48dp, monochrome.
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../../widgets/cached_media_image.dart';
import 'streamviewer_screen.dart';
import 'golive_screen.dart';

/// Minimum touch target per DESIGN.md (48dp).
const double _kMinTouchTarget = 48.0;

/// Design tokens per DESIGN.md.
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kLiveRed = Color(0xFFE53935);

class StreamsScreen extends StatefulWidget {
  final int currentUserId;

  const StreamsScreen({super.key, required this.currentUserId});

  @override
  State<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends State<StreamsScreen>
    with SingleTickerProviderStateMixin {
  final LiveStreamService _streamService = LiveStreamService();
  late TabController _tabController;

  List<LiveStream> _liveStreams = [];
  List<LiveStream> _allStreams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _streamService.getLiveStreams(currentUserId: widget.currentUserId),
        _streamService.getStreams(currentUserId: widget.currentUserId),
      ]);

      if (!mounted) return;
      final StreamsResult liveResult = results[0];
      final StreamsResult allResult = results[1];
      setState(() {
        _liveStreams = liveResult.success ? liveResult.streams : [];
        _allStreams = allResult.success ? allResult.streams : [];
        _isLoading = false;
        _error = (!liveResult.success || !allResult.success)
            ? (liveResult.message ?? allResult.message ?? 'Imeshindwa kupakia')
            : null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _watchStream(LiveStream stream) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => StreamViewerScreen(
          stream: stream,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((_) {
      if (mounted) _loadStreams();
    });
  }

  void _goLive() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => GoLiveScreen(userId: widget.currentUserId),
      ),
    ).then((_) {
      if (mounted) _loadStreams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar header
            Container(
              color: _kSurface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _LiveTabSegments(
                    controller: _tabController,
                    labels: [
                      s?.liveNow ?? 'Live now',
                      s?.all ?? 'All',
                    ],
                  ),
                  const Spacer(),
                  // Go Live button in header
                  SizedBox(
                    height: _kMinTouchTarget,
                    child: TextButton.icon(
                      onPressed: _goLive,
                      icon: const HeroIcon(
                        HeroIcons.videoCamera,
                        style: HeroIconStyle.solid,
                        size: 18,
                        color: _kSurface,
                      ),
                      label: Text(
                        s?.startBroadcast ?? 'Start',
                        style: const TextStyle(
                          color: _kSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: _kPrimaryText,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.5, color: _kDivider),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kPrimaryText, strokeWidth: 2))
                  : _error != null
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLiveStreamsList(),
                            _buildAllStreamsList(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final s = AppStringsScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HeroIcon(
              HeroIcons.exclamationTriangle,
              style: HeroIconStyle.outline,
              size: 64,
              color: _kTertiaryText,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondaryText, fontSize: 14),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: _kMinTouchTarget,
              child: TextButton.icon(
                onPressed: _loadStreams,
                icon: const HeroIcon(
                  HeroIcons.arrowPath,
                  style: HeroIconStyle.outline,
                  size: 20,
                  color: _kPrimaryText,
                ),
                label: Text(
                  s?.retry ?? 'Retry',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStreamsList() {
    final s = AppStringsScope.of(context);
    if (_liveStreams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HeroIcon(
                HeroIcons.signal,
                style: HeroIconStyle.outline,
                size: 64,
                color: _kTertiaryText,
              ),
              const SizedBox(height: 16),
              Text(
                s?.noLiveBroadcastsMessage ?? 'No live broadcasts',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                s?.liveStreamsEmptyHint ?? 'Your followers are not live yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kSecondaryText,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: _kMinTouchTarget,
                child: TextButton.icon(
                  onPressed: _goLive,
                  icon: const HeroIcon(
                    HeroIcons.videoCamera,
                    style: HeroIconStyle.outline,
                    size: 20,
                    color: _kSurface,
                  ),
                  label: Text(
                    s?.startBroadcast ?? 'Start broadcast',
                    style: const TextStyle(
                      color: _kSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: _kPrimaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      color: _kPrimaryText,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _liveStreams.length,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: _LiveStreamCard(
              stream: _liveStreams[index],
              onTap: () => _watchStream(_liveStreams[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllStreamsList() {
    final s = AppStringsScope.of(context);
    if (_allStreams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HeroIcon(
                HeroIcons.signal,
                style: HeroIconStyle.outline,
                size: 64,
                color: _kTertiaryText,
              ),
              const SizedBox(height: 16),
              Text(
                s?.noBroadcasts ?? 'No broadcasts',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                s?.scheduleBroadcastHint ?? 'All broadcasts will appear here',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kSecondaryText,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      color: _kPrimaryText,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _allStreams.length,
        separatorBuilder: (_, __) => const Divider(height: 0.5, indent: 108, color: _kDivider),
        itemBuilder: (context, index) {
          final stream = _allStreams[index];
          return RepaintBoundary(
            child: _StreamListTile(
              stream: stream,
              onTap: () => _watchStream(stream),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ─── Tab Segments ──────────────────────────────────────────

class _LiveTabSegments extends StatelessWidget {
  const _LiveTabSegments({
    required this.controller,
    required this.labels,
  });

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _Segment(
                label: labels[i],
                selected: controller.index == i,
                onTap: () => controller.animateTo(i),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _kPrimaryText.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: _kMinTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? _kPrimaryText : _kSecondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ─── Live Stream Card (grid) ───────────────────────────────

class _LiveStreamCard extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback onTap;

  const _LiveStreamCard({required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _kPrimaryText,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail with adaptive treatment
            _buildThumbnail(),
            // Bottom gradient for text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
            // Live badge (top-left)
            if (stream.isLive)
              Positioned(
                top: 8,
                left: 8,
                child: _LiveBadge(),
              ),
            // Viewer count (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HeroIcon(
                      HeroIcons.eye,
                      style: HeroIconStyle.solid,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(stream.viewersCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // User info + title (bottom)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: _kTertiaryText,
                        backgroundImage: stream.user?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(stream.user!.avatarUrl)
                            : null,
                        child: stream.user?.avatarUrl.isEmpty == true
                            ? Text(
                                stream.user!.firstName.isNotEmpty
                                    ? stream.user!.firstName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: _kSurface, fontSize: 11),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stream.user?.displayName ?? 'Mtumiaji',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (stream.title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      stream.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (stream.thumbnailUrl.isEmpty) {
      return Container(
        color: _kPrimaryText,
        child: const Center(
          child: HeroIcon(
            HeroIcons.signal,
            style: HeroIconStyle.outline,
            size: 48,
            color: Colors.white24,
          ),
        ),
      );
    }

    return CachedMediaImage(
      imageUrl: stream.thumbnailUrl,
      fit: BoxFit.cover,
      backgroundColor: _kPrimaryText,
      placeholder: Container(
        color: _kPrimaryText,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// ─── Live Badge with pulsing dot ───────────────────────────

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kLiveRed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 0.4 + (_controller.value * 0.6),
                child: child,
              );
            },
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stream List Tile (All tab) ────────────────────────────

class _StreamListTile extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback onTap;

  const _StreamListTile({required this.stream, required this.onTap});

  String _getStatusText(LiveStream stream, AppStrings s) {
    if (stream.isLive) return s.streamStatusLive;
    if (stream.isScheduled) return s.streamStatusScheduled;
    if (stream.isEnded) return stream.durationFormatted;
    return stream.status;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Material(
      color: _kSurface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 60,
                      child: stream.thumbnailUrl.isNotEmpty
                          ? CachedMediaImage(
                              imageUrl: stream.thumbnailUrl,
                              fit: BoxFit.cover,
                              backgroundColor: _kPrimaryText,
                            )
                          : Container(
                              color: _kPrimaryText,
                              child: const Center(
                                child: HeroIcon(
                                  HeroIcons.signal,
                                  style: HeroIconStyle.outline,
                                  size: 28,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (stream.isLive)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kLiveRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          s?.streamStatusLive.toUpperCase() ?? 'LIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Title + user
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stream.title,
                      style: const TextStyle(
                        color: _kPrimaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stream.user?.displayName ?? (s?.userLabel ?? 'User'),
                      style: const TextStyle(
                        color: _kSecondaryText,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Viewers + status
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HeroIcon(
                        HeroIcons.eye,
                        style: HeroIconStyle.outline,
                        size: 14,
                        color: _kSecondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stream.viewersCount}',
                        style: const TextStyle(
                          color: _kSecondaryText,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s != null ? _getStatusText(stream, s) : stream.status,
                    style: TextStyle(
                      color: stream.isLive ? _kLiveRed : _kSecondaryText,
                      fontSize: 12,
                      fontWeight: stream.isLive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
