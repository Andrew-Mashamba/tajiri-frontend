// lib/ambulance/pages/medical_profile_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';
import '../widgets/medical_id_card.dart';
import 'emergency_contacts_page.dart';
import 'insurance_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class MedicalProfilePage extends StatefulWidget {
  final int userId;
  const MedicalProfilePage({super.key, required this.userId});
  @override
  State<MedicalProfilePage> createState() => _MedicalProfilePageState();
}

class _MedicalProfilePageState extends State<MedicalProfilePage> {
  final AmbulanceService _service = AmbulanceService();
  MedicalProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  late final bool _isSwahili;

  String? _bloodType;
  final TextEditingController _allergyCtrl = TextEditingController();
  final TextEditingController _conditionCtrl = TextEditingController();
  final TextEditingController _medicationCtrl = TextEditingController();
  List<String> _allergies = [];
  List<String> _conditions = [];
  List<String> _medications = [];

  static const _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  @override
  void dispose() {
    _allergyCtrl.dispose();
    _conditionCtrl.dispose();
    _medicationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getMedicalProfile();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _profile = result.data;
          _bloodType = _profile!.bloodType;
          _allergies = List.from(_profile!.allergies);
          _conditions = List.from(_profile!.conditions);
          _medications = List.from(_profile!.medications);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final updated = MedicalProfile(
      id: _profile?.id ?? 0,
      userId: widget.userId,
      bloodType: _bloodType,
      allergies: _allergies,
      conditions: _conditions,
      medications: _medications,
      emergencyContacts: _profile?.emergencyContacts ?? [],
      insuranceProvider: _profile?.insuranceProvider,
      insurancePolicyNo: _profile?.insurancePolicyNo,
    );

    try {
      final result = await _service.updateMedicalProfile(updated);
      if (!mounted) return;
      setState(() => _isSaving = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(
                  _isSwahili ? 'Profaili imehifadhiwa!' : 'Profile saved!'),
              backgroundColor: _kPrimary),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa kuhifadhi' : 'Save failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  void _addItem(TextEditingController ctrl, List<String> list) {
    final val = ctrl.text.trim();
    if (val.isNotEmpty && !list.contains(val)) {
      setState(() => list.add(val));
      ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
            _isSwahili ? 'Profaili ya Afya' : 'Medical Profile',
            style: const TextStyle(
                color: _kPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : Text(_isSwahili ? 'Hifadhi' : 'Save',
                    style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medical ID Card preview
                  if (_profile != null)
                    MedicalIdCard(profile: _profile!, isSwahili: _isSwahili),
                  const SizedBox(height: 20),

                  // Blood type
                  Text(
                      _isSwahili ? 'Kundi la Damu' : 'Blood Type',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bloodTypes.map((bt) {
                      final selected = _bloodType == bt;
                      return ChoiceChip(
                        label: Text(bt,
                            style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : _kPrimary,
                                fontSize: 13)),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _bloodType = bt),
                        selectedColor: _kPrimary,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: selected
                                ? _kPrimary
                                : const Color(0xFFE0E0E0)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Allergies
                  _TagSection(
                    title: _isSwahili ? 'Mzio' : 'Allergies',
                    items: _allergies,
                    controller: _allergyCtrl,
                    hint: 'e.g. Penicillin',
                    onAdd: () =>
                        _addItem(_allergyCtrl, _allergies),
                    onRemove: (s) =>
                        setState(() => _allergies.remove(s)),
                  ),
                  const SizedBox(height: 20),

                  // Conditions
                  _TagSection(
                    title: _isSwahili
                        ? 'Hali za Kiafya'
                        : 'Medical Conditions',
                    items: _conditions,
                    controller: _conditionCtrl,
                    hint: 'e.g. Diabetes',
                    onAdd: () =>
                        _addItem(_conditionCtrl, _conditions),
                    onRemove: (s) =>
                        setState(() => _conditions.remove(s)),
                  ),
                  const SizedBox(height: 20),

                  // Medications
                  _TagSection(
                    title: _isSwahili
                        ? 'Dawa za Sasa'
                        : 'Current Medications',
                    items: _medications,
                    controller: _medicationCtrl,
                    hint: 'e.g. Metformin',
                    onAdd: () =>
                        _addItem(_medicationCtrl, _medications),
                    onRemove: (s) =>
                        setState(() => _medications.remove(s)),
                  ),
                  const SizedBox(height: 24),

                  // Quick links
                  const Divider(),
                  const SizedBox(height: 12),
                  _QuickLink(
                    icon: Icons.contacts_rounded,
                    label: _isSwahili
                        ? 'Mawasiliano ya Dharura'
                        : 'Emergency Contacts',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const EmergencyContactsPage())),
                  ),
                  const SizedBox(height: 8),
                  _QuickLink(
                    icon: Icons.shield_rounded,
                    label: _isSwahili ? 'Bima' : 'Insurance',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const InsurancePage())),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TagSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  final void Function(String) onRemove;
  const _TagSection({
    required this.title,
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
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onAdd(),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                      fontSize: 13, color: Color(0xFF666666)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.add_rounded, size: 20),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) {
              return Chip(
                label:
                    Text(item, style: const TextStyle(fontSize: 12)),
                deleteIcon:
                    const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => onRemove(item),
                backgroundColor: Colors.white,
                side:
                    const BorderSide(color: Color(0xFFE0E0E0)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF1A1A1A)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF666666)),
            ],
          ),
        ),
      ),
    );
  }
}
