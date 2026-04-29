import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/partner_skill_persona.dart';
import '../models/tajirika_models.dart';
import '../services/partner_product_service.dart';
import '../services/partner_skill_persona_service.dart';
import '../services/tajirika_service.dart';

/// Spec line 1234 — these clusters require a regulated-credential upload
/// before the persona can flip from `pending_verification` → `active`.
const Set<SkillCategory> _kRegulatedSkills = {
  SkillCategory.legal,
  SkillCategory.medical,
  SkillCategory.nursing,
  SkillCategory.pharmacy,
  SkillCategory.accounting,
  SkillCategory.taxAdvisory,
};

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);

/// Spec §13.6 — per-skill identity overlay (display name, bio, pricing band,
/// auto-reply). Photo upload UI deferred to a follow-up; URL-based override
/// supported via the model + API for future image_picker wiring.
class SkillPersonaPage extends StatefulWidget {
  final int userId;
  final String skillCategory;
  final SkillCategory? skillEnum;
  /// Optional pre-loaded persona so the form opens without a fetch flash.
  final PartnerSkillPersona? initial;

  const SkillPersonaPage({
    super.key,
    required this.userId,
    required this.skillCategory,
    this.skillEnum,
    this.initial,
  });

  @override
  State<SkillPersonaPage> createState() => _SkillPersonaPageState();
}

class _SkillPersonaPageState extends State<SkillPersonaPage> {
  PartnerSkillPersona? _persona;
  bool _loading = false;
  bool _saving = false;
  bool _uploadingCredential = false;
  bool _uploadingPhoto = false;
  String? _profilePhotoUrl;
  String? _error;

  bool get _isRegulated =>
      widget.skillEnum != null && _kRegulatedSkills.contains(widget.skillEnum);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _lowCtrl;
  late final TextEditingController _highCtrl;
  late final TextEditingController _replyCtrl;
  late final TextEditingController _tagInputCtrl;
  /// Spec line 1228 — partner-locked suggested-tag list for this persona.
  /// Sent to backend via PATCH `tag_preset`.
  final List<String> _tagPreset = <String>[];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _lowCtrl = TextEditingController();
    _highCtrl = TextEditingController();
    _replyCtrl = TextEditingController();
    _tagInputCtrl = TextEditingController();
    if (widget.initial != null) {
      _persona = widget.initial;
      _hydrate(widget.initial!);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _lowCtrl.dispose();
    _highCtrl.dispose();
    _replyCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  void _hydrate(PartnerSkillPersona p) {
    _nameCtrl.text = p.displayName ?? '';
    _bioCtrl.text = p.bio ?? '';
    _lowCtrl.text = p.pricingBandLowTzs?.toString() ?? '';
    _highCtrl.text = p.pricingBandHighTzs?.toString() ?? '';
    _replyCtrl.text = p.autoReplyText ?? '';
    _profilePhotoUrl = p.profilePhotoUrl;
    _tagPreset
      ..clear()
      ..addAll(p.tagPreset ?? const <String>[]);
  }

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    final res = await PartnerProductService.uploadPhoto(
      userId: widget.userId,
      file: File(picked.path),
    );
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (res.success && (res.photoUrl ?? '').isNotEmpty) {
      setState(() => _profilePhotoUrl = res.photoUrl);
      _toast(_isSwahili ? 'Picha imepakuliwa' : 'Photo uploaded');
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
    }
  }

  Future<void> _uploadCredential() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingCredential = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _uploadingCredential = false);
      _toast(_isSwahili ? 'Sijaingia' : 'Not signed in');
      return;
    }
    final res = await TajirikaService.submitProfessionalLicense(
      token,
      widget.userId,
      // Backend stores `license_type` free-form on tajirika_partners; we tag
      // by skill so an admin reviewer knows which persona this credential
      // unlocks. (Multi-regulated-skill partners overwrite — limitation
      // tracked under F13.2 follow-up: needs partner_skill_credentials table.)
      widget.skillCategory,
      File(picked.path),
    );
    if (!mounted) return;
    setState(() => _uploadingCredential = false);
    if (res.success) {
      _toast(_isSwahili
          ? 'Cheti kimepokelewa — tunakihakiki'
          : 'Credential submitted — under review');
      _load();
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await PartnerSkillPersonaService.get(
      partnerUserId: widget.userId,
      skillCategory: widget.skillCategory,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success && res.persona != null) {
      _persona = res.persona;
      _hydrate(res.persona!);
    } else {
      _error = res.message ?? 'Failed';
    }
  }

  void _addTagFromInput() {
    final raw = _tagInputCtrl.text.trim();
    if (raw.isEmpty) return;
    final parts = raw
        .split(RegExp(r'[,\n]+'))
        .map((s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_'))
        .where((s) => s.isNotEmpty);
    setState(() {
      for (final p in parts) {
        if (!_tagPreset.contains(p)) _tagPreset.add(p);
      }
      _tagInputCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final res = await PartnerSkillPersonaService.upsert(
      partnerUserId: widget.userId,
      skillCategory: widget.skillCategory,
      actingUserId: widget.userId,
      displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      pricingBandLowTzs: int.tryParse(_lowCtrl.text.replaceAll(',', '').trim()),
      pricingBandHighTzs: int.tryParse(_highCtrl.text.replaceAll(',', '').trim()),
      autoReplyText: _replyCtrl.text.trim().isEmpty ? null : _replyCtrl.text.trim(),
      tagPreset: _tagPreset.isEmpty ? <String>[] : List.of(_tagPreset),
      profilePhotoUrl: _profilePhotoUrl,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imehifadhiwa' : 'Saved'),
      ));
      Navigator.of(context).pop(res.persona);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? 'Failed'),
      ));
    }
  }

  String get _skillLabel {
    if (widget.skillEnum != null) {
      return _isSwahili ? widget.skillEnum!.labelSwahili : widget.skillEnum!.label;
    }
    return widget.skillCategory;
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
          _isSwahili ? 'Wasifu wa $_skillLabel' : '$_skillLabel persona',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: _kMuted))),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_persona != null && _persona!.isDefault) _defaultHint(),
          _profilePhotoSection(),
          const SizedBox(height: 16),
          if (_isRegulated) _credentialSection(),
          _section(
            title: _isSwahili ? 'Jina la persona' : 'Display name',
            subtitle: _isSwahili
                ? 'Mfano: "Asha\'s Cakes 🎂" badala ya jina lako kamili'
                : 'e.g. "Asha\'s Cakes 🎂" instead of your full legal name',
            child: TextField(
              controller: _nameCtrl,
              maxLength: 128,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            title: _isSwahili ? 'Bio (hadi 200)' : 'Bio (200 char max)',
            child: TextField(
              controller: _bioCtrl,
              minLines: 2,
              maxLines: 5,
              maxLength: 200,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            title: _isSwahili ? 'Bei kawaida (TZS)' : 'Typical price band (TZS)',
            subtitle: _isSwahili
                ? 'Inaonyeshwa kwa wateja kwenye kadi ya tafuta'
                : 'Shown to customers on search cards',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lowCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _isSwahili ? 'Chini' : 'Low',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('—', style: TextStyle(color: _kMuted)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _highCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _isSwahili ? 'Juu' : 'High',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            title: _isSwahili ? 'Jibu la kwanza la moja kwa moja' : 'Auto-reply on first contact',
            subtitle: _isSwahili
                ? 'Mfano: "Habari! Asante kwa kupendezwa..."'
                : 'e.g. "Hi! Thanks for reaching out..."',
            child: TextField(
              controller: _replyCtrl,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            title: _isSwahili ? 'Lebo zilizoidhinishwa' : 'Locked tag preset',
            subtitle: _isSwahili
                ? 'Lebo zinazoonyeshwa kwa wateja wakati wanachuja huduma zako.'
                : 'Tags shown to customers when they filter your services.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _tagInputCtrl,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    hintText: _isSwahili
                        ? 'Mfano: kuni, mbao, milango'
                        : 'e.g. carpentry, doors, oak',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      tooltip: _isSwahili ? 'Ongeza' : 'Add',
                      onPressed: _addTagFromInput,
                    ),
                  ),
                  onSubmitted: (_) => _addTagFromInput(),
                ),
                if (_tagPreset.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tagPreset
                        .map((t) => InputChip(
                              label: Text(t),
                              onDeleted: () => setState(() => _tagPreset.remove(t)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(_isSwahili ? 'Hifadhi' : 'Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isSwahili
                ? 'Picha ya wasifu itaongezwa baadaye (image_picker integration follow-up)'
                : 'Profile photo upload arrives in a follow-up (image_picker wiring deferred)',
            style: const TextStyle(fontSize: 11, color: _kMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _profilePhotoSection() {
    final url = _profilePhotoUrl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: const Color(0xFFEEEEEE),
          backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty)
              ? const Icon(Icons.person_rounded, size: 36, color: _kMuted)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSwahili ? 'Picha ya wasifu' : 'Profile photo',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              Text(
                _isSwahili
                    ? 'Picha hii inaonyeshwa kwa ujuzi huu pekee.'
                    : 'Shown for this persona only.',
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _uploadingPhoto ? null : _uploadProfilePhoto,
                icon: _uploadingPhoto
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_camera_rounded, size: 16),
                label: Text(_isSwahili ? 'Badilisha' : 'Change'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(36),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _credentialSection() {
    final sw = _isSwahili;
    final status = _persona?.status;
    final isPending = status == SkillPersonaStatus.pendingVerification;
    final isRejected = status == SkillPersonaStatus.rejected;
    final (bg, fg, msg) = isRejected
        ? (
            const Color(0xFFFFEBEE),
            const Color(0xFFB71C1C),
            sw
                ? 'Cheti kimekataliwa — pakia upya'
                : 'Credential rejected — please re-upload',
          )
        : isPending
            ? (
                const Color(0xFFE3F2FD),
                const Color(0xFF0D47A1),
                sw
                    ? 'Cheti kinahakikiwa. Wasifu utawaka baada ya uthibitisho.'
                    : 'Credential under review. Profile activates after approval.',
              )
            : (
                const Color(0xFFFFF8E1),
                const Color(0xFFE65100),
                sw
                    ? 'Pakia cheti chako kuanzisha wasifu huu'
                    : 'Upload your credential to activate this persona',
              );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw ? 'Cheti cha mtaalamu' : 'Professional credential',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(msg, style: TextStyle(fontSize: 12, color: fg)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _uploadingCredential ? null : _uploadCredential,
            icon: _uploadingCredential
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file_rounded, size: 16),
            label: Text(isRejected
                ? (sw ? 'Pakia upya' : 'Re-upload')
                : (sw ? 'Pakia cheti' : 'Upload credential')),
            style: ElevatedButton.styleFrom(
              backgroundColor: fg,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultHint() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSwahili
                  ? 'Wasifu huu unatumia jina lako la kawaida na ikoni ya kawaida ya $_skillLabel. Hifadhi mabadiliko hapo chini.'
                  : 'This persona uses your default name and the $_skillLabel icon. Save below to override.',
              style: const TextStyle(fontSize: 12, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, String? subtitle, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
