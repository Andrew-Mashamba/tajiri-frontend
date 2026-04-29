import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../food/models/beneficiary_org.dart';
import '../../food/models/chef_listing.dart';
import '../../food/services/food_service.dart';

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

class ScheduleMenuPage extends StatefulWidget {
  final int userId;
  const ScheduleMenuPage({super.key, required this.userId});

  @override
  State<ScheduleMenuPage> createState() => _ScheduleMenuPageState();
}

class _ScheduleMenuPageState extends State<ScheduleMenuPage> {
  final FoodService _service = FoodService();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _portionsCtrl = TextEditingController(text: '10');
  final _priceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  final _deliveryRadiusCtrl = TextEditingController(text: '5');

  final Set<String> _selectedTags = {};
  ChefListingMode _selectedMode = ChefListingMode.todayExtra;
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _pickupEndTime = const TimeOfDay(hour: 14, minute: 0);
  bool _deliveryEnabled = false;
  File? _photoFile;
  String? _uploadedPhotoUrl;
  bool _uploading = false;
  bool _submitting = false;

  bool _cascadeEnabled = false;
  int? _cascadeOrgId;
  List<BeneficiaryOrg> _orgs = const [];
  bool _orgsLoaded = false;
  bool _orgsLoading = false;

  bool get _isGiveaway => _selectedMode == ChefListingMode.giveaway;
  bool get _maxOneDay =>
      _selectedMode == ChefListingMode.todayExtra || _selectedMode == ChefListingMode.giveaway;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  Future<void> _loadOrgs() async {
    if (_orgsLoading) return;
    setState(() => _orgsLoading = true);
    final result = await _service.listBeneficiaryOrgs(status: 'verified', limit: 100);
    if (!mounted) return;
    setState(() {
      _orgsLoading = false;
      _orgsLoaded = true;
      if (result.success) {
        _orgs = result.items;
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _portionsCtrl.dispose();
    _priceCtrl.dispose();
    _addressCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _deliveryRadiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = _maxOneDay ? today : today.add(const Duration(days: 14));
    final initial = _pickupDate.isBefore(today)
        ? today
        : (_pickupDate.isAfter(lastDate) ? lastDate : _pickupDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: lastDate,
    );
    if (picked != null) setState(() => _pickupDate = picked);
  }

  void _onModeChanged(ChefListingMode mode) {
    if (mode == _selectedMode) return;
    setState(() {
      _selectedMode = mode;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_maxOneDay && _pickupDate.isAfter(today)) {
        _pickupDate = today;
      }
      if (mode == ChefListingMode.giveaway) {
        _priceCtrl.clear();
        _cascadeEnabled = true;
      }
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _pickupStartTime);
    if (picked != null) {
      setState(() {
        _pickupStartTime = picked;
        if (_toMinutes(_pickupEndTime) <= _toMinutes(picked)) {
          _pickupEndTime = TimeOfDay(hour: (picked.hour + 2) % 24, minute: picked.minute);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _pickupEndTime);
    if (picked != null) setState(() => _pickupEndTime = picked);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    int? price;
    if (!_isGiveaway) {
      price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
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
    if (_toMinutes(_pickupEndTime) <= _toMinutes(_pickupStartTime)) {
      _showSnack('Muda wa mwisho lazima uwe baada ya mwanzo');
      return;
    }

    if ((_isGiveaway || _cascadeEnabled) && _cascadeOrgId == null) {
      _showSnack('Chagua shirika la kupokea mabaki');
      return;
    }

    int? deliveryFee;
    double? deliveryRadius;
    if (_deliveryEnabled) {
      deliveryFee = int.tryParse(_deliveryFeeCtrl.text.trim());
      deliveryRadius = double.tryParse(_deliveryRadiusCtrl.text.trim());
      if (deliveryFee == null || deliveryFee < 0) {
        _showSnack('Weka ada ya usafirishaji');
        return;
      }
      if (deliveryRadius == null || deliveryRadius <= 0) {
        _showSnack('Weka umbali wa kilomita');
        return;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _submitting = true);
    final start = _combine(_pickupDate, _pickupStartTime);
    final end = _combine(_pickupDate, _pickupEndTime);

    final recipientType = _isGiveaway
        ? ChefListingRecipientType.organisation
        : ChefListingRecipientType.public;

    final result = await _service.createChefListing(
      userId: widget.userId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      photoUrl: _uploadedPhotoUrl,
      mode: _selectedMode,
      recipientType: recipientType,
      beneficiaryOrgId: _isGiveaway ? _cascadeOrgId : null,
      cascadeOrgId: !_isGiveaway && _cascadeEnabled ? _cascadeOrgId : null,
      cookedAt: DateTime.now(),
      portionsTotal: portions,
      priceTzs: price,
      pickupWindowStart: start,
      pickupWindowEnd: end,
      pickupAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      dietaryTags: _selectedTags.toList(),
      deliveryEnabled: _deliveryEnabled,
      deliveryFeeTzs: deliveryFee,
      deliveryRadiusKm: deliveryRadius,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Menu imewekwa.')));
      navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa')));
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
          'Panga Menu Yangu',
          style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _modeSelector(),
              const SizedBox(height: 16),
              _photoPicker(),
              const SizedBox(height: 16),
              _sectionLabel('Jina la Chakula', 'Dish name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 60,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(hint: 'Mfano: Pilau ya Kuku'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Jina linahitajika' : null,
              ),
              const SizedBox(height: 8),
              _sectionLabel('Maelezo (hiari)', 'Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: _inputDecoration(hint: 'Viungo, ukubwa wa sehemu...'),
              ),
              const SizedBox(height: 8),
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
                          decoration: _inputDecoration(hint: '10'),
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
                  if (!_isGiveaway) ...[
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
                              if (_isGiveaway) return null;
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
              const SizedBox(height: 16),
              _sectionLabel('Tarehe ya Kuchukua', 'Pickup date'),
              const SizedBox(height: 6),
              _pickerRow(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(_pickupDate),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Mwanzo', 'Start'),
                        const SizedBox(height: 6),
                        _pickerRow(
                          icon: Icons.access_time_rounded,
                          label: _pickupStartTime.format(context),
                          onTap: _pickStartTime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Mwisho', 'End'),
                        const SizedBox(height: 6),
                        _pickerRow(
                          icon: Icons.access_time_rounded,
                          label: _pickupEndTime.format(context),
                          onTap: _pickEndTime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionLabel('Mahali pa Kuchukua (hiari)', 'Pickup address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressCtrl,
                decoration: _inputDecoration(hint: 'Mfano: Mbezi Louis, karibu na soko'),
              ),
              const SizedBox(height: 16),
              _deliverySection(),
              const SizedBox(height: 16),
              _cascadeSection(),
              const SizedBox(height: 16),
              _sectionLabel('Vigezo vya Chakula', 'Dietary tags'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kDietaryTags.map(_tagChip).toList(),
              ),
              const SizedBox(height: 24),
              _submitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deliverySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delivery_dining_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nitafikisha',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    Text(
                      'I’ll deliver to buyer',
                      style: TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _deliveryEnabled,
                onChanged: _submitting ? null : (v) => setState(() => _deliveryEnabled = v),
                activeThumbColor: _kAccent,
              ),
            ],
          ),
          if (_deliveryEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Ada', 'Fee (TZS)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _deliveryFeeCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDecoration(hint: '2000'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Umbali', 'Radius (km)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _deliveryRadiusCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(hint: '5'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeSelector() {
    Widget chip(ChefListingMode mode, String sw, String hint, IconData icon) {
      final selected = _selectedMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: _submitting ? null : () => _onModeChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : _kCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? _kPrimary : _kPrimary.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : _kPrimary),
                const SizedBox(height: 6),
                Text(
                  sw,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _kPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected ? Colors.white.withValues(alpha: 0.85) : _kSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(ChefListingMode.todayExtra, 'Chakula cha Leo', 'Chukua leo', Icons.today_rounded),
        const SizedBox(width: 8),
        chip(ChefListingMode.scheduled, 'Imepangwa', 'Tarehe ijayo', Icons.event_rounded),
        const SizedBox(width: 8),
        chip(ChefListingMode.giveaway, 'Mgao wa Bure', 'Kwa shirika', Icons.volunteer_activism_rounded),
      ],
    );
  }

  Widget _cascadeSection() {
    final showToggle = !_isGiveaway;
    final mustPickOrg = _isGiveaway || _cascadeEnabled;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isGiveaway ? 'Toa kwa shirika' : 'Tuma mabaki kwa shirika',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    Text(
                      _isGiveaway
                          ? 'Chakula chote kinaenda kwa shirika la wenye uhitaji'
                          : 'Yasiyouzwa baada ya muda wa kuchukua yatatumwa moja kwa moja',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                  ],
                ),
              ),
              if (showToggle)
                Switch(
                  value: _cascadeEnabled,
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() {
                            _cascadeEnabled = v;
                            if (!v) _cascadeOrgId = null;
                          }),
                  activeThumbColor: _kAccent,
                ),
            ],
          ),
          if (mustPickOrg) ...[
            const SizedBox(height: 12),
            if (_orgsLoading && _orgs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                  ),
                ),
              )
            else if (_orgsLoaded && _orgs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: _kSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hakuna shirika lililothibitishwa karibu nawe',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: _orgsLoading ? null : _loadOrgs,
                      child: const Text('Jaribu tena'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                initialValue: _cascadeOrgId,
                isExpanded: true,
                decoration: _inputDecoration(hint: 'Chagua shirika'),
                items: _orgs
                    .map((o) => DropdownMenuItem<int>(
                          value: o.id,
                          child: Text(
                            o.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: _kPrimary),
                          ),
                        ))
                    .toList(),
                onChanged: _submitting ? null : (v) => setState(() => _cascadeOrgId = v),
              ),
          ],
        ],
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
                  Icon(Icons.add_a_photo_rounded, size: 36, color: _kSecondary),
                  SizedBox(height: 8),
                  Text(
                    'Ongeza picha ya chakula',
                    style: TextStyle(color: _kSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_photoFile!, fit: BoxFit.cover),
                    if (_uploading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                    if (_uploadedPhotoUrl != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✓ Imepakiwa',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _pickerRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _submitting ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _kSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String sw, String en) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(sw, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(width: 6),
        Text(en, style: const TextStyle(fontSize: 11, color: _kSecondary)),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
      filled: true,
      fillColor: _kCardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPrimary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _tagChip(_DietaryTag tag) {
    final selected = _selectedTags.contains(tag.key);
    return FilterChip(
      label: Text(tag.labelSw, style: TextStyle(fontSize: 12, color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      showCheckmark: false,
      onSelected: _submitting
          ? null
          : (v) {
              setState(() {
                if (v) {
                  _selectedTags.add(tag.key);
                } else {
                  _selectedTags.remove(tag.key);
                }
              });
            },
      backgroundColor: _kCardBg,
      selectedColor: _kPrimary,
      side: BorderSide(color: _kPrimary.withValues(alpha: selected ? 0 : 0.12)),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitting || _uploading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Chapisha', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _DietaryTag {
  final String key;
  final String labelSw;
  const _DietaryTag({required this.key, required this.labelSw});
}
