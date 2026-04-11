// lib/tanesco/pages/buy_tokens_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';
import '../widgets/token_display.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BuyTokensPage extends StatefulWidget {
  final Meter meter;
  const BuyTokensPage({super.key, required this.meter});
  @override
  State<BuyTokensPage> createState() => _BuyTokensPageState();
}

class _BuyTokensPageState extends State<BuyTokensPage> {
  final _amountCtrl = TextEditingController();
  String _method = 'mpesa';
  bool _buying = false;
  TokenPurchase? _result;

  // Token history
  List<TokenPurchase> _history = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final result = await TanescoService.getTokenHistory(widget.meter.meterNumber);
    if (!mounted) return;
    setState(() {
      _loadingHistory = false;
      if (result.success) _history = result.items;
    });
  }

  Future<void> _buy() async {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSwahili ? 'Kiwango cha chini ni TZS 1,000' : 'Minimum amount is TZS 1,000')));
      return;
    }
    setState(() => _buying = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await TanescoService.buyTokens(widget.meter.meterNumber, amount, _method);
      if (!mounted) return;
      setState(() { _buying = false; if (result.success) _result = result.data; });
      if (!result.success) {
        messenger.showSnackBar(
            SnackBar(content: Text(result.message ?? (isSwahili ? 'Imeshindwa kununua' : 'Purchase failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _buying = false);
      messenger.showSnackBar(
          SnackBar(content: Text(isSwahili ? 'Imeshindwa kununua' : 'Purchase failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: Text(isSwahili ? 'Nunua LUKU' : 'Buy Tokens',
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Meter info
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            const Icon(Icons.speed_rounded, size: 20, color: _kPrimary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.meter.alias ?? (isSwahili ? 'Mita' : 'Meter'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(widget.meter.meterNumber, style: const TextStyle(fontSize: 12, color: _kSecondary)),
            ])),
            Text('${widget.meter.balance.toStringAsFixed(1)} kWh',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          ])),
        const SizedBox(height: 16),

        if (_result == null) ...[
          Text(isSwahili ? 'Kiasi' : 'Amount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Min TZS 1,000', prefixText: 'TZS ',
              hintStyle: const TextStyle(color: _kSecondary),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [5000, 10000, 20000, 50000].map((a) =>
            ActionChip(label: Text('${(a / 1000).toInt()}K',
                style: const TextStyle(fontSize: 12, color: _kPrimary)),
              backgroundColor: Colors.white,
              onPressed: () => _amountCtrl.text = '$a')).toList()),
          const SizedBox(height: 16),
          Text(isSwahili ? 'Njia ya Malipo' : 'Payment Method', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          ...['mpesa', 'tigopesa', 'airtelmoney'].map((m) {
            final labels = {'mpesa': 'M-Pesa', 'tigopesa': 'Tigo Pesa', 'airtelmoney': 'Airtel Money'};
            return RadioListTile<String>(title: Text(labels[m]!, style: const TextStyle(fontSize: 14, color: _kPrimary)),
              value: m, groupValue: _method, onChanged: (v) => setState(() => _method = v!),
              activeColor: _kPrimary, contentPadding: EdgeInsets.zero);
          }),
          const SizedBox(height: 20),
          SizedBox(height: 48, width: double.infinity, child: ElevatedButton(
            onPressed: _buying ? null : _buy,
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _buying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isSwahili ? 'Nunua Sasa' : 'Buy Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),

          // Recent purchases
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(isSwahili ? 'Manunuzi ya Hivi Karibuni' : 'Recent Purchases', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            ..._history.take(5).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                const Icon(Icons.receipt_long_rounded, size: 16, color: _kSecondary),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TZS ${p.amount.toStringAsFixed(0)} - ${p.units.toStringAsFixed(1)} kWh',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${p.purchasedAt.day}/${p.purchasedAt.month}/${p.purchasedAt.year}',
                      style: const TextStyle(fontSize: 10, color: _kSecondary)),
                ])),
                if (p.token != null)
                  Text(p.token!.length > 8 ? '...${p.token!.substring(p.token!.length - 8)}' : p.token!,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: _kPrimary)),
              ]),
            )),
          ],
          if (_loadingHistory)
            const Padding(padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
        ] else ...[
          // Success - show TokenDisplay
          TokenDisplay(
            token: _result!.token ?? '',
            units: _result!.units,
            amount: _result!.amount,
            meterNumber: _result!.meterNumber,
            selcomReference: _result!.selcomReference,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: SizedBox(height: 48, child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(isSwahili ? 'Rudi' : 'Back', style: const TextStyle(color: _kPrimary)))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(height: 48, child: ElevatedButton(
                onPressed: () => setState(() { _result = null; _amountCtrl.clear(); }),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(isSwahili ? 'Nunua Tena' : 'Buy Again', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
            ),
          ]),
        ],
        const SizedBox(height: 32),
      ]),
    );
  }
}
