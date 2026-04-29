// lib/accounting/pages/accounting_reports_page.dart
// Tab 3: Trial Balance | P&L | Balance Sheet with SegmentedButton switcher.
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

enum _Report { trialBalance, pnl, balanceSheet }

class AccountingReportsPage extends StatefulWidget {
  final int userId;
  const AccountingReportsPage({super.key, required this.userId});

  @override
  State<AccountingReportsPage> createState() => _AccountingReportsPageState();
}

class _AccountingReportsPageState extends State<AccountingReportsPage>
    with AutomaticKeepAliveClientMixin {
  String? _token;
  _Report _report = _Report.trialBalance;
  bool _loading = true;

  // Trial Balance
  TrialBalance? _trialBalance;
  DateTime? _tbFrom, _tbTo;

  // P&L
  ProfitAndLoss? _pnl;
  DateTime _pnlFrom = DateTime(DateTime.now().year, 1, 1);
  DateTime _pnlTo = DateTime.now();

  // Balance Sheet
  BalanceSheet? _balanceSheet;

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
    await _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    switch (_report) {
      case _Report.trialBalance:
        final tb = await AccountingService.getTrialBalance(
          token: _token!, userId: widget.userId,
          dateFrom: _tbFrom != null ? _dateFmt.format(_tbFrom!) : null,
          dateTo: _tbTo != null ? _dateFmt.format(_tbTo!) : null,
        );
        if (mounted) setState(() { _trialBalance = tb; _loading = false; });
      case _Report.pnl:
        final pnl = await AccountingService.getProfitAndLoss(
          token: _token!, userId: widget.userId,
          dateFrom: _dateFmt.format(_pnlFrom),
          dateTo: _dateFmt.format(_pnlTo),
        );
        if (mounted) setState(() { _pnl = pnl; _loading = false; });
      case _Report.balanceSheet:
        final bs = await AccountingService.getBalanceSheet(
            token: _token!, userId: widget.userId);
        if (mounted) setState(() { _balanceSheet = bs; _loading = false; });
    }
  }

  Future<void> _pickDate(bool isFrom, {bool isPnl = false}) async {
    final current = isPnl ? (isFrom ? _pnlFrom : _pnlTo) : (isFrom ? _tbFrom : _tbTo);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      if (isPnl) {
        if (isFrom) { _pnlFrom = picked; } else { _pnlTo = picked; }
      } else {
        if (isFrom) { _tbFrom = picked; } else { _tbTo = picked; }
      }
    });
    await _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<_Report>(
            segments: [
              ButtonSegment(value: _Report.trialBalance,
                  label: Text(sw ? 'Mizani' : 'Trial Bal.', style: const TextStyle(fontSize: 11))),
              ButtonSegment(value: _Report.pnl,
                  label: Text(sw ? 'Faida/Hasara' : 'P&L', style: const TextStyle(fontSize: 11))),
              ButtonSegment(value: _Report.balanceSheet,
                  label: Text(sw ? 'Karatasi' : 'Bal. Sheet', style: const TextStyle(fontSize: 11))),
            ],
            selected: {_report},
            onSelectionChanged: (s) {
              setState(() => _report = s.first);
              _loadCurrent();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected) ? _kPrimary : _kCardBg),
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected) ? Colors.white : _kPrimary),
            ),
          ),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadCurrent,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (_report == _Report.trialBalance) _buildTrialBalance(sw),
                    if (_report == _Report.pnl) _buildPnl(sw),
                    if (_report == _Report.balanceSheet) _buildBalanceSheet(sw),
                  ],
                ),
              )),
      ]),
    );
  }

  Widget _buildTrialBalance(bool sw) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => _pickDate(true),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: Text(_tbFrom != null ? _displayDateFmt.format(_tbFrom!) : (sw ? 'Tangu' : 'From'),
              style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(
          onPressed: () => _pickDate(false),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: Text(_tbTo != null ? _displayDateFmt.format(_tbTo!) : (sw ? 'Hadi' : 'To'),
              style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
      ]),
      const SizedBox(height: 16),
      if (_trialBalance == null)
        Center(child: Text(sw ? 'Hakuna data' : 'No data',
            style: const TextStyle(color: _kSecondary)))
      else
        _ReportTable(
          headers: [sw ? 'Akaunti' : 'Account', sw ? 'Deni' : 'Debit', sw ? 'Mkopo' : 'Credit'],
          rows: _trialBalance!.lines.map((l) => [
            '${l.coaCode} ${l.accountName}',
            _amtFmt.format(l.debit),
            _amtFmt.format(l.credit),
          ]).toList(),
        ),
    ]);
  }

  Widget _buildPnl(bool sw) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => _pickDate(true, isPnl: true),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: Text(_displayDateFmt.format(_pnlFrom),
              style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(
          onPressed: () => _pickDate(false, isPnl: true),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: Text(_displayDateFmt.format(_pnlTo),
              style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
      ]),
      const SizedBox(height: 16),
      if (_pnl == null)
        Center(child: Text(sw ? 'Chagua kipindi' : 'Select a period to load',
            style: const TextStyle(color: _kSecondary)))
      else ...[
        _SectionHeader(title: sw ? 'Mapato' : 'Income'),
        _ReportTable(
          headers: [sw ? 'Akaunti' : 'Account', sw ? 'Kiasi' : 'Amount'],
          rows: _pnl!.incomeAccounts.map((a) => [
            '${a.coaCode} ${a.accountName}', _amtFmt.format(a.amount)]).toList(),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: sw ? 'Matumizi' : 'Expenses'),
        _ReportTable(
          headers: [sw ? 'Akaunti' : 'Account', sw ? 'Kiasi' : 'Amount'],
          rows: _pnl!.expenseAccounts.map((a) => [
            '${a.coaCode} ${a.accountName}', _amtFmt.format(a.amount)]).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _pnl!.netProfit >= 0 ? _kGreen.withValues(alpha: 0.08) : _kError.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text(sw ? 'Faida/Hasara Halisi' : 'Net Profit / Loss',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: _pnl!.netProfit >= 0 ? _kGreen : _kError)),
            const Spacer(),
            Text(_amtFmt.format(_pnl!.netProfit),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: _pnl!.netProfit >= 0 ? _kGreen : _kError)),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildBalanceSheet(bool sw) {
    if (_balanceSheet == null) {
      return Center(child: Text(sw ? 'Hakuna data' : 'No data',
          style: const TextStyle(color: _kSecondary)));
    }
    return Column(children: [
      _BsSection(
        title: sw ? 'Mali' : 'Assets',
        accounts: _balanceSheet!.assets,
        amtFmt: _amtFmt,
      ),
      const SizedBox(height: 12),
      _BsSection(
        title: sw ? 'Madeni' : 'Liabilities',
        accounts: _balanceSheet!.liabilities,
        amtFmt: _amtFmt,
      ),
      const SizedBox(height: 12),
      _BsSection(
        title: sw ? 'Hisa' : 'Equity',
        accounts: _balanceSheet!.equity,
        amtFmt: _amtFmt,
      ),
    ]);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
  );
}

class _ReportTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const _ReportTable({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('—', style: TextStyle(color: _kSecondary))),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: headers.asMap().entries.map((e) => Expanded(
            flex: e.key == 0 ? 3 : 2,
            child: Text(e.value, style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: _kSecondary),
                textAlign: e.key == 0 ? TextAlign.left : TextAlign.right),
          )).toList()),
        ),
        const Divider(height: 1, thickness: 0.5),
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: row.asMap().entries.map((e) => Expanded(
            flex: e.key == 0 ? 3 : 2,
            child: Text(e.value, style: const TextStyle(fontSize: 12, color: _kPrimary),
                textAlign: e.key == 0 ? TextAlign.left : TextAlign.right,
                maxLines: 2, overflow: TextOverflow.ellipsis),
          )).toList()),
        )),
      ]),
    );
  }
}

class _BsSection extends StatelessWidget {
  final String title;
  final List<BsAccount> accounts;
  final NumberFormat amtFmt;

  const _BsSection({required this.title, required this.accounts, required this.amtFmt});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _kCardBg, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(children: [
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
        const Spacer(),
        Text(
          amtFmt.format(accounts.fold(0.0, (s, a) => s + a.amount)),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        const SizedBox(width: 8),
      ]),
      children: accounts.map((a) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(a.coaCode, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          const SizedBox(width: 8),
          Expanded(child: Text(a.accountName,
              style: const TextStyle(fontSize: 12, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(amtFmt.format(a.amount),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
        ]),
      )).toList(),
    ),
  );
}
