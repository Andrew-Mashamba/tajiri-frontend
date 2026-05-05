import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/photo_models.dart';
import '../services/photo_service.dart';
import '../services/photos_cache_service.dart';
import '../widgets/inline_error_banner.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/cached_media_image.dart';
import '../../myphotos/widgets/photo_viewer_screen.dart';
import '../../widgets/motion_tokens.dart';

/// Album detail: view photos, edit and delete album (owner only).
/// Reachable: Home → Photos → Albamu → tap album.
class AlbumDetailScreen extends StatefulWidget {
  final int albumId;
  final int currentUserId;
  final VoidCallback? onAlbumUpdated;
  final VoidCallback? onAlbumDeleted;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    required this.currentUserId,
    this.onAlbumUpdated,
    this.onAlbumDeleted,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final PhotoService _photoService = PhotoService();
  PhotoAlbum? _album;
  List<Photo> _photos = [];
  bool _isLoading = true;
  String? _error;
  static const int _perPage = 20;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum({int page = 1}) async {
    if (page == 1) {
      if (mounted) setState(() => _isLoading = true);
    } else {
      if (mounted) setState(() => _loadingMore = true);
    }
    _error = null;

    final result = await _photoService.getAlbum(
      widget.albumId,
      page: page,
      perPage: _perPage,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingMore = false;
      if (result.success && result.album != null) {
        _album = result.album;
        if (page == 1) {
          _photos = result.photos;
        } else {
          _photos = [..._photos, ...result.photos];
        }
      } else {
        _error = result.message ??
            (AppStringsScope.of(context)?.noPhotos ?? 'No photos yet');
      }
    });
  }

  bool get _isOwner =>
      _album != null && _album!.userId == widget.currentUserId;

  void _openPhotoViewer(int index) {
    Navigator.push<void>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return PhotoViewerScreen(
            photos: _photos,
            initialIndex: index,
            heroTagPrefix: 'album_${widget.albumId}',
            onDelete: _isOwner
                ? (Photo photo) async {
                    HapticFeedback.mediumImpact();
                    final success = await _photoService.deletePhoto(photo.id);
                    if (success && context.mounted) {
                      _loadAlbum(page: 1);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                : null,
            onSave: null,
          );
        },
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: MotionTokens.page,
      ),
    ).then((_) {
      if (mounted) _loadAlbum(page: 1);
    });
  }

  Future<void> _editAlbum() async {
    if (_album == null) return;
    final edited = await showDialog<PhotoAlbum>(
      context: context,
      builder: (context) => _EditAlbumDialog(
        album: _album!,
        photoService: _photoService,
      ),
    );
    if (edited != null && mounted) {
      setState(() => _album = edited);
      _loadAlbum(page: 1);
      widget.onAlbumUpdated?.call();
      PhotosCacheService.instance.invalidateAlbums(widget.currentUserId);
    }
  }

  Future<void> _deleteAlbum() async {
    final s = AppStringsScope.of(context);
    if (_album == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.deleteAlbum ?? 'Delete Album'),
        content: Text(
          '${s?.deleteAlbum ?? 'Delete album'} "${_album!.name}"? ${s?.noPhotosSubtitle ?? 'Photos will remain without an album.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              s?.deleteAlbum ?? 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await _photoService.deleteAlbum(widget.albumId);
    if (!mounted) return;
    if (success) {
      PhotosCacheService.instance.invalidateAlbums(widget.currentUserId);
      widget.onAlbumDeleted?.call();
      Navigator.pop(context);
    } else {
      setState(() => _error = s?.saveFailed ?? 'Could not delete album');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          _album?.name ?? (s?.albumsTitle ?? 'Albums'),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A1A)),
              tooltip: s?.privacy ?? 'Privacy',
              color: Colors.white,
              onSelected: (value) {
                if (value == 'edit') _editAlbum();
                if (value == 'delete') _deleteAlbum();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined, size: 24),
                    title: Text(s?.editAlbum ?? 'Edit album'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline,
                        size: 24, color: Colors.red),
                    title: Text(
                      s?.deleteAlbum ?? 'Delete album',
                      style: const TextStyle(color: Colors.red),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final s = AppStringsScope.of(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF1A1A1A),
        ),
      );
    }
    if (_error != null && _photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: InlineErrorBanner(
            message: _error!,
            onRetry: () => _loadAlbum(page: 1),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _loadAlbum(page: 1);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_album?.description != null &&
                      _album!.description!.isNotEmpty)
                    Text(
                      _album!.description!,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (_album?.description != null &&
                      _album!.description!.isNotEmpty)
                    const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${_album?.photosCount ?? 0} ${s?.photosTitle ?? 'Photos'}',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF999999)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _album?.privacy.label ??
                              (s?.privacyPublic ?? 'Public'),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _photos.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s?.noPhotos ?? 'No photos yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final photo = _photos[index];
                        return _PhotoTile(
                          photo: photo,
                          onTap: () => _openPhotoViewer(index),
                        );
                      },
                      childCount: _photos.length,
                    ),
                  ),
                ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;

  const _PhotoTile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedMediaImage(
            imageUrl: photo.thumbnailUrl ?? photo.fileUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget: Container(
              color: const Color(0xFF999999).withValues(alpha: 0.3),
              child: const Icon(
                Icons.image_outlined,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditAlbumDialog extends StatefulWidget {
  final PhotoAlbum album;
  final PhotoService photoService;

  const _EditAlbumDialog({
    required this.album,
    required this.photoService,
  });

  @override
  State<_EditAlbumDialog> createState() => _EditAlbumDialogState();
}

class _EditAlbumDialogState extends State<_EditAlbumDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _privacy;
  bool _isSaving = false;
  String? _formError;
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.album.name);
    _descController =
        TextEditingController(text: widget.album.description ?? '');
    _privacy = widget.album.privacy.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = AppStringsScope.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _formError = s?.enterAlbumName ?? 'Enter album name');
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    final result = await widget.photoService.updateAlbum(
      widget.album.id,
      name: name,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      privacy: _privacy,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success && result.album != null) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, result.album);
    } else {
      setState(() => _formError = result.message ??
          (s?.saveFailed ?? 'Could not save'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(s?.editAlbum ?? 'Edit Album'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InlineErrorBanner(message: _formError!),
              ),
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              decoration: InputDecoration(
                labelText: s?.albumName ?? 'Album name',
                border: const OutlineInputBorder(),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _descFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              focusNode: _descFocus,
              decoration: InputDecoration(
                labelText: s?.descriptionOptional ?? 'Description (optional)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _privacy,
              decoration: InputDecoration(
                labelText: s?.privacy ?? 'Privacy',
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'public',
                  child: Text(s?.privacyPublic ?? 'Public'),
                ),
                DropdownMenuItem(
                  value: 'friends',
                  child: Text(s?.privacyFriends ?? 'Friends only'),
                ),
                DropdownMenuItem(
                  value: 'private',
                  child: Text(s?.privacyPrivate ?? 'Private'),
                ),
              ],
              onChanged: (value) => setState(() => _privacy = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s?.cancel ?? 'Cancel'),
        ),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(s?.save ?? 'Save'),
          ),
        ),
      ],
    );
  }
}
