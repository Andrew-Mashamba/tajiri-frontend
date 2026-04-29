// lib/accounting/pages/accounting_journal_page.dart
// Tab 2: paginated journal ledger + entry detail bottom sheet.
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
const Color _kGreen = Color(0xFF2E7D32);
const Color _kError = Color(0xFFB00020);

class AccountingJournalPage extends StatefulWidget {
  final int userId;
  const AccountingJournalPage({super.key, required this.userId});

  @override
  State<AccountingJournalPage> createState() => _AccountingJournalPageState();
}

class _AccountingJournalPageState extends State<AccountingJournalPage>
    with AutomaticKeepAliveClientMixin {
  String? _token;
  bool _loading = true;
  bool _loadingMore = false;
  List<JournalEntry> _entries = [];
  DateTime? _dateFrom, _dateTo;
  String? _sourceType;
  int _perPage = 20;

  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _displayDateFmt = DateFormat('dd MMM yyyy');
  final _amtFmt = NumberFormat('#,##0.00');

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
    await _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_token == null) {
      if (mounted) setState(() { _loading = false; _loadingMore = false; });
      return;
    }
    if (reset) {
      if (mounted) setState(() { _loading = true; _entries = []; _perPage = 20; });
    } else {
      if (mounted) setState(() => _loadingMore = true);
    }
    final entries = await AccountingService.getJournalLedger(
      token: _token!,
      userId: widget.userId,
      dateFrom: _dateFrom != null ? _dateFmt.format(_dateFrom!) : null,
      dateTo: _dateTo != null ? _dateFmt.format(_dateTo!) : null,
      sourceType: _sourceType,
      perPage: _perPage,
    );
    if (mounted) setState(() { _entries = entries; _loading = false; _loadingMore = false; });
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() { if (isFrom) { _dateFrom = picked; } else { _dateTo = picked; } });
    await _load(reset: true);
  }

  void _showEntryDetail(JournalEntry entry) {
    final sw = _isSwahili;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: Text(entry.entryNumber,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (!entry.totals.balanced)
                const Icon(Icons.warning_amber_rounded, size: 18, color: _kError),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(entry.description,
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const Divider(height: 24),
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(children: [
                  _th(sw ? 'Nambari' : 'Code'),
                  _th(sw ? 'Akaunti' : 'Account'),
                  _th(sw ? 'Deni' : 'Debit', align: TextAlign.right),
                  _th(sw ? 'Mkopo' : 'Credit', align: TextAlign.right),
                ]),
                ...entry.lines.map((l) => TableRow(children: [
                  _td(l.coaCode),
                  _td(l.accountName),
                  _td(_amtFmt.format(l.debit), align: TextAlign.right),
                  _td(_amtFmt.format(l.credit), align: TextAlign.right),
                ])),
              ],
            ),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(sw ? 'Jumla' : 'Totals',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              Text('${_amtFmt.format(entry.totals.debit)} / ${_amtFmt.format(entry.totals.credit)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: entry.totals.balanced ? _kGreen : _kError)),
            ]),
            const SizedBox(height: 24),
          ])),
        ]),
      ),
    );
  }

  Widget _th(String t, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kSecondary),
        textAlign: align),
  );

  Widget _td(String t, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(t, style: const TextStyle(fontSize: 12, color: _kPrimary),
        textAlign: align, maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _pickDate(true),
                style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
                    side: const BorderSide(color: Color(0xFFE0E0E0))),
                child: Text(_dateFrom != null ? _displayDateFmt.format(_dateFrom!) : (sw ? 'Tangu' : 'From'),
                    style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(
                onPressed: () => _pickDate(false),
                style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
                    side: const BorderSide(color: Color(0xFFE0E0E0))),
                child: Text(_dateTo != null ? _displayDateFmt.format(_dateTo!) : (sw ? 'Hadi' : 'To'),
                    style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
              if (_dateFrom != null || _dateTo != null || _sourceType != null) ...[
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.clear_rounded, size: 20, color: _kSecondary),
                    onPressed: () { setState(() { _dateFrom = null; _dateTo = null; _sourceType = null; }); _load(reset: true); }),
              ],
            ]),
            const SizedBox(height: 8),
            _SourceTypeFilter(
              key: ValueKey(_sourceType),
              value: _sourceType,
              isSwahili: sw,
              onChanged: (v) { setState(() => _sourceType = v); _load(reset: true); },
            ),
          ]),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _entries.isEmpty
                ? Center(child: Text(sw ? 'Hakuna ingizo' : 'No journal entries',
                    style: const TextStyle(color: _kSecondary)))
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: () => _load(reset: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _entries.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        if (i == _entries.length) {
                          return _loadingMore
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
                              : TextButton(
                                  onPressed: () { setState(() => _perPage += 20); _load(); },
                                  child: Text(sw ? 'Pakia zaidi' : 'Load more',
                                      style: const TextStyle(color: _kPrimary)));
                        }
                        final e = _entries[i];
                        return _EntryCard(
                          entry: e,
                          amtFmt: _amtFmt,
                          dateFmt: _displayDateFmt,
                          isSwahili: sw,
                          onTap: () => _showEntryDetail(e),
                        );
                      },
                    ),
                  )),
      ]),
    );
  }
}

class _SourceTypeFilter extends StatelessWidget {
  final String? value;
  final bool isSwahili;
  final ValueChanged<String?> onChanged;

  const _SourceTypeFilter({super.key, required this.value, required this.isSwahili, required this.onChanged});

  static const _types = ['invoice', 'expense', 'payroll', 'payment', 'manual'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        isDense: true,
      ),
      hint: Text(isSwahili ? 'Aina yote' : 'All types',
          style: const TextStyle(fontSize: 13, color: _kSecondary)),
      items: [
        DropdownMenuItem(value: null, child: Text(isSwahili ? 'Aina zote' : 'All types',
            style: const TextStyle(fontSize: 13))),
        ..._types.map((t) => DropdownMenuItem(value: t, child: Text(t,
            style: const TextStyle(fontSize: 13)))),
      ],
      onChanged: onChanged,
    );
  }
}

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final NumberFormat amtFmt;
  final DateFormat dateFmt;
  final bool isSwahili;
  final VoidCallback onTap;

  const _EntryCard({
    required this.entry, required this.amtFmt, required this.dateFmt,
    required this.isSwahili, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(entry.entryNumber,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (entry.sourceType.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(entry.sourceType,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
            ),
        ]),
        if (entry.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(entry.description,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Text(entry.postedAt != null ? dateFmt.format(entry.postedAt!) : '',
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
          const Spacer(),
          Icon(entry.totals.balanced ? Icons.check_circle_rounded : Icons.warning_rounded,
              size: 14, color: entry.totals.balanced ? _kGreen : _kError),
          const SizedBox(width: 4),
          Text('${amtFmt.format(entry.totals.debit)} Dr',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
        ]),
      ]),
    ),
  );
}
