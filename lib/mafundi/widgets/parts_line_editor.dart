import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/service_request.dart';
import '../services/service_request_service.dart';

class PartsLineEditor extends StatefulWidget {
  final int requestId;
  final int userId;
  final List<PartsLineItem> initialItems;
  final int? initialMarkupPct;
  final VoidCallback? onSaved;

  const PartsLineEditor({
    super.key,
    required this.requestId,
    required this.userId,
    required this.initialItems,
    this.initialMarkupPct,
    this.onSaved,
  });

  @override
  State<PartsLineEditor> createState() => _PartsLineEditorState();
}

class _PartsLineEditorState extends State<PartsLineEditor> {
  late final List<_Row> _rows;
  late final TextEditingController _markupCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialItems
        .map((i) => _Row(
              nameCtrl: TextEditingController(text: i.name),
              costCtrl: TextEditingController(text: i.costTzs.toString()),
              markupCtrl:
                  TextEditingController(text: i.markupPct?.toString() ?? ''),
            ))
        .toList();
    _markupCtrl =
        TextEditingController(text: widget.initialMarkupPct?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _markupCtrl.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_Row(
        nameCtrl: TextEditingController(),
        costCtrl: TextEditingController(),
        markupCtrl: TextEditingController(text: _markupCtrl.text),
      ));
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  Future<void> _save() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final items = <Map<String, dynamic>>[];
    for (final r in _rows) {
      final name = r.nameCtrl.text.trim();
      final cost = int.tryParse(r.costCtrl.text.trim());
      if (name.isEmpty || cost == null || cost < 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isSw
              ? 'Jaza jina na bei sahihi kwa kila kipengele'
              : 'Fill name and valid cost for every item'),
        ));
        return;
      }
      final markup = int.tryParse(r.markupCtrl.text.trim());
      items.add({
        'name': name,
        'cost_tzs': cost,
        if (markup != null) 'markup_pct': markup,
      });
    }
    final globalMarkup = int.tryParse(_markupCtrl.text.trim());

    setState(() => _saving = true);
    final res = await ServiceRequestService.updateParts(
      id: widget.requestId,
      userId: widget.userId,
      partsLineItems: items,
      partsMarkupPct: globalMarkup,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isSw ? 'Vifaa vimehifadhiwa' : 'Parts saved'),
      ));
      widget.onSaved?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (isSw ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSw ? 'Vifaa vinavyohitajika' : 'Parts required',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_rows.isEmpty)
            Text(
              isSw
                  ? 'Bado hakuna vifaa. Ongeza hapa chini.'
                  : 'No parts yet. Add below.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ..._rows.asMap().entries.map((e) => _rowTile(e.key, e.value, isSw)),
          TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded),
            label: Text(isSw ? 'Ongeza kipengele' : 'Add item'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _markupCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isSw
                  ? 'Asilimia ya markup (hiari)'
                  : 'Markup % (optional)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(isSw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _rowTile(int index, _Row row, bool isSw) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.nameCtrl,
              decoration: InputDecoration(
                hintText: isSw ? 'Jina' : 'Name',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.costCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: isSw ? 'Bei' : 'Cost',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 1,
            child: TextField(
              controller: row.markupCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: isSw ? '%' : '%',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _removeRow(index),
          ),
        ],
      ),
    );
  }
}

class _Row {
  final TextEditingController nameCtrl;
  final TextEditingController costCtrl;
  final TextEditingController markupCtrl;

  _Row({
    required this.nameCtrl,
    required this.costCtrl,
    required this.markupCtrl,
  });

  void dispose() {
    nameCtrl.dispose();
    costCtrl.dispose();
    markupCtrl.dispose();
  }
}
