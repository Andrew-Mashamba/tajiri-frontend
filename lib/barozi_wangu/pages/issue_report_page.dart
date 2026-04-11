// lib/barozi_wangu/pages/issue_report_page.dart
import 'package:flutter/material.dart';
import '../models/barozi_wangu_models.dart';
import '../services/barozi_wangu_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class IssueReportPage extends StatefulWidget {
  final int wardId;
  const IssueReportPage({super.key, required this.wardId});

  @override
  State<IssueReportPage> createState() => _IssueReportPageState();
}

class _IssueReportPageState extends State<IssueReportPage> {
  final _descCtrl = TextEditingController();
  IssueCategory _category = IssueCategory.roads;
  String _priority = 'medium';
  bool _submitting = false;

  final _service = BaroziWanguService();

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali eleza tatizo')),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await _service.reportIssue({
      'ward_id': widget.wardId,
      'category': _category.name,
      'description': desc,
      'priority': _priority,
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tatizo limeripotiwa')),
      );
      Navigator.pop(context, result.data);
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text(
          'Ripoti Tatizo',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Category ──
          const Text('Aina', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IssueCategory.values.map((c) {
              final selected = c == _category;
              return ChoiceChip(
                label: Text(_categoryLabel(c)),
                selected: selected,
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontSize: 13,
                ),
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Priority ──
          const Text('Kipaumbele',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['low', 'medium', 'high'].map((p) {
              final selected = p == _priority;
              return ChoiceChip(
                label: Text(p == 'low'
                    ? 'Chini'
                    : p == 'medium'
                        ? 'Wastani'
                        : 'Juu'),
                selected: selected,
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontSize: 13,
                ),
                onSelected: (_) => setState(() => _priority = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Description ──
          const Text('Maelezo', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Eleza tatizo kwa ufupi...',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Photo (placeholder) ──
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kupakia picha / Photo upload - coming soon')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        color: _kSecondary, size: 28),
                    SizedBox(height: 4),
                    Text('Ongeza picha / Add photo',
                        style: TextStyle(color: _kSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Wasilisha', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(IssueCategory c) {
    switch (c) {
      case IssueCategory.roads:
        return 'Barabara';
      case IssueCategory.water:
        return 'Maji';
      case IssueCategory.sanitation:
        return 'Usafi';
      case IssueCategory.electricity:
        return 'Umeme';
      case IssueCategory.security:
        return 'Usalama';
      case IssueCategory.other:
        return 'Nyingine';
    }
  }
}
