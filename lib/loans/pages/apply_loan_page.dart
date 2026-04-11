// lib/loans/pages/apply_loan_page.dart
import 'package:flutter/material.dart';
import '../models/loan_models.dart';
import '../services/loan_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ApplyLoanPage extends StatefulWidget {
  final int userId;
  final LoanTier tier;
  final CreatorCreditScore creditScore;
  final double maxAmount;

  const ApplyLoanPage({
    super.key,
    required this.userId,
    required this.tier,
    required this.creditScore,
    required this.maxAmount,
  });

  @override
  State<ApplyLoanPage> createState() => _ApplyLoanPageState();
}

class _ApplyLoanPageState extends State<ApplyLoanPage> {
  final BoostLoanService _service = BoostLoanService();
  late double _selectedAmount;
  bool _isSubmitting = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.maxAmount;
  }

  double get _fee => _selectedAmount * (widget.tier.feePercent / 100);
  double get _totalRepayable => _selectedAmount + _fee;

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali kubali masharti ya mkopo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _service.applyForLoan(
      userId: widget.userId,
      tier: widget.tier,
      amount: _selectedAmount,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ombi la mkopo limetumwa! Pesa zitaingia kwenye pochi yako.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Imeshindwa kuomba mkopo'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: Text(
          'Omba ${tier.displayName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tier info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tier.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(tier.icon, size: 32, color: tier.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAJIRI Boost — ${tier.displayName}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tier.color),
                      ),
                      Text(
                        'Ada: ${tier.feePercent.toStringAsFixed(0)}% • Makato: ${tier.repaymentPercent.toStringAsFixed(0)}% ya mapato • Muda: ${tier.termDays} siku',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount slider
          const Text(
            'Chagua Kiasi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'TZS ${_fmt(_selectedAmount)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _kPrimary),
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: tier.color,
              thumbColor: tier.color,
              inactiveTrackColor: tier.color.withValues(alpha: 0.15),
              overlayColor: tier.color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _selectedAmount,
              min: tier.minAmount,
              max: widget.maxAmount,
              divisions: ((widget.maxAmount - tier.minAmount) / 5000).round().clamp(1, 1000),
              onChanged: (v) => setState(() => _selectedAmount = (v / 1000).round() * 1000),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TZS ${_fmt(tier.minAmount)}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
              Text('TZS ${_fmt(widget.maxAmount)}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ],
          ),
          const SizedBox(height: 24),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Mkopo', value: 'TZS ${_fmt(_selectedAmount)}'),
                const Divider(height: 20),
                _SummaryRow(label: 'Ada (${tier.feePercent.toStringAsFixed(0)}%)', value: 'TZS ${_fmt(_fee)}'),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Jumla ya Kulipa',
                  value: 'TZS ${_fmt(_totalRepayable)}',
                  isBold: true,
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Makato ya Mapato',
                  value: '${tier.repaymentPercent.toStringAsFixed(0)}% ya kila kipato',
                ),
                const Divider(height: 20),
                _SummaryRow(label: 'Muda wa Neema', value: '14 siku'),
                const Divider(height: 20),
                _SummaryRow(label: 'Muda wa Mkopo', value: '${tier.termDays} siku'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // How it works
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jinsi Inavyofanya Kazi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                const SizedBox(height: 12),
                _StepItem(number: '1', text: 'Pesa itaingia kwenye Pochi yako ya Tajiri'),
                _StepItem(number: '2', text: 'Siku 14 za neema — hakuna makato'),
                _StepItem(number: '3', text: '${tier.repaymentPercent.toStringAsFixed(0)}% ya kila kipato kitakatwa moja kwa moja'),
                _StepItem(number: '4', text: 'Mapato yakipungua, makato yanapungua pia'),
                _StepItem(number: '5', text: 'Mkopo unakamilika baada ya kulipa TZS ${_fmt(_totalRepayable)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  activeColor: _kPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ninakubali masharti ya mkopo wa TAJIRI Boost, ikiwemo makato ya moja kwa moja kutoka mapato yangu.',
                  style: TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: (_isSubmitting || !_agreedToTerms) ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: tier.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Omba Mkopo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isBold ? _kPrimary : _kSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: _kPrimary,
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _kSecondary))),
        ],
      ),
    );
  }
}
