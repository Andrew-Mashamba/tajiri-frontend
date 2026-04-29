// lib/invoices/pages/invoices_page.dart
// Invoice management dashboard with hero summary, aging report, search,
// status-tab filtering, send, mark-as-paid, and email actions.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../widgets/invoice_card.dart';
import 'create_invoice_page.dart';
import 'invoice_detail_page.dart';
import '../../business/pages/email/email_compose_page.dart';
import 'invoice_settings_page.dart';
import 'invoice_reports_page.dart';
import 'received_invoices_page.dart';
import 'recurring_invoices_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class InvoicesPage extends StatefulWidget {
  final int businessId;
  const InvoicesPage({super.key, required this.businessId});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage>
    with SingleTickerProviderStateMixin {
  String? _token;
  int? _currentUserId;
  bool _loading = true;
  String? _error;
  List<Invoice> _invoices = [];
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'amount', 'due_date'
  bool _sortAsc = false;
  int _viewIndex = 0; // 0 = Sent, 1 = Received, 2 = Recurring

  final _nf = NumberFormat('#,###', 'en');
  final _df = DateFormat('dd/MM/yyyy');

  // 6 tabs: All | Drafts | Sent | Paid | Partially Paid | Overdue
  static const _statusFilters = [
    null, 'draft', 'sent', 'paid', 'partially_paid', 'overdue',
  ];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  List<String> get _tabs => _sw
      ? const [
          'Zote', 'Rasimu', 'Zimetumwa', 'Zimelipwa',
          'Sehemu imelipwa', 'Zimechelewa',
        ]
      : const [
          'All', 'Drafts', 'Sent', 'Paid',
          'Partially Paid', 'Overdue',
        ];

  // ── Computed summaries ──────────────────────────────────────────────

  double get _outstandingTotal => _invoices
      .where((i) =>
          i.status != InvoiceStatus.paid &&
          i.status != InvoiceStatus.cancelled &&
          i.status != InvoiceStatus.void_status &&
          i.status != InvoiceStatus.credit_noted)
      .fold(0.0, (sum, i) => sum + i.balanceRemaining);

  double get _overdueTotal => _invoices
      .where((i) => isInvoiceOverdue(i))
      .fold(0.0, (sum, i) => sum + i.balanceRemaining);

  double get _revenueThisMonth {
    final now = DateTime.now();
    return _invoices
        .where((i) =>
            i.status == InvoiceStatus.paid &&
            i.paidAt != null &&
            i.paidAt!.year == now.year &&
            i.paidAt!.month == now.month)
        .fold(0.0, (sum, i) => sum + i.amountPaid);
  }

  /// Monthly paid revenue for the last 6 months (index 0 = oldest).
  List<double> get _monthlyRevenueLast6 {
    final now = DateTime.now();
    final result = List<double>.filled(6, 0);
    for (final inv in _invoices) {
      if (inv.status != InvoiceStatus.paid || inv.paidAt == null) continue;
      final paid = inv.paidAt!;
      // Calculate how many months ago this payment was
      final monthsAgo = (now.year - paid.year) * 12 + (now.month - paid.month);
      if (monthsAgo < 0 || monthsAgo >= 6) continue;
      // Index: 5 = current month, 4 = 1 month ago, ... 0 = 5 months ago
      result[5 - monthsAgo] += inv.amountPaid;
    }
    return result;
  }

  /// Unpaid invoices grouped by aging bucket.
  /// Returns [0-30, 31-60, 61-90, 90+] as list of (count, amount).
  List<_AgingBucket> get _agingBuckets {
    final now = DateTime.now();
    int c0 = 0, c1 = 0, c2 = 0, c3 = 0;
    double a0 = 0, a1 = 0, a2 = 0, a3 = 0;

    for (final inv in _invoices) {
      if (inv.status == InvoiceStatus.paid ||
          inv.status == InvoiceStatus.cancelled ||
          inv.status == InvoiceStatus.void_status ||
          inv.status == InvoiceStatus.credit_noted) {
        continue;
      }
      if (inv.dueDate == null) {
        continue;
      }
      final days = now.difference(inv.dueDate!).inDays;
      if (days < 0) {
        continue; // not yet due
      }
      final bal = inv.balanceRemaining;
      if (days <= 30) {
        c0++;
        a0 += bal;
      } else if (days <= 60) {
        c1++;
        a1 += bal;
      } else if (days <= 90) {
        c2++;
        a2 += bal;
      } else {
        c3++;
        a3 += bal;
      }
    }
    return [
      _AgingBucket('0-30', c0, a0, Colors.grey.shade600),
      _AgingBucket('31-60', c1, a1, Colors.amber.shade700),
      _AgingBucket('61-90', c2, a2, Colors.orange.shade700),
      _AgingBucket('90+', c3, a3, Colors.red.shade700),
    ];
  }

  // ── Filtering ───────────────────────────────────────────────────────

  List<Invoice> get _filtered {
    var list = _invoices;

    // Tab filter
    final f = _statusFilters[_tabCtrl.index];
    if (f != null) {
      if (f == 'overdue') {
        list = list.where((i) => isInvoiceOverdue(i)).toList();
      } else {
        list = list.where((i) => i.status.name == f).toList();
      }
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((i) {
        final q = _searchQuery;
        return i.invoiceNumber.toLowerCase().contains(q) ||
            (i.customerName ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // Sort
    list = List.of(list);
    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'amount':
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'due_date':
          final ad = a.dueDate ?? DateTime(2000);
          final bd = b.dueDate ?? DateTime(2000);
          cmp = ad.compareTo(bd);
          break;
        case 'date':
        default:
          final ad = a.createdAt ?? DateTime(2000);
          final bd = b.createdAt ?? DateTime(2000);
          cmp = ad.compareTo(bd);
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  // ── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _currentUserId = storage.getUser()?.userId;
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await BusinessService.getInvoices(_token!, widget.businessId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _invoices = res.data;
          } else {
            _error = res.message ?? 'Failed to load invoices';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────

  Future<void> _sendInvoice(Invoice inv) async {
    if (_token == null || inv.id == null) return;
    final sw = _sw;
    try {
      final res = await BusinessService.sendInvoice(_token!, inv.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.success
                ? (sw ? 'Ankara imetumwa!' : 'Invoice sent!')
                : res.message ?? (sw ? 'Imeshindikana' : 'Failed'))));
        if (res.success) _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sw ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  Future<void> _markPaid(Invoice inv) async {
    if (_token == null || inv.id == null) return;
    final sw = _sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Thibitisha Malipo' : 'Confirm Payment',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw
            ? 'Thibitisha kuwa ankara ${inv.invoiceNumber} imelipwa?'
            : 'Confirm that invoice ${inv.invoiceNumber} has been paid?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(sw ? 'Thibitisha' : 'Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final res = await BusinessService.markInvoicePaid(_token!, inv.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.success
                ? (sw ? 'Ankara imelipwa!' : 'Invoice marked as paid!')
                : res.message ?? (sw ? 'Imeshindikana' : 'Failed'))));
        if (res.success) _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sw ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  void _emailInvoice(Invoice inv) {
    final itemsText = inv.items
        .map((item) =>
            '- ${item.description} x${item.quantity.toStringAsFixed(0)} = TZS ${_nf.format(item.totalPrice)}')
        .join('\n');

    final body = 'Invoice: ${inv.invoiceNumber}\n'
        'To: ${inv.customerName ?? "Customer"}\n'
        'Date: ${inv.createdAt != null ? _df.format(inv.createdAt!) : "-"}\n'
        'Due: ${inv.dueDate != null ? _df.format(inv.dueDate!) : "-"}\n\n'
        'Items:\n$itemsText\n\n'
        'Subtotal: TZS ${_nf.format(inv.subtotal)}\n'
        'VAT (18%): TZS ${_nf.format(inv.vatAmount)}\n'
        'Total: TZS ${_nf.format(inv.totalAmount)}\n\n'
        'Please make payment before ${inv.dueDate != null ? _df.format(inv.dueDate!) : "the due date"}.\n';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailComposePage(
          fromAddress: 'business@tajiri.co.tz',
          fromName: 'TAJIRI Business',
          initialSubject: 'Invoice ${inv.invoiceNumber}',
          initialBody: body,
        ),
      ),
    );
  }

  void _openInvoiceDetail(Invoice inv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoice: inv,
          businessId: widget.businessId,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(
        children: [
          // ── Sent / Received / Recurring Toggle ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _viewTab(0, sw ? 'Zilizotumwa' : 'Sent', isFirst: true),
                _viewTab(1, sw ? 'Zilizopokelewa' : 'Received'),
                _viewTab(2, sw ? 'Za Kujirudia' : 'Recurring', isLast: true),
              ],
            ),
          ),

          // ── Received Invoices View ─────────────────────────────────
          if (_viewIndex == 1)
            Expanded(
              child: _currentUserId != null
                  ? ReceivedInvoicesPage(userId: _currentUserId!)
                  : Center(child: Text(sw ? 'Ingia kwanza' : 'Please log in')),
            ),

          // ── Recurring Invoices View ────────────────────────────────
          if (_viewIndex == 2)
            Expanded(
              child: RecurringInvoicesPage(businessId: widget.businessId),
            ),

          // ── Sent/Outgoing Invoices View ────────────────────────────
          if (_viewIndex == 0) ...[
          // ── Hero Summary Cards ────────────────────────────────────
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.account_balance_wallet_rounded,
                      label: sw ? 'Deni' : 'Outstanding',
                      amount: _outstandingTotal,
                      iconTone: _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.warning_amber_rounded,
                      label: sw ? 'Zimechelewa' : 'Overdue',
                      amount: _overdueTotal,
                      iconTone: _kSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.trending_up_rounded,
                      label: sw ? 'Mapato (Mwezi)' : 'Revenue (Month)',
                      amount: _revenueThisMonth,
                      iconTone: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

          // ── Revenue Sparkline ──────────────────────────────────
          if (!_loading && _error == null) _buildRevenueSparkline(sw),

          // ── Aging Report ──────────────────────────────────────────
          if (!_loading && _error == null) _buildAgingReport(sw),

          _buildSearchSortSection(sw),

          // ── Pill Button + Tab Bar ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                // Reports pill
                _topPillActionButton(
                  label: sw ? 'Ripoti' : 'Reports',
                  icon: Icons.bar_chart_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => InvoiceReportsPage(businessId: widget.businessId),
                  )),
                ),
                const SizedBox(width: 8),
                // Settings gear
                SizedBox(
                  height: 34,
                  width: 34,
                  child: Material(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => InvoiceSettingsPage(businessId: widget.businessId),
                      )),
                      child: const Icon(Icons.settings_rounded, size: 16, color: _kPrimary),
                    ),
                  ),
                ),
                const Spacer(),
                _topPillActionButton(
                  label: sw ? 'Unda Ankara' : 'Create Invoice',
                  icon: Icons.add_rounded,
                  onTap: () async {
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateInvoicePage(businessId: widget.businessId),
                      ),
                    );
                    if (created == true) _load();
                  },
                ),
              ],
            ),
          ),
          Material(
            color: _kCardBg,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: _kPrimary,
              unselectedLabelColor: _kSecondary,
              indicatorColor: _kPrimary,
              indicatorWeight: 2,
              isScrollable: true,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // ── Invoice List ──────────────────────────────────────────
          Expanded(child: _buildBody(sw)),
          ], // end if (!_showReceived)
        ],
      ),
    );
  }

  // ── Summary Card ──────────────────────────────────────────────────

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color iconTone,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF999999).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconTone.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconTone),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _kSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'TZS ${_nf.format(amount)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Revenue Sparkline ──────────────────────────────────────────────

  Widget _buildRevenueSparkline(bool sw) {
    final values = _monthlyRevenueLast6;
    // Only show if at least 2 months have data
    final monthsWithData = values.where((v) => v > 0).length;
    if (monthsWithData < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sw ? 'Mapato (Miezi 6)' : 'Revenue (6 Months)',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _kSecondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: values,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Aging Report Bar ──────────────────────────────────────────────

  Widget _buildAgingReport(bool sw) {
    final buckets = _agingBuckets;
    final hasAny = buckets.any((b) => b.count > 0);
    if (!hasAny) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sw ? 'Umri wa Madeni' : 'Aging Report',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: buckets.map((b) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(
                          '${b.label} ${sw ? "siku" : "days"}',
                          style: TextStyle(
                              fontSize: 9,
                              color: b.color,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: b.count > 0
                                ? b.color.withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${b.count}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: b.color),
                        ),
                        Text(
                          'TZS ${_nf.format(b.amount)}',
                          style:
                              const TextStyle(fontSize: 9, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body (loading / error / empty / list) ─────────────────────────

  Widget _buildBody(bool sw) {
    if (_loading) {
      return const Center(
          child:
              CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              sw ? 'Imeshindikana kupakia' : 'Failed to load',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(sw ? 'Jaribu tena' : 'Retry'),
              style: TextButton.styleFrom(foregroundColor: _kPrimary),
            ),
          ],
        ),
      );
    }

    final invoices = _filtered;

    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              sw ? 'Huna ankara bado' : 'No invoices yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              sw
                  ? 'Unda ankara yako ya kwanza'
                  : 'Create your first invoice',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateInvoicePage(businessId: widget.businessId),
                  ),
                );
                if (created == true) _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(sw ? 'Unda Ankara' : 'Create Invoice'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (_, i) {
          final inv = invoices[i];
          return InvoiceCard(
            invoice: inv,
            isSwahili: sw,
            onTap: inv.id != null ? () => _openInvoiceDetail(inv) : null,
            onSendTap: inv.status == InvoiceStatus.draft
                ? () => _sendInvoice(inv)
                : null,
            onMarkPaidTap: inv.status != InvoiceStatus.paid &&
                    inv.status != InvoiceStatus.cancelled
                ? () => _markPaid(inv)
                : null,
            onEmailTap: () => _emailInvoice(inv),
          );
        },
      ),
    );
  }

  // ── Search & Sort ─────────────────────────────────────────────────
  Widget _buildSearchSortSection(bool sw) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF999999).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _searchQuery = v.trim().toLowerCase();
              }),
              decoration: InputDecoration(
                hintText: sw ? 'Tafuta ankara...' : 'Search invoices...',
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close_rounded, color: _kSecondary),
                        tooltip: sw ? 'Futa' : 'Clear',
                      )
                    : null,
                filled: true,
                fillColor: _kBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              sw ? 'Panga kwa' : 'Sort by',
              style: const TextStyle(
                fontSize: 12,
                color: _kSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _sortChip(sw ? 'Tarehe' : 'Date', 'date'),
                _sortChip(sw ? 'Kiasi' : 'Amount', 'amount'),
                _sortChip(sw ? 'Mwisho' : 'Due Date', 'due_date'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String label, String key) {
    final selected = _sortBy == key;
    return Material(
      color: selected ? _kPrimary : _kBackground,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          setState(() {
            if (_sortBy == key) {
              _sortAsc = !_sortAsc;
            } else {
              _sortBy = key;
              _sortAsc = false;
            }
          });
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : _kSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(
                  _sortAsc
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewTab(int index, String label, {bool isFirst = false, bool isLast = false}) {
    final selected = _viewIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewIndex = index),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _kPrimary : _kBackground,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(10) : Radius.zero,
              right: isLast ? const Radius.circular(10) : Radius.zero,
            ),
            border: Border.all(color: selected ? _kPrimary : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _kSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _topPillActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 34,
      child: Material(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper class for aging buckets ────────────────────────────────────
class _AgingBucket {
  final String label;
  final int count;
  final double amount;
  final Color color;

  const _AgingBucket(this.label, this.count, this.amount, this.color);
}

// ── Sparkline painter ────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - (values[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    // Draw dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - (values[i] / maxVal) * size.height;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}
