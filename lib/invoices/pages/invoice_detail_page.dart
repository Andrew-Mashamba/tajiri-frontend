// lib/invoices/pages/invoice_detail_page.dart
// Full invoice detail page — header, customer, items, totals, payments,
// delivery timeline, notes, VFD, credit notes, and context-sensitive actions.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import 'create_invoice_page.dart';
import 'credit_note_page.dart';
import 'customer_statement_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;
  final int businessId;
  const InvoiceDetailPage({
    super.key,
    required this.invoice,
    required this.businessId,
  });

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final _fmt = NumberFormat('#,###', 'en');
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _dtFmt = DateFormat('dd/MM/yyyy HH:mm');

  String? _token;
  bool _loading = true;
  late Invoice _invoice;
  Business? _business;
  List<InvoicePayment> _payments = [];
  List<InvoiceDelivery> _deliveries = [];
  List<CreditNote> _creditNotes = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (_token == null) return;
    // Load business info
    final userId = storage.getUser()?.userId;
    if (userId != null) {
      final bizRes = await BusinessService.getMyBusinesses(_token!, userId);
      if (bizRes.success) {
        final match = bizRes.data.where((b) => b.id == widget.businessId).toList();
        if (match.isNotEmpty) _business = match.first;
      }
    }
    await _loadDetails();
  }

  Future<void> _loadDetails() async {
    if (_token == null || _invoice.id == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        BusinessService.getInvoice(_token!, _invoice.id!),
        BusinessService.getInvoicePayments(_token!, _invoice.id!),
        BusinessService.getInvoiceDeliveries(_token!, _invoice.id!),
        BusinessService.getInvoiceCreditNotes(_token!, _invoice.id!),
      ]);
      if (!mounted) return;
      final invResult = results[0] as BusinessResult<Invoice>;
      final payResult = results[1] as BusinessListResult<InvoicePayment>;
      final delResult = results[2] as BusinessListResult<InvoiceDelivery>;
      final cnResult = results[3] as BusinessListResult<CreditNote>;
      setState(() {
        if (invResult.success && invResult.data != null) {
          _invoice = invResult.data!;
        }
        _payments = payResult.data;
        _payments.sort((a, b) =>
            (b.paidAt ?? b.createdAt ?? DateTime(2000))
                .compareTo(a.paidAt ?? a.createdAt ?? DateTime(2000)));
        _deliveries = delResult.data;
        _creditNotes = cnResult.data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Status color
  // ---------------------------------------------------------------------------
  Color _statusColor(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue.shade700;
      case InvoiceStatus.delivered:
        return Colors.blue.shade500;
      case InvoiceStatus.viewed:
        return Colors.indigo.shade600;
      case InvoiceStatus.partially_paid:
        return Colors.orange.shade700;
      case InvoiceStatus.paid:
        return Colors.green.shade700;
      case InvoiceStatus.overdue:
        return Colors.red.shade700;
      case InvoiceStatus.cancelled:
        return Colors.grey;
      case InvoiceStatus.credit_noted:
        return Colors.purple.shade600;
      case InvoiceStatus.void_status:
        return Colors.grey.shade400;
    }
  }

  Color _deliveryStatusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'viewed':
        return Colors.green.shade700;
      case 'sent':
        return Colors.blue.shade700;
      case 'failed':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _channelIcon(String channel) {
    switch (channel) {
      case 'whatsapp':
        return Icons.chat_rounded;
      case 'in_app':
        return Icons.phone_android_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'pdf_download':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.send_rounded;
    }
  }

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'mpesa':
      case 'tigo_pesa':
      case 'airtel_money':
        return Icons.phone_android_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.payments_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String _fmtCurrency(double v) => 'TZS ${_fmt.format(v.round())}';

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _voidInvoice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_sw ? 'Batilisha Ankara' : 'Void Invoice'),
        content: Text(_sw
            ? 'Ankara hii itabatilishwa na haiwezi kurudishwa. Una uhakika?'
            : 'This invoice will be voided and cannot be reversed. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_sw ? 'Hapana' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_sw ? 'Ndiyo, Batilisha' : 'Yes, Void',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || _token == null || _invoice.id == null) return;
    final res = await BusinessService.voidInvoice(_token!, _invoice.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.success
          ? (_sw ? 'Ankara imebatilishwa' : 'Invoice voided')
          : (res.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
    ));
    if (res.success) _loadDetails();
  }

  Future<void> _downloadPdf() async {
    if (_token == null || _invoice.id == null) return;
    final res = await BusinessService.getInvoicePdf(_token!, _invoice.id!);
    if (!mounted) return;
    if (res.success && res.data != null && res.data!.isNotEmpty) {
      final uri = Uri.tryParse(res.data!);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (_sw ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  void _editInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateInvoicePage(
          businessId: widget.businessId,
          editInvoice: _invoice,
        ),
      ),
    ).then((_) => _loadDetails());
  }

  // ---------------------------------------------------------------------------
  // Send Invoice (multi-channel)
  // ---------------------------------------------------------------------------
  void _showSendSheet() {
    final sw = _sw;
    final hasPhone = _invoice.customerPhone != null && _invoice.customerPhone!.isNotEmpty;
    final hasEmail = _invoice.customerEmail != null && _invoice.customerEmail!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final selected = <String>{};
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                  left: 20, right: 20, top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(sw ? 'Tuma Ankara' : 'Send Invoice',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
                  const SizedBox(height: 4),
                  Text('${_invoice.invoiceNumber} — ${_fmtCurrency(_invoice.totalAmount)}',
                      style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  const SizedBox(height: 16),
                  // WhatsApp
                  _channelCheckbox(
                    'whatsapp', Icons.chat_rounded, 'WhatsApp',
                    enabled: hasPhone, selected: selected,
                    disabledHint: sw ? 'Mteja hana nambari ya simu' : 'Customer has no phone number',
                    onChanged: (v) => setLocal(() => v ? selected.add('whatsapp') : selected.remove('whatsapp')),
                  ),
                  // Email
                  _channelCheckbox(
                    'email', Icons.email_rounded, sw ? 'Barua pepe' : 'Email',
                    enabled: hasEmail, selected: selected,
                    disabledHint: sw ? 'Mteja hana barua pepe' : 'Customer has no email',
                    onChanged: (v) => setLocal(() => v ? selected.add('email') : selected.remove('email')),
                  ),
                  // In-App
                  _channelCheckbox(
                    'in_app', Icons.phone_android_rounded, sw ? 'Ndani ya TAJIRI' : 'In-App',
                    enabled: _invoice.customerId != null, selected: selected,
                    disabledHint: sw ? 'Mteja hayupo TAJIRI' : 'Customer not on TAJIRI',
                    onChanged: (v) => setLocal(() => v ? selected.add('in_app') : selected.remove('in_app')),
                  ),
                  // PDF Download
                  _channelCheckbox(
                    'pdf_download', Icons.picture_as_pdf_rounded, 'PDF',
                    enabled: true, selected: selected,
                    onChanged: (v) => setLocal(() => v ? selected.add('pdf_download') : selected.remove('pdf_download')),
                  ),
                  const SizedBox(height: 16),
                  // WhatsApp message preview
                  if (selected.contains('whatsapp')) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kBackground, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200)),
                      child: Text(
                        sw
                            ? 'Habari ${_invoice.customerName ?? ''}, ankara yako #${_invoice.invoiceNumber} ya ${_fmtCurrency(_invoice.totalAmount)} iko tayari. Tafadhali lipa kabla ya ${_invoice.dueDate != null ? _dateFmt.format(_invoice.dueDate!) : '-'}. Ahsante!'
                            : 'Dear ${_invoice.customerName ?? ''}, your invoice #${_invoice.invoiceNumber} for ${_fmtCurrency(_invoice.totalAmount)} is ready. Please pay before ${_invoice.dueDate != null ? _dateFmt.format(_invoice.dueDate!) : '-'}. Thank you!',
                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      onPressed: selected.isEmpty ? null : () async {
                        Navigator.pop(ctx);
                        await _executeSend(selected.toList());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary, foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(sw ? 'Tuma Ankara' : 'Send Invoice',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _channelCheckbox(String key, IconData icon, String label, {
    required bool enabled,
    required Set<String> selected,
    String? disabledHint,
    required ValueChanged<bool> onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: CheckboxListTile(
        value: selected.contains(key),
        onChanged: enabled ? (v) => onChanged(v == true) : null,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeColor: _kPrimary,
        title: Row(
          children: [
            Icon(icon, size: 18, color: enabled ? _kPrimary : _kSecondary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, color: enabled ? _kPrimary : _kSecondary)),
          ],
        ),
        subtitle: !enabled && disabledHint != null
            ? Text(disabledHint, style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
            : null,
      ),
    );
  }

  Future<void> _executeSend(List<String> channels) async {
    if (_token == null || _invoice.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    // Handle PDF download separately
    if (channels.contains('pdf_download')) {
      _downloadPdf();
      channels.remove('pdf_download');
    }

    // Send via API channels
    if (channels.isNotEmpty) {
      final res = await BusinessService.sendInvoiceMultiChannel(
        _token!, _invoice.id!, {'channels': channels},
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Ankara imetumwa!' : 'Invoice sent!')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Failed'))),
      ));
    }

    _loadDetails();
  }

  // ---------------------------------------------------------------------------
  // Record Payment
  // ---------------------------------------------------------------------------
  void _showRecordPaymentSheet() {
    final sw = _sw;
    final remaining = _invoice.balanceRemaining;
    final amountCtrl = TextEditingController(text: remaining.round().toString());
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedMethod = 'mpesa';
    DateTime paymentDate = DateTime.now();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final enteredAmount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
            final exceeds = enteredAmount > remaining;
            return Padding(
              padding: EdgeInsets.only(
                  left: 20, right: 20, top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(sw ? 'Pokea Malipo' : 'Record Payment',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
                    const SizedBox(height: 4),
                    Text('${sw ? 'Baki' : 'Balance'}: ${_fmtCurrency(remaining)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                    const SizedBox(height: 16),

                    // Amount
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setLocal(() {}),
                      decoration: InputDecoration(
                        labelText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
                        filled: true, fillColor: _kBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        errorText: exceeds ? (sw ? 'Kiasi kimezidi baki' : 'Amount exceeds balance') : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick buttons
                    Row(
                      children: [
                        _quickAmountChip(sw ? 'Lipa Yote' : 'Pay Full', remaining, amountCtrl, setLocal),
                        const SizedBox(width: 8),
                        _quickAmountChip(sw ? 'Nusu' : 'Half', (remaining / 2).roundToDouble(), amountCtrl, setLocal),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment method
                    Text(sw ? 'Njia ya malipo' : 'Payment method',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _methodChip('mpesa', 'M-Pesa', Icons.phone_android_rounded, selectedMethod, (v) => setLocal(() => selectedMethod = v)),
                        _methodChip('tigo_pesa', 'Tigo Pesa', Icons.phone_android_rounded, selectedMethod, (v) => setLocal(() => selectedMethod = v)),
                        _methodChip('airtel_money', 'Airtel', Icons.phone_android_rounded, selectedMethod, (v) => setLocal(() => selectedMethod = v)),
                        _methodChip('bank', sw ? 'Benki' : 'Bank', Icons.account_balance_rounded, selectedMethod, (v) => setLocal(() => selectedMethod = v)),
                        _methodChip('cash', sw ? 'Taslimu' : 'Cash', Icons.payments_rounded, selectedMethod, (v) => setLocal(() => selectedMethod = v)),
                        _methodChip('wallet', 'Wallet', Icons.account_balance_wallet_rounded, selectedMethod, (v) => setLocal(() => selectedMethod = v)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Reference
                    TextField(
                      controller: refCtrl,
                      decoration: InputDecoration(
                        labelText: sw ? 'Nambari ya uthibitisho' : 'Reference number',
                        hintText: sw ? 'Mfano: M-Pesa code' : 'e.g. M-Pesa code',
                        filled: true, fillColor: _kBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    GestureDetector(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: ctx, initialDate: paymentDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (dt != null) setLocal(() => paymentDate = dt);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: sw ? 'Tarehe ya malipo' : 'Payment date',
                          filled: true, fillColor: _kBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                        ),
                        child: Text(_dateFmt.format(paymentDate)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: sw ? 'Maelezo' : 'Notes',
                        hintText: sw ? 'Malipo ya kwanza, n.k.' : 'First installment, etc.',
                        filled: true, fillColor: _kBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save button
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: (saving || exceeds || enteredAmount <= 0) ? null : () async {
                          setLocal(() => saving = true);
                          final body = {
                            'amount': enteredAmount,
                            'method': selectedMethod,
                            'paid_at': paymentDate.toIso8601String(),
                            if (refCtrl.text.trim().isNotEmpty) 'reference': refCtrl.text.trim(),
                            if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                            'recorded_by': 'manual',
                          };
                          final messenger = ScaffoldMessenger.of(ctx);
                          final nav = Navigator.of(ctx);
                          final res = await BusinessService.recordInvoicePayment(_token!, _invoice.id!, body);
                          if (!ctx.mounted) return;
                          nav.pop();
                          messenger.showSnackBar(SnackBar(
                            content: Text(res.success
                                ? (sw ? 'Malipo ya ${_fmtCurrency(enteredAmount)} yamehifadhiwa' : 'Payment of ${_fmtCurrency(enteredAmount)} recorded')
                                : (res.message ?? (sw ? 'Imeshindikana' : 'Failed'))),
                          ));
                          if (res.success) {
                            // Auto-trigger VFD receipt if invoice is now fully paid
                            final newPaid = _invoice.amountPaid + enteredAmount;
                            if (newPaid >= _invoice.totalAmount && _token != null && _invoice.id != null) {
                              BusinessService.generateVfdReceipt(_token!, _invoice.id!);
                            }
                            _loadDetails();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary, foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: saving
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(sw ? 'Hifadhi Malipo' : 'Save Payment',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickAmountChip(String label, double amount, TextEditingController ctrl, StateSetter setLocal) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: _kPrimary.withValues(alpha: 0.08),
      side: BorderSide.none,
      onPressed: () => setLocal(() => ctrl.text = amount.round().toString()),
    );
  }

  Widget _methodChip(String value, String label, IconData icon, String selected, ValueChanged<String> onSelect) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? _kPrimary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : _kSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _kPrimary)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Send Reminder
  // ---------------------------------------------------------------------------
  void _showReminderSheet() {
    final sw = _sw;
    final overdue = isInvoiceOverdue(_invoice);
    final overdueDays = invoiceOverdueDays(_invoice);
    final balance = _invoice.balanceRemaining;
    final isPartial = _invoice.status == InvoiceStatus.partially_paid;

    String message;
    if (isPartial) {
      message = sw
          ? 'Habari ${_invoice.customerName ?? ''}, asante kwa malipo ya ${_fmtCurrency(_invoice.amountPaid)}. Baki ya ankara #${_invoice.invoiceNumber} ni ${_fmtCurrency(balance)}. Tafadhali kamilisha malipo. Ahsante!'
          : 'Dear ${_invoice.customerName ?? ''}, thank you for the payment of ${_fmtCurrency(_invoice.amountPaid)}. The balance on invoice #${_invoice.invoiceNumber} is ${_fmtCurrency(balance)}. Please complete payment. Thank you!';
    } else if (overdue) {
      message = sw
          ? 'Habari ${_invoice.customerName ?? ''}, ankara #${_invoice.invoiceNumber} ya ${_fmtCurrency(_invoice.totalAmount)} ilipaswa kulipwa ${_invoice.dueDate != null ? _dateFmt.format(_invoice.dueDate!) : '-'} (siku $overdueDays zilizopita). Tafadhali lipa haraka iwezekanavyo. Ahsante!'
          : 'Dear ${_invoice.customerName ?? ''}, invoice #${_invoice.invoiceNumber} for ${_fmtCurrency(_invoice.totalAmount)} was due on ${_invoice.dueDate != null ? _dateFmt.format(_invoice.dueDate!) : '-'} ($overdueDays days ago). Please pay as soon as possible. Thank you!';
    } else {
      final daysLeft = _invoice.dueDate != null ? _invoice.dueDate!.difference(DateTime.now()).inDays : 0;
      message = sw
          ? 'Habari ${_invoice.customerName ?? ''}, ankara #${_invoice.invoiceNumber} ya ${_fmtCurrency(_invoice.totalAmount)} mwisho wake ni ${_invoice.dueDate != null ? _dateFmt.format(_invoice.dueDate!) : '-'} (siku $daysLeft zimebaki). Tafadhali lipa ndani ya muda. Ahsante!'
          : 'Dear ${_invoice.customerName ?? ''}, invoice #${_invoice.invoiceNumber} for ${_fmtCurrency(_invoice.totalAmount)} is due on ${_invoice.dueDate != null ? _dateFmt.format(_invoice.dueDate!) : '-'} ($daysLeft days remaining). Please pay on time. Thank you!';
    }

    final msgCtrl = TextEditingController(text: message);
    String channel = 'whatsapp';

    // Check for recent reminder in deliveries
    final recentReminder = _deliveries.where((d) =>
      d.deliveryType == 'reminder' &&
      d.sentAt != null &&
      DateTime.now().difference(d.sentAt!).inDays < 3
    ).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                  left: 20, right: 20, top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(sw ? 'Tuma Kikumbusho' : 'Send Reminder',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
                    const SizedBox(height: 4),
                    Text('${_invoice.invoiceNumber} — ${_fmtCurrency(balance)} ${sw ? 'baki' : 'remaining'}',
                        style: const TextStyle(fontSize: 13, color: _kSecondary)),

                    // Cooldown warning
                    if (recentReminder.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200)),
                        child: Text(
                          sw ? 'Kikumbusho kilitumwa siku ${DateTime.now().difference(recentReminder.first.sentAt!).inDays} zilizopita. Tuma tena?'
                             : 'Reminder was sent ${DateTime.now().difference(recentReminder.first.sentAt!).inDays} days ago. Send again?',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Message
                    TextField(
                      controller: msgCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: sw ? 'Ujumbe' : 'Message',
                        filled: true, fillColor: _kBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Channel picker
                    Text(sw ? 'Tuma kupitia' : 'Send via',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _methodChip('whatsapp', 'WhatsApp', Icons.chat_rounded, channel, (v) => setLocal(() => channel = v)),
                        _methodChip('email', sw ? 'Barua pepe' : 'Email', Icons.email_rounded, channel, (v) => setLocal(() => channel = v)),
                        _methodChip('in_app', sw ? 'TAJIRI' : 'In-App', Icons.phone_android_rounded, channel, (v) => setLocal(() => channel = v)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          // If a recent reminder was sent (< 3 days), confirm before sending
                          if (recentReminder.isNotEmpty) {
                            final confirmed = await showDialog<bool>(
                              context: ctx,
                              builder: (dlgCtx) => AlertDialog(
                                title: Text(sw
                                    ? 'Tuma tena?'
                                    : 'Send again?'),
                                content: Text(sw
                                    ? 'Kikumbusho kilitumwa hivi karibuni. Tuma tena?'
                                    : 'Reminder was sent recently. Send again?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dlgCtx, false),
                                    child: Text(sw ? 'Hapana' : 'No'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dlgCtx, true),
                                    child: Text(sw ? 'Ndio' : 'Yes'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          final body = {
                            'channel': channel,
                            'message': msgCtrl.text.trim(),
                          };
                          final res = await BusinessService.sendInvoiceReminder(_token!, _invoice.id!, body);
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(
                            content: Text(res.success
                                ? (sw ? 'Kikumbusho kimetumwa' : 'Reminder sent')
                                : (res.message ?? (sw ? 'Imeshindikana' : 'Failed'))),
                          ));
                          if (res.success) _loadDetails();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.notifications_rounded, size: 18),
                        label: Text(sw ? 'Tuma Kikumbusho' : 'Send Reminder',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCreditNotePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditNotePage(invoice: _invoice),
      ),
    ).then((result) {
      if (result == true) _loadDetails();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _invoice.invoiceNumber.isNotEmpty
              ? _invoice.invoiceNumber
              : 'Invoice #${_invoice.id ?? ''}',
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _kPrimary),
            onSelected: (v) {
              switch (v) {
                case 'pdf':
                  _downloadPdf();
                case 'void':
                  _voidInvoice();
                case 'statement':
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CustomerStatementPage(
                      businessId: widget.businessId,
                      customerId: _invoice.customerId,
                      customerName: _invoice.customerName,
                    ),
                  ));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pdf',
                child: Text(_sw ? 'Pakua PDF' : 'Download PDF'),
              ),
              if (_invoice.customerId != null || _invoice.customerName != null)
                PopupMenuItem(
                  value: 'statement',
                  child: Text(_sw ? 'Taarifa ya Mteja' : 'Customer Statement'),
                ),
              if (_invoice.status == InvoiceStatus.draft)
                PopupMenuItem(
                  value: 'void',
                  child: Text(_sw ? 'Batilisha' : 'Void',
                      style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildBusinessCard(),
                const SizedBox(height: 12),
                _buildCustomerCard(),
                const SizedBox(height: 12),
                _buildLineItems(),
                const SizedBox(height: 12),
                _buildTotals(),
                if (_invoice.amountPaid > 0) ...[
                  const SizedBox(height: 12),
                  _buildPaymentProgress(),
                ],
                const SizedBox(height: 12),
                _buildPaymentHistory(),
                const SizedBox(height: 12),
                _buildDeliveryTimeline(),
                if (_invoice.notes != null && _invoice.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildNotesSection(),
                ],
                if (_invoice.sourceQuoteId != null) ...[
                  const SizedBox(height: 12),
                  _buildSourceReference(),
                ],
                if (_invoice.vfdReceiptNumber != null ||
                    _invoice.status == InvoiceStatus.paid ||
                    _creditNotes.any((cn) => cn.vfdReverseReceiptNumber != null)) ...[
                  const SizedBox(height: 12),
                  _buildVfdSection(),
                ],
                if (_creditNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCreditNotes(),
                ],
              ],
            ),
      bottomNavigationBar: _loading ? null : _buildBottomBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    final overdue = isInvoiceOverdue(_invoice);
    final overdueDays = invoiceOverdueDays(_invoice);
    final voided = _invoice.status == InvoiceStatus.void_status;

    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _invoice.invoiceNumber.isNotEmpty
                        ? _invoice.invoiceNumber
                        : 'Invoice #${_invoice.id ?? ''}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(_invoice.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    invoiceStatusLabel(_invoice.status, swahili: _sw),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(_invoice.status)),
                  ),
                ),
              ],
            ),
            if (voided) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _sw ? 'Imebatilishwa' : 'Voided',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (overdue && !voided) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _sw
                      ? 'Imechelewa siku $overdueDays'
                      : 'Overdue by $overdueDays days',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _labelValue(
                    _sw ? 'Imeundwa' : 'Created',
                    _invoice.createdAt != null
                        ? _dateFmt.format(_invoice.createdAt!)
                        : '-',
                  ),
                ),
                Expanded(
                  child: _labelValue(
                    _sw ? 'Tarehe ya mwisho' : 'Due Date',
                    _invoice.dueDate != null
                        ? _dateFmt.format(_invoice.dueDate!)
                        : '-',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Customer
  // ---------------------------------------------------------------------------
  Widget _buildBusinessCard() {
    if (_business == null) return const SizedBox.shrink();
    final b = _business!;
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sw ? 'Biashara' : 'Business',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary)),
            const SizedBox(height: 8),
            Text(b.name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (b.tinNumber != null && b.tinNumber!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.badge_rounded, size: 15, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text('TIN: ${b.tinNumber!}',
                      style: const TextStyle(fontSize: 14, color: _kSecondary)),
                ],
              ),
            ],
            if (b.vrn != null && b.vrn!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 15, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text('VRN: ${b.vrn!}',
                      style: const TextStyle(fontSize: 14, color: _kSecondary)),
                ],
              ),
            ],
            if (b.address != null && b.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 15, color: _kSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(b.address!,
                        style: const TextStyle(fontSize: 14, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            if (b.phone != null && b.phone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 15, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text(b.phone!,
                      style: const TextStyle(fontSize: 14, color: _kSecondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    final hasCustomer = _invoice.customerName != null ||
        _invoice.customerPhone != null ||
        _invoice.customerEmail != null;
    if (!hasCustomer) return const SizedBox.shrink();

    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sw ? 'Mteja' : 'Customer',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary)),
            const SizedBox(height: 8),
            if (_invoice.customerName != null)
              Text(_invoice.customerName!,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            if (_invoice.customerPhone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 15, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text(_invoice.customerPhone!,
                      style:
                          const TextStyle(fontSize: 14, color: _kSecondary)),
                ],
              ),
            ],
            if (_invoice.customerEmail != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_rounded, size: 15, color: _kSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_invoice.customerEmail!,
                        style:
                            const TextStyle(fontSize: 14, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            if (_invoice.customerTin != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.badge_rounded, size: 15, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text('TIN: ${_invoice.customerTin!}',
                      style:
                          const TextStyle(fontSize: 14, color: _kSecondary)),
                ],
              ),
            ],
            if (_invoice.customerAddress != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 15, color: _kSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_invoice.customerAddress!,
                        style:
                            const TextStyle(fontSize: 14, color: _kSecondary),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Line Items
  // ---------------------------------------------------------------------------
  Widget _buildLineItems() {
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sw ? 'Bidhaa / Huduma' : 'Items / Services',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary)),
            const SizedBox(height: 12),
            // Column headers
            Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text(_sw ? 'Maelezo' : 'Description',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500))),
                Expanded(
                    flex: 1,
                    child: Text(_sw ? 'Idadi' : 'Qty',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        textAlign: TextAlign.center)),
                Expanded(
                    flex: 2,
                    child: Text(_sw ? 'Bei' : 'Price',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        textAlign: TextAlign.right)),
                Expanded(
                    flex: 2,
                    child: Text(_sw ? 'Jumla' : 'Total',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        textAlign: TextAlign.right)),
              ],
            ),
            const Divider(height: 16),
            ..._invoice.items.map(_buildItemRow),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(InvoiceItem item) {
    final unitStr = item.unitLabel != null && item.unitLabel!.isNotEmpty
        ? ' ${item.unitLabel}'
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(item.description,
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 1,
                child: Text(
                    '${_fmt.format(item.quantity.round())}$unitStr',
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 2,
                child: Text(_fmt.format(item.unitPrice.round()),
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 2,
                child: Text(_fmt.format(item.totalPrice.round()),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (item.isVatExempt)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _sw ? '(Hakuna VAT)' : '(VAT exempt)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Totals
  // ---------------------------------------------------------------------------
  Widget _buildTotals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _totalRow(_sw ? 'Jumla ndogo' : 'Subtotal',
              _fmtCurrency(_invoice.subtotal)),
          if (_invoice.discountAmount > 0) ...[
            const SizedBox(height: 6),
            _totalRow(
              _sw ? 'Punguzo' : 'Discount',
              '- ${_fmtCurrency(_invoice.discountAmount)}',
              valueColor: Colors.orange.shade700,
            ),
          ],
          const SizedBox(height: 6),
          _totalRow(
            'VAT (${_invoice.vatRate.round()}%)',
            _fmtCurrency(_invoice.vatAmount),
          ),
          const Divider(height: 20),
          _totalRow(
            _sw ? 'Jumla' : 'Total',
            _fmtCurrency(_invoice.totalAmount),
            bold: true,
            fontSize: 16,
          ),
          const SizedBox(height: 8),
          _totalRow(
            _sw ? 'Kiasi Kilicholipwa' : 'Amount Paid',
            _fmtCurrency(_invoice.amountPaid),
            valueColor: Colors.green.shade700,
          ),
          const SizedBox(height: 6),
          _totalRow(
            _sw ? 'Salio' : 'Balance Remaining',
            _fmtCurrency(_invoice.balanceRemaining),
            bold: true,
            valueColor: _invoice.balanceRemaining > 0
                ? Colors.red.shade700
                : Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool bold = false, double fontSize = 14, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: _kPrimary)),
        Text(value,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? _kPrimary)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Payment Progress
  // ---------------------------------------------------------------------------
  Widget _buildPaymentProgress() {
    final ratio = _invoice.totalAmount > 0
        ? (_invoice.amountPaid / _invoice.totalAmount).clamp(0.0, 1.0)
        : 0.0;
    final percent = (ratio * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_fmtCurrency(_invoice.amountPaid)} / ${_fmtCurrency(_invoice.totalAmount)} ($percent%)',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Payment History
  // ---------------------------------------------------------------------------
  Widget _buildPaymentHistory() {
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sw ? 'Historia ya Malipo' : 'Payment History',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary)),
            const SizedBox(height: 8),
            if (_payments.isEmpty)
              Text(_sw ? 'Hakuna malipo bado' : 'No payments yet',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500))
            else
              ..._payments.map(_buildPaymentItem),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(InvoicePayment p) {
    final dateStr = p.paidAt != null ? _dtFmt.format(p.paidAt!) : '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_paymentMethodIcon(p.method), size: 18, color: _kSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.methodLabel(swahili: _sw),
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: p.recordedBy == 'auto'
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p.recordedBy == 'auto' ? 'Auto' : 'Manual',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: p.recordedBy == 'auto'
                          ? Colors.blue.shade700
                          : _kSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              Text(_fmtCurrency(p.amount),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
            ],
          ),
          if (p.reference != null && p.reference!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Ref: ${p.reference!}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Delivery Timeline
  // ---------------------------------------------------------------------------
  Widget _buildDeliveryTimeline() {
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sw ? 'Hali ya Uwasilishaji' : 'Delivery Status',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary)),
            const SizedBox(height: 8),
            if (_deliveries.isEmpty)
              Text(
                  _sw
                      ? 'Ankara bado haijatumwa'
                      : 'Invoice not yet sent',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500))
            else
              ..._deliveries.map(_buildDeliveryItem),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryItem(InvoiceDelivery d) {
    final isReminder = d.deliveryType == 'reminder';
    final prefix =
        isReminder ? (_sw ? 'Kikumbusho - ' : 'Reminder - ') : '';
    final dateStr = d.sentAt != null ? _dtFmt.format(d.sentAt!) : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_channelIcon(d.channel), size: 18, color: _kSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$prefix${d.channelLabel(swahili: _sw)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(dateStr,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _deliveryStatusColor(d.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              d.status[0].toUpperCase() + d.status.substring(1),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _deliveryStatusColor(d.status)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Notes
  // ---------------------------------------------------------------------------
  Widget _buildNotesSection() {
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sw ? 'Maelezo' : 'Notes',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary)),
            const SizedBox(height: 8),
            Text(_invoice.notes!,
                style: const TextStyle(fontSize: 14, color: _kPrimary)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. Source Reference
  // ---------------------------------------------------------------------------
  Widget _buildSourceReference() {
    final sw = _sw;
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: const Icon(Icons.link_rounded, size: 16, color: _kSecondary),
        label: Text(
          sw
              ? 'Kutoka Nukuu #${_invoice.sourceQuoteId}'
              : 'From Quote #${_invoice.sourceQuoteId}',
          style: const TextStyle(fontSize: 13, color: _kPrimary),
        ),
        backgroundColor: _kCardBg,
        side: BorderSide(color: Colors.grey.shade300),
        onPressed: _showQuoteDetail,
      ),
    );
  }

  Future<void> _showQuoteDetail() async {
    if (_token == null || _invoice.sourceQuoteId == null) return;
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _kPrimary)),
    );

    try {
      final res = await BusinessService.getQuotes(_token!, widget.businessId);
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading

      if (!res.success) {
        messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Imeshindikana kupakia nukuu' : 'Failed to load quotes'),
        ));
        return;
      }

      final match = res.data.where((q) => q.id == _invoice.sourceQuoteId).toList();
      if (match.isEmpty) {
        messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Nukuu haipatikani' : 'Quote not found'),
        ));
        return;
      }

      final quote = match.first;

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: _kCardBg,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            expand: false,
            builder: (_, scrollCtrl) => ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
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
                  sw ? 'Nukuu ya Chanzo' : 'Source Quote',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
                ),
                const SizedBox(height: 16),

                // Quote number & status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        quote.quoteNumber.isNotEmpty
                            ? quote.quoteNumber
                            : '#${quote.id ?? ''}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        quoteStatusLabel(quote.status, swahili: sw),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Customer
                if (quote.customerName != null && quote.customerName!.isNotEmpty)
                  _cnDetailRow(sw ? 'Mteja' : 'Customer', quote.customerName!),
                const SizedBox(height: 8),

                // Valid until
                if (quote.validUntil != null)
                  _cnDetailRow(
                    sw ? 'Inaisha' : 'Valid Until',
                    df.format(quote.validUntil!),
                  ),
                const Divider(height: 20),

                // Items
                Text(
                  sw ? 'Bidhaa / Huduma' : 'Items / Services',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary),
                ),
                const SizedBox(height: 8),
                if (quote.items.isNotEmpty)
                  ...quote.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.description} x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}',
                            style: const TextStyle(fontSize: 13, color: _kPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'TZS ${nf.format((item.quantity * item.unitPrice).round())}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                        ),
                      ],
                    ),
                  ))
                else
                  Text(
                    sw ? 'Hakuna bidhaa' : 'No items',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                const Divider(height: 20),

                // Totals
                _cnDetailRow(sw ? 'Jumla ndogo' : 'Subtotal',
                    'TZS ${nf.format(quote.subtotal.round())}'),
                const SizedBox(height: 4),
                _cnDetailRow('VAT (${quote.vatRate.round()}%)',
                    'TZS ${nf.format(quote.vatAmount.round())}'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sw ? 'JUMLA' : 'TOTAL',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                    Text('TZS ${nf.format(quote.totalAmount.round())}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                  ],
                ),

                // Notes
                if (quote.notes != null && quote.notes!.trim().isNotEmpty) ...[
                  const Divider(height: 20),
                  _cnDetailRow(sw ? 'Maelezo' : 'Notes', quote.notes!),
                ],

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Imeshindikana kupakia nukuu' : 'Failed to load quote'),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 10. VFD
  // ---------------------------------------------------------------------------
  Widget _buildVfdSection() {
    final sw = _sw;
    // Show VFD section for paid invoices even if receipt not yet generated
    final hasCreditNoteVfd = _creditNotes.any((cn) =>
        cn.vfdReverseReceiptNumber != null && cn.vfdReverseReceiptNumber!.isNotEmpty);

    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 18, color: _kSecondary),
                const SizedBox(width: 6),
                Text(sw ? 'Risiti ya VFD' : 'VFD Receipt',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            // Original VFD receipt
            if (_invoice.vfdReceiptNumber != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_invoice.vfdReceiptNumber!,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(sw ? 'Risiti imetolewa' : 'Receipt issued',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
                        ],
                      ),
                    ),
                    if (_invoice.vfdReceiptUrl != null)
                      IconButton(
                        icon: Icon(Icons.download_rounded, size: 20, color: Colors.green.shade700),
                        onPressed: () {
                          final uri = Uri.tryParse(_invoice.vfdReceiptUrl!);
                          if (uri != null) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ] else if (_invoice.status == InvoiceStatus.paid) ...[
              // Paid but no VFD yet — may be generating or failed
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sw ? 'Risiti ya VFD inatengenezwa au imeshindikana. Jaribu tena.'
                           : 'VFD receipt is generating or failed. Tap to retry.',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, size: 20, color: Colors.orange.shade700),
                      onPressed: () async {
                        if (_token == null || _invoice.id == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final res = await BusinessService.retryVfdReceipt(_token!, _invoice.id!);
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(
                          content: Text(res.success
                              ? (_sw ? 'VFD inajaribiwa tena' : 'VFD retry initiated')
                              : (res.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
                        ));
                        _loadDetails();
                      },
                    ),
                  ],
                ),
              ),
            ],
            // Reverse VFD from credit notes
            if (hasCreditNoteVfd) ...[
              const SizedBox(height: 8),
              ..._creditNotes
                  .where((cn) => cn.vfdReverseReceiptNumber != null && cn.vfdReverseReceiptNumber!.isNotEmpty)
                  .map((cn) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.undo_rounded, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cn.vfdReverseReceiptNumber!,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(sw ? 'Risiti ya mkopo (${cn.creditNoteNumber})'
                                     : 'Reverse receipt (${cn.creditNoteNumber})',
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 11. Credit Notes
  // ---------------------------------------------------------------------------
  Widget _buildCreditNotes() {
    return Card(
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sw ? 'Nota za Mkopo' : 'Credit Notes',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary)),
            const SizedBox(height: 8),
            ..._creditNotes.map(_buildCreditNoteItem),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditNoteItem(CreditNote cn) {
    final dateStr = cn.issuedAt != null ? _dateFmt.format(cn.issuedAt!) : '-';
    return GestureDetector(
      onTap: () => _showCreditNoteDetailSheet(cn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                      cn.creditNoteNumber.isNotEmpty
                          ? cn.creditNoteNumber
                          : 'CN #${cn.id ?? ''}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cn.status == 'issued'
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cn.status == 'issued'
                        ? (_sw ? 'Imetolewa' : 'Issued')
                        : (_sw ? 'Rasimu' : 'Draft'),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cn.status == 'issued'
                            ? Colors.green.shade700
                            : _kSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cn.reasonLabel(swahili: _sw),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(_fmtCurrency(cn.totalAmount),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreditNoteDetailSheet(CreditNote cn) {
    final sw = _sw;
    final dateStr = cn.issuedAt != null ? _dtFmt.format(cn.issuedAt!) : '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
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
                sw ? 'Nota ya Mkopo' : 'Credit Note',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
              ),
              const SizedBox(height: 16),

              // Number & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cn.creditNoteNumber.isNotEmpty
                        ? cn.creditNoteNumber
                        : 'CN #${cn.id ?? ''}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cn.status == 'issued'
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cn.status == 'issued'
                          ? (sw ? 'Imetolewa' : 'Issued')
                          : (sw ? 'Rasimu' : 'Draft'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cn.status == 'issued'
                              ? Colors.green.shade700
                              : _kSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Invoice Reference
              _cnDetailRow(
                sw ? 'Ankara Husika' : 'Invoice Reference',
                _invoice.invoiceNumber,
              ),
              const Divider(height: 20),

              // Date
              _cnDetailRow(sw ? 'Tarehe' : 'Date', dateStr),
              const SizedBox(height: 8),

              // Reason
              _cnDetailRow(sw ? 'Sababu' : 'Reason', cn.reasonLabel(swahili: sw)),
              const Divider(height: 20),

              // Items
              Text(
                sw ? 'Bidhaa za Mkopo' : 'Credited Items',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary),
              ),
              const SizedBox(height: 8),
              if (cn.items.isNotEmpty)
                ...cn.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.description} x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}',
                          style: const TextStyle(fontSize: 13, color: _kPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _fmtCurrency(item.quantity * item.unitPrice),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                      ),
                    ],
                  ),
                ))
              else
                Text(
                  sw ? 'Hakuna bidhaa' : 'No items',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              const Divider(height: 20),

              // Totals
              _cnDetailRow(sw ? 'Jumla ndogo' : 'Subtotal',
                  _fmtCurrency(cn.subtotal)),
              const SizedBox(height: 4),
              _cnDetailRow(sw ? 'VAT' : 'VAT', _fmtCurrency(cn.vatAmount)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sw ? 'JUMLA YA MKOPO' : 'CREDIT TOTAL',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                  Text(_fmtCurrency(cn.totalAmount),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                ],
              ),

              // VFD Reverse Receipt
              if (cn.vfdReverseReceiptNumber != null &&
                  cn.vfdReverseReceiptNumber!.isNotEmpty) ...[
                const Divider(height: 20),
                _cnDetailRow(sw ? 'VFD Risiti ya Kurudi' : 'VFD Reverse Receipt',
                    cn.vfdReverseReceiptNumber!),
              ],

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _cnDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: _kSecondary)),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 12. Bottom Action Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar() {
    final status = _invoice.status;
    final actions = <Widget>[];

    switch (status) {
      case InvoiceStatus.draft:
        actions.addAll([
          _actionBtn(Icons.edit_rounded, _sw ? 'Hariri' : 'Edit', _editInvoice),
          _actionBtn(
              Icons.send_rounded, _sw ? 'Tuma' : 'Send', _showSendSheet),
          _actionBtn(Icons.block_rounded, _sw ? 'Batilisha' : 'Void',
              _voidInvoice,
              color: Colors.red.shade700),
        ]);
      case InvoiceStatus.sent:
      case InvoiceStatus.delivered:
      case InvoiceStatus.viewed:
        actions.addAll([
          _actionBtn(Icons.refresh_rounded, _sw ? 'Tuma tena' : 'Resend',
              _showSendSheet),
          _actionBtn(Icons.notifications_rounded,
              _sw ? 'Kumbuka' : 'Remind', _showReminderSheet),
          _actionBtn(Icons.payment_rounded,
              _sw ? 'Pokea Malipo' : 'Record Payment', _showRecordPaymentSheet),
        ]);
      case InvoiceStatus.partially_paid:
        actions.addAll([
          _actionBtn(Icons.payment_rounded,
              _sw ? 'Pokea Malipo' : 'Record Payment', _showRecordPaymentSheet),
          _actionBtn(Icons.notifications_rounded,
              _sw ? 'Kumbuka' : 'Remind', _showReminderSheet),
        ]);
      case InvoiceStatus.overdue:
        actions.addAll([
          _actionBtn(Icons.payment_rounded,
              _sw ? 'Pokea Malipo' : 'Record Payment', _showRecordPaymentSheet),
          _actionBtn(Icons.notifications_rounded,
              _sw ? 'Kumbuka' : 'Remind', _showReminderSheet),
        ]);
      case InvoiceStatus.paid:
        actions.addAll([
          _actionBtn(Icons.note_add_rounded,
              _sw ? 'Nota ya Mkopo' : 'Credit Note', _openCreditNotePage),
          _actionBtn(Icons.picture_as_pdf_rounded,
              _sw ? 'Pakua PDF' : 'Download PDF', _downloadPdf),
        ]);
      case InvoiceStatus.void_status:
      case InvoiceStatus.cancelled:
        actions.add(_actionBtn(Icons.picture_as_pdf_rounded,
            _sw ? 'Pakua PDF' : 'Download PDF', _downloadPdf));
      case InvoiceStatus.credit_noted:
        actions.add(_actionBtn(Icons.picture_as_pdf_rounded,
            _sw ? 'Pakua PDF' : 'Download PDF', _downloadPdf));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: actions
              .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
              .toList()
            ..removeLast(),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? _kPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: c.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: c),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
