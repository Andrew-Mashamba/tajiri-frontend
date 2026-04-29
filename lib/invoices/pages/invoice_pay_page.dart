// lib/invoices/pages/invoice_pay_page.dart
// Customer-facing invoice payment page (Journey 13).
// Shows invoice details (read-only) and a "Pay Now" section for wallet payment.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../services/wallet_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class InvoicePayPage extends StatefulWidget {
  final int invoiceId;
  const InvoicePayPage({super.key, required this.invoiceId});

  @override
  State<InvoicePayPage> createState() => _InvoicePayPageState();
}

class _InvoicePayPageState extends State<InvoicePayPage> {
  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;
  final _nf = NumberFormat('#,###', 'en');
  final _df = DateFormat('dd MMM yyyy');
  final _amountController = TextEditingController();

  String? _token;
  Invoice? _invoice;
  List<InvoicePayment> _payments = [];
  double _walletBalance = 0;
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = _sw ? 'Haujaingia. Tafadhali ingia kwanza.' : 'Not logged in. Please log in first.';
        });
        return;
      }
      _token = token;

      final results = await Future.wait([
        BusinessService.getInvoice(token, widget.invoiceId),
        BusinessService.getInvoicePayments(token, widget.invoiceId),
      ]);

      final invoiceResult = results[0] as BusinessResult<Invoice>;
      final paymentsResult = results[1] as BusinessListResult<InvoicePayment>;

      if (!mounted) return;

      if (!invoiceResult.success || invoiceResult.data == null) {
        setState(() {
          _loading = false;
          _error = invoiceResult.message ?? (_sw ? 'Imeshindikana kupakia ankara' : 'Failed to load invoice');
        });
        return;
      }

      // Try to load wallet balance
      double balance = 0;
      final user = storage.getUser();
      if (user?.userId != null) {
        final walletResult = await WalletService().getWallet(user!.userId!);
        if (walletResult.success && walletResult.wallet != null) {
          balance = walletResult.wallet!.balance;
        }
      }

      if (!mounted) return;
      setState(() {
        _invoice = invoiceResult.data;
        _payments = paymentsResult.success ? paymentsResult.data : [];
        _walletBalance = balance;
        _loading = false;
        _amountController.text = _invoice!.balanceRemaining.toStringAsFixed(0);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _formatAmount(double amount) => 'TZS ${_nf.format(amount.round())}';

  int _daysUntilDue() {
    if (_invoice?.dueDate == null) return 0;
    return _invoice!.dueDate!.difference(DateTime.now()).inDays;
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_sw ? 'Tafadhali weka kiasi sahihi' : 'Please enter a valid amount'),
      ));
      return;
    }
    if (amount > _invoice!.balanceRemaining) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_sw ? 'Kiasi kimezidi deni lililobaki' : 'Amount exceeds balance remaining'),
      ));
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_sw ? 'Thibitisha Malipo' : 'Confirm Payment'),
        content: Text(
          _sw
              ? 'Lipa ${_formatAmount(amount)} kwa ${_invoice!.customerName ?? 'biashara'} kwa ankara #${_invoice!.invoiceNumber}?'
              : 'Pay ${_formatAmount(amount)} to ${_invoice!.customerName ?? 'business'} for invoice #${_invoice!.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_sw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(_sw ? 'Lipa' : 'Pay'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _paying = true);

    try {
      final body = {
        'amount': amount,
        'method': 'wallet',
        'recorded_by': 'auto',
        'paid_at': DateTime.now().toIso8601String(),
      };
      final result = await BusinessService.recordInvoicePayment(
        _token!,
        widget.invoiceId,
        body,
      );

      if (!mounted) return;

      if (result.success) {
        // VFD auto-trigger when invoice is now fully paid
        final inv = _invoice!;
        if (inv.amountPaid + amount >= inv.totalAmount) {
          BusinessService.generateVfdReceipt(_token!, widget.invoiceId);
        }

        // NOTE: ExpenditureService.recordExpenditure() should be called server-side
        // when a wallet payment is recorded, to track the customer's spending in their budget.
        // This is handled by the backend payment recording endpoint.

        messenger.showSnackBar(SnackBar(
          content: Text(
            _sw
                ? 'Malipo yamefanikiwa! ${_formatAmount(amount)}'
                : 'Payment successful! ${_formatAmount(amount)}',
          ),
          backgroundColor: Colors.green.shade700,
          // Gap 3: Receipt download stub
          action: SnackBarAction(
            label: _sw ? 'Pakua Risiti' : 'Download Receipt',
            textColor: Colors.white,
            onPressed: () {
              messenger.showSnackBar(SnackBar(
                content: Text(
                  _sw
                      ? 'Itakuja hivi karibuni'
                      : 'Coming soon',
                ),
              ));
            },
          ),
        ));
        setState(() => _paying = false);
        await _init();
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(result.message ?? (_sw ? 'Malipo yameshindikana' : 'Payment failed')),
          backgroundColor: Colors.red.shade700,
        ));
        setState(() => _paying = false);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(_sw ? 'Hitilafu: $e' : 'Error: $e'),
        backgroundColor: Colors.red.shade700,
      ));
      setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _sw ? 'Ankara / Lipa' : 'Invoice / Pay',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _init();
              },
              child: Text(_sw ? 'Jaribu tena' : 'Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final inv = _invoice!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceHeader(inv),
          const SizedBox(height: 16),
          _buildLineItems(inv),
          const SizedBox(height: 16),
          _buildTotals(inv),
          const SizedBox(height: 16),
          _buildPaymentHistory(),
          const SizedBox(height: 16),
          if (inv.balanceRemaining > 0) _buildPayNowSection(inv),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 1. Invoice Header
  // ---------------------------------------------------------------
  Widget _buildInvoiceHeader(Invoice inv) {
    final days = _daysUntilDue();
    final isOverdue = inv.dueDate != null && days < 0;
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_rounded, color: _kSecondary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  inv.customerName ?? (_sw ? 'Biashara' : 'Business'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: _kPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _headerRow(_sw ? 'Ankara #' : 'Invoice #', inv.invoiceNumber),
          if (inv.createdAt != null)
            _headerRow(
              _sw ? 'Tarehe ya kutolewa' : 'Issue date',
              _df.format(inv.createdAt!),
            ),
          if (inv.dueDate != null)
            _headerRow(
              _sw ? 'Tarehe ya mwisho' : 'Due date',
              _df.format(inv.dueDate!),
            ),
          if (inv.dueDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isOverdue
                    ? (_sw ? 'Imechelewa siku ${days.abs()}' : '${days.abs()} days overdue')
                    : (_sw ? 'Siku $days zimebaki' : '$days days remaining'),
                style: TextStyle(
                  color: isOverdue ? Colors.red.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _kSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kPrimary)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 2. Line Items
  // ---------------------------------------------------------------
  Widget _buildLineItems(Invoice inv) {
    if (inv.items.isEmpty) return const SizedBox.shrink();
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
            _sw ? 'Bidhaa / Huduma' : 'Items',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          ...inv.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: const TextStyle(fontSize: 14, color: _kPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}'
                            '${item.unitLabel != null ? ' ${item.unitLabel}' : ''}'
                            ' x ${_formatAmount(item.unitPrice)}',
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatAmount(item.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kPrimary),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 3. Totals
  // ---------------------------------------------------------------
  Widget _buildTotals(Invoice inv) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _totalRow(_sw ? 'Jumla ndogo' : 'Subtotal', _formatAmount(inv.subtotal)),
          if (inv.discountAmount > 0)
            _totalRow(
              _sw ? 'Punguzo' : 'Discount',
              '-${_formatAmount(inv.discountAmount)}',
              valueColor: Colors.green.shade700,
            ),
          if (inv.vatAmount > 0)
            _totalRow('VAT (${inv.vatRate.toStringAsFixed(0)}%)', _formatAmount(inv.vatAmount)),
          const Divider(height: 20),
          _totalRow(_sw ? 'Jumla' : 'Total', _formatAmount(inv.totalAmount), bold: true),
          if (inv.amountPaid > 0)
            _totalRow(
              _sw ? 'Kiasi kilicholipwa' : 'Amount paid',
              _formatAmount(inv.amountPaid),
              valueColor: Colors.green.shade700,
            ),
          _totalRow(
            _sw ? 'Deni lililobaki' : 'Balance remaining',
            _formatAmount(inv.balanceRemaining),
            bold: true,
            valueColor: inv.balanceRemaining > 0 ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _kSecondary,
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
              color: valueColor ?? _kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 4. Payment History
  // ---------------------------------------------------------------
  Widget _buildPaymentHistory() {
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
            _sw ? 'Historia ya Malipo' : 'Payment History',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          if (_payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _sw ? 'Hakuna malipo bado' : 'No payments yet',
                style: const TextStyle(color: _kSecondary, fontSize: 14),
              ),
            )
          else
            ..._payments.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatAmount(p.amount),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kPrimary),
                            ),
                            Text(
                              '${p.methodLabel(swahili: _sw)}${p.paidAt != null ? ' - ${_df.format(p.paidAt!)}' : ''}',
                              style: const TextStyle(fontSize: 12, color: _kSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 5. Pay Now Section
  // ---------------------------------------------------------------
  Widget _buildPayNowSection(Invoice inv) {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final insufficientBalance = _walletBalance > 0 && _walletBalance < amount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sw ? 'Lipa Sasa' : 'Pay Now',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          // Wallet balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _kBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: _kSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _sw
                      ? 'Salio lako: ${_formatAmount(_walletBalance)}'
                      : 'Your balance: ${_formatAmount(_walletBalance)}',
                  style: const TextStyle(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Amount field
          Text(
            _sw ? 'Kiasi cha kulipa' : 'Amount to pay',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixText: 'TZS ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary),
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          // Quick buttons
          Row(
            children: [
              _quickButton(
                _sw ? 'Lipa Yote' : 'Pay Full',
                () {
                  _amountController.text = inv.balanceRemaining.toStringAsFixed(0);
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              _quickButton(
                _sw ? 'Lipa Nusu' : 'Pay Half',
                () {
                  _amountController.text = (inv.balanceRemaining / 2).toStringAsFixed(0);
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              _quickButton(
                _sw ? 'Kiasi Kingine' : 'Other Amount',
                () {
                  _amountController.clear();
                  setState(() {});
                },
              ),
            ],
          ),
          // Insufficient balance warning
          if (insufficientBalance) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sw
                          ? 'Salio halitoshi. Jaza wallet kwanza au lipa kiasi unachoweza.'
                          : 'Insufficient balance. Top up first or pay what you can.',
                      style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/wallet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _sw ? 'Jaza Wallet' : 'Top Up Wallet',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Pay button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _paying ? null : _pay,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _paying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _sw ? 'Lipa Sasa' : 'Pay Now',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickButton(String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimary,
          side: const BorderSide(color: _kSecondary, width: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: const Size(0, 40),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
