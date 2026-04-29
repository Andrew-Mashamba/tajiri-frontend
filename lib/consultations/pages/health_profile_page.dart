import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/health_profile_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 720 — persistent customer health profile reused across every
/// medical/legal booking. Stores allergies, chronic conditions, past Rx,
/// lab uploads, insurance cards. Server upserts via PUT.
class HealthProfilePage extends StatefulWidget {
  final int userId;
  const HealthProfilePage({super.key, required this.userId});

  @override
  State<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends State<HealthProfilePage> {
  bool _loading = true;
  bool _saving = false;
  HealthProfile? _profile;
  final _allergyCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _allergyCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await HealthProfileService.show(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _profile = res;
    });
  }

  Future<void> _save() async {
    if (_profile == null) return;
    setState(() => _saving = true);
    final ok = await HealthProfileService.upsert(
      userId: widget.userId,
      allergies: _profile!.allergies,
      chronicConditions: _profile!.chronicConditions,
      pastPrescriptions: _profile!.pastPrescriptions,
      labUploads: _profile!.labUploads,
      insuranceCards: _profile!.insuranceCards,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (_isSwahili ? 'Imehifadhiwa' : 'Saved')
          : (_isSwahili ? 'Imeshindikana' : 'Failed')),
    ));
  }

  void _addAllergy() {
    final v = _allergyCtrl.text.trim();
    if (v.isEmpty || _profile == null) return;
    setState(() {
      _profile = HealthProfile(
        userId: _profile!.userId,
        allergies: [..._profile!.allergies, v],
        chronicConditions: _profile!.chronicConditions,
        pastPrescriptions: _profile!.pastPrescriptions,
        labUploads: _profile!.labUploads,
        insuranceCards: _profile!.insuranceCards,
      );
      _allergyCtrl.clear();
    });
  }

  void _removeAllergy(int idx) {
    if (_profile == null) return;
    final a = [..._profile!.allergies]..removeAt(idx);
    setState(() {
      _profile = HealthProfile(
        userId: _profile!.userId,
        allergies: a,
        chronicConditions: _profile!.chronicConditions,
        pastPrescriptions: _profile!.pastPrescriptions,
        labUploads: _profile!.labUploads,
        insuranceCards: _profile!.insuranceCards,
      );
    });
  }

  void _addCondition() {
    final v = _conditionCtrl.text.trim();
    if (v.isEmpty || _profile == null) return;
    setState(() {
      _profile = HealthProfile(
        userId: _profile!.userId,
        allergies: _profile!.allergies,
        chronicConditions: [..._profile!.chronicConditions, v],
        pastPrescriptions: _profile!.pastPrescriptions,
        labUploads: _profile!.labUploads,
        insuranceCards: _profile!.insuranceCards,
      );
      _conditionCtrl.clear();
    });
  }

  void _removeCondition(int idx) {
    if (_profile == null) return;
    final c = [..._profile!.chronicConditions]..removeAt(idx);
    setState(() {
      _profile = HealthProfile(
        userId: _profile!.userId,
        allergies: _profile!.allergies,
        chronicConditions: c,
        pastPrescriptions: _profile!.pastPrescriptions,
        labUploads: _profile!.labUploads,
        insuranceCards: _profile!.insuranceCards,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Wasifu wa Afya' : 'Health Profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _profile == null
              ? Center(child: Text(isSw ? 'Hapatikani' : 'Not found'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _section(
                      isSw ? 'Mzio (Allergies)' : 'Allergies',
                      _profile!.allergies,
                      _allergyCtrl,
                      _addAllergy,
                      _removeAllergy,
                    ),
                    const SizedBox(height: 16),
                    _section(
                      isSw ? 'Magonjwa sugu' : 'Chronic Conditions',
                      _profile!.chronicConditions,
                      _conditionCtrl,
                      _addCondition,
                      _removeCondition,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(isSw ? 'Hifadhi' : 'Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _section(
    String title,
    List<String> items,
    TextEditingController ctrl,
    VoidCallback onAdd,
    void Function(int) onRemove,
  ) {
    final isSw = _isSwahili;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              isSw ? 'Hakuna' : 'None',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < items.length; i++)
                  Chip(
                    label: Text(items[i], style: const TextStyle(fontSize: 11)),
                    onDeleted: () => onRemove(i),
                    deleteIconColor: const Color(0xFFB71C1C),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: isSw ? 'Ongeza...' : 'Add...',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_rounded, color: _kPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
