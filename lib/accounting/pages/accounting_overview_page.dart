// lib/accounting/pages/accounting_overview_page.dart
// Tab 1: book summary — entry count, total debit/credit, balanced status.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/accounting_models.dart';
import '../services/accounting_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kError = Color(0xFFB00020);
const Color _kGreen = Color(0xFF2E7D32);

class AccountingOverviewPage extends StatefulWidget {
  final int userId;
  const AccountingOverviewPage({super.key, required this.userId});

  @override
  State<AccountingOverviewPage> createState() => _AccountingOverviewPageState();
}

class _AccountingOverviewPageState extends State<AccountingOverviewPage>
    with AutomaticKeepAliveClientMixin {
  String? _token;
  bool _loading = true;
  BookSummary? _summary;
  DateTime? _dateFrom, _dateTo;

  final _fmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('yyyy-MM-dd');

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final summary = await AccountingService.getBookSummary(
      token: _token!,
      userId: widget.userId,
      dateFrom: _dateFrom != null ? _dateFmt.format(_dateFrom!) : null,
      dateTo: _dateTo != null ? _dateFmt.format(_dateTo!) : null,
    );
    if (mounted) setState(() { _summary = summary; _loading = false; });
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() { if (isFrom) { _dateFrom = picked; } else { _dateTo = picked; } });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DateFilterRow(
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              isSwahili: sw,
              onPickFrom: () => _pickDate(true),
              onPickTo: () => _pickDate(false),
              onClear: () { setState(() { _dateFrom = null; _dateTo = null; }); _load(); },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              ))
            else if (_summary == null)
              Center(child: Text(sw ? 'Hakuna data' : 'No data available',
                  style: const TextStyle(color: _kSecondary)))
            else ...[
              Row(children: [
                _MetricCard(
                  label: sw ? 'Ingizo' : 'Entries',
                  value: _summary!.entryCount.toString(),
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  label: sw ? 'Usawa' : 'Balanced',
                  value: _summary!.balanced ? (sw ? 'Ndio' : 'Yes') : (sw ? 'Hapana' : 'No'),
                  icon: _summary!.balanced ? Icons.check_circle_rounded : Icons.warning_rounded,
                  valueColor: _summary!.balanced ? _kGreen : _kError,
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _MetricCard(
                  label: sw ? 'Jumla Deni' : 'Total Debit',
                  value: _fmt.format(_summary!.totalDebit),
                  icon: Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  label: sw ? 'Jumla Mkopo' : 'Total Credit',
                  value: _fmt.format(_summary!.totalCredit),
                  icon: Icons.arrow_downward_rounded,
                ),
              ]),
              if (_summary!.unbalancedEntries.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(sw ? 'Ingizo Zisizo Sawa' : 'Unbalanced Entries',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kError)),
                const SizedBox(height: 8),
                ..._summary!.unbalancedEntries.map((e) => _UnbalancedCard(entry: e, fmt: _fmt)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DateFilterRow extends StatelessWidget {
  final DateTime? dateFrom, dateTo;
  final bool isSwahili;
  final VoidCallback onPickFrom, onPickTo, onClear;

  const _DateFilterRow({
    required this.dateFrom, required this.dateTo, required this.isSwahili,
    required this.onPickFrom, required this.onPickTo, required this.onClear,
  });

  String _label(DateTime? d, String fallback) =>
      d != null ? DateFormat('dd MMM yyyy').format(d) : fallback;

  @override
  Widget build(BuildContext context) {
    final sw = isSwahili;
    return Row(children: [
      Expanded(child: OutlinedButton(
        onPressed: onPickFrom,
        style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
            side: const BorderSide(color: Color(0xFFE0E0E0))),
        child: Text(_label(dateFrom, sw ? 'Tangu' : 'From'),
            style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      )),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton(
        onPressed: onPickTo,
        style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
            side: const BorderSide(color: Color(0xFFE0E0E0))),
        child: Text(_label(dateTo, sw ? 'Hadi' : 'To'),
            style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      )),
      if (dateFrom != null || dateTo != null) ...[
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.clear_rounded, size: 20, color: _kSecondary),
            onPressed: onClear),
      ],
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? valueColor;

  const _MetricCard({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: _kSecondary),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor ?? _kPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _UnbalancedCard extends StatelessWidget {
  final UnbalancedEntry entry;
  final NumberFormat fmt;
  const _UnbalancedCard({required this.entry, required this.fmt});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kError.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, size: 18, color: _kError),
      const SizedBox(width: 10),
      Expanded(child: Text(entry.entryNumber,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      Text('Δ ${fmt.format(entry.difference)}',
          style: const TextStyle(fontSize: 12, color: _kError, fontWeight: FontWeight.w600)),
    ]),
  );
}
