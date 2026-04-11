// lib/events/pages/event_photos_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event_strings.dart';
import '../models/event_wall.dart';
import '../services/event_wall_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventPhotosPage extends StatefulWidget {
  final int eventId;

  const EventPhotosPage({super.key, required this.eventId});

  @override
  State<EventPhotosPage> createState() => _EventPhotosPageState();
}

class _EventPhotosPageState extends State<EventPhotosPage> {
  final _wallService = EventWallService();
  final _picker = ImagePicker();

  List<EventPhoto> _photos = [];
  bool _loading = true;
  bool _uploading = false;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos({bool refresh = false}) async {
    if (refresh) setState(() { _currentPage = 1; _loading = true; });
    final result = await _wallService.getEventPhotos(
      eventId: widget.eventId,
      page: _currentPage,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _lastPage = result.lastPage ?? 1;
        if (refresh || _currentPage == 1) {
          _photos = result.items ?? [];
        } else {
          _photos.addAll(result.items ?? []);
        }
        _loading = false;
        _loadingMore = false;
      });
    } else {
      setState(() { _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _uploadPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    final result = await _wallService.uploadEventPhoto(
      eventId: widget.eventId,
      filePath: picked.path,
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (result.success) {
      await _loadPhotos(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (Localizations.localeOf(context).languageCode == 'sw' ? 'Imeshindwa kupakia picha' : 'Failed to upload photo')),
          backgroundColor: _kPrimary,
        ),
      );
    }
  }

  void _openPhoto(int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _FullScreenPhoto(photos: _photos, initialIndex: index),
    ));
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollEndNotification &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        !_loadingMore && _currentPage < _lastPage) {
      setState(() { _currentPage++; _loadingMore = true; });
      _loadPhotos();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: Localizations.localeOf(context).languageCode == 'sw');
    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: RefreshIndicator(
                color: _kPrimary,
                onRefresh: () => _loadPhotos(refresh: true),
                child: _photos.isEmpty
                    ? _EmptyPhotos(label: strings.noPhotos, onUpload: _uploading ? null : _uploadPhoto)
                    : CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(4),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => GestureDetector(
                                  onTap: () => _openPhoto(i),
                                  child: _PhotoTile(photo: _photos[i]),
                                ),
                                childCount: _photos.length,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 3,
                                mainAxisSpacing: 3,
                              ),
                            ),
                          ),
                          if (_loadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(color: _kPrimary)),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
      floatingActionButton: _photos.isNotEmpty
          ? FloatingActionButton(
              onPressed: _uploading ? null : _uploadPhoto,
              backgroundColor: _kPrimary,
              child: _uploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
            )
          : null,
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final EventPhoto photo;
  const _PhotoTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        photo.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFE0E0E0),
          child: const Icon(Icons.broken_image_rounded, color: _kSecondary),
        ),
      ),
    );
  }
}

class _EmptyPhotos extends StatelessWidget {
  final String label;
  final VoidCallback? onUpload;
  const _EmptyPhotos({required this.label, this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.photo_library_outlined, size: 56, color: _kSecondary),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: _kSecondary, fontSize: 15)),
        const SizedBox(height: 16),
        if (onUpload != null)
          OutlinedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
            label: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Pakia Picha' : 'Upload Photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
      ]),
    );
  }
}

class _FullScreenPhoto extends StatefulWidget {
  final List<EventPhoto> photos;
  final int initialIndex;
  const _FullScreenPhoto({required this.photos, required this.initialIndex});

  @override
  State<_FullScreenPhoto> createState() => _FullScreenPhotoState();
}

class _FullScreenPhotoState extends State<_FullScreenPhoto> {
  late int _current;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.photos.length}',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.photos[i].url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded,
                  color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
