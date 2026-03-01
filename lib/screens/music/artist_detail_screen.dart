import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/music_models.dart';
import '../../services/music_service.dart';
import '../../widgets/cached_media_image.dart';
import 'music_player_sheet.dart';

/// Spotify-style Artist Detail Screen
/// Features:
/// - Parallax header with artist image
/// - Blurred background
/// - Popular tracks
/// - Albums/Singles sections
/// - Follow button
/// - Shuffle play
class ArtistDetailScreen extends StatefulWidget {
  final MusicArtistModel artist;
  final int currentUserId;
  final Function(MusicTrack)? onTrackSelected;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
    required this.currentUserId,
    this.onTrackSelected,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final MusicService _musicService = MusicService();
  final ScrollController _scrollController = ScrollController();

  List<MusicTrack> _tracks = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadArtistTracks();
    _isFollowing = widget.artist.isFollowing ?? false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadArtistTracks() async {
    // Load tracks by this artist
    final result = await _musicService.searchTracks(
      widget.artist.name,
      currentUserId: widget.currentUserId,
    );

    if (mounted) {
      setState(() {
        _tracks = result.tracks;
        _isLoading = false;
      });
    }
  }

  void _playTrack(MusicTrack track) {
    if (widget.onTrackSelected != null) {
      widget.onTrackSelected!(track);
      Navigator.pop(context);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MusicPlayerSheet(
          track: track,
          currentUserId: widget.currentUserId,
        ),
      );
    }
  }

  void _shufflePlay() {
    if (_tracks.isNotEmpty) {
      final shuffled = List<MusicTrack>.from(_tracks)..shuffle();
      _playTrack(shuffled.first);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowing = !_isFollowing);
    // TODO: Call API to follow/unfollow artist
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing
            ? 'Unafuata ${widget.artist.name}'
            : 'Umekoma kumfuata ${widget.artist.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = screenWidth * 0.8;
    final collapseOffset = headerHeight - 100;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background blur
          if (widget.artist.photoUrl != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight + 100,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                  child: CachedMediaImage(
                    imageUrl: widget.artist.photoUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),

          // Gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight + 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: headerHeight,
                pinned: true,
                backgroundColor: _scrollOffset > collapseOffset
                    ? const Color(0xFF282828)
                    : Colors.transparent,
                elevation: _scrollOffset > collapseOffset ? 4 : 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: _scrollOffset > collapseOffset - 50
                      ? Text(
                          widget.artist.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Artist image (cached for offline viewing)
                      if (widget.artist.photoUrl != null)
                        CachedMediaImage(
                          imageUrl: widget.artist.photoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      else
                        Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),

                      // Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),

                      // Artist name at bottom
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.artist.isVerified == true)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Msanii Aliyethibitishwa',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Text(
                              widget.artist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatNumber(widget.artist.monthlyListeners ?? 0)} wasikilizaji kwa mwezi',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Follow button
                      OutlinedButton(
                        onPressed: _toggleFollow,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                        ),
                        child: Text(_isFollowing ? 'Unafuata' : 'Fuata'),
                      ),
                      const Spacer(),
                      // Shuffle button
                      IconButton(
                        onPressed: _shufflePlay,
                        icon: const Icon(Icons.shuffle, color: Colors.grey),
                      ),
                      // Play button
                      GestureDetector(
                        onTap: _shufflePlay,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Popular Tracks Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Maarufu',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Tracks List
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _tracks.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.music_off,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hakuna nyimbo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final track = _tracks[index];
                              return _ArtistTrackTile(
                                track: track,
                                index: index + 1,
                                onTap: () => _playTrack(track),
                              );
                            },
                            childCount: _tracks.length.clamp(0, 10),
                          ),
                        ),

                // See More Button
              if (_tracks.length > 10)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: () {
                        // Show all tracks
                      },
                      child: const Text(
                        'Tazama zote',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),

              // About Section
              SliverToBoxAdapter(
                child: _buildAboutSection(),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kuhusu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.artist.bio != null && widget.artist.bio!.isNotEmpty) ...[
            Text(
              widget.artist.bio!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _buildStat(
                '${_formatNumber(widget.artist.monthlyListeners ?? 0)}',
                'Wasikilizaji/Mwezi',
              ),
              const SizedBox(width: 24),
              _buildStat(
                '${_formatNumber(widget.artist.followersCount)}',
                'Wafuasi',
              ),
              const SizedBox(width: 24),
              _buildStat(
                '${widget.artist.tracksCount ?? 0}',
                'Nyimbo',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
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
}

class _ArtistTrackTile extends StatelessWidget {
  final MusicTrack track;
  final int index;
  final VoidCallback onTap;

  const _ArtistTrackTile({
    required this.track,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 48,
              height: 48,
              child: track.coverUrl.isNotEmpty
                  ? CachedMediaImage(
                      imageUrl: track.coverUrl,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.grey),
                    ),
            ),
          ),
        ],
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          if (track.isTrending) ...[
            const Icon(Icons.local_fire_department,
                size: 12, color: Colors.orange),
            const SizedBox(width: 4),
          ],
          Text(
            '${_formatPlayCount(track.playCount ?? 0)} sikilizi',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            track.durationFormatted,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}K';
    }
    return count.toString();
  }
}
