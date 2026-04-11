// lib/buy_car/pages/import_calculator_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/buy_car_models.dart';
import '../services/buy_car_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ImportCalculatorPage extends StatefulWidget {
  const ImportCalculatorPage({super.key});
  @override
  State<ImportCalculatorPage> createState() => _ImportCalculatorPageState();
}

class _ImportCalculatorPageState extends State<ImportCalculatorPage> {
  final _cifCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _currency = 'USD';
  ImportCost? _result;
  bool _isLoading = false;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _cifCtrl.dispose();
    _engineCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final cif = double.tryParse(_cifCtrl.text.trim());
    final engine = int.tryParse(_engineCtrl.text.trim());
    final age = int.tryParse(_ageCtrl.text.trim());
    if (cif == null || engine == null || age == null) return;
    setState(() => _isLoading = true);
    final r = await BuyCarService.calculateImportCost(
      cifPrice: cif,
      cifCurrency: _currency,
      engineCc: engine,
      vehicleAge: age,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _result = r.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
            _isSwahili ? 'Hesabu Ushuru wa Kuagiza' : 'Import Calculator',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
              _isSwahili
                  ? 'Hesabu gharama za kuagiza gari kutoka Japan au Dubai'
                  : 'Calculate costs to import a car from Japan or Dubai',
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 16),
          _field(_cifCtrl, 'CIF Price', '15000',
              keyboard: TextInputType.number),
          Row(children: [
            Expanded(
                child: _field(
                    _engineCtrl, _isSwahili ? 'Injini (cc)' : 'Engine (cc)',
                    '2500',
                    keyboard: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(
                child: _field(_ageCtrl,
                    _isSwahili ? 'Umri (miaka)' : 'Age (years)', '5',
                    keyboard: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          Text(_isSwahili ? 'Fedha' : 'Currency',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 6),
          Row(children: [
            _currencyChip('USD'),
            const SizedBox(width: 8),
            _currencyChip('JPY'),
            const SizedBox(width: 8),
            _currencyChip('AED'),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _calculate,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isSwahili ? 'Hesabu' : 'Calculate',
                      style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),

          if (_result != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isSwahili ? 'Matokeo' : 'Breakdown',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const Divider(height: 20),
                    _costRow('CIF Price',
                        'TZS ${_result!.cifPrice.toStringAsFixed(0)}'),
                    _costRow(
                        _isSwahili ? 'Ushuru wa Forodha (25%)' : 'Import Duty (25%)',
                        'TZS ${_result!.importDuty.toStringAsFixed(0)}'),
                    _costRow(
                        _isSwahili ? 'Excise Duty' : 'Excise Duty',
                        'TZS ${_result!.exciseDuty.toStringAsFixed(0)}'),
                    _costRow('VAT (18%)',
                        'TZS ${_result!.vat.toStringAsFixed(0)}'),
                    _costRow(
                        _isSwahili ? 'Ada Nyingine' : 'Other Fees',
                        'TZS ${_result!.otherFees.toStringAsFixed(0)}'),
                    const Divider(height: 20),
                    _costRow(
                        _isSwahili
                            ? 'JUMLA YOTE'
                            : 'TOTAL LANDED COST',
                        'TZS ${_result!.totalLandedCost.toStringAsFixed(0)}',
                        bold: true),
                  ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _currencyChip(String value) {
    final selected = _currency == value;
    return ChoiceChip(
      label: Text(value,
          style: TextStyle(
              fontSize: 12, color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => setState(() => _currency = value),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _kPrimary : Colors.grey.shade300),
    );
  }

  Widget _costRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: bold ? _kPrimary : _kSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: _kPrimary)),
      ]),
    );
  }
}
