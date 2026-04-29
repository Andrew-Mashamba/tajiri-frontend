import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../housing/models/property_listing.dart';
import '../../housing/services/property_listing_service.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);

/// Partner-facing property listing form (spec §9 line 882).
/// Doubles as edit form: pass [existing] to load values + PATCH on submit.
class PostPropertyListingPage extends StatefulWidget {
  final int userId;
  final int? partnerId;
  final PropertyListing? existing;

  const PostPropertyListingPage({
    super.key,
    required this.userId,
    this.partnerId,
    this.existing,
  });

  @override
  State<PostPropertyListingPage> createState() => _PostPropertyListingPageState();
}

class _PostPropertyListingPageState extends State<PostPropertyListingPage> {
  int _step = 0;

  ListingKind _kind = ListingKind.sale;
  PropertyType _type = PropertyType.house;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  PriceFrequency _frequency = PriceFrequency.monthly;

  final _regionCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();

  final _bedroomsCtrl = TextEditingController();
  final _bathroomsCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _plotCtrl = TextEditingController();

  static const _knownAmenities = <String>[
    'parking', 'garden', 'security', 'water_tank', 'generator',
    'furnished', 'wifi', 'pool', 'gym', 'air_conditioning',
  ];
  final Set<String> _amenities = <String>{};

  final List<String> _photoPaths = []; // server-side relative URLs (after upload)
  bool _uploadingPhoto = false;

  bool _submitting = false;
  String? _submitError;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _kind = e.listingKind;
      _type = e.propertyType;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _priceCtrl.text = e.priceTzs.toString();
      if (e.priceFrequency != null) _frequency = e.priceFrequency!;
      _regionCtrl.text = e.region ?? '';
      _districtCtrl.text = e.district ?? '';
      _wardCtrl.text = e.ward ?? '';
      _streetCtrl.text = e.street ?? '';
      if (e.bedrooms != null) _bedroomsCtrl.text = '${e.bedrooms}';
      if (e.bathrooms != null) _bathroomsCtrl.text = '${e.bathrooms}';
      if (e.areaSqm != null) _areaCtrl.text = '${e.areaSqm}';
      if (e.plotSizeSqm != null) _plotCtrl.text = '${e.plotSizeSqm}';
      _amenities.addAll(e.amenities);
      _photoPaths.addAll(e.photos);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _regionCtrl.dispose();
    _districtCtrl.dispose();
    _wardCtrl.dispose();
    _streetCtrl.dispose();
    _bedroomsCtrl.dispose();
    _bathroomsCtrl.dispose();
    _areaCtrl.dispose();
    _plotCtrl.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pickPhoto() async {
    if (_photoPaths.length >= 12) {
      _toast(_isSwahili ? 'Picha 12 ndio kikomo' : 'Maximum 12 photos');
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    final res = await PropertyListingService.uploadPhoto(
      userId: widget.userId,
      file: File(picked.path),
    );
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (res.success && res.url != null) {
      setState(() => _photoPaths.add(res.url!));
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Upload failed'));
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _toast(_isSwahili ? 'Andika kichwa' : 'Enter a title');
      return;
    }
    if (_descCtrl.text.trim().length < 30) {
      _toast(_isSwahili ? 'Eleza vizuri (≥30)' : 'Describe (≥30 chars)');
      return;
    }
    final price = int.tryParse(_priceCtrl.text.replaceAll(',', '').trim());
    if (price == null || price <= 0) {
      _toast(_isSwahili ? 'Andika bei' : 'Enter price');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    PropertyListingResult res;
    if (_isEdit) {
      res = await PropertyListingService.update(
        id: widget.existing!.id,
        userId: widget.userId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        listingKind: _kind,
        propertyType: _type,
        region: _regionCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        ward: _wardCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        priceTzs: price,
        priceFrequency: _kind == ListingKind.rent ? _frequency : null,
        bedrooms: int.tryParse(_bedroomsCtrl.text.trim()),
        bathrooms: int.tryParse(_bathroomsCtrl.text.trim()),
        areaSqm: int.tryParse(_areaCtrl.text.trim()),
        plotSizeSqm: int.tryParse(_plotCtrl.text.trim()),
        amenities: _amenities.toList(),
        photos: _photoPaths,
      );
    } else {
      res = await PropertyListingService.create(
        userId: widget.userId,
        partnerId: widget.partnerId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        listingKind: _kind,
        propertyType: _type,
        region: _regionCtrl.text.trim().isEmpty ? null : _regionCtrl.text.trim(),
        district: _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
        ward: _wardCtrl.text.trim().isEmpty ? null : _wardCtrl.text.trim(),
        street: _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
        priceTzs: price,
        priceFrequency: _kind == ListingKind.rent ? _frequency : null,
        bedrooms: int.tryParse(_bedroomsCtrl.text.trim()),
        bathrooms: int.tryParse(_bathroomsCtrl.text.trim()),
        areaSqm: int.tryParse(_areaCtrl.text.trim()),
        plotSizeSqm: int.tryParse(_plotCtrl.text.trim()),
        amenities: _amenities.toList(),
        photos: _photoPaths,
      );
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.listing != null) {
      _toast(_isEdit
          ? (_isSwahili ? 'Imehifadhiwa' : 'Saved')
          : (_isSwahili ? 'Tangazo limewekwa' : 'Listing posted'));
      Navigator.of(context).pop(res.listing);
    } else {
      setState(() => _submitError = res.message ?? 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isEdit
              ? (_isSwahili ? 'Hariri Tangazo' : 'Edit Listing')
              : (_isSwahili ? 'Tangaza Mali' : 'Post Listing'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stepper(
        currentStep: _step,
        type: StepperType.vertical,
        controlsBuilder: (ctx, details) {
          final isLast = _step >= 5;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: _submitting ? null : details.onStepCancel,
                    child: Text(_isSwahili ? 'Rudi' : 'Back'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : (isLast ? _submit : details.onStepContinue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isLast
                      ? (_isEdit
                          ? (_isSwahili ? 'Hifadhi' : 'Save')
                          : (_isSwahili ? 'Chapisha' : 'Publish'))
                      : (_isSwahili ? 'Endelea' : 'Continue')),
                ),
              ],
            ),
          );
        },
        onStepContinue: () {
          if (_step < 5) setState(() => _step++);
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step--);
        },
        steps: [
          _stepKindType(),
          _stepBasics(),
          _stepLocation(),
          _stepStats(),
          _stepAmenitiesPhotos(),
          _stepReview(),
        ],
      ),
    );
  }

  Step _stepKindType() {
    return Step(
      title: Text(_isSwahili ? 'Aina ya tangazo' : 'Listing kind'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: ListingKind.values.map((k) {
              final selected = _kind == k;
              return ChoiceChip(
                label: Text(_isSwahili ? k.labelSwahili : k.label),
                selected: selected,
                onSelected: (_) => setState(() => _kind = k),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(_isSwahili ? 'Aina ya mali' : 'Property type',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PropertyType.values.map((t) {
              final selected = _type == t;
              return ChoiceChip(
                avatar: Icon(t.icon, size: 16, color: selected ? Colors.white : _kPrimary),
                label: Text(_isSwahili ? t.labelSwahili : t.label),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Step _stepBasics() {
    return Step(
      title: Text(_isSwahili ? 'Maelezo' : 'Basics'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            maxLength: 255,
            decoration: _input(_isSwahili ? 'Kichwa' : 'Title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 4,
            maxLines: 10,
            maxLength: 5000,
            decoration: _input(_isSwahili
                ? 'Maelezo (≥30 herufi)'
                : 'Description (≥30 chars)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(_isSwahili ? 'Bei (TZS)' : 'Price (TZS)'),
                ),
              ),
              if (_kind == ListingKind.rent) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<PriceFrequency>(
                    initialValue: _frequency,
                    items: PriceFrequency.values
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(_isSwahili ? f.labelSwahili : f.label),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _frequency = v ?? PriceFrequency.monthly),
                    decoration: _input(_isSwahili ? 'Mara' : 'Per'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Step _stepLocation() {
    return Step(
      title: Text(_isSwahili ? 'Mahali' : 'Location'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _regionCtrl,
                  decoration: _input(_isSwahili ? 'Mkoa' : 'Region'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _districtCtrl,
                  decoration: _input(_isSwahili ? 'Wilaya' : 'District'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wardCtrl,
                  decoration: _input(_isSwahili ? 'Kata' : 'Ward'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _streetCtrl,
                  decoration: _input(_isSwahili ? 'Mtaa (hiari)' : 'Street (optional)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Step _stepStats() {
    return Step(
      title: Text(_isSwahili ? 'Vipimo' : 'Stats'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bedroomsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(_isSwahili ? 'Vyumba vya kulala' : 'Bedrooms'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _bathroomsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(_isSwahili ? 'Bafu' : 'Bathrooms'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _areaCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(_isSwahili ? 'Eneo (m²)' : 'Area (m²)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _plotCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(_isSwahili ? 'Kiwanja (m²)' : 'Plot (m²)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Step _stepAmenitiesPhotos() {
    return Step(
      title: Text(_isSwahili ? 'Vifaa na picha' : 'Amenities + photos'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _knownAmenities.map((a) {
              final selected = _amenities.contains(a);
              return FilterChip(
                label: Text(_amenityLabel(a)),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _amenities.add(a);
                  } else {
                    _amenities.remove(a);
                  }
                }),
                selectedColor: _kPrimary.withValues(alpha: 0.12),
                labelStyle: const TextStyle(fontSize: 11, color: _kPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _isSwahili
                      ? 'Picha (${_photoPaths.length}/12)'
                      : 'Photos (${_photoPaths.length}/12)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              TextButton.icon(
                onPressed: _uploadingPhoto || _photoPaths.length >= 12 ? null : _pickPhoto,
                icon: _uploadingPhoto
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_a_photo_rounded, size: 16),
                label: Text(_isSwahili ? 'Pakia' : 'Add'),
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
              ),
            ],
          ),
          if (_photoPaths.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                _isSwahili
                    ? 'Picha 4+ zinapendelewa katika utafutaji'
                    : '4+ original photos boost discovery ranking',
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photoPaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _photoTile(i, _photoPaths[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoTile(int index, String url) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            PropertyListing.resolvePhoto(url),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: _kPrimary.withValues(alpha: 0.06),
              child: const Icon(Icons.broken_image_rounded, color: _kMuted),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() => _photoPaths.removeAt(index)),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Step _stepReview() {
    return Step(
      title: Text(_isSwahili ? 'Hakiki' : 'Review'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(_isSwahili ? 'Aina' : 'Kind', _isSwahili ? _kind.labelSwahili : _kind.label),
          _kv(_isSwahili ? 'Mali' : 'Type', _isSwahili ? _type.labelSwahili : _type.label),
          _kv(_isSwahili ? 'Bei' : 'Price', 'TZS ${_priceCtrl.text}'),
          _kv(_isSwahili ? 'Picha' : 'Photos', '${_photoPaths.length}'),
          _kv(_isSwahili ? 'Vifaa' : 'Amenities', '${_amenities.length}'),
          if (_submitError != null) ...[
            const SizedBox(height: 8),
            Text(_submitError!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12)),
          ],
        ],
      ),
    );
  }

  String _amenityLabel(String key) {
    final swMap = <String, String>{
      'parking': 'Parking',
      'garden': 'Bustani',
      'security': 'Ulinzi',
      'water_tank': 'Tank ya maji',
      'generator': 'Generator',
      'furnished': 'Vyombo',
      'wifi': 'Wifi',
      'pool': 'Bwawa',
      'gym': 'Gym',
      'air_conditioning': 'AC',
    };
    final enMap = <String, String>{
      'parking': 'Parking',
      'garden': 'Garden',
      'security': 'Security',
      'water_tank': 'Water tank',
      'generator': 'Generator',
      'furnished': 'Furnished',
      'wifi': 'Wifi',
      'pool': 'Pool',
      'gym': 'Gym',
      'air_conditioning': 'AC',
    };
    return _isSwahili ? (swMap[key] ?? key) : (enMap[key] ?? key);
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(fontSize: 12, color: _kMuted))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary))),
        ],
      ),
    );
  }

  InputDecoration _input(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
      );
}
