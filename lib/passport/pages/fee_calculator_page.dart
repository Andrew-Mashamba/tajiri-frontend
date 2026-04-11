// lib/passport/pages/fee_calculator_page.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PassportFeeCalcPage extends StatefulWidget {
  const PassportFeeCalcPage({super.key});
  @override
  State<PassportFeeCalcPage> createState() => _PassportFeeCalcPageState();
}

class _PassportFeeCalcPageState extends State<PassportFeeCalcPage> {
  int _pages = 32;
  int _validity = 5;
  bool _express = false;

  double get _baseFee {
    if (_pages == 32 && _validity == 5) return 150000;
    if (_pages == 64 && _validity == 5) return 200000;
    if (_pages == 32 && _validity == 10) return 200000;
    return 250000; // 64 pages, 10 years
  }

  double get _expressFee => _express ? 300000 : 0;
  double get _total => _baseFee + _expressFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Hesabu Ada ya Pasipoti',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Kurasa / Pages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        Row(children: [
          _Opt(label: '32 kurasa', selected: _pages == 32, onTap: () => setState(() => _pages = 32)),
          const SizedBox(width: 10),
          _Opt(label: '64 kurasa', selected: _pages == 64, onTap: () => setState(() => _pages = 64)),
        ]),
        const SizedBox(height: 16),
        const Text('Muda / Validity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        Row(children: [
          _Opt(label: 'Miaka 5', selected: _validity == 5, onTap: () => setState(() => _validity = 5)),
          const SizedBox(width: 10),
          _Opt(label: 'Miaka 10', selected: _validity == 10, onTap: () => setState(() => _validity = 10)),
        ]),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Huduma ya haraka / Express', style: TextStyle(fontSize: 14, color: _kPrimary)),
          value: _express, onChanged: (v) => setState(() => _express = v),
          activeColor: _kPrimary,
        ),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mgawanyo wa Ada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 12),
            _FeeRow(label: 'Ada ya pasipoti', amount: _baseFee),
            if (_express) ...[const SizedBox(height: 6), _FeeRow(label: 'Ada ya haraka', amount: _expressFee)],
            const Divider(height: 20),
            _FeeRow(label: 'Jumla', amount: _total, bold: true),
          ]),
        ),
      ]),
    );
  }
}

class _Opt extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _Opt({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: selected ? _kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? _kPrimary : const Color(0xFFE0E0E0))),
      child: Center(child: Text(label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _kPrimary))))));
}

class _FeeRow extends StatelessWidget {
  final String label; final double amount; final bool bold;
  const _FeeRow({required this.label, required this.amount, this.bold = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: bold ? _kPrimary : _kSecondary)),
    Text('TZS ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: _kPrimary)),
  ]);
}
