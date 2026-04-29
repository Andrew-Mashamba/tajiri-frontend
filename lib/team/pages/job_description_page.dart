// lib/team/pages/job_description_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/work_models.dart';
import '../services/work_service.dart';
import '../widgets/kpi_sparkline_chart.dart';
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
  final Map<int, List<KpiEntry>> _kpiEntries = {};

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
      'business_id': widget.businessId,
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

  void _addResponsibility() => setState(() => _respCtrs.add(TextEditingController()));

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
          content: Text(res.message ?? 'Failed'), backgroundColor: Colors.red));
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
              builder: (_) => KpiDetailPage(kpi: kpi, token: widget.token, sw: sw))),
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
          if ((_kpiEntries[kpi.id] ?? []).isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: KpiSparklineChart(
                  entries: (_kpiEntries[kpi.id] ?? []).reversed.take(6).toList().reversed.toList(),
                  target: kpi.targetValue),
            ),
          ],
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
                  _sectionCard(
                    sw ? 'Majukumu' : 'Responsibilities',
                    _editing
                        ? Column(children: [
                            ...List.generate(_respCtrs.length, (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Text('${i + 1}.',
                                    style: const TextStyle(color: _kSecondary, fontSize: 13)),
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
                                        style: const TextStyle(fontSize: 14, color: _kPrimary)),
                                  ),
                                ),
                              ),
                  ),
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
    _targetCtrl = TextEditingController(text: kpi != null ? kpi.targetValue.toString() : '');
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
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? (sw ? 'Hariri KPI' : 'Edit KPI') : (sw ? 'Ongeza KPI' : 'Add KPI'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
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
            initialValue: _unit,
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
