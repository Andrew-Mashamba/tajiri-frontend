// lib/business/pages/recurring_invoices_page.dart
// Recurring Invoices management.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class RecurringInvoicesPage extends StatefulWidget {
  final int businessId;
  const RecurringInvoicesPage({super.key, required this.businessId});

  @override
  State<RecurringInvoicesPage> createState() => _RecurringInvoicesPageState();
}

class _RecurringInvoicesPageState extends State<RecurringInvoicesPage> {
  String? _token;
  bool _loading = true;
  String? _error;
  List<RecurringInvoice> _invoices = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

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
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await BusinessService.getRecurringInvoices(
          _token!, widget.businessId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _invoices = res.data;
          } else {
            _error = res.message ?? 'Failed to load';
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

  Future<void> _cancelRecurring(RecurringInvoice ri) async {
    if (_token == null || ri.id == null) return;
    final sw = _sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Sitisha Ankara?' : 'Cancel Recurring Invoice?'),
        content: Text(sw
            ? 'Ankara hii haitaendelea kutolewa. Hatua hii haiwezi kurudishwa.'
            : 'This invoice will no longer be issued. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Hapana' : 'No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(sw ? 'Ndio, Sitisha' : 'Yes, Cancel',
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await BusinessService.cancelRecurringInvoice(_token!, ri.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.message ??
                (sw ? 'Imesitishwa' : 'Cancelled'))));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sw ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  void _showCreateSheet() {
    final customerNameCtrl = TextEditingController();
    final nf = NumberFormat('#,###', 'en');
    RecurringFrequency freq = RecurringFrequency.monthly;
    bool includeVat = true;
    const double vatRate = 18.0;
    final items = <_QuickItem>[];
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          double subtotal =
              items.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
          double vatAmount = includeVat ? subtotal * (vatRate / 100) : 0;
          double total = subtotal + vatAmount;
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      sw
                          ? 'Ankara Mpya ya Kujirudia'
                          : 'New Recurring Invoice',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: customerNameCtrl,
                    decoration: InputDecoration(
                      labelText: sw ? 'Jina la Mteja' : 'Customer Name',
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Frequency selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _kBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RecurringFrequency>(
                        value: freq,
                        isExpanded: true,
                        items: RecurringFrequency.values
                            .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(recurringFrequencyLabel(f,
                                    swahili: sw))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => freq = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // VAT toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sw ? 'Jumuisha VAT (18%)' : 'Include VAT (18%)',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary)),
                      Switch(
                        value: includeVat,
                        onChanged: (v) => setSheetState(() => includeVat = v),
                        activeTrackColor: _kPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Items
                  if (items.isNotEmpty)
                    ...items.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(i.description,
                                      style: const TextStyle(
                                          fontSize: 13, color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                              Text(
                                  'TZS ${nf.format(i.unitPrice * i.quantity)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary)),
                            ],
                          ),
                        )),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            hintText: sw ? 'Bidhaa' : 'Item',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: sw ? 'Bei' : 'Price',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: _kPrimary),
                        onPressed: () {
                          final d = descCtrl.text.trim();
                          final p = double.tryParse(
                                  priceCtrl.text.replaceAll(',', '')) ??
                              0;
                          if (d.isNotEmpty && p > 0) {
                            setSheetState(() {
                              items.add(
                                  _QuickItem(description: d, unitPrice: p));
                              descCtrl.clear();
                              priceCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const Divider(),
                    if (includeVat) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(sw ? 'Jumla Ndogo' : 'Subtotal',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                          Text('TZS ${nf.format(subtotal)}',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VAT (18%)',
                              style: TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                          Text('TZS ${nf.format(vatAmount)}',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sw ? 'JUMLA' : 'TOTAL',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kPrimary)),
                        Text('TZS ${nf.format(total)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kPrimary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (customerNameCtrl.text.trim().isEmpty ||
                            items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(sw
                                  ? 'Jaza jina la mteja na ongeza bidhaa'
                                  : 'Enter customer name and add items')));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        final startDate = DateTime.now();
                        final body = {
                          'business_id': widget.businessId,
                          'customer_name': customerNameCtrl.text.trim(),
                          'items': items
                              .map((i) => {
                                    'description': i.description,
                                    'quantity': i.quantity,
                                    'unit_price': i.unitPrice,
                                    'total_price': i.unitPrice * i.quantity,
                                  })
                              .toList(),
                          'subtotal': subtotal,
                          'vat_amount': vatAmount,
                          'total_amount': total,
                          'frequency': freq.name,
                          'start_date': startDate.toIso8601String(),
                          'next_issue_date': startDate.toIso8601String(),
                        };
                        try {
                          final res =
                              await BusinessService.createRecurringInvoice(
                                  _token!, widget.businessId, body);
                          if (mounted) {
                            nav.pop();
                            messenger.showSnackBar(
                                SnackBar(
                                    content: Text(res.message ??
                                        (sw ? 'Imeundwa' : 'Created'))));
                            _load();
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                                SnackBar(
                                    content: Text(sw
                                        ? 'Imeshindikana'
                                        : 'Failed')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          sw ? 'Unda Ankara' : 'Create Invoice',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _loading
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
              : _invoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                              sw
                                  ? 'Hakuna ankara za kujirudia'
                                  : 'No recurring invoices',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            sw
                                ? 'Bonyeza + kuunda ankara mpya'
                                : 'Tap + to create one',
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
                        itemCount: _invoices.length,
                        itemBuilder: (_, i) {
                          final ri = _invoices[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: ri.isActive
                                            ? Colors.green.shade50
                                            : Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.repeat_rounded,
                                          size: 18,
                                          color: ri.isActive
                                              ? Colors.green.shade700
                                              : _kSecondary),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              ri.customerName ??
                                                  (sw
                                                      ? 'Mteja'
                                                      : 'Customer'),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: _kPrimary,
                                                  fontSize: 14),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                          Text(
                                            recurringFrequencyLabel(
                                                ri.frequency,
                                                swahili: sw),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: _kSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                            'TZS ${nf.format(ri.totalAmount)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _kPrimary,
                                                fontSize: 14)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: ri.isActive
                                                ? Colors.green.shade50
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            ri.isActive
                                                ? (sw ? 'Hai' : 'Active')
                                                : (sw
                                                    ? 'Imesitishwa'
                                                    : 'Cancelled'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: ri.isActive
                                                  ? Colors.green.shade700
                                                  : _kSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (ri.nextIssueDate != null) ...[
                                      const Icon(Icons.schedule_rounded,
                                          size: 14, color: _kSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${sw ? 'Inayofuata' : 'Next'}: ${df.format(ri.nextIssueDate!)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _kSecondary)),
                                    ],
                                    const Spacer(),
                                    Text(
                                        '${sw ? 'Zimetolewa' : 'Issued'}: ${ri.totalIssued}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: _kSecondary)),
                                  ],
                                ),
                                if (ri.isActive) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 36,
                                    child: OutlinedButton(
                                      onPressed: () => _cancelRecurring(ri),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                            color: Colors.red, width: 0.5),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                      ),
                                      child: Text(
                                          sw ? 'Sitisha' : 'Cancel',
                                          style: const TextStyle(
                                              fontSize: 11)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _QuickItem {
  final String description;
  final double unitPrice;
  final double quantity;
  _QuickItem(
      {required this.description, this.unitPrice = 0, double? qty})
      : quantity = qty ?? 1;
}
