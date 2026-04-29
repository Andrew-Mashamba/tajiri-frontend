import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings_scope.dart';
import '../../tajirika/services/partner_product_service.dart';
import '../models/garage_booking.dart';
import 'book_garage_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF2E7D32);

/// Spec F5 — pre-booking symptom wizard. Walks the customer through symptom
/// selection, suggests an `AutoSkill`, captures vehicle basics + optional VIN
/// (image_picker + manual entry; OCR is a future-pass deferral), and routes
/// to `BookGaragePage` with the right prefills.
class SymptomWizardPage extends StatefulWidget {
  final int userId;
  const SymptomWizardPage({super.key, required this.userId});

  @override
  State<SymptomWizardPage> createState() => _SymptomWizardPageState();
}

enum _SymptomCategory {
  engine,
  brakes,
  electrical,
  body,
  transmission,
  ac,
  tires,
  fluid,
  other,
}

class _Symptom {
  final String key;
  final String labelSw;
  final String labelEn;
  final AutoSkill suggestedSkill;
  final _SymptomCategory category;
  const _Symptom(this.key, this.labelSw, this.labelEn, this.suggestedSkill, this.category);
}

const List<_Symptom> _kSymptoms = [
  _Symptom('engine_knock', 'Sauti ya kugonga injinini', 'Engine knock', AutoSkill.autoMechanic, _SymptomCategory.engine),
  _Symptom('engine_smoke', 'Moshi mzito', 'Heavy smoke', AutoSkill.autoMechanic, _SymptomCategory.engine),
  _Symptom('engine_overheat', 'Joto la juu', 'Overheating', AutoSkill.autoMechanic, _SymptomCategory.engine),
  _Symptom('engine_no_start', 'Haianzi', 'Won\'t start', AutoSkill.autoElectrician, _SymptomCategory.engine),
  _Symptom('brake_squeal', 'Breki linapiga sauti', 'Brake squeal', AutoSkill.autoMechanic, _SymptomCategory.brakes),
  _Symptom('brake_soft', 'Breki dhaifu', 'Soft brake pedal', AutoSkill.autoMechanic, _SymptomCategory.brakes),
  _Symptom('battery_dead', 'Betri imekufa', 'Dead battery', AutoSkill.autoElectrician, _SymptomCategory.electrical),
  _Symptom('alternator', 'Alternator', 'Alternator issue', AutoSkill.autoElectrician, _SymptomCategory.electrical),
  _Symptom('lights_fail', 'Taa hazifanyi kazi', 'Lights not working', AutoSkill.autoElectrician, _SymptomCategory.electrical),
  _Symptom('dent', 'Mkwaruzo / dent', 'Dent / scratch', AutoSkill.panelBeating, _SymptomCategory.body),
  _Symptom('paint', 'Rangi', 'Paint job', AutoSkill.sprayPainting, _SymptomCategory.body),
  _Symptom('window', 'Kioo kimevunjika', 'Window broken', AutoSkill.panelBeating, _SymptomCategory.body),
  _Symptom('transmission_slip', 'Gari liko slipping', 'Transmission slipping', AutoSkill.autoMechanic, _SymptomCategory.transmission),
  _Symptom('ac_warm', 'AC haitoi baridi', 'AC not cooling', AutoSkill.autoElectrician, _SymptomCategory.ac),
  _Symptom('tire_punc', 'Tairi imechomeka', 'Tire puncture', AutoSkill.autoMechanic, _SymptomCategory.tires),
  _Symptom('oil_leak', 'Mafuta yanavuja', 'Oil leak', AutoSkill.autoMechanic, _SymptomCategory.fluid),
  _Symptom('coolant_leak', 'Maji ya gari yanavuja', 'Coolant leak', AutoSkill.autoMechanic, _SymptomCategory.fluid),
  _Symptom('other', 'Nyingine', 'Other / not sure', AutoSkill.autoMechanic, _SymptomCategory.other),
];

class _SymptomWizardPageState extends State<SymptomWizardPage> {
  int _step = 0;
  final Set<_Symptom> _selected = <_Symptom>{};
  final _plateCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String _urgency = 'soon'; // 'now' | 'soon' | 'later'
  bool _scanning = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _vinCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  AutoSkill get _suggestedSkill {
    if (_selected.isEmpty) return AutoSkill.autoMechanic;
    final tally = <AutoSkill, int>{};
    for (final s in _selected) {
      tally[s.suggestedSkill] = (tally[s.suggestedSkill] ?? 0) + 1;
    }
    final entries = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  String _summary() {
    if (_selected.isEmpty) return '';
    final isSw = _isSwahili;
    return _selected.map((s) => isSw ? s.labelSw : s.labelEn).join(', ');
  }

  Future<void> _scanVin() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _scanning = true);
    // Upload the image so an admin can later run OCR; placeholder for now.
    // We don't have on-device VIN OCR yet — manual entry remains primary.
    await PartnerProductService.uploadPhoto(
      userId: widget.userId,
      file: File(picked.path),
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isSwahili
          ? 'Picha imepakuliwa. Andika VIN hapa chini (OCR inakuja baadaye).'
          : 'Photo uploaded. Type VIN below (OCR coming soon).'),
    ));
  }

  void _next() {
    if (_step < 2) {
      if (_step == 0 && _selected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili ? 'Chagua angalau dalili moja' : 'Pick at least one symptom'),
        ));
        return;
      }
      if (_step == 1 && _plateCtrl.text.trim().length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili ? 'Andika namba ya gari' : 'Plate required'),
        ));
        return;
      }
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => BookGaragePage(
        userId: widget.userId,
        preselectedSkill: _suggestedSkill,
        prefillFaultSummary: _summary(),
        prefillPlate: _plateCtrl.text.trim().toUpperCase(),
        prefillVin: _vinCtrl.text.trim().isEmpty ? null : _vinCtrl.text.trim(),
        prefillMake: _makeCtrl.text.trim().isEmpty ? null : _makeCtrl.text.trim(),
        prefillModel: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
        prefillYear: int.tryParse(_yearCtrl.text.trim()),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Anzisha matengenezo' : 'Service wizard'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              backgroundColor: _kBorder,
              color: _kPrimary,
            ),
            Expanded(
              child: switch (_step) {
                0 => _stepSymptoms(),
                1 => _stepVehicle(),
                _ => _stepConfirm(),
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _step -= 1),
                      child: Text(isSw ? 'Rudi' : 'Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_step < 2 ? (isSw ? 'Endelea' : 'Next') : (isSw ? 'Anza Booking' : 'Start booking')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepSymptoms() {
    final isSw = _isSwahili;
    final byCat = <_SymptomCategory, List<_Symptom>>{};
    for (final s in _kSymptoms) {
      byCat.putIfAbsent(s.category, () => []).add(s);
    }
    String catLabel(_SymptomCategory c) {
      switch (c) {
        case _SymptomCategory.engine: return isSw ? 'Injinini' : 'Engine';
        case _SymptomCategory.brakes: return isSw ? 'Breki' : 'Brakes';
        case _SymptomCategory.electrical: return isSw ? 'Umeme' : 'Electrical';
        case _SymptomCategory.body: return isSw ? 'Mwili' : 'Body';
        case _SymptomCategory.transmission: return isSw ? 'Gear' : 'Transmission';
        case _SymptomCategory.ac: return 'AC';
        case _SymptomCategory.tires: return isSw ? 'Matairi' : 'Tires';
        case _SymptomCategory.fluid: return isSw ? 'Mafuta' : 'Fluid';
        case _SymptomCategory.other: return isSw ? 'Nyingine' : 'Other';
      }
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isSw ? 'Chagua dalili zinazoendana' : 'Pick symptoms that apply',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              isSw
                  ? 'Imechaguliwa: ${_selected.length} • Pendekezo: ${_suggestedSkill.labelSwahili}'
                  : 'Selected: ${_selected.length} • Suggested: ${_suggestedSkill.label}',
              style: const TextStyle(fontSize: 12, color: _kAccent, fontWeight: FontWeight.w700),
            ),
          ),
        for (final cat in _SymptomCategory.values)
          if (byCat.containsKey(cat)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(catLabel(cat).toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kSecondary, letterSpacing: 0.5)),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: byCat[cat]!.map((s) {
                final on = _selected.contains(s);
                return FilterChip(
                  label: Text(isSw ? s.labelSw : s.labelEn),
                  selected: on,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selected.add(s);
                    } else {
                      _selected.remove(s);
                    }
                  }),
                );
              }).toList(),
            ),
          ],
      ],
    );
  }

  Widget _stepVehicle() {
    final isSw = _isSwahili;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isSw ? 'Maelezo ya gari' : 'Vehicle details',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _plateCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: isSw ? 'Namba ya gari *' : 'Plate *',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: _makeCtrl,
            decoration: InputDecoration(labelText: isSw ? 'Aina (Toyota...)' : 'Make', border: const OutlineInputBorder(), isDense: true),
          )),
          const SizedBox(width: 6),
          Expanded(child: TextField(
            controller: _modelCtrl,
            decoration: InputDecoration(labelText: 'Model', border: const OutlineInputBorder(), isDense: true),
          )),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: isSw ? 'Mwaka' : 'Year', border: const OutlineInputBorder(), isDense: true),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Text(
          isSw ? 'VIN (hiari)' : 'VIN (optional)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _vinCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: 'VIN', border: const OutlineInputBorder(), isDense: true),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: _scanning ? null : _scanVin,
            icon: _scanning
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt_rounded, size: 16),
            label: Text(isSw ? 'Skani' : 'Scan'),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          isSw
              ? 'Skanning hutumia kamera kupakia picha; OCR ya VIN itaongezwa baadaye.'
              : 'Scanning uses your camera to upload a photo; VIN OCR coming soon.',
          style: const TextStyle(fontSize: 11, color: _kSecondary),
        ),
      ],
    );
  }

  Widget _stepConfirm() {
    final isSw = _isSwahili;
    final entries = <(String, String)>[
      (isSw ? 'Dalili' : 'Symptoms', _summary()),
      (isSw ? 'Pendekezo' : 'Suggested', isSw ? _suggestedSkill.labelSwahili : _suggestedSkill.label),
      (isSw ? 'Plate' : 'Plate', _plateCtrl.text.trim().toUpperCase()),
      if (_makeCtrl.text.trim().isNotEmpty || _modelCtrl.text.trim().isNotEmpty || _yearCtrl.text.trim().isNotEmpty)
        ('Vehicle', '${_makeCtrl.text.trim()} ${_modelCtrl.text.trim()} ${_yearCtrl.text.trim()}'.trim()),
      if (_vinCtrl.text.trim().isNotEmpty)
        ('VIN', _vinCtrl.text.trim()),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isSw ? 'Hakiki' : 'Review',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 12),
        ...entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 96,
                  child: Text(e.$1,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kSecondary)),
                ),
                Expanded(
                  child: Text(e.$2, style: const TextStyle(fontSize: 13, color: _kPrimary)),
                ),
              ]),
            )),
        const SizedBox(height: 16),
        Text(
          isSw ? 'Haraka kiasi gani?' : 'How urgent?',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(label: Text(isSw ? 'Sasa hivi' : 'Now'), selected: _urgency == 'now', onSelected: (_) => setState(() => _urgency = 'now')),
            ChoiceChip(label: Text(isSw ? 'Hivi karibuni' : 'Soon'), selected: _urgency == 'soon', onSelected: (_) => setState(() => _urgency = 'soon')),
            ChoiceChip(label: Text(isSw ? 'Baadaye' : 'Later'), selected: _urgency == 'later', onSelected: (_) => setState(() => _urgency = 'later')),
          ],
        ),
      ],
    );
  }
}
