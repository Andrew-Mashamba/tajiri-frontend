import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/photo_models.dart';
import '../../services/photo_service.dart';
import '../../widgets/cached_media_image.dart';
import '../../widgets/gallery/photo_viewer_screen.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Picha'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Picha'),
            Tab(text: 'Albamu'),
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
      floatingActionButton: widget.isCurrentUser
          ? FloatingActionButton(
              heroTag: 'photos_fab',
              onPressed: _uploadPhoto,
              child: const Icon(Icons.add_a_photo),
            )
          : null,
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
            setState(() {});
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

class _PhotosTabState extends State<_PhotosTab> {
  List<Photo> _photos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);

    final result = await widget.photoService.getPhotos(userId: widget.userId);

    setState(() {
      _isLoading = false;
      if (result.success) {
        _photos = result.photos;
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(onPressed: _loadPhotos, child: const Text('Jaribu tena')),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Hakuna picha'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPhotos,
      child: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
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
                          color: const Color(0xFF999999).withOpacity(0.2),
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
            heroTagPrefix: 'photos_tab',
            onDelete: widget.isCurrentUser
                ? (Photo photo) async {
                    final success =
                        await widget.photoService.deletePhoto(photo.id);
                    if (success && context.mounted) {
                      setState(() {
                        _photos.removeWhere((p) => p.id == photo.id);
                      });
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

class _AlbumsTabState extends State<_AlbumsTab> {
  List<PhotoAlbum> _albums = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);

    final result = await widget.photoService.getAlbums(widget.userId);

    setState(() {
      _isLoading = false;
      if (result.success) {
        _albums = result.albums;
      } else {
        _error = result.message;
      }
    });
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(onPressed: _loadAlbums, child: const Text('Jaribu tena')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlbums,
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
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Hakuna albamu',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
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

/// Create album button per DESIGN.md: min height 72–80, white bg, 48dp touch target.
class _CreateAlbumButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateAlbumButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
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
                const Expanded(
                  child: Text(
                    'Unda Albamu Mpya',
                    style: TextStyle(
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
                  color: const Color(0xFF999999).withOpacity(0.2),
                ),
                child: album.coverPhotoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          album.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Center(
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
              'Picha ${album.photosCount}',
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

/// Full-screen upload flow: multi-select photos, assign to album or create new.
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
    super.dispose();
  }

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
    int? albumId = _selectedAlbumId;
    if (_createNewAlbum) {
      final name = _newAlbumNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingiza jina la albamu')),
        );
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
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(createResult.message ?? 'Imeshindwa kuunda albamu')),
        );
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
          _uploadError = result.message;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kupakia')),
        );
        return;
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
      widget.onUploaded();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picha ${_files.length} zimepakiwa')),
      );
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryText,
        elevation: 2,
        title: const Text('Pakia Picha', style: TextStyle(color: _primaryText)),
        leading: IconButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Rudi',
        ),
      ),
      body: SafeArea(
        child: _files.isEmpty
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Picha ${_files.length} zimechaguliwa',
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
                                    borderRadius: BorderRadius.circular(24),
                                    child: InkWell(
                                      onTap: () => _removeFile(index),
                                      borderRadius: BorderRadius.circular(24),
                                      child: const SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Icon(Icons.close, color: Colors.white, size: 24),
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
                    const Text(
                      'Albamu',
                      style: TextStyle(
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_albumsError!, style: const TextStyle(color: _secondaryText)),
                      )
                    else ...[
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _createNewAlbum ? -1 : _selectedAlbumId,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            hint: const Text('Chagua albamu (hiari)'),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Hakuna albamu')),
                              ..._albums.map(
                                (a) => DropdownMenuItem<int?>(
                                  value: a.id,
                                  child: Text(a.name, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const DropdownMenuItem<int?>(
                                value: -1,
                                child: Text('+ Unda albamu mpya'),
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
                          decoration: const InputDecoration(
                            labelText: 'Jina la albamu',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 1,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newAlbumDescController,
                          decoration: const InputDecoration(
                            labelText: 'Maelezo (hiari)',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _newAlbumPrivacy,
                          decoration: const InputDecoration(
                            labelText: 'Faragha',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'public', child: Text('Hadharani')),
                            DropdownMenuItem(value: 'friends', child: Text('Marafiki tu')),
                            DropdownMenuItem(value: 'private', child: Text('Binafsi')),
                          ],
                          onChanged: (v) => setState(() => _newAlbumPrivacy = v ?? 'public'),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Maelezo (hiari)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionController,
                      decoration: const InputDecoration(
                        hintText: 'Caption kwa picha zote',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 2,
                      maxLength: 500,
                    ),
                    if (_uploadError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _uploadError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 72,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        child: InkWell(
                          onTap: _isUploading ? null : _upload,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isUploading
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Inapakia ${_uploadedCount + 1}/${_files.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Pakia',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryText,
                                    ),
                                  ),
                          ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isCreating = true);

    final result = await widget.photoService.createAlbum(
      userId: widget.userId,
      name: _nameController.text,
      description: _descController.text.isNotEmpty ? _descController.text : null,
      privacy: _privacy,
    );

    if (mounted) {
      if (result.success && result.album != null) {
        widget.onCreated(result.album!);
        Navigator.pop(context);
      } else {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kuunda')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unda Albamu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Jina la Albamu',
              border: OutlineInputBorder(),
            ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ghairi'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _create,
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unda'),
        ),
      ],
    );
  }
}

