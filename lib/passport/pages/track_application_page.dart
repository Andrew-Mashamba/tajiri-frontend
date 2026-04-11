// lib/passport/pages/track_application_page.dart
import 'package:flutter/material.dart';
import '../models/passport_models.dart';
import '../services/passport_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PassportTrackPage extends StatefulWidget {
  const PassportTrackPage({super.key});
  @override
  State<PassportTrackPage> createState() => _PassportTrackPageState();
}

class _PassportTrackPageState extends State<PassportTrackPage> {
  final _ctrl = TextEditingController();
  PassportApplication? _app;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _track() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _app = null; });
    final result = await PassportService.trackApplication(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.data != null) _app = result.data;
      else _error = result.message ?? 'Haikupatikana';
    });
  }

  @override
  Widget build(BuildContext context) {
    final stages = ['Imewasilishwa', 'Inashughulikiwa', 'Inachapishwa', 'Tayari'];
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Fuatilia Ombi la Pasipoti',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _ctrl,
              decoration: InputDecoration(hintText: 'Nambari ya ombi',
                hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              style: const TextStyle(fontSize: 14, color: _kPrimary))),
            const SizedBox(width: 8),
            SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _track,
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search_rounded, color: Colors.white))),
          ]),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
          if (_app != null) ...[
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('#${_app!.applicationNumber}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text('${_app!.type} - ${_app!.pages} kurasa / ${_app!.validity} miaka',
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
                const SizedBox(height: 16),
                // Timeline
                ...List.generate(stages.length, (i) {
                  final active = i <= _app!.stageIndex;
                  final current = i == _app!.stageIndex;
                  return Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: active ? _kPrimary : const Color(0xFFE0E0E0), shape: BoxShape.circle),
                        child: active ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : const SizedBox()),
                      const SizedBox(width: 12),
                      Text(stages[i], style: TextStyle(fontSize: 13,
                          fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                          color: active ? _kPrimary : _kSecondary)),
                    ]),
                  );
                }),
                if (_app!.submissionOffice != null) ...[
                  const Divider(height: 16),
                  Text('Ofisi: ${_app!.submissionOffice}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
