// lib/business/pages/create_invoice_page.dart
// Invoice creation with line items, VAT calculation, and preview.
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

class CreateInvoicePage extends StatefulWidget {
  final int businessId;
  const CreateInvoicePage({super.key, required this.businessId});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  String? _token;
  bool _saving = false;
  bool _loading = true;
  bool _includeVat = true;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  final _customerNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final List<_LineItem> _items = [];

  static const double _vatRate = 18.0;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (_token != null) {
      try {
        final res =
            await BusinessService.getCustomers(_token!, widget.businessId);
        if (mounted) {
          setState(() {
            _loading = false;
            if (res.success) _customers = res.data;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  double get _vatAmount => _includeVat ? _subtotal * (_vatRate / 100) : 0;

  double get _totalAmount => _subtotal + _vatAmount;

  void _addLineItem() {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
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
            Text(sw ? 'Ongeza Bidhaa/Huduma' : 'Add Item/Service',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary)),
            const SizedBox(height: 14),
            _inputField(descCtrl, sw ? 'Maelezo ya Bidhaa/Huduma' : 'Item/Service description'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _inputField(qtyCtrl, sw ? 'Idadi' : 'Qty',
                    keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _inputField(priceCtrl, sw ? 'Bei (TZS)' : 'Price (TZS)',
                    keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final desc = descCtrl.text.trim();
                  final qty = double.tryParse(qtyCtrl.text) ?? 1;
                  final price = double.tryParse(
                          priceCtrl.text.replaceAll(',', '')) ??
                      0;
                  if (desc.isEmpty || price <= 0) return;
                  setState(() {
                    _items.add(_LineItem(
                        description: desc, quantity: qty, unitPrice: price));
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(sw ? 'Ongeza' : 'Add',
                    style:
                        const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Future<void> _save() async {
    if (_token == null) return;
    final sw = _sw;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Ongeza angalau bidhaa moja' : 'Add at least one item')));
      return;
    }
    final customerName = _selectedCustomer?.name ?? _customerNameCtrl.text.trim();
    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw
              ? 'Chagua au andika jina la mteja'
              : 'Select or enter a customer name')));
      return;
    }

    setState(() => _saving = true);

    final body = {
      'business_id': widget.businessId,
      'customer_id': _selectedCustomer?.id,
      'customer_name': customerName,
      'items': _items
          .map((i) => {
                'description': i.description,
                'quantity': i.quantity,
                'unit_price': i.unitPrice,
                'total_price': i.total,
              })
          .toList(),
      'subtotal': _subtotal,
      'vat_rate': _includeVat ? _vatRate : 0,
      'vat_amount': _vatAmount,
      'total_amount': _totalAmount,
      'due_date': _dueDate.toIso8601String(),
      'notes': _notesCtrl.text.trim(),
      'status': 'draft',
    };

    try {
      final res = await BusinessService.createInvoice(_token!, body);
      if (mounted) {
        setState(() => _saving = false);
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(sw ? 'Ankara imeundwa!' : 'Invoice created!')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res.message ?? (sw ? 'Imeshindikana' : 'Failed'))));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sw ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  void _showPreview() {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final customerName =
        _selectedCustomer?.name ?? _customerNameCtrl.text.trim();
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Center(
              child: Text(sw ? 'ANKARA / INVOICE' : 'INVOICE',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 24),

            // Business & Customer info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sw ? 'Kutoka:' : 'From:',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                      Text(sw ? 'Biashara Yako' : 'Your Business',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(sw ? 'Kwa:' : 'To:',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                      Text(customerName.isNotEmpty ? customerName : '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${sw ? 'Tarehe ya Mwisho' : 'Due Date'}: ${df.format(_dueDate)}',
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const Divider(height: 24),

            // Items table
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(item.description,
                          style: const TextStyle(
                              fontSize: 13, color: _kPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: Text('x${item.quantity.toStringAsFixed(0)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('TZS ${nf.format(item.total)}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 20),

            // Totals
            _totalRow(sw ? 'Jumla Ndogo' : 'Subtotal', 'TZS ${nf.format(_subtotal)}'),
            if (_includeVat)
              _totalRow('VAT (${_vatRate.toStringAsFixed(0)}%)',
                  'TZS ${nf.format(_vatAmount)}'),
            const SizedBox(height: 4),
            _totalRow(sw ? 'JUMLA' : 'TOTAL', 'TZS ${nf.format(_totalAmount)}',
                isBold: true, fontSize: 16),

            if (_notesCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('${sw ? 'Maelezo' : 'Notes'}: ${_notesCtrl.text.trim()}',
                  style:
                      const TextStyle(fontSize: 12, color: _kSecondary)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _save();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(sw ? 'Hifadhi Ankara' : 'Save Invoice',
                    style:
                        const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool isBold = false, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  color: isBold ? _kPrimary : _kSecondary,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  color: _kPrimary,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(sw ? 'Unda Ankara' : 'Create Invoice',
            style: const TextStyle(
                color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _showPreview,
              child: Text(sw ? 'Angalia' : 'Preview',
                  style: const TextStyle(
                      color: _kPrimary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Customer selection
                Text(sw ? 'Mteja' : 'Customer',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
                const SizedBox(height: 8),
                if (_customers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedCustomer?.id,
                        hint: Text(sw ? 'Chagua Mteja' : 'Select Customer'),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<int>(
                              value: -1,
                              child: Text(
                                  sw ? 'Andika jina la mteja' : 'Enter customer name',
                                  style: const TextStyle(color: _kSecondary))),
                          ..._customers.map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) {
                          setState(() {
                            if (v == -1) {
                              _selectedCustomer = null;
                            } else {
                              _selectedCustomer =
                                  _customers.firstWhere((c) => c.id == v);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                if (_selectedCustomer == null) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customerNameCtrl,
                    decoration: InputDecoration(
                      hintText: sw ? 'Jina la Mteja' : 'Customer Name',
                      filled: true,
                      fillColor: _kCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Line items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sw ? 'Bidhaa / Huduma' : 'Items / Services',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary)),
                    TextButton.icon(
                      onPressed: _addLineItem,
                      icon: const Icon(Icons.add_circle_rounded, size: 18),
                      label: Text(sw ? 'Ongeza' : 'Add'),
                      style: TextButton.styleFrom(foregroundColor: _kPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Center(
                      child: Text(
                          sw
                              ? 'Bonyeza "Ongeza" kuongeza bidhaa'
                              : 'Tap "Add" to add items',
                          style:
                              const TextStyle(color: _kSecondary, fontSize: 13)),
                    ),
                  )
                else
                  ...List.generate(_items.length, (i) {
                    final item = _items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _kPrimary,
                                        fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  '${item.quantity.toStringAsFixed(0)} x TZS ${nf.format(item.unitPrice)} = TZS ${nf.format(item.total)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: _kSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: Colors.red),
                            onPressed: () =>
                                setState(() => _items.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // VAT toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sw ? 'Jumuisha VAT (18%)' : 'Include VAT (18%)',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary)),
                      Switch(
                        value: _includeVat,
                        onChanged: (v) => setState(() => _includeVat = v),
                        activeTrackColor: _kPrimary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Due date
                GestureDetector(
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (dt != null) setState(() => _dueDate = dt);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: sw ? 'Tarehe ya Mwisho' : 'Due Date',
                      filled: true,
                      fillColor: _kCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today_rounded,
                          size: 18, color: _kSecondary),
                    ),
                    child: Text(df.format(_dueDate)),
                  ),
                ),

                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: sw ? 'Maelezo ya ziada' : 'Additional notes',
                    filled: true,
                    fillColor: _kCardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Totals
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _totalRow(sw ? 'Jumla Ndogo' : 'Subtotal',
                          'TZS ${nf.format(_subtotal)}'),
                      if (_includeVat)
                        _totalRow('VAT (18%)', 'TZS ${nf.format(_vatAmount)}'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(sw ? 'JUMLA' : 'TOTAL',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary)),
                          Text('TZS ${nf.format(_totalAmount)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _items.isNotEmpty ? _showPreview : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: _kPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(sw ? 'Angalia Ankara' : 'Preview Invoice',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(sw ? 'Hifadhi' : 'Save',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _LineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  double get total => quantity * unitPrice;

  _LineItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
  });
}
