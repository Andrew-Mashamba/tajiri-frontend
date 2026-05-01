import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_i_services.dart';

/// Spec F7 #symptom-checker — free-text symptom → predicted skill mapping.
class SymptomCheckerPage extends StatefulWidget {
  const SymptomCheckerPage({super.key});

  @override
  State<SymptomCheckerPage> createState() => _SymptomCheckerPageState();
}

class _SymptomCheckerPageState extends State<SymptomCheckerPage> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  List<Map<String, dynamic>> _predicted = const [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    final res = await SymptomCheckerService.predict(_ctrl.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _predicted = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Mshauri wa daktari' : 'Symptom checker'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isSw
                ? 'Eleza dalili — tutapendekeza aina ya daktari unayohitaji.'
                : 'Describe the symptoms — we suggest the right specialty.',
            style: const TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: isSw ? 'mfano: homa, kichwa, tumbo' : 'e.g. fever, headache',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
              onPressed: _busy ? null : _check,
              child: Text(_busy
                  ? (isSw ? 'Inaangalia…' : 'Checking…')
                  : (isSw ? 'Pendekeza' : 'Predict')),
            ),
          ),
          const SizedBox(height: 16),
          ..._predicted.map((p) {
            final skill = p['skill']?.toString() ?? '';
            final conf = (p['confidence'] as num?)?.toDouble() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      skill,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                  Text('${(conf * 100).round()}%',
                      style: const TextStyle(color: Color(0xFF666666))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
