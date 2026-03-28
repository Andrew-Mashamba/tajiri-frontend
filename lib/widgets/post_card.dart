import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/post_models.dart';
import 'user_avatar.dart';
import 'audio_player_widget.dart';
import 'cached_media_image.dart';
import 'poll_vote_widget.dart';
import '../l10n/app_strings_scope.dart';
import '../services/event_tracking_service.dart';
import '../services/engagement_level_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'thread_badge.dart';
import 'sponsored_badge.dart';
import 'adaptive_media_zone.dart';

// DESIGN.md tokens for PostCard (monochrome, §1–3, §6–7)
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const double _kCardPadding = 16.0;
const double _kGapIconText = 8.0;

/// PostCard widget optimized for smooth scrolling in feeds.
/// DESIGN.md: surface, primary/secondary/tertiary text, 16px radius, 48dp touch targets.
class PostCard extends StatefulWidget {
  /// Session-level engagement level, set by FeedScreen on load.
  /// Used to gate reaction prompts and other engagement features.
  /// Static intentionally: shared across all PostCard instances for consistent session behavior.
  static EngagementLevel sessionEngagementLevel = EngagementLevel.gentle;

  final Post post;
  final int currentUserId;
  final VoidCallback? onLike;
  final Function(ReactionType)? onReaction;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onUserTap;
  final VoidCallback? onMenuTap;
  final Function(String hashtag)? onHashtagTap;
  final Function(String username)? onMentionTap;
  /// When set, tapping the card (content/header/media) opens post detail.
  final VoidCallback? onTap;
  /// Called when user taps Subscribe button on subscribers-only content.
  final VoidCallback? onSubscribe;
  /// Called when user taps the ThreadBadge (post belongs to a thread).
  final VoidCallback? onThreadTap;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onLike,
    this.onReaction,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onUserTap,
    this.onMenuTap,
    this.onHashtagTap,
    this.onMentionTap,
    this.onTap,
    this.onSubscribe,
    this.onThreadTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _showReactionPicker = false;
  bool _captionExpanded = false;
  // PERFORMANCE: Lazy-load animation controller only when needed
  AnimationController? _reactionController;
  Animation<double>? _reactionAnimation;

  // View/dwell tracking state
  DateTime? _visibleSince;
  bool _viewTracked = false; // Intentionally single-track-per-lifecycle: reset only on widget rebuild
  Timer? _viewTrackTimer; // Cancellable replacement for Future.delayed

  // Reaction pulse prompt (flywheel: show after 3s dwell without action)
  bool _showReactionPulse = false;
  bool _hasActed = false;
  Timer? _reactionPulseTimer;

  // Session-level passive view counter (resets on app restart).
  // Static intentionally: tracks cross-instance session engagement for "been quiet" prompt.
  static int _sessionPassiveViews = 0;

  // Cached TapGestureRecognizers to avoid memory leaks
  final List<TapGestureRecognizer> _tapRecognizers = [];

  // App lifecycle tracking for accurate dwell calculation
  DateTime? _backgroundedAt;

  AnimationController get reactionController {
    if (_reactionController == null) {
      _reactionController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _reactionAnimation = CurvedAnimation(
        parent: _reactionController!,
        curve: Curves.easeOutBack,
      );
    }
    return _reactionController!;
  }

  Animation<double> get reactionAnimation {
    // Ensure controller exists
    reactionController;
    return _reactionAnimation!;
  }

  void _markActed() {
    _hasActed = true;
    _reactionPulseTimer?.cancel();
    _reactionPulseTimer = null;
    if (_showReactionPulse && mounted) {
      setState(() => _showReactionPulse = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewTrackTimer?.cancel();
    _reactionPulseTimer?.cancel();
    _reactionController?.dispose();
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    _tapRecognizers.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _backgroundedAt != null && _visibleSince != null) {
      // Subtract background time from dwell calculation
      final backgroundDuration = DateTime.now().difference(_backgroundedAt!);
      _visibleSince = _visibleSince!.add(backgroundDuration);
      _backgroundedAt = null;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction >= 0.5) {
      // Post is 50%+ visible
      _visibleSince ??= DateTime.now();
      if (!_viewTracked) {
        _viewTracked = true;
        _viewTrackTimer?.cancel();
        _viewTrackTimer = Timer(const Duration(seconds: 1), () {
          if (mounted && _visibleSince != null) {
            EventTrackingService.getInstance().then((tracker) {
              tracker.trackEvent(
                eventType: 'view',
                postId: widget.post.id,
                creatorId: widget.post.userId,
              );
            }).catchError((_) {});
          }
        });
      }
      // Start reaction pulse timer if user hasn't acted (gated by engagement level)
      if (!_hasActed && _reactionPulseTimer == null &&
          EngagementLevelService.shouldShow(
            level: PostCard.sessionEngagementLevel,
            feature: EngagementFeature.reactionPrompts,
          )) {
        _reactionPulseTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_hasActed) {
            setState(() => _showReactionPulse = true);
          }
        });
      }
    } else {
      // Post left viewport
      if (_visibleSince != null) {
        final dwellMs = DateTime.now().difference(_visibleSince!).inMilliseconds;
        if (dwellMs > 1000) {
          // Track passive view for session prompt
          if (!_hasActed) {
            _sessionPassiveViews++;
          }
          // Meaningful view — emit dwell
          EventTrackingService.getInstance().then((tracker) {
            tracker.trackEvent(
              eventType: 'dwell',
              postId: widget.post.id,
              creatorId: widget.post.userId,
              durationMs: dwellMs,
            );
          }).catchError((_) {});
        } else {
          // Quick scroll past — emit scroll_past
          EventTrackingService.getInstance().then((tracker) {
            tracker.trackEvent(
              eventType: 'scroll_past',
              postId: widget.post.id,
              creatorId: widget.post.userId,
              durationMs: dwellMs,
            );
          }).catchError((_) {});
        }
        _visibleSince = null;
      }
      // Reset pulse state
      _reactionPulseTimer?.cancel();
      _reactionPulseTimer = null;
      if (_showReactionPulse && mounted) {
        setState(() => _showReactionPulse = false);
      }
    }
  }

  void _toggleReactionPicker() {
    setState(() {
      _showReactionPicker = !_showReactionPicker;
      if (_showReactionPicker) {
        reactionController.forward();
      } else {
        reactionController.reverse();
      }
    });
  }

  void _selectReaction(ReactionType reaction) {
    _markActed();
    widget.onReaction?.call(reaction);
    setState(() {
      _showReactionPicker = false;
    });
    reactionController.reverse();
  }

  Post get post => widget.post;

  Color? _postDominantColor() {
    final firstMedia = post.media.isNotEmpty ? post.media.first : null;
    if (firstMedia?.dominantColor != null) {
      return parseDominantColor(firstMedia!.dominantColor);
    }
    return null;
  }

  TapGestureRecognizer _createTapRecognizer(VoidCallback onTap) {
    final r = TapGestureRecognizer()..onTap = onTap;
    _tapRecognizers.add(r);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    // Dispose previous recognizers before rebuilding
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    _tapRecognizers.clear();

    final cardContent = Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          _buildMediaZone(context),
          _buildActionRow(context),
          _buildLikesCount(context),
          _buildCaption(context),
          _buildViewComments(context),
          _buildCommentPreview(context),
        ],
      ),
    );
    final Widget tappableCard = widget.onTap != null
        ? GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.deferToChild,
            child: cardContent,
          )
        : cardContent;

    return VisibilityDetector(
      key: Key('post_card_${widget.post.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: tappableCard,
    );
  }

  /// Instagram-style media zone — full-bleed content area between header and actions.
  /// Dispatches to the appropriate visual treatment based on post type.
  Widget _buildMediaZone(BuildContext context) {
    Widget content;

    if (post.isColoredTextPost) {
      content = _buildColoredTextContent(context);
    } else if (post.isAudioPost) {
      content = _buildAudioPostContent(context);
    } else if (post.postType == PostType.poll && post.pollId != null) {
      content = Container(
        constraints: const BoxConstraints(minHeight: 200),
        color: const Color(0xFFFAFAFA),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: PollVoteWidget(
          pollId: post.pollId!,
          currentUserId: widget.currentUserId,
        ),
      );
    } else if (post.isShared && post.originalPost != null) {
      content = _buildSharedPost(context);
    } else if (post.hasMedia) {
      final visualMedia = post.media.where((m) => m.mediaType == MediaType.image || m.mediaType == MediaType.video).toList();
      if (visualMedia.isNotEmpty) {
        content = AdaptiveMediaZone(
          media: visualMedia,
          dominantColor: _postDominantColor(),
          onTap: widget.onTap,
          onImageTap: (images, tapped) => widget.onTap?.call(),
        );
      } else {
        // Only documents/audio — fall through to document/audio handling
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in post.media)
              if (m.mediaType == MediaType.document)
                _buildDocumentPreview(m)
              else if (m.mediaType == MediaType.audio)
                AudioPlayerWidget(audioUrl: m.fileUrl, duration: m.duration),
          ],
        );
      }
    } else if (post.content != null && post.content!.isNotEmpty) {
      // Text-only post: render as styled media card
      content = _buildTextOnlyMedia(context);
    } else {
      return const SizedBox.shrink();
    }

    // Wrap in stack for overlays (thread badge, sponsored badge, subscriber lock)
    final hasOverlays = post.threadId != null || post.isSponsored || _isContentLocked;

    if (!hasOverlays) return content;

    return Stack(
      children: [
        content,
        if (post.threadId != null)
          Positioned(
            top: 10,
            left: 10,
            child: ThreadBadge(
              threadId: post.threadId!,
              threadTitle: post.threadTitle,
              onTap: widget.onThreadTap,
            ),
          ),
        if (post.isSponsored)
          Positioned(
            top: post.threadId != null ? 44 : 10,
            left: 10,
            child: SponsoredBadge(sponsorName: post.sponsorName),
          ),
        if (_isContentLocked)
          Positioned.fill(
            child: _buildSubscriberOverlay(),
          ),
      ],
    );
  }

  /// Text-only posts get a dark gradient background with large centered text.
  Widget _buildTextOnlyMedia(BuildContext context) {
    final text = post.content!;
    final fontSize = text.length < 80 ? 24.0 : text.length < 200 ? 20.0 : 16.0;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
        ),
      ),
      child: Center(
        child: Text(
          text.length > 300 ? '${text.substring(0, 300)}...' : text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 12,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final s = AppStringsScope.of(context);
    final username = post.user?.username ?? post.user?.fullName ?? (s?.unknownUser ?? 'Unknown');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onUserTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kPrimaryText, width: 1.5),
              ),
              child: UserAvatar(
                photoUrl: post.user?.profilePhotoUrl,
                name: post.user?.fullName,
                radius: 16,
                onTap: widget.onUserTap,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.onUserTap,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _kPrimaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.isViral || post.isFeatured || post.isTrending) ...[
                    const SizedBox(width: 4),
                    HeroIcon(
                      post.isViral ? HeroIcons.fire
                          : post.isFeatured ? HeroIcons.star
                          : HeroIcons.arrowTrendingUp,
                      style: HeroIconStyle.solid,
                      size: 14,
                      color: _kPrimaryText,
                    ),
                  ],
                  Text(
                    ' · ${_formatTime(post.createdAt, s)}',
                    style: const TextStyle(
                      color: _kTertiaryText,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onMenuTap,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: HeroIcon(HeroIcons.ellipsisHorizontal, style: HeroIconStyle.outline, size: 20, color: _kPrimaryText),
            ),
          ),
        ],
      ),
    );
  }

  /// Build rich text content with clickable hashtags and @mentions
  Widget _buildRichContent(BuildContext context, String content) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(#[\w\u0621-\u064A]+)|(@[\w\u0621-\u064A]+)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(content)) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
          style: const TextStyle(fontSize: 14, color: _kPrimaryText),
        ));
      }

      // Add the hashtag or mention (DESIGN.md: monochrome, tappable)
      final matchText = match.group(0)!;
      final isHashtag = matchText.startsWith('#');

      spans.add(TextSpan(
        text: matchText,
        style: const TextStyle(
          fontSize: 14,
          color: _kPrimaryText,
          fontWeight: FontWeight.w500,
        ),
        recognizer: _createTapRecognizer(() {
            if (isHashtag) {
              widget.onHashtagTap?.call(matchText.substring(1));
            } else {
              widget.onMentionTap?.call(matchText.substring(1));
            }
          }),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
        style: const TextStyle(fontSize: 14, color: _kPrimaryText),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Colored text post as full-bleed media zone content.
  Widget _buildColoredTextContent(BuildContext context) {
    Color bgColor = _kSecondaryText;
    if (post.backgroundColor != null) {
      try {
        final colorStr = post.backgroundColor!.replaceAll('#', '');
        bgColor = Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {
        bgColor = _kSecondaryText;
      }
    }

    final textColor = bgColor.computeLuminance() > 0.5 ? _kPrimaryText : _kSurface;
    final text = post.content ?? '';
    final fontSize = text.length < 80 ? 26.0 : text.length < 200 ? 20.0 : 16.0;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            HSLColor.fromColor(bgColor).withLightness(
              (HSLColor.fromColor(bgColor).lightness - 0.12).clamp(0.0, 1.0),
            ).toColor(),
          ],
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.4,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 12,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Audio post as full-bleed media zone with dark background.
  Widget _buildAudioPostContent(BuildContext context) {
    final s = AppStringsScope.of(context);
    String? audioUrl = post.audioUrl;
    int? audioDuration = post.audioDuration;

    if (audioUrl == null || audioUrl.isEmpty) {
      final audioMedia = post.media.where((m) => m.mediaType == MediaType.audio).firstOrNull;
      if (audioMedia != null) {
        audioUrl = audioMedia.fileUrl;
        audioDuration = audioMedia.duration;
      }
    }

    if (audioUrl == null || audioUrl.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroIcon(HeroIcons.exclamationCircle, style: HeroIconStyle.outline, size: 32, color: _kTertiaryText),
              const SizedBox(height: 8),
              Text(
                s?.audioUnavailable ?? 'Audio unavailable',
                style: const TextStyle(color: _kTertiaryText, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image if available — full-bleed
          if (post.coverImagePath != null)
            AspectRatio(
              aspectRatio: 1,
              child: CachedMediaImage(
                imageUrl: post.coverImageUrl,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: const Color(0xFF1A1A1A),
                  child: HeroIcon(HeroIcons.musicalNote, style: HeroIconStyle.outline, size: 50, color: _kTertiaryText),
                ),
              ),
            )
          else
            // No cover image — show audio player centered on dark bg
            Container(
              constraints: const BoxConstraints(minHeight: 280),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: const HeroIcon(HeroIcons.play, style: HeroIconStyle.solid, size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    if (audioDuration != null)
                      Text(
                        '${(audioDuration ~/ 60).toString().padLeft(2, '0')}:${(audioDuration % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: _kTertiaryText, fontSize: 13),
                      ),
                    if (post.hasMusic && post.musicTrack != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HeroIcon(HeroIcons.musicalNote, style: HeroIconStyle.outline, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              post.musicTrack!.title,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Audio player widget
          AudioPlayerWidget(
            audioUrl: audioUrl,
            duration: audioDuration,
            title: post.postType == PostType.audioText
                ? (s?.audioAndText ?? 'Audio + Text')
                : (s?.audio ?? 'Audio'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(PostMedia media) {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _kCardPadding, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kPrimaryText.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HeroIcon(HeroIcons.document, style: HeroIconStyle.outline, size: 24, color: _kPrimaryText),
          ),
          const SizedBox(width: _kGapIconText),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  media.originalFilename ?? (s?.file ?? 'File'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: _kPrimaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (media.fileSize != null)
                  Text(
                    _formatFileSize(media.fileSize!),
                    style: const TextStyle(color: _kSecondaryText, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: HeroIcon(HeroIcons.arrowDownTray, style: HeroIconStyle.outline, size: 20, color: _kPrimaryText),
            onPressed: () async {
              try {
                final url = Uri.parse(media.fileUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } catch (_) {
                // Malformed URL or launch failure — silently ignore
              }
            },
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }


  Widget _buildSharedPost(BuildContext context) {
    final s = AppStringsScope.of(context);
    final original = post.originalPost!;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/post/${original.id}'),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: _kDivider, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                UserAvatar(
                  photoUrl: original.user?.profilePhotoUrl,
                  name: original.user?.fullName,
                  radius: 16,
                ),
                const SizedBox(width: _kGapIconText),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        original.user?.fullName ?? (s?.unknownUser ?? 'Unknown'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _kPrimaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatTime(original.createdAt, s),
                        style: const TextStyle(color: _kSecondaryText, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (original.content != null && original.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _buildRichContent(context, original.content!),
            ),
          if (original.hasMedia)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: AdaptiveMediaZone(
                media: original.media.where((m) => m.mediaType == MediaType.image || m.mediaType == MediaType.video).toList(),
                dominantColor: parseDominantColor(original.media.first.dominantColor),
                onTap: () => Navigator.pushNamed(context, '/post/${original.id}'),
              ),
            ),
        ],
      ),
    ),
    );
  }

  /// Instagram-style likes count: "42,300 likes"
  Widget _buildLikesCount(BuildContext context) {
    if (post.likesCount <= 0 && post.viewsCount <= 0) return const SizedBox.shrink();

    final s = AppStringsScope.of(context);
    final text = post.likesCount > 0
        ? (s?.likesCount(_formatCount(post.likesCount)) ?? '${_formatCount(post.likesCount)} likes')
        : (s?.viewsCount(_formatCount(post.viewsCount)) ?? '${_formatCount(post.viewsCount)} views');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: _kPrimaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

  /// Instagram-style action row: icon-only buttons (heart, comment, share, spacer, bookmark).
  Widget _buildActionRow(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reaction pulse prompt (flywheel: nudge after 3s dwell)
        if (_showReactionPulse) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
            child: Text(
              _sessionPassiveViews >= 10
                  ? (AppStringsScope.of(context)?.beenQuietToday ?? 'You\'ve been quiet today \u2014 what do you think?')
                  : (AppStringsScope.of(context)?.whatDoYouThink ?? 'What do you think?'),
              style: const TextStyle(
                fontSize: 12,
                color: _kSecondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_sessionPassiveViews >= 10)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ReactionType.values.map((r) => GestureDetector(
                  onTap: () {
                    _markActed();
                    widget.onReaction?.call(r);
                  },
                  child: Text(r.emoji, style: const TextStyle(fontSize: 22)),
                )).toList(),
              ),
            ),
        ],
        // Reaction picker (animated, shown on long-press)
        if (_showReactionPicker)
          ScaleTransition(
            scale: reactionAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ReactionType.values.map((reaction) {
                  final isSelected = post.userReaction == reaction;
                  return GestureDetector(
                    onTap: () => _selectReaction(reaction),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimaryText.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(reaction.emoji, style: TextStyle(fontSize: isSelected ? 28 : 24)),
                          Text(
                            AppStringsScope.of(context)?.reactionLabel(reaction.value) ?? reaction.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? _kPrimaryText : _kSecondaryText,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        // Icon-only action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              // Like — tap to like, long press for reaction picker
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _markActed();
                  if (_showReactionPicker) {
                    _toggleReactionPicker();
                  } else {
                    widget.onLike?.call();
                    EventTrackingService.getInstance().then((tracker) {
                      tracker.trackEvent(eventType: 'like', postId: widget.post.id, creatorId: widget.post.userId);
                    }).catchError((_) {});
                  }
                },
                onLongPress: _toggleReactionPicker,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      child: post.userReaction != null
                          ? Text(post.userReaction!.emoji, style: const TextStyle(fontSize: 24))
                          : HeroIcon(
                              HeroIcons.heart,
                              style: post.isLiked ? HeroIconStyle.solid : HeroIconStyle.outline,
                              size: 26,
                              color: _kPrimaryText,
                            ),
                    ),
                  ),
                ),
              ),
              // Comment
              IconButton(
                onPressed: () {
                  _markActed();
                  widget.onComment?.call();
                  EventTrackingService.getInstance().then((tracker) {
                    tracker.trackEvent(eventType: 'comment', postId: widget.post.id, creatorId: widget.post.userId);
                  }).catchError((_) {});
                },
                icon: const HeroIcon(HeroIcons.chatBubbleOvalLeft, style: HeroIconStyle.outline, size: 26, color: _kPrimaryText),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              // Share
              IconButton(
                onPressed: () {
                  _markActed();
                  widget.onShare?.call();
                  EventTrackingService.getInstance().then((tracker) {
                    tracker.trackEvent(eventType: 'share', postId: widget.post.id, creatorId: widget.post.userId);
                  }).catchError((_) {});
                },
                icon: const HeroIcon(HeroIcons.paperAirplane, style: HeroIconStyle.outline, size: 26, color: _kPrimaryText),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              const Spacer(),
              // Save / Bookmark
              IconButton(
                onPressed: () {
                  _markActed();
                  widget.onSave?.call();
                  EventTrackingService.getInstance().then((tracker) {
                    tracker.trackEvent(eventType: 'save', postId: widget.post.id, creatorId: widget.post.userId);
                  }).catchError((_) {});
                },
                icon: HeroIcon(
                  HeroIcons.bookmark,
                  style: post.isSaved ? HeroIconStyle.solid : HeroIconStyle.outline,
                  size: 26,
                  color: _kPrimaryText,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Instagram-style caption: bold username + content text with "...more" truncation.
  Widget _buildCaption(BuildContext context) {
    // For text-only and colored-text posts, content is shown in the media zone
    if (post.isColoredTextPost) return const SizedBox.shrink();
    if (!post.hasMedia && !post.isAudioPost && !post.isShared &&
        post.postType != PostType.poll) {
      return const SizedBox.shrink(); // text-only — already in media zone
    }

    final content = post.content;
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    final cs = AppStringsScope.of(context);
    final username = post.user?.username ?? post.user?.fullName ?? (cs?.unknownUser ?? 'Unknown');
    final isLong = content.length > 120;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isLong && !_captionExpanded
                ? () => setState(() => _captionExpanded = true)
                : null,
            child: RichText(
              maxLines: _captionExpanded ? 100 : 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$username ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _kPrimaryText,
                    ),
                    recognizer: _createTapRecognizer(() => widget.onUserTap?.call()),
                  ),
                  ..._buildCaptionSpans(content),
                ],
              ),
            ),
          ),
          if (isLong && !_captionExpanded)
            GestureDetector(
              onTap: () => setState(() => _captionExpanded = true),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  AppStringsScope.of(context)?.more ?? 'more',
                  style: const TextStyle(color: _kTertiaryText, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build inline spans for caption text with clickable hashtags and @mentions.
  List<InlineSpan> _buildCaptionSpans(String content) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(#[\w\u0621-\u064A]+)|(@[\w\u0621-\u064A]+)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
          style: const TextStyle(fontSize: 13, color: _kPrimaryText),
        ));
      }

      final matchText = match.group(0)!;
      final isHashtag = matchText.startsWith('#');
      spans.add(TextSpan(
        text: matchText,
        style: const TextStyle(fontSize: 13, color: _kPrimaryText, fontWeight: FontWeight.w500),
        recognizer: _createTapRecognizer(() {
            if (isHashtag) {
              widget.onHashtagTap?.call(matchText.substring(1));
            } else {
              widget.onMentionTap?.call(matchText.substring(1));
            }
          }),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
        style: const TextStyle(fontSize: 13, color: _kPrimaryText),
      ));
    }

    return spans;
  }

  /// "View all X comments" link.
  Widget _buildViewComments(BuildContext context) {
    if (post.commentsCount <= 0) return const SizedBox.shrink();

    final s = AppStringsScope.of(context);
    return GestureDetector(
      onTap: () {
        _markActed();
        widget.onComment?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Text(
          s?.viewAllComments(_formatCount(post.commentsCount)) ?? 'View all ${_formatCount(post.commentsCount)} comments',
          style: const TextStyle(color: _kTertiaryText, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Single comment preview (top comment if available).
  Widget _buildCommentPreview(BuildContext context) {
    if (post.topCommentText == null || post.topCommentText!.isEmpty) {
      return const SizedBox(height: 8);
    }
    final s = AppStringsScope.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '${post.topCommentAuthor ?? (s?.someone ?? 'Someone')} ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kPrimaryText,
              ),
            ),
            TextSpan(
              text: post.topCommentText!,
              style: const TextStyle(fontSize: 13, color: _kPrimaryText),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time, AppStrings? s) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return s?.justNow ?? 'Just now';
    if (diff.inMinutes < 60) return s?.minutesAgoShort(diff.inMinutes) ?? '${diff.inMinutes}m';
    if (diff.inHours < 24) return s?.hoursAgoShort(diff.inHours) ?? '${diff.inHours}h';
    if (diff.inDays < 7) return s?.daysAgoShort(diff.inDays) ?? '${diff.inDays}d';
    return s?.shortDate(time.day, time.month, time.year) ?? '${time.day}/${time.month}/${time.year}';
  }

  /// Returns true if this is subscribers-only content and current user is NOT subscribed.
  bool get _isContentLocked {
    // Own posts are never locked
    if (post.userId == widget.currentUserId) return false;
    // Only lock if privacy is subscribers and user is not subscribed
    return post.privacy == PostPrivacy.subscribers && !post.isSubscribedToAuthor;
  }

  /// Builds the subscriber-only overlay with tint and subscribe button.
  Widget _buildSubscriberOverlay() {
    final s = AppStringsScope.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s?.subscribersOnly ?? 'Subscribers Only',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s?.subscribeTo(post.user?.fullName ?? (s.thisCreator)) ?? 'Subscribe to ${post.user?.fullName ?? 'this creator'}\nto see this content',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (widget.onSubscribe != null)
              ElevatedButton.icon(
                onPressed: widget.onSubscribe,
                icon: const Icon(Icons.star, size: 20),
                label: Text(
                  s?.subscribe ?? 'Subscribe',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _kPrimaryText,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
