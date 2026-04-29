import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';

/// Spec line 1283 — partner pauses an individual skill without affecting
/// the rest. `is_paused` column on `partner_skill_personas` shipped session 12;
/// this widget surfaces the toggle on partner profile per skill.
class SkillPauseToggle extends StatefulWidget {
  final int partnerUserId;
  final String skillCategory;
  final bool initiallyPaused;
  final ValueChanged<bool>? onChanged;
  const SkillPauseToggle({
    super.key,
    required this.partnerUserId,
    required this.skillCategory,
    this.initiallyPaused = false,
    this.onChanged,
  });

  @override
  State<SkillPauseToggle> createState() => _SkillPauseToggleState();
}

class _SkillPauseToggleState extends State<SkillPauseToggle> {
  late bool _paused;
  bool _busy = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _paused = widget.initiallyPaused;
  }

  Future<void> _toggle(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await _setPaused(v);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _paused = v;
    });
    if (ok) widget.onChanged?.call(v);
  }

  Future<bool> _setPaused(bool paused) async {
    try {
      final res = await http.patch(
        Uri.parse(
            '${ApiConfig.baseUrl}/partner-skill-personas/${widget.skillCategory}'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partner_user_id': widget.partnerUserId,
          'is_paused': paused,
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return InkWell(
      onTap: _busy ? null : () => _toggle(!_paused),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _paused
              ? const Color(0xFFFFF8E1)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              Icon(
                _paused
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                size: 11,
                color: _paused
                    ? const Color(0xFFE65100)
                    : const Color(0xFF1B5E20),
              ),
            const SizedBox(width: 3),
            Text(
              _paused
                  ? (isSw ? 'Imesimama' : 'Paused')
                  : (isSw ? 'Hai' : 'Active'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _paused
                    ? const Color(0xFFE65100)
                    : const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
