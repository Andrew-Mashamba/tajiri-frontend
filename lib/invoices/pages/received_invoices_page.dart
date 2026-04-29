// lib/invoices/pages/received_invoices_page.dart
// Lists invoices sent TO the current user by businesses.
// Embedded as a profile tab (no AppBar).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import 'invoice_pay_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ReceivedInvoicesPage extends StatefulWidget {
  final int userId;
  const ReceivedInvoicesPage({super.key, required this.userId});

  @override
  State<ReceivedInvoicesPage> createState() => _ReceivedInvoicesPageState();
}

class _ReceivedInvoicesPageState extends State<ReceivedInvoicesPage>
    with SingleTickerProviderStateMixin {
  final _nf = NumberFormat('#,###', 'en');
  final _df = DateFormat('dd/MM/yyyy');

  String? _token;
  bool _loading = true;
  String? _error;
  List<Invoice> _invoices = [];
  late TabController _tabCtrl;

  final _statusFilters = const [null, 'unpaid', 'paid'];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  List<String> get _tabs => _sw
      ? const ['Zote', 'Hazijalipwa', 'Zimelipwa']
      : const ['All', 'Unpaid', 'Paid'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
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
          await BusinessService.getReceivedInvoices(_token!, widget.userId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (res.success) {
          _invoices = res.data;
        } else {
          _error = res.message ?? 'Failed to load';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Invoice> get _filtered {
    final f = _statusFilters[_tabCtrl.index];
    if (f == null) return _invoices;
    if (f == 'unpaid') {
      return _invoices
          .where((i) =>
              i.status != InvoiceStatus.paid &&
              i.status != InvoiceStatus.void_status &&
              i.status != InvoiceStatus.cancelled)
          .toList();
    }
    return _invoices.where((i) => i.status == InvoiceStatus.paid).toList();
  }

  double get _totalOutstanding => _invoices
      .where((i) =>
          i.status != InvoiceStatus.paid &&
          i.status != InvoiceStatus.void_status &&
          i.status != InvoiceStatus.cancelled)
      .fold(0.0, (sum, i) => sum + i.balanceRemaining);

  String _fmtCurrency(double v) => 'TZS ${_nf.format(v.round())}';

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final items = _filtered;

    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(
        children: [
          // Summary card
          if (!_loading && _error == null && _invoices.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Ankara zinazosubiri malipo' : 'Invoices awaiting payment',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtCurrency(_totalOutstanding),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_invoices.where((i) => i.status != InvoiceStatus.paid && i.status != InvoiceStatus.void_status && i.status != InvoiceStatus.cancelled).length} ${sw ? 'ankara' : 'invoices'}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),

          // Tabs
          Material(
            color: _kCardBg,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: _kPrimary,
              unselectedLabelColor: _kSecondary,
              indicatorColor: _kPrimary,
              indicatorWeight: 2,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                                sw
                                    ? 'Imeshindikana kupakia'
                                    : 'Failed to load',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _load,
                              icon:
                                  const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(sw ? 'Jaribu tena' : 'Retry'),
                              style: TextButton.styleFrom(
                                  foregroundColor: _kPrimary),
                            ),
                          ],
                        ),
                      )
                    : items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                    sw
                                        ? 'Huna ankara zilizopokewa'
                                        : 'No received invoices',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                    sw
                                        ? 'Ankara zitaonekana hapa zikitumwa kwako'
                                        : 'Invoices will appear here when sent to you',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: _kPrimary,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              itemBuilder: (_, i) =>
                                  _buildInvoiceCard(items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice inv) {
    final sw = _sw;
    final overdue = isInvoiceOverdue(inv);
    final overdueDays = invoiceOverdueDays(inv);
    final isPaid = inv.status == InvoiceStatus.paid;

    return GestureDetector(
      onTap: () async {
        if (inv.id == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoicePayPage(invoiceId: inv.id!),
          ),
        );
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: overdue ? Colors.red.shade200 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: business name + status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store_rounded,
                      size: 20, color: _kPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.customerName ?? inv.invoiceNumber,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        inv.invoiceNumber,
                        style:
                            const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.shade50
                        : overdue
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invoiceStatusLabel(inv.status, swahili: sw),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPaid
                            ? Colors.green.shade700
                            : overdue
                                ? Colors.red.shade700
                                : Colors.blue.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sw ? 'Jumla' : 'Total',
                        style:
                            const TextStyle(fontSize: 11, color: _kSecondary)),
                    Text(_fmtCurrency(inv.totalAmount),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                  ],
                ),
                if (!isPaid)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(sw ? 'Baki' : 'Balance',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                      Text(_fmtCurrency(inv.balanceRemaining),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700)),
                    ],
                  ),
              ],
            ),

            // Payment progress
            if (inv.amountPaid > 0 && !isPaid) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: inv.totalAmount > 0
                      ? (inv.amountPaid / inv.totalAmount).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                  minHeight: 4,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Footer: due date + overdue warning
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${sw ? 'Mwisho' : 'Due'}: ${inv.dueDate != null ? _df.format(inv.dueDate!) : '-'}',
                  style: TextStyle(
                      fontSize: 12,
                      color: overdue ? Colors.red.shade700 : _kSecondary),
                ),
                if (overdue && !isPaid)
                  Text(
                    sw
                        ? 'Imechelewa siku $overdueDays'
                        : 'Overdue $overdueDays days',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700),
                  ),
                if (!isPaid && !overdue)
                  Text(
                    sw ? 'Bonyeza kulipa' : 'Tap to pay',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700),
                  ),
                if (isPaid)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(sw ? 'Imelipwa' : 'Paid',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
