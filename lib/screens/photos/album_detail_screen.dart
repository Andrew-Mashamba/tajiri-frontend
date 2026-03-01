import 'package:flutter/material.dart';
import '../../models/photo_models.dart';
import '../../services/photo_service.dart';
import '../../widgets/cached_media_image.dart';
import '../../widgets/gallery/photo_viewer_screen.dart';

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
        _error = result.message ?? 'Imeshindwa kupakia albamu';
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
                    final success =
                        await _photoService.deletePhoto(photo.id);
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
        transitionDuration: const Duration(milliseconds: 300),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Albamu imesasishwa')),
      );
    }
  }

  Future<void> _deleteAlbum() async {
    if (_album == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Albamu'),
        content: Text(
          'Una uhakika unataka kufuta albamu "${_album!.name}"? Picha zote zitaachwa bila albamu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await _photoService.deleteAlbum(widget.albumId);
    if (!mounted) return;
    if (success) {
      widget.onAlbumDeleted?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Albamu imefutwa')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kufuta albamu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          _album?.name ?? 'Albamu',
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
              color: Colors.white,
              onSelected: (value) {
                if (value == 'edit') _editAlbum();
                if (value == 'delete') _deleteAlbum();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined, size: 24),
                    title: Text('Hariri albamu'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, size: 24, color: Colors.red),
                    title: Text('Futa albamu', style: TextStyle(color: Colors.red)),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _loadAlbum(page: 1),
                  child: const Text('Jaribu tena'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAlbum(page: 1),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        'Picha ${_album?.photosCount ?? 0}',
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
                          color: const Color(0xFF999999).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _album?.privacy.label ?? 'Wote',
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
              ? const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Color(0xFF999999),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Hakuna picha bado',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
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
              color: const Color(0xFF999999).withOpacity(0.3),
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.album.name);
    _descController = TextEditingController(text: widget.album.description ?? '');
    _privacy = widget.album.privacy.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jina la albamu linahitajika')),
      );
      return;
    }

    setState(() => _isSaving = true);

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
      Navigator.pop(context, result.album);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kusasisha')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Hariri Albamu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Jina la Albamu',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Maelezo (hiari)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _privacy,
              decoration: const InputDecoration(
                labelText: 'Faragha',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Hadharani')),
                DropdownMenuItem(value: 'friends', child: Text('Marafiki tu')),
                DropdownMenuItem(value: 'private', child: Text('Binafsi')),
              ],
              onChanged: (value) => setState(() => _privacy = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ghairi'),
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Hifadhi'),
          ),
        ),
      ],
    );
  }
}
