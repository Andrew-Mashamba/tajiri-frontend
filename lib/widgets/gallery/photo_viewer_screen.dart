import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/photo_models.dart';
import '../cached_media_image.dart';
import 'image_filters.dart';

/// Modern fullscreen photo viewer with gestures and filters
/// Inspired by Instagram and Pinterest viewers
class PhotoViewerScreen extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final String heroTagPrefix;
  final Function(Photo photo)? onDelete;
  final Function(Photo photo, File editedFile)? onSave;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.heroTagPrefix = 'photo',
    this.onDelete,
    this.onSave,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;

  bool _showControls = true;
  bool _isEditing = false;
  ImageFilterPreset _selectedFilter = ImageFilters.normal;

  // Adjustment values
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _warmth = 0.0;

  // For saving edited images
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset adjustments when exiting edit mode
        _resetAdjustments();
      }
    });
  }

  void _resetAdjustments() {
    setState(() {
      _selectedFilter = ImageFilters.normal;
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _warmth = 0.0;
    });
  }

  List<double>? _getCurrentColorMatrix() {
    final matrices = <List<double>>[];

    // Add filter matrix
    if (_selectedFilter.matrix != null) {
      matrices.add(_selectedFilter.matrix!);
    }

    // Add adjustment matrices
    if (_brightness != 0.0) {
      matrices.add(ImageAdjustments.brightness(_brightness));
    }
    if (_contrast != 1.0) {
      matrices.add(ImageAdjustments.contrast(_contrast));
    }
    if (_saturation != 1.0) {
      matrices.add(ImageAdjustments.saturation(_saturation));
    }
    if (_warmth != 0.0) {
      matrices.add(ImageAdjustments.warmth(_warmth));
    }

    if (matrices.isEmpty) return null;
    if (matrices.length == 1) return matrices[0];
    return ImageAdjustments.combine(matrices);
  }

  Future<void> _saveEditedPhoto() async {
    final photo = widget.photos[_currentIndex];

    try {
      // Show saving indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inahifadhi picha...')),
      );

      // Capture the rendered image
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picha imehifadhiwa!')),
        );
        widget.onSave?.call(photo, file);
        _toggleEditing();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa kuhifadhi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photo viewer
          GestureDetector(
            onTap: _toggleControls,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  if (_isEditing) _resetAdjustments();
                });
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return _buildPhotoPage(photo, index);
              },
            ),
          ),

          // Top controls
          if (_showControls && !_isEditing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

          // Bottom controls
          if (_showControls && !_isEditing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),

          // Edit mode controls
          if (_isEditing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildEditControls(),
            ),

          // Edit mode top bar
          if (_isEditing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildEditTopBar(),
            ),

          // Page indicator
          if (widget.photos.length > 1 && _showControls && !_isEditing)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoPage(Photo photo, int index) {
    final colorMatrix = _getCurrentColorMatrix();

    Widget imageWidget = RepaintBoundary(
      key: index == _currentIndex ? _repaintKey : null,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Hero(
            tag: '${widget.heroTagPrefix}_${photo.id}',
            child: colorMatrix != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.matrix(colorMatrix),
                    child: CachedMediaImage(
                      imageUrl: photo.fileUrl,
                      fit: BoxFit.contain,
                    ),
                  )
                : CachedMediaImage(
                    imageUrl: photo.fileUrl,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );

    return imageWidget;
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 8,
        bottom: 16,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Spacer(),
          if (widget.photos[_currentIndex].caption?.isNotEmpty == true)
            Expanded(
              child: Text(
                widget.photos[_currentIndex].caption!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey.shade900,
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _toggleEditing();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
                case 'share':
                  // TODO: Implement share
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Hariri', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Shiriki', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Futa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final photo = widget.photos[_currentIndex];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.favorite_border, 'Penda', () {}),
              _buildActionButton(Icons.comment_outlined, 'Toa Maoni', () {}),
              _buildActionButton(Icons.edit_outlined, 'Hariri', _toggleEditing),
              _buildActionButton(Icons.share_outlined, 'Shiriki', () {}),
            ],
          ),
          // Photo info
          ...[
            const SizedBox(height: 12),
            Text(
              _formatDate(photo.createdAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.photos.length.clamp(0, 10),
        (index) {
          final isActive = index == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 8 : 6,
            height: isActive ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditTopBar() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              _resetAdjustments();
              _toggleEditing();
            },
            child: const Text(
              'Ghairi',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const Spacer(),
          const Text(
            'Hariri Picha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _saveEditedPhoto,
            child: const Text(
              'Hifadhi',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditControls() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Adjustment sliders
          _buildAdjustmentSliders(),
          const Divider(color: Colors.grey, height: 1),
          // Filter presets
          _buildFilterPresets(),
        ],
      ),
    );
  }

  Widget _buildAdjustmentSliders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSlider(
            'Mwangaza',
            Icons.brightness_6,
            _brightness,
            -1.0,
            1.0,
            (v) => setState(() => _brightness = v),
          ),
          _buildSlider(
            'Tofauti',
            Icons.contrast,
            _contrast,
            0.5,
            1.5,
            (v) => setState(() => _contrast = v),
          ),
          _buildSlider(
            'Rangi',
            Icons.palette,
            _saturation,
            0.0,
            2.0,
            (v) => setState(() => _saturation = v),
          ),
          _buildSlider(
            'Joto',
            Icons.thermostat,
            _warmth,
            -1.0,
            1.0,
            (v) => setState(() => _warmth = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            // Reset to default
            if (label == 'Mwangaza') {
              onChanged(0.0);
            } else if (label == 'Tofauti') {
              onChanged(1.0);
            } else if (label == 'Rangi') {
              onChanged(1.0);
            } else if (label == 'Joto') {
              onChanged(0.0);
            }
          },
          child: const Icon(Icons.refresh, color: Colors.white38, size: 18),
        ),
      ],
    );
  }

  Widget _buildFilterPresets() {
    final photo = widget.photos[_currentIndex];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: ImageFilters.presets.length,
        itemBuilder: (context, index) {
          final filter = ImageFilters.presets[index];
          final isSelected = filter.name == _selectedFilter.name;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: filter.apply(
                        CachedMediaImage(
                          imageUrl: photo.thumbnailUrl ?? photo.fileUrl,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Futa Picha', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Una uhakika unataka kufuta picha hii?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call(widget.photos[_currentIndex]);
              if (widget.photos.length == 1) {
                Navigator.pop(context);
              }
            },
            child: const Text('Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Machi',
      'Aprili',
      'Mei',
      'Juni',
      'Julai',
      'Agosti',
      'Septemba',
      'Oktoba',
      'Novemba',
      'Desemba'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
