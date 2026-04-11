// lib/rita/pages/fee_calculator_page.dart
import 'package:flutter/material.dart';
import '../models/rita_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FeeCalculatorPage extends StatefulWidget {
  const FeeCalculatorPage({super.key});
  @override
  State<FeeCalculatorPage> createState() => _FeeCalculatorPageState();
}

class _FeeCalculatorPageState extends State<FeeCalculatorPage> {
  CertificateType _type = CertificateType.birth;
  bool _lateRegistration = false;
  bool _express = false;

  double get _registrationFee {
    switch (_type) {
      case CertificateType.birth:
        return _lateRegistration ? 4000 : 3500;
      case CertificateType.death: return 3500;
      case CertificateType.marriage: return 10000;
    }
  }

  double get _processingFee => 500;
  double get _expressFee => _express ? 5000 : 0;
  double get _total => _registrationFee + _processingFee + _expressFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Hesabu Ada',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Aina ya Cheti', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: CertificateType.values.map((t) {
            final labels = {CertificateType.birth: 'Kuzaliwa', CertificateType.death: 'Kifo', CertificateType.marriage: 'Ndoa'};
            return ChoiceChip(
              label: Text(labels[t]!, style: TextStyle(fontSize: 12, color: _type == t ? Colors.white : _kPrimary)),
              selected: _type == t,
              onSelected: (_) => setState(() => _type = t),
              selectedColor: _kPrimary,
              backgroundColor: Colors.white,
            );
          }).toList()),
          const SizedBox(height: 16),
          if (_type == CertificateType.birth)
            SwitchListTile(
              title: const Text('Usajili wa kuchelewa', style: TextStyle(fontSize: 14, color: _kPrimary)),
              subtitle: const Text('Late registration (after 90 days)', style: TextStyle(fontSize: 12, color: _kSecondary)),
              value: _lateRegistration,
              onChanged: (v) => setState(() => _lateRegistration = v),
              activeColor: _kPrimary,
            ),
          SwitchListTile(
            title: const Text('Huduma ya haraka', style: TextStyle(fontSize: 14, color: _kPrimary)),
            subtitle: const Text('Express processing', style: TextStyle(fontSize: 12, color: _kSecondary)),
            value: _express,
            onChanged: (v) => setState(() => _express = v),
            activeColor: _kPrimary,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mgawanyo wa Ada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 12),
              _FeeRow(label: 'Ada ya usajili', amount: _registrationFee),
              const SizedBox(height: 6),
              _FeeRow(label: 'Ada ya usindikaji', amount: _processingFee),
              if (_express) ...[
                const SizedBox(height: 6),
                _FeeRow(label: 'Ada ya haraka', amount: _expressFee),
              ],
              const Divider(height: 20),
              _FeeRow(label: 'Jumla / Total', amount: _total, bold: true),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Ada zinaweza kubadilika. Tembelea ofisi ya RITA kwa bei halisi.',
                style: TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;
  const _FeeRow({required this.label, required this.amount, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: bold ? _kPrimary : _kSecondary)),
      Text('TZS ${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: _kPrimary)),
    ]);
  }
}
