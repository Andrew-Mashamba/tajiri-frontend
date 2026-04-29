import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/ai_brief_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec line 825 — bottom sheet that captures a one-line goal, calls the
/// AI brief endpoint, and returns a structured `AiBrief` for the parent
/// page to apply to its propose-engagement form.
class AiBriefSheet extends StatefulWidget {
  final String? skillCategory;
  const AiBriefSheet({super.key, this.skillCategory});

  static Future<AiBrief?> show(BuildContext context, {String? skillCategory}) {
    return showModalBottomSheet<AiBrief>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AiBriefSheet(skillCategory: skillCategory),
    );
  }

  @override
  State<AiBriefSheet> createState() => _AiBriefSheetState();
}

class _AiBriefSheetState extends State<AiBriefSheet> {
  final _ctrl = TextEditingController();
  bool _generating = false;
  String? _error;
  AiBrief? _brief;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_ctrl.text.trim().length < 6) return;
    setState(() {
      _generating = true;
      _error = null;
      _brief = null;
    });
    final res = await AiBriefService.generate(
      goal: _ctrl.text.trim(),
      skillCategory: widget.skillCategory,
    );
    if (!mounted) return;
    setState(() {
      _generating = false;
      _brief = res;
      if (res == null) {
        _error = _isSwahili
            ? 'Imeshindikana kuunda muhtasari. Jaribu tena.'
            : 'AI couldn\'t generate. Try a different phrasing.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    const Icon(Icons.auto_awesome_rounded,
                        size: 18, color: _kPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isSw
                            ? 'Tengeneza muhtasari kwa AI'
                            : 'AI-generate a brief',
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
                      ? 'Andika lengo lako kwa sentensi moja, na AI itatengeneza wigo, milestones na bajeti.'
                      : 'Describe your goal in one line. AI will draft the scope, milestones and budget.',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: isSw
                        ? 'Mfano: Nataka logo mpya kwa mkahawa wangu'
                        : 'e.g. I need a new logo for my restaurant',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(
                    _generating
                        ? (isSw ? 'Inafikiri...' : 'Thinking...')
                        : (isSw ? 'Tengeneza' : 'Generate'),
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
                if (_brief != null) ...[
                  const SizedBox(height: 16),
                  _briefPreview(_brief!, isSw),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _brief),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(isSw ? 'Tumia muhtasari huu' : 'Use this brief'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
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

  Widget _briefPreview(AiBrief b, bool isSw) {
    final title = isSw ? b.titleSw : b.titleEn;
    final scope = isSw ? b.scopeSw : b.scopeEn;
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scope,
            style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.3),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (b.deliverables.isNotEmpty) ...[
            Text(
              isSw ? 'Vitu vya kutoa' : 'Deliverables',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: _kSecondary),
            ),
            const SizedBox(height: 4),
            ...b.deliverables.take(5).map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 11)),
                        Expanded(
                          child: Text(
                            d,
                            style: const TextStyle(fontSize: 11, color: _kPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (b.milestones.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              isSw ? 'Hatua' : 'Milestones',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: _kSecondary),
            ),
            const SizedBox(height: 4),
            ...b.milestones.take(5).map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.title,
                            style: const TextStyle(fontSize: 11, color: _kPrimary),
                          ),
                        ),
                        Text(
                          'TZS ${m.amountTzs}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _miniChip(
                  isSw ? 'Siku ${b.timelineDays}' : '${b.timelineDays}d',
                  Icons.schedule_rounded),
              _miniChip(
                  'TZS ${b.budgetBandLowTzs} – ${b.budgetBandHighTzs}',
                  Icons.savings_rounded),
              _miniChip(b.contractType, Icons.gavel_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF0D47A1)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }
}
