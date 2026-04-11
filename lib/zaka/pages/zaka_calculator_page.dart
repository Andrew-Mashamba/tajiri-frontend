// lib/zaka/pages/zaka_calculator_page.dart
import 'package:flutter/material.dart';
import '../models/zaka_models.dart';
import '../services/zaka_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ZakaCalculatorPage extends StatefulWidget {
  final int userId;
  const ZakaCalculatorPage({super.key, required this.userId});

  @override
  State<ZakaCalculatorPage> createState() => _ZakaCalculatorPageState();
}

class _ZakaCalculatorPageState extends State<ZakaCalculatorPage> {
  final _service = ZakaService();
  final _controllers = <AssetCategory, TextEditingController>{};
  final _debtsController = TextEditingController();
  ZakatCalculation? _result;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    for (final cat in AssetCategory.values) {
      _controllers[cat] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _debtsController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    setState(() => _calculating = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken() ?? '';

    final assets = <AssetEntry>[];
    for (final cat in AssetCategory.values) {
      final amount = double.tryParse(_controllers[cat]!.text) ?? 0;
      if (amount > 0) {
        assets.add(AssetEntry(category: cat, amount: amount));
      }
    }
    final debts = double.tryParse(_debtsController.text) ?? 0;

    final result = await _service.calculate(
      token: token, assets: assets, totalDebts: debts,
    );

    if (mounted) {
      setState(() {
        _result = result.data;
        _calculating = false;
      });
    }
  }

  String _formatTZS(double amount) {
    return '${amount.toStringAsFixed(0)} TZS';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Hesabu Zaka',
            style: TextStyle(color: _kPrimary, fontSize: 18,
                fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Mali Zako',
                style: TextStyle(color: _kPrimary, fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Asset inputs
            ...AssetCategory.values.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _controllers[cat],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: cat.label,
                  labelStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                  hintText: '0',
                  suffixText: 'TZS',
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
            )),

            const SizedBox(height: 16),
            const Text('Madeni',
                style: TextStyle(color: _kPrimary, fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _debtsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumla ya Madeni',
                labelStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                hintText: '0', suffixText: 'TZS',
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 20),

            // Calculate button
            SizedBox(
              width: double.infinity, height: 48,
              child: FilledButton(
                onPressed: _calculating ? null : _calculate,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: _calculating
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Hesabu'),
              ),
            ),
            const SizedBox(height: 24),

            // Result
            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _result!.aboveNisab ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: _result!.aboveNisab
                      ? null
                      : Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      _result!.aboveNisab
                          ? 'Zaka Yako Inapaswa'
                          : 'Chini ya Nisab',
                      style: TextStyle(
                        color: _result!.aboveNisab
                            ? Colors.white70
                            : _kSecondary,
                        fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTZS(_result!.zakatDue),
                      style: TextStyle(
                        color: _result!.aboveNisab
                            ? Colors.white
                            : _kPrimary,
                        fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _summaryRow('Jumla ya Mali',
                        _formatTZS(_result!.totalAssets),
                        _result!.aboveNisab),
                    _summaryRow('Madeni',
                        '- ${_formatTZS(_result!.totalDebts)}',
                        _result!.aboveNisab),
                    _summaryRow('Utajiri Halisi',
                        _formatTZS(_result!.netWealth),
                        _result!.aboveNisab),
                    _summaryRow('Nisab',
                        _formatTZS(_result!.nisabThreshold),
                        _result!.aboveNisab),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              color: dark ? Colors.white54 : _kSecondary, fontSize: 13)),
          Text(value, style: TextStyle(
              color: dark ? Colors.white70 : _kPrimary, fontSize: 13,
              fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
