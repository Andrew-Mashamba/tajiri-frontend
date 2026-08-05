import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/partner_product_service.dart';
import '../services/tajirika_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);

const int _kMaxPhotos = 6;
const int _kMinLeadHours = 1;
const int _kMaxLeadHours = 720;
const int _kMaxTitleLen = 80;
const int _kMaxDescLen = 500;

const List<_TagOption> _kGenericTags = [
  _TagOption('emergency', 'Dharura'),
  _TagOption('weekend', 'Wiki ya weekend'),
  _TagOption('night', 'Usiku'),
  _TagOption('home_visit', 'Nyumbani'),
  _TagOption('on_site', 'Site'),
  _TagOption('online', 'Mtandaoni'),
  _TagOption('warranty', 'Hakikisho'),
];

// Spec §1: hard dietary tag set (6 entries)
const List<_TagOption> _kFoodDietary = [
  _TagOption('halali', 'Halali'),
  _TagOption('vegan', 'Mboga tu / Vegan'),
  _TagOption('no_pork', 'Bila nyama ya nguruwe'),
  _TagOption('gluten_free', 'Bila gluten'),
  _TagOption('kid_portion', 'Kid-portion'),
  _TagOption('ugali_friendly', 'Ugali-friendly'),
];

// Spec §1: hair-type taxonomy (1A–4C + locs/braids/natural/relaxed)
const List<_TagOption> _kHairTypes = [
  _TagOption('1a', '1A'),
  _TagOption('1b', '1B'),
  _TagOption('1c', '1C'),
  _TagOption('2a', '2A'),
  _TagOption('2b', '2B'),
  _TagOption('2c', '2C'),
  _TagOption('3a', '3A'),
  _TagOption('3b', '3B'),
  _TagOption('3c', '3C'),
  _TagOption('4a', '4A'),
  _TagOption('4b', '4B'),
  _TagOption('4c', '4C'),
  _TagOption('locs', 'Locs'),
  _TagOption('braids', 'Braids'),
  _TagOption('natural', 'Natural'),
  _TagOption('relaxed', 'Relaxed'),
];

// Spec §1: per-skill suggested tags (cluster-aware; partner can add custom on top)
List<_TagOption> _suggestedTagsFor(SkillCategory? skill) {
  if (skill == null) return const [];
  switch (skill) {
    case SkillCategory.cooking:
    case SkillCategory.catering:
      return const [
        _TagOption('lunch', 'Chakula cha mchana'),
        _TagOption('dinner', 'Chakula cha jioni'),
        _TagOption('event', 'Hafla'),
        _TagOption('homemade', 'Nyumbani'),
        _TagOption('local_dish', 'Chakula cha asili'),
      ];
    case SkillCategory.baking:
      return const [
        _TagOption('cake', 'Keki'),
        _TagOption('birthday', 'Sherehe'),
        _TagOption('wedding', 'Harusi'),
        _TagOption('chocolate', 'Chocolate'),
        _TagOption('vanilla', 'Vanilla'),
      ];
    case SkillCategory.carpentry:
      return const [
        _TagOption('door', 'Mlango'),
        _TagOption('table', 'Meza'),
        _TagOption('bed', 'Kitanda'),
        _TagOption('wardrobe', 'Kabati'),
        _TagOption('mahogany', 'Mahogany'),
        _TagOption('oak', 'Oak'),
      ];
    case SkillCategory.plumbing:
      return const [
        _TagOption('leak_fix', 'Kuziba bomba'),
        _TagOption('pipe_install', 'Ufungaji bomba'),
        _TagOption('water_heater', 'Hita ya maji'),
        _TagOption('drainage', 'Mfereji'),
      ];
    case SkillCategory.electrical:
      return const [
        _TagOption('wiring', 'Waya'),
        _TagOption('lighting', 'Taa'),
        _TagOption('socket', 'Soketi'),
        _TagOption('panel', 'Paneli'),
      ];
    case SkillCategory.welding:
    case SkillCategory.masonry:
    case SkillCategory.roofing:
    case SkillCategory.tiling:
    case SkillCategory.painting:
    case SkillCategory.solarInstallation:
      return const [
        _TagOption('repair', 'Kurekebisha'),
        _TagOption('installation', 'Ufungaji'),
        _TagOption('residential', 'Nyumbani'),
        _TagOption('commercial', 'Kibiashara'),
      ];
    case SkillCategory.autoMechanic:
    case SkillCategory.autoElectrician:
    case SkillCategory.panelBeating:
    case SkillCategory.sprayPainting:
      return const [
        _TagOption('oil_change', 'Mafuta'),
        _TagOption('brakes', 'Breki'),
        _TagOption('tires', 'Mawatu'),
        _TagOption('engine', 'Injini'),
        _TagOption('diagnostic', 'Uchunguzi'),
      ];
    case SkillCategory.hairstyling:
    case SkillCategory.barbering:
    case SkillCategory.nailTechnician:
      return const [
        _TagOption('haircut', 'Kunyoa'),
        _TagOption('braiding', 'Kusuka'),
        _TagOption('color', 'Rangi'),
        _TagOption('manicure', 'Manicure'),
        _TagOption('pedicure', 'Pedicure'),
      ];
    case SkillCategory.skincare:
    case SkillCategory.makeup:
      return const [
        _TagOption('facial', 'Facial'),
        _TagOption('bridal', 'Harusi'),
        _TagOption('cleansing', 'Usafi'),
        _TagOption('event_makeup', 'Mapambo ya hafla'),
      ];
    case SkillCategory.eventPlanning:
    case SkillCategory.photography:
    case SkillCategory.videography:
    case SkillCategory.djing:
    case SkillCategory.mc:
      return const [
        _TagOption('wedding', 'Harusi'),
        _TagOption('birthday', 'Sherehe'),
        _TagOption('corporate', 'Kibiashara'),
        _TagOption('full_day', 'Siku nzima'),
        _TagOption('half_day', 'Nusu siku'),
      ];
    case SkillCategory.personalTraining:
    case SkillCategory.nutrition:
      return const [
        _TagOption('one_on_one', 'Mtu mmoja'),
        _TagOption('group', 'Kikundi'),
        _TagOption('meal_plan', 'Mpango wa lishe'),
        _TagOption('weight_loss', 'Kupunguza uzito'),
      ];
    case SkillCategory.medical:
    case SkillCategory.nursing:
    case SkillCategory.pharmacy:
      return const [
        _TagOption('consultation', 'Ushauri'),
        _TagOption('home_visit', 'Nyumbani'),
        _TagOption('telehealth', 'Mtandaoni'),
      ];
    case SkillCategory.legal:
      return const [
        _TagOption('will', 'Wasia'),
        _TagOption('contract', 'Mkataba'),
        _TagOption('lease_review', 'Ukaguzi wa pango'),
        _TagOption('consult_30m', 'Ushauri 30min'),
      ];
    case SkillCategory.accounting:
    case SkillCategory.taxAdvisory:
    case SkillCategory.businessConsulting:
    case SkillCategory.hrConsulting:
    case SkillCategory.careerCoaching:
      return const [
        _TagOption('tax_filing', 'Kodi'),
        _TagOption('bookkeeping', 'Vitabu'),
        _TagOption('strategy', 'Mkakati'),
        _TagOption('coaching', 'Kocha'),
      ];
    case SkillCategory.realEstate:
    case SkillCategory.propertyManagement:
    case SkillCategory.homeInspection:
    case SkillCategory.interiorDesign:
      return const [
        _TagOption('inspection', 'Ukaguzi'),
        _TagOption('staging', 'Maandalizi'),
        _TagOption('renovation', 'Marekebisho'),
      ];
    case SkillCategory.tourGuide:
    case SkillCategory.travelAgent:
    case SkillCategory.safariOperator:
      return const [
        _TagOption('day_trip', 'Safari ya siku'),
        _TagOption('multi_day', 'Siku nyingi'),
        _TagOption('national_park', 'Hifadhi'),
        _TagOption('beach', 'Ufukweni'),
      ];
    case SkillCategory.deliveryDriver:
      return const [
        _TagOption('local', 'Karibu'),
        _TagOption('intercity', 'Mji-mji'),
        _TagOption('same_day', 'Siku hiyo hiyo'),
        _TagOption('bulky', 'Mzigo mkubwa'),
        _TagOption('refrigerated', 'Joto la baridi'),
      ];
  }
}

class PostPartnerProductPage extends StatefulWidget {
  final int userId;
  final PartnerProduct? existing;

  const PostPartnerProductPage({
    super.key,
    required this.userId,
    this.existing,
  });

  @override
  State<PostPartnerProductPage> createState() => _PostPartnerProductPageState();
}

class _PostPartnerProductPageState extends State<PostPartnerProductPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minQtyCtrl = TextEditingController(text: '1');
  final _amcVisitCtrl = TextEditingController(text: '4');
  final _amcMonthsCtrl = TextEditingController(text: '12');
  final _skuCtrl = TextEditingController();
  final _leadTimeCtrl = TextEditingController(text: '24');
  final _rebookCadenceCtrl = TextEditingController();
  final _customTagCtrl = TextEditingController();

  TajirikaPartner? _partner;
  bool _loadingPartner = true;
  String? _loadError;

  SkillCategory? _selectedSkill;
  PartnerProductKind _kind = PartnerProductKind.standard;
  String _mode = 'pickup_only';
  final Set<String> _genericTags = {};
  final Set<String> _dietaryTags = {};
  final Set<String> _hairTypes = {};
  final List<_VariantDraft> _variants = [];

  final List<File> _localPhotos = [];
  final List<String> _uploadedUrls = [];
  bool _uploading = false;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;
  String get _domain => _selectedSkill?.domainModule ?? '';
  bool get _isFood => _domain == 'food';
  bool get _isHair => _domain == 'hair_nails';

  @override
  void initState() {
    super.initState();
    _loadPartner();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _priceCtrl.text = e.basePriceTzs.toString();
      _minQtyCtrl.text = e.minQuantity.toString();
      _leadTimeCtrl.text = e.leadTimeHours.toString();
      if (e.rebookCadenceDays != null) _rebookCadenceCtrl.text = '${e.rebookCadenceDays}';
      _mode = e.mode;
      _kind = e.kind;
      _selectedSkill = e.skillCategory;
      _genericTags.addAll(e.tags);
      _dietaryTags.addAll(e.dietaryTags);
      _hairTypes.addAll(e.hairTypes);
      _uploadedUrls.addAll(e.photos.map((p) => p.photoUrl));
      if (e.amcVisitCount != null) _amcVisitCtrl.text = '${e.amcVisitCount}';
      if (e.amcValidityMonths != null) _amcMonthsCtrl.text = '${e.amcValidityMonths}';
      if (e.catalogSkuCode != null) _skuCtrl.text = e.catalogSkuCode!;
      for (final v in e.variants) {
        _variants.add(_VariantDraft.from(v));
      }
    } else {
      // Spec line 40 — sticky last-skill memory. Re-pre-select the skill the
      // partner used for their previous post so they don't have to scroll the
      // long list every time.
      _restoreLastSkill();
    }
  }

  Future<void> _restoreLastSkill() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final last = storage.getString('last_partner_product_skill');
      if (last == null || last.isEmpty || !mounted) return;
      final resolved = SkillCategory.fromString(last);
      if (resolved != null) {
        setState(() => _selectedSkill = resolved);
      }
    } catch (_) {}
  }

  Future<void> _persistLastSkill(SkillCategory s) async {
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.setString('last_partner_product_skill', s.name);
    } catch (_) {}
  }

  Future<void> _loadPartner() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _loadingPartner = false;
          _loadError = 'Sijaingia';
        });
        return;
      }
      final res = await TajirikaService.getMyPartnerProfile(token, widget.userId);
      if (!mounted) return;
      setState(() {
        _loadingPartner = false;
        if (res.success && res.partner != null) {
          _partner = res.partner;
          if (_selectedSkill == null && res.partner!.skills.isNotEmpty) {
            _selectedSkill = res.partner!.skills.first;
          }
        } else {
          _loadError = res.message ?? 'Imeshindwa kupakia profaili';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPartner = false;
        _loadError = 'Kosa: $e';
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _minQtyCtrl.dispose();
    _amcVisitCtrl.dispose();
    _amcMonthsCtrl.dispose();
    _skuCtrl.dispose();
    _leadTimeCtrl.dispose();
    _rebookCadenceCtrl.dispose();
    _customTagCtrl.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
      final res = await PartnerProductService.uploadPhoto(
        userId: widget.userId,
        file: file,
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _localPhotos.remove(file);
      });
      if (res.success && (res.photoUrl ?? '').isNotEmpty) {
        setState(() => _uploadedUrls.add(res.photoUrl!));
      } else {
        _toast(res.message ?? 'Picha imeshindikana');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _toast('Kosa: $e');
    }
  }

  void _removePhoto(int i) {
    setState(() => _uploadedUrls.removeAt(i));
  }

  void _addVariant() {
    setState(() => _variants.add(_VariantDraft.empty()));
  }

  void _removeVariant(int i) {
    setState(() {
      _variants[i].dispose();
      _variants.removeAt(i);
    });
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final minQty = int.tryParse(_minQtyCtrl.text.trim()) ?? 1;
    final leadTimeHours = int.tryParse(_leadTimeCtrl.text.trim()) ?? 0;
    final rebookCadenceDays = int.tryParse(_rebookCadenceCtrl.text.trim());

    if (_selectedSkill == null) {
      _toast('Chagua aina ya huduma');
      return;
    }
    if (title.isEmpty) {
      _toast('Andika jina la huduma/bidhaa');
      return;
    }
    if (price <= 0) {
      _toast('Andika bei sahihi');
      return;
    }
    if (leadTimeHours < _kMinLeadHours || leadTimeHours > _kMaxLeadHours) {
      _toast('Muda wa kuandaa lazima uwe kati ya $_kMinLeadHours na $_kMaxLeadHours saa');
      return;
    }
    if (_uploadedUrls.isEmpty) {
      _toast('Ongeza picha angalau moja');
      return;
    }

    final variants = <PartnerProductVariant>[];
    for (var i = 0; i < _variants.length; i++) {
      final d = _variants[i];
      final lbl = d.labelSwCtrl.text.trim();
      final p = int.tryParse(d.priceCtrl.text.replaceAll(',', '').trim()) ?? 0;
      if (lbl.isEmpty || p <= 0) {
        _toast('Variant ya ${i + 1}: jaza jina na bei sahihi');
        return;
      }
      variants.add(PartnerProductVariant(
        id: 0,
        labelSwahili: lbl,
        labelEnglish: d.labelEnCtrl.text.trim().isEmpty ? null : d.labelEnCtrl.text.trim(),
        priceTzs: p,
        leadTimeHours: int.tryParse(d.leadCtrl.text.trim()),
        sortOrder: i,
        isActive: true,
      ));
    }

    int? amcVisitCount;
    int? amcValidityMonths;
    if (_kind == PartnerProductKind.amc) {
      amcVisitCount = int.tryParse(_amcVisitCtrl.text.trim());
      amcValidityMonths = int.tryParse(_amcMonthsCtrl.text.trim());
      if (amcVisitCount == null || amcVisitCount <= 0) {
        _toast('Idadi ya ziara za AMC si sahihi');
        return;
      }
      if (amcValidityMonths == null || amcValidityMonths <= 0) {
        _toast('Muda wa AMC (miezi) si sahihi');
        return;
      }
    }

    final isProductized = _kind == PartnerProductKind.productized;
    final sku = _skuCtrl.text.trim();

    setState(() => _submitting = true);

    final res = _isEdit
        ? await PartnerProductService.updateProduct(
            productId: widget.existing!.id,
            userId: widget.userId,
            title: title,
            description: _descCtrl.text.trim(),
            basePriceTzs: price,
            leadTimeHours: leadTimeHours,
            minQuantity: minQty,
            mode: _mode,
            kind: _kind,
            isProductized: isProductized,
            catalogSkuCode: isProductized && sku.isNotEmpty ? sku : null,
            tags: _genericTags.toList(),
            dietaryTags: _isFood ? _dietaryTags.toList() : const [],
            hairTypes: _isHair ? _hairTypes.toList() : const [],
            amcVisitCount: amcVisitCount,
            amcValidityMonths: amcValidityMonths,
            rebookCadenceDays: rebookCadenceDays,
            photos: _uploadedUrls,
            variants: variants,
          )
        : await PartnerProductService.createProduct(
            userId: widget.userId,
            skillCategory: _selectedSkill!.name,
            domain: _domain,
            kind: _kind,
            isProductized: isProductized,
            catalogSkuCode: isProductized && sku.isNotEmpty ? sku : null,
            title: title,
            description: _descCtrl.text.trim(),
            basePriceTzs: price,
            leadTimeHours: leadTimeHours,
            minQuantity: minQty,
            mode: _mode,
            tags: _genericTags.toList(),
            dietaryTags: _isFood ? _dietaryTags.toList() : const [],
            hairTypes: _isHair ? _hairTypes.toList() : const [],
            amcVisitCount: amcVisitCount,
            amcValidityMonths: amcValidityMonths,
            rebookCadenceDays: rebookCadenceDays,
            photos: _uploadedUrls,
            variants: variants,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.success && res.product != null) {
      _toast(_isEdit ? 'Imehifadhiwa' : 'Imechapishwa');
      // Spec line 40 — remember the skill so the next post defaults to it.
      if (_selectedSkill != null && !_isEdit) {
        await _persistLastSkill(_selectedSkill!);
      }
      if (!mounted) return;
      Navigator.pop(context, res.product);
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
              child: _loadingPartner
                  ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                  : _loadError != null
                      ? _buildError()
                      : _buildForm(),
            ),
            if (!_loadingPartner && _loadError == null) _buildSubmitBar(),
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
            icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _kPrimary),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              _isEdit ? 'Hariri huduma' : 'Tangaza huduma',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _loadError ?? 'Kosa',
          style: const TextStyle(color: _kSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _label('Aina ya huduma'),
        _skillSelector(),
        const SizedBox(height: 16),
        _label('Aina ya kifurushi'),
        _kindSelector(),
        if (_kind == PartnerProductKind.amc) ...[
          const SizedBox(height: 12),
          _amcFields(),
        ],
        if (_kind == PartnerProductKind.productized) ...[
          const SizedBox(height: 12),
          _label('SKU code (hiari)'),
          TextField(
            controller: _skuCtrl,
            decoration: _input(hint: 'Mfano: STD-OIL-CHANGE'),
          ),
        ],
        const SizedBox(height: 16),
        _photoGrid(),
        const SizedBox(height: 16),
        _label('Jina la huduma/bidhaa'),
        TextField(
          controller: _titleCtrl,
          maxLength: _kMaxTitleLen,
          decoration: _input(hint: 'Mfano: Kubadilisha mafuta ya gari'),
        ),
        const SizedBox(height: 8),
        _label('Maelezo'),
        TextField(
          controller: _descCtrl,
          minLines: 2,
          maxLines: 5,
          maxLength: _kMaxDescLen,
          decoration: _input(hint: 'Eleza huduma kwa undani...'),
        ),
        const SizedBox(height: 12),
        _label('Bei ya msingi (TZS)'),
        TextField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _input(hint: '50000'),
        ),
        const SizedBox(height: 12),
        _label('Idadi ya chini'),
        TextField(
          controller: _minQtyCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _input(hint: '1'),
        ),
        const SizedBox(height: 16),
        _label('Muda wa kuandaa (saa, $_kMinLeadHours–$_kMaxLeadHours)'),
        TextField(
          controller: _leadTimeCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _input(hint: '24'),
        ),
        const SizedBox(height: 16),
        _label('Rudia baada ya siku / Rebook after days'),
        TextField(
          controller: _rebookCadenceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _input(hint: '14').copyWith(
            helperText: 'Mfano: 14 siku baada ya huduma, mtumiaji atapata kumbusho kuweka miadi nyingine. / e.g. 14 days after service, customer gets a rebook reminder.',
            helperMaxLines: 3,
          ),
        ),
        const SizedBox(height: 16),
        _label('Njia ya kupata'),
        _modeSelector(),
        const SizedBox(height: 16),
        _label('Variants (vifurushi tofauti, hiari)'),
        _variantsEditor(),
        const SizedBox(height: 16),
        if (_selectedSkill != null) ...[
          _label('Lebo za ${_selectedSkill!.labelSwahili}'),
          _suggestedTagSelector(),
          const SizedBox(height: 12),
        ],
        _label('Lebo za jumla'),
        _genericTagSelector(),
        const SizedBox(height: 8),
        _customTagInput(),
        if (_isFood) ...[
          const SizedBox(height: 16),
          _label('Lebo za chakula'),
          _dietaryTagSelector(),
        ],
        if (_isHair) ...[
          const SizedBox(height: 16),
          _label('Aina za nywele'),
          _hairTypeSelector(),
        ],
      ],
    );
  }

  Widget _skillSelector() {
    final skills = _partner?.skills ?? const <SkillCategory>[];
    final pool = skills.isEmpty ? SkillCategory.values : skills;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pool.map((s) {
        final selected = _selectedSkill == s;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedSkill = s;
            _dietaryTags.clear();
            _hairTypes.clear();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? _kPrimary : _kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s.icon,
                    size: 14, color: selected ? Colors.white : _kSecondary),
                const SizedBox(width: 6),
                Text(
                  s.labelSwahili,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _kPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _kindSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PartnerProductKind.values.map((k) {
        final selected = _kind == k;
        return GestureDetector(
          onTap: () => setState(() => _kind = k),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? _kPrimary : _kBorder),
            ),
            child: Text(
              k.labelSwahili,
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

  Widget _amcFields() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Idadi ya ziara'),
              TextField(
                controller: _amcVisitCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _input(hint: '4'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Muda (miezi)'),
              TextField(
                controller: _amcMonthsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _input(hint: '12'),
              ),
            ],
          ),
        ),
      ],
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

  Widget _photoTile(String src, {bool isLocal = false, VoidCallback? onRemove}) {
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
                      errorBuilder: (_, _, _) => Container(
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
            const Positioned.fill(child: ColoredBox(color: Color(0x66000000))),
          if (isLocal)
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 28, color: _kSecondary),
            SizedBox(height: 4),
            Text('Ongeza picha', style: TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _modeSelector() {
    const opts = ['pickup_only', 'delivery_only', 'both', 'digital_only'];
    const labels = {
      'pickup_only': 'Kuchukua',
      'delivery_only': 'Kuletewa',
      'both': 'Zote',
      'digital_only': 'Kidijitali',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts.map((m) {
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
              labels[m]!,
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

  Widget _variantsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _variants.length; i++) ...[
          _variantRow(i, _variants[i]),
          const SizedBox(height: 8),
        ],
        TextButton.icon(
          onPressed: _addVariant,
          icon: const Icon(Icons.add_rounded, size: 16, color: _kPrimary),
          label: const Text('Ongeza variant',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
        ),
      ],
    );
  }

  Widget _variantRow(int i, _VariantDraft v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Variant ${i + 1}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
              ),
              GestureDetector(
                onTap: () => _removeVariant(i),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: _kSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: v.labelSwCtrl,
            decoration: _input(hint: 'Jina (Kiswahili) – mf. Standard'),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: v.labelEnCtrl,
            decoration: _input(hint: 'Jina (English, hiari)'),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: v.priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(hint: 'Bei (TZS)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: v.leadCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(hint: 'Lead (saa)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genericTagSelector() => _tagWrap(_kGenericTags, _genericTags);
  Widget _dietaryTagSelector() => _tagWrap(_kFoodDietary, _dietaryTags);
  Widget _hairTypeSelector() => _tagWrap(_kHairTypes, _hairTypes);
  Widget _suggestedTagSelector() =>
      _tagWrap(_suggestedTagsFor(_selectedSkill), _genericTags);

  Widget _customTagInput() {
    final added = _genericTags
        .where((k) =>
            !_kGenericTags.any((t) => t.key == k) &&
            !_suggestedTagsFor(_selectedSkill).any((t) => t.key == k))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTagCtrl,
                decoration: _input(hint: 'Ongeza lebo yako (mfano: bridal)'),
                onSubmitted: (_) => _addCustomTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_rounded, color: _kPrimary),
              onPressed: _addCustomTag,
            ),
          ],
        ),
        if (added.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: added.map((k) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(k,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _genericTags.remove(k)),
                      child: const Icon(Icons.close_rounded,
                          size: 12, color: _kSecondary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _addCustomTag() {
    final raw = _customTagCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    if (raw.isEmpty) return;
    setState(() {
      _genericTags.add(raw);
      _customTagCtrl.clear();
    });
  }

  Widget _tagWrap(List<_TagOption> opts, Set<String> selectedSet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts.map((t) {
        final selected = selectedSet.contains(t.key);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              selectedSet.remove(t.key);
            } else {
              selectedSet.add(t.key);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? _kPrimary.withValues(alpha: 0.08) : _kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? _kPrimary : _kBorder),
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
              fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
    );
  }

  InputDecoration _input({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _kCardBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  _isEdit ? 'Hifadhi mabadiliko' : 'Tangaza',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

class _VariantDraft {
  final TextEditingController labelSwCtrl;
  final TextEditingController labelEnCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController leadCtrl;

  _VariantDraft._(this.labelSwCtrl, this.labelEnCtrl, this.priceCtrl, this.leadCtrl);

  factory _VariantDraft.empty() => _VariantDraft._(
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      );

  factory _VariantDraft.from(PartnerProductVariant v) => _VariantDraft._(
        TextEditingController(text: v.labelSwahili),
        TextEditingController(text: v.labelEnglish ?? ''),
        TextEditingController(text: '${v.priceTzs}'),
        TextEditingController(text: v.leadTimeHours == null ? '' : '${v.leadTimeHours}'),
      );

  void dispose() {
    labelSwCtrl.dispose();
    labelEnCtrl.dispose();
    priceCtrl.dispose();
    leadCtrl.dispose();
  }
}
