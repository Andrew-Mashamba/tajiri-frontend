// lib/tra/pages/tax_calculator_page.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TaxCalculatorPage extends StatefulWidget {
  const TaxCalculatorPage({super.key});
  @override
  State<TaxCalculatorPage> createState() => _TaxCalculatorPageState();
}

class _TaxCalculatorPageState extends State<TaxCalculatorPage> {
  String _taxType = 'PAYE';
  final _incomeCtrl = TextEditingController();
  double? _result;

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(_incomeCtrl.text.replaceAll(',', ''));
    if (income == null || income <= 0) return;

    double tax = 0;
    if (_taxType == 'PAYE') {
      // Tanzania PAYE tiers (simplified 2024 rates)
      if (income <= 270000) {
        tax = 0;
      } else if (income <= 520000) {
        tax = (income - 270000) * 0.08;
      } else if (income <= 760000) {
        tax = 20000 + (income - 520000) * 0.20;
      } else if (income <= 1000000) {
        tax = 68000 + (income - 760000) * 0.25;
      } else {
        tax = 128000 + (income - 1000000) * 0.30;
      }
    } else if (_taxType == 'VAT') {
      tax = income * 0.18;
    } else if (_taxType == 'Corporate') {
      tax = income * 0.30;
    } else if (_taxType == 'Presumptive') {
      if (income <= 4000000) {
        tax = 0;
      } else if (income <= 7000000) {
        tax = income * 0.01;
      } else if (income <= 11000000) {
        tax = income * 0.02;
      } else {
        tax = income * 0.03;
      }
    }

    setState(() => _result = tax);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Hesabu Kodi',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Aina ya Kodi / Tax Type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: ['PAYE', 'VAT', 'Corporate', 'Presumptive'].map((t) {
            return ChoiceChip(
              label: Text(t, style: TextStyle(fontSize: 12,
                  color: _taxType == t ? Colors.white : _kPrimary)),
              selected: _taxType == t,
              onSelected: (_) => setState(() { _taxType = t; _result = null; }),
              selectedColor: _kPrimary,
              backgroundColor: Colors.white,
            );
          }).toList()),
          const SizedBox(height: 16),
          TextField(
            controller: _incomeCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: _taxType == 'PAYE' ? 'Mshahara wa mwezi (TZS)' : 'Kiasi (TZS)',
              hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
              prefixText: 'TZS ',
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 14, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 48, width: double.infinity, child: ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hesabu / Calculate', style: TextStyle(color: Colors.white)),
          )),
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Matokeo / Result',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 12),
                _Row(label: 'Aina', value: _taxType),
                const SizedBox(height: 6),
                _Row(label: 'Kiasi cha kodi', value: 'TZS ${_result!.toStringAsFixed(0)}'),
                if (_taxType == 'PAYE') ...[
                  const SizedBox(height: 6),
                  _Row(label: 'Kima baada ya kodi',
                      value: 'TZS ${((double.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0) - _result!).toStringAsFixed(0)}'),
                ],
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, size: 18, color: _kSecondary),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Hii ni makisio tu. Wasiliana na mshauri wa kodi kwa hesabu halisi.',
                style: TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
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
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
    ]);
  }
}
