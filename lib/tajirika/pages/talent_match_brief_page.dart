import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F8 #71 — Toptal-style talent matching brief.
///
/// Customer fills 4-step brief; backend returns shortlist of partner_user_ids;
/// page shows them with a "Request introduction" CTA.
class TalentMatchBriefPage extends StatefulWidget {
  final int userId;
  const TalentMatchBriefPage({super.key, required this.userId});

  @override
  State<TalentMatchBriefPage> createState() => _TalentMatchBriefPageState();
}

class _TalentMatchBriefPageState extends State<TalentMatchBriefPage> {
  String? _skill;
  final _yearsCtrl = TextEditingController(text: '5');
  final _scopeCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  bool _submitting = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _yearsCtrl.dispose();
    _scopeCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_skill == null) return;
    setState(() => _submitting = true);
    final res = await TalentMatchService.brief(
      userId: widget.userId,
      skillCategory: _skill!,
      requirements: {
        'years': int.tryParse(_yearsCtrl.text) ?? 5,
        'scope': _scopeCtrl.text,
      },
      budgetTzs: int.tryParse(_budgetCtrl.text),
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Tafuta mtaalamu' : 'Find an expert'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_result == null) ...[
            Text(
              isSw
                  ? 'Tueleze unahitaji mtaalamu wa aina gani.'
                  : 'Tell us what kind of expert you need.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _skill,
              decoration: InputDecoration(
                labelText: isSw ? 'Ujuzi' : 'Skill',
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'consultant', child: Text('Consultant')),
                DropdownMenuItem(value: 'designer', child: Text('Designer')),
                DropdownMenuItem(value: 'engineer', child: Text('Engineer')),
                DropdownMenuItem(value: 'lawyer', child: Text('Lawyer')),
                DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
              ],
              onChanged: (v) => setState(() => _skill = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isSw ? 'Uzoefu (miaka)' : 'Min years experience',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _scopeCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: isSw ? 'Eleza kazi' : 'Describe the work',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isSw ? 'Bajeti (TZS)' : 'Budget (TZS)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A)),
                onPressed: _submitting || _skill == null ? null : _submit,
                child: Text(
                  _submitting
                      ? (isSw ? 'Inatuma…' : 'Sending…')
                      : (isSw ? 'Tafuta' : 'Match me'),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isSw
                    ? 'Tumepata wataalamu ${(_result!['shortlist'] as List?)?.length ?? 0}.'
                    : 'We matched ${(_result!['shortlist'] as List?)?.length ?? 0} experts.',
                style: const TextStyle(
                    color: Color(0xFF1B5E20), fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            ...((_result!['shortlist'] as List?) ?? []).map((id) {
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
                    const CircleAvatar(
                      backgroundColor: Color(0xFFEEEEEE),
                      child: Icon(Icons.person_rounded, color: Color(0xFF666666)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSw ? 'Mtaalamu #$id' : 'Expert #$id',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(isSw
                                  ? 'Ombi limetumwa'
                                  : 'Introduction requested')),
                        );
                      },
                      child: Text(isSw ? 'Wasiliana' : 'Introduce'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _result = null),
              child: Text(isSw ? 'Anza upya' : 'Start over'),
            ),
          ],
        ],
      ),
    );
  }
}
