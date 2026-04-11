// lib/insurance/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';
import '../services/insurance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProductDetailPage extends StatefulWidget {
  final int userId;
  final InsuranceProduct product;
  const ProductDetailPage({super.key, required this.userId, required this.product});
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final InsuranceService _service = InsuranceService();
  final _phoneController = TextEditingController();
  final _beneficiaryController = TextEditingController();
  String _frequency = 'monthly';
  bool _isPurchasing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _beneficiaryController.dispose();
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

  double get _displayPremium => _frequency == 'annual' && widget.product.premiumAnnual != null
      ? widget.product.premiumAnnual!
      : widget.product.premiumMonthly;

  Future<void> _purchase() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingiza nambari ya M-Pesa')));
      return;
    }
    setState(() => _isPurchasing = true);

    final result = await _service.purchasePolicy(
      userId: widget.userId,
      productId: widget.product.id,
      premiumFrequency: _frequency,
      beneficiaryName: _beneficiaryController.text.trim().isNotEmpty ? _beneficiaryController.text.trim() : null,
      paymentMethod: 'mobile_money',
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bima imeagizwa! Thibitisha malipo kwenye simu yako.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
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
          // Product header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(p.category.icon, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(p.providerName, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Malipo', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('TZS ${_fmt(p.premiumMonthly)}/mwezi', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bima', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('TZS ${_fmt(p.coverLimit)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Benefits
          if (p.benefits.isNotEmpty) ...[
            const Text('Faida', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: p.benefits.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(b, style: const TextStyle(fontSize: 13, color: _kPrimary))),
                        ],
                      ),
                    )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Exclusions
          if (p.exclusions.isNotEmpty) ...[
            const Text('Haijumuishi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: p.exclusions.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e, style: const TextStyle(fontSize: 13, color: _kSecondary))),
                        ],
                      ),
                    )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Details
          if (p.waitingPeriodDays != null || p.description != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.waitingPeriodDays != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_empty_rounded, size: 16, color: _kSecondary),
                          const SizedBox(width: 8),
                          Text('Muda wa kusubiri: ${p.waitingPeriodDays} siku', style: const TextStyle(fontSize: 13, color: _kPrimary)),
                        ],
                      ),
                    ),
                  if (p.description != null)
                    Text(p.description!, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.5)),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Purchase section
          const Text('Nunua Bima', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 10),

          // Frequency toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _frequency = 'monthly'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _frequency == 'monthly' ? _kPrimary : _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _frequency == 'monthly' ? _kPrimary : const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Text('Kwa Mwezi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _frequency == 'monthly' ? Colors.white : _kPrimary)),
                        Text('TZS ${_fmt(p.premiumMonthly)}', style: TextStyle(fontSize: 12, color: _frequency == 'monthly' ? Colors.white70 : _kSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              if (p.premiumAnnual != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _frequency = 'annual'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _frequency == 'annual' ? _kPrimary : _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _frequency == 'annual' ? _kPrimary : const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        children: [
                          Text('Kwa Mwaka', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _frequency == 'annual' ? Colors.white : _kPrimary)),
                          Text('TZS ${_fmt(p.premiumAnnual!)}', style: TextStyle(fontSize: 12, color: _frequency == 'annual' ? Colors.white70 : _kSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Beneficiary
          TextField(
            controller: _beneficiaryController,
            decoration: InputDecoration(
              labelText: 'Mrithi / Mnufaika (Hiari)',
              hintText: 'Jina la mnufaika',
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 12),

          // Phone
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nambari ya M-Pesa',
              hintText: '0712 345 678',
              prefixIcon: const Icon(Icons.phone_outlined, color: _kSecondary),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isPurchasing ? null : _purchase,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isPurchasing
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Nunua — TZS ${_fmt(_displayPremium)}/${_frequency == 'monthly' ? 'mwezi' : 'mwaka'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
