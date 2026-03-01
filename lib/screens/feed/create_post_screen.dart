import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/draft_models.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../services/draft_service.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import 'create_text_post_screen.dart';
import 'create_image_post_screen.dart';
import 'create_audio_post_screen.dart';
import 'create_short_video_screen.dart';
import '../groups/createpoll_screen.dart';

/// Create Post screen - professional content creation studio
/// Features: 4 consolidated post types + drafts management + scheduling
class CreatePostScreen extends StatefulWidget {
  final int currentUserId;
  final String? userName;
  final String? userPhotoUrl;

  const CreatePostScreen({
    super.key,
    required this.currentUserId,
    this.userName,
    this.userPhotoUrl,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final DraftService _draftService = DraftService();
  List<PostDraft> _drafts = [];
  DraftCounts? _draftCounts;
  bool _isLoadingDrafts = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoadingDrafts = true);

    final results = await Future.wait([
      _draftService.getDrafts(userId: widget.currentUserId, perPage: 5),
      _draftService.getDraftCounts(),
    ]);

    if (mounted) {
      setState(() {
        _isLoadingDrafts = false;
        if (results[0].success) {
          _drafts = results[0].drafts ?? [];
        }
        if (results[1].success) {
          _draftCounts = results[1].counts;
        }
      });
    }
  }

  @override
  void dispose() {
    _draftService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: TajiriAppBar(
        title: s?.createPost ?? 'Create post',
        actions: [
          if (_draftCounts != null && _draftCounts!.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _showAllDrafts(context),
                icon: HeroIcon(
                  HeroIcons.inbox,
                  style: HeroIconStyle.outline,
                  size: 20,
                  color: TajiriAppBar.primaryTextColor,
                ),
                label: Text(
                  '${_draftCounts!.total}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDrafts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drafts section (if any)
              if (_drafts.isNotEmpty || _isLoadingDrafts)
                _buildDraftsSection(context, s),

              // Create new section header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  s?.createNew ?? 'Create new',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 4 Post Type Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PostTypeCard(
                            icon: Icons.videocam_rounded,
                            title: s?.shortVideo ?? 'Short video',
                            subtitle: s?.shortVideoSubtitle ?? 'Up to 60 seconds',
                            onTap: () => _navigateToScreen(
                              context,
                              CreateShortVideoScreen(
                                currentUserId: widget.currentUserId,
                                userName: widget.userName,
                                userPhotoUrl: widget.userPhotoUrl,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PostTypeCard(
                            icon: Icons.photo_library_rounded,
                            title: s?.photoPost ?? 'Photo',
                            subtitle: s?.sharePhotos ?? 'Share photos',
                            onTap: () => _navigateToScreen(
                              context,
                              CreateImagePostScreen(
                                currentUserId: widget.currentUserId,
                                userName: widget.userName,
                                userPhotoUrl: widget.userPhotoUrl,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PostTypeCard(
                            icon: Icons.edit_note_rounded,
                            title: s?.textPost ?? 'Text',
                            subtitle: s?.shareThoughts ?? 'Share thoughts',
                            onTap: () => _navigateToScreen(
                              context,
                              CreateTextPostScreen(
                                currentUserId: widget.currentUserId,
                                userName: widget.userName,
                                userPhotoUrl: widget.userPhotoUrl,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PostTypeCard(
                            icon: Icons.mic_rounded,
                            title: s?.audioPost ?? 'Audio',
                            subtitle: s?.voiceMessage ?? 'Voice message',
                            onTap: () => _navigateToScreen(
                              context,
                              CreateAudioPostScreen(
                                currentUserId: widget.currentUserId,
                                userName: widget.userName,
                                userPhotoUrl: widget.userPhotoUrl,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PostTypeCard(
                            icon: Icons.poll_rounded,
                            title: s?.poll ?? 'Poll',
                            subtitle: s?.createPollSubtitle ?? 'Create poll',
                            onTap: () => _navigateToScreen(
                              context,
                              CreatePollScreen(creatorId: widget.currentUserId),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),

              // Tips section
              _buildTipsSection(context, s),

              // Scheduled posts indicator
              if (_draftCounts != null && _draftCounts!.scheduled > 0)
                _buildScheduledIndicator(context, s),

              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDraftsSection(BuildContext context, AppStrings? s) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.history, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  s?.continueEditing ?? 'Continue editing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_drafts.length > 3)
                  TextButton(
                    onPressed: () => _showAllDrafts(context),
                    child: Text(s?.seeAll ?? 'See all'),
                  ),
              ],
            ),
          ),
          if (_isLoadingDrafts)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _drafts.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final draft = _drafts[index];
                  return _DraftCard(
                    draft: draft,
                    onTap: () => _openDraft(context, draft),
                    onDelete: () => _deleteDraft(draft),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context, AppStrings? s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF999999).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Icon(
                  Icons.tips_and_updates,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                s?.proTips ?? 'Pro tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            icon: Icons.schedule,
            text: s?.schedulePostsTip ?? 'Schedule posts for optimal engagement times',
          ),
          _buildTipItem(
            icon: Icons.video_collection,
            text: s?.shortVideosTip ?? 'Short videos get 3x more reach',
          ),
          _buildTipItem(
            icon: Icons.save_alt,
            text: s?.draftsAutoSaveTip ?? 'Drafts auto-save as you type',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF999999)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledIndicator(BuildContext context, AppStrings? s) {
    final count = _draftCounts!.scheduled;
    final label = count > 1 ? (s?.scheduledPosts ?? 'Scheduled posts') : (s?.scheduledPost ?? 'Scheduled post');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF999999).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showScheduledPosts(context),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.schedule_send,
                color: Color(0xFF1A1A1A),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count $label',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s?.tapToViewAndManage ?? 'Tap to view and manage',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      } else {
        // Refresh drafts in case user saved a draft
        _loadDrafts();
      }
    });
  }

  void _openDraft(BuildContext context, PostDraft draft) {
    Widget screen;

    switch (draft.postType) {
      case DraftPostType.shortVideo:
        screen = CreateShortVideoScreen(
          currentUserId: widget.currentUserId,
          userName: widget.userName,
          userPhotoUrl: widget.userPhotoUrl,
          draft: draft,
        );
        break;
      case DraftPostType.photo:
        screen = CreateImagePostScreen(
          currentUserId: widget.currentUserId,
          userName: widget.userName,
          userPhotoUrl: widget.userPhotoUrl,
          draft: draft,
        );
        break;
      case DraftPostType.audio:
        screen = CreateAudioPostScreen(
          currentUserId: widget.currentUserId,
          userName: widget.userName,
          userPhotoUrl: widget.userPhotoUrl,
          draft: draft,
        );
        break;
      case DraftPostType.text:
      default:
        screen = CreateTextPostScreen(
          currentUserId: widget.currentUserId,
          userName: widget.userName,
          userPhotoUrl: widget.userPhotoUrl,
          draft: draft,
        );
        break;
    }

    _navigateToScreen(context, screen);
  }

  Future<void> _deleteDraft(PostDraft draft) async {
    final s = AppStringsScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.deleteDraftTitle ?? 'Delete draft?'),
        content: Text(s?.deleteDraftMessage ?? 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(s?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && draft.id != null) {
      final result = await _draftService.deleteDraft(draft.id!);
      if (result.success) {
        _loadDrafts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s?.draftDeleted ?? 'Draft deleted')),
          );
        }
      }
    }
  }

  void _showAllDrafts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AllDraftsScreen(
          userId: widget.currentUserId,
          draftService: _draftService,
          onDraftSelected: (draft) => _openDraft(context, draft),
        ),
      ),
    ).then((_) => _loadDrafts());
  }

  void _showScheduledPosts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ScheduledPostsScreen(
          userId: widget.currentUserId,
          draftService: _draftService,
        ),
      ),
    ).then((_) => _loadDrafts());
  }
}

/// Post type card widget - monochrome per DOCS/DESIGN.md (icon #1A1A1A, 48dp min touch)
class _PostTypeCard extends StatelessWidget {
  static const Color _iconBg = Color(0xFF1A1A1A);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PostTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _primaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _secondaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draft card widget for horizontal list
class _DraftCard extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DraftCard({
    required this.draft,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          draft.typeIcon,
                          size: 16,
                          color: _getTypeColor(draft.postType),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          draft.postType.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getTypeColor(draft.postType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (draft.isScheduled)
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Color(0xFF666666),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        draft.displayTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      draft.lastEditedAgo,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button (min 48dp touch target per DESIGN.md)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(DraftPostType type) {
    return const Color(0xFF666666);
  }
}

/// All Drafts Screen
class _AllDraftsScreen extends StatefulWidget {
  final int userId;
  final DraftService draftService;
  final Function(PostDraft) onDraftSelected;

  const _AllDraftsScreen({
    required this.userId,
    required this.draftService,
    required this.onDraftSelected,
  });

  @override
  State<_AllDraftsScreen> createState() => _AllDraftsScreenState();
}

class _AllDraftsScreenState extends State<_AllDraftsScreen> {
  List<PostDraft> _drafts = [];
  bool _isLoading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);

    final result = await widget.draftService.getDrafts(
      userId: widget.userId,
      type: _filterType,
      perPage: 50,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _drafts = result.drafts ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.allDrafts ?? 'All drafts'),
        actions: [
          PopupMenuButton<String?>(
            onSelected: (value) {
              setState(() => _filterType = value);
              _loadDrafts();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: null, child: Text(s?.allTypes ?? 'All types')),
              PopupMenuItem(value: 'text', child: Text(s?.textPost ?? 'Text')),
              PopupMenuItem(value: 'photo', child: Text(s?.photoPost ?? 'Photo')),
              PopupMenuItem(value: 'short_video', child: Text(s?.shortVideo ?? 'Video')),
              PopupMenuItem(value: 'audio', child: Text(s?.audioPost ?? 'Audio')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.drafts_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        s?.noDrafts ?? 'No drafts yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drafts.length,
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    return _DraftListTile(
                      draft: draft,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onDraftSelected(draft);
                      },
                      onDelete: () => _deleteDraft(draft),
                    );
                  },
                ),
    );
  }

  Future<void> _deleteDraft(PostDraft draft) async {
    if (draft.id != null) {
      final result = await widget.draftService.deleteDraft(draft.id!);
      if (result.success) {
        _loadDrafts();
      }
    }
  }
}

/// Draft list tile for all drafts view
class _DraftListTile extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DraftListTile({
    required this.draft,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor(draft.postType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            draft.typeIcon,
            color: _getTypeColor(draft.postType),
          ),
        ),
        title: Text(
          draft.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(draft.postType.label),
            const Text(' • '),
            Text(draft.lastEditedAgo),
            if (draft.isScheduled) ...[
              const Text(' • '),
              const Icon(Icons.schedule, size: 14, color: Color(0xFF666666)),
            ],
          ],
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  Color _getTypeColor(DraftPostType type) {
    return const Color(0xFF666666);
  }
}

/// Scheduled Posts Screen
class _ScheduledPostsScreen extends StatefulWidget {
  final int userId;
  final DraftService draftService;

  const _ScheduledPostsScreen({
    required this.userId,
    required this.draftService,
  });

  @override
  State<_ScheduledPostsScreen> createState() => _ScheduledPostsScreenState();
}

class _ScheduledPostsScreenState extends State<_ScheduledPostsScreen> {
  List<PostDraft> _scheduledDrafts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledDrafts();
  }

  Future<void> _loadScheduledDrafts() async {
    setState(() => _isLoading = true);

    final result = await widget.draftService.getDrafts(
      userId: widget.userId,
      scheduledOnly: true,
      perPage: 50,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _scheduledDrafts = result.drafts ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.scheduledPosts ?? 'Scheduled posts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scheduledDrafts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_send, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        s?.noScheduled ?? 'No scheduled posts',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s?.schedulePostsSubtitle ?? 'Schedule posts to publish at optimal times',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scheduledDrafts.length,
                  itemBuilder: (context, index) {
                    final draft = _scheduledDrafts[index];
                    return _ScheduledPostTile(
                      draft: draft,
                      onPublishNow: () => _publishNow(draft),
                      onReschedule: () => _reschedule(draft),
                      onCancel: () => _cancelSchedule(draft),
                    );
                  },
                ),
    );
  }

  Future<void> _publishNow(PostDraft draft) async {
    if (draft.id != null) {
      final result = await widget.draftService.publishDraft(draft.id!);
      if (result.success && mounted) {
        final s = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (s?.published ?? 'Published!'))),
        );
        _loadScheduledDrafts();
      }
    }
  }

  Future<void> _reschedule(PostDraft draft) async {
    // TODO: Implement date/time picker for rescheduling
  }

  Future<void> _cancelSchedule(PostDraft draft) async {
    if (draft.id != null) {
      final result = await widget.draftService.deleteDraft(draft.id!);
      if (result.success) {
        _loadScheduledDrafts();
      }
    }
  }
}

/// Scheduled post tile
class _ScheduledPostTile extends StatelessWidget {
  final PostDraft draft;
  final VoidCallback onPublishNow;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  const _ScheduledPostTile({
    required this.draft,
    required this.onPublishNow,
    required this.onReschedule,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(draft.typeIcon, size: 20),
                const SizedBox(width: 8),
                Text(
                  draft.postType.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Color(0xFF666666)),
                      const SizedBox(width: 4),
                      Text(
                        _formatScheduledDate(draft.scheduledAt!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              draft.displayTitle,
              style: const TextStyle(fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPublishNow,
                    child: Builder(
                      builder: (ctx) => Text(AppStringsScope.of(ctx)?.publishNow ?? 'Publish now'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (ctx) {
                    final s = AppStringsScope.of(ctx);
                    return IconButton(
                      onPressed: onReschedule,
                      icon: const Icon(Icons.edit_calendar),
                      tooltip: s?.reschedule ?? 'Reschedule',
                    );
                  },
                ),
                Builder(
                  builder: (ctx) {
                    final s = AppStringsScope.of(ctx);
                    return IconButton(
                      onPressed: onCancel,
                      icon: const Icon(Icons.delete_outline, color: Color(0xFF1A1A1A)),
                      tooltip: s?.cancel ?? 'Cancel',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatScheduledDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
