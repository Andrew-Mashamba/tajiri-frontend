// lib/my_children/pages/university_prep_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';
import '../services/children_notification_helper.dart';
import 'career_guidance_page.dart';
import 'academic_tracker_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class UniversityPrepPage extends StatefulWidget {
  final Child child;
  final int userId;

  const UniversityPrepPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<UniversityPrepPage> createState() => _UniversityPrepPageState();
}

class _UniversityPrepPageState extends State<UniversityPrepPage> {
  bool _isLoading = true;
  final Set<String> _checkedItems = {};

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  static const List<Map<String, String>> _checklistItems = [
    {'key': 'research_uni', 'en': 'Research universities', 'sw': 'Tafiti vyuo vikuu'},
    {'key': 'check_necta', 'en': 'Check NECTA results', 'sw': 'Angalia matokeo ya NECTA'},
    {'key': 'apply_heslb', 'en': 'Apply for HESLB loan', 'sw': 'Omba mkopo wa HESLB'},
    {'key': 'gather_docs', 'en': 'Gather required documents', 'sw': 'Kusanya nyaraka zinazohitajika'},
    {'key': 'personal_statement', 'en': 'Write personal statement', 'sw': 'Andika barua ya maombi'},
    {'key': 'apply_uni', 'en': 'Apply to universities', 'sw': 'Omba nafasi ya chuo'},
    {'key': 'prep_interviews', 'en': 'Prepare for interviews', 'sw': 'Jiandae kwa mahojiano'},
  ];

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'uni_prep_${widget.child.id}';
      final saved = prefs.getStringList(key) ?? [];
      _checkedItems.addAll(saved);
      if (mounted) {
        setState(() => _isLoading = false);
        // Fire-and-forget: schedule monthly university prep reminder
        try {
          ChildrenNotificationHelper.scheduleUniPrepReminder(
            widget.child.id,
            widget.child.name,
            isSwahili: _sw,
          ).catchError((_) {});
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleItem(String itemKey, bool checked) async {
    setState(() {
      if (checked) {
        _checkedItems.add(itemKey);
      } else {
        _checkedItems.remove(itemKey);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'uni_prep_${widget.child.id}';
      await prefs.setStringList(key, _checkedItems.toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final completed = _checkedItems.length;
    final total = _checklistItems.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Maandalizi ya Chuo' : 'University Prep',
          style: const TextStyle(
            color: _kPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Progress card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _kPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school_rounded,
                                  color: _kPrimary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sw ? 'Maendeleo' : 'Progress',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _kPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$completed / $total ${sw ? 'hatua zimekamilika' : 'steps completed'}',
                                    style: const TextStyle(
                                        fontSize: 13, color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: _kPrimary.withValues(alpha: 0.08),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_kPrimary),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // HESLB deadline reminder
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            color: _kPrimary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sw
                                    ? 'Kumbusho: Maombi ya HESLB'
                                    : 'Reminder: HESLB Application',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sw
                                    ? 'Maombi ya HESLB kwa kawaida yanafunguliwa kati ya Julai na Septemba kila mwaka. Hakikisha umeshajitayarisha mapema.'
                                    : 'HESLB applications typically open between July and September each year. Make sure you prepare early.',
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Checklist
                  Container(
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            sw ? 'Orodha ya Maandalizi' : 'Preparation Checklist',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ..._checklistItems.map((item) {
                          final isChecked =
                              _checkedItems.contains(item['key']);
                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (val) =>
                                _toggleItem(item['key']!, val ?? false),
                            activeColor: _kPrimary,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            dense: true,
                            title: Text(
                              sw ? item['sw']! : item['en']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isChecked ? _kSecondary : _kPrimary,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link to HESLB module (if route exists)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to HESLB module if available
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(sw
                                ? 'Moduli ya HESLB inakuja hivi karibuni'
                                : 'HESLB module coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_balance_rounded, size: 18),
                      label: Text(
                        sw ? 'Fungua Moduli ya HESLB' : 'Open HESLB Module',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  // ─── Cross-module links ──────────────
                  const SizedBox(height: 20),
                  Text(
                    sw ? 'Viunganishi' : 'Related',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCrossModuleLink(
                    icon: Icons.work_rounded,
                    label: sw
                        ? 'Mwongozo wa Kazi'
                        : 'Career Guidance',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CareerGuidancePage(child: widget.child, userId: widget.userId))),
                  ),
                  _buildCrossModuleLink(
                    icon: Icons.school_rounded,
                    label: sw
                        ? 'Angalia matokeo ya masomo'
                        : 'View academic results',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AcademicTrackerPage(child: widget.child, userId: widget.userId))),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }
}
