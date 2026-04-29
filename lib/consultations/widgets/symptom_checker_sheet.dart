import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/symptom_checker_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 716 — bottom sheet that captures a free-text symptom (Swahili
/// or English), calls AI triage, and returns a SymptomTriage so callers
/// can route the customer to the right specialty + booking mode.
class SymptomCheckerSheet extends StatefulWidget {
  const SymptomCheckerSheet({super.key});

  static Future<SymptomTriage?> show(BuildContext context) {
    return showModalBottomSheet<SymptomTriage>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SymptomCheckerSheet(),
    );
  }

  @override
  State<SymptomCheckerSheet> createState() => _SymptomCheckerSheetState();
}

class _SymptomCheckerSheetState extends State<SymptomCheckerSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  SymptomTriage? _result;
  String? _error;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_ctrl.text.trim().length < 4) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    final res = await SymptomCheckerService.check(_ctrl.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = res;
      if (res == null) {
        _error = _isSwahili
            ? 'Imeshindikana. Eleza dalili kwa maneno mengine.'
            : 'Triage failed. Try a different phrasing.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.health_and_safety_rounded,
                        size: 18, color: _kPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isSw
                            ? 'Eleza dalili zako'
                            : 'Describe your symptom',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isSw
                      ? 'AI itasaidia kupendekeza daktari sahihi.'
                      : 'AI will suggest the right specialty.',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: isSw
                        ? 'Mfano: Inaumiza kifua nikifanya mazoezi'
                        : 'e.g. Chest pain when exercising',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _check,
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.medical_services_rounded, size: 16),
                  label: Text(
                    _busy
                        ? (isSw ? 'Inafikiri...' : 'Thinking...')
                        : (isSw ? 'Tathmini' : 'Triage'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFB71C1C))),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _resultCard(_result!, isSw),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _result),
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: Text(
                      isSw
                          ? 'Tafuta madaktari wa ${_result!.specialty}'
                          : 'Find ${_result!.specialty} doctors',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultCard(SymptomTriage t, bool isSw) {
    final (severityBg, severityFg, severityLabel) = _classifySeverity(t.severity, isSw);
    final (routingBg, routingFg, routingLabel) = _classifyRouting(t.routing, isSw);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, size: 14, color: _kPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isSw
                      ? 'Daktari wa ${t.specialty}'
                      : '${_capitalize(t.specialty)} doctor',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                  ),
                ),
              ),
              Text(
                '${(t.confidence * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(severityLabel, severityBg, severityFg, Icons.warning_rounded),
              _chip(routingLabel, routingBg, routingFg, Icons.directions_rounded),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  (Color, Color, String) _classifySeverity(String s, bool isSw) {
    switch (s) {
      case 'emergency':
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFB71C1C),
          isSw ? 'Dharura' : 'Emergency',
        );
      case 'urgent':
        return (
          const Color(0xFFFFF8E1),
          const Color(0xFFE65100),
          isSw ? 'Haraka' : 'Urgent',
        );
      default:
        return (
          const Color(0xFFE8F5E9),
          const Color(0xFF1B5E20),
          isSw ? 'Kawaida' : 'Routine',
        );
    }
  }

  (Color, Color, String) _classifyRouting(String r, bool isSw) {
    switch (r) {
      case 'er':
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFB71C1C),
          isSw ? 'Hospitali sasa' : 'ER now',
        );
      case 'in_person':
        return (
          const Color(0xFFE3F2FD),
          const Color(0xFF0D47A1),
          isSw ? 'Ana kwa ana' : 'In-person',
        );
      case 'video':
        return (
          const Color(0xFFE3F2FD),
          const Color(0xFF0D47A1),
          isSw ? 'Video' : 'Video',
        );
      case 'self_care':
        return (
          const Color(0xFFEEEEEE),
          const Color(0xFF666666),
          isSw ? 'Jipake' : 'Self-care',
        );
      default:
        return (
          const Color(0xFFE3F2FD),
          const Color(0xFF0D47A1),
          isSw ? 'SMS' : 'Async chat',
        );
    }
  }

  Widget _chip(String text, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
