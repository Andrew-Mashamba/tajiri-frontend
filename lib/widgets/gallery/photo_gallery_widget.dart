import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/photo_models.dart';
import '../../services/photo_service.dart';
import '../../services/media_cache_service.dart';
import '../cached_media_image.dart';
import 'photo_viewer_screen.dart';

/// Modern Pinterest-style staggered photo gallery
/// Based on best practices from https://vibe-studio.ai/insights/building-pinterest-style-staggered-grid-layouts-in-flutter
class PhotoGalleryWidget extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;
  final String heroTagPrefix;

  const PhotoGalleryWidget({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.heroTagPrefix = 'photo',
  });

  @override
  State<PhotoGalleryWidget> createState() => _PhotoGalleryWidgetState();
}

class _PhotoGalleryWidgetState extends State<PhotoGalleryWidget>
    with AutomaticKeepAliveClientMixin {
  final PhotoService _photoService = PhotoService();
  final MediaCacheService _cacheService = MediaCacheService();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  List<Photo> _photos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  // Layout mode
  GalleryLayoutMode _layoutMode = GalleryLayoutMode.staggered;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }

    // Preload images coming into view
    _preloadVisibleImages();
  }

  void _preloadVisibleImages() {
    if (_photos.isEmpty) return;

    final scrollPosition = _scrollController.position.pixels;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Estimate visible items (rough calculation)
    final itemHeight = 200.0; // Average item height
    final startIndex =
        ((scrollPosition - 500) / itemHeight).floor().clamp(0, _photos.length - 1);
    final endIndex =
        ((scrollPosition + viewportHeight + 500) / itemHeight).ceil().clamp(0, _photos.length - 1);

    // Preload URLs
    for (var i = startIndex; i <= endIndex; i++) {
      final photo = _photos[i];
      _cacheService.preloadMedia(photo.thumbnailUrl ?? photo.fileUrl);
    }
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _photoService.getPhotos(
      userId: widget.userId,
      page: 1,
      perPage: 30,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _photos = result.photos;
          _hasMore = result.meta?.hasMore ?? false;
          _currentPage = 1;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _photoService.getPhotos(
      userId: widget.userId,
      page: _currentPage + 1,
      perPage: 30,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _photos.addAll(result.photos);
          _hasMore = result.meta?.hasMore ?? false;
          _currentPage++;
        }
      });
    }
  }

  Future<void> _uploadPhoto() async {
    debugPrint('[PhotoGalleryWidget] _uploadPhoto() called');
    debugPrint('[PhotoGalleryWidget] userId: ${widget.userId}');

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) {
      debugPrint('[PhotoGalleryWidget] User cancelled image picker');
      return;
    }

    debugPrint('[PhotoGalleryWidget] Image selected:');
    debugPrint('[PhotoGalleryWidget]   path: ${image.path}');
    debugPrint('[PhotoGalleryWidget]   name: ${image.name}');
    debugPrint('[PhotoGalleryWidget]   mimeType: ${image.mimeType}');

    final file = File(image.path);
    debugPrint('[PhotoGalleryWidget] File exists: ${file.existsSync()}');

    if (file.existsSync()) {
      final fileSize = await file.length();
      debugPrint('[PhotoGalleryWidget] File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inapakia picha...')),
      );
    }

    debugPrint('[PhotoGalleryWidget] Calling PhotoService.uploadPhoto()...');

    final result = await _photoService.uploadPhoto(
      userId: widget.userId,
      file: file,
    );

    debugPrint('[PhotoGalleryWidget] Upload result:');
    debugPrint('[PhotoGalleryWidget]   success: ${result.success}');
    debugPrint('[PhotoGalleryWidget]   message: ${result.message}');
    debugPrint('[PhotoGalleryWidget]   photo: ${result.photo?.id ?? 'null'}');

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (result.success) {
        debugPrint('[PhotoGalleryWidget] Upload SUCCESS - refreshing photos');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picha imepakiwa!')),
        );
        _loadPhotos();
      } else {
        debugPrint('[PhotoGalleryWidget] Upload FAILED: ${result.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kupakia picha')),
        );
      }
    }
  }

  void _openPhotoViewer(int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return PhotoViewerScreen(
            photos: _photos,
            initialIndex: index,
            heroTagPrefix: widget.heroTagPrefix,
            onDelete: widget.isOwnProfile ? _deletePhoto : null,
            onSave: widget.isOwnProfile ? _saveEditedPhoto : null,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _deletePhoto(Photo photo) async {
    final success = await _photoService.deletePhoto(photo.id);
    if (success && mounted) {
      setState(() {
        _photos.removeWhere((p) => p.id == photo.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Picha imefutwa')),
      );
    }
  }

  Future<void> _saveEditedPhoto(Photo originalPhoto, File editedFile) async {
    // Upload the edited file as a new photo
    final result = await _photoService.uploadPhoto(
      userId: widget.userId,
      file: editedFile,
      caption: originalPhoto.caption,
    );

    if (result.success && mounted) {
      _loadPhotos(); // Refresh to show new photo
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_photos.isEmpty) {
      return _buildEmptyWidget();
    }

    return Column(
      children: [
        // Layout toggle and actions
        _buildHeader(),
        // Photo grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPhotos,
            child: _buildPhotoGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_photos.length} picha',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          // Layout toggle
          SegmentedButton<GalleryLayoutMode>(
            segments: const [
              ButtonSegment(
                value: GalleryLayoutMode.staggered,
                icon: Icon(Icons.dashboard, size: 18),
              ),
              ButtonSegment(
                value: GalleryLayoutMode.grid,
                icon: Icon(Icons.grid_on, size: 18),
              ),
              ButtonSegment(
                value: GalleryLayoutMode.list,
                icon: Icon(Icons.view_agenda, size: 18),
              ),
            ],
            selected: {_layoutMode},
            onSelectionChanged: (modes) {
              setState(() => _layoutMode = modes.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (widget.isOwnProfile) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _uploadPhoto,
              icon: const Icon(Icons.add_photo_alternate),
              tooltip: 'Pakia Picha',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    switch (_layoutMode) {
      case GalleryLayoutMode.staggered:
        return _buildStaggeredGrid();
      case GalleryLayoutMode.grid:
        return _buildRegularGrid();
      case GalleryLayoutMode.list:
        return _buildListView();
    }
  }

  /// Pinterest-style staggered masonry grid
  Widget _buildStaggeredGrid() {
    return MasonryGridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      itemCount: _photos.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _photos.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final photo = _photos[index];
        // Calculate aspect ratio for staggered effect
        final aspectRatio = photo.aspectRatio ?? _getRandomAspectRatio(index);

        return _buildPhotoCard(photo, index, aspectRatio);
      },
    );
  }

  /// Regular square grid (Instagram-style)
  Widget _buildRegularGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _photos.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _photos.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final photo = _photos[index];
        return _buildPhotoCard(photo, index, 1.0);
      },
    );
  }

  /// Full-width list view
  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _photos.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _photos.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final photo = _photos[index];
        return _buildListCard(photo, index);
      },
    );
  }

  Widget _buildPhotoCard(Photo photo, int index, double aspectRatio) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(index),
      child: Hero(
        tag: '${widget.heroTagPrefix}_${photo.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            _layoutMode == GalleryLayoutMode.staggered ? 12 : 0,
          ),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image with loading shimmer
                CachedMediaImage(
                  imageUrl: photo.thumbnailUrl ?? photo.fileUrl,
                  fit: BoxFit.cover,
                ),
                // Gradient overlay at bottom
                if (_layoutMode == GalleryLayoutMode.staggered)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                // Stats overlay
                if (photo.likesCount > 0 || photo.commentsCount > 0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      children: [
                        if (photo.likesCount > 0) ...[
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${photo.likesCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (photo.commentsCount > 0) ...[
                          const Icon(
                            Icons.comment,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${photo.commentsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(Photo photo, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openPhotoViewer(index),
            child: Hero(
              tag: '${widget.heroTagPrefix}_${photo.id}',
              child: AspectRatio(
                aspectRatio: photo.aspectRatio ?? 4 / 3,
                child: CachedMediaImage(
                  imageUrl: photo.fileUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (photo.caption != null && photo.caption!.isNotEmpty)
                  Expanded(
                    child: Text(
                      photo.caption!,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    _formatDate(photo.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.favorite_border,
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${photo.likesCount}'),
                    const SizedBox(width: 12),
                    Icon(Icons.comment_outlined,
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${photo.commentsCount}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isOwnProfile ? 'Hujapakia picha bado' : 'Hakuna picha',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isOwnProfile
                ? 'Shiriki kumbukumbu zako na marafiki'
                : 'Mtumiaji huyu hajapakia picha',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.isOwnProfile) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _uploadPhoto,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Pakia Picha'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Imeshindwa kupakia picha',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadPhotos,
            icon: const Icon(Icons.refresh),
            label: const Text('Jaribu tena'),
          ),
        ],
      ),
    );
  }

  double _getRandomAspectRatio(int index) {
    // Create varied but consistent aspect ratios for visual interest
    final ratios = [1.0, 0.75, 1.25, 0.8, 1.0, 1.5, 0.67, 1.2];
    return ratios[index % ratios.length];
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

enum GalleryLayoutMode {
  staggered, // Pinterest-style masonry
  grid, // Instagram-style squares
  list, // Full-width cards
}
