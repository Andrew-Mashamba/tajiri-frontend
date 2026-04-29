import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/shop_category_picker.dart';
import '../models/biz_service_models.dart';
import '../services/biz_service_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);

class BizServiceFormPage extends StatefulWidget {
  final int businessId;
  final String token;
  final BusinessService? service;
  const BizServiceFormPage({super.key, required this.businessId,
      required this.token, this.service});

  @override
  State<BizServiceFormPage> createState() => _BizServiceFormPageState();
}

class _BizServiceFormPageState extends State<BizServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _categoryCtrl;

  ServicePricingType _pricingType = ServicePricingType.fixed;
  ServiceAvailability _availability = ServiceAvailability.available;
  String _durationUnit = 'min';
  String? _existingPhotoUrl;
  XFile? _newPhoto;
  int? _shopCategoryId;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isEditing => widget.service != null;

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      (_pricingType == ServicePricingType.quoted || _priceCtrl.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _priceCtrl = TextEditingController(
        text: s?.price != null ? s!.price!.toStringAsFixed(0) : '');
    _durationCtrl = TextEditingController(
        text: s?.durationMinutes != null ? s!.durationMinutes!.toString() : '');
    _categoryCtrl = TextEditingController(text: s?.category ?? '');
    if (s != null) {
      _pricingType = s.pricingType;
      _availability = s.availability;
      _existingPhotoUrl = s.photoUrl;
      _shopCategoryId = s.shopCategoryId;
    }
    _nameCtrl.addListener(() => setState(() {}));
    _priceCtrl.addListener(() => setState(() {}));
    _categoryCtrl.addListener(() => setState(() {}));
  }

  Future<void> _pickCategory() async {
    final sel = await ShopCategoryPicker.show(
      context,
      initialCategoryId: _shopCategoryId,
      showServicesOnly: true,
    );
    if (sel == null) return;
    setState(() {
      _shopCategoryId = sel.id;
      _categoryCtrl.text = sel.breadcrumb;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _durationCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() { _newPhoto = picked; _existingPhotoUrl = null; });
  }

  int? _durationToMinutes() {
    if (_durationCtrl.text.isEmpty) return null;
    final val = int.tryParse(_durationCtrl.text);
    if (val == null) return null;
    switch (_durationUnit) {
      case 'hr': return val * 60;
      case 'days': return val * 1440;
      default: return val;
    }
  }

  Future<void> _showPostSaveNudge() async {
    if (!mounted) return;
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final nav = Navigator.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
              const SizedBox(height: 8),
              Text(
                isSwahili
                    ? (_isEditing ? 'Huduma imesasishwa!' : 'Huduma imeongezwa!')
                    : (_isEditing ? 'Service updated!' : 'Service saved!'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                isSwahili ? 'Hatua Zifuatazo' : 'Next Steps',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded, color: _kPrimary),
                title: Text(isSwahili ? 'Weka Wakati wa Kazi' : 'Block Calendar'),
                subtitle: Text(isSwahili ? 'Onyesha siku unazofanya kazi' : 'Show days you are available'),
                onTap: () {
                  Navigator.pop(ctx);
                  nav.pushNamed('/calendar');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_rounded, color: _kPrimary),
                title: Text(isSwahili ? 'Weka Miadi' : 'Set up Appointments'),
                subtitle: Text(isSwahili ? 'Wacha wateja waweke miadi' : 'Let clients book time with you'),
                onTap: () {
                  Navigator.pop(ctx);
                  nav.pushNamed('/appointments');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined, color: _kPrimary),
                title: Text(isSwahili ? 'Weka Lengo la Mapato' : 'Set Revenue Goal'),
                subtitle: Text(isSwahili ? 'Fuatilia mapato ya huduma hii' : 'Track income from this service'),
                onTap: () {
                  Navigator.pop(ctx);
                  nav.pushNamed('/budget');
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pricingType != ServicePricingType.quoted && _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Weka bei ya huduma' : 'Enter a price for this service'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_newPhoto == null && _existingPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Ongeza picha — wateja wanaamini huduma zenye picha'
            : 'Add a photo — clients trust services with photos'),
        backgroundColor: Colors.orange.shade700,
      ));
    }
    setState(() => _saving = true);

    final service = BusinessService(
      id: widget.service?.id ?? 0,
      businessId: widget.businessId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      pricingType: _pricingType,
      price: _pricingType == ServicePricingType.quoted || _priceCtrl.text.isEmpty
          ? null : double.tryParse(_priceCtrl.text),
      availability: _availability,
      durationMinutes: _durationToMinutes(),
      shopCategoryId: _shopCategoryId,
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      photoUrl: _existingPhotoUrl,
    );

    final result = _isEditing
        ? await BizServiceService.updateService(
            widget.token, widget.businessId, service, _newPhoto)
        : await BizServiceService.createService(
            widget.token, widget.businessId, service, _newPhoto);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
      final becameAvailable = widget.service != null &&
          _availability == ServiceAvailability.available &&
          widget.service!.availability != ServiceAvailability.available;
      final becameUnavailable = widget.service != null &&
          _availability == ServiceAvailability.unavailable &&
          widget.service!.availability != ServiceAvailability.unavailable;

      if (becameUnavailable) {
        // Show dialog BEFORE pop so context is still valid
        final goToCalendar = await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text(isSwahili ? 'Zuia Tarehe kwenye Kalenda?' : 'Block these dates on Calendar?'),
            content: Text(isSwahili
                ? 'Ungependa kuzuia tarehe kwenye kalenda yako?'
                : 'Would you like to block off dates on your calendar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx, false),
                child: Text(isSwahili ? 'Hapana' : 'No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dCtx, true),
                child: Text(isSwahili ? 'Ndio' : 'Yes',
                    style: const TextStyle(color: _kPrimary)),
              ),
            ],
          ),
        );
        if (!mounted) return;
        final nav = Navigator.of(context);
        Navigator.pop(context, true);
        if (goToCalendar == true) nav.pushNamed('/calendar');
      } else if (becameAvailable) {
        // Capture messenger + navigator before pop
        final messenger = ScaffoldMessenger.of(context);
        final nav = Navigator.of(context);
        Navigator.pop(context, true);
        messenger.showSnackBar(SnackBar(
          content: Text(isSwahili
              ? 'Huduma inapatikana! Tuma post kumwambia wateja wako.'
              : 'Service is available! Share a post to let customers know.'),
          action: SnackBarAction(
            label: isSwahili ? 'Tuma' : 'Post',
            onPressed: () => nav.pushNamed('/create-post'),
          ),
          duration: const Duration(seconds: 5),
        ));
      } else {
        // Show nudge BEFORE pop; _showPostSaveNudge pops internally when done
        await _showPostSaveNudge();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? 'Failed'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(_isEditing
            ? (_isSwahili ? 'Hariri Huduma' : 'Edit Service')
            : (_isSwahili ? 'Ongeza Huduma' : 'Add Service'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))))
          else
            TextButton(
              onPressed: _canSave ? _save : null,
              child: Text(_isSwahili ? 'Hifadhi' : 'Save',
                  style: TextStyle(
                      color: _canSave ? _kPrimary : Colors.grey,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(_isSwahili ? 'Maelezo ya Msingi' : 'Basic Info'),
              _card(Column(children: [
                _field(_nameCtrl, _isSwahili ? 'Jina la huduma' : 'Service name', required: true),
                _buildCategoryPickerTile(),
                _field(_descCtrl, _isSwahili ? 'Maelezo' : 'Description', maxLines: 3),
              ])),

              _section(_isSwahili ? 'Bei' : 'Pricing'),
              _card(Column(children: [
                SegmentedButton<ServicePricingType>(
                  segments: [
                    ButtonSegment(value: ServicePricingType.fixed,
                        label: Text(_isSwahili ? 'Kawaida' : 'Fixed')),
                    ButtonSegment(value: ServicePricingType.hourly,
                        label: Text(_isSwahili ? 'Kwa Saa' : 'Per Hour')),
                    ButtonSegment(value: ServicePricingType.quoted,
                        label: Text(_isSwahili ? 'Makubaliano' : 'Quote')),
                  ],
                  selected: {_pricingType},
                  onSelectionChanged: (s) => setState(() => _pricingType = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected) ? _kPrimary : null),
                    foregroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected) ? Colors.white : _kPrimary),
                  ),
                ),
                if (_pricingType != ServicePricingType.quoted) ...[
                  const SizedBox(height: 12),
                  _field(
                    _priceCtrl,
                    _pricingType == ServicePricingType.hourly
                        ? (_isSwahili ? 'Kwa Saa' : 'Per hour')
                        : (_isSwahili ? 'Kwa Kazi' : 'Per job'),
                    keyboardType: TextInputType.number,
                    prefix: 'TZS ',
                  ),
                ],
              ])),

              _section(_isSwahili ? 'Picha' : 'Photo'),
              _card(_buildPhotoPicker()),

              _section(_isSwahili ? 'Maelezo Mengine' : 'Details'),
              _card(Column(children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _isSwahili ? 'Muda' : 'Duration',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          value: _durationUnit,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(value: 'min', child: Text(_isSwahili ? 'Dakika' : 'Min')),
                            DropdownMenuItem(value: 'hr', child: Text(_isSwahili ? 'Saa' : 'Hr')),
                            DropdownMenuItem(value: 'days', child: Text(_isSwahili ? 'Siku' : 'Days')),
                          ],
                          onChanged: (v) => setState(() => _durationUnit = v!),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(_isSwahili ? 'Upatikanaji' : 'Availability',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ServiceAvailability.values.map((a) => ChoiceChip(
                    label: Text(a.label(_isSwahili)),
                    selected: _availability == a,
                    selectedColor: a.color.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _availability = a),
                  )).toList(),
                ),
              ])),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final hasPhoto = _existingPhotoUrl != null || _newPhoto != null;
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Stack(fit: StackFit.expand, children: [
                if (_newPhoto != null)
                  Image.file(File(_newPhoto!.path), fit: BoxFit.cover)
                else
                  Image.network(_existingPhotoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                Positioned(top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  )),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 36),
                const SizedBox(height: 8),
                Text(_isSwahili ? 'Ongeza picha' : 'Add photo',
                    style: const TextStyle(color: Colors.grey)),
              ]),
      ),
    );
  }

  Widget _buildCategoryPickerTile() {
    final hasSelection = _shopCategoryId != null && _categoryCtrl.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickCategory,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.category_outlined, size: 20, color: _kSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isSwahili ? 'Jamii' : 'Category',
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      hasSelection
                          ? _categoryCtrl.text
                          : (_isSwahili ? 'Chagua jamii ya duka' : 'Select shop category'),
                      style: TextStyle(
                        fontSize: 14,
                        color: hasSelection ? _kPrimary : Colors.grey,
                        fontWeight: hasSelection ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasSelection)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    _shopCategoryId = null;
                    _categoryCtrl.text = '';
                  }),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: _kPrimary, letterSpacing: 0.5)),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1,
       TextInputType? keyboardType, String? prefix, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? (_isSwahili ? 'Hii inahitajika' : 'Required')
                : null
            : null,
      ),
    );
  }
}
