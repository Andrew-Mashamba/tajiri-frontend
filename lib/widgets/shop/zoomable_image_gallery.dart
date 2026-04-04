import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../../config/api_config.dart';

/// Swipeable image gallery with dot indicators and tap-to-zoom full-screen viewer.
///
/// Tapping any image opens [_FullScreenViewer] with pinch-to-zoom via
/// [InteractiveViewer]. Pass raw storage paths — [ApiConfig.sanitizeUrl] is
/// applied internally.
class ZoomableImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final double height;

  const ZoomableImageGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.height = 360,
  });

  @override
  State<ZoomableImageGallery> createState() => _ZoomableImageGalleryState();
}

class _ZoomableImageGalleryState extends State<ZoomableImageGallery> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullScreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenViewer(
          imageUrls: widget.imageUrls,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Color(0xFFE0E0E0),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final url = ApiConfig.sanitizeUrl(widget.imageUrls[index]);
              return GestureDetector(
                onTap: () => _openFullScreen(index),
                child: CachedMediaImage(imageUrl: url, fit: BoxFit.contain),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) {
                final isActive = i == _currentIndex;
                return Container(
                  width: isActive ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

/// Full-screen pinch-to-zoom viewer shown when user taps a gallery image.
class _FullScreenViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: widget.imageUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final url = ApiConfig.sanitizeUrl(widget.imageUrls[index]);
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: CachedMediaImage(imageUrl: url, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
