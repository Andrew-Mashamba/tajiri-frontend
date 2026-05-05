import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/photo_models.dart';
import '../services/photo_service.dart';
import '../services/photos_cache_service.dart';
import '../widgets/inline_error_banner.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/cached_media_image.dart';
import '../../myphotos/widgets/photo_viewer_screen.dart';
import '../../widgets/motion_tokens.dart';
import 'album_detail_screen.dart';

class PhotosScreen extends StatefulWidget {
  final int userId;
  final bool isCurrentUser;

  const PhotosScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = true,
  });

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PhotoService _photoService = PhotoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(s?.photosTitle ?? 'Photos'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (widget.isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: FilledButton.icon(
                  onPressed: _uploadPhoto,
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: Text(
                    s?.upload ?? 'Upload',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A1A1A),
          unselectedLabelColor: const Color(0xFF999999),
          indicatorColor: const Color(0xFF1A1A1A),
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: s?.photosTitle ?? 'Photos'),
            Tab(text: s?.albumsTitle ?? 'Albums'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _PhotosTab(
              userId: widget.userId,
              photoService: _photoService,
              isCurrentUser: widget.isCurrentUser,
            ),
            _AlbumsTab(
              userId: widget.userId,
              photoService: _photoService,
              isCurrentUser: widget.isCurrentUser,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    if (!mounted) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => _UploadPhotosScreen(
          files: images.map((e) => File(e.path)).toList(),
          userId: widget.userId,
          photoService: _photoService,
          onUploaded: () {
            PhotosCacheService.instance.invalidatePhotos(widget.userId);
            PhotosCacheService.instance.invalidateAlbums(widget.userId);
          },
        ),
      ),
    );
  }
}

class _PhotosTab extends StatefulWidget {
  final int userId;
  final PhotoService photoService;
  final bool isCurrentUser;

  const _PhotosTab({
    required this.userId,
    required this.photoService,
    required this.isCurrentUser,
  });

  @override
  State<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<_PhotosTab>
    with AutomaticKeepAliveClientMixin {
  List<Photo> _photos = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _hydrateAndRefresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _hydrateAndRefresh() async {
    final cache = PhotosCacheService.instance;

    final hot = cache.getPhotosSync(widget.userId);
    if (hot != null && hot.isNotEmpty) {
      setState(() {
        _photos = hot;
        _isLoading = false;
        _hasMore = true;
      });
    } else {
      final cold = await cache.getPhotosCached(widget.userId);
      if (!mounted) return;
      if (cold != null && cold.isNotEmpty) {
        setState(() {
          _photos = cold;
          _isLoading = false;
          _hasMore = true;
        });
      }
    }

    await _loadPhotos(silent: _photos.isNotEmpty);
  }

  Future<void> _loadPhotos({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    _error = null;

    final result = await widget.photoService.getPhotos(
      userId: widget.userId,
      page: _currentPage,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingMore = false;
      if (result.success) {
        if (_currentPage == 1) {
          _photos = result.photos;
        } else {
          _photos = [..._photos, ...result.photos];
        }
        _hasMore = result.photos.length >= 20;
      } else {
        _error = result.message;
      }
    });

    if (result.success) {
      PhotosCacheService.instance.savePhotos(widget.userId, _photos);
    }
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore || _isLoading) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (max > 0 && current > max * 0.7) {
      setState(() => _loadingMore = true);
      _currentPage++;
      _loadPhotos(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppStringsScope.of(context);

    if (_isLoading && _photos.isEmpty) {
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
          padding: const EdgeInsets.all(16),
          child: InlineErrorBanner(
            message: _error!,
            onRetry: () {
              _currentPage = 1;
              _loadPhotos();
            },
          ),
        ),
      );
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              s?.noPhotos ?? 'No photos yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s?.noPhotosSubtitle ?? 'Tap upload to add your first photo',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        _currentPage = 1;
        await _loadPhotos();
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photos.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _photos.length) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final photo = _photos[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _viewPhoto(index),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedMediaImage(
                        imageUrl: photo.thumbnailUrl ?? photo.fileUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: const Color(0xFF999999).withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _viewPhoto(int index) {
    Navigator.push<void>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return PhotoViewerScreen(
            photos: _photos,
            initialIndex: index,
            heroTagPrefix: 'photos_tab_${widget.userId}',
            onDelete: widget.isCurrentUser
                ? (Photo photo) async {
                    final success =
                        await widget.photoService.deletePhoto(photo.id);
                    if (success && context.mounted) {
                      setState(() {
                        _photos.removeWhere((p) => p.id == photo.id);
                      });
                      PhotosCacheService.instance.savePhotos(
                          widget.userId, _photos);
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
    );
  }
}

class _AlbumsTab extends StatefulWidget {
  final int userId;
  final PhotoService photoService;
  final bool isCurrentUser;

  const _AlbumsTab({
    required this.userId,
    required this.photoService,
    required this.isCurrentUser,
  });

  @override
  State<_AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<_AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  List<PhotoAlbum> _albums = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hydrateAndRefresh();
  }

  Future<void> _hydrateAndRefresh() async {
    final cache = PhotosCacheService.instance;

    final hot = cache.getAlbumsSync(widget.userId);
    if (hot != null && hot.isNotEmpty) {
      setState(() {
        _albums = hot;
        _isLoading = false;
      });
    } else {
      final cold = await cache.getAlbumsCached(widget.userId);
      if (!mounted) return;
      if (cold != null && cold.isNotEmpty) {
        setState(() {
          _albums = cold;
          _isLoading = false;
        });
      }
    }

    await _loadAlbums(silent: _albums.isNotEmpty);
  }

  Future<void> _loadAlbums({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    _error = null;

    final result = await widget.photoService.getAlbums(widget.userId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _albums = result.albums;
      } else {
        _error = result.message;
      }
    });

    if (result.success) {
      PhotosCacheService.instance.saveAlbums(widget.userId, _albums);
    }
  }

  void _createAlbum() {
    showDialog(
      context: context,
      builder: (context) => _CreateAlbumDialog(
        userId: widget.userId,
        photoService: widget.photoService,
        onCreated: (album) {
          setState(() {
            _albums.insert(0, album);
          });
          PhotosCacheService.instance.saveAlbums(widget.userId, _albums);
        },
      ),
    );
  }

  void _openAlbum(PhotoAlbum album) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AlbumDetailScreen(
          albumId: album.id,
          currentUserId: widget.userId,
          onAlbumUpdated: () => _loadAlbums(),
          onAlbumDeleted: () => _loadAlbums(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppStringsScope.of(context);

    if (_isLoading && _albums.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF1A1A1A),
        ),
      );
    }

    if (_error != null && _albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InlineErrorBanner(
            message: _error!,
            onRetry: _loadAlbums,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _loadAlbums();
      },
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (widget.isCurrentUser) ...[
              _CreateAlbumButton(onPressed: _createAlbum),
              const SizedBox(height: 16),
            ],
            if (_albums.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.photo_album_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        s?.noAlbums ?? 'No albums yet',
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
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _albums.length,
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  return _AlbumCard(
                    album: album,
                    onTap: () => _openAlbum(album),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateAlbumButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateAlbumButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    s?.createNewAlbum ?? 'Create New Album',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final PhotoAlbum album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF999999).withValues(alpha: 0.2),
                ),
                child: album.coverPhotoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedMediaImage(
                          imageUrl: album.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: const Center(
                            child: Icon(
                              Icons.photo_album,
                              size: 40,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.photo_album,
                          size: 40,
                          color: Color(0xFF666666),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${album.photosCount} ${AppStringsScope.of(context)?.photosTitle ?? 'Photos'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadPhotosScreen extends StatefulWidget {
  final List<File> files;
  final int userId;
  final PhotoService photoService;
  final VoidCallback onUploaded;

  const _UploadPhotosScreen({
    required this.files,
    required this.userId,
    required this.photoService,
    required this.onUploaded,
  });

  @override
  State<_UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends State<_UploadPhotosScreen> {
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  List<File> _files = [];
  List<PhotoAlbum> _albums = [];
  bool _albumsLoading = true;
  String? _albumsError;
  int? _selectedAlbumId;
  bool _createNewAlbum = false;
  final _newAlbumNameController = TextEditingController();
  final _newAlbumDescController = TextEditingController();
  String _newAlbumPrivacy = 'public';
  final _captionController = TextEditingController();
  bool _isUploading = false;
  int _uploadedCount = 0;
  String? _uploadError;
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
    _loadAlbums();
  }

  @override
  void dispose() {
    _newAlbumNameController.dispose();
    _newAlbumDescController.dispose();
    _captionController.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _files.isNotEmpty && !_isUploading && _uploadedCount == 0;

  Future<void> _loadAlbums() async {
    setState(() {
      _albumsLoading = true;
      _albumsError = null;
    });
    final result = await widget.photoService.getAlbums(widget.userId);
    if (mounted) {
      setState(() {
        _albumsLoading = false;
        if (result.success) {
          _albums = result.albums;
        } else {
          _albumsError = result.message;
        }
      });
    }
  }

  Future<void> _upload() async {
    final s = AppStringsScope.of(context);
    int? albumId = _selectedAlbumId;
    if (_createNewAlbum) {
      final name = _newAlbumNameController.text.trim();
      if (name.isEmpty) {
        setState(() => _uploadError = s?.enterAlbumName ?? 'Enter album name');
        return;
      }
      setState(() => _isUploading = true);
      final createResult = await widget.photoService.createAlbum(
        userId: widget.userId,
        name: name,
        description: _newAlbumDescController.text.trim().isEmpty
            ? null
            : _newAlbumDescController.text.trim(),
        privacy: _newAlbumPrivacy,
      );
      if (!mounted) return;
      if (!createResult.success || createResult.album == null) {
        setState(() {
          _isUploading = false;
          _uploadError = createResult.message ??
              (s?.saveFailed ?? 'Could not create album');
        });
        return;
      }
      albumId = createResult.album!.id;
    } else {
      setState(() => _isUploading = true);
    }

    final caption = _captionController.text.trim().isEmpty
        ? null
        : _captionController.text.trim();
    _uploadError = null;
    _uploadedCount = 0;

    for (var i = 0; i < _files.length; i++) {
      if (!mounted) return;
      setState(() => _uploadedCount = i);
      final result = await widget.photoService.uploadPhoto(
        userId: widget.userId,
        file: _files[i],
        albumId: albumId,
        caption: caption,
      );
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _uploadError = result.message ??
              (s?.saveFailed ?? 'Could not upload');
          _isUploading = false;
        });
        HapticFeedback.vibrate();
        return;
      }
    }

    if (mounted) {
      HapticFeedback.mediumImpact();
      setState(() => _isUploading = false);
      widget.onUploaded();
      Navigator.pop(context);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
      if (_files.isEmpty) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(s?.discardUploadBody ??
                'Your photos have not been uploaded. Leave anyway?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s?.keepEditing ?? 'Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  s?.discard ?? 'Discard',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (discard == true && mounted) Navigator.pop(context);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: _primaryText,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Text(
              s?.uploadPhotos ?? 'Upload Photos',
              style: const TextStyle(color: _primaryText),
            ),
            leading: IconButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              tooltip: s?.back ?? 'Back',
            ),
          ),
          body: SafeArea(
            child: _files.isEmpty
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${_files.length} ${s?.photosSelected ?? 'Photos selected'}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _files[index],
                                        width: 100,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Material(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(24),
                                        child: InkWell(
                                          onTap: () => _removeFile(index),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          child: const SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: Icon(Icons.close,
                                                color: Colors.white,
                                                size: 24),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          s?.album ?? 'Album',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_albumsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_albumsError != null)
                          InlineErrorBanner(
                            message: _albumsError!,
                            onRetry: _loadAlbums,
                          )
                        else ...[
                          Container(
                            width: double.infinity,
                            constraints:
                                const BoxConstraints(minHeight: 48),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: _createNewAlbum
                                    ? -1
                                    : _selectedAlbumId,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                hint: Text(s?.chooseAlbumOptional ??
                                    'Choose album (optional)'),
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                        s?.noAlbum ?? 'No album'),
                                  ),
                                  ..._albums.map(
                                    (a) => DropdownMenuItem<int?>(
                                      value: a.id,
                                      child: Text(a.name,
                                          overflow:
                                              TextOverflow.ellipsis),
                                    ),
                                  ),
                                  DropdownMenuItem<int?>(
                                    value: -1,
                                    child: Text(
                                        s?.createNewAlbumShort ??
                                            '+ Create new album'),
                                  ),
                                ],
                                onChanged: _isUploading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          if (value == -1) {
                                            _createNewAlbum = true;
                                            _selectedAlbumId = null;
                                          } else {
                                            _createNewAlbum = false;
                                            _selectedAlbumId = value;
                                          }
                                        });
                                      },
                              ),
                            ),
                          ),
                          if (_createNewAlbum) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _newAlbumNameController,
                              focusNode: _nameFocus,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _descFocus.requestFocus(),
                              decoration: InputDecoration(
                                labelText: s?.albumName ?? 'Album name',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 1,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newAlbumDescController,
                              focusNode: _descFocus,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => FocusScope.of(context)
                                  .nextFocus(),
                              decoration: InputDecoration(
                                labelText: s?.descriptionOptional ??
                                    'Description (optional)',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _newAlbumPrivacy,
                              decoration: InputDecoration(
                                labelText: s?.privacy ?? 'Privacy',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'public',
                                  child: Text(
                                      s?.privacyPublic ?? 'Public'),
                                ),
                                DropdownMenuItem(
                                  value: 'friends',
                                  child: Text(
                                      s?.privacyFriends ?? 'Friends only'),
                                ),
                                DropdownMenuItem(
                                  value: 'private',
                                  child: Text(
                                      s?.privacyPrivate ?? 'Private'),
                                ),
                              ],
                              onChanged: (v) => setState(
                                  () => _newAlbumPrivacy = v ?? 'public'),
                            ),
                          ],
                        ],
                        const SizedBox(height: 24),
                        Text(
                          s?.descriptionOptional ?? 'Description (optional)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _captionController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _upload(),
                          decoration: InputDecoration(
                            hintText: s?.captionHint ??
                                'Caption for all photos',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 2,
                          maxLength: 500,
                        ),
                        if (_uploadError != null) ...[
                          const SizedBox(height: 8),
                          InlineErrorBanner(message: _uploadError!),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 72,
                          child: FilledButton(
                            onPressed: _isUploading ? null : _upload,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isUploading
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${s?.uploading ?? 'Uploading'} ${_uploadedCount + 1} ${s?.of ?? 'of'} ${_files.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      ),
                                    ],
                                  )
                                : Text(
                                    s?.upload ?? 'Upload',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CreateAlbumDialog extends StatefulWidget {
  final int userId;
  final PhotoService photoService;
  final Function(PhotoAlbum) onCreated;

  const _CreateAlbumDialog({
    required this.userId,
    required this.photoService,
    required this.onCreated,
  });

  @override
  State<_CreateAlbumDialog> createState() => _CreateAlbumDialogState();
}

class _CreateAlbumDialogState extends State<_CreateAlbumDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _privacy = 'public';
  bool _isCreating = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final s = AppStringsScope.of(context);
    if (_nameController.text.isEmpty) {
      setState(() => _formError = s?.enterAlbumName ?? 'Enter album name');
      return;
    }

    setState(() {
      _isCreating = true;
      _formError = null;
    });

    final result = await widget.photoService.createAlbum(
      userId: widget.userId,
      name: _nameController.text,
      description: _descController.text.isNotEmpty ? _descController.text : null,
      privacy: _privacy,
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (result.success && result.album != null) {
      HapticFeedback.mediumImpact();
      widget.onCreated(result.album!);
      Navigator.pop(context);
    } else {
      setState(() => _formError = result.message ??
          (s?.saveFailed ?? 'Could not create'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(s?.createAlbum ?? 'Create Album'),
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
              decoration: InputDecoration(
                labelText: s?.albumName ?? 'Album name',
                border: const OutlineInputBorder(),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: s?.descriptionOptional ?? 'Description (optional)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(),
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
              onChanged: (v) => setState(() => _privacy = v!),
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
            onPressed: _isCreating ? null : _create,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
            ),
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(s?.createAlbum ?? 'Create'),
          ),
        ),
      ],
    );
  }
}
