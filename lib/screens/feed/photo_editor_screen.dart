import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Professional photo editor with Instagram/Snapchat-style tools
/// Features: Filters, Adjustments, Crop/Rotate, Text, Stickers, Draw
class PhotoEditorScreen extends StatefulWidget {
  final File imageFile;
  final String? initialFilter;

  const PhotoEditorScreen({
    super.key,
    required this.imageFile,
    this.initialFilter,
  });

  /// Navigate to editor and return edited file (or null if cancelled)
  static Future<PhotoEditResult?> edit(BuildContext context, File imageFile, {String? initialFilter}) async {
    return Navigator.push<PhotoEditResult>(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoEditorScreen(
          imageFile: imageFile,
          initialFilter: initialFilter,
        ),
      ),
    );
  }

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _imageKey = GlobalKey();

  // Current editing state
  String _selectedFilter = 'normal';
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _warmth = 0.0;
  double _sharpness = 0.0;
  double _vignette = 0.0;
  double _highlights = 0.0;
  double _shadows = 0.0;
  double _fade = 0.0;
  double _grain = 0.0;

  // Crop/Rotate state
  double _rotation = 0.0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;
  String _aspectRatio = 'free';

  // Text overlays
  List<TextOverlay> _textOverlays = [];
  int? _selectedTextIndex;

  // Sticker overlays
  List<StickerOverlay> _stickerOverlays = [];
  int? _selectedStickerIndex;

  // Drawing
  List<DrawingPath> _drawingPaths = [];
  Color _drawingColor = Colors.white;
  double _drawingStrokeWidth = 5.0;
  bool _isDrawing = false;
  List<Offset> _currentPath = [];

  // Undo stack
  final List<EditorState> _undoStack = [];
  bool _isSaving = false;

  static const List<Map<String, dynamic>> _filters = [
    {'name': 'normal', 'label': 'Normal'},
    {'name': 'vivid', 'label': 'Vivid'},
    {'name': 'warm', 'label': 'Warm'},
    {'name': 'cool', 'label': 'Cool'},
    {'name': 'black_white', 'label': 'B&W'},
    {'name': 'vintage', 'label': 'Vintage'},
    {'name': 'fade', 'label': 'Fade'},
    {'name': 'chrome', 'label': 'Chrome'},
    {'name': 'dramatic', 'label': 'Drama'},
    {'name': 'mono', 'label': 'Mono'},
    {'name': 'silvertone', 'label': 'Silver'},
    {'name': 'noir', 'label': 'Noir'},
    {'name': 'clarendon', 'label': 'Claren'},
    {'name': 'gingham', 'label': 'Gingham'},
    {'name': 'moon', 'label': 'Moon'},
    {'name': 'lark', 'label': 'Lark'},
  ];

  static const List<String> _emojis = [
    '😀', '😍', '🥰', '😎', '🤩', '😂', '🥳', '🔥', '❤️', '💕',
    '✨', '🌟', '💫', '⭐', '🎉', '🎊', '💯', '👑', '💎', '🦋',
    '🌈', '☀️', '🌙', '🌸', '🌺', '🍀', '🎵', '🎶', '📸', '💋',
    '👍', '👏', '🙌', '💪', '✌️', '🤟', '🤘', '👋', '🎁', '🏆',
  ];

  static const List<String> _aspectRatios = ['free', '1:1', '4:5', '16:9', '9:16', '4:3', '3:4'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    if (widget.initialFilter != null) {
      _selectedFilter = widget.initialFilter!;
    }
    _saveState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveState() {
    _undoStack.add(EditorState(
      filter: _selectedFilter,
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      warmth: _warmth,
      sharpness: _sharpness,
      vignette: _vignette,
      highlights: _highlights,
      shadows: _shadows,
      fade: _fade,
      grain: _grain,
      rotation: _rotation,
      flipHorizontal: _flipHorizontal,
      flipVertical: _flipVertical,
      textOverlays: List.from(_textOverlays),
      stickerOverlays: List.from(_stickerOverlays),
      drawingPaths: List.from(_drawingPaths),
    ));
  }

  void _undo() {
    if (_undoStack.length > 1) {
      _undoStack.removeLast();
      final state = _undoStack.last;
      setState(() {
        _selectedFilter = state.filter;
        _brightness = state.brightness;
        _contrast = state.contrast;
        _saturation = state.saturation;
        _warmth = state.warmth;
        _sharpness = state.sharpness;
        _vignette = state.vignette;
        _highlights = state.highlights;
        _shadows = state.shadows;
        _fade = state.fade;
        _grain = state.grain;
        _rotation = state.rotation;
        _flipHorizontal = state.flipHorizontal;
        _flipVertical = state.flipVertical;
        _textOverlays = List.from(state.textOverlays);
        _stickerOverlays = List.from(state.stickerOverlays);
        _drawingPaths = List.from(state.drawingPaths);
      });
    }
  }

  void _resetAll() {
    setState(() {
      _selectedFilter = 'normal';
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _warmth = 0.0;
      _sharpness = 0.0;
      _vignette = 0.0;
      _highlights = 0.0;
      _shadows = 0.0;
      _fade = 0.0;
      _grain = 0.0;
      _rotation = 0.0;
      _flipHorizontal = false;
      _flipVertical = false;
      _textOverlays.clear();
      _stickerOverlays.clear();
      _drawingPaths.clear();
      _selectedTextIndex = null;
      _selectedStickerIndex = null;
    });
    _saveState();
  }

  ColorFilter? _getFilterMatrix(String filterName) {
    switch (filterName) {
      case 'black_white':
      case 'mono':
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'vintage':
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'cool':
        return const ColorFilter.matrix(<double>[
          0.9, 0, 0, 0, 0,
          0, 0.9, 0, 0, 0,
          0, 0, 1.1, 0, 20,
          0, 0, 0, 1, 0,
        ]);
      case 'warm':
        return const ColorFilter.matrix(<double>[
          1.1, 0, 0, 0, 10,
          0, 1.0, 0, 0, 0,
          0, 0, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'vivid':
        return const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 0,
          0, 1.2, 0, 0, 0,
          0, 0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'fade':
        return const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 20,
          0, 1, 0, 0, 20,
          0, 0, 1, 0, 20,
          0, 0, 0, 0.9, 0,
        ]);
      case 'chrome':
        return const ColorFilter.matrix(<double>[
          1.1, 0.1, 0.1, 0, 0,
          0.1, 1.1, 0.1, 0, 0,
          0.1, 0.1, 1.1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'dramatic':
        return const ColorFilter.matrix(<double>[
          1.4, 0, 0, 0, -30,
          0, 1.4, 0, 0, -30,
          0, 0, 1.4, 0, -30,
          0, 0, 0, 1, 0,
        ]);
      case 'silvertone':
        return const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 10,
          0.33, 0.33, 0.33, 0, 10,
          0.33, 0.33, 0.33, 0, 10,
          0, 0, 0, 1, 0,
        ]);
      case 'noir':
        return const ColorFilter.matrix(<double>[
          0.3, 0.59, 0.11, 0, -30,
          0.3, 0.59, 0.11, 0, -30,
          0.3, 0.59, 0.11, 0, -30,
          0, 0, 0, 1, 0,
        ]);
      case 'clarendon':
        return const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 10,
          0, 1.1, 0, 0, 5,
          0, 0, 1.3, 0, 15,
          0, 0, 0, 1, 0,
        ]);
      case 'gingham':
        return const ColorFilter.matrix(<double>[
          0.9, 0.1, 0.1, 0, 20,
          0.1, 0.9, 0.1, 0, 20,
          0.1, 0.1, 0.9, 0, 20,
          0, 0, 0, 1, 0,
        ]);
      case 'moon':
        return const ColorFilter.matrix(<double>[
          0.5, 0.5, 0, 0, 0,
          0, 0.7, 0.3, 0, 0,
          0, 0.3, 0.7, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'lark':
        return const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 20,
          0, 1.05, 0, 0, 10,
          0, 0, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      default:
        return null;
    }
  }

  List<double> _getAdjustmentMatrix() {
    // Start with identity matrix
    List<double> matrix = [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    // Apply brightness (-100 to 100 → -255 to 255)
    final brightnessValue = _brightness * 2.55;
    matrix[4] += brightnessValue;
    matrix[9] += brightnessValue;
    matrix[14] += brightnessValue;

    // Apply contrast (0 to 2)
    final contrast = _contrast;
    final t = (1 - contrast) / 2 * 255;
    matrix = _multiplyMatrix(matrix, [
      contrast, 0, 0, 0, t,
      0, contrast, 0, 0, t,
      0, 0, contrast, 0, t,
      0, 0, 0, 1, 0,
    ]);

    // Apply saturation (0 to 2)
    final sat = _saturation;
    final invSat = 1 - sat;
    final r = 0.2126 * invSat;
    final g = 0.7152 * invSat;
    final b = 0.0722 * invSat;
    matrix = _multiplyMatrix(matrix, [
      r + sat, g, b, 0, 0,
      r, g + sat, b, 0, 0,
      r, g, b + sat, 0, 0,
      0, 0, 0, 1, 0,
    ]);

    // Apply warmth (shift red/blue channels)
    if (_warmth != 0) {
      final warmthValue = _warmth * 30;
      matrix[4] += warmthValue; // Red
      matrix[14] -= warmthValue; // Blue
    }

    return matrix;
  }

  List<double> _multiplyMatrix(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) sum += a[i * 5 + 4];
        result[i * 5 + j] = sum;
      }
    }
    return result;
  }

  Future<void> _saveAndReturn() async {
    setState(() => _isSaving = true);

    try {
      // Capture the rendered image
      final RenderRepaintBoundary boundary = _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Save to temp file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(pngBytes);

        if (mounted) {
          Navigator.pop(context, PhotoEditResult(
            editedFile: tempFile,
            filter: _selectedFilter,
            brightness: _brightness,
            contrast: _contrast,
            saturation: _saturation,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addTextOverlay() {
    showDialog(
      context: context,
      builder: (context) => _AddTextDialog(
        onAdd: (text, color, fontSize, fontWeight) {
          setState(() {
            _textOverlays.add(TextOverlay(
              text: text,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              position: const Offset(0.5, 0.5),
            ));
            _selectedTextIndex = _textOverlays.length - 1;
          });
          _saveState();
        },
      ),
    );
  }

  void _editTextOverlay(int index) {
    final overlay = _textOverlays[index];
    showDialog(
      context: context,
      builder: (context) => _AddTextDialog(
        initialText: overlay.text,
        initialColor: overlay.color,
        initialFontSize: overlay.fontSize,
        initialFontWeight: overlay.fontWeight,
        onAdd: (text, color, fontSize, fontWeight) {
          setState(() {
            _textOverlays[index] = TextOverlay(
              text: text,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              position: overlay.position,
            );
          });
          _saveState();
        },
      ),
    );
  }

  void _removeTextOverlay(int index) {
    setState(() {
      _textOverlays.removeAt(index);
      _selectedTextIndex = null;
    });
    _saveState();
  }

  void _addSticker(String emoji) {
    setState(() {
      _stickerOverlays.add(StickerOverlay(
        emoji: emoji,
        position: const Offset(0.5, 0.5),
        scale: 1.0,
        rotation: 0.0,
      ));
      _selectedStickerIndex = _stickerOverlays.length - 1;
    });
    _saveState();
  }

  void _removeSticker(int index) {
    setState(() {
      _stickerOverlays.removeAt(index);
      _selectedStickerIndex = null;
    });
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Photo'),
        actions: [
          if (_undoStack.length > 1)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undo,
              tooltip: 'Undo',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAll,
            tooltip: 'Reset',
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveAndReturn,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            child: GestureDetector(
              onPanStart: _tabController.index == 5 ? (details) {
                setState(() {
                  _isDrawing = true;
                  _currentPath = [details.localPosition];
                });
              } : null,
              onPanUpdate: _tabController.index == 5 ? (details) {
                if (_isDrawing) {
                  setState(() => _currentPath.add(details.localPosition));
                }
              } : null,
              onPanEnd: _tabController.index == 5 ? (details) {
                if (_isDrawing && _currentPath.isNotEmpty) {
                  setState(() {
                    _drawingPaths.add(DrawingPath(
                      points: List.from(_currentPath),
                      color: _drawingColor,
                      strokeWidth: _drawingStrokeWidth,
                    ));
                    _currentPath = [];
                    _isDrawing = false;
                  });
                  _saveState();
                }
              } : null,
              child: Center(
                child: RepaintBoundary(
                  key: _imageKey,
                  child: Stack(
                    children: [
                      // Main image with filters and adjustments
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateZ(_rotation * math.pi / 180)
                          ..scale(_flipHorizontal ? -1.0 : 1.0, _flipVertical ? -1.0 : 1.0, 1.0),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix(_getAdjustmentMatrix()),
                          child: ColorFiltered(
                            colorFilter: _getFilterMatrix(_selectedFilter) ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                            child: Image.file(
                              widget.imageFile,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      // Vignette overlay
                      if (_vignette > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: _vignette * 0.7),
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Text overlays
                      ..._textOverlays.asMap().entries.map((entry) {
                        final index = entry.key;
                        final overlay = entry.value;
                        return _DraggableOverlay(
                          position: overlay.position,
                          isSelected: _selectedTextIndex == index,
                          onTap: () => setState(() => _selectedTextIndex = index),
                          onDoubleTap: () => _editTextOverlay(index),
                          onPositionChanged: (newPos) {
                            setState(() {
                              _textOverlays[index] = TextOverlay(
                                text: overlay.text,
                                color: overlay.color,
                                fontSize: overlay.fontSize,
                                fontWeight: overlay.fontWeight,
                                position: newPos,
                              );
                            });
                          },
                          onDelete: () => _removeTextOverlay(index),
                          child: Text(
                            overlay.text,
                            style: TextStyle(
                              color: overlay.color,
                              fontSize: overlay.fontSize,
                              fontWeight: overlay.fontWeight,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Sticker overlays
                      ..._stickerOverlays.asMap().entries.map((entry) {
                        final index = entry.key;
                        final overlay = entry.value;
                        return _DraggableOverlay(
                          position: overlay.position,
                          isSelected: _selectedStickerIndex == index,
                          onTap: () => setState(() => _selectedStickerIndex = index),
                          onPositionChanged: (newPos) {
                            setState(() {
                              _stickerOverlays[index] = StickerOverlay(
                                emoji: overlay.emoji,
                                position: newPos,
                                scale: overlay.scale,
                                rotation: overlay.rotation,
                              );
                            });
                          },
                          onDelete: () => _removeSticker(index),
                          child: Text(
                            overlay.emoji,
                            style: TextStyle(fontSize: 48 * overlay.scale),
                          ),
                        );
                      }),
                      // Drawing paths
                      ..._drawingPaths.map((path) => CustomPaint(
                        size: Size.infinite,
                        painter: _DrawingPainter(path),
                      )),
                      // Current drawing path
                      if (_currentPath.isNotEmpty)
                        CustomPaint(
                          size: Size.infinite,
                          painter: _DrawingPainter(DrawingPath(
                            points: _currentPath,
                            color: _drawingColor,
                            strokeWidth: _drawingStrokeWidth,
                          )),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Tab bar
          Container(
            color: Colors.grey.shade900,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(icon: Icon(Icons.filter), text: 'Filters'),
                Tab(icon: Icon(Icons.tune), text: 'Adjust'),
                Tab(icon: Icon(Icons.crop_rotate), text: 'Crop'),
                Tab(icon: Icon(Icons.text_fields), text: 'Text'),
                Tab(icon: Icon(Icons.emoji_emotions), text: 'Stickers'),
                Tab(icon: Icon(Icons.brush), text: 'Draw'),
              ],
            ),
          ),
          // Tab content
          Container(
            height: 160,
            color: Colors.grey.shade900,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFiltersTab(),
                _buildAdjustTab(),
                _buildCropTab(),
                _buildTextTab(),
                _buildStickersTab(),
                _buildDrawTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: _filters.length,
      itemBuilder: (context, index) {
        final filter = _filters[index];
        final isSelected = _selectedFilter == filter['name'];
        return GestureDetector(
          onTap: () {
            setState(() => _selectedFilter = filter['name']);
            _saveState();
          },
          child: Container(
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ColorFiltered(
                      colorFilter: _getFilterMatrix(filter['name']) ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                      child: Image.file(widget.imageFile, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  filter['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdjustTab() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildAdjustSlider('Brightness', _brightness, -100, 100, (v) => setState(() => _brightness = v)),
          _buildAdjustSlider('Contrast', (_contrast - 1) * 100, -100, 100, (v) => setState(() => _contrast = 1 + v / 100)),
          _buildAdjustSlider('Saturation', (_saturation - 1) * 100, -100, 100, (v) => setState(() => _saturation = 1 + v / 100)),
          _buildAdjustSlider('Warmth', _warmth * 100, -100, 100, (v) => setState(() => _warmth = v / 100)),
          _buildAdjustSlider('Vignette', _vignette * 100, 0, 100, (v) => setState(() => _vignette = v / 100)),
          _buildAdjustSlider('Highlights', _highlights * 100, -100, 100, (v) => setState(() => _highlights = v / 100)),
          _buildAdjustSlider('Shadows', _shadows * 100, -100, 100, (v) => setState(() => _shadows = v / 100)),
          _buildAdjustSlider('Fade', _fade * 100, 0, 100, (v) => setState(() => _fade = v / 100)),
        ],
      ),
    );
  }

  Widget _buildAdjustSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(height: 4),
          SizedBox(
            height: 100,
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                activeColor: Colors.white,
                inactiveColor: Colors.grey.shade700,
                onChanged: onChanged,
                onChangeEnd: (_) => _saveState(),
              ),
            ),
          ),
          Text(
            value.round().toString(),
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCropTab() {
    return Column(
      children: [
        // Aspect ratio buttons
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _aspectRatios.length,
            itemBuilder: (context, index) {
              final ratio = _aspectRatios[index];
              final isSelected = _aspectRatio == ratio;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(ratio == 'free' ? 'Free' : ratio),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _aspectRatio = ratio),
                  selectedColor: Colors.white,
                  backgroundColor: Colors.grey.shade800,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Rotate/Flip buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCropButton(Icons.rotate_left, 'Rotate L', () {
              setState(() => _rotation -= 90);
              _saveState();
            }),
            _buildCropButton(Icons.rotate_right, 'Rotate R', () {
              setState(() => _rotation += 90);
              _saveState();
            }),
            _buildCropButton(Icons.flip, 'Flip H', () {
              setState(() => _flipHorizontal = !_flipHorizontal);
              _saveState();
            }),
            _buildCropButton(Icons.flip_outlined, 'Flip V', () {
              setState(() => _flipVertical = !_flipVertical);
              _saveState();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCropButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    return Column(
      children: [
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addTextOverlay,
          icon: const Icon(Icons.add),
          label: const Text('Add Text'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        if (_textOverlays.isNotEmpty)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _textOverlays.length,
              itemBuilder: (context, index) {
                final overlay = _textOverlays[index];
                final isSelected = _selectedTextIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTextIndex = index),
                  onDoubleTap: () => _editTextOverlay(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          overlay.text.length > 15 ? '${overlay.text.substring(0, 15)}...' : overlay.text,
                          style: TextStyle(color: isSelected ? Colors.black : Colors.white),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeTextOverlay(index),
                          child: Icon(Icons.close, size: 16, color: isSelected ? Colors.black : Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text('Tap "Add Text" to add text overlay', style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }

  Widget _buildStickersTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _emojis.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _addSticker(_emojis[index]),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_emojis[index], style: const TextStyle(fontSize: 24)),
          ),
        );
      },
    );
  }

  Widget _buildDrawTab() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Color picker
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Colors.white, Colors.black, Colors.red, Colors.orange,
              Colors.yellow, Colors.green, Colors.blue, Colors.purple,
              Colors.pink, Colors.cyan, Colors.teal, Colors.amber,
            ].map((color) {
              final isSelected = _drawingColor == color;
              return GestureDetector(
                onTap: () => setState(() => _drawingColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected ? [
                      const BoxShadow(color: Colors.white24, blurRadius: 8),
                    ] : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Brush size
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              const Icon(Icons.brush, color: Colors.white, size: 16),
              Expanded(
                child: Slider(
                  value: _drawingStrokeWidth,
                  min: 2,
                  max: 20,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey.shade700,
                  onChanged: (v) => setState(() => _drawingStrokeWidth = v),
                ),
              ),
              const Icon(Icons.brush, color: Colors.white, size: 24),
            ],
          ),
        ),
        // Clear button
        TextButton.icon(
          onPressed: _drawingPaths.isEmpty ? null : () {
            setState(() => _drawingPaths.clear());
            _saveState();
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear Drawing'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ],
    );
  }
}

// Data classes
class TextOverlay {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final Offset position;

  TextOverlay({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.fontWeight,
    required this.position,
  });
}

class StickerOverlay {
  final String emoji;
  final Offset position;
  final double scale;
  final double rotation;

  StickerOverlay({
    required this.emoji,
    required this.position,
    required this.scale,
    required this.rotation,
  });
}

class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class EditorState {
  final String filter;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double sharpness;
  final double vignette;
  final double highlights;
  final double shadows;
  final double fade;
  final double grain;
  final double rotation;
  final bool flipHorizontal;
  final bool flipVertical;
  final List<TextOverlay> textOverlays;
  final List<StickerOverlay> stickerOverlays;
  final List<DrawingPath> drawingPaths;

  EditorState({
    required this.filter,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.sharpness,
    required this.vignette,
    required this.highlights,
    required this.shadows,
    required this.fade,
    required this.grain,
    required this.rotation,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.textOverlays,
    required this.stickerOverlays,
    required this.drawingPaths,
  });
}

class PhotoEditResult {
  final File editedFile;
  final String filter;
  final double brightness;
  final double contrast;
  final double saturation;

  PhotoEditResult({
    required this.editedFile,
    required this.filter,
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });
}

// Draggable overlay widget
class _DraggableOverlay extends StatefulWidget {
  final Offset position;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onDelete;
  final Widget child;

  const _DraggableOverlay({
    required this.position,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
    required this.onPositionChanged,
    required this.onDelete,
    required this.child,
  });

  @override
  State<_DraggableOverlay> createState() => _DraggableOverlayState();
}

class _DraggableOverlayState extends State<_DraggableOverlay> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.position;
  }

  @override
  void didUpdateWidget(_DraggableOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _position = widget.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Positioned(
          left: _position.dx * constraints.maxWidth - 50,
          top: _position.dy * constraints.maxHeight - 25,
          child: GestureDetector(
            onTap: widget.onTap,
            onDoubleTap: widget.onDoubleTap,
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  (_position.dx + details.delta.dx / constraints.maxWidth).clamp(0.0, 1.0),
                  (_position.dy + details.delta.dy / constraints.maxHeight).clamp(0.0, 1.0),
                );
              });
            },
            onPanEnd: (_) => widget.onPositionChanged(_position),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: widget.isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  widget.child,
                  if (widget.isSelected)
                    Positioned(
                      right: -12,
                      top: -12,
                      child: GestureDetector(
                        onTap: widget.onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Drawing painter
class _DrawingPainter extends CustomPainter {
  final DrawingPath path;

  _DrawingPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    if (path.points.isEmpty) return;

    final paint = Paint()
      ..color = path.color
      ..strokeWidth = path.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pathObj = Path();
    pathObj.moveTo(path.points.first.dx, path.points.first.dy);

    for (int i = 1; i < path.points.length; i++) {
      pathObj.lineTo(path.points[i].dx, path.points[i].dy);
    }

    canvas.drawPath(pathObj, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

// Add Text Dialog
class _AddTextDialog extends StatefulWidget {
  final String? initialText;
  final Color? initialColor;
  final double? initialFontSize;
  final FontWeight? initialFontWeight;
  final void Function(String text, Color color, double fontSize, FontWeight fontWeight) onAdd;

  const _AddTextDialog({
    this.initialText,
    this.initialColor,
    this.initialFontSize,
    this.initialFontWeight,
    required this.onAdd,
  });

  @override
  State<_AddTextDialog> createState() => _AddTextDialogState();
}

class _AddTextDialogState extends State<_AddTextDialog> {
  late TextEditingController _controller;
  late Color _selectedColor;
  late double _fontSize;
  late FontWeight _fontWeight;

  static const List<Color> _colors = [
    Colors.white, Colors.black, Colors.red, Colors.orange,
    Colors.yellow, Colors.green, Colors.blue, Colors.purple,
    Colors.pink, Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _selectedColor = widget.initialColor ?? Colors.white;
    _fontSize = widget.initialFontSize ?? 24;
    _fontWeight = widget.initialFontWeight ?? FontWeight.bold;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialText != null ? 'Edit Text' : 'Add Text'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter text...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Color picker
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Font size slider
            Row(
              children: [
                const Text('Size:'),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 72,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
                Text(_fontSize.round().toString()),
              ],
            ),
            // Font weight toggle
            Row(
              children: [
                const Text('Bold:'),
                Switch(
                  value: _fontWeight == FontWeight.bold,
                  onChanged: (v) => setState(() => _fontWeight = v ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty ? null : () {
            widget.onAdd(_controller.text.trim(), _selectedColor, _fontSize, _fontWeight);
            Navigator.pop(context);
          },
          child: Text(widget.initialText != null ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
