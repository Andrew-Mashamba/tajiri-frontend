import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/partner_skill_persona.dart';
import '../models/tajirika_models.dart';
import '../services/partner_skill_persona_service.dart';
import '../services/tajirika_service.dart';
import 'skill_persona_page.dart';

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
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Spec §13.5 — partner-side skill registry hub.
class ManageSkillsPage extends StatefulWidget {
  final int userId;
  /// Partner's registered skills (from tajirika_partners.skills) so we can
  /// resolve enum metadata (icon, label) for skills not yet customized.
  final List<SkillCategory> registeredSkills;

  const ManageSkillsPage({
    super.key,
    required this.userId,
    this.registeredSkills = const [],
  });

  @override
  State<ManageSkillsPage> createState() => _ManageSkillsPageState();
}

class _ManageSkillsPageState extends State<ManageSkillsPage> {
  bool _loading = true;
  String? _error;
  List<PartnerSkillPersona> _personas = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await PartnerSkillPersonaService.list(partnerUserId: widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _personas = res.items;
      } else {
        _error = res.message ?? 'Failed';
      }
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  SkillCategory? _resolveEnum(String key) {
    for (final s in widget.registeredSkills) {
      if (s.name == key) return s;
    }
    return SkillCategory.fromString(key);
  }

  Future<void> _open(PartnerSkillPersona p) async {
    final result = await Navigator.push<PartnerSkillPersona?>(
      context,
      MaterialPageRoute(
        builder: (_) => SkillPersonaPage(
          userId: widget.userId,
          skillCategory: p.skillCategory,
          skillEnum: _resolveEnum(p.skillCategory),
          initial: p,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) _load();
  }

  Future<void> _showActionsMenu(PartnerSkillPersona p) async {
    final canResume = p.status == SkillPersonaStatus.paused;
    final canPause = p.status == SkillPersonaStatus.active;
    final action = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canPause)
              ListTile(
                leading: const Icon(Icons.pause_circle_outline_rounded),
                title: Text(_isSwahili ? 'Sitisha' : 'Pause'),
                subtitle: Text(_isSwahili
                    ? 'Wateja hawataona ujuzi huu kwenye tafuta'
                    : 'Hides from customer search'),
                onTap: () => Navigator.pop(context, 'pause'),
              ),
            if (canResume)
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: Text(_isSwahili ? 'Endelea' : 'Resume'),
                onTap: () => Navigator.pop(context, 'resume'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB71C1C)),
              title: Text(_isSwahili ? 'Ondoa' : 'Remove',
                  style: const TextStyle(color: Color(0xFFB71C1C))),
              subtitle: Text(_isSwahili
                  ? 'Itashindwa ikiwa una oda hai'
                  : 'Fails if you have active orders'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;

    if (action == 'pause') {
      final res = await PartnerSkillPersonaService.pause(
        partnerUserId: widget.userId,
        skillCategory: p.skillCategory,
        actingUserId: widget.userId,
      );
      _toast(res.success ? (_isSwahili ? 'Imesimamishwa' : 'Paused') : (res.message ?? 'Failed'));
      if (res.success) _load();
    } else if (action == 'resume') {
      final res = await PartnerSkillPersonaService.resume(
        partnerUserId: widget.userId,
        skillCategory: p.skillCategory,
        actingUserId: widget.userId,
      );
      _toast(res.success ? (_isSwahili ? 'Imeendelea' : 'Resumed') : (res.message ?? 'Failed'));
      if (res.success) _load();
    } else if (action == 'remove') {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_isSwahili ? 'Ondoa ujuzi huu?' : 'Remove this skill?'),
          content: Text(_isSwahili
              ? 'Itaondolewa kwenye wasifu wako wa hadhara. Historia ya oda itabaki.'
              : 'It will disappear from your public profile. Order history is preserved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Funga' : 'Close'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
              ),
              child: Text(_isSwahili ? 'Ondoa' : 'Remove'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final res = await PartnerSkillPersonaService.remove(
        partnerUserId: widget.userId,
        skillCategory: p.skillCategory,
        actingUserId: widget.userId,
      );
      if (res.success) {
        _toast(_isSwahili ? 'Imeondolewa' : 'Removed');
        _load();
      } else {
        _toast(res.message ?? 'Failed');
      }
    }
  }

  /// Spec line 1218 — full add-a-skill flow: searchable picker grouped by
  /// cluster → register on `tajirika_partners.skills` via PUT /partners/me →
  /// open SkillPersonaPage so the partner can customize display name/photo
  /// before the persona is published.
  Future<void> _openAddSkillFlow() async {
    final registered = _registeredSkillKeys();
    final candidates = SkillCategory.values
        .where((s) => !registered.contains(s.name))
        .toList();
    if (candidates.isEmpty) {
      _toast(_isSwahili
          ? 'Tayari umesajili ujuzi wote unaopatikana'
          : 'You have already registered every available skill');
      return;
    }
    final picked = await showModalBottomSheet<SkillCategory?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddSkillPicker(
        candidates: candidates,
        isSwahili: _isSwahili,
      ),
    );
    if (picked == null || !mounted) return;
    await _registerSkill(picked);
  }

  Set<String> _registeredSkillKeys() {
    final set = <String>{};
    for (final s in widget.registeredSkills) {
      set.add(s.name);
    }
    for (final p in _personas) {
      set.add(p.skillCategory);
    }
    return set;
  }

  Future<void> _registerSkill(SkillCategory skill) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) {
      _toast(_isSwahili ? 'Sijaingia' : 'Not signed in');
      return;
    }
    final updatedSkills = <String>{
      ...widget.registeredSkills.map((s) => s.name),
      ..._personas.map((p) => p.skillCategory),
      skill.name,
    }.toList();
    final res = await TajirikaService.updatePartnerProfile(
      token,
      widget.userId,
      {'skills': updatedSkills},
    );
    if (!mounted) return;
    if (!res.success) {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
      return;
    }
    // Now open the persona customization page so display name/photo land
    // before the customer-visible profile flips on.
    final regulated = _kRegulatedSkills.contains(skill);
    if (regulated) {
      _toast(_isSwahili
          ? 'Itahitajika cheti — itasubiri uhakiki'
          : 'A credential will be required — pending verification');
    }
    final created = await Navigator.push<PartnerSkillPersona?>(
      context,
      MaterialPageRoute(
        builder: (_) => SkillPersonaPage(
          userId: widget.userId,
          skillCategory: skill.name,
          skillEnum: skill,
        ),
      ),
    );
    if (!mounted) return;
    if (created != null || regulated) _load();
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
          _isSwahili ? 'Ujuzi Wangu' : 'My Skills',
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
              : _personas.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: _personas.length,
                        itemBuilder: (_, i) => _personaRow(_personas[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSkillFlow,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_isSwahili ? 'Ongeza Ujuzi' : 'Add Skill'),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_outlined, size: 56, color: _kMuted),
            const SizedBox(height: 12),
            Text(_isSwahili ? 'Hakuna ujuzi bado' : 'No skills yet',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 6),
            Text(
              _isSwahili
                  ? 'Sajili ujuzi wa kwanza kwenye Wasifu wa Tajirika.'
                  : 'Register your first skill from your Tajirika profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personaRow(PartnerSkillPersona p) {
    final skillEnum = _resolveEnum(p.skillCategory);
    final icon = skillEnum?.icon ?? Icons.work_rounded;
    final label = skillEnum != null
        ? (_isSwahili ? skillEnum.labelSwahili : skillEnum.label)
        : p.skillCategory;
    final (badgeBg, badgeFg) = _statusColors(p.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _open(p),
        onLongPress: () => _showActionsMenu(p),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.displayName?.isNotEmpty == true ? p.displayName! : label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isSwahili ? p.status.labelSwahili : p.status.label,
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700, color: badgeFg),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: _kMuted),
                    ),
                    if (p.hasPricingBand) ...[
                      const SizedBox(height: 4),
                      Text(
                        'TZS ${NumberFormat('#,##0', 'en_US').format(p.pricingBandLowTzs)}–${NumberFormat('#,##0', 'en_US').format(p.pricingBandHighTzs)}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                    ],
                    if (p.isDefault) ...[
                      const SizedBox(height: 4),
                      Text(
                        _isSwahili ? 'Bonyeza kuhariri wasifu' : 'Tap to customize',
                        style: const TextStyle(
                            fontSize: 10, color: _kMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: _kMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _statusColors(SkillPersonaStatus s) {
    switch (s) {
      case SkillPersonaStatus.active:
        return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20));
      case SkillPersonaStatus.paused:
        return (const Color(0xFFFFF8E1), const Color(0xFFE65100));
      case SkillPersonaStatus.pendingVerification:
        return (const Color(0xFFE3F2FD), const Color(0xFF0D47A1));
      case SkillPersonaStatus.rejected:
        return (const Color(0xFFFFEBEE), const Color(0xFFB71C1C));
    }
  }
}

class _AddSkillPicker extends StatefulWidget {
  final List<SkillCategory> candidates;
  final bool isSwahili;
  const _AddSkillPicker({required this.candidates, required this.isSwahili});

  @override
  State<_AddSkillPicker> createState() => _AddSkillPickerState();
}

class _AddSkillPickerState extends State<_AddSkillPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Cluster grouping per `tajirika_models.dart` enum comments.
  String _cluster(SkillCategory s) {
    switch (s) {
      case SkillCategory.plumbing:
      case SkillCategory.electrical:
      case SkillCategory.carpentry:
      case SkillCategory.painting:
      case SkillCategory.welding:
      case SkillCategory.masonry:
      case SkillCategory.roofing:
      case SkillCategory.tiling:
      case SkillCategory.solarInstallation:
        return widget.isSwahili ? 'Mafundi' : 'Trades';
      case SkillCategory.autoMechanic:
      case SkillCategory.autoElectrician:
      case SkillCategory.panelBeating:
      case SkillCategory.sprayPainting:
        return widget.isSwahili ? 'Magari' : 'Auto';
      case SkillCategory.hairstyling:
      case SkillCategory.barbering:
      case SkillCategory.nailTechnician:
      case SkillCategory.skincare:
      case SkillCategory.makeup:
        return widget.isSwahili ? 'Urembo' : 'Beauty & Wellness';
      case SkillCategory.legal:
      case SkillCategory.medical:
      case SkillCategory.nursing:
      case SkillCategory.pharmacy:
      case SkillCategory.accounting:
      case SkillCategory.taxAdvisory:
        return widget.isSwahili ? 'Wataalamu' : 'Professional';
      case SkillCategory.realEstate:
      case SkillCategory.propertyManagement:
      case SkillCategory.homeInspection:
      case SkillCategory.interiorDesign:
        return widget.isSwahili ? 'Mali' : 'Property';
      case SkillCategory.personalTraining:
      case SkillCategory.nutrition:
      case SkillCategory.cooking:
      case SkillCategory.catering:
      case SkillCategory.baking:
        return widget.isSwahili ? 'Afya na Chakula' : 'Fitness & Food';
      case SkillCategory.eventPlanning:
      case SkillCategory.photography:
      case SkillCategory.videography:
      case SkillCategory.djing:
      case SkillCategory.mc:
        return widget.isSwahili ? 'Matukio' : 'Events & Creative';
      case SkillCategory.tourGuide:
      case SkillCategory.travelAgent:
      case SkillCategory.safariOperator:
        return widget.isSwahili ? 'Safari' : 'Travel & Transport';
      case SkillCategory.businessConsulting:
      case SkillCategory.hrConsulting:
      case SkillCategory.careerCoaching:
        return widget.isSwahili ? 'Biashara' : 'Business';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    final filtered = widget.candidates.where((s) {
      if (_query.isEmpty) return true;
      final lab = sw ? s.labelSwahili : s.label;
      return lab.toLowerCase().contains(_query.toLowerCase()) ||
          s.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    final grouped = <String, List<SkillCategory>>{};
    for (final s in filtered) {
      grouped.putIfAbsent(_cluster(s), () => []).add(s);
    }
    final clusters = grouped.keys.toList()..sort();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              sw ? 'Ongeza Ujuzi' : 'Add Skill',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: sw ? 'Tafuta ujuzi...' : 'Search skills...',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        sw ? 'Hakuna ujuzi unaolingana' : 'No matching skills',
                        style: const TextStyle(color: _kMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: clusters.fold<int>(
                          0, (sum, c) => sum + 1 + grouped[c]!.length),
                      itemBuilder: (_, idx) {
                        var i = idx;
                        for (final cluster in clusters) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                              child: Text(
                                cluster.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kMuted,
                                    letterSpacing: 0.5),
                              ),
                            );
                          }
                          i--;
                          final items = grouped[cluster]!;
                          if (i < items.length) {
                            final s = items[i];
                            final regulated = _kRegulatedSkills.contains(s);
                            return ListTile(
                              leading: Icon(s.icon, color: _kPrimary),
                              title: Text(sw ? s.labelSwahili : s.label),
                              subtitle: regulated
                                  ? Text(
                                      sw
                                          ? 'Inahitaji cheti'
                                          : 'Credential required',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFE65100),
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.pop(context, s),
                            );
                          }
                          i -= items.length;
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
