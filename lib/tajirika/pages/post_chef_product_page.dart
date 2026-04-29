// lib/tajirika/pages/post_chef_product_page.dart
// Partner UI for creating/editing a chef product (e.g. cake-to-order).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../food/models/chef_product.dart';
import '../../food/services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);

const List<int> _kLeadTimes = [6, 12, 24, 48, 72, 168];
const int _kMaxPhotos = 5;

const List<_TagOption> _kTagOptions = [
  _TagOption('cake', 'Keki'),
  _TagOption('birthday', 'Sherehe'),
  _TagOption('wedding', 'Harusi'),
  _TagOption('chocolate', 'Chocolate'),
  _TagOption('vanilla', 'Vanilla'),
  _TagOption('halal', 'Halal'),
  _TagOption('homemade', 'Nyumbani'),
];

class PostChefProductPage extends StatefulWidget {
  final int userId;
  final ChefProduct? existing;

  const PostChefProductPage({
    super.key,
    required this.userId,
    this.existing,
  });

  @override
  State<PostChefProductPage> createState() => _PostChefProductPageState();
}

class _PostChefProductPageState extends State<PostChefProductPage> {
  final FoodService _service = FoodService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minQtyCtrl = TextEditingController(text: '1');

  int _leadTimeHours = 24;
  ChefProductMode _mode = ChefProductMode.both;
  final Set<String> _tags = {};

  final List<File> _localPhotos = [];
  final List<String> _uploadedUrls = [];
  bool _uploading = false;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description ?? '';
      _priceCtrl.text = e.basePriceTzs.toString();
      _minQtyCtrl.text = e.minQuantity.toString();
      _leadTimeHours = e.leadTimeHours;
      _mode = e.mode;
      _tags.addAll(e.tags);
      _uploadedUrls.addAll(e.photos);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _minQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_uploadedUrls.length >= _kMaxPhotos) {
      _toast('Picha zaidi ya $_kMaxPhotos haziruhusiwi');
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      setState(() {
        _localPhotos.add(file);
        _uploading = true;
      });
      final res = await _service.uploadChefProductPhoto(
        userId: widget.userId,
        file: file,
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _localPhotos.remove(file);
      });
      if (res.success && (res.data ?? '').isNotEmpty) {
        setState(() => _uploadedUrls.add(res.data!));
      } else {
        _toast(res.message ?? 'Picha imeshindikana');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _toast('Kosa: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() => _uploadedUrls.removeAt(index));
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final minQty = int.tryParse(_minQtyCtrl.text.trim()) ?? 1;

    if (title.isEmpty) {
      _toast('Andika jina la bidhaa');
      return;
    }
    if (price <= 0) {
      _toast('Andika bei sahihi');
      return;
    }
    if (_uploadedUrls.isEmpty) {
      _toast('Ongeza picha angalau moja');
      return;
    }

    setState(() => _submitting = true);

    final res = _isEdit
        ? await _service.updateChefProduct(
            productId: widget.existing!.id,
            userId: widget.userId,
            title: title,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            basePriceTzs: price,
            leadTimeHours: _leadTimeHours,
            minQuantity: minQty,
            mode: _mode,
            tags: _tags.toList(),
            photos: _uploadedUrls,
          )
        : await _service.createChefProduct(
            userId: widget.userId,
            title: title,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            basePriceTzs: price,
            leadTimeHours: _leadTimeHours,
            minQuantity: minQty,
            mode: _mode,
            tags: _tags.toList(),
            photos: _uploadedUrls,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.success && res.data != null) {
      _toast(_isEdit ? 'Imehifadhiwa' : 'Imechapishwa');
      Navigator.pop(context, res.data);
    } else {
      _toast(res.message ?? 'Imeshindikana');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _photoGrid(),
                  const SizedBox(height: 16),
                  _label('Jina la bidhaa'),
                  TextField(
                    controller: _titleCtrl,
                    maxLength: 100,
                    decoration: _input(hint: 'Mfano: Keki ya chocolate'),
                  ),
                  const SizedBox(height: 12),
                  _label('Maelezo (si lazima)'),
                  TextField(
                    controller: _descCtrl,
                    minLines: 2,
                    maxLines: 5,
                    decoration: _input(hint: 'Vipimo, ladha, viungo...'),
                  ),
                  const SizedBox(height: 12),
                  _label('Bei (TZS)'),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: _input(hint: '50000'),
                  ),
                  const SizedBox(height: 12),
                  _label('Idadi ya chini ya kuagiza'),
                  TextField(
                    controller: _minQtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: _input(hint: '1'),
                  ),
                  const SizedBox(height: 16),
                  _label('Muda wa kuandaa (saa)'),
                  _leadTimeSelector(),
                  const SizedBox(height: 16),
                  _label('Njia ya kupata'),
                  _modeSelector(),
                  const SizedBox(height: 16),
                  _label('Lebo (chagua zinazohusu)'),
                  _tagSelector(),
                ],
              ),
            ),
            _buildSubmitBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                size: 22, color: _kPrimary),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              _isEdit ? 'Hariri bidhaa' : 'Tangaza bidhaa',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoGrid() {
    final tiles = <Widget>[];
    for (var i = 0; i < _uploadedUrls.length; i++) {
      tiles.add(_photoTile(_uploadedUrls[i], onRemove: () => _removePhoto(i)));
    }
    for (final f in _localPhotos) {
      tiles.add(_photoTile(f.path, isLocal: true));
    }
    if (_uploadedUrls.length + _localPhotos.length < _kMaxPhotos) {
      tiles.add(_addPhotoTile());
    }
    return Wrap(spacing: 8, runSpacing: 8, children: tiles);
  }

  Widget _photoTile(String src,
      {bool isLocal = false, VoidCallback? onRemove}) {
    final tileSize = (MediaQuery.of(context).size.width - 32 - 24) / 3;
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isLocal
                  ? Image.file(File(src), fit: BoxFit.cover)
                  : Image.network(src, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: _kBorder,
                          child: const Icon(Icons.broken_image_rounded,
                              color: _kSecondary))),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
          if (isLocal)
            const Positioned.fill(
              child: ColoredBox(color: Color(0x66000000)),
            ),
          if (isLocal)
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addPhotoTile() {
    final tileSize = (MediaQuery.of(context).size.width - 32 - 24) / 3;
    return GestureDetector(
      onTap: _uploading ? null : _addPhoto,
      child: Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border.all(color: _kBorder, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                size: 28, color: _kSecondary),
            SizedBox(height: 4),
            Text('Ongeza picha',
                style: TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _leadTimeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kLeadTimes.map((h) {
        final selected = _leadTimeHours == h;
        return GestureDetector(
          onTap: () => setState(() => _leadTimeHours = h),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? _kPrimary : _kBorder),
            ),
            child: Text(
              h < 24
                  ? '${h}h'
                  : h == 24
                      ? '1 siku'
                      : h == 48
                          ? '2 siku'
                          : h == 72
                              ? '3 siku'
                              : '1 wiki',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _modeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ChefProductMode.values.map((m) {
        final selected = _mode == m;
        return GestureDetector(
          onTap: () => setState(() => _mode = m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? _kPrimary : _kBorder),
            ),
            child: Text(
              m.labelSwahili,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tagSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kTagOptions.map((t) {
        final selected = _tags.contains(t.key);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _tags.remove(t.key);
            } else {
              _tags.add(t.key);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? _kPrimary.withValues(alpha: 0.08)
                  : _kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: selected ? _kPrimary : _kBorder),
            ),
            child: Text(
              t.labelSw,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _kPrimary : _kSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kPrimary)),
    );
  }

  InputDecoration _input({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _kCardBg,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      counterText: '',
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kPrimary),
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(
                  _isEdit ? 'Hifadhi mabadiliko' : 'Tangaza bidhaa',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

class _TagOption {
  final String key;
  final String labelSw;
  const _TagOption(this.key, this.labelSw);
}
