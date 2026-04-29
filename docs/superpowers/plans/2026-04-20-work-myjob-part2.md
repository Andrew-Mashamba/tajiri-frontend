# Work Management & My Job — Implementation Plan (Part 2: Manager UI)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Run after Part 1 is complete.

**Goal:** Build all manager-facing pages: JobDescriptionPage, KpiDetailPage, EmployeeTasksPage, TaskDetailPage, WorkBoardPage, and the two new cards on EmployeeDetailPage.

**Depends on:** Part 1 complete (work_models.dart, task_models.dart, work_service.dart exist).

---

## Task 6: JobDescriptionPage

**Files:**
- Create: `lib/team/pages/job_description_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/team/pages/job_description_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/work_models.dart';
import '../services/work_service.dart';
// Note: kpi_sparkline_chart.dart is added in Task 7. After Task 7 completes,
// uncomment the next line and the sparkline usage in _kpiCard.
// import '../widgets/kpi_sparkline_chart.dart';
import 'kpi_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class JobDescriptionPage extends StatefulWidget {
  final int employeeId;
  final int businessId;
  final String employeeName;
  final String ownerName;
  final String token;

  const JobDescriptionPage({
    super.key,
    required this.employeeId,
    required this.businessId,
    required this.employeeName,
    required this.ownerName,
    required this.token,
  });

  @override
  State<JobDescriptionPage> createState() => _JobDescriptionPageState();
}

class _JobDescriptionPageState extends State<JobDescriptionPage> {
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  JobDescription? _jd;
  List<Kpi> _kpis = [];
  Map<int, List<KpiEntry>> _kpiEntries = {};

  // Edit controllers
  late TextEditingController _summaryCtrl;
  late List<TextEditingController> _respCtrs;

  @override
  void initState() {
    super.initState();
    _summaryCtrl = TextEditingController();
    _respCtrs = [];
    _load();
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    for (final c in _respCtrs) { c.dispose(); }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final results = await Future.wait([
      WorkService.getJobDescription(widget.token, widget.employeeId),
      WorkService.getKpis(widget.token, widget.employeeId),
    ]);
    if (!mounted) return;
    final jdRes = results[0] as WorkResult<JobDescription>;
    final kpiRes = results[1] as WorkListResult<Kpi>;
    setState(() {
      _loading = false;
      _jd = jdRes.data;
      _kpis = kpiRes.data;
      if (_jd != null) _populateControllers(_jd!);
    });
    // Load entries for each KPI (for sparkline display)
    for (final kpi in _kpis) {
      if (kpi.id != null) _loadKpiEntries(kpi.id!);
    }
  }

  Future<void> _loadKpiEntries(int kpiId) async {
    final res = await WorkService.getKpiEntries(widget.token, kpiId);
    if (!mounted) return;
    setState(() => _kpiEntries[kpiId] = res.data);
  }

  void _populateControllers(JobDescription jd) {
    _summaryCtrl.text = jd.roleSummary;
    for (final c in _respCtrs) { c.dispose(); }
    _respCtrs = jd.responsibilities.map((r) => TextEditingController(text: r)).toList();
  }

  void _startEdit() {
    if (_jd != null) _populateControllers(_jd!);
    setState(() => _editing = true);
  }

  Future<void> _save(bool sw) async {
    setState(() => _saving = true);
    final body = {
      'role_summary': _summaryCtrl.text.trim(),
      'responsibilities': _respCtrs.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
    };
    final res = await WorkService.saveJobDescription(widget.token, widget.employeeId, body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Maelezo ya kazi yamehifadhiwa' : 'Job description saved')));
      setState(() { _jd = res.data ?? _jd; _editing = false; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Imeshindwa kuhifadhi. Jaribu tena.' : 'Failed to save. Try again.'),
          backgroundColor: Colors.red));
    }
  }

  void _addResponsibility() {
    setState(() => _respCtrs.add(TextEditingController()));
  }

  void _removeResponsibility(int i) {
    _respCtrs[i].dispose();
    setState(() => _respCtrs.removeAt(i));
  }

  Future<void> _showAddKpiSheet(bool sw) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _KpiFormSheet(
        token: widget.token,
        employeeId: widget.employeeId,
        businessId: widget.businessId,
        sw: sw,
        onSaved: _load,
      ),
    );
  }

  Future<void> _showEditKpiSheet(Kpi kpi, bool sw) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _KpiFormSheet(
        token: widget.token,
        employeeId: widget.employeeId,
        businessId: widget.businessId,
        sw: sw,
        existingKpi: kpi,
        onSaved: _load,
      ),
    );
  }

  Future<void> _deleteKpi(Kpi kpi, bool sw) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa KPI' : 'Delete KPI',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw
            ? 'Futa ${kpi.name}? Rekodi zote zitafutwa pia.'
            : 'Delete ${kpi.name}? All logged entries will also be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final res = await WorkService.deleteKpi(widget.token, kpi.id!);
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ?? 'Failed'),
          backgroundColor: Colors.red));
    }
  }

  Widget _sectionCard(String title, Widget child) => Card(
        color: _kCard,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
            const SizedBox(height: 10),
            child,
          ]),
        ),
      );

  Widget _kpiCard(Kpi kpi, bool sw) {
    final targetStr = kpi.unit == 'TZS'
        ? 'TZS ${kpi.targetValue.round()}'
        : '${kpi.targetValue.toStringAsFixed(kpi.targetValue == kpi.targetValue.roundToDouble() ? 0 : 1)} ${kpi.unit}';
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => KpiDetailPage(
                    kpi: kpi,
                    token: widget.token,
                    sw: sw,
                  ))),
      onLongPress: () async {
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(sw ? 'Hariri KPI' : 'Edit KPI'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: Text(sw ? 'Futa KPI' : 'Delete KPI',
                    style: const TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ]),
          ),
        );
        if (!mounted) return;
        if (choice == 'edit') _showEditKpiSheet(kpi, sw);
        if (choice == 'delete') _deleteKpi(kpi, sw);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kpi.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$targetStr · ${_periodLabel(kpi.reviewPeriod, sw)}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary, size: 18),
          ]),
          // Sparkline added in Task 7 Step 3 after KpiSparklineChart widget is created.
        ]),
      ),
    );
  }

  String _periodLabel(String p, bool sw) {
    if (sw) {
      switch (p) {
        case 'monthly': return 'Kila Mwezi';
        case 'quarterly': return 'Kila Robo Mwaka';
        case 'annual': return 'Kila Mwaka';
        default: return p;
      }
    }
    switch (p) {
      case 'monthly': return 'Monthly';
      case 'quarterly': return 'Quarterly';
      case 'annual': return 'Annual';
      default: return p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(widget.employeeName,
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: _saving
            ? [const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))]
            : [
                if (!_editing)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: _kPrimary),
                    onPressed: _startEdit,
                  )
                else
                  TextButton(
                    onPressed: () => _save(sw),
                    child: Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(
                            color: _kPrimary, fontWeight: FontWeight.bold)),
                  ),
              ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary, foregroundColor: Colors.white),
                      child: Text(sw ? 'Jaribu Tena' : 'Retry')),
                ]))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  // Role Summary
                  _sectionCard(
                    sw ? 'Muhtasari wa Nafasi' : 'Role Summary',
                    _editing
                        ? TextField(
                            controller: _summaryCtrl,
                            maxLines: null,
                            style: const TextStyle(fontSize: 14, color: _kPrimary),
                            decoration: InputDecoration(
                              hintText: sw ? 'Andika muhtasari...' : 'Enter role summary...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        : (_jd?.roleSummary.isEmpty ?? true)
                            ? Text(sw ? 'Hakuna muhtasari bado' : 'No summary yet',
                                style: const TextStyle(
                                    fontSize: 14, color: _kSecondary,
                                    fontStyle: FontStyle.italic))
                            : Text(_jd!.roleSummary,
                                style: const TextStyle(fontSize: 14, color: _kPrimary)),
                  ),

                  // Responsibilities
                  _sectionCard(
                    sw ? 'Majukumu' : 'Responsibilities',
                    _editing
                        ? Column(children: [
                            ...List.generate(_respCtrs.length, (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Text('${i + 1}.',
                                    style: const TextStyle(
                                        color: _kSecondary, fontSize: 13)),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(
                                  controller: _respCtrs[i],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(isDense: true),
                                )),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                  onPressed: () => _removeResponsibility(i),
                                ),
                              ]),
                            )),
                            TextButton.icon(
                              onPressed: _addResponsibility,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(sw ? 'Ongeza Jukumu' : 'Add Responsibility'),
                            ),
                          ])
                        : (_jd == null || _jd!.responsibilities.isEmpty)
                            ? Text(sw ? 'Hakuna majukumu bado' : 'No responsibilities set',
                                style: const TextStyle(
                                    fontSize: 14, color: _kSecondary,
                                    fontStyle: FontStyle.italic))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  _jd!.responsibilities.length,
                                  (i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text('${i + 1}. ${_jd!.responsibilities[i]}',
                                        style: const TextStyle(
                                            fontSize: 14, color: _kPrimary)),
                                  ),
                                ),
                              ),
                  ),

                  // Reporting To
                  _sectionCard(
                    sw ? 'Anaripoti Kwa' : 'Reporting To',
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          _jd?.reportingTo.isNotEmpty == true
                              ? _jd!.reportingTo
                              : widget.ownerName,
                          style: const TextStyle(fontSize: 13, color: _kPrimary)),
                    ),
                  ),

                  // KPIs
                  _sectionCard(
                    sw ? 'Viashiria vya Utendaji (KPI)' : 'KPIs',
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ..._kpis.map((k) => _kpiCard(k, sw)),
                      if (_kpis.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                              sw ? 'Hakuna KPI. Gonga + kuongeza.'
                                 : 'No KPIs set. Tap + to add.',
                              style: const TextStyle(
                                  fontSize: 14, color: _kSecondary,
                                  fontStyle: FontStyle.italic)),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _showAddKpiSheet(sw),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(sw ? 'Ongeza KPI' : 'Add KPI'),
                        style: OutlinedButton.styleFrom(foregroundColor: _kPrimary),
                      ),
                    ]),
                  ),

                  if (_jd?.updatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      child: Text(
                          '${sw ? 'Imesasishwa' : 'Last updated'}: ${DateFormat('dd MMM yyyy').format(_jd!.updatedAt!)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ),
                ]),
    );
  }
}

// ── KPI Add/Edit Sheet ──────────────────────────────────────────────────────

class _KpiFormSheet extends StatefulWidget {
  final String token;
  final int employeeId;
  final int businessId;
  final bool sw;
  final Kpi? existingKpi;
  final VoidCallback onSaved;

  const _KpiFormSheet({
    required this.token,
    required this.employeeId,
    required this.businessId,
    required this.sw,
    this.existingKpi,
    required this.onSaved,
  });

  @override
  State<_KpiFormSheet> createState() => _KpiFormSheetState();
}

class _KpiFormSheetState extends State<_KpiFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _targetCtrl;
  late TextEditingController _customUnitCtrl;

  String _unit = '%';
  String _period = 'monthly';
  bool _saving = false;

  static const _units = ['%', 'TZS', 'count', 'hrs', 'Custom'];
  static const _periods = ['monthly', 'quarterly', 'annual'];

  @override
  void initState() {
    super.initState();
    final kpi = widget.existingKpi;
    _nameCtrl = TextEditingController(text: kpi?.name ?? '');
    _targetCtrl = TextEditingController(
        text: kpi != null ? kpi.targetValue.toString() : '');
    _customUnitCtrl = TextEditingController();
    if (kpi != null) {
      if (_units.contains(kpi.unit)) {
        _unit = kpi.unit;
      } else {
        _unit = 'Custom';
        _customUnitCtrl.text = kpi.unit;
      }
      _period = kpi.reviewPeriod;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _customUnitCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existingKpi != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final unitValue = _unit == 'Custom' ? _customUnitCtrl.text.trim() : _unit;
    final body = {
      'employee_id': widget.employeeId,
      'business_id': widget.businessId,
      'name': _nameCtrl.text.trim(),
      'target_value': double.tryParse(_targetCtrl.text.trim()) ?? 0,
      'unit': unitValue,
      'review_period': _period,
    };
    late WorkResult res;
    if (_isEdit) {
      res = await WorkService.updateKpi(widget.token, widget.existingKpi!.id!, body);
    } else {
      res = await WorkService.createKpi(widget.token, body);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ?? 'Failed'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? (sw ? 'Hariri KPI' : 'Edit KPI') : (sw ? 'Ongeza KPI' : 'Add KPI'),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: sw ? 'Jina la KPI' : 'KPI Name',
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (sw ? 'Weka jina la KPI' : 'Enter KPI name') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: sw ? 'Thamani Lengwa' : 'Target Value',
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (sw ? 'Weka thamani lengwa' : 'Enter target value') : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _unit,
            decoration: InputDecoration(
              labelText: sw ? 'Kitengo' : 'Unit',
              border: const OutlineInputBorder(),
            ),
            items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setState(() => _unit = v ?? '%'),
            validator: (v) => (v == null || v.isEmpty)
                ? (sw ? 'Chagua kitengo' : 'Select a unit') : null,
          ),
          if (_unit == 'Custom') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customUnitCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Kitengo Maalum' : 'Custom Unit',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter unit' : null,
            ),
          ],
          const SizedBox(height: 12),
          Text(sw ? 'Kipindi cha Tathmini' : 'Review Period',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _periods.map((p) {
              final label = sw
                  ? (p == 'monthly' ? 'Kila Mwezi' : p == 'quarterly' ? 'Kila Robo Mwaka' : 'Kila Mwaka')
                  : (p == 'monthly' ? 'Monthly' : p == 'quarterly' ? 'Quarterly' : 'Annual');
              return ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: _period == p,
                onSelected: (_) => setState(() => _period = p),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(color: _period == p ? Colors.white : _kPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? (sw ? 'Sasisha' : 'Update') : (sw ? 'Hifadhi' : 'Save')),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/team/pages/job_description_page.dart
```

---

## Task 7: KpiDetailPage

**Files:**
- Create: `lib/team/pages/kpi_detail_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/team/pages/kpi_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_models.dart';
import '../services/work_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class KpiDetailPage extends StatefulWidget {
  final Kpi kpi;
  final String token;
  final bool sw;

  const KpiDetailPage({
    super.key,
    required this.kpi,
    required this.token,
    required this.sw,
  });

  @override
  State<KpiDetailPage> createState() => _KpiDetailPageState();
}

class _KpiDetailPageState extends State<KpiDetailPage> {
  List<KpiEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await WorkService.getKpiEntries(widget.token, widget.kpi.id!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _entries = res.data;
    });
  }

  String _fmt(double v) {
    final kpi = widget.kpi;
    if (kpi.unit == 'TZS') {
      return 'TZS ${NumberFormat('#,###').format(v.round())}';
    }
    final num = v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
    return '$num ${kpi.unit}';
  }

  Future<void> _showLogSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LogEntrySheet(
        token: widget.token,
        kpiId: widget.kpi.id!,
        sw: widget.sw,
        kpi: widget.kpi,
        onSaved: _load,
      ),
    );
  }

  Future<void> _deleteEntry(KpiEntry entry) async {
    final sw = widget.sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa Rekodi' : 'Delete Entry',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw ? 'Futa rekodi hii?' : 'Delete this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final res = await WorkService.deleteKpiEntry(widget.token, entry.id!);
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ?? 'Failed'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final kpi = widget.kpi;
    final target = kpi.targetValue;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(kpi.name,
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogSheet,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(sw ? 'Ingiza Thamani Halisi' : 'Log Actual'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : ListView(padding: const EdgeInsets.all(16), children: [
              // Header chips
              Wrap(spacing: 8, children: [
                _chip('${sw ? 'Lengo' : 'Target'}: ${_fmt(target)}'),
                _chip(sw
                    ? (kpi.reviewPeriod == 'monthly' ? 'Kila Mwezi'
                        : kpi.reviewPeriod == 'quarterly' ? 'Kila Robo Mwaka' : 'Kila Mwaka')
                    : (kpi.reviewPeriod == 'monthly' ? 'Monthly'
                        : kpi.reviewPeriod == 'quarterly' ? 'Quarterly' : 'Annual')),
              ]),
              const SizedBox(height: 16),

              // Mini chart
              if (_entries.isNotEmpty) ...[
                Card(
                  color: _kCard, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 120,
                      child: _KpiSparklineChart(
                          entries: _entries.reversed.take(12).toList().reversed.toList(),
                          target: target),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // History
              Card(
                color: _kCard, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sw ? 'Historia' : 'History',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
                    const SizedBox(height: 12),
                    if (_entries.isEmpty)
                      Text(
                          sw ? 'Hakuna rekodi bado. Gonga kitufe kuingiza ya kwanza.'
                             : 'No entries logged yet. Tap the button to log the first actual.',
                          style: const TextStyle(
                              fontSize: 14, color: _kSecondary, fontStyle: FontStyle.italic))
                    else
                      ...List.generate(_entries.length, (i) {
                        final e = _entries[i];
                        final prev = i < _entries.length - 1 ? _entries[i + 1] : null;
                        final delta = prev != null ? e.actualValue - prev.actualValue : null;
                        final metTarget = e.actualValue >= target;
                        return GestureDetector(
                          onLongPress: () => _deleteEntry(e),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(e.periodLabel,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: _kPrimary)),
                                if (e.note != null && e.note!.isNotEmpty)
                                  Text(e.note!, style: const TextStyle(
                                      fontSize: 12, color: _kSecondary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(_fmt(e.actualValue),
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold,
                                        color: metTarget ? Colors.green : Colors.red)),
                                if (delta != null)
                                  Text('${delta >= 0 ? '+' : ''}${_fmt(delta)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: delta >= 0 ? Colors.green : Colors.red)),
                              ]),
                            ]),
                          ),
                        );
                      }),
                  ]),
                ),
              ),
              const SizedBox(height: 100),
            ]),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary)),
      );
}

class _KpiSparklineChart extends StatelessWidget {
  final List<KpiEntry> entries;
  final double target;

  const _KpiSparklineChart({required this.entries, required this.target});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SparklinePainter(entries: entries, target: target));
  }
}

class _SparklinePainter extends CustomPainter {
  final List<KpiEntry> entries;
  final double target;

  _SparklinePainter({required this.entries, required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final values = entries.map((e) => e.actualValue).toList();
    final maxV = ([...values, target].reduce((a, b) => a > b ? a : b)) * 1.1;
    final minV = values.reduce((a, b) => a < b ? a : b) * 0.9;
    final range = maxV - minV == 0 ? 1.0 : maxV - minV;

    double xOf(int i) => size.width * i / (entries.length - 1).clamp(1, 999);
    double yOf(double v) => size.height - (size.height * (v - minV) / range);

    // Target line
    final tY = yOf(target);
    canvas.drawLine(Offset(0, tY), Offset(size.width, tY),
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..pathEffect = null);

    // Value line
    final path = Path();
    for (int i = 0; i < entries.length; i++) {
      final x = xOf(i);
      final y = yOf(values[i]);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true);

    // Dots
    for (int i = 0; i < entries.length; i++) {
      final met = values[i] >= target;
      canvas.drawCircle(Offset(xOf(i), yOf(values[i])), 3,
          Paint()..color = met ? Colors.green : Colors.red);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.entries != entries || old.target != target;
}

class _LogEntrySheet extends StatefulWidget {
  final String token;
  final int kpiId;
  final bool sw;
  final Kpi kpi;
  final VoidCallback onSaved;

  const _LogEntrySheet({
    required this.token,
    required this.kpiId,
    required this.sw,
    required this.kpi,
    required this.onSaved,
  });

  @override
  State<_LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<_LogEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _periodCtrl;
  late TextEditingController _actualCtrl;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final kpi = widget.kpi;
    String period;
    if (kpi.reviewPeriod == 'monthly') {
      period = DateFormat('MMMM yyyy').format(now);
    } else if (kpi.reviewPeriod == 'quarterly') {
      final q = ((now.month - 1) ~/ 3) + 1;
      period = 'Q$q ${now.year}';
    } else {
      period = now.year.toString();
    }
    _periodCtrl = TextEditingController(text: period);
    _actualCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    _actualCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final res = await WorkService.logKpiEntry(widget.token, widget.kpiId, {
      'actual_value': double.tryParse(_actualCtrl.text.trim()) ?? 0,
      'period_label': _periodCtrl.text.trim(),
      if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ?? 'Failed'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(sw ? 'Ingiza Thamani Halisi' : 'Log Actual',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _periodCtrl,
            decoration: InputDecoration(
              labelText: sw ? 'Lebo ya Kipindi' : 'Period Label',
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (sw ? 'Weka lebo ya kipindi' : 'Enter period label') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _actualCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: sw ? 'Thamani Halisi' : 'Actual Value',
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (sw ? 'Weka thamani halisi' : 'Enter actual value') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: sw ? 'Maelezo (hiari)' : 'Note (optional)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(sw ? 'Ingiza' : 'Log'),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Extract shared `KpiSparklineChart` widget**

Create `lib/team/widgets/kpi_sparkline_chart.dart`:

```dart
// lib/team/widgets/kpi_sparkline_chart.dart
import 'package:flutter/material.dart';
import '../models/work_models.dart';

class KpiSparklineChart extends StatelessWidget {
  final List<KpiEntry> entries;
  final double target;

  const KpiSparklineChart({
    super.key,
    required this.entries,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(entries: entries, target: target),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<KpiEntry> entries;
  final double target;

  _SparklinePainter({required this.entries, required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final values = entries.map((e) => e.actualValue).toList();
    final maxV = ([...values, target].reduce((a, b) => a > b ? a : b)) * 1.1;
    final minV = values.reduce((a, b) => a < b ? a : b) * 0.9;
    final range = maxV - minV == 0 ? 1.0 : maxV - minV;
    double xOf(int i) => size.width * i / (entries.length - 1).clamp(1, 999);
    double yOf(double v) => size.height - (size.height * (v - minV) / range);
    final tY = yOf(target);
    canvas.drawLine(Offset(0, tY), Offset(size.width, tY),
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);
    final path = Path();
    for (int i = 0; i < entries.length; i++) {
      i == 0
          ? path.moveTo(xOf(i), yOf(values[i]))
          : path.lineTo(xOf(i), yOf(values[i]));
    }
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true);
    for (int i = 0; i < entries.length; i++) {
      canvas.drawCircle(Offset(xOf(i), yOf(values[i])), 3,
          Paint()..color = values[i] >= target ? Colors.green : Colors.red);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.entries != entries || old.target != target;
}
```

- [ ] **Step 3: Update `kpi_detail_page.dart` to use the public widget**

In `lib/team/pages/kpi_detail_page.dart`, add this import after the existing imports:
```dart
import '../widgets/kpi_sparkline_chart.dart';
```

Replace the private `_KpiSparklineChart` usage in the body with `KpiSparklineChart`:
```dart
// Find this line:
child: _KpiSparklineChart(
    entries: _entries.reversed.take(12).toList().reversed.toList(),
    target: target),
// Replace with:
child: KpiSparklineChart(
    entries: _entries.reversed.take(12).toList().reversed.toList(),
    target: target),
```

Then delete the private `_KpiSparklineChart` class and `_SparklinePainter` class from the bottom of `kpi_detail_page.dart` (lines ~905–969 in the file), since they're now in the shared widget file.

- [ ] **Step 4: Enable sparkline in `job_description_page.dart`**

In `lib/team/pages/job_description_page.dart`:

1. Uncomment the import:
```dart
import '../widgets/kpi_sparkline_chart.dart';
```

2. In `_kpiCard`, replace the placeholder comment with actual sparkline:
```dart
// Replace:
// Sparkline added in Task 7 Step 3 after KpiSparklineChart widget is created.

// With:
if ((_kpiEntries[kpi.id] ?? []).isNotEmpty) ...[
  const SizedBox(height: 8),
  SizedBox(
    height: 40,
    child: KpiSparklineChart(
        entries: (_kpiEntries[kpi.id] ?? []).reversed.take(6).toList().reversed.toList(),
        target: kpi.targetValue),
  ),
],
```

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/team/widgets/kpi_sparkline_chart.dart \
               lib/team/pages/kpi_detail_page.dart \
               lib/team/pages/job_description_page.dart
```

Expected: No issues.

---

## Task 8: AddWorkTaskSheet

**Files:**
- Create: `lib/team/widgets/add_work_task_sheet.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/team/widgets/add_work_task_sheet.dart
import 'package:flutter/material.dart';
import '../models/team_models.dart';
import '../models/task_models.dart';
import '../services/work_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCard = Color(0xFFFFFFFF);

class AddWorkTaskSheet extends StatefulWidget {
  final String token;
  final int businessId;
  final int? preselectedEmployeeId;
  final String? preselectedEmployeeName;
  final List<Employee> employees; // pass all active employees for dropdown
  final VoidCallback onSaved;
  final bool sw;

  const AddWorkTaskSheet({
    super.key,
    required this.token,
    required this.businessId,
    this.preselectedEmployeeId,
    this.preselectedEmployeeName,
    required this.employees,
    required this.onSaved,
    required this.sw,
  });

  @override
  State<AddWorkTaskSheet> createState() => _AddWorkTaskSheetState();
}

class _AddWorkTaskSheetState extends State<AddWorkTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _taskType = 'adhoc';
  String? _recurrence;
  List<int> _customDays = [];
  DateTime? _dueDate;
  int? _selectedEmployeeId;
  bool _saving = false;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.preselectedEmployeeId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_taskType == 'standing' && _recurrence == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.sw
              ? 'Chagua mpangilio wa kurudia'
              : 'Select recurrence pattern')));
      return;
    }
    if (_taskType == 'adhoc' && _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.sw ? 'Chagua tarehe ya mwisho' : 'Select a due date')));
      return;
    }
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.sw ? 'Chagua mfanyakazi' : 'Select an employee')));
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final body = {
      'employee_id': _selectedEmployeeId,
      'business_id': widget.businessId,
      'title': _titleCtrl.text.trim(),
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      'task_type': _taskType,
      if (_taskType == 'standing') 'recurrence': _recurrence,
      if (_taskType == 'standing' && _recurrence == 'custom' && _customDays.isNotEmpty)
        'recurrence_days': _customDays,
      if (_taskType == 'adhoc' && _dueDate != null)
        'due_date': '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
      'assigned_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    };

    final res = await WorkService.createTask(widget.token, body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.sw ? 'Kazi imegawiwa' : 'Task assigned')));
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ??
              (widget.sw ? 'Imeshindwa kugawanya kazi. Jaribu tena.' : 'Failed to assign task. Try again.')),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final hasPreselected = widget.preselectedEmployeeId != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Gawanya Kazi' : 'Assign Task',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
            const SizedBox(height: 16),

            // Employee dropdown (only when no preselected)
            if (!hasPreselected) ...[
              DropdownButtonFormField<int>(
                value: _selectedEmployeeId,
                decoration: InputDecoration(
                  labelText: sw ? 'Mfanyakazi' : 'Employee',
                  border: const OutlineInputBorder(),
                ),
                items: widget.employees
                    .where((e) => e.isActive)
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
              ),
              const SizedBox(height: 12),
            ],

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Kichwa cha Kazi' : 'Task Title',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (sw ? 'Weka kichwa cha kazi' : 'Enter task title') : null,
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo (hiari)' : 'Description (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Task type toggle
            Text(sw ? 'Aina ya Kazi' : 'Task Type',
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: 'standing',
                    label: Text(sw ? 'Kawaida' : 'Standing')),
                ButtonSegment(
                    value: 'adhoc',
                    label: Text(sw ? 'Maalum' : 'Ad-hoc')),
              ],
              selected: {_taskType},
              onSelectionChanged: (s) =>
                  setState(() { _taskType = s.first; _recurrence = null; }),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                    states.contains(WidgetState.selected) ? _kPrimary : null),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                    states.contains(WidgetState.selected) ? Colors.white : _kPrimary),
              ),
            ),
            const SizedBox(height: 12),

            // Standing: recurrence
            if (_taskType == 'standing') ...[
              Text(sw ? 'Mpangilio wa Kurudia' : 'Recurrence',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final r in ['daily', 'weekly', 'weekdays', 'custom'])
                  ChoiceChip(
                    label: Text(sw
                        ? (r == 'daily' ? 'Kila Siku' : r == 'weekly' ? 'Kila Wiki'
                            : r == 'weekdays' ? 'Siku za Kazi' : 'Maalum')
                        : (r == 'daily' ? 'Daily' : r == 'weekly' ? 'Weekly'
                            : r == 'weekdays' ? 'Weekdays' : 'Custom'),
                        style: const TextStyle(fontSize: 12)),
                    selected: _recurrence == r,
                    onSelected: (_) => setState(() => _recurrence = r),
                    selectedColor: _kPrimary,
                    labelStyle: TextStyle(
                        color: _recurrence == r ? Colors.white : _kPrimary),
                  ),
              ]),
              if (_recurrence == 'custom') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final selected = _customDays.contains(day);
                    return GestureDetector(
                      onTap: () => setState(() {
                        selected ? _customDays.remove(day) : _customDays.add(day);
                      }),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: selected ? _kPrimary : Colors.grey.shade200,
                        child: Text(_dayLabels[i],
                            style: TextStyle(
                                fontSize: 11,
                                color: selected ? Colors.white : _kPrimary,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 12),
            ],

            // Ad-hoc: due date
            if (_taskType == 'adhoc') ...[
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(_dueDate != null
                    ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                    : (sw ? 'Chagua Tarehe ya Mwisho' : 'Select Due Date')),
                style: OutlinedButton.styleFrom(foregroundColor: _kPrimary),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48)),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(sw ? 'Gawanya' : 'Assign'),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/team/widgets/add_work_task_sheet.dart
```

---

## Task 9: EmployeeTasksPage + TaskDetailPage

**Files:**
- Create: `lib/team/pages/employee_tasks_page.dart`
- Create: `lib/team/pages/task_detail_page.dart`

- [ ] **Step 1: Create EmployeeTasksPage**

```dart
// lib/team/pages/employee_tasks_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../models/task_models.dart';
import '../services/work_service.dart';
import '../services/team_service.dart';
import '../widgets/add_work_task_sheet.dart';
import 'task_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class EmployeeTasksPage extends StatefulWidget {
  final int employeeId;
  final int businessId;
  final String employeeName;
  final String token;

  const EmployeeTasksPage({
    super.key,
    required this.employeeId,
    required this.businessId,
    required this.employeeName,
    required this.token,
  });

  @override
  State<EmployeeTasksPage> createState() => _EmployeeTasksPageState();
}

class _EmployeeTasksPageState extends State<EmployeeTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<WorkTask> _tasks = [];
  List<Employee> _allEmployees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      WorkService.getEmployeeTasks(widget.token, widget.employeeId),
      TeamService.getEmployees(widget.token, widget.businessId),
    ]);
    if (!mounted) return;
    final taskRes = results[0] as WorkListResult<WorkTask>;
    final empRes = results[1] as TeamListResult<Employee>;
    setState(() {
      _loading = false;
      _tasks = taskRes.data;
      _allEmployees = empRes.data;
    });
  }

  List<WorkTask> _filtered(String status) =>
      _tasks.where((t) => t.status == status).toList();

  void _openAddSheet(bool sw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddWorkTaskSheet(
        token: widget.token,
        businessId: widget.businessId,
        preselectedEmployeeId: widget.employeeId,
        preselectedEmployeeName: widget.employeeName,
        employees: _allEmployees,
        sw: sw,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(widget.employeeName,
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: _kPrimary),
            tooltip: sw ? 'Gawanya Kazi' : 'Assign Task',
            onPressed: () => _openAddSheet(sw),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: sw ? 'Inasubiri' : 'Pending'),
            Tab(text: sw ? 'Inaendelea' : 'In Progress'),
            Tab(text: sw ? 'Imekamilika' : 'Done'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : Column(children: [
              // Completion rate strip
              Builder(builder: (ctx) {
                final adhoc = _tasks.where((t) => t.isAdhoc).toList();
                final adhocDone = adhoc.where((t) => t.isDone).length;
                final pct = adhoc.isEmpty ? 0 : (adhocDone * 100 ~/ adhoc.length);
                return Container(
                  color: _kCard,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Expanded(child: Text(
                        sw ? 'Ukamilishaji wiki hii: $adhocDone kati ya ${adhoc.length} ($pct%)'
                           : 'Completion this week: $adhocDone of ${adhoc.length} ad-hoc tasks done ($pct%)',
                        style: const TextStyle(fontSize: 12, color: _kSecondary))),
                  ]),
                );
              }),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _TaskList(tasks: _filtered('pending'), allTasks: _tasks, token: widget.token,
                        businessId: widget.businessId, allEmployees: _allEmployees, sw: sw, onChanged: _load),
                    _TaskList(tasks: _filtered('in_progress'), allTasks: _tasks, token: widget.token,
                        businessId: widget.businessId, allEmployees: _allEmployees, sw: sw, onChanged: _load),
                    _TaskList(tasks: _filtered('done'), allTasks: _tasks, token: widget.token,
                        businessId: widget.businessId, allEmployees: _allEmployees, sw: sw, onChanged: _load),
                  ],
                ),
              ),
            ]),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<WorkTask> tasks;
  final List<WorkTask> allTasks;
  final String token;
  final int businessId;
  final List<Employee> allEmployees;
  final bool sw;
  final VoidCallback onChanged;

  const _TaskList({
    required this.tasks,
    required this.allTasks,
    required this.token,
    required this.businessId,
    required this.allEmployees,
    required this.sw,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(sw ? 'Hakuna kazi' : 'No tasks',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async => onChanged(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (_, i) => _WorkTaskCard(
          task: tasks[i],
          allTasks: allTasks,
          token: token,
          businessId: businessId,
          allEmployees: allEmployees,
          sw: sw,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _WorkTaskCard extends StatelessWidget {
  final WorkTask task;
  final List<WorkTask> allTasks;
  final String token;
  final int businessId;
  final List<Employee> allEmployees;
  final bool sw;
  final VoidCallback onChanged;

  const _WorkTaskCard({
    required this.task,
    required this.allTasks,
    required this.token,
    required this.businessId,
    required this.allEmployees,
    required this.sw,
    required this.onChanged,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress': return Colors.amber;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => TaskDetailPage(
              taskId: task.id!,
              task: task,
              token: token,
              businessId: businessId,
              allEmployees: allEmployees,
              sw: sw,
              onChanged: onChanged,
            )));
  }

  Future<void> _showReassign(BuildContext context) async {
    final others = allEmployees
        .where((e) => e.isActive && e.id != task.employeeId)
        .toList();
    if (others.isEmpty) return;
    int? newEmpId;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) {
        final pendingForNew = newEmpId == null ? 0
            : allTasks.where((t) => t.employeeId == newEmpId && t.status == 'pending').length;
        final showWarning = pendingForNew >= 5;
        return AlertDialog(
          title: Text(sw ? 'Gawanya Upya Kazi' : 'Reassign Task',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                  labelText: sw ? 'Mfanyakazi Mpya' : 'New Employee',
                  border: const OutlineInputBorder()),
              items: others.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
              onChanged: (v) => setSt(() => newEmpId = v),
            ),
            if (showWarning) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(child: Text(
                    sw ? 'Mfanyakazi huyu ana kazi $pendingForNew zinazongoja.'
                       : 'This employee has $pendingForNew pending tasks.',
                    style: const TextStyle(fontSize: 12, color: Colors.orange))),
              ]),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(sw ? 'Ghairi' : 'Cancel')),
            ElevatedButton(
              onPressed: newEmpId == null ? null : () async {
                Navigator.pop(ctx);
                final res = await WorkService.reassignTask(token, task.id!, newEmpId!);
                if (res.success) onChanged();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
              child: Text(sw ? 'Gawanya Upya' : 'Reassign'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueStr = task.dueDate != null
        ? DateFormat('dd MMM').format(task.dueDate!)
        : null;
    final recurrenceStr = task.recurrence != null
        ? (sw
            ? (task.recurrence == 'daily' ? 'Kila Siku'
                : task.recurrence == 'weekly' ? 'Kila Wiki'
                : task.recurrence == 'weekdays' ? 'Siku za Kazi' : 'Maalum')
            : (task.recurrence == 'daily' ? 'Daily'
                : task.recurrence == 'weekly' ? 'Weekly'
                : task.recurrence == 'weekdays' ? 'Weekdays' : 'Custom'))
        : null;

    return GestureDetector(
      onTap: () => _openDetail(context),
      onLongPress: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: Text(sw ? 'Gawanya Upya Kazi' : 'Reassign Task'),
                onTap: () => Navigator.pop(context, 'reassign'),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: Text(sw ? 'Tazama Maelezo' : 'View Details'),
                onTap: () => Navigator.pop(context, 'detail'),
              ),
            ]),
          ),
        );
        if (!context.mounted) return;
        if (action == 'reassign') _showReassign(context);
        if (action == 'detail') _openDetail(context);
      },
      child: Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: task.isStanding
                        ? Colors.blue.shade50
                        : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                    task.isStanding
                        ? (sw ? 'Kawaida' : 'Standing')
                        : (sw ? 'Maalum' : 'Ad-hoc'),
                    style: TextStyle(
                        fontSize: 10,
                        color: task.isStanding ? Colors.blue : Colors.purple)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(task.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: _statusColor(task.status),
                    shape: BoxShape.circle),
              ),
            ]),
            if (dueStr != null || recurrenceStr != null) ...[
              const SizedBox(height: 4),
              Text(dueStr ?? recurrenceStr!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            ],
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: task.progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_statusColor(task.status)),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 4),
            Text('${task.progress}%',
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create TaskDetailPage**

```dart
// lib/team/pages/task_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/team_models.dart';
import '../models/task_models.dart';
import '../services/work_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class TaskDetailPage extends StatefulWidget {
  final int taskId;
  final WorkTask task;          // passed from navigation for header display
  final String token;
  final int businessId;
  final List<Employee> allEmployees;
  final bool sw;
  final VoidCallback? onChanged;

  const TaskDetailPage({
    super.key,
    required this.taskId,
    required this.task,
    required this.token,
    required this.businessId,
    required this.allEmployees,
    required this.sw,
    this.onChanged,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  WorkTask? _task;
  List<TaskUpdate> _updates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // We reload via the all-tasks endpoint is not ideal — prefer direct task endpoint.
    // Fallback: reload updates and trust task passed via navigation for header.
    final res = await WorkService.getTaskUpdates(widget.token, widget.taskId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _updates = res.data;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress': return Colors.amber;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _deleteTask() async {
    final sw = widget.sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa Kazi' : 'Delete Task',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw ? 'Futa kazi hii?' : 'Delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final nav = Navigator.of(context);
    final res = await WorkService.deleteTask(widget.token, widget.taskId);
    if (!mounted) return;
    if (res.success) {
      widget.onChanged?.call();
      nav.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ?? 'Failed'), backgroundColor: Colors.red));
    }
  }

  Future<void> _reassign() async {
    final sw = widget.sw;
    final others = widget.allEmployees
        .where((e) => e.isActive && (_task == null || e.id != _task!.employeeId))
        .toList();
    if (others.isEmpty) return;
    int? newEmpId;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) => AlertDialog(
        title: Text(sw ? 'Gawanya Upya Kazi' : 'Reassign Task',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: DropdownButtonFormField<int>(
          decoration: InputDecoration(
              labelText: sw ? 'Mfanyakazi Mpya' : 'New Employee',
              border: const OutlineInputBorder()),
          items: others.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
          onChanged: (v) => setSt(() => newEmpId = v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: newEmpId == null ? null : () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final res = await WorkService.reassignTask(widget.token, widget.taskId, newEmpId!);
              if (!mounted) return;
              final name = others.firstWhere((e) => e.id == newEmpId).name;
              messenger.showSnackBar(SnackBar(
                  content: Text(res.success
                      ? (sw ? 'Kazi imegawiwa kwa $name' : 'Task reassigned to $name')
                      : (res.message ?? 'Failed'))));
              if (res.success) { widget.onChanged?.call(); _load(); }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(sw ? 'Gawanya Upya' : 'Reassign'),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    // Use the last known task from updates or a minimal placeholder
    final progress = _updates.isNotEmpty ? _updates.first.progress : 0;
    final status = _updates.isNotEmpty ? _updates.first.status : 'pending';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(sw ? 'Maelezo ya Kazi' : 'Task Detail',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : ListView(padding: const EdgeInsets.all(16), children: [
              // Task header card
              Card(
                color: _kCard, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.task.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: _kPrimary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: widget.task.isStanding
                                ? Colors.blue.shade50 : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                            widget.task.isStanding
                                ? (sw ? 'Kawaida' : 'Standing')
                                : (sw ? 'Maalum' : 'Ad-hoc'),
                            style: TextStyle(
                                fontSize: 11,
                                color: widget.task.isStanding
                                    ? Colors.blue : Colors.purple)),
                      ),
                      // Assignee chip
                      if (widget.task.assigneeName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12, color: _kSecondary),
                            const SizedBox(width: 4),
                            Text(widget.task.assigneeName!,
                                style: const TextStyle(fontSize: 11, color: _kPrimary)),
                          ]),
                        ),
                      // Due date or recurrence
                      if (widget.task.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 12, color: _kSecondary),
                            const SizedBox(width: 4),
                            Text(DateFormat('dd MMM yyyy').format(widget.task.dueDate!),
                                style: const TextStyle(fontSize: 11, color: _kPrimary)),
                          ]),
                        )
                      else if (widget.task.recurrence != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.repeat_rounded,
                                size: 12, color: _kSecondary),
                            const SizedBox(width: 4),
                            Text(
                                sw
                                    ? (widget.task.recurrence == 'daily' ? 'Kila Siku'
                                        : widget.task.recurrence == 'weekly' ? 'Kila Wiki'
                                        : widget.task.recurrence == 'weekdays'
                                            ? 'Siku za Kazi' : 'Maalum')
                                    : (widget.task.recurrence == 'daily' ? 'Every day'
                                        : widget.task.recurrence == 'weekly' ? 'Every week'
                                        : widget.task.recurrence == 'weekdays'
                                            ? 'Every weekday' : 'Custom'),
                                style: const TextStyle(fontSize: 11, color: _kPrimary)),
                          ]),
                        ),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // Progress ring card
              Card(
                color: _kCard, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    SizedBox(
                      width: 100, height: 100,
                      child: Stack(alignment: Alignment.center, children: [
                        CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                              status == 'done' ? Colors.green
                              : status == 'in_progress' ? Colors.amber
                              : Colors.grey),
                        ),
                        Text('$progress%',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: (status == 'done' ? Colors.green
                              : status == 'in_progress' ? Colors.amber
                              : Colors.grey).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          sw
                              ? (status == 'done' ? 'Imekamilika'
                                  : status == 'in_progress' ? 'Inaendelea' : 'Inasubiri')
                              : (status == 'done' ? 'Done'
                                  : status == 'in_progress' ? 'In Progress' : 'Pending'),
                          style: TextStyle(
                              fontSize: 12,
                              color: status == 'done' ? Colors.green
                                  : status == 'in_progress' ? Colors.amber.shade800
                                  : Colors.grey)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reassign,
                      style: OutlinedButton.styleFrom(foregroundColor: _kPrimary),
                      child: Text(sw ? 'Gawanya Upya' : 'Reassign'),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // Update history
              Card(
                color: _kCard, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sw ? 'Historia ya Masasisho' : 'Update History',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
                    const SizedBox(height: 12),
                    if (_updates.isEmpty)
                      Text(
                          sw ? 'Hakuna masasisho bado. Mfanyakazi hajasasisha maendeleo.'
                             : "No updates yet. Employee hasn't logged progress.",
                          style: const TextStyle(
                              fontSize: 14, color: _kSecondary, fontStyle: FontStyle.italic))
                    else
                      ..._updates.map((u) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: _statusColor(u.status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(
                                sw
                                    ? (u.status == 'done' ? 'Imekamilika'
                                        : u.status == 'in_progress' ? 'Inaendelea' : 'Inasubiri')
                                    : (u.status == 'done' ? 'Done'
                                        : u.status == 'in_progress' ? 'In Progress' : 'Pending'),
                                style: TextStyle(fontSize: 10, color: _statusColor(u.status))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${u.progress}%',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                            if (u.comment != null && u.comment!.isNotEmpty)
                              Text(u.comment!,
                                  style: const TextStyle(fontSize: 12, color: _kPrimary),
                                  maxLines: 3, overflow: TextOverflow.ellipsis),
                            Text(DateFormat('dd MMM yyyy · HH:mm').format(u.createdAt),
                                style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ])),
                        ]),
                      )),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
            ]),
    );
  }
}
```

- [ ] **Step 3: Analyze both files**

```bash
flutter analyze lib/team/pages/employee_tasks_page.dart lib/team/pages/task_detail_page.dart
```

---

## Task 10: WorkBoardPage

**Files:**
- Create: `lib/team/pages/work_board_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/team/pages/work_board_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../models/task_models.dart';
import '../services/team_service.dart';
import '../services/work_service.dart';
import '../widgets/add_work_task_sheet.dart';
import 'task_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class WorkBoardPage extends StatefulWidget {
  final int businessId;
  final String token;

  const WorkBoardPage({
    super.key,
    required this.businessId,
    required this.token,
  });

  @override
  State<WorkBoardPage> createState() => _WorkBoardPageState();
}

class _WorkBoardPageState extends State<WorkBoardPage> {
  List<WorkTask> _tasks = [];
  List<Employee> _employees = [];
  bool _loading = true;

  String _statusFilter = 'all';
  String _typeFilter = 'all';
  int? _employeeFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      WorkService.getAllBusinessTasks(widget.token, widget.businessId),
      TeamService.getEmployees(widget.token, widget.businessId),
    ]);
    if (!mounted) return;
    final taskRes = results[0] as WorkListResult<WorkTask>;
    final empRes = results[1] as TeamListResult<Employee>;
    setState(() {
      _loading = false;
      _tasks = taskRes.data;
      _employees = empRes.data;
    });
  }

  List<WorkTask> get _filtered {
    return _tasks.where((t) {
      if (_statusFilter != 'all' && t.status != _statusFilter) return false;
      if (_typeFilter != 'all' && t.taskType != _typeFilter) return false;
      if (_employeeFilter != null && t.employeeId != _employeeFilter) return false;
      if (_search.isNotEmpty &&
          !t.title.toLowerCase().contains(_search.toLowerCase()) &&
          !(t.assigneeName?.toLowerCase().contains(_search.toLowerCase()) ?? false)) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _pendingCount => _tasks.where((t) => t.status == 'pending').length;
  int get _inProgressCount => _tasks.where((t) => t.status == 'in_progress').length;
  int get _doneCount => _tasks.where((t) => t.status == 'done').length;
  int get _overdueCount => _tasks.where((t) =>
      t.isAdhoc && t.dueDate != null && t.dueDate!.isBefore(DateTime.now()) && !t.isDone).length;

  void _openAdd(bool sw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddWorkTaskSheet(
        token: widget.token,
        businessId: widget.businessId,
        employees: _employees,
        sw: sw,
        onSaved: _load,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress': return Colors.amber;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  Employee? _empById(int id) {
    try { return _employees.firstWhere((e) => e.id == id); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final filtered = _filtered;
    final overdue = _overdueCount;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(sw ? 'Ubao wa Kazi' : 'Work Board',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(sw),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
            : Column(children: [
                // Summary strip
                Container(
                  color: _kCard,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryChip(sw ? 'Inasubiri' : 'Pending', _pendingCount, Colors.grey),
                      _summaryChip(sw ? 'Inaendelea' : 'In Progress', _inProgressCount, Colors.amber),
                      _summaryChip(sw ? 'Imekamilika' : 'Done', _doneCount, Colors.green),
                      _summaryChip(sw ? 'Imechelewa' : 'Overdue', overdue,
                          overdue > 0 ? Colors.red : Colors.grey),
                    ],
                  ),
                ),

                // Search
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: sw ? 'Tafuta kazi au mfanyakazi...' : 'Search tasks or employee...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    // Employee dropdown
                    DropdownButton<int?>(
                      value: _employeeFilter,
                      hint: Text(sw ? 'Wafanyakazi Wote' : 'All Employees',
                          style: const TextStyle(fontSize: 12)),
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem<int?>(
                            value: null,
                            child: Text(sw ? 'Wafanyakazi Wote' : 'All',
                                style: const TextStyle(fontSize: 12))),
                        ..._employees.map((e) => DropdownMenuItem<int?>(
                              value: e.id,
                              child: Text(e.name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setState(() => _employeeFilter = v),
                    ),
                    const SizedBox(width: 8),
                    // Status chips
                    for (final s in ['all', 'pending', 'in_progress', 'done'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                              s == 'all' ? (sw ? 'Zote' : 'All')
                              : s == 'pending' ? (sw ? 'Inasubiri' : 'Pending')
                              : s == 'in_progress' ? (sw ? 'Inaendelea' : 'In Progress')
                              : (sw ? 'Imekamilika' : 'Done'),
                              style: const TextStyle(fontSize: 11)),
                          selected: _statusFilter == s,
                          onSelected: (_) => setState(() => _statusFilter = s),
                          selectedColor: _kPrimary,
                          labelStyle: TextStyle(
                              color: _statusFilter == s ? Colors.white : _kPrimary),
                        ),
                      ),
                    const SizedBox(width: 4),
                    // Type chips
                    for (final t in ['all', 'standing', 'adhoc'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                              t == 'all' ? (sw ? 'Aina Zote' : 'All Types')
                              : t == 'standing' ? (sw ? 'Kawaida' : 'Standing')
                              : (sw ? 'Maalum' : 'Ad-hoc'),
                              style: const TextStyle(fontSize: 11)),
                          selected: _typeFilter == t,
                          onSelected: (_) => setState(() => _typeFilter = t),
                          selectedColor: _kPrimary,
                          labelStyle: TextStyle(
                              color: _typeFilter == t ? Colors.white : _kPrimary),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),

                // Task list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                              _tasks.isEmpty
                                  ? (sw ? 'Hakuna kazi bado. Gonga + kugawanya kazi ya kwanza.'
                                        : 'No tasks assigned yet. Tap + to assign the first task.')
                                  : (sw ? 'Hakuna kazi zinazofanana na vichujio vyako.'
                                        : 'No tasks match your filters.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final t = filtered[i];
                            final emp = _empById(t.employeeId);
                            final due = t.dueDate != null
                                ? DateFormat('dd MMM').format(t.dueDate!)
                                : null;
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => TaskDetailPage(
                                        taskId: t.id!,
                                        task: t,
                                        token: widget.token,
                                        businessId: widget.businessId,
                                        allEmployees: _employees,
                                        sw: sw,
                                        onChanged: _load,
                                      ))),
                              child: Card(
                                color: _kCard, elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.grey.shade200,
                                      child: Text(
                                          emp?.name.isNotEmpty == true
                                              ? emp!.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 12, color: _kPrimary,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(t.title,
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600,
                                              color: _kPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(emp?.name ?? t.assigneeName ?? '',
                                          style: const TextStyle(
                                              fontSize: 11, color: _kSecondary)),
                                      if (due != null)
                                        Text(due,
                                            style: const TextStyle(
                                                fontSize: 11, color: _kSecondary)),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                              color: _statusColor(t.status),
                                              shape: BoxShape.circle)),
                                      const SizedBox(height: 4),
                                      Text('${t.progress}%',
                                          style: const TextStyle(
                                              fontSize: 11, color: _kSecondary)),
                                    ]),
                                  ]),
                                ),
                              ),
                            );
                          }),
                ),
              ]),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$count',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
    ],
  );
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/team/pages/work_board_page.dart
```

- [ ] **Step 3: Commit Part 2 UI**

```bash
git add lib/team/pages/job_description_page.dart \
        lib/team/pages/kpi_detail_page.dart \
        lib/team/widgets/add_work_task_sheet.dart \
        lib/team/pages/employee_tasks_page.dart \
        lib/team/pages/task_detail_page.dart \
        lib/team/pages/work_board_page.dart
git commit -m "feat(work): add manager-side pages — job description, KPIs, tasks, board"
```
