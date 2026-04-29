import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chef_listing.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);

const List<_DietaryTag> _kDietaryTags = [
  _DietaryTag(key: 'halal', labelSw: 'Halal'),
  _DietaryTag(key: 'vegetarian', labelSw: 'Mboga'),
  _DietaryTag(key: 'vegan', labelSw: 'Vegan'),
  _DietaryTag(key: 'no_pork', labelSw: 'Hakuna Nguruwe'),
  _DietaryTag(key: 'gluten_free', labelSw: 'Bila Ngano'),
  _DietaryTag(key: 'spicy', labelSw: 'Kali'),
];

class PostTodayExtraPage extends StatefulWidget {
  final int userId;
  const PostTodayExtraPage({super.key, required this.userId});

  @override
  State<PostTodayExtraPage> createState() => _PostTodayExtraPageState();
}

class _PostTodayExtraPageState extends State<PostTodayExtraPage> {
  final FoodService _service = FoodService();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _portionsCtrl = TextEditingController(text: '4');
  final _priceCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  ChefListingMode _mode = ChefListingMode.todayExtra;
  final Set<String> _selectedTags = {};
  int _windowHours = 2;
  File? _photoFile;
  String? _uploadedPhotoUrl;
  bool _uploading = false;
  bool _submitting = false;

  bool _deliveryEnabled = false;
  final _deliveryFeeCtrl = TextEditingController(text: '2000');
  double _deliveryRadiusKm = 3;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _portionsCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _addressCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _photoFile = File(picked.path);
        _uploadedPhotoUrl = null;
        _uploading = true;
      });
      final result = await _service.uploadChefListingPhoto(
        userId: widget.userId,
        file: _photoFile!,
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      if (result.success) {
        setState(() => _uploadedPhotoUrl = result.data);
      } else {
        _showSnack(result.message ?? 'Picha imeshindikana');
        setState(() => _photoFile = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _photoFile = null;
      });
      _showSnack('Kosa la picha: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mode != ChefListingMode.giveaway) {
      final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
      if (price <= 0) {
        _showSnack('Weka bei sahihi');
        return;
      }
    }
    final portions = int.tryParse(_portionsCtrl.text.trim()) ?? 0;
    if (portions <= 0) {
      _showSnack('Weka idadi ya sehemu');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _submitting = true);
    final now = DateTime.now();
    final start = now.add(const Duration(minutes: 15));
    final end = now.add(Duration(hours: _windowHours));

    final priceTzs = _mode == ChefListingMode.giveaway
        ? null
        : int.tryParse(_priceCtrl.text.trim());
    final originalPrice = int.tryParse(_originalPriceCtrl.text.trim());

    final result = await _service.createChefListing(
      userId: widget.userId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      photoUrl: _uploadedPhotoUrl,
      mode: _mode,
      portionsTotal: portions,
      priceTzs: priceTzs,
      originalPriceTzs: originalPrice,
      pickupWindowStart: start,
      pickupWindowEnd: end,
      pickupAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      dietaryTags: _selectedTags.toList(),
      deliveryEnabled: _deliveryEnabled,
      deliveryFeeTzs: _deliveryEnabled ? int.tryParse(_deliveryFeeCtrl.text.trim()) : null,
      deliveryRadiusKm: _deliveryEnabled ? _deliveryRadiusKm : null,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chakula kimewekwa. Wateja wataona sasa.')),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuweka chakula')),
      );
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          'Nina Chakula Zaidi Leo',
          style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _photoPicker(),
              const SizedBox(height: 16),
              _modePicker(),
              const SizedBox(height: 16),
              _sectionLabel('Jina la Chakula', 'Dish name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(hint: 'Mfano: Pilau ya Kuku'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Jina linahitajika' : null,
              ),
              const SizedBox(height: 16),
              _sectionLabel('Maelezo (hiari)', 'Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: _inputDecoration(
                  hint: 'Viungo, ukubwa wa sehemu, mapendekezo...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Sehemu', 'Portions'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _portionsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecoration(hint: '4'),
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim()) ?? 0;
                            if (n <= 0) return 'Idadi?';
                            if (n > 500) return 'Zaidi sana';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_mode != ChefListingMode.giveaway) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Bei / Sehemu', 'Price per portion'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDecoration(hint: 'TZS'),
                            validator: (v) {
                              if (_mode == ChefListingMode.giveaway) return null;
                              final n = int.tryParse((v ?? '').trim()) ?? 0;
                              if (n <= 0) return 'Weka bei';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (_mode != ChefListingMode.giveaway) ...[
                const SizedBox(height: 16),
                _sectionLabel('Bei ya Awali (hiari)', 'Original price (for discount badge)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _originalPriceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(hint: 'TZS — ikiwa punguzo'),
                ),
              ],
              const SizedBox(height: 16),
              _sectionLabel('Muda wa Kuchukua', 'Pickup window'),
              const SizedBox(height: 6),
              _windowSlider(),
              const SizedBox(height: 16),
              _sectionLabel('Mahali pa Kuchukua (hiari)', 'Pickup address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressCtrl,
                decoration: _inputDecoration(hint: 'Mfano: Mbezi Louis, karibu na soko'),
              ),
              const SizedBox(height: 16),
              _sectionLabel('Vigezo vya Chakula', 'Dietary tags'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kDietaryTags.map(_tagChip).toList(),
              ),
              const SizedBox(height: 16),
              _deliveryToggle(),
              const SizedBox(height: 24),
              _submitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPicker() {
    return GestureDetector(
      onTap: _uploading || _submitting ? null : _pickPhoto,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _photoFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 36, color: _kSecondary),
                  const SizedBox(height: 8),
                  const Text(
                    'Piga picha ya chakula',
                    style: TextStyle(color: _kSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to take photo',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _photoFile!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_uploading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: IconButton(
                        iconSize: 18,
                        color: Colors.white,
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _uploading ? null : _pickPhoto,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _modePicker() {
    return Row(
      children: [
        Expanded(child: _modeOption(ChefListingMode.todayExtra, 'Ninauza')),
        const SizedBox(width: 8),
        Expanded(child: _modeOption(ChefListingMode.giveaway, 'Natoa Bure')),
      ],
    );
  }

  Widget _modeOption(ChefListingMode mode, String label) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _kPrimary : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kPrimary,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String sw, String en) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(sw, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kPrimary)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            en,
            style: const TextStyle(fontSize: 11, color: _kSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
      filled: true,
      fillColor: _kCardBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPrimary),
      ),
    );
  }

  Widget _windowSlider() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saa $_windowHours — mpaka ${TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: _windowHours))).format(context)}',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kPrimary,
              thumbColor: _kPrimary,
              overlayColor: _kPrimary.withValues(alpha: 0.1),
            ),
            child: Slider(
              min: 1,
              max: 4,
              divisions: 3,
              value: _windowHours.toDouble(),
              label: '$_windowHours h',
              onChanged: (v) => setState(() => _windowHours = v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(_DietaryTag tag) {
    final selected = _selectedTags.contains(tag.key);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedTags.remove(tag.key);
          } else {
            _selectedTags.add(tag.key);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kPrimary : Colors.grey.shade300),
        ),
        child: Text(
          tag.labelSw,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kPrimary,
          ),
        ),
      ),
    );
  }

  Widget _deliveryToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: _kPrimary,
            title: const Text(
              'Naweza kufikisha kwa mteja',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kPrimary),
            ),
            subtitle: const Text(
              'Toggle delivery option (chef brings the food)',
              style: TextStyle(fontSize: 11, color: _kSecondary),
            ),
            value: _deliveryEnabled,
            onChanged: (v) => setState(() => _deliveryEnabled = v),
          ),
          if (_deliveryEnabled) ...[
            const SizedBox(height: 6),
            _sectionLabel('Ada ya Usafiri', 'Delivery fee'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _deliveryFeeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration(hint: 'TZS'),
              validator: (v) {
                if (!_deliveryEnabled) return null;
                final n = int.tryParse((v ?? '').trim()) ?? 0;
                if (n < 0) return 'Si sahihi';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _sectionLabel('Eneo la Usafiri', 'Delivery radius'),
            const SizedBox(height: 6),
            Text(
              '${_deliveryRadiusKm.toStringAsFixed(1)} km',
              style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _kPrimary,
                thumbColor: _kPrimary,
                overlayColor: _kPrimary.withValues(alpha: 0.1),
              ),
              child: Slider(
                min: 0.5,
                max: 10,
                divisions: 19,
                value: _deliveryRadiusKm,
                label: '${_deliveryRadiusKm.toStringAsFixed(1)} km',
                onChanged: (v) => setState(() => _deliveryRadiusKm = v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _submitButton() {
    final disabled = _submitting || _uploading;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _submitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _mode == ChefListingMode.giveaway
                        ? Icons.volunteer_activism_rounded
                        : Icons.publish_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _mode == ChefListingMode.giveaway ? 'Toa Bure' : 'Chapisha',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DietaryTag {
  final String key;
  final String labelSw;
  const _DietaryTag({required this.key, required this.labelSw});
}

// ignore: unused_element
Color get _kAccentRef => _kAccent;
