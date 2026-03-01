/// Story 89: Streams Screen — browse live streams.
/// Navigation: Home → Feed → Live tab → StreamsScreen OR Profile → Live → Browse.
/// DESIGN: docs/DESIGN.md — TajiriAppBar, Heroicons, empty/error states, 48dp, monochrome.
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/livestream_models.dart';
import '../../services/livestream_service.dart';
import '../../widgets/cached_media_image.dart';
import '../../widgets/tajiri_app_bar.dart';
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
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(
        title: null,
        titleWidget: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _LiveTabSegments(
            controller: _tabController,
            labels: const ['Live now', 'All'],
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimaryText))
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
    );
  }

  /// DESIGN.md §10: error state — tertiary icon, bodySmall, retry with primary.
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
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
                icon: HeroIcon(
                  HeroIcons.arrowPath,
                  style: HeroIconStyle.outline,
                  size: 20,
                  color: _kPrimaryText,
                ),
                label: const Text(
                  'Jaribu tena',
                  style: TextStyle(
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

  /// DESIGN.md §10: empty state — tertiary icon, title 18/600, bodySmall, 48dp CTA.
  Widget _buildLiveStreamsList() {
    if (_liveStreams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeroIcon(
                HeroIcons.signal,
                style: HeroIconStyle.outline,
                size: 64,
                color: _kTertiaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Hakuna matangazo ya moja kwa moja',
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
                'Anza tangazo lako ili watazamaji waone moja kwa moja',
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
                  icon: HeroIcon(
                    HeroIcons.videoCamera,
                    style: HeroIconStyle.outline,
                    size: 20,
                    color: _kSurface,
                  ),
                  label: const Text(
                    'Anza Tangazo',
                    style: TextStyle(
                      color: _kSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: _kPrimaryText,
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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

  /// DESIGN.md §10: empty state for All tab.
  Widget _buildAllStreamsList() {
    if (_allStreams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeroIcon(
                HeroIcons.signal,
                style: HeroIconStyle.outline,
                size: 64,
                color: _kTertiaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Hakuna matangazo',
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
                'Matangazo yote yataonekana hapa',
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _allStreams.length,
        itemBuilder: (context, index) {
          final stream = _allStreams[index];
          return _StreamListTile(
            stream: stream,
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

/// Custom segment control: pill wraps only the label content (no TabBar indicator constraints).
class _LiveTabSegments extends StatelessWidget {
  const _LiveTabSegments({
    required this.controller,
    required this.labels,
  });

  final TabController controller;
  final List<String> labels;

  static const double _pillPaddingH = 14.0;
  static const double _pillPaddingV = 6.0;
  static const double _pillRadius = 20.0;
  static const double _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
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
      color: selected ? _kPrimaryText.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(_LiveTabSegments._pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_LiveTabSegments._pillRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _LiveTabSegments._pillPaddingH,
            vertical: _LiveTabSegments._pillPaddingV,
          ),
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

class _LiveStreamCard extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback onTap;

  const _LiveStreamCard({required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      shadowColor: const Color(0xFF000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _kDivider,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              stream.thumbnailUrl.isNotEmpty
                  ? CachedMediaImage(
                      imageUrl: stream.thumbnailUrl,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      errorWidget: Container(
                        color: _kDivider,
                        child: HeroIcon(
                          HeroIcons.signal,
                          style: HeroIconStyle.outline,
                          size: 48,
                          color: _kTertiaryText,
                        ),
                      ),
                      placeholder: Container(
                        color: _kDivider,
                        child: HeroIcon(
                          HeroIcons.signal,
                          style: HeroIconStyle.outline,
                          size: 48,
                          color: _kTertiaryText,
                        ),
                      ),
                    )
                  : Container(
                      color: _kDivider,
                      child: HeroIcon(
                        HeroIcons.signal,
                        style: HeroIconStyle.outline,
                        size: 48,
                        color: _kTertiaryText,
                      ),
                    ),
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
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimaryText,
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
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimaryText.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeroIcon(
                        HeroIcons.eye,
                        style: HeroIconStyle.outline,
                        size: 12,
                        color: _kSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(stream.viewersCount),
                        style: const TextStyle(
                          color: _kSurface,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
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
                          radius: 14,
                          backgroundColor: _kTertiaryText,
                          backgroundImage: stream.user?.avatarUrl.isNotEmpty ==
                                  true
                              ? NetworkImage(stream.user!.avatarUrl)
                              : null,
                          child: stream.user?.avatarUrl.isEmpty == true
                              ? Text(
                                  stream.user!.firstName.isNotEmpty
                                      ? stream.user!.firstName[0]
                                      : '?',
                                  style: const TextStyle(color: _kSurface),
                                )
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                            )
                          : Container(
                              color: _kDivider,
                              child: HeroIcon(
                                HeroIcons.signal,
                                style: HeroIconStyle.outline,
                                size: 32,
                                color: _kTertiaryText,
                              ),
                            ),
                    ),
                  ),
                  if (stream.isLive)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kPrimaryText,
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeroIcon(
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
                      color: stream.isLive ? _kPrimaryText : _kSecondaryText,
                      fontSize: 12,
                    ),
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
