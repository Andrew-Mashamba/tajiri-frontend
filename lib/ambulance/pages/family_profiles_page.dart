// lib/ambulance/pages/family_profiles_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';
import '../widgets/family_member_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);

class FamilyProfilesPage extends StatefulWidget {
  const FamilyProfilesPage({super.key});
  @override
  State<FamilyProfilesPage> createState() => _FamilyProfilesPageState();
}

class _FamilyProfilesPageState extends State<FamilyProfilesPage> {
  final AmbulanceService _service = AmbulanceService();
  List<FamilyProfile> _members = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getFamilyProfiles();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _members = result.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _addOrEditMember({FamilyProfile? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String relationship = existing?.relationship ??
        (_isSwahili ? 'Mke/Mume' : 'Spouse');
    String? bloodType = existing?.bloodType;
    List<String> allergies = List.from(existing?.allergies ?? []);
    List<String> conditions = List.from(existing?.conditions ?? []);
    List<String> medications = List.from(existing?.medications ?? []);
    final allergyCtrl = TextEditingController();
    final conditionCtrl = TextEditingController();
    final medicationCtrl = TextEditingController();

    final relationships = _isSwahili
        ? ['Mke/Mume', 'Mtoto', 'Mzazi', 'Ndugu', 'Kaka/Dada', 'Bibi/Babu']
        : ['Spouse', 'Child', 'Parent', 'Sibling', 'Brother/Sister', 'Grandparent'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null
              ? (_isSwahili ? 'Hariri Mwanafamilia' : 'Edit Family Member')
              : (_isSwahili ? 'Ongeza Mwanafamilia' : 'Add Family Member')),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: _isSwahili ? 'Jina' : 'Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: relationships.contains(relationship)
                        ? relationship
                        : relationships.first,
                    decoration: InputDecoration(
                      labelText: _isSwahili ? 'Uhusiano' : 'Relationship',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: relationships
                        .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => relationship = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Blood type
                  Text(
                    _isSwahili ? 'Kundi la Damu' : 'Blood Type',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _bloodTypes.map((bt) {
                      final selected = bloodType == bt;
                      return ChoiceChip(
                        label: Text(bt,
                            style: TextStyle(
                                color: selected ? Colors.white : _kPrimary,
                                fontSize: 12)),
                        selected: selected,
                        onSelected: (_) =>
                            setDialogState(() => bloodType = bt),
                        selectedColor: _kPrimary,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: selected
                                ? _kPrimary
                                : const Color(0xFFE0E0E0)),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Allergies
                  _DialogTagInput(
                    label: _isSwahili ? 'Mzio' : 'Allergies',
                    items: allergies,
                    controller: allergyCtrl,
                    hint: 'e.g. Penicillin',
                    onAdd: () {
                      final v = allergyCtrl.text.trim();
                      if (v.isNotEmpty && !allergies.contains(v)) {
                        setDialogState(() => allergies.add(v));
                        allergyCtrl.clear();
                      }
                    },
                    onRemove: (s) =>
                        setDialogState(() => allergies.remove(s)),
                  ),
                  const SizedBox(height: 12),

                  // Conditions
                  _DialogTagInput(
                    label: _isSwahili ? 'Hali za Kiafya' : 'Conditions',
                    items: conditions,
                    controller: conditionCtrl,
                    hint: 'e.g. Diabetes',
                    onAdd: () {
                      final v = conditionCtrl.text.trim();
                      if (v.isNotEmpty && !conditions.contains(v)) {
                        setDialogState(() => conditions.add(v));
                        conditionCtrl.clear();
                      }
                    },
                    onRemove: (s) =>
                        setDialogState(() => conditions.remove(s)),
                  ),
                  const SizedBox(height: 12),

                  // Medications
                  _DialogTagInput(
                    label: _isSwahili ? 'Dawa' : 'Medications',
                    items: medications,
                    controller: medicationCtrl,
                    hint: 'e.g. Metformin',
                    onAdd: () {
                      final v = medicationCtrl.text.trim();
                      if (v.isNotEmpty && !medications.contains(v)) {
                        setDialogState(() => medications.add(v));
                        medicationCtrl.clear();
                      }
                    },
                    onRemove: (s) =>
                        setDialogState(() => medications.remove(s)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Ghairi' : 'Cancel',
                  style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(_isSwahili ? 'Hifadhi' : 'Save'),
            ),
          ],
        ),
      ),
    );

    allergyCtrl.dispose();
    conditionCtrl.dispose();
    medicationCtrl.dispose();

    if (confirmed != true) {
      nameCtrl.dispose();
      return;
    }

    final name = nameCtrl.text.trim();
    nameCtrl.dispose();

    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _isSwahili ? 'Jina linahitajika' : 'Name is required')),
      );
      return;
    }

    final profile = FamilyProfile(
      name: name,
      relationship: relationship,
      bloodType: bloodType,
      allergies: allergies,
      conditions: conditions,
      medications: medications,
    );

    try {
      final result = existing?.id != null
          ? await _service.updateFamilyProfile(existing!.id!, profile)
          : await _service.addFamilyProfile(profile);
      if (!mounted) return;
      if (result.success) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isSwahili ? 'Imehifadhiwa' : 'Saved'),
              backgroundColor: _kPrimary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _deleteMember(FamilyProfile member) async {
    if (member.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Ondoa' : 'Remove'),
        content: Text(_isSwahili
            ? 'Una uhakika unataka kuondoa ${member.name}?'
            : 'Are you sure you want to remove ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            child: Text(_isSwahili ? 'Ondoa' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _service.deleteFamilyProfile(member.id!);
      if (!mounted) return;
      if (result.success) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isSwahili ? 'Imeondolewa' : 'Removed'),
              backgroundColor: _kPrimary),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Familia' : 'Family Profiles',
          style:
              const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: () => _addOrEditMember(),
              icon: const Icon(Icons.add_rounded, color: _kPrimary),
              tooltip: _isSwahili ? 'Ongeza' : 'Add',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.family_restroom_rounded,
                          size: 48, color: _kSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _isSwahili
                            ? 'Hakuna wanafamilia'
                            : 'No family members yet',
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _addOrEditMember(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                            _isSwahili ? 'Ongeza Kwanza' : 'Add First Member'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          minimumSize: const Size(180, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _members.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final m = _members[i];
                      return FamilyMemberCard(
                        member: m,
                        isSwahili: _isSwahili,
                        onTap: () => _addOrEditMember(existing: m),
                        onDelete: () => _deleteMember(m),
                      );
                    },
                  ),
                ),
      floatingActionButton: _members.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _addOrEditMember(),
              backgroundColor: _kPrimary,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _DialogTagInput extends StatelessWidget {
  final String label;
  final List<String> items;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  const _DialogTagInput({
    required this.label,
    required this.items,
    required this.controller,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kPrimary)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onAdd(),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontSize: 12, color: _kSecondary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 36,
              width: 36,
              child: IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: items
                .map((item) => Chip(
                      label: Text(item, style: const TextStyle(fontSize: 11)),
                      deleteIcon:
                          const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => onRemove(item),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
