// lib/suppliers/pages/supplier_payables_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/wallet_service.dart';
import '../../my_wallet/pages/wallet_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class SupplierPayablesPage extends StatefulWidget {
  final int businessId;
  final bool isSwahili;

  const SupplierPayablesPage({
    super.key,
    required this.businessId,
    required this.isSwahili,
  });

  @override
  State<SupplierPayablesPage> createState() => _SupplierPayablesPageState();
}

class _SupplierPayablesPageState extends State<SupplierPayablesPage> {
  String? _token;
  int _userId = 0;
  bool _loading = true;
  String? _error;
  List<SupplierPayable> _payables = [];

  final _nf = NumberFormat('#,###', 'en');
  final _df = DateFormat('dd MMM yyyy');

  bool get _sw => widget.isSwahili;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId ?? 0;
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) {
      setState(() {
        _loading = false;
        _error = _sw ? 'Hujaingia' : 'Not authenticated';
      });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await BusinessService.getPayables(
          _token!, widget.businessId,
          status: 'unpaid,partially_paid');
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _payables = res.data;
          } else {
            _error = res.message ??
                (_sw ? 'Imeshindikana kupata madeni' : 'Failed to load payables');
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  double get _totalOutstanding =>
      _payables.fold(0.0, (sum, p) => sum + p.remainingAmount);

  Future<void> _deletePayable(SupplierPayable payable) async {
    if (payable.id == null || _token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(_sw ? 'Futa Deni' : 'Remove Payable'),
        content: Text(_sw
            ? 'Futa deni hili la TZS ${_nf.format(payable.remainingAmount)} kutoka ${payable.supplierName ?? "msambazaji"}?'
            : 'Remove payable of TZS ${_nf.format(payable.remainingAmount)} from ${payable.supplierName ?? "supplier"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(_sw ? 'Ghairi' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_sw ? 'Futa' : 'Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await BusinessService.deletePayable(_token!, payable.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.success
              ? (_sw ? 'Deni limefutwa' : 'Payable removed')
              : (res.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
          backgroundColor: res.success ? null : Colors.red));
      if (res.success) _load();
    }
  }

  void _showPaymentSheet(SupplierPayable payable) {
    final amountCtrl = TextEditingController(
        text: payable.remainingAmount.toStringAsFixed(0));
    final referenceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? selectedMethod;
    DateTime paymentDate = DateTime.now();
    bool saving = false;

    const methods = [
      'M-Pesa',
      'Tigo Pesa',
      'Airtel Money',
      'NMB Bank',
      'CRDB Bank',
      'Cash',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: paymentDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) setSt(() => paymentDate = picked);
        }

        Future<void> pay() async {
          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
          if (amount <= 0 || payable.id == null || _token == null) return;
          setSt(() => saving = true);
          final messenger = ScaffoldMessenger.of(context);
          final body = <String, dynamic>{
            'amount': amount,
            'payment_date': paymentDate.toIso8601String().substring(0, 10),
            if (selectedMethod != null) 'payment_method': selectedMethod,
            if (referenceCtrl.text.trim().isNotEmpty)
              'reference': referenceCtrl.text.trim(),
            if (notesCtrl.text.trim().isNotEmpty)
              'notes': notesCtrl.text.trim(),
          };
          final res = await BusinessService.recordPayablePayment(
              _token!, payable.id!, body);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (mounted) {
            messenger.showSnackBar(SnackBar(
                content: Text(res.success
                    ? (_sw
                        ? 'Malipo yamerekodiwa — TZS ${_nf.format(amount)}'
                        : 'Payment recorded — TZS ${_nf.format(amount)}')
                    : (res.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
                backgroundColor: res.success ? null : Colors.red));
            if (res.success) {
              _load();
              // Record as business expense (fire-and-forget)
              if (_token != null) {
                String? mappedMethod;
                if (selectedMethod != null) {
                  if (selectedMethod!.toLowerCase().contains('pesa') ||
                      selectedMethod!.toLowerCase().contains('mpesa') ||
                      selectedMethod!.toLowerCase().contains('airtel')) {
                    mappedMethod = 'mpesa';
                  } else if (selectedMethod!.toLowerCase().contains('bank')) {
                    mappedMethod = 'bank';
                  } else if (selectedMethod == 'Cash') {
                    mappedMethod = 'cash';
                  }
                }
                BusinessService.addExpense(_token!, widget.businessId, {
                  'category': 'supplies',
                  'description': _sw
                      ? 'Malipo ya msambazaji: ${payable.supplierName ?? ""}'
                      : 'Supplier payment: ${payable.supplierName ?? ""}',
                  'amount': amount,
                  'date': paymentDate.toIso8601String().substring(0, 10),
                  if (payable.supplierName?.isNotEmpty == true)
                    'vendor_name': payable.supplierName,
                  if (mappedMethod != null) 'payment_method': mappedMethod,
                  if (referenceCtrl.text.trim().isNotEmpty)
                    'reference': referenceCtrl.text.trim(),
                  if (payable.poNumber?.isNotEmpty == true)
                    'notes': 'PO: ${payable.poNumber}',
                });
              }
            }
          }
        }

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sw ? 'Rekodi Malipo' : 'Record Payment',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${payable.supplierName ?? ""}'
                  '${payable.poNumber != null && payable.poNumber!.isNotEmpty ? "  •  ${payable.poNumber}" : ""}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_sw ? "Inayobaki" : "Remaining"}: TZS ${_nf.format(payable.remainingAmount)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                ),
                const SizedBox(height: 16),
                // Wallet shortcut
                if (_userId > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        final result = await WalletService().getWallet(_userId);
                        if (!mounted) return;
                        if (result.success && result.wallet != null) {
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => WalletHomePage(
                              userId: _userId,
                              wallet: result.wallet!,
                              authToken: _token ?? '',
                            ),
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(_sw
                                ? 'Imeshindwa kufungua Pochi. Jaribu tena.'
                                : 'Could not open Wallet. Try again.'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                      label: Text(_sw
                          ? 'Lipa kupitia TAJIRI Pochi'
                          : 'Pay via TAJIRI Wallet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary, width: 0.8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(_sw ? 'au ingiza malipo' : 'or record manually',
                          style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
                    prefixText: 'TZS ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Payment date picker
                GestureDetector(
                  onTap: pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sw ? 'Tarehe ya Malipo' : 'Payment Date',
                                style: const TextStyle(
                                    fontSize: 11, color: _kSecondary),
                              ),
                              Text(
                                _df.format(paymentDate),
                                style: const TextStyle(
                                    fontSize: 14, color: _kPrimary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: _kSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: InputDecoration(
                    labelText: _sw ? 'Njia ya Malipo' : 'Payment Method',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: methods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setSt(() => selectedMethod = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: referenceCtrl,
                  decoration: InputDecoration(
                    labelText: _sw
                        ? 'Nambari ya Kumbukumbu (si lazima)'
                        : 'Reference Number (optional)',
                    hintText: _sw
                        ? 'Mfano: MPESA1234XYZ'
                        : 'e.g. MPESA1234XYZ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: _sw ? 'Maelezo (si lazima)' : 'Notes (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : pay,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            _sw ? 'Hifadhi Malipo' : 'Save Payment',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ).whenComplete(() {
      amountCtrl.dispose();
      referenceCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(
          _sw ? 'Madeni ya Wasambazaji' : 'Supplier Payables',
          style: const TextStyle(
              color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: _kSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _load,
                          child: Text(_sw ? 'Jaribu tena' : 'Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: _payables.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_rounded,
                                      size: 48,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    _sw
                                        ? 'Hakuna madeni yanayosubiri'
                                        : 'No outstanding payables',
                                    style: const TextStyle(
                                        color: _kSecondary, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Total outstanding header
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: _kPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _sw
                                              ? 'Jumla inayodaiwa'
                                              : 'Total outstanding',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'TZS ${_nf.format(_totalOutstanding)}',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${_payables.length} ${_sw ? "madeni" : "payables"}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            ..._payables.map((p) => _PayableCard(
                                  payable: p,
                                  nf: _nf,
                                  df: _df,
                                  isSwahili: _sw,
                                  onPay: () => _showPaymentSheet(p),
                                  onDelete: () => _deletePayable(p),
                                )),
                          ],
                        ),
                ),
    );
  }
}

class _PayableCard extends StatelessWidget {
  final SupplierPayable payable;
  final NumberFormat nf;
  final DateFormat df;
  final bool isSwahili;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  const _PayableCard({
    required this.payable,
    required this.nf,
    required this.df,
    required this.isSwahili,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue =
        payable.dueDate != null && payable.dueDate!.isBefore(now);
    final isDueSoon = !isOverdue &&
        payable.dueDate != null &&
        payable.dueDate!
            .isBefore(now.add(const Duration(days: 7)));

    final statusColor = isOverdue
        ? Colors.red
        : isDueSoon
            ? Colors.orange
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payable.supplierName ??
                          (isSwahili ? 'Msambazaji' : 'Supplier'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (payable.poNumber != null &&
                        payable.poNumber!.isNotEmpty)
                      Text(
                        payable.poNumber!,
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOverdue
                      ? (isSwahili ? 'Imechelewa' : 'Overdue')
                      : isDueSoon
                          ? (isSwahili ? 'Inakaribia' : 'Due Soon')
                          : (isSwahili ? 'Sawa' : 'On Track'),
                  style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: _kSecondary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                tooltip: isSwahili ? 'Futa Deni' : 'Remove Payable',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili ? 'Jumla' : 'Total',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                  Text(
                    'TZS ${nf.format(payable.amount)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili ? 'Imelipwa' : 'Paid',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                  Text(
                    'TZS ${nf.format(payable.paidAmount)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili ? 'Inabaki' : 'Remaining',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                  Text(
                    'TZS ${nf.format(payable.remainingAmount)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          if (payable.dueDate != null) ...[
            const SizedBox(height: 6),
            Text(
              '${isSwahili ? "Tarehe ya kulipa" : "Due"}: ${df.format(payable.dueDate!)}',
              style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? Colors.red : _kSecondary,
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPay,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                isSwahili ? 'Lipa Sasa' : 'Record Payment',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
