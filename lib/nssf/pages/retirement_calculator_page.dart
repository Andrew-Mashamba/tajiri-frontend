// lib/nssf/pages/retirement_calculator_page.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RetirementCalculatorPage extends StatefulWidget {
  const RetirementCalculatorPage({super.key});
  @override
  State<RetirementCalculatorPage> createState() => _RetirementCalculatorPageState();
}

class _RetirementCalculatorPageState extends State<RetirementCalculatorPage> {
  double _age = 30;
  double _salary = 1000000;
  double _retirementAge = 60;

  double get _yearsLeft => _retirementAge - _age;
  double get _monthlyContrib => _salary * 0.20;
  double get _totalProjected => _monthlyContrib * 12 * _yearsLeft;
  double get _monthlyPension => _totalProjected > 0 ? (_totalProjected / (12 * 15)) : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Hesabu Pensheni',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _SliderField(label: 'Umri wako / Your age', value: _age, min: 18, max: 59, suffix: ' miaka',
            onChanged: (v) => setState(() => _age = v)),
        const SizedBox(height: 16),
        _SliderField(label: 'Mshahara wa mwezi / Monthly salary', value: _salary,
            min: 200000, max: 10000000, suffix: ' TZS', divisions: 98,
            onChanged: (v) => setState(() => _salary = v)),
        const SizedBox(height: 16),
        _SliderField(label: 'Umri wa kustaafu / Retirement age', value: _retirementAge,
            min: 55, max: 65, suffix: ' miaka',
            onChanged: (v) => setState(() => _retirementAge = v)),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Makisio / Projection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 12),
            _PRow(label: 'Michango ya kila mwezi', value: 'TZS ${_monthlyContrib.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            _PRow(label: 'Miaka ya kuchangia', value: '${_yearsLeft.toInt()} miaka'),
            const SizedBox(height: 8),
            _PRow(label: 'Jumla ya michango', value: 'TZS ${(_totalProjected / 1000000).toStringAsFixed(1)}M'),
            const Divider(height: 20),
            _PRow(label: 'Pensheni ya kila mwezi (est.)', value: 'TZS ${_monthlyPension.toStringAsFixed(0)}', bold: true),
          ])),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Hii ni makisio tu. Pensheni halisi hutegemea mambo mengi.',
                style: TextStyle(fontSize: 12, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ])),
      ]),
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label; final double value; final double min; final double max;
  final String suffix; final int? divisions; final ValueChanged<double> onChanged;
  const _SliderField({required this.label, required this.value, required this.min,
    required this.max, required this.suffix, this.divisions, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
      Text('${value.toInt()}$suffix', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
    ]),
    Slider(value: value, min: min, max: max, divisions: divisions ?? (max - min).toInt(),
      onChanged: onChanged, activeColor: _kPrimary, inactiveColor: const Color(0xFFE0E0E0)),
  ]);
}

class _PRow extends StatelessWidget {
  final String label; final String value; final bool bold;
  const _PRow({required this.label, required this.value, this.bold = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 13, color: bold ? _kPrimary : _kSecondary,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
    Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: _kPrimary)),
  ]);
}
