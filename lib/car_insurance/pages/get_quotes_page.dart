// lib/car_insurance/pages/get_quotes_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/car_insurance_models.dart';
import '../services/car_insurance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class GetQuotesPage extends StatefulWidget {
  const GetQuotesPage({super.key});
  @override
  State<GetQuotesPage> createState() => _GetQuotesPageState();
}

class _GetQuotesPageState extends State<GetQuotesPage> {
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String _coverageType = 'comprehensive';
  List<InsuranceQuote> _quotes = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_makeCtrl.text.isEmpty || _modelCtrl.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    final result = await CarInsuranceService.getQuotes(
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
      coverageType: _coverageType,
      vehicleValue: double.tryParse(_valueCtrl.text.trim()),
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _quotes = result.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Pata Bei' : 'Get Quotes',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle info inputs
          _field(_makeCtrl, _isSwahili ? 'Aina (Make)' : 'Make', 'Toyota'),
          _field(_modelCtrl, _isSwahili ? 'Modeli' : 'Model', 'Land Cruiser'),
          _field(_yearCtrl, _isSwahili ? 'Mwaka' : 'Year', '2018',
              keyboard: TextInputType.number),
          _field(_valueCtrl,
              _isSwahili ? 'Thamani (TZS)' : 'Vehicle Value (TZS)', '35000000',
              keyboard: TextInputType.number),
          const SizedBox(height: 8),
          Text(_isSwahili ? 'Aina ya Bima' : 'Coverage Type',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            _chip('tpo', 'TPO'),
            _chip('tpft', 'TPFT'),
            _chip('comprehensive',
                _isSwahili ? 'Kamili' : 'Comprehensive'),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _search,
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
                  : Text(_isSwahili ? 'Tafuta Bei' : 'Get Quotes',
                      style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),

          if (_hasSearched && !_isLoading) ...[
            Text(
                _isSwahili
                    ? 'Bei Zilizopatikana (${_quotes.length})'
                    : 'Quotes Found (${_quotes.length})',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            if (_quotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                      _isSwahili
                          ? 'Hakuna bei zilizopatikana'
                          : 'No quotes found',
                      style:
                          const TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              )
            else
              ..._quotes.map(_quoteTile),
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

  Widget _chip(String value, String label) {
    final selected = _coverageType == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12, color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => setState(() => _coverageType = value),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _kPrimary : Colors.grey.shade300),
    );
  }

  Widget _quoteTile(InsuranceQuote q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (q.providerLogo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(q.providerLogo!,
                  width: 36, height: 36, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.shield_rounded, size: 36, color: _kPrimary)),
            )
          else
            const Icon(Icons.shield_rounded, size: 36, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.providerName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(q.coverageLabel,
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary)),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('TZS ${q.premium.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            Text(_isSwahili ? '/mwaka' : '/year',
                style: const TextStyle(fontSize: 10, color: _kSecondary)),
          ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _infoChip(
              '${_isSwahili ? 'Excess' : 'Excess'}: TZS ${q.excess.toStringAsFixed(0)}'),
          const SizedBox(width: 6),
          if (q.hasNoClaimsDiscount)
            _infoChip(
                '${q.discountPercent?.toStringAsFixed(0) ?? ''}% ${_isSwahili ? 'punguzo' : 'NCD'}'),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(_isSwahili ? 'Nunua Bima?' : 'Purchase Policy?'),
                  content: Text(
                      '${q.providerName} - ${q.coverageLabel}\nTZS ${q.premium.toStringAsFixed(0)}/${_isSwahili ? 'mwaka' : 'year'}'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(_isSwahili ? 'Hapana' : 'Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(_isSwahili ? 'Nunua' : 'Purchase',
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              );
              if (confirm != true || !mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              final result = await CarInsuranceService.purchasePolicy(q.id, {});
              if (!mounted) return;
              if (result.success) {
                messenger.showSnackBar(SnackBar(
                    content: Text(_isSwahili ? 'Bima imesajiliwa!' : 'Policy purchased!')));
                Navigator.pop(context, true);
              } else {
                messenger.showSnackBar(SnackBar(
                    content: Text(result.message ??
                        (_isSwahili ? 'Imeshindwa' : 'Purchase failed'))));
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_isSwahili ? 'Nunua Sasa' : 'Purchase',
                style: const TextStyle(fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 10, color: _kSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}
