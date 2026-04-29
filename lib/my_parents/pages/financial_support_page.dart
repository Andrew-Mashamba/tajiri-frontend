// lib/my_parents/pages/financial_support_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../services/expenditure_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import '../services/parents_notification_helper.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFEF5350);

class FinancialSupportPage extends StatefulWidget {
  final Parent parent;

  const FinancialSupportPage({super.key, required this.parent});

  @override
  State<FinancialSupportPage> createState() => _FinancialSupportPageState();
}

class _FinancialSupportPageState extends State<FinancialSupportPage> {
  final MyParentsService _service = MyParentsService();
  String? _token;
  bool _isLoading = true;
  List<FinancialSupport> _transactions = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getSupportHistory(_token!, widget.parent.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _transactions = result.items
            ..sort((a, b) => b.date.compareTo(a.date));
          // Schedule monthly support reminder
          _scheduleMonthlySupportReminder();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Imeshindikana kupakia malipo'
            : 'Failed to load transactions')),
      );
    }
  }

  /// Fire-and-forget: schedule monthly support reminder on 1st of each month.
  void _scheduleMonthlySupportReminder() {
    try {
      ParentsNotificationHelper.scheduleMonthlySupportReminder(
        widget.parent.id,
        widget.parent.name,
        _sw,
      );
    } catch (_) {}
  }

  double get _monthlyTotal {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _yearlyTotal {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String _typeLabel(String type, bool sw) {
    switch (type) {
      case 'monthly_support':
        return sw ? 'Msaada' : 'Support';
      case 'medical':
        return sw ? 'Matibabu' : 'Medical';
      case 'insurance':
        return sw ? 'Bima' : 'Insurance';
      default:
        return sw ? 'Nyingine' : 'Other';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'monthly_support':
        return const Color(0xFF4CAF50);
      case 'medical':
        return const Color(0xFFEF5350);
      case 'insurance':
        return const Color(0xFF42A5F5);
      default:
        return _kSecondary;
    }
  }

  String _paymentLabel(String? method, bool sw) {
    switch (method) {
      case 'mpesa':
        return 'M-Pesa';
      case 'bank':
        return sw ? 'Benki' : 'Bank';
      case 'cash':
        return sw ? 'Taslimu' : 'Cash';
      default:
        return method ?? '';
    }
  }

  void _showAddTransactionSheet({FinancialSupport? existing}) {
    final isEdit = existing != null;
    final amountCtrl = TextEditingController(
        text: isEdit ? existing.amount.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController(text: existing?.description ?? '');
    String type = existing?.type ?? 'monthly_support';
    String payment = existing?.paymentMethod ?? 'mpesa';
    DateTime selectedDate = existing?.date ?? DateTime.now();
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
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
                  isEdit
                      ? (sw ? 'Hariri Malipo' : 'Edit Payment')
                      : (sw ? 'Rekodi Malipo' : 'Log Payment'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: sw ? 'Kiasi (TSh)' : 'Amount (TSh)',
                    labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                    filled: true,
                    fillColor: _kPrimary.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 14, color: _kPrimary),
                ),
                const SizedBox(height: 12),
                // Type dropdown
                Text(sw ? 'Aina' : 'Type',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: type,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 'monthly_support',
                            child: Text(sw ? 'Msaada wa Kila Mwezi' : 'Monthly Support')),
                        DropdownMenuItem(value: 'medical',
                            child: Text(sw ? 'Matibabu' : 'Medical')),
                        DropdownMenuItem(value: 'insurance',
                            child: Text(sw ? 'Bima' : 'Insurance')),
                        DropdownMenuItem(value: 'other',
                            child: Text(sw ? 'Nyingine' : 'Other')),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheetState(() => type = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Payment method
                Text(sw ? 'Njia ya Malipo' : 'Payment Method',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: payment,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                        DropdownMenuItem(value: 'bank',
                            child: Text(sw ? 'Benki' : 'Bank')),
                        DropdownMenuItem(value: 'cash',
                            child: Text(sw ? 'Taslimu' : 'Cash')),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheetState(() => payment = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Text(
                          '${sw ? 'Tarehe: ' : 'Date: '}'
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 13, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: sw ? 'Maelezo' : 'Notes',
                    labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                    filled: true,
                    fillColor: _kPrimary.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 14, color: _kPrimary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(sw
                              ? 'Tafadhali ingiza kiasi sahihi'
                              : 'Please enter a valid amount')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      if (isEdit) {
                        _updateTransaction(
                          supportId: existing.id,
                          amount: amount,
                          type: type,
                          paymentMethod: payment,
                          date: selectedDate,
                          notes: notesCtrl.text.trim().isNotEmpty
                              ? notesCtrl.text.trim()
                              : null,
                        );
                      } else {
                        _saveTransaction(
                          amount: amount,
                          type: type,
                          paymentMethod: payment,
                          date: selectedDate,
                          notes: notesCtrl.text.trim().isNotEmpty
                              ? notesCtrl.text.trim()
                              : null,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                        isEdit
                            ? (sw ? 'Sasisha' : 'Update')
                            : (sw ? 'Hifadhi' : 'Save'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      amountCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  Future<void> _saveTransaction({
    required double amount,
    required String type,
    required String paymentMethod,
    required DateTime date,
    String? notes,
  }) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final result = await _service.logSupport(
        token: _token!,
        parentId: widget.parent.id,
        amount: amount,
        type: type,
        paymentMethod: paymentMethod,
        date: date,
        description: notes,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Malipo yamerekodiwa' : 'Payment recorded')),
        );
        // Fire-and-forget: record expenditure
        ExpenditureService.recordExpenditure(
          token: _token!,
          amount: amount,
          category: 'wazazi',
          description: '${_typeLabel(type, sw)} - ${widget.parent.name}',
          sourceModule: 'my_parents',
        );
        _loadTransactions();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _updateTransaction({
    required int supportId,
    required double amount,
    required String type,
    required String paymentMethod,
    required DateTime date,
    String? notes,
  }) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final result = await _service.updateSupport(
        token: _token!,
        supportId: supportId,
        amount: amount,
        type: type,
        paymentMethod: paymentMethod,
        date: date,
        description: notes,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Malipo yamesasishwa' : 'Payment updated')),
        );
        _loadTransactions();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kusasisha' : 'Failed to update'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _deleteTransaction(FinancialSupport tx) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa malipo?' : 'Delete payment?'),
        content: Text(sw
            ? 'Hatua hii haiwezi kutenduliwa.'
            : 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: _kDanger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await _service.deleteSupport(token: _token!, supportId: tx.id);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Malipo yamefutwa' : 'Payment deleted')),
        );
        _loadTransactions();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kufuta' : 'Failed to delete'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Msaada wa Kifedha' : 'Financial Support',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary card
                  _buildSummaryCard(sw),
                  const SizedBox(height: 16),

                  // Send to parent button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/wallet');
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        sw ? 'Tuma kwa Mzazi Sasa' : 'Send to Parent Now',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Monthly trend (last 6 months)
                  if (_transactions.isNotEmpty) ...[
                    _buildMonthlyTrend(sw),
                    const SizedBox(height: 20),
                  ],

                  // Transaction history
                  Text(
                    sw ? 'Historia ya Malipo' : 'Transaction History',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            sw ? 'Hakuna malipo' : 'No transactions yet',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._transactions.map((t) => _buildTransactionCard(t, sw)),
                  const SizedBox(height: 20),

                  // Cross-module links
                  _buildCrossModuleLink(
                    icon: Icons.account_balance_wallet_rounded,
                    label: sw
                        ? 'Tazama Bajeti ya Wazazi'
                        : 'View Parent Care Budget',
                    onTap: () {
                      Navigator.pushNamed(context, '/budget');
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildCrossModuleLink(
                    icon: Icons.smart_toy_rounded,
                    label: sw
                        ? 'Uliza Shangazi kuhusu bajeti ya kutunza mzazi'
                        : 'Ask Shangazi about parent care budgeting',
                    onTap: () {
                      Navigator.pushNamed(context, '/chat/0');
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            sw ? 'Mwezi Huu' : 'This Month',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            'TSh ${_formatAmount(_monthlyTotal)}',
            style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${sw ? 'Jumla ya mwaka: ' : 'Yearly total: '}TSh ${_formatAmount(_yearlyTotal)}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrend(bool sw) {
    final now = DateTime.now();
    final monthlyTotals = <double>[];
    final monthLabels = <String>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = _transactions
          .where((t) => t.date.year == month.year && t.date.month == month.month)
          .fold(0.0, (sum, t) => sum + t.amount);
      monthlyTotals.add(total);
      monthLabels.add(_monthAbbr(month.month));
    }

    final maxVal = monthlyTotals.isEmpty
        ? 1.0
        : monthlyTotals.reduce(math.max).clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sw ? 'Mwelekeo (Miezi 6)' : 'Monthly Trend (6 Months)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final h = (monthlyTotals[i] / maxVal) * 60;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (monthlyTotals[i] > 0)
                      Text(
                        _formatAmountShort(monthlyTotals[i]),
                        style: const TextStyle(fontSize: 8, color: _kSecondary),
                      ),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: math.max(h, 4),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: i == 5 ? 0.8 : 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(monthLabels[i],
                        style: const TextStyle(fontSize: 9, color: _kSecondary)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(FinancialSupport tx, bool sw) {
    final color = _typeColor(tx.type);
    return GestureDetector(
      onTap: () => _showAddTransactionSheet(existing: tx),
      onLongPress: () => _deleteTransaction(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                tx.type == 'medical'
                    ? Icons.medical_services_rounded
                    : tx.type == 'insurance'
                        ? Icons.health_and_safety_rounded
                        : Icons.payments_rounded,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel(tx.type, sw),
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                      if (tx.paymentMethod != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          _paymentLabel(tx.paymentMethod, sw),
                          style: const TextStyle(fontSize: 10, color: _kSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (tx.description != null && tx.description!.isNotEmpty)
                    Text(tx.description!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TSh ${_formatAmount(tx.amount)}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                Text(
                  '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                  style: const TextStyle(fontSize: 10, color: _kSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      final whole = amount.toInt();
      final thousands = whole ~/ 1000;
      final remainder = whole % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatAmountShort(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[((month - 1) % 12).clamp(0, 11)];
  }
}
