import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/product_variant.dart';
import '../services/product_variant_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 144 — Booksy-style Service Variants. Partner picks a parent
/// service ("Box Braids"), then defines variants (small/medium/jumbo) each
/// with its own price + duration. Avoids 30-row scroll menus.
class ManageProductVariantsPage extends StatefulWidget {
  final int productId;
  final String productTitle;
  const ManageProductVariantsPage({
    super.key,
    required this.productId,
    required this.productTitle,
  });

  @override
  State<ManageProductVariantsPage> createState() =>
      _ManageProductVariantsPageState();
}

class _ManageProductVariantsPageState extends State<ManageProductVariantsPage> {
  bool _loading = true;
  List<ProductVariant> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ProductVariantService.listForProduct(widget.productId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res;
    });
  }

  Future<void> _addOrEdit({ProductVariant? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _VariantDialog(
        productId: widget.productId,
        existing: existing,
        isSwahili: _isSwahili,
      ),
    );
    if (result == true && mounted) _load();
  }

  Future<void> _delete(ProductVariant v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa variant?' : 'Delete variant?'),
        content: Text(v.displayLabel(_isSwahili)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await ProductVariantService.delete(v.id);
    if (!mounted) return;
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSw ? 'Aina Mbalimbali' : 'Service Variants',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          widget.productTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kSecondary,
                          ),
                        ),
                      ),
                      ..._items.map(_row),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(isSw ? 'Ongeza' : 'Add'),
      ),
    );
  }

  Widget _empty() {
    final isSw = _isSwahili;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 56, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              isSw ? 'Hakuna aina bado' : 'No variants yet',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isSw
                  ? 'Mfano: small / medium / jumbo kwa "Box Braids".'
                  : 'e.g. small / medium / jumbo for "Box Braids".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(ProductVariant v) {
    final isSw = _isSwahili;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          v.displayLabel(isSw),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        subtitle: Text(
          [
            'TZS ${NumberFormat('#,##0').format(v.priceTzs)}',
            if (v.durationMinutes > 0) '${v.durationMinutes} ${isSw ? 'daka' : 'min'}',
            if (v.leadTimeHours > 0) '${v.leadTimeHours}h ${isSw ? 'kabla' : 'lead'}',
          ].join(' • '),
          style: const TextStyle(fontSize: 11, color: _kSecondary),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (k) {
            if (k == 'edit') _addOrEdit(existing: v);
            if (k == 'delete') _delete(v);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'edit', child: Text(isSw ? 'Hariri' : 'Edit')),
            PopupMenuItem(
                value: 'delete', child: Text(isSw ? 'Futa' : 'Delete')),
          ],
        ),
      ),
    );
  }
}

class _VariantDialog extends StatefulWidget {
  final int productId;
  final ProductVariant? existing;
  final bool isSwahili;
  const _VariantDialog({
    required this.productId,
    required this.existing,
    required this.isSwahili,
  });

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  late final TextEditingController _labelSw, _labelEn, _price, _duration, _lead;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelSw = TextEditingController(text: e?.labelSw ?? '');
    _labelEn = TextEditingController(text: e?.labelEn ?? '');
    _price = TextEditingController(text: e?.priceTzs.toString() ?? '');
    _duration = TextEditingController(
        text: e?.durationMinutes.toString() ?? '');
    _lead = TextEditingController(text: e?.leadTimeHours.toString() ?? '');
  }

  @override
  void dispose() {
    _labelSw.dispose();
    _labelEn.dispose();
    _price.dispose();
    _duration.dispose();
    _lead.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = int.tryParse(_price.text.trim());
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili ? 'Bei si halali' : 'Invalid price'),
      ));
      return;
    }
    setState(() => _saving = true);
    final ok = await ProductVariantService.create(
      partnerProductId: widget.productId,
      labelSw: _labelSw.text.trim().isEmpty ? null : _labelSw.text.trim(),
      labelEn: _labelEn.text.trim().isEmpty ? null : _labelEn.text.trim(),
      priceTzs: price,
      durationMinutes: int.tryParse(_duration.text.trim()) ?? 0,
      leadTimeHours: int.tryParse(_lead.text.trim()) ?? 0,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isSwahili ? 'Imeshindikana' : 'Failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return AlertDialog(
      title: Text(widget.existing == null
          ? (sw ? 'Variant Mpya' : 'New Variant')
          : (sw ? 'Hariri Variant' : 'Edit Variant')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _labelSw,
              decoration: InputDecoration(
                labelText: sw ? 'Jina (KS)' : 'Label (Sw)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _labelEn,
              decoration: InputDecoration(
                labelText: sw ? 'Jina (EN)' : 'Label (En)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: sw ? 'Bei (TZS) *' : 'Price (TZS) *',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: sw ? 'Muda (daka)' : 'Duration (min)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _lead,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: sw ? 'Lead (saa)' : 'Lead (h)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(sw ? 'Funga' : 'Close')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary, foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(sw ? 'Hifadhi' : 'Save'),
        ),
      ],
    );
  }
}
