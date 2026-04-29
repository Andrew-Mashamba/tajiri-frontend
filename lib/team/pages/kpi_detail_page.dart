// lib/team/pages/kpi_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_models.dart';
import '../services/work_service.dart';
import '../widgets/kpi_sparkline_chart.dart';

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
              Wrap(spacing: 8, children: [
                _chip('${sw ? 'Lengo' : 'Target'}: ${_fmt(target)}'),
                _chip(sw
                    ? (kpi.reviewPeriod == 'monthly' ? 'Kila Mwezi'
                        : kpi.reviewPeriod == 'quarterly' ? 'Kila Robo Mwaka' : 'Kila Mwaka')
                    : (kpi.reviewPeriod == 'monthly' ? 'Monthly'
                        : kpi.reviewPeriod == 'quarterly' ? 'Quarterly' : 'Annual')),
              ]),
              const SizedBox(height: 16),
              if (_entries.isNotEmpty) ...[
                Card(
                  color: _kCard, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 120,
                      child: KpiSparklineChart(
                          entries: _entries.reversed.take(12).toList().reversed.toList(),
                          target: target),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
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
