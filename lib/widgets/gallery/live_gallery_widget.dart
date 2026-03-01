import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../../services/local_storage_service.dart';
import '../../screens/clips/golive_screen.dart';
import '../../screens/streams/backstage_screen.dart';
import '../../screens/streams/live_broadcast_screen_advanced.dart';
import '../cached_media_image.dart';

/// Creator-focused Live streaming gallery for profile page
/// Features for streamers/creators:
/// - Go Live / Schedule stream buttons
/// - Past broadcasts with analytics
/// - Stream recordings management
/// - Earnings from gifts
/// - Stream settings (edit, delete, toggle recording)
class LiveGalleryWidget extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onGoLive;

  const LiveGalleryWidget({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onGoLive,
  });

  @override
  State<LiveGalleryWidget> createState() => _LiveGalleryWidgetState();
}

class _LiveGalleryWidgetState extends State<LiveGalleryWidget>
    with SingleTickerProviderStateMixin {
  final LiveStreamService _streamService = LiveStreamService();
  late TabController _tabController;

  List<LiveStream> _allStreams = [];
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;

  // Filtered lists
  List<LiveStream> get _liveNow =>
      _allStreams.where((s) => s.isLive).toList();
  List<LiveStream> get _scheduled =>
      _allStreams.where((s) => s.isScheduled).toList();
  List<LiveStream> get _pastStreams =>
      _allStreams.where((s) => s.isEnded).toList();
  List<LiveStream> get _recordings =>
      _pastStreams.where((s) => s.recordingPath != null).toList();

  // Stats
  int get _totalViews => _allStreams.fold(0, (sum, s) => sum + s.totalViewers);
  double get _totalEarnings => _allStreams.fold(0.0, (sum, s) => sum + s.giftsValue);
  int get _totalGifts => _allStreams.fold(0, (sum, s) => sum + s.giftsCount);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
    _loadStreams();
  }

  Future<void> _loadCurrentUser() async {
    print('[LiveGallery] Loading current user from local storage...');
    try {
      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      print('[LiveGallery] User from storage: ${user != null ? "found" : "null"}');
      if (user != null) {
        print('[LiveGallery] User details - userId: ${user.userId}, firstName: ${user.firstName}');
      }

      if (mounted && user?.userId != null) {
        setState(() {
          _currentUserId = user!.userId;
        });
        print('[LiveGallery] Set _currentUserId to: $_currentUserId');
      } else {
        print('[LiveGallery] WARNING: User not found in storage or userId is null');
        print('[LiveGallery] Will use widget.userId as fallback: ${widget.userId}');
      }
    } catch (e) {
      print('[LiveGallery] ERROR loading current user: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStreams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _streamService.getUserStreams(widget.userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _allStreams = result.streams;
        } else {
          _error = result.message;
        }
      });
    }
  }

  void _navigateToGoLive() {
    print('[LiveGallery] _navigateToGoLive called');
    print('[LiveGallery] widget.onGoLive != null: ${widget.onGoLive != null}');
    print('[LiveGallery] _currentUserId: $_currentUserId');
    print('[LiveGallery] widget.userId: ${widget.userId}');

    if (widget.onGoLive != null) {
      print('[LiveGallery] Calling widget.onGoLive callback');
      widget.onGoLive!();
    } else if (_currentUserId != null) {
      print('[LiveGallery] Navigating to GoLiveScreen with userId: $_currentUserId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GoLiveScreen(userId: _currentUserId!),
        ),
      ).then((_) {
        print('[LiveGallery] Returned from GoLiveScreen, reloading streams');
        _loadStreams();
      }).catchError((error) {
        print('[LiveGallery] ERROR navigating to GoLiveScreen: $error');
      });
    } else {
      print('[LiveGallery] ERROR: Cannot navigate - _currentUserId is null!');
      print('[LiveGallery] Falling back to widget.userId: ${widget.userId}');

      // Fallback: use widget.userId if _currentUserId is null
      if (widget.userId > 0) {
        print('[LiveGallery] Using fallback userId: ${widget.userId}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoLiveScreen(userId: widget.userId),
          ),
        ).then((_) {
          print('[LiveGallery] Returned from GoLiveScreen (fallback), reloading streams');
          _loadStreams();
        }).catchError((error) {
          print('[LiveGallery] ERROR navigating to GoLiveScreen (fallback): $error');
        });
      } else {
        print('[LiveGallery] CRITICAL ERROR: Both _currentUserId and widget.userId are invalid!');
        final s = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s?.liveUserInfoUnavailable ?? 'Error: User info unavailable'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final useScroll = constraints.maxHeight < 250;
        if (useScroll) {
          final contentHeight = (constraints.maxHeight - 150).clamp(200.0, 600.0);
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isOwnProfile || _allStreams.isNotEmpty) _buildHeader(s),
                if (widget.isOwnProfile && _allStreams.isNotEmpty) _buildStatsSummary(s),
                if (_liveNow.isNotEmpty) _buildLiveNowBanner(s),
                _buildTabBar(s),
                SizedBox(height: contentHeight, child: _buildContent(s)),
              ],
            ),
          );
        }
        return Column(
          children: [
            if (widget.isOwnProfile || _allStreams.isNotEmpty) _buildHeader(s),
            if (widget.isOwnProfile && _allStreams.isNotEmpty) _buildStatsSummary(s),
            if (_liveNow.isNotEmpty) _buildLiveNowBanner(s),
            _buildTabBar(s),
            Expanded(child: _buildContent(s)),
          ],
        );
      },
    );
  }

  /// Header matches Me → Photos/Posts/Video/Music: Container(12,8), Row(count, Spacer(), action).
  Widget _buildHeader(AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_allStreams.length} ${s.liveBroadcasts}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (widget.isOwnProfile)
            IconButton(
              onPressed: _navigateToGoLive,
              icon: const Icon(Icons.videocam, size: 22),
              iconSize: 22,
              tooltip: s.startBroadcastingTooltip,
            ),
        ],
      ),
    );
  }

  /// Stats row per DESIGN.md §13.4.3: spaceEvenly, divider between items.
  Widget _buildStatsSummary(AppStrings s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(value: _allStreams.length.toString(), label: s.liveBroadcasts),
          _buildStatDivider(),
          _buildStatItem(value: _formatNumber(_totalViews), label: s.viewers),
          _buildStatDivider(),
          _buildStatItem(value: _formatNumber(_totalGifts), label: s.liveGifts),
          _buildStatDivider(),
          _buildStatItem(
            value: 'TSh ${_formatNumber(_totalEarnings.toInt())}',
            label: s.liveEarnings,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNowBanner(AppStrings s) {
    final liveStream = _liveNow.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.live_tv, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.youAreLiveNow.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${liveStream.title} • ${_formatNumber(liveStream.viewersCount)} ${s.viewers}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: () => _showStreamDashboard(liveStream),
          child: Text(s.manage),
        ),
      ),
    );
  }

  Widget _buildTabBar(AppStrings s) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.allTab),
                if (_pastStreams.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _buildBadge(_pastStreams.length),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.scheduledTab),
                if (_scheduled.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _buildBadge(_scheduled.length),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.recordingsTab),
                if (_recordings.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _buildBadge(_recordings.length),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildContent(AppStrings s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state per DESIGN.md §13.4.10
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loadStreams,
                  child: Text(s.retry),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // All past broadcasts
        _pastStreams.isEmpty
            ? _buildEmptyState(s)
            : _buildStreamsList(_pastStreams, s),
        // Scheduled
        _scheduled.isEmpty
            ? _buildEmptyState(
                s,
                icon: Icons.schedule,
                title: s.noScheduledBroadcasts,
                message: s.scheduleBroadcastHint,
                actionLabel: s.scheduleBroadcast,
                onAction: _navigateToGoLive,
              )
            : _buildScheduledList(_scheduled, s),
        // Recordings
        _recordings.isEmpty
            ? _buildEmptyState(
                s,
                icon: Icons.video_library,
                title: s.noRecordings,
                message: s.recordingsHint,
              )
            : _buildStreamsList(_recordings, s, isRecordings: true),
      ],
    );
  }

  /// Empty state per DESIGN.md §13.4.10: icon 64, title 18 w600, message 14, 48dp button.
  Widget _buildEmptyState(
    AppStrings s, {
    IconData icon = Icons.live_tv_outlined,
    String? title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final effectiveTitle = title ?? s.noBroadcasts;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              effectiveTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.isOwnProfile) ...[
              const SizedBox(height: 24),
              if (actionLabel != null && onAction != null)
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.schedule),
                    label: Text(actionLabel),
                  ),
                )
              else
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToGoLive,
                    icon: const Icon(Icons.videocam),
                    label: Text(s.startFirstBroadcast),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreamsList(List<LiveStream> streams, AppStrings s, {bool isRecordings = false}) {
    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: streams.length,
        itemBuilder: (context, index) {
          return _buildStreamCard(streams[index], s, isRecording: isRecordings);
        },
      ),
    );
  }

  Widget _buildStreamCard(LiveStream stream, AppStrings s, {bool isRecording = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showStreamDetails(stream),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with overlay
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail
                  if (stream.thumbnailPath != null && stream.thumbnailPath!.isNotEmpty)
                    CachedMediaImage(
                      imageUrl: stream.thumbnailPath,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: Colors.grey.shade300,
                      child: Icon(Icons.live_tv, size: 48, color: Colors.grey.shade500),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),

                  // Duration badge
                  if (stream.duration != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stream.durationFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // Recording badge
                  if (isRecording)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_outline, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              s.recordingBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Stats overlay
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildOverlayStat(Icons.visibility, _formatNumber(stream.totalViewers)),
                        const SizedBox(width: 12),
                        _buildOverlayStat(Icons.favorite, _formatNumber(stream.likesCount)),
                        const SizedBox(width: 12),
                        _buildOverlayStat(Icons.chat_bubble, _formatNumber(stream.commentsCount)),
                        if (stream.giftsValue > 0) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TSh ${_formatNumber(stream.giftsValue.toInt())}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stream.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (stream.category != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stream.category!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _formatDate(stream.startedAt ?? stream.createdAt, s),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // More options
                  if (widget.isOwnProfile)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      onSelected: (value) => _handleStreamAction(stream, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'analytics',
                          child: Row(
                            children: [
                              const Icon(Icons.analytics),
                              const SizedBox(width: 12),
                              Text(s.analytics),
                            ],
                          ),
                        ),
                        if (stream.recordingPath != null)
                          PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                const Icon(Icons.download),
                                const SizedBox(width: 12),
                                Text(s.download),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit),
                              const SizedBox(width: 12),
                              Text(s.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(s.delete, style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledList(List<LiveStream> streams, AppStrings s) {
    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: streams.length,
        itemBuilder: (context, index) {
          return _buildScheduledCard(streams[index], s);
        },
      ),
    );
  }

  Widget _buildScheduledCard(LiveStream stream, AppStrings s) {
    final isUpcoming = stream.scheduledAt != null &&
        stream.scheduledAt!.isAfter(DateTime.now());
    final timeUntil = stream.scheduledAt != null
        ? stream.scheduledAt!.difference(DateTime.now())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 60,
                    child: stream.thumbnailPath != null && stream.thumbnailPath!.isNotEmpty
                        ? CachedMediaImage(
                            imageUrl: stream.thumbnailPath!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.live_tv, color: Colors.grey.shade400),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stream.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (stream.scheduledAt != null)
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              _formatScheduledDate(stream.scheduledAt!, s),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Countdown or action buttons
            if (isUpcoming && timeUntil != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      s.timeRemaining(_formatTimeUntil(timeUntil, s)),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editScheduledStream(stream),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(s.edit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startScheduledStream(stream),
                    icon: const Icon(Icons.videocam, size: 18),
                    label: Text(s.startLive),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStreamDetails(LiveStream stream) {
    final s = AppStringsScope.of(context);
    if (s == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: stream.thumbnailPath != null && stream.thumbnailPath!.isNotEmpty
                            ? CachedMediaImage(
                                imageUrl: stream.thumbnailPath!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.live_tv, size: 48, color: Colors.grey.shade400),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      stream.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (stream.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        stream.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Analytics
                    Text(
                      s.analytics,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildAnalyticsGrid(stream, s),

                    const SizedBox(height: 24),

                    // Actions
                    if (widget.isOwnProfile) ...[
                      if (stream.recordingPath != null)
                        ListTile(
                          leading: const Icon(Icons.download),
                          title: Text(s.downloadRecording),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context);
                            _downloadRecording(stream);
                          },
                        ),
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: Text(s.share),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          _shareStream(stream);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: Text(s.deleteBroadcast, style: const TextStyle(color: Colors.red)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.red),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeleteStream(stream);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid(LiveStream stream, AppStrings s) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildAnalyticsTile(
          icon: Icons.visibility,
          value: _formatNumber(stream.totalViewers),
          label: s.totalViewers,
          color: Colors.blue,
        ),
        _buildAnalyticsTile(
          icon: Icons.trending_up,
          value: _formatNumber(stream.peakViewers),
          label: s.peakViewers,
          color: Colors.green,
        ),
        _buildAnalyticsTile(
          icon: Icons.favorite,
          value: _formatNumber(stream.likesCount),
          label: s.likes,
          color: Colors.red,
        ),
        _buildAnalyticsTile(
          icon: Icons.chat_bubble,
          value: _formatNumber(stream.commentsCount),
          label: s.comments,
          color: Colors.orange,
        ),
        _buildAnalyticsTile(
          icon: Icons.card_giftcard,
          value: _formatNumber(stream.giftsCount),
          label: s.liveGifts,
          color: Colors.purple,
        ),
        _buildAnalyticsTile(
          icon: Icons.account_balance_wallet,
          value: 'TSh ${_formatNumber(stream.giftsValue.toInt())}',
          label: s.liveEarnings,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildAnalyticsTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStreamDashboard(LiveStream stream) {
    final s = AppStringsScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s?.liveDashboardComingSoon ?? 'Coming soon')),
    );
  }

  void _handleStreamAction(LiveStream stream, String action) {
    switch (action) {
      case 'analytics':
        _showStreamDetails(stream);
        break;
      case 'download':
        _downloadRecording(stream);
        break;
      case 'edit':
        _editStream(stream);
        break;
      case 'delete':
        _confirmDeleteStream(stream);
        break;
    }
  }

  void _editStream(LiveStream stream) {
    final s = AppStringsScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s?.liveEditComingSoon ?? 'Coming soon')),
    );
  }

  void _editScheduledStream(LiveStream stream) {
    final s = AppStringsScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s?.liveEditComingSoon ?? 'Coming soon')),
    );
  }

  Future<void> _startScheduledStream(LiveStream stream) async {
    print('[LiveGallery] _startScheduledStream called for stream: ${stream.id}');
    // Navigate to backstage screen for final preparations
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (backstageContext) => BackstageScreen(
          stream: stream,
          onGoLive: () async {
            // This callback is called when user clicks "Enda Live" from backstage
            print('[LiveGallery] User clicked Enda Live from backstage - starting stream ${stream.id}');

            // Call startStream API
            final startResult = await _streamService.startStream(stream.id);

            if (startResult.success && startResult.stream != null) {
              print('[LiveGallery] Stream started successfully! Status: ${startResult.stream!.status}');

              // Navigate to advanced live broadcast screen
              if (backstageContext.mounted) {
                Navigator.pushReplacement(
                  backstageContext,
                  MaterialPageRoute(
                    builder: (_) => LiveBroadcastScreenAdvanced(
                      stream: startResult.stream!,
                      currentUserId: _currentUserId ?? widget.userId,
                    ),
                  ),
                );
              }
            } else {
              print('[LiveGallery] Failed to start stream: ${startResult.message}');
              if (backstageContext.mounted) {
                final s = AppStringsScope.of(backstageContext);
                ScaffoldMessenger.of(backstageContext).showSnackBar(
                  SnackBar(
                    content: Text(s?.failedToStartStream(startResult.message) ?? 'Failed to start'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onCancel: () {
            // User cancelled from backstage
            Navigator.pop(context);
          },
        ),
      ),
    ).then((_) {
      // Refresh streams when returning from backstage
      print('[LiveGallery] Returned from BackstageScreen, reloading streams');
      _loadStreams();
    });
  }

  void _downloadRecording(LiveStream stream) {
    final s = AppStringsScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s?.liveDownloadComingSoon ?? 'Coming soon')),
    );
  }

  void _shareStream(LiveStream stream) {
    final s = AppStringsScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s?.liveShareComingSoon ?? 'Coming soon')),
    );
  }

  Future<void> _confirmDeleteStream(LiveStream stream) async {
    final s = AppStringsScope.of(context);
    if (s == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteBroadcast),
        content: Text(
          s.deleteBroadcastConfirmMessage(stream.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(s.yesDelete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Call delete API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.broadcastDeleted)),
      );
      _loadStreams();
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date, AppStrings s) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return s.today;
    } else if (diff.inDays == 1) {
      return s.yesterday;
    } else if (diff.inDays < 7) {
      return s.daysAgo(diff.inDays);
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatScheduledDate(DateTime date, AppStrings s) {
    final now = DateTime.now();
    final diff = date.difference(now);

    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff.inDays == 0) {
      return '${s.today}, $time';
    } else if (diff.inDays == 1) {
      return '${s.tomorrow}, $time';
    }
    return '${date.day}/${date.month}, $time';
  }

  String _formatTimeUntil(Duration duration, AppStrings s) {
    if (duration.inDays > 0) {
      return s.formatTimeUntilDaysHours(duration.inDays, duration.inHours % 24);
    } else if (duration.inHours > 0) {
      return s.formatTimeUntilHoursMins(duration.inHours, duration.inMinutes % 60);
    } else if (duration.inMinutes > 0) {
      return s.formatTimeUntilMins(duration.inMinutes);
    }
    return s.underAMinute;
  }
}
