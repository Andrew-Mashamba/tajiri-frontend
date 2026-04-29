import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chef_listing.dart';
import '../services/food_service.dart';
import 'curated_reservations_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

const List<_Tag> _kTags = [
  _Tag(key: 'halal', labelSw: 'Halal'),
  _Tag(key: 'vegetarian', labelSw: 'Mboga'),
  _Tag(key: 'vegan', labelSw: 'Vegan'),
  _Tag(key: 'no_pork', labelSw: 'Hakuna Nguruwe'),
  _Tag(key: 'gluten_free', labelSw: 'Bila Ngano'),
  _Tag(key: 'spicy', labelSw: 'Kali'),
];

class CommunityGiveawayPage extends StatefulWidget {
  final int userId;
  const CommunityGiveawayPage({super.key, required this.userId});

  @override
  State<CommunityGiveawayPage> createState() => _CommunityGiveawayPageState();
}

class _CommunityGiveawayPageState extends State<CommunityGiveawayPage> {
  final FoodService _service = FoodService();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _portionsCtrl = TextEditingController(text: '4');
  final _addressCtrl = TextEditingController();

  ChefListingSelectionMode _selectionMode = ChefListingSelectionMode.open;
  final Set<String> _tags = {};
  int _windowHours = 2;
  File? _photoFile;
  String? _uploadedPhotoUrl;
  bool _uploading = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _portionsCtrl.dispose();
    _addressCtrl.dispose();
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

    final result = await _service.createChefListing(
      userId: widget.userId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      photoUrl: _uploadedPhotoUrl,
      mode: ChefListingMode.giveaway,
      recipientType: ChefListingRecipientType.community,
      selectionMode: _selectionMode,
      portionsTotal: portions,
      pickupWindowStart: start,
      pickupWindowEnd: end,
      pickupAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      dietaryTags: _tags.toList(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success && result.data != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_selectionMode == ChefListingSelectionMode.curated
              ? 'Chakula kimewekwa. Utapokea maombi ya kuchagua.'
              : 'Chakula kimewekwa. Jirani wa kwanza atapokea.'),
        ),
      );
      if (_selectionMode == ChefListingSelectionMode.curated) {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => CuratedReservationsPage(
              listingId: result.data!.id,
              listingTitle: result.data!.title,
              partnerUserId: widget.userId,
            ),
          ),
        );
      } else {
        navigator.pop(true);
      }
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
        title: const Text('Toa Bure (Jirani)',
            style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _photoPicker(),
              const SizedBox(height: 16),
              _label('Nani apate chakula?'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _modeChip(ChefListingSelectionMode.open)),
                  const SizedBox(width: 8),
                  Expanded(child: _modeChip(ChefListingSelectionMode.curated)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _selectionMode == ChefListingSelectionMode.open
                    ? 'Jirani wa kwanza kuomba atapokea'
                    : 'Wewe utachagua kutoka kwa walioomba (kila mmoja anaandika "Kwa nini mimi")',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
              const SizedBox(height: 16),
              _label('Jina la Chakula'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDec(hint: 'k.m. Ugali na samaki'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Jina linahitajika' : null,
              ),
              const SizedBox(height: 16),
              _label('Maelezo (hiari)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: _inputDec(hint: 'Viungo, ukubwa, mapendekezo...'),
              ),
              const SizedBox(height: 16),
              _label('Sehemu'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _portionsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDec(hint: '4'),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim()) ?? 0;
                  if (n <= 0) return 'Idadi?';
                  if (n > 500) return 'Zaidi sana';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Muda wa Kuchukua'),
              const SizedBox(height: 6),
              _windowSlider(),
              const SizedBox(height: 16),
              _label('Mahali pa Kuchukua (hiari)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressCtrl,
                decoration: _inputDec(hint: 'k.m. Mbezi Louis, karibu na soko'),
              ),
              const SizedBox(height: 16),
              _label('Vigezo vya Chakula'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kTags.map(_tagChip).toList(),
              ),
              const SizedBox(height: 24),
              _submitBtn(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(ChefListingSelectionMode m) {
    final selected = _selectionMode == m;
    return GestureDetector(
      onTap: () => setState(() => _selectionMode = m),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _kPrimary : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          m.labelSwahili,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : _kPrimary,
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
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, size: 36, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Piga picha ya chakula',
                      style: TextStyle(color: _kSecondary, fontWeight: FontWeight.w600)),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_photoFile!,
                        height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                  if (_uploading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  Widget _tagChip(_Tag tag) {
    final selected = _tags.contains(tag.key);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _tags.remove(tag.key);
          } else {
            _tags.add(tag.key);
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

  Widget _submitBtn() {
    final disabled = _submitting || _uploading;
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.volunteer_activism_rounded, size: 20),
        label: const Text('Toa Bure',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _label(String s) => Text(s,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kPrimary));

  InputDecoration _inputDec({required String hint}) => InputDecoration(
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

class _Tag {
  final String key;
  final String labelSw;
  const _Tag({required this.key, required this.labelSw});
}
