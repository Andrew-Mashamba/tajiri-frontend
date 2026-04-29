// lib/my_children/pages/dental_record_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../doctor/doctor_module.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ─── Dental milestone presets ────────────────────────────────────
class _DentalMilestonePreset {
  final String key;
  final String labelEn;
  final String labelSw;
  const _DentalMilestonePreset({required this.key, required this.labelEn, required this.labelSw});
  String label(bool sw) => sw ? labelSw : labelEn;
}

const List<_DentalMilestonePreset> _milestonePresets = [
  _DentalMilestonePreset(key: 'first_tooth', labelEn: 'First Tooth', labelSw: 'Jino la Kwanza'),
  _DentalMilestonePreset(key: 'first_tooth_lost', labelEn: 'First Tooth Lost', labelSw: 'Jino la Kwanza Kupotea'),
  _DentalMilestonePreset(key: 'all_baby_teeth', labelEn: 'All Baby Teeth In', labelSw: 'Meno Yote ya Mtoto Yameota'),
  _DentalMilestonePreset(key: 'all_baby_teeth_lost', labelEn: 'All Baby Teeth Lost', labelSw: 'Meno Yote ya Mtoto Yamepotea'),
  _DentalMilestonePreset(key: 'first_permanent_molar', labelEn: 'First Permanent Molar', labelSw: 'Jino la Kudumu la Kwanza'),
  _DentalMilestonePreset(key: 'all_permanent_teeth', labelEn: 'All Permanent Teeth', labelSw: 'Meno Yote ya Kudumu'),
  _DentalMilestonePreset(key: 'wisdom_teeth', labelEn: 'Wisdom Teeth', labelSw: 'Meno ya Hekima'),
];

// ─── Page ────────────────────────────────────────────────────────

class DentalRecordPage extends StatefulWidget {
  final Child child;
  const DentalRecordPage({super.key, required this.child});

  @override
  State<DentalRecordPage> createState() => _DentalRecordPageState();
}

class _DentalRecordPageState extends State<DentalRecordPage> {
  bool _isLoading = true;

  // Data
  DateTime? _firstToothDate;
  List<_DentalVisit> _visits = [];
  _BracesTracking? _braces;
  final Map<String, DateTime> _milestones = {};

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;
  String get _prefKey => 'dental_records_${widget.child.id}';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _firstToothDate = data['first_tooth_date'] != null ? DateTime.tryParse(data['first_tooth_date'] as String) : null;
        if (data['visits'] is List) {
          _visits = (data['visits'] as List).map((v) => _DentalVisit.fromMap(v as Map<String, dynamic>)).toList();
        }
        if (data['braces'] is Map) {
          _braces = _BracesTracking.fromMap(data['braces'] as Map<String, dynamic>);
        }
        if (data['milestones'] is Map) {
          final m = data['milestones'] as Map<String, dynamic>;
          for (final entry in m.entries) {
            final dt = DateTime.tryParse(entry.value as String? ?? '');
            if (dt != null) _milestones[entry.key] = dt;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        if (_firstToothDate != null) 'first_tooth_date': _firstToothDate!.toIso8601String(),
        'visits': _visits.map((v) => v.toMap()).toList(),
        if (_braces != null) 'braces': _braces!.toMap(),
        'milestones': _milestones.map((k, v) => MapEntry(k, v.toIso8601String())),
      };
      await prefs.setString(_prefKey, jsonEncode(data));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Rekodi za Meno' : 'Dental Records',
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFirstToothCard(sw),
                    const SizedBox(height: 16),
                    _buildDentalVisitsSection(sw),
                    const SizedBox(height: 16),
                    _buildBracesSection(sw),
                    const SizedBox(height: 16),
                    _buildMilestonesSection(sw),

                    // ─── Cross-module links ──────────────
                    const SizedBox(height: 20),
                    Text(
                      sw ? 'Viunganishi' : 'Related',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCrossModuleLink(
                      icon: Icons.local_hospital_rounded,
                      label: sw
                          ? 'Tafuta daktari wa meno'
                          : 'Find a dental specialist',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DoctorModule(userId: widget.child.userId))),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.shopping_bag_rounded,
                      label: sw
                          ? 'Nunua bidhaa za utunzaji wa meno'
                          : 'Shop dental care products',
                      onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.chat_rounded,
                      label: sw
                          ? 'Uliza Shangazi kuhusu afya ya meno'
                          : 'Ask Shangazi about dental health',
                      onTap: () => Navigator.pushNamed(context, '/chat/0'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── First Tooth ─────────────────────────────────────────────

  Widget _buildFirstToothCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _firstToothDate != null ? _kPrimary.withValues(alpha: 0.08) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.child_care_rounded, color: _firstToothDate != null ? _kPrimary : _kSecondary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sw ? 'Jino la Kwanza' : 'First Tooth Date', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            _firstToothDate != null ? _formatDate(_firstToothDate!) : (sw ? 'Bonyeza kuweka tarehe' : 'Tap to set date'),
            style: TextStyle(fontSize: 13, color: _firstToothDate != null ? _kPrimary : _kSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ])),
        SizedBox(
          width: 48, height: 48,
          child: IconButton(
            onPressed: () => _pickFirstToothDate(sw),
            icon: Icon(_firstToothDate != null ? Icons.edit_rounded : Icons.add_rounded, color: _kPrimary, size: 20),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickFirstToothDate(bool sw) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstToothDate ?? widget.child.dateOfBirth.add(const Duration(days: 180)),
      firstDate: widget.child.dateOfBirth,
      lastDate: DateTime.now(),
      helpText: sw ? 'Chagua tarehe' : 'Select date',
    );
    if (picked != null && mounted) {
      setState(() => _firstToothDate = picked);
      _saveData();
    }
  }

  // ─── Dental Visits ───────────────────────────────────────────

  Widget _buildDentalVisitsSection(bool sw) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(sw ? 'Ziara za Daktari wa Meno' : 'Dental Visits', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary))),
        SizedBox(
          width: 48, height: 48,
          child: IconButton(
            onPressed: () => _addOrEditVisit(sw, null),
            icon: const Icon(Icons.add_circle_outline_rounded, color: _kPrimary, size: 24),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      if (_visits.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
          child: Text(sw ? 'Hakuna ziara bado' : 'No visits recorded yet', style: const TextStyle(fontSize: 13, color: _kSecondary)),
        )
      else
        ..._visits.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _addOrEditVisit(sw, i),
              onLongPress: () => _confirmDeleteVisit(sw, i),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.local_hospital_rounded, size: 18, color: _kPrimary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(v.dentistName.isNotEmpty ? v.dentistName : (sw ? 'Daktari wa Meno' : 'Dentist'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(_formatDate(v.date), style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  ]),
                  if (v.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(v.notes, style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (v.nextAppointment != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.event_rounded, size: 14, color: _kSecondary),
                      const SizedBox(width: 4),
                      Text('${sw ? "Miadi inayofuata" : "Next"}: ${_formatDate(v.nextAppointment!)}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ],
                ]),
              ),
            ),
          );
        }),
    ]);
  }

  Future<void> _addOrEditVisit(bool sw, int? editIndex) async {
    final existing = editIndex != null ? _visits[editIndex] : null;
    final dentistCtrl = TextEditingController(text: existing?.dentistName ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    DateTime visitDate = existing?.date ?? DateTime.now();
    DateTime? nextAppt = existing?.nextAppointment;

    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          backgroundColor: _kCardBg,
          title: Text(
            editIndex != null ? (sw ? 'Hariri Ziara' : 'Edit Visit') : (sw ? 'Ongeza Ziara' : 'Add Visit'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Visit date
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: visitDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                if (d != null) setDialogState(() => visitDate = d);
              },
              child: _dialogDateField(sw ? 'Tarehe ya ziara' : 'Visit Date', _formatDate(visitDate)),
            ),
            const SizedBox(height: 12),
            TextField(controller: dentistCtrl, decoration: InputDecoration(labelText: sw ? 'Jina la daktari' : 'Dentist Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, maxLines: 3, decoration: InputDecoration(labelText: sw ? 'Maelezo' : 'Notes', hintText: sw ? 'Uchunguzi, matibabu, mapendekezo...' : 'Diagnosis, treatment, recommendations...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            // Next appointment
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: nextAppt ?? DateTime.now().add(const Duration(days: 180)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                if (d != null) setDialogState(() => nextAppt = d);
              },
              child: _dialogDateField(
                sw ? 'Miadi inayofuata' : 'Next Appointment',
                nextAppt != null ? _formatDate(nextAppt!) : (sw ? 'Bonyeza kuchagua' : 'Tap to select'),
                optional: true,
              ),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(sw ? 'Hifadhi' : 'Save', style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))),
          ],
        );
      });
    });

    if (result == true && mounted) {
      final visit = _DentalVisit(
        date: visitDate,
        dentistName: dentistCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
        nextAppointment: nextAppt,
      );
      setState(() {
        if (editIndex != null) {
          _visits[editIndex] = visit;
        } else {
          _visits.insert(0, visit);
        }
        _visits.sort((a, b) => b.date.compareTo(a.date));
      });
      _saveData();
      messenger.showSnackBar(SnackBar(content: Text(sw ? 'Ziara imehifadhiwa' : 'Visit saved'), duration: const Duration(seconds: 1)));
    }
    dentistCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _confirmDeleteVisit(bool sw, int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        backgroundColor: _kCardBg,
        title: Text(sw ? 'Futa ziara?' : 'Delete visit?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        content: Text(sw ? 'Hatua hii haiwezi kutenduliwa.' : 'This action cannot be undone.', style: const TextStyle(fontSize: 14, color: _kSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(sw ? 'Futa' : 'Delete', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      );
    });
    if (confirmed == true && mounted) {
      setState(() => _visits.removeAt(index));
      _saveData();
      messenger.showSnackBar(SnackBar(content: Text(sw ? 'Ziara imefutwa' : 'Visit deleted'), duration: const Duration(seconds: 1)));
    }
  }

  // ─── Braces Tracking ─────────────────────────────────────────

  Widget _buildBracesSection(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_fix_high_rounded, size: 20, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(sw ? 'Ufuatiliaji wa Braces' : 'Braces Tracking', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary))),
          SizedBox(
            width: 48, height: 48,
            child: IconButton(
              onPressed: () => _editBraces(sw),
              icon: Icon(_braces != null ? Icons.edit_rounded : Icons.add_rounded, color: _kPrimary, size: 20),
            ),
          ),
        ]),
        if (_braces == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(sw ? 'Hakuna taarifa za braces' : 'No braces information recorded', style: const TextStyle(fontSize: 13, color: _kSecondary)),
          )
        else ...[
          const SizedBox(height: 12),
          _bracesInfoRow(Icons.calendar_today_rounded, sw ? 'Tarehe ya kuanza' : 'Start Date', _formatDate(_braces!.startDate)),
          if (_braces!.expectedEndDate != null)
            _bracesInfoRow(Icons.event_available_rounded, sw ? 'Tarehe ya mwisho inayotarajiwa' : 'Expected End Date', _formatDate(_braces!.expectedEndDate!)),
          if (_braces!.adjustmentDates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(sw ? 'Marekebisho' : 'Adjustments', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: _braces!.adjustmentDates.map((d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _kBackground, borderRadius: BorderRadius.circular(8)),
              child: Text(_formatDate(d), style: const TextStyle(fontSize: 12, color: _kPrimary)),
            )).toList()),
          ],
          if (_braces!.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_braces!.notes, style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ],
      ]),
    );
  }

  Widget _bracesInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: _kSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: _kSecondary)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Future<void> _editBraces(bool sw) async {
    final notesCtrl = TextEditingController(text: _braces?.notes ?? '');
    DateTime startDate = _braces?.startDate ?? DateTime.now();
    DateTime? endDate = _braces?.expectedEndDate;
    List<DateTime> adjustments = List<DateTime>.from(_braces?.adjustmentDates ?? []);

    final result = await showDialog<bool>(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          backgroundColor: _kCardBg,
          title: Text(sw ? 'Braces' : 'Braces Tracking', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Start date
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setDialogState(() => startDate = d);
              },
              child: _dialogDateField(sw ? 'Tarehe ya kuanza' : 'Start Date', _formatDate(startDate)),
            ),
            const SizedBox(height: 12),
            // Expected end date
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: endDate ?? startDate.add(const Duration(days: 730)), firstDate: startDate, lastDate: startDate.add(const Duration(days: 2190)));
                if (d != null) setDialogState(() => endDate = d);
              },
              child: _dialogDateField(
                sw ? 'Tarehe ya mwisho inayotarajiwa' : 'Expected End Date',
                endDate != null ? _formatDate(endDate!) : (sw ? 'Bonyeza kuchagua' : 'Tap to select'),
                optional: true,
              ),
            ),
            const SizedBox(height: 12),
            // Adjustments
            Align(alignment: Alignment.centerLeft, child: Text(sw ? 'Marekebisho' : 'Adjustment Dates', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary))),
            const SizedBox(height: 6),
            if (adjustments.isNotEmpty)
              Wrap(spacing: 6, runSpacing: 6, children: adjustments.asMap().entries.map((e) => Chip(
                label: Text(_formatDate(e.value), style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                onDeleted: () => setDialogState(() => adjustments.removeAt(e.key)),
                backgroundColor: _kBackground,
                side: BorderSide.none,
              )).toList()),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(context: ctx, initialDate: adjustments.isNotEmpty ? adjustments.last.add(const Duration(days: 30)) : DateTime.now(), firstDate: startDate, lastDate: DateTime.now().add(const Duration(days: 1095)));
                  if (d != null) setDialogState(() { adjustments.add(d); adjustments.sort(); });
                },
                icon: const Icon(Icons.add_rounded, size: 18, color: _kPrimary),
                label: Text(sw ? 'Ongeza tarehe' : 'Add Date', style: const TextStyle(fontSize: 13, color: _kPrimary)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, maxLines: 2, decoration: InputDecoration(labelText: sw ? 'Maelezo' : 'Notes', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          ])),
          actions: [
            if (_braces != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _removeBraces(sw);
                },
                child: Text(sw ? 'Ondoa' : 'Remove', style: const TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(sw ? 'Hifadhi' : 'Save', style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))),
          ],
        );
      });
    });

    if (result == true && mounted) {
      setState(() {
        _braces = _BracesTracking(
          startDate: startDate,
          expectedEndDate: endDate,
          adjustmentDates: adjustments,
          notes: notesCtrl.text.trim(),
        );
      });
      _saveData();
    }
    notesCtrl.dispose();
  }

  void _removeBraces(bool sw) {
    setState(() => _braces = null);
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sw ? 'Taarifa za braces zimeondolewa' : 'Braces information removed'), duration: const Duration(seconds: 1)),
    );
  }

  // ─── Dental Milestones ───────────────────────────────────────

  Widget _buildMilestonesSection(bool sw) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(sw ? 'Hatua za Meno' : 'Dental Milestones', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
      const SizedBox(height: 8),
      ..._milestonePresets.map((preset) {
        final date = _milestones[preset.key];
        final isRecorded = date != null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () => _toggleMilestone(sw, preset),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isRecorded ? _kPrimary.withValues(alpha: 0.08) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isRecorded ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isRecorded ? _kPrimary : _kSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(preset.label(sw), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (isRecorded) Text(_formatDate(date), style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ])),
                if (isRecorded)
                  SizedBox(
                    width: 48, height: 48,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _milestones.remove(preset.key));
                        _saveData();
                      },
                      icon: const Icon(Icons.close_rounded, color: _kSecondary, size: 18),
                    ),
                  ),
              ]),
            ),
          ),
        );
      }),
    ]);
  }

  Future<void> _toggleMilestone(bool sw, _DentalMilestonePreset preset) async {
    if (_milestones.containsKey(preset.key)) {
      // Already recorded, offer to change date
      final picked = await showDatePicker(
        context: context,
        initialDate: _milestones[preset.key]!,
        firstDate: widget.child.dateOfBirth,
        lastDate: DateTime.now(),
        helpText: sw ? 'Badilisha tarehe' : 'Change date',
      );
      if (picked != null && mounted) {
        setState(() => _milestones[preset.key] = picked);
        _saveData();
      }
    } else {
      // Not yet recorded, pick date
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: widget.child.dateOfBirth,
        lastDate: DateTime.now(),
        helpText: sw ? 'Chagua tarehe' : 'Select date',
      );
      if (picked != null && mounted) {
        setState(() => _milestones[preset.key] = picked);
        _saveData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${preset.label(sw)} ${sw ? "imerekodiwa" : "recorded"}'), duration: const Duration(seconds: 1)),
        );
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────

  Widget _dialogDateField(String label, String value, {bool optional = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 11, color: optional ? _kSecondary : _kPrimary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }
}

// ─── Data Models ────────────────────────────────────────────────

class _DentalVisit {
  final DateTime date;
  final String dentistName;
  final String notes;
  final DateTime? nextAppointment;

  const _DentalVisit({
    required this.date,
    required this.dentistName,
    required this.notes,
    this.nextAppointment,
  });

  factory _DentalVisit.fromMap(Map<String, dynamic> map) => _DentalVisit(
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    dentistName: map['dentist_name'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    nextAppointment: map['next_appointment'] != null ? DateTime.tryParse(map['next_appointment'] as String) : null,
  );

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'dentist_name': dentistName,
    'notes': notes,
    if (nextAppointment != null) 'next_appointment': nextAppointment!.toIso8601String(),
  };
}

class _BracesTracking {
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final List<DateTime> adjustmentDates;
  final String notes;

  const _BracesTracking({
    required this.startDate,
    this.expectedEndDate,
    this.adjustmentDates = const [],
    this.notes = '',
  });

  factory _BracesTracking.fromMap(Map<String, dynamic> map) => _BracesTracking(
    startDate: DateTime.tryParse(map['start_date'] as String? ?? '') ?? DateTime.now(),
    expectedEndDate: map['expected_end_date'] != null ? DateTime.tryParse(map['expected_end_date'] as String) : null,
    adjustmentDates: map['adjustment_dates'] is List
        ? (map['adjustment_dates'] as List).map((d) => DateTime.tryParse(d as String? ?? '') ?? DateTime.now()).toList()
        : const [],
    notes: map['notes'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'start_date': startDate.toIso8601String(),
    if (expectedEndDate != null) 'expected_end_date': expectedEndDate!.toIso8601String(),
    'adjustment_dates': adjustmentDates.map((d) => d.toIso8601String()).toList(),
    'notes': notes,
  };
}
