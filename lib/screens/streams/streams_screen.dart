import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../clips/streamviewer_screen.dart';
import '../clips/golive_screen.dart';

class StreamsScreen extends StatefulWidget {
  final int currentUserId;

  const StreamsScreen({super.key, required this.currentUserId});

  @override
  State<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends State<StreamsScreen> with SingleTickerProviderStateMixin {
  final LiveStreamService _streamService = LiveStreamService();
  late TabController _tabController;

  List<LiveStream> _liveStreams = [];
  List<LiveStream> _allStreams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoading = true);

    final results = await Future.wait<StreamsResult>([
      _streamService.getLiveStreams(currentUserId: widget.currentUserId),
      _streamService.getStreams(currentUserId: widget.currentUserId),
    ]);

    setState(() {
      _liveStreams = results[0].streams;
      _allStreams = results[1].streams;
      _isLoading = false;
    });
  }

  void _watchStream(LiveStream stream) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamViewerScreen(
          stream: stream,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((_) => _loadStreams());
  }

  void _goLive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoLiveScreen(userId: widget.currentUserId),
      ),
    ).then((_) => _loadStreams());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(s.liveBroadcastsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.live),
            Tab(text: s.allTab),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLiveStreamsList(s),
                _buildAllStreamsList(s),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'streams_fab',
        onPressed: _goLive,
        icon: const Icon(Icons.videocam),
        label: Text(s.goLive),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildLiveStreamsList(AppStrings s) {
    if (_liveStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              s.noLiveBroadcastsMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _goLive,
              icon: const Icon(Icons.videocam),
              label: Text(s.startBroadcast),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _liveStreams.length,
        itemBuilder: (context, index) {
          return _LiveStreamCard(
            stream: _liveStreams[index],
            onTap: () => _watchStream(_liveStreams[index]),
          );
        },
      ),
    );
  }

  Widget _buildAllStreamsList(AppStrings s) {
    if (_allStreams.isEmpty) {
      return Center(
        child: Text(
          s.noBroadcasts,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: ListView.builder(
        itemCount: _allStreams.length,
        itemBuilder: (context, index) {
          final stream = _allStreams[index];
          return _StreamListTile(
            stream: stream,
            strings: s,
            onTap: () => _watchStream(stream),
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
          color: Colors.grey[200],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (stream.thumbnailUrl.isNotEmpty)
              Image.network(
                stream.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.live_tv, color: Colors.white54, size: 48),
                ),
              )
            else
              Container(
                color: Colors.grey[800],
                child: const Icon(Icons.live_tv, color: Colors.white54, size: 48),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),

            // Live badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
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
                      'MOJA KWA MOJA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Viewers count
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(stream.viewersCount),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom info
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: stream.user?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(stream.user!.avatarUrl)
                            : null,
                        child: stream.user?.avatarUrl.isEmpty == true
                            ? Text(stream.user!.firstName[0])
                            : null,
                      ),
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 4),
                  Text(
                    stream.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _StreamListTile extends StatelessWidget {
  final LiveStream stream;
  final AppStrings strings;
  final VoidCallback onTap;

  const _StreamListTile({
    required this.stream,
    required this.strings,
    required this.onTap,
  });

  String _statusText(LiveStream stream, AppStrings s) {
    if (stream.isLive) return s.streamStatusLive;
    if (stream.isScheduled) return s.streamStatusScheduled;
    if (stream.isEnded) return stream.durationFormatted;
    return stream.status;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 60,
              color: Colors.grey[300],
              child: stream.thumbnailUrl.isNotEmpty
                  ? Image.network(stream.thumbnailUrl, fit: BoxFit.cover)
                  : const Icon(Icons.live_tv, color: Colors.grey),
            ),
          ),
          if (stream.isLive)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  strings.streamStatusLive.toUpperCase(),
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
      title: Text(
        stream.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        stream.user?.displayName ?? strings.userLabel,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${stream.viewersCount}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          Text(
            _statusText(stream, strings),
            style: TextStyle(
              color: stream.isLive ? Colors.red : Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
