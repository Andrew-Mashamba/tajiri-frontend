// lib/loans/pages/loan_detail_page.dart
import 'package:flutter/material.dart';
import '../../widgets/budget_context_banner.dart';
import '../models/loan_models.dart';
import '../services/loan_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class LoanDetailPage extends StatefulWidget {
  final int userId;
  final BoostLoan loan;
  const LoanDetailPage({super.key, required this.userId, required this.loan});
  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  final BoostLoanService _service = BoostLoanService();
  late BoostLoan _loan;
  List<LoanRepaymentEvent> _repayments = [];
  bool _isLoadingRepayments = true;

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
    _loadRepayments();
  }

  Future<void> _loadRepayments() async {
    setState(() => _isLoadingRepayments = true);
    final result = await _service.getRepaymentHistory(_loan.id);
    if (mounted) {
      setState(() {
        _isLoadingRepayments = false;
        if (result.success) _repayments = result.items;
      });
    }
  }

  Future<void> _refresh() async {
    final result = await _service.getLoanDetail(_loan.id);
    if (mounted && result.success && result.data != null) {
      setState(() => _loan = result.data!);
    }
    await _loadRepayments();
  }

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showManualRepaySheet() {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                  const Text('Lipa Mkopo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Text('Baki: TZS ${_fmt(_loan.remainingAmount)}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kiasi (TZS)',
                      filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nambari ya M-Pesa',
                      hintText: '0712 345 678',
                      filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  BudgetContextBanner(
                    category: 'michango',
                    paymentAmount: double.tryParse(amountController.text.trim()) ?? 0,
                    isSwahili: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : () async {
                        final amount = double.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0) return;
                        setSheetState(() => isSubmitting = true);
                        final result = await _service.makeManualRepayment(
                          loanId: _loan.id,
                          amount: amount,
                          paymentMethod: 'mobile_money',
                          phoneNumber: phoneController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(
                              result.success ? 'Malipo yametumwa!' : (result.message ?? 'Imeshindwa'),
                            )),
                          );
                          if (result.success) _refresh();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Lipa Sasa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Future<void> _requestPause() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simamisha Mkopo'),
        content: const Text('Unataka kusimamisha makato kwa siku 30? Unaweza kufanya hivi mara moja tu kwa kila mkopo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Ndiyo, Simamisha'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _service.requestPause(_loan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.success ? 'Mkopo umesimamishwa kwa siku 30' : (result.message ?? 'Imeshindwa'))),
        );
        if (result.success) _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: Text('Mkopo: ${_loan.tier.displayName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status + progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_loan.loanId, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _loan.status.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _loan.status.displayName,
                          style: TextStyle(color: _loan.status.color, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TZS ${_fmt(_loan.remainingAmount)}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const Text('baki ya kulipa', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_loan.repaidPercent / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(_loan.tier.color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Umelipa: TZS ${_fmt(_loan.amountRepaid)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('${_loan.repaidPercent.toStringAsFixed(0)}%', style: TextStyle(color: _loan.tier.color, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _DetailRow(label: 'Mkopo', value: 'TZS ${_fmt(_loan.principalAmount)}'),
                  _DetailRow(label: 'Ada', value: 'TZS ${_fmt(_loan.feeAmount)}'),
                  _DetailRow(label: 'Jumla ya Kulipa', value: 'TZS ${_fmt(_loan.totalRepayable)}', isBold: true),
                  _DetailRow(label: 'Makato', value: '${_loan.repaymentPercent.toStringAsFixed(0)}% ya mapato'),
                  _DetailRow(label: 'Tarehe ya Maombi', value: _formatDate(_loan.applicationDate)),
                  if (_loan.disbursementDate != null)
                    _DetailRow(label: 'Tarehe ya Kutolewa', value: _formatDate(_loan.disbursementDate!)),
                  if (_loan.dueDate != null)
                    _DetailRow(label: 'Tarehe ya Mwisho', value: _formatDate(_loan.dueDate!)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            if (_loan.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _showManualRepaySheet,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Lipa Mkopo'),
                      ),
                    ),
                  ),
                  if (_loan.canRequestPause) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _requestPause,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simamisha'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Repayment history
            const Text(
              'Historia ya Malipo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 10),

            if (_isLoadingRepayments)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              ))
            else if (_repayments.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text('Hakuna malipo bado', style: TextStyle(color: Colors.grey.shade500)),
                ),
              )
            else
              ...List.generate(_repayments.length, (i) {
                final r = _repayments[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_rounded, size: 18, color: Color(0xFF4CAF50)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.earningTypeLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                            Text(_formatDate(r.date), style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        'TZS ${_fmt(r.amount)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  const _DetailRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isBold ? _kPrimary : _kSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: _kPrimary)),
        ],
      ),
    );
  }
}
