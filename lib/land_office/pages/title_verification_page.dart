// lib/land_office/pages/title_verification_page.dart
import 'package:flutter/material.dart';
import '../models/land_office_models.dart';
import '../services/land_office_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TitleVerificationPage extends StatefulWidget {
  const TitleVerificationPage({super.key});
  @override
  State<TitleVerificationPage> createState() => _TitleVerificationPageState();
}

class _TitleVerificationPageState extends State<TitleVerificationPage> {
  final _ctrl = TextEditingController();
  TitleDeed? _deed;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _verify() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _deed = null; });
    final result = await LandOfficeService.verifyTitle(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.data != null) _deed = result.data;
      else _error = result.message ?? 'Haikupatikana';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Thibitisha Hati',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Ingiza nambari ya cheti',
            style: TextStyle(fontSize: 13, color: _kSecondary)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _ctrl,
            decoration: InputDecoration(hintText: 'Certificate number',
              hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            style: const TextStyle(fontSize: 14, color: _kPrimary))),
          const SizedBox(width: 8),
          SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _verify,
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Thibitisha', style: TextStyle(color: Colors.white)))),
        ]),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
        if (_deed != null) ...[
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_deed!.verified ? Icons.verified_rounded : Icons.cancel_rounded,
                    size: 28, color: _deed!.verified ? const Color(0xFF4CAF50) : Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text(_deed!.verified ? 'Hati Halali' : 'Hati Haijathibitishwa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: _deed!.verified ? const Color(0xFF4CAF50) : Colors.red))),
              ]),
              const SizedBox(height: 12),
              _Row(label: 'Nambari', value: _deed!.certificateNumber),
              const SizedBox(height: 6),
              _Row(label: 'Mmiliki', value: _deed!.ownerName),
              const SizedBox(height: 6),
              _Row(label: 'Aina', value: _deed!.titleType),
              if (_deed!.issueDate != null) ...[
                const SizedBox(height: 6),
                _Row(label: 'Tarehe', value: '${_deed!.issueDate!.day}/${_deed!.issueDate!.month}/${_deed!.issueDate!.year}'),
              ],
            ])),
        ],
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label; final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary))),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]);
}
