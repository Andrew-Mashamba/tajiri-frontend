// lib/nssf/pages/employer_check_page.dart
import 'package:flutter/material.dart';
import '../models/nssf_models.dart';
import '../services/nssf_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EmployerCheckPage extends StatefulWidget {
  const EmployerCheckPage({super.key});
  @override
  State<EmployerCheckPage> createState() => _EmployerCheckPageState();
}

class _EmployerCheckPageState extends State<EmployerCheckPage> {
  final _ctrl = TextEditingController();
  EmployerCompliance? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _check() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    final result = await NssfService.checkEmployer(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.data != null) _result = result.data;
      else _error = result.message ?? 'Haikupatikana';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Angalia Mwajiri',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Tafuta mwajiri kwa jina au TIN',
            style: TextStyle(fontSize: 13, color: _kSecondary)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _ctrl,
            decoration: InputDecoration(hintText: 'Jina la kampuni au TIN',
              hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            style: const TextStyle(fontSize: 14, color: _kPrimary))),
          const SizedBox(width: 8),
          SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _check,
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.search_rounded, color: Colors.white))),
        ]),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
        if (_result != null) ...[
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_result!.employerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              if (_result!.tin != null) Text('TIN: ${_result!.tin}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
              const SizedBox(height: 12),
              _StatusRow(label: 'Imesajiliwa NSSF', ok: _result!.registered),
              const SizedBox(height: 6),
              _StatusRow(label: 'Inachangia', ok: _result!.contributing),
              if (_result!.monthsOwed > 0) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.warning_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Inadaiwa miezi ${_result!.monthsOwed}',
                      style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600)),
                ]),
              ],
              if (_result!.lastContribution != null) ...[
                const SizedBox(height: 6),
                Text('Mchango wa mwisho: ${_result!.lastContribution}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ])),
        ],
      ]),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label; final bool ok;
  const _StatusRow({required this.label, required this.ok});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18,
        color: ok ? const Color(0xFF4CAF50) : Colors.red),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 13, color: _kPrimary)),
  ]);
}
