// lib/ewura/pages/tariff_calculator_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/ewura_models.dart';
import '../services/ewura_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TariffCalculatorPage extends StatefulWidget {
  const TariffCalculatorPage({super.key});
  @override
  State<TariffCalculatorPage> createState() => _TariffCalculatorPageState();
}

class _TariffCalculatorPageState extends State<TariffCalculatorPage> {
  List<UtilityTariff> _tariffs = [];
  bool _isLoading = true;
  bool _isSwahili = true;
  String _utilityType = 'electricity';
  final _unitsCtrl = TextEditingController();
  double? _calculatedCost;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadTariffs();
  }

  @override
  void dispose() {
    _unitsCtrl.dispose();
    super.dispose();
  }

  String _utilityLabel(String t) {
    if (_isSwahili) {
      switch (t) {
        case 'electricity': return 'Umeme';
        case 'water': return 'Maji';
        case 'gas': return 'Gesi';
        default: return t;
      }
    }
    return t[0].toUpperCase() + t.substring(1);
  }

  Future<void> _loadTariffs() async {
    setState(() => _isLoading = true);
    final r = await EwuraService.getTariffs(utilityType: _utilityType);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _tariffs = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili ? 'Imeshindwa kupakia tozo' : 'Failed to load tariffs')),
      ));
    }
  }

  void _calculate() {
    final units = double.tryParse(_unitsCtrl.text);
    if (units == null || _tariffs.isEmpty) return;
    final tariff = _tariffs.first;
    setState(() {
      _calculatedCost = units * tariff.ratePerUnit;
      if (tariff.minCharge != null && _calculatedCost! < tariff.minCharge!) {
        _calculatedCost = tariff.minCharge;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Kikokotoo cha Tozo' : 'Tariff Calculator',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label(_isSwahili ? 'Aina ya Huduma' : 'Utility Type'),
          DropdownButtonFormField<String>(
            value: _utilityType,
            decoration: _dec(''),
            items: ['electricity', 'water', 'gas']
                .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_utilityLabel(t))))
                .toList(),
            onChanged: (v) {
              setState(() {
                _utilityType = v ?? 'electricity';
                _calculatedCost = null;
              });
              _loadTariffs();
            },
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
          else if (_tariffs.isNotEmpty) ...[
            // Show current rate
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _tariffs
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t.category[0].toUpperCase() +
                                    t.category.substring(1),
                                style: const TextStyle(
                                    fontSize: 13, color: _kPrimary),
                              ),
                              Text(
                                'TZS ${t.ratePerUnit.toStringAsFixed(0)}/${t.unit}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            _label(_isSwahili ? 'Kiasi (units)' : 'Units consumed'),
            TextField(
              controller: _unitsCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec('100'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _calculate,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_isSwahili ? 'Kokotoa' : 'Calculate'),
            ),

            if (_calculatedCost != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _isSwahili ? 'Gharama Inakadiriwa' : 'Estimated Cost',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${_calculatedCost!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      );
}
