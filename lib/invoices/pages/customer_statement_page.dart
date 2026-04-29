// lib/invoices/pages/customer_statement_page.dart
// Customer statement — shows invoices (debits), payments (credits), and
// running balance for a specific customer over a configurable date range.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ---------------------------------------------------------------------------
// Statement entry — unified debit/credit row
// ---------------------------------------------------------------------------
class _StatementEntry {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  double balance = 0; // computed after sort

  _StatementEntry({
    required this.date,
    required this.description,
    this.debit = 0,
    this.credit = 0,
  });
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class CustomerStatementPage extends StatefulWidget {
  final int businessId;
  final int? customerId;
  final String? customerName;
  final DateTime? initialFrom;
  final DateTime? initialTo;

  const CustomerStatementPage({
    super.key,
    required this.businessId,
    this.customerId,
    this.customerName,
    this.initialFrom,
    this.initialTo,
  });

  @override
  State<CustomerStatementPage> createState() => _CustomerStatementPageState();
}

class _CustomerStatementPageState extends State<CustomerStatementPage> {
  final _currencyFmt = NumberFormat('#,###', 'en');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  bool _loading = true;
  String? _error;

  late DateTime _from;
  late DateTime _to;

  List<Invoice> _allInvoices = [];
  Map<int, List<CreditNote>> _creditNotesByInvoice = {};
  List<_StatementEntry> _entries = [];
  double _openingBalance = 0;
  double _totalInvoiced = 0;
  double _totalPaid = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = widget.initialFrom ?? DateTime(now.year, now.month, 1);
    _to = widget.initialTo ?? DateTime(now.year, now.month, now.day, 23, 59, 59);
    _load();
  }

  // -------------------------------------------------------------------------
  // Data
  // -------------------------------------------------------------------------
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      final result =
          await BusinessService.getInvoices(token, widget.businessId);
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _loading = false;
          _error = result.message ?? 'Failed to load invoices';
        });
        return;
      }

      _allInvoices = result.data;

      // Load credit notes for invoices in the date range
      _creditNotesByInvoice = {};
      final invoicesInRange = _allInvoices.where((inv) {
        final invDate = inv.createdAt ?? inv.dueDate ?? DateTime(2000);
        return !invDate.isBefore(_from) && !invDate.isAfter(_to);
      }).toList();
      final cnFutures = <Future<void>>[];
      for (final inv in invoicesInRange) {
        if (inv.id == null) continue;
        cnFutures.add(() async {
          try {
            final cnResult = await BusinessService.getInvoiceCreditNotes(
                token, inv.id!);
            if (cnResult.success && cnResult.data.isNotEmpty) {
              _creditNotesByInvoice[inv.id!] = cnResult.data;
            }
          } catch (_) {
            // Silently skip — credit notes are supplementary
          }
        }());
      }
      await Future.wait(cnFutures);
      if (!mounted) return;

      _buildStatement();
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _buildStatement() {
    // Filter invoices belonging to this customer
    final customerInvoices = _allInvoices.where((inv) {
      if (widget.customerId != null) return inv.customerId == widget.customerId;
      if (widget.customerName != null) {
        return inv.customerName?.toLowerCase() ==
            widget.customerName!.toLowerCase();
      }
      return false;
    }).toList();

    // Separate entries before range (for opening balance) and in range
    final List<_StatementEntry> inRange = [];
    double openDebits = 0;
    double openCredits = 0;

    final bool sw = mounted
        ? (AppStringsScope.of(context)?.isSwahili ?? false)
        : false;

    for (final inv in customerInvoices) {
      final invDate = inv.createdAt ?? inv.dueDate ?? DateTime(2000);
      final payDate = inv.paidAt ?? invDate;

      if (invDate.isBefore(_from)) {
        // Before range — contribute to opening balance
        openDebits += inv.totalAmount;
        if (inv.amountPaid > 0) openCredits += inv.amountPaid;
        // Credit notes before range also affect opening balance
        if (inv.id != null) {
          final cns = _creditNotesByInvoice[inv.id!] ?? [];
          for (final cn in cns) {
            final cnDate = cn.issuedAt ?? cn.createdAt ?? invDate;
            if (cnDate.isBefore(_from)) {
              openCredits += cn.totalAmount;
            }
          }
        }
      } else if (!invDate.isAfter(_to)) {
        // In range — add debit entry
        inRange.add(_StatementEntry(
          date: invDate,
          description: 'INV #${inv.invoiceNumber}',
          debit: inv.totalAmount,
        ));
        // If there is a payment, add a credit entry
        if (inv.amountPaid > 0) {
          inRange.add(_StatementEntry(
            date: payDate,
            description:
                'PMT — ${inv.invoiceNumber}',
            credit: inv.amountPaid,
          ));
        }
        // Credit note entries for this invoice
        if (inv.id != null) {
          final cns = _creditNotesByInvoice[inv.id!] ?? [];
          for (final cn in cns) {
            final cnDate = cn.issuedAt ?? cn.createdAt ?? invDate;
            if (!cnDate.isBefore(_from) && !cnDate.isAfter(_to)) {
              inRange.add(_StatementEntry(
                date: cnDate,
                description: sw
                    ? 'Nota ya Mkopo #${cn.creditNoteNumber}'
                    : 'Credit Note #${cn.creditNoteNumber}',
                credit: cn.totalAmount,
              ));
            }
          }
        }
      }
      // After range — ignore
    }

    // Sort by date
    inRange.sort((a, b) => a.date.compareTo(b.date));

    // Opening balance = debits - credits before the range
    _openingBalance = openDebits - openCredits;

    // Compute running balance
    double running = _openingBalance;
    for (final e in inRange) {
      running = running + e.debit - e.credit;
      e.balance = running;
    }

    // Totals for entries in range only
    _totalInvoiced = inRange.fold<double>(0, (s, e) => s + e.debit);
    _totalPaid = inRange.fold<double>(0, (s, e) => s + e.credit);
    _entries = inRange;
  }

  // -------------------------------------------------------------------------
  // Date picking helpers
  // -------------------------------------------------------------------------
  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
      _buildStatement();
    });
  }

  void _applyPreset(String key) {
    final now = DateTime.now();
    switch (key) {
      case 'month':
        _from = DateTime(now.year, now.month, 1);
        _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case '3months':
        _from = DateTime(now.year, now.month - 2, 1);
        _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'year':
        _from = DateTime(now.year, 1, 1);
        _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
    setState(() => _buildStatement());
  }

  String _fmtCurrency(double v) => 'TZS ${_currencyFmt.format(v.round())}';

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool sw = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: Text(
          sw ? 'Taarifa ya Mteja' : 'Customer Statement',
          style: const TextStyle(
            color: _kPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _buildError(sw)
              : _buildBody(sw),
    );
  }

  Widget _buildError(bool sw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: Text(sw ? 'Jaribu tena' : 'Retry',
                  style: const TextStyle(color: _kPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool sw) {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildCustomerHeader(sw),
          const SizedBox(height: 12),
          _buildDateRange(sw),
          const SizedBox(height: 16),
          if (_entries.isEmpty) _buildEmpty(sw) else ..._buildTable(sw),
          const SizedBox(height: 16),
          if (_entries.isNotEmpty) _buildSummary(sw),
          const SizedBox(height: 16),
          if (_entries.isNotEmpty) _buildExportActions(sw),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 1. Customer Header
  // -------------------------------------------------------------------------
  Widget _buildCustomerHeader(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: _kPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerName ?? (sw ? 'Mteja' : 'Customer'),
                  style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.customerId != null)
                  Text(
                    'ID: ${widget.customerId}',
                    style: const TextStyle(color: _kSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 2. Date Range Picker
  // -------------------------------------------------------------------------
  Widget _buildDateRange(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _dateTile(
                  label: sw ? 'Kuanzia' : 'From',
                  value: _dateFmt.format(_from),
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateTile(
                  label: sw ? 'Hadi' : 'To',
                  value: _dateFmt.format(_to),
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _presetChip(sw ? 'Mwezi huu' : 'This Month', 'month'),
              _presetChip(sw ? 'Miezi 3' : '3 Months', '3months'),
              _presetChip(sw ? 'Mwaka huu' : 'This Year', 'year'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: _kSecondary, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, String key) {
    return ActionChip(
      label: Text(label,
          style: const TextStyle(color: _kPrimary, fontSize: 12)),
      backgroundColor: _kPrimary.withValues(alpha: 0.06),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _applyPreset(key),
    );
  }

  // -------------------------------------------------------------------------
  // 3. Statement Table
  // -------------------------------------------------------------------------
  List<Widget> _buildTable(bool sw) {
    return [
      // Column headers
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(
          children: [
            SizedBox(
                width: 72,
                child: Text(sw ? 'Tarehe' : 'Date',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600))),
            Expanded(
                child: Text(sw ? 'Maelezo' : 'Description',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600))),
            SizedBox(
                width: 70,
                child: Text(sw ? 'Deni' : 'Debit',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600))),
            SizedBox(
                width: 70,
                child: Text(sw ? 'Malipo' : 'Credit',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600))),
            SizedBox(
                width: 76,
                child: Text(sw ? 'Salio' : 'Balance',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600))),
          ],
        ),
      ),

      // Opening balance row
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: _kCardBg,
        child: Row(
          children: [
            const SizedBox(width: 72),
            Expanded(
              child: Text(
                sw ? 'Salio la Awali' : 'Opening Balance',
                style: const TextStyle(
                    color: _kSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 70),
            const SizedBox(width: 70),
            SizedBox(
              width: 76,
              child: Text(
                _fmtCurrency(_openingBalance),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      // Data rows
      ...List.generate(_entries.length, (i) {
        final e = _entries[i];
        final bg = i.isEven
            ? _kCardBg
            : _kPrimary.withValues(alpha: 0.03);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: bg,
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(_dateFmt.format(e.date),
                    style: const TextStyle(color: _kSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: Text(e.description,
                    style: const TextStyle(color: _kPrimary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  e.debit > 0 ? _fmtCurrency(e.debit) : '',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: _kPrimary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  e.credit > 0 ? _fmtCurrency(e.credit) : '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Colors.green.shade700, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 76,
                child: Text(
                  _fmtCurrency(e.balance),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),

      // Closing balance row
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.06),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 72),
            Expanded(
              child: Text(
                sw ? 'Salio la Mwisho' : 'Closing Balance',
                style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 70),
            const SizedBox(width: 70),
            SizedBox(
              width: 76,
              child: Text(
                _fmtCurrency(_entries.isNotEmpty
                    ? _entries.last.balance
                    : _openingBalance),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // 4. Summary Card
  // -------------------------------------------------------------------------
  Widget _buildSummary(bool sw) {
    final netBalance = _openingBalance + _totalInvoiced - _totalPaid;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow(
            sw ? 'Jumla ya Ankara' : 'Total Invoiced',
            _fmtCurrency(_totalInvoiced),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            sw ? 'Jumla ya Malipo' : 'Total Paid',
            _fmtCurrency(_totalPaid),
          ),
          const Divider(color: Colors.white24, height: 20),
          _summaryRow(
            sw ? 'Salio Halisi' : 'Net Balance',
            _fmtCurrency(netBalance),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white70,
                fontSize: bold ? 14 : 13)),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: bold ? 16 : 13)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 5. Export Actions
  // -------------------------------------------------------------------------
  Widget _buildExportActions(bool sw) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sw
                            ? 'Itakuja hivi karibuni'
                            : 'Coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(
                    sw ? 'Pakua PDF' : 'Download PDF',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sw
                            ? 'Itakuja hivi karibuni'
                            : 'Coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    sw ? 'Shiriki' : 'Share',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sw
                      ? 'Chapisha — Itakuja hivi karibuni'
                      : 'Print — Coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: Text(
              sw ? 'Chapisha' : 'Print',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: BorderSide(color: _kPrimary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 6. Empty State
  // -------------------------------------------------------------------------
  Widget _buildEmpty(bool sw) {
    final name = widget.customerName ?? (sw ? 'mteja huyu' : 'this customer');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 48, color: _kSecondary),
          const SizedBox(height: 12),
          Text(
            sw
                ? 'Hakuna shughuli na $name katika kipindi hiki'
                : 'No transactions with $name in this period',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kSecondary, fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
