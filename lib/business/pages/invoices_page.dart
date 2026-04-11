// lib/business/pages/invoices_page.dart
// Invoice management with status filtering, send, and mark-as-paid.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';
import '../widgets/invoice_card.dart';
import 'create_invoice_page.dart';
import 'email/email_compose_page.dart';

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
  bool _loading = true;
  String? _error;
  List<Invoice> _invoices = [];
  late TabController _tabCtrl;

  final _statusFilters = const [null, 'draft', 'sent', 'paid', 'overdue'];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  List<String> get _tabs => _sw
      ? const ['Zote', 'Rasimu', 'Zimetumwa', 'Zimelipwa', 'Zimechelewa']
      : const ['All', 'Drafts', 'Sent', 'Paid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
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
      final res = await BusinessService.getInvoices(_token!, widget.businessId);
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

  List<Invoice> get _filtered {
    final f = _statusFilters[_tabCtrl.index];
    if (f == null) return _invoices;
    return _invoices.where((i) => i.status.name == f).toList();
  }

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
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');

    final itemsText = inv.items
        .map((item) =>
            '- ${item.description} x${item.quantity.toStringAsFixed(0)} = TZS ${nf.format(item.totalPrice)}')
        .join('\n');

    final body = 'Invoice: ${inv.invoiceNumber}\n'
        'To: ${inv.customerName ?? "Customer"}\n'
        'Date: ${inv.createdAt != null ? df.format(inv.createdAt!) : "-"}\n'
        'Due: ${inv.dueDate != null ? df.format(inv.dueDate!) : "-"}\n\n'
        'Items:\n$itemsText\n\n'
        'Subtotal: TZS ${nf.format(inv.subtotal)}\n'
        'VAT (18%): TZS ${nf.format(inv.vatAmount)}\n'
        'Total: TZS ${nf.format(inv.totalAmount)}\n\n'
        'Please make payment before ${inv.dueDate != null ? df.format(inv.dueDate!) : "the due date"}.\n';

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

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _filtered;
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CreateInvoicePage(businessId: widget.businessId)),
          );
          if (created == true) _load();
        },
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(sw ? 'Ankara Mpya' : 'New Invoice',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
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
          Expanded(
            child: _loading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        sw ? 'Imeshindikana kupakia' : 'Failed to load',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(sw ? 'Jaribu tena' : 'Retry'),
                        style:
                            TextButton.styleFrom(foregroundColor: _kPrimary),
                      ),
                    ],
                  ),
                )
              : invoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(sw ? 'Hakuna ankara' : 'No invoices',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            sw
                                ? 'Bonyeza + kuunda ankara mpya'
                                : 'Tap + to create a new invoice',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
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
                    ),
          ),
        ],
      ),
    );
  }
}
