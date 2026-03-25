import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/post_models.dart';
import 'user_avatar.dart';
import 'video_player_widget.dart';
import 'audio_player_widget.dart';
import 'cached_media_image.dart';
import 'poll_vote_widget.dart';
import '../l10n/app_strings_scope.dart';

// DESIGN.md tokens for PostCard (monochrome, §1–3, §6–7)
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kShadow = Color(0xFF000000);
const double _kCardRadius = 16.0;
const double _kCardMarginV = 6.0;
const double _kCardPadding = 16.0;
const double _kGapIconText = 8.0;

/// PostCard widget optimized for smooth scrolling in feeds.
/// DESIGN.md: surface, primary/secondary/tertiary text, 16px radius, 48dp touch targets.
class PostCard extends StatefulWidget {
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
  final VoidCallback? onVideoTap;
  /// When set, tapping the card (content/header/media) opens post detail.
  final VoidCallback? onTap;
  /// Called when user taps Subscribe button on subscribers-only content.
  final VoidCallback? onSubscribe;

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
    this.onVideoTap,
    this.onTap,
    this.onSubscribe,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool _showReactionPicker = false;
  // PERFORMANCE: Lazy-load animation controller only when needed
  AnimationController? _reactionController;
  Animation<double>? _reactionAnimation;

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

  @override
  void dispose() {
    _reactionController?.dispose();
    super.dispose();
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
    widget.onReaction?.call(reaction);
    setState(() {
      _showReactionPicker = false;
    });
    reactionController.reverse();
  }

  Post get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: const EdgeInsets.symmetric(vertical: _kCardMarginV),
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [
          BoxShadow(
            color: _kShadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.maxHeight.isFinite;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _buildHeader(context),
              if (hasBoundedHeight)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: _buildCardBody(context),
                  ),
                )
              else
                _buildCardBody(context),
              _buildStats(context),
              Divider(height: 1, color: _kDivider),
              _buildActions(context),
            ],
          );
        },
      ),
    ),
    );
    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }
    return cardContent;
  }

  /// Body content (content, media, shared). Used inside scroll when height is bounded.
  Widget _buildCardBody(BuildContext context) {
    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (post.isColoredTextPost)
          _buildColoredTextContent(context)
        else if (post.isAudioPost)
          _buildAudioPostContent(context)
        else if (post.postType == PostType.poll && post.pollId != null)
          PollVoteWidget(
            pollId: post.pollId!,
            currentUserId: widget.currentUserId,
          )
        else if (post.content != null && post.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildRichContent(context, post.content!),
          ),
        if (post.postType == PostType.poll &&
            post.content != null &&
            post.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildRichContent(context, post.content!),
          ),
        if (post.hasMedia) _buildMedia(context),
        if (post.isShared && post.originalPost != null)
          _buildSharedPost(context),
      ],
    );

    // If content is locked (subscribers-only and not subscribed), show overlay
    if (_isContentLocked) {
      return Stack(
        children: [
          // Show blurred/dimmed content underneath
          bodyContent,
          // Overlay with subscribe prompt
          Positioned.fill(
            child: _buildSubscriberOverlay(),
          ),
        ],
      );
    }

    return bodyContent;
  }

  Widget _buildHeader(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(_kCardPadding),
      child: Row(
        children: [
          UserAvatar(
            photoUrl: post.user?.profilePhotoUrl,
            name: post.user?.fullName,
            radius: 22,
            onTap: widget.onUserTap,
          ),
          const SizedBox(width: _kGapIconText),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: widget.onUserTap,
                        child: Text(
                          post.user?.fullName ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: _kPrimaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (post.isViral) ...[
                      const SizedBox(width: 6),
                      _buildBadge('Viral', HeroIcon(HeroIcons.fire, style: HeroIconStyle.solid, size: 12, color: _kPrimaryText)),
                    ],
                    if (post.isFeatured) ...[
                      const SizedBox(width: 6),
                      _buildBadge('Featured', HeroIcon(HeroIcons.star, style: HeroIconStyle.solid, size: 12, color: _kPrimaryText)),
                    ],
                    if (post.isTrending) ...[
                      const SizedBox(width: 6),
                      _buildBadge('Trending', HeroIcon(HeroIcons.arrowTrendingUp, style: HeroIconStyle.outline, size: 12, color: _kPrimaryText)),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (post.user?.username != null &&
                        post.user!.username!.isNotEmpty) ...[
                      Text(
                        '@${post.user!.username}',
                        style: const TextStyle(
                          color: _kSecondaryText,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: _kSecondaryText, fontSize: 12),
                      ),
                    ],
                    Text(
                      _formatTime(post.createdAt),
                      style: const TextStyle(
                        color: _kSecondaryText,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (post.isEdited) ...[
                      const Text(' · ', style: TextStyle(color: _kSecondaryText, fontSize: 12)),
                      Text(
                        s?.edited ?? 'Edited',
                        style: const TextStyle(
                          color: _kSecondaryText,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(width: 4),
                    HeroIcon(
                      _getPrivacyHeroIcon(post.privacy),
                      style: HeroIconStyle.outline,
                      size: 12,
                      color: _kSecondaryText,
                    ),
                    if (post.isShortVideo) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kPrimaryText.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Short',
                          style: const TextStyle(
                            color: _kPrimaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (post.locationName != null) ...[
                      const SizedBox(width: 4),
                      HeroIcon(HeroIcons.mapPin, style: HeroIconStyle.outline, size: 12, color: _kSecondaryText),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          post.locationName!,
                          style: const TextStyle(color: _kSecondaryText, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (post.userId == widget.currentUserId)
            IconButton(
              icon: HeroIcon(HeroIcons.ellipsisHorizontal, style: HeroIconStyle.outline, size: 20, color: _kPrimaryText),
              onPressed: widget.onMenuTap,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
        ],
      ),
    );
  }

  /// DESIGN.md: chip/badge — overlay 0.08, primary text, 12px radius.
  Widget _buildBadge(String label, Widget icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimaryText.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (isHashtag) {
              widget.onHashtagTap?.call(matchText.substring(1));
            } else {
              widget.onMentionTap?.call(matchText.substring(1));
            }
          },
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
    );
  }

  /// Build colored text content for text-only posts with background
  Widget _buildColoredTextContent(BuildContext context) {
    // Parse background color (fallback DESIGN.md grey if invalid)
    Color bgColor = _kSecondaryText;
    if (post.backgroundColor != null) {
      try {
        final colorStr = post.backgroundColor!.replaceAll('#', '');
        bgColor = Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {
        bgColor = _kSecondaryText;
      }
    }

    // Determine text color based on background luminance
    final textColor = bgColor.computeLuminance() > 0.5 ? _kPrimaryText : _kSurface;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            HSLColor.fromColor(bgColor).withLightness(
              (HSLColor.fromColor(bgColor).lightness - 0.1).clamp(0.0, 1.0),
            ).toColor(),
          ],
        ),
      ),
      child: Center(
        child: Text(
          post.content ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: post.content != null && post.content!.length < 100 ? 24 : 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Build audio post content with waveform visualization
  Widget _buildAudioPostContent(BuildContext context) {
    final s = AppStringsScope.of(context);
    // Try to get audio URL from multiple sources:
    // 1. Direct audioPath on the post
    // 2. Audio media item in media array
    String? audioUrl = post.audioUrl;
    int? audioDuration = post.audioDuration;

    // If no direct audio path, check media array
    if (audioUrl == null || audioUrl.isEmpty) {
      final audioMedia = post.media.where((m) => m.mediaType == MediaType.audio).firstOrNull;
      if (audioMedia != null) {
        audioUrl = audioMedia.fileUrl;
        audioDuration = audioMedia.duration;
      }
    }

    if (audioUrl == null || audioUrl.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: _kCardPadding, vertical: 8),
        padding: const EdgeInsets.all(_kCardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
        ),
        child: Row(
          children: [
            HeroIcon(HeroIcons.exclamationCircle, style: HeroIconStyle.outline, size: 20, color: _kTertiaryText),
            const SizedBox(width: _kGapIconText),
            Expanded(
              child: Text(
                s?.audioUnavailable ?? 'Audio unavailable - no audio_path',
                style: const TextStyle(color: _kSecondaryText, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _kCardPadding, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image if available
          if (post.coverImagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedMediaImage(
                  imageUrl: post.coverImageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: _kDivider,
                    child: HeroIcon(HeroIcons.musicalNote, style: HeroIconStyle.outline, size: 50, color: _kTertiaryText),
                  ),
                ),
              ),
            ),

          // Audio player - using the actual AudioPlayerWidget
          AudioPlayerWidget(
            audioUrl: audioUrl,
            duration: audioDuration,
            title: post.postType == PostType.audioText
                ? (s?.audioAndText ?? 'Audio + Text')
                : (s?.audio ?? 'Audio'),
          ),

          // Music info if present
          if (post.hasMusic && post.musicTrack != null)
            Padding(
              padding: const EdgeInsets.only(left: _kCardPadding, right: _kCardPadding, bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimaryText.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeroIcon(HeroIcons.musicalNote, style: HeroIconStyle.outline, size: 14, color: _kPrimaryText),
                    const SizedBox(width: 4),
                    Text(
                      post.musicTrack!.title,
                      style: const TextStyle(color: _kPrimaryText, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // Caption/content for audio_text type
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildRichContent(context, post.content!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    // PERFORMANCE: Wrap media in RepaintBoundary for isolation
    return RepaintBoundary(
      child: post.media.length == 1
          ? _buildSingleMedia(post.media.first)
          : _buildMediaGrid(),
    );
  }

  Widget _buildSingleMedia(PostMedia media) {
    switch (media.mediaType) {
      case MediaType.image:
        return GestureDetector(
          onTap: () {
            // TODO: Open image viewer
          },
          child: AspectRatio(
            aspectRatio: _calculateAspectRatio(media),
            child: CachedMediaImage(
              imageUrl: media.fileUrl,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: _kDivider,
                child: HeroIcon(HeroIcons.photo, style: HeroIconStyle.outline, size: 50, color: _kTertiaryText),
              ),
            ),
          ),
        );

      case MediaType.video:
        return VideoPlayerWidget(
          videoUrl: media.fileUrl,
          thumbnailUrl: media.thumbnailUrl,
          aspectRatio: _calculateAspectRatio(media),
        );

      case MediaType.audio:
        return AudioPlayerWidget(
          audioUrl: media.fileUrl,
          duration: media.duration,
        );

      case MediaType.document:
        return _buildDocumentPreview(media);
    }
  }

  double _calculateAspectRatio(PostMedia media) {
    if (media.width != null && media.height != null && media.height! > 0) {
      return media.width! / media.height!;
    }
    return 16 / 9;
  }

  Widget _buildDocumentPreview(PostMedia media) {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _kCardPadding, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kPrimaryText.withOpacity(0.08),
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
            onPressed: () {
              // TODO: Download file
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

  Widget _buildMediaGrid() {
    final mediaList = post.media.take(4).toList();
    final hasMore = post.media.length > 4;

    // If first item is video or audio, show it separately
    if (mediaList.first.mediaType == MediaType.video) {
      return Column(
        children: [
          VideoPlayerWidget(
            videoUrl: mediaList.first.fileUrl,
            thumbnailUrl: mediaList.first.thumbnailUrl,
            aspectRatio: _calculateAspectRatio(mediaList.first),
          ),
          if (mediaList.length > 1)
            _buildImageGrid(mediaList.skip(1).toList(), hasMore && mediaList.length == 4),
        ],
      );
    }

    if (mediaList.first.mediaType == MediaType.audio) {
      return Column(
        children: [
          AudioPlayerWidget(
            audioUrl: mediaList.first.fileUrl,
            duration: mediaList.first.duration,
          ),
          if (mediaList.length > 1)
            _buildImageGrid(mediaList.skip(1).toList(), hasMore && mediaList.length == 4),
        ],
      );
    }

    return _buildImageGrid(mediaList, hasMore);
  }

  Widget _buildImageGrid(List<PostMedia> mediaList, bool hasMore) {
    if (mediaList.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: mediaList.length == 1 ? 200 : 300,
      child: GridView.count(
        crossAxisCount: mediaList.length == 1 ? 1 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: List.generate(mediaList.length.clamp(0, 4), (index) {
          final media = mediaList[index];
          final isLast = index == 3 && hasMore;

          Widget child;
          if (media.mediaType == MediaType.video) {
            child = Stack(
              fit: StackFit.expand,
              children: [
                CachedMediaImage(
                  imageUrl: media.thumbnailUrl ?? media.fileUrl,
                  fit: BoxFit.cover,
                  backgroundColor: _kPrimaryText,
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: HeroIcon(HeroIcons.play, style: HeroIconStyle.solid, size: 32, color: Colors.white),
                  ),
                ),
              ],
            );
          } else {
            child = CachedMediaImage(
              imageUrl: media.thumbnailUrl ?? media.fileUrl,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: _kDivider,
                child: HeroIcon(HeroIcons.photo, style: HeroIconStyle.outline, size: 50, color: _kTertiaryText),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (isLast)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+${post.media.length - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSharedPost(BuildContext context) {
    final s = AppStringsScope.of(context);
    final original = post.originalPost!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: _kDivider),
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
                        _formatTime(original.createdAt),
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
              child: _buildSingleMedia(original.media.first),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final s = AppStringsScope.of(context);
    final hasAnyStats = post.likesCount > 0 ||
        post.commentsCount > 0 ||
        post.sharesCount > 0 ||
        post.viewsCount > 0 ||
        post.savesCount > 0;

    if (!hasAnyStats) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kCardPadding, vertical: 8),
      child: Row(
        children: [
          if (post.likesCount > 0) ...[
            if (post.userReaction != null)
              Text(post.userReaction!.emoji, style: const TextStyle(fontSize: 14))
            else
              HeroIcon(
                HeroIcons.handThumbUp,
                style: HeroIconStyle.solid,
                size: 16,
                color: post.isLiked ? _kPrimaryText : _kSecondaryText,
              ),
            const SizedBox(width: 4),
            Text(
              _formatCount(post.likesCount),
              style: const TextStyle(color: _kSecondaryText, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (post.viewsCount > 0) ...[
            if (post.likesCount > 0) const SizedBox(width: 12),
            HeroIcon(HeroIcons.eye, style: HeroIconStyle.outline, size: 14, color: _kSecondaryText),
            const SizedBox(width: 2),
            Text(
              _formatCount(post.viewsCount),
              style: const TextStyle(color: _kSecondaryText, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          if (post.savesCount > 0) ...[
            Text(
              '${s?.save ?? 'Save'} ${_formatCount(post.savesCount)}',
              style: const TextStyle(color: _kSecondaryText, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 12),
          ],
          if (post.commentsCount > 0)
            Text(
              '${s?.comments ?? 'Comments'} ${_formatCount(post.commentsCount)}',
              style: const TextStyle(color: _kSecondaryText, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (post.sharesCount > 0) ...[
            const SizedBox(width: 12),
            Text(
              '${s?.share ?? 'Share'} ${_formatCount(post.sharesCount)}',
              style: const TextStyle(color: _kSecondaryText, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
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

  Widget _buildActions(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Column(
      children: [
        // Reaction picker (animated)
        if (_showReactionPicker)
          ScaleTransition(
            scale: reactionAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        color: isSelected ? _kPrimaryText.withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reaction.emoji,
                            style: TextStyle(fontSize: isSelected ? 28 : 24),
                          ),
                          Text(
                            reaction.label,
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
        // Action buttons (touch targets min 48dp per DESIGN.md)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              // Like/Reaction button with long press for picker
              Expanded(
                child: Semantics(
                  button: true,
                  label: post.isLiked ? (s?.removeLike ?? 'Unlike') : (s?.like ?? 'Like'),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: GestureDetector(
                      onLongPress: _toggleReactionPicker,
                      behavior: HitTestBehavior.opaque,
                      child: TextButton.icon(
                        onPressed: () {
                          if (_showReactionPicker) {
                            _toggleReactionPicker();
                          } else {
                            widget.onLike?.call();
                          }
                        },
                        icon: post.userReaction != null
                            ? Text(post.userReaction!.emoji, style: const TextStyle(fontSize: 18))
                            : HeroIcon(
                                HeroIcons.handThumbUp,
                                style: post.isLiked ? HeroIconStyle.solid : HeroIconStyle.outline,
                                size: 20,
                                color: post.isLiked ? _kPrimaryText : _kSecondaryText,
                              ),
                        label: Text(
                          post.userReaction?.label ?? (s?.like ?? 'Like'),
                          style: TextStyle(
                            color: post.isLiked ? _kPrimaryText : _kSecondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Comment button
              Expanded(
                child: TextButton.icon(
                  onPressed: widget.onComment,
                  icon: HeroIcon(HeroIcons.chatBubbleLeft, style: HeroIconStyle.outline, size: 20, color: _kSecondaryText),
                  label: Text(s?.comment ?? 'Comment', style: TextStyle(color: _kSecondaryText, fontSize: 13)),
                ),
              ),
              // Share button
              Expanded(
                child: TextButton.icon(
                  onPressed: widget.onShare,
                  icon: HeroIcon(HeroIcons.share, style: HeroIconStyle.outline, size: 20, color: _kSecondaryText),
                  label: Text(s?.share ?? 'Share', style: TextStyle(color: _kSecondaryText, fontSize: 13)),
                ),
              ),
              // Save/Bookmark button (48dp touch target per DESIGN.md)
              IconButton(
                onPressed: widget.onSave,
                icon: HeroIcon(
                  HeroIcons.bookmark,
                  style: post.isSaved ? HeroIconStyle.solid : HeroIconStyle.outline,
                  size: 22,
                  color: post.isSaved ? _kPrimaryText : _kSecondaryText,
                ),
                tooltip: post.isSaved ? (s?.unsave ?? 'Unsave') : (s?.save ?? 'Save'),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Sasa hivi';
    if (diff.inMinutes < 60) return 'Dakika ${diff.inMinutes}';
    if (diff.inHours < 24) return 'Saa ${diff.inHours}';
    if (diff.inDays < 7) return 'Siku ${diff.inDays}';
    return '${time.day}/${time.month}/${time.year}';
  }

  HeroIcons _getPrivacyHeroIcon(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return HeroIcons.globeAlt;
      case PostPrivacy.friends:
        return HeroIcons.userGroup;
      case PostPrivacy.subscribers:
        return HeroIcons.star;
      case PostPrivacy.private:
        return HeroIcons.lockClosed;
    }
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
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  size: 40,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s?.subscribersOnly ?? 'Subscribers Only',
                style: TextStyle(
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
              ElevatedButton.icon(
                onPressed: widget.onSubscribe,
                icon: const Icon(Icons.star, size: 20),
                label: Text(
                  s?.subscribe ?? 'Subscribe',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
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
