// lib/dc/pages/dc_report_page.dart
import 'package:flutter/material.dart';
import '../services/dc_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DcReportPage extends StatefulWidget {
  final int districtId;
  const DcReportPage({super.key, required this.districtId});

  @override
  State<DcReportPage> createState() => _DcReportPageState();
}

class _DcReportPageState extends State<DcReportPage> {
  final _descCtrl = TextEditingController();
  String _category = 'general';
  bool _submitting = false;
  final _service = DcService();

  static const _categories = [
    ('general', 'Jumla'),
    ('infrastructure', 'Miundombinu'),
    ('education', 'Elimu'),
    ('health', 'Afya'),
    ('security', 'Usalama'),
    ('corruption', 'Rushwa'),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali andika maelezo')),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await _service.submitComplaint({
      'district_id': widget.districtId,
      'category': _category,
      'description': desc,
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      final tracking = result.data?.trackingNumber ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imesajiliwa${tracking.isNotEmpty ? ": $tracking" : ""}')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text('Ripoti kwa DC',
            style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Aina', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((c) {
              final selected = c.$1 == _category;
              return ChoiceChip(
                label: Text(c.$2),
                selected: selected,
                selectedColor: _kPrimary,
                labelStyle: TextStyle(color: selected ? Colors.white : _kPrimary, fontSize: 13),
                onSelected: (_) => setState(() => _category = c.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Maelezo', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl, maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Eleza tatizo au pendekezo lako...',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Wasilisha', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
