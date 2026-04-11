// lib/business/pages/purchase_orders_page.dart
// Purchase Orders (Maagizo ya Manunuzi / Purchase Orders).
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

class PurchaseOrdersPage extends StatefulWidget {
  final int businessId;
  const PurchaseOrdersPage({super.key, required this.businessId});

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _token;
  bool _loading = true;
  String? _error;
  List<PurchaseOrder> _orders = [];
  List<Supplier> _suppliers = [];

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  List<String> get _tabs => _isSwahili
      ? const ['Zote', 'Rasimu', 'Zimetumwa', 'Zimepokelewa']
      : const ['All', 'Draft', 'Sent', 'Received'];
  final _statusFilters = const [null, 'draft', 'sent', 'received'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _loadOrders();
    });
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (_token != null) {
      await Future.wait([_loadOrders(), _loadSuppliers()]);
    }
  }

  Future<void> _loadOrders() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = _statusFilters[_tabCtrl.index];
      final res = await BusinessService.getPurchaseOrders(
          _token!, widget.businessId,
          status: status);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _orders = res.data;
          } else {
            _error = res.message ??
                (_isSwahili ? 'Imeshindikana kupata maagizo' : 'Failed to load orders');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _isSwahili ? 'Tatizo la mtandao' : 'Network error';
        });
      }
    }
  }

  Future<void> _loadSuppliers() async {
    if (_token == null) return;
    final res =
        await BusinessService.getSuppliers(_token!, widget.businessId);
    if (mounted && res.success) {
      setState(() => _suppliers = res.data);
    }
  }

  Future<void> _markReceived(PurchaseOrder po) async {
    if (_token == null || po.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await BusinessService.markPOReceived(_token!, po.id!);
    if (mounted) {
      messenger.showSnackBar(SnackBar(
          content: Text(res.success
              ? (_isSwahili ? 'Imepokelewa' : 'Marked as received')
              : (res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'))),
          backgroundColor: res.success ? null : Colors.red));
      if (res.success) _loadOrders();
    }
  }

  Future<void> _cancelOrder(PurchaseOrder po) async {
    if (_token == null || po.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa Agizo?' : 'Cancel Order?'),
        content: Text(_isSwahili
            ? 'Agizo hili litafutwa.'
            : 'This order will be cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Hapana' : 'No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_isSwahili ? 'Ndio, Futa' : 'Yes, Cancel',
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await BusinessService.cancelPO(_token!, po.id!);
    if (mounted) {
      messenger.showSnackBar(SnackBar(
          content: Text(res.success
              ? (_isSwahili ? 'Agizo limefutwa' : 'Order cancelled')
              : (res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'))),
          backgroundColor: res.success ? null : Colors.red));
      if (res.success) _loadOrders();
    }
  }

  Color _statusColor(PurchaseOrderStatus s) {
    switch (s) {
      case PurchaseOrderStatus.draft:
        return Colors.grey;
      case PurchaseOrderStatus.sent:
        return Colors.blue;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel(PurchaseOrderStatus s) {
    if (_isSwahili) return poStatusLabel(s);
    switch (s) {
      case PurchaseOrderStatus.draft:
        return 'Draft';
      case PurchaseOrderStatus.sent:
        return 'Sent';
      case PurchaseOrderStatus.received:
        return 'Received';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _showCreateSheet() {
    final nf = NumberFormat('#,###', 'en');
    Supplier? selectedSupplier;
    final supplierNameCtrl = TextEditingController();
    final deliveryDate = ValueNotifier<DateTime>(
        DateTime.now().add(const Duration(days: 7)));
    final notesCtrl = TextEditingController();
    final items = <_QuickItem>[];
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          double total =
              items.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
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
                  // Drag handle
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
                      _isSwahili
                          ? 'Agizo Jipya la Manunuzi'
                          : 'New Purchase Order',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  const SizedBox(height: 14),
                  // Supplier selector
                  if (_suppliers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedSupplier?.id,
                          hint: Text(_isSwahili
                              ? 'Chagua Msambazaji'
                              : 'Select Supplier'),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem<int>(
                                value: -1,
                                child: Text(
                                    _isSwahili
                                        ? 'Andika jina'
                                        : 'Type name',
                                    style: const TextStyle(
                                        color: _kSecondary))),
                            ..._suppliers.map((s) => DropdownMenuItem(
                                value: s.id, child: Text(s.name))),
                          ],
                          onChanged: (v) {
                            setSheetState(() {
                              if (v == -1) {
                                selectedSupplier = null;
                              } else {
                                selectedSupplier =
                                    _suppliers.firstWhere((s) => s.id == v);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  if (selectedSupplier == null) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: supplierNameCtrl,
                      decoration: InputDecoration(
                        hintText: _isSwahili
                            ? 'Jina la Msambazaji'
                            : 'Supplier Name',
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Items
                  if (items.isNotEmpty)
                    ...items.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      '${i.description} x${i.quantity.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 13, color: _kPrimary))),
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
                            hintText: _isSwahili ? 'Bidhaa' : 'Item',
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
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: _isSwahili ? 'Bei' : 'Price',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: _kPrimary),
                        onPressed: () {
                          final d = descCtrl.text.trim();
                          final qty =
                              double.tryParse(qtyCtrl.text) ?? 1;
                          final p = double.tryParse(
                                  priceCtrl.text.replaceAll(',', '')) ??
                              0;
                          if (d.isNotEmpty && p > 0) {
                            setSheetState(() {
                              items.add(_QuickItem(
                                  description: d,
                                  unitPrice: p,
                                  quantity: qty));
                              descCtrl.clear();
                              priceCtrl.clear();
                              qtyCtrl.text = '1';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isSwahili ? 'JUMLA' : 'TOTAL',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: _kPrimary)),
                        Text('TZS ${nf.format(total)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: _kPrimary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Delivery date
                  ValueListenableBuilder<DateTime>(
                    valueListenable: deliveryDate,
                    builder: (_, date, child) => GestureDetector(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (dt != null) deliveryDate.value = dt;
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: _isSwahili
                              ? 'Tarehe ya Kupokea'
                              : 'Expected Delivery Date',
                          filled: true,
                          fillColor: _kBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: _kSecondary),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(date)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final supplierName = selectedSupplier?.name ??
                                  supplierNameCtrl.text.trim();
                              if (supplierName.isEmpty || items.isEmpty) return;
                              setSheetState(() => submitting = true);
                              try {
                                final body = {
                                  'business_id': widget.businessId,
                                  'supplier_id': selectedSupplier?.id,
                                  'supplier_name': supplierName,
                                  'items': items
                                      .map((i) => {
                                            'description': i.description,
                                            'quantity': i.quantity,
                                            'unit_price': i.unitPrice,
                                            'total_price':
                                                i.unitPrice * i.quantity,
                                          })
                                      .toList(),
                                  'subtotal': total,
                                  'vat_amount': 0,
                                  'total_amount': total,
                                  'status': 'draft',
                                  'expected_delivery_date':
                                      deliveryDate.value.toIso8601String(),
                                  'notes': notesCtrl.text.trim(),
                                };
                                final res =
                                    await BusinessService.createPurchaseOrder(
                                        _token!, widget.businessId, body);
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(res.message ??
                                            (_isSwahili
                                                ? 'Agizo limeundwa'
                                                : 'Order created'))),
                                  );
                                  _loadOrders();
                                }
                              } catch (e) {
                                setSheetState(() => submitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(_isSwahili
                                          ? 'Imeshindikana. Jaribu tena.'
                                          : 'Failed. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isSwahili ? 'Unda Agizo' : 'Create Order',
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
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
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
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadOrders,
                        style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary),
                        child:
                            Text(_isSwahili ? 'Jaribu Tena' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                              _isSwahili
                                  ? 'Hakuna maagizo bado'
                                  : 'No orders yet',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                              _isSwahili
                                  ? 'Bonyeza + kuunda agizo jipya'
                                  : 'Tap + to create a new order',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) {
                          final po = _orders[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        po.poNumber.isNotEmpty
                                            ? po.poNumber
                                            : 'PO-${po.id ?? ""}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(po.status)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _statusLabel(po.status),
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _statusColor(po.status)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    po.supplierName ??
                                        (_isSwahili
                                            ? 'Msambazaji'
                                            : 'Supplier'),
                                    style: const TextStyle(
                                        fontSize: 13, color: _kSecondary)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'TZS ${nf.format(po.totalAmount)}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimary)),
                                    if (po.expectedDeliveryDate != null)
                                      Text(
                                          '${_isSwahili ? "Kupokea" : "Due"}: ${df.format(po.expectedDeliveryDate!)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _kSecondary)),
                                  ],
                                ),
                                if (po.status ==
                                        PurchaseOrderStatus.sent ||
                                    po.status ==
                                        PurchaseOrderStatus.draft) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (po.status ==
                                          PurchaseOrderStatus.sent)
                                        _actionBtn(
                                            _isSwahili
                                                ? 'Pokelewa'
                                                : 'Received',
                                            Icons.check_rounded,
                                            () => _markReceived(po)),
                                      _actionBtn(
                                          _isSwahili ? 'Futa' : 'Cancel',
                                          Icons.cancel_rounded,
                                          () => _cancelOrder(po)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 14),
          label: Text(label, style: const TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kPrimary, width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
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
      {required this.description, this.unitPrice = 0, this.quantity = 1});
}
