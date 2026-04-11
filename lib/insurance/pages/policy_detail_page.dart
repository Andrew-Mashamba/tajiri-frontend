// lib/insurance/pages/policy_detail_page.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';
import '../services/insurance_service.dart';
import 'submit_claim_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PolicyDetailPage extends StatelessWidget {
  final int userId;
  final InsurancePolicy policy;
  const PolicyDetailPage({super.key, required this.userId, required this.policy});

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg, elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Maelezo ya Bima', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(policy.category.icon, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text(policy.productName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: policy.status.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(policy.status.displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: policy.status.color)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(policy.providerName, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 12),
                Text('Bima: TZS ${_fmt(policy.coverLimit)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _Row(label: 'Namba ya Bima', value: policy.policyNumber),
                _Row(label: 'Malipo', value: 'TZS ${_fmt(policy.premiumAmount)}/${policy.premiumFrequency == 'monthly' ? 'mwezi' : 'mwaka'}'),
                _Row(label: 'Aina', value: policy.category.displayName),
                _Row(label: 'Kuanzia', value: _fmtDate(policy.startDate)),
                _Row(label: 'Hadi', value: _fmtDate(policy.endDate)),
                if (policy.nextPaymentDate != null) _Row(label: 'Malipo Yajayo', value: _fmtDate(policy.nextPaymentDate!)),
                if (policy.beneficiaryName != null) _Row(label: 'Mnufaika', value: policy.beneficiaryName!),
                if (policy.linkedModule != null) _Row(label: 'Imeunganishwa na', value: policy.linkedModule == 'loan' ? 'Mkopo wa TAJIRI Boost' : policy.linkedModule!),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (policy.isExpiringSoon) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Bima yako inaisha siku ${policy.daysRemaining}. Huisha tena ili uendelee kulindwa.', style: TextStyle(fontSize: 13, color: Colors.orange.shade700))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final phoneController = TextEditingController();
                  final phone = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Huisha Bima'),
                      content: TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Nambari ya M-Pesa')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, phoneController.text.trim()), child: const Text('Lipa')),
                      ],
                    ),
                  );
                  if (phone != null && phone.isNotEmpty && context.mounted) {
                    final result = await InsuranceService().renewPolicy(policyId: policy.id, paymentMethod: 'mobile_money', phoneNumber: phone);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.success ? 'Imehuishwa!' : (result.message ?? 'Imeshindwa'))));
                    }
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Huisha Bima Sasa'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          if (policy.isActive) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitClaimPage(userId: userId, policy: policy))),
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Dai Fidia'),
                      style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Ghairi Bima'),
                          content: const Text('Una uhakika unataka kughairi bima hii?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Ndiyo')),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        final result = await InsuranceService().cancelPolicy(policy.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.success ? 'Imeghairiwa' : (result.message ?? 'Imeshindwa'))));
                          if (result.success) Navigator.pop(context);
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Ghairi'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
