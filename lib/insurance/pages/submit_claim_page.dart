// lib/insurance/pages/submit_claim_page.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';
import '../services/insurance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SubmitClaimPage extends StatefulWidget {
  final int userId;
  final InsurancePolicy policy;
  const SubmitClaimPage({super.key, required this.userId, required this.policy});
  @override
  State<SubmitClaimPage> createState() => _SubmitClaimPageState();
}

class _SubmitClaimPageState extends State<SubmitClaimPage> {
  final InsuranceService _service = InsuranceService();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingiza kiasi sahihi')));
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingiza sababu ya dai')));
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await _service.submitClaim(
      policyId: widget.policy.id,
      amount: amount,
      reason: _reasonController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dai limetumwa! Litakaguliwa ndani ya siku 5-7.')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa'), backgroundColor: Colors.red.shade700));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg, elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Dai Fidia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Policy info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(widget.policy.category.icon, size: 24, color: _kPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.policy.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                      Text('${widget.policy.providerName} • ${widget.policy.policyNumber}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    ],
                  ),
                ),
                Text('Bima: TZS ${_fmt(widget.policy.coverLimit)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Amount
          const Text('Kiasi cha Dai (TZS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0', hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 20),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Reason
          const Text('Sababu ya Dai *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'Mfano: Kulazwa hospitali, ajali ya gari...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          const Text('Maelezo Zaidi (Hiari)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Eleza kwa ufupi kilichotokea...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dai litakaguliwa ndani ya siku 5-7 za kazi. Unaweza kuombwa nyaraka za ziada.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tuma Dai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
