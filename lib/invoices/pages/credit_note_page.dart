// lib/invoices/pages/credit_note_page.dart
// Issue a credit note against a paid / partially-paid invoice.
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

class CreditNotePage extends StatefulWidget {
  final Invoice invoice;
  const CreditNotePage({super.key, required this.invoice});

  @override
  State<CreditNotePage> createState() => _CreditNotePageState();
}

class _CreditNotePageState extends State<CreditNotePage> {
  final _nf = NumberFormat('#,###', 'en');
  final _reasonTextController = TextEditingController();

  String? _token;

  /// index in invoice.items -> credited quantity
  final Map<int, double> _selectedItems = {};

  /// Controllers for quantity fields keyed by item index.
  final Map<int, TextEditingController> _qtyControllers = {};

  String? _reason;
  String _applicationMethod = 'manual';
  bool _saving = false;

  /// Existing credit notes for this invoice, loaded during init.
  List<CreditNote> _existingCreditNotes = [];
  bool _loadingCreditNotes = true;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  // ---- computed totals ----

  double get _creditSubtotal {
    double total = 0;
    _selectedItems.forEach((idx, qty) {
      if (idx < widget.invoice.items.length) {
        total += qty * widget.invoice.items[idx].unitPrice;
      }
    });
    return total;
  }

  double get _creditVat {
    double vat = 0;
    _selectedItems.forEach((idx, qty) {
      if (idx < widget.invoice.items.length) {
        final item = widget.invoice.items[idx];
        if (!item.isVatExempt) {
          vat += qty * item.unitPrice * (widget.invoice.vatRate / 100);
        }
      }
    });
    return vat;
  }

  double get _creditTotal => _creditSubtotal + _creditVat;

  // ---- lifecycle ----

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final storage = await LocalStorageService.getInstance();
    final t = storage.getAuthToken();
    if (mounted) setState(() => _token = t);
    if (t != null && widget.invoice.id != null) {
      _loadExistingCreditNotes(t);
    }
  }

  Future<void> _loadExistingCreditNotes(String token) async {
    try {
      final result = await BusinessService.getInvoiceCreditNotes(
          token, widget.invoice.id!);
      if (mounted) {
        setState(() {
          _existingCreditNotes = result.data;
          _loadingCreditNotes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCreditNotes = false);
    }
  }

  /// Sum of all existing credit note amounts for this invoice.
  double get _existingCreditTotal =>
      _existingCreditNotes.fold(0.0, (sum, cn) => sum + cn.totalAmount);

  /// Remaining amount that can still be credited.
  double get _remainingCreditable =>
      widget.invoice.totalAmount - _existingCreditTotal;

  @override
  void dispose() {
    _reasonTextController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- helpers ----

  String _fmtCurrency(double v) => 'TZS ${_nf.format(v.round())}';

  void _toggleItem(int index, bool selected) {
    setState(() {
      if (selected) {
        final item = widget.invoice.items[index];
        _selectedItems[index] = item.quantity;
        _qtyControllers[index] ??=
            TextEditingController(text: item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2));
      } else {
        _selectedItems.remove(index);
        _qtyControllers[index]?.dispose();
        _qtyControllers.remove(index);
      }
    });
  }

  void _updateQty(int index, String val) {
    final item = widget.invoice.items[index];
    final parsed = double.tryParse(val);
    if (parsed != null && parsed > 0 && parsed <= item.quantity) {
      setState(() => _selectedItems[index] = parsed);
    }
  }

  // ---- validation & submit ----

  String? _validate() {
    if (_selectedItems.isEmpty) {
      return _sw ? 'Chagua bidhaa angalau moja' : 'Select at least one item';
    }
    if (_reason == null) {
      return _sw ? 'Chagua sababu' : 'Select a reason';
    }
    if (_creditTotal <= 0) {
      return _sw
          ? 'Jumla ya mkopo haiwezi kuwa sifuri'
          : 'Credit total cannot be zero';
    }
    if (!_loadingCreditNotes && _creditTotal > _remainingCreditable) {
      return _sw
          ? 'Mkopo umezidi kiasi kinachoruhusiwa'
          : 'Credit exceeds allowed amount';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_sw ? 'Toa Nota ya Mkopo?' : 'Issue Credit Note?'),
        content: Text(
          _sw
              ? 'Nota ya mkopo ya ${_fmtCurrency(_creditTotal)} itatolewa. Hatua hii haiwezi kurudishwa. Endelea?'
              : 'A credit note of ${_fmtCurrency(_creditTotal)} will be issued. This cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_sw ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_sw ? 'Thibitisha' : 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);

    final items = <Map<String, dynamic>>[];
    _selectedItems.forEach((idx, qty) {
      final orig = widget.invoice.items[idx];
      items.add(CreditNoteItem(
        description: orig.description,
        quantity: qty,
        unitPrice: orig.unitPrice,
        originalInvoiceItemIndex: idx,
      ).toJson());
    });

    final body = <String, dynamic>{
      'invoice_id': widget.invoice.id,
      'items': items,
      'reason': _reason,
      if (_reason == 'other') 'reason_text': _reasonTextController.text.trim(),
      'subtotal': _creditSubtotal,
      'vat_amount': _creditVat,
      'total_amount': _creditTotal,
      'application_method': _applicationMethod,
    };

    if (_token == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final result = await BusinessService.createCreditNote(
          _token!, widget.invoice.id!, body);
      if (!mounted) return;

      if (result.success) {
        messenger.showSnackBar(SnackBar(
          content:
              Text(_sw ? 'Nota ya mkopo imetolewa' : 'Credit note issued'),
          action: SnackBarAction(
            label: _sw ? 'Pakua PDF' : 'Download PDF',
            textColor: Colors.white,
            onPressed: () {
              messenger.showSnackBar(SnackBar(
                content: Text(_sw
                    ? 'Itakuja hivi karibuni'
                    : 'Coming soon'),
              ));
            },
          ),
        ));
        nav.pop(true);
      } else {
        messenger.showSnackBar(
            SnackBar(content: Text(result.message ?? (_sw ? 'Imeshindikana' : 'Failed'))));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _sw ? 'Nota ya Mkopo' : 'Credit Note',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInvoiceSummary(),
                  const SizedBox(height: 16),
                  _buildLineItems(),
                  const SizedBox(height: 16),
                  _buildReasonPicker(),
                  const SizedBox(height: 16),
                  _buildTotals(),
                  const SizedBox(height: 16),
                  _buildApplicationMethod(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ---- sections ----

  Widget _buildInvoiceSummary() {
    final inv = widget.invoice;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sw ? 'Ankara Asili' : 'Original Invoice',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          _summaryRow(
              _sw ? 'Nambari ya ankara' : 'Invoice number', inv.invoiceNumber),
          const SizedBox(height: 6),
          _summaryRow(
              _sw ? 'Mteja' : 'Customer', inv.customerName ?? '-'),
          const SizedBox(height: 6),
          _summaryRow(
              _sw ? 'Jumla' : 'Total amount', _fmtCurrency(inv.totalAmount)),
          const SizedBox(height: 6),
          _summaryRow(
              _sw
                  ? 'Kiasi kinachoweza kupewa mkopo'
                  : 'Creditable amount',
              _loadingCreditNotes
                  ? '...'
                  : _fmtCurrency(_remainingCreditable)),

          // Existing credit notes list
          if (_existingCreditNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              _sw ? 'Nota za mkopo zilizopo' : 'Existing credit notes',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13, color: _kSecondary),
            ),
            const SizedBox(height: 6),
            ..._existingCreditNotes.map((cn) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cn.creditNoteNumber.isNotEmpty
                        ? cn.creditNoteNumber
                        : 'CN #${cn.id ?? ''}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                  Text(
                    _fmtCurrency(cn.totalAmount),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _kSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13, color: _kPrimary)),
      ],
    );
  }

  Widget _buildLineItems() {
    final items = widget.invoice.items;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sw ? 'Chagua Bidhaa' : 'Select Items',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (i) => _buildItemRow(i, items[i])),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, InvoiceItem item) {
    final selected = _selectedItems.containsKey(index);
    final creditQty = _selectedItems[index] ?? 0;
    final creditTotal = creditQty * item.unitPrice;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: selected,
                  activeColor: _kPrimary,
                  onChanged: (v) => _toggleItem(index, v ?? false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.description,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)} x ${_nf.format(item.unitPrice.round())}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                _fmtCurrency(item.totalPrice),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary),
              ),
            ],
          ),
          if (selected) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 36),
                Text(
                  _sw ? 'Idadi ya mkopo:' : 'Credit qty:',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  height: 36,
                  child: TextField(
                    controller: _qtyControllers[index],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => _updateQty(index, v),
                  ),
                ),
                Text(
                  ' / ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const Spacer(),
                Text(
                  _fmtCurrency(creditTotal),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sw ? 'Sababu' : 'Reason',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _reason ?? '',
            onChanged: (v) { if (v != null) setState(() => _reason = v); },
            child: Column(
              children: [
                _reasonRadio('goods_returned',
                    _sw ? 'Bidhaa zimerudishwa' : 'Goods returned'),
                _reasonRadio('service_not_delivered',
                    _sw ? 'Huduma haijatolewa' : 'Service not delivered'),
                _reasonRadio(
                    'pricing_error', _sw ? 'Kosa la bei' : 'Pricing error'),
                _reasonRadio('other', _sw ? 'Nyingine' : 'Other'),
              ],
            ),
          ),
          if (_reason == 'other') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _reasonTextController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: _sw ? 'Eleza sababu...' : 'Explain reason...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reasonRadio(String value, String label) {
    return RadioListTile<String>(
      value: value,
      activeColor: _kPrimary,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildTotals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow(
            _sw ? 'Jumla ndogo ya mkopo' : 'Credit Subtotal',
            _fmtCurrency(_creditSubtotal),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            _sw ? 'VAT ya mkopo' : 'Credit VAT',
            _fmtCurrency(_creditVat),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _sw ? 'Jumla ya mkopo' : 'Credit Total',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kPrimary),
              ),
              Text(
                _fmtCurrency(_creditTotal),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sw ? 'Njia ya Kutumia' : 'Application Method',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _applicationMethod,
            onChanged: (v) { if (v != null) setState(() => _applicationMethod = v); },
            child: Column(
              children: [
                _methodRadio('next_invoice',
                    _sw ? 'Ondoa kwenye ankara ijayo' : 'Apply to next invoice'),
                _methodRadio('wallet_refund',
                    _sw ? 'Rejesha kwenye wallet' : 'Refund to wallet'),
                _methodRadio('manual', _sw ? 'Mwongozo' : 'Manual'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodRadio(String value, String label) {
    return RadioListTile<String>(
      value: value,
      activeColor: _kPrimary,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  void _showPreviewSheet() {
    final sw = _sw;
    final reasonLabels = <String, String>{
      'goods_returned': sw ? 'Bidhaa zimerudishwa' : 'Goods returned',
      'service_not_delivered':
          sw ? 'Huduma haijatolewa' : 'Service not delivered',
      'pricing_error': sw ? 'Kosa la bei' : 'Pricing error',
      'other': _reasonTextController.text.trim().isNotEmpty
          ? _reasonTextController.text.trim()
          : (sw ? 'Nyingine' : 'Other'),
    };
    final methodLabels = <String, String>{
      'next_invoice':
          sw ? 'Ondoa kwenye ankara ijayo' : 'Apply to next invoice',
      'wallet_refund': sw ? 'Rejesha kwenye wallet' : 'Refund to wallet',
      'manual': sw ? 'Mwongozo' : 'Manual',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  sw ? 'Hakiki Nota ya Mkopo' : 'Credit Note Preview',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                ),
                const SizedBox(height: 14),

                // Invoice reference
                _summaryRow(
                    sw ? 'Ankara' : 'Invoice',
                    widget.invoice.invoiceNumber),
                const SizedBox(height: 6),
                _summaryRow(
                    sw ? 'Mteja' : 'Customer',
                    widget.invoice.customerName ?? '-'),
                const SizedBox(height: 12),

                // Credited items
                Text(
                  sw ? 'Bidhaa za Mkopo' : 'Credited Items',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                ),
                const SizedBox(height: 6),
                ..._selectedItems.entries.map((entry) {
                  final item = widget.invoice.items[entry.key];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.description} x${entry.value.toStringAsFixed(entry.value == entry.value.roundToDouble() ? 0 : 2)}',
                            style: const TextStyle(
                                fontSize: 13, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _fmtCurrency(entry.value * item.unitPrice),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kPrimary),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(height: 20),

                // Totals
                _summaryRow(
                    sw ? 'Jumla ndogo' : 'Subtotal',
                    _fmtCurrency(_creditSubtotal)),
                const SizedBox(height: 4),
                _summaryRow(
                    sw ? 'VAT' : 'VAT', _fmtCurrency(_creditVat)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sw ? 'JUMLA YA MKOPO' : 'CREDIT TOTAL',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kPrimary)),
                    Text(_fmtCurrency(_creditTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kPrimary)),
                  ],
                ),
                const SizedBox(height: 12),

                // Reason
                _summaryRow(
                    sw ? 'Sababu' : 'Reason',
                    reasonLabels[_reason] ?? '-'),
                const SizedBox(height: 6),

                // Application method
                _summaryRow(
                    sw ? 'Njia' : 'Method',
                    methodLabels[_applicationMethod] ?? '-'),

                const SizedBox(height: 18),

                // Issue button from preview
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _submit();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      sw ? 'Toa Nota ya Mkopo' : 'Issue Credit Note',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () {
                        final err = _validate();
                        if (err != null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(err)));
                          return;
                        }
                        _showPreviewSheet();
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _sw ? 'Hakiki / Preview' : 'Preview',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: _kSecondary,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _sw ? 'Toa Nota' : 'Issue',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
