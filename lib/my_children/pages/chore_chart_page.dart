// lib/my_children/pages/chore_chart_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';
import '../services/children_notification_helper.dart';
import '../services/my_children_service.dart';
import 'allowance_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ChoreChartPage extends StatefulWidget {
  final Child child;
  final int userId;

  const ChoreChartPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<ChoreChartPage> createState() => _ChoreChartPageState();
}

class _ChoreChartPageState extends State<ChoreChartPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  List<ChoreAssignment> _chores = [];
  String? _token;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadChores();
  }

  Future<void> _loadChores() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getChores(_token!, widget.child.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _chores = result.items;
      });
      // Schedule daily chore reminder if there are incomplete chores
      if (result.success) {
        final incompleteCount =
            result.items.where((c) => !c.isCompleted).length;
        ChildrenNotificationHelper.scheduleDailyChoreReminder(
          widget.child.id, widget.child.name, incompleteCount, _sw,
        ).catchError((_) {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _sw ? 'Imeshindikana kupakia' : 'Failed to load'),
        ),
      );
    }
  }

  Future<void> _completeChore(int choreId, int index) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);

    // Optimistic update
    setState(() {
      _chores[index] = _chores[index].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
    });

    try {
      final result = await _service.completeChore(_token!, choreId);
      if (!mounted) return;
      if (!result.success) {
        // Revert
        setState(() {
          _chores[index] = _chores[index].copyWith(
            isCompleted: false,
            completedAt: null,
          );
        });
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      } else if (_chores[index].rewardAmount > 0 && _token != null) {
        // Fire-and-forget: report chore reward as parent expenditure
        ExpenditureService.recordExpenditure(
          token: _token!,
          amount: _chores[index].rewardAmount,
          category: 'watoto',
          description: 'Child expense: ${widget.child.name} — chore reward: ${_chores[index].localizedTitle(isSwahili: false)}',
          referenceId: 'child_expense_${widget.child.id}_${DateTime.now().millisecondsSinceEpoch}',
          sourceModule: 'my_children',
        ).catchError((_) => null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chores[index] = _chores[index].copyWith(
          isCompleted: false,
          completedAt: null,
        );
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              _sw ? 'Imeshindikana' : 'Failed to complete'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final doneCount = _chores.where((c) => c.isCompleted).length;
    final totalEarned = _chores
        .where((c) => c.isCompleted)
        .fold<double>(0, (sum, c) => sum + c.rewardAmount);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Majukumu' : 'Chores',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadChores,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            sw ? 'Zilizofanyika' : 'Completed',
                            '$doneCount / ${_chores.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            sw ? 'Kilichopatikana' : 'Earned',
                            'TZS ${totalEarned.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weekly scorecard
                    _buildWeeklyScorecard(sw),
                    const SizedBox(height: 16),

                    // Today's chores header
                    Text(
                      sw ? 'Majukumu ya Leo' : "Today's Chores",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_chores.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            sw
                                ? 'Hakuna majukumu bado'
                                : 'No chores yet',
                            style: const TextStyle(
                                fontSize: 15, color: _kSecondary),
                          ),
                        ),
                      )
                    else
                      ..._chores.asMap().entries.map(
                            (e) => _buildChoreItem(sw, e.value, e.key)),

                    // ─── Cross-module link: allowance ────────
                    if (totalEarned > 0) ...[
                      const SizedBox(height: 16),
                      _buildCrossModuleLink(
                        icon: Icons.account_balance_wallet_rounded,
                        label: sw
                            ? 'Hongera! TZS ${totalEarned.toStringAsFixed(0)} imepatikana. Tazama posho'
                            : 'Well done! TZS ${totalEarned.toStringAsFixed(0)} earned. View allowance',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllowancePage(
                              child: widget.child,
                              userId: widget.userId,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWeeklyScorecard(bool sw) {
    if (_chores.isEmpty) return const SizedBox.shrink();

    final total = _chores.length;
    final completed = _chores.where((c) => c.isCompleted).length;
    final fraction = total > 0 ? completed / total : 0.0;
    final pct = (fraction * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.scoreboard_rounded, size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw ? 'Kadi ya Alama ya Wiki' : 'Weekly Scorecard',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
              Text(
                '$completed / $total',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade200,
              color: pct >= 80
                  ? const Color(0xFF4CAF50)
                  : pct >= 50
                      ? Colors.orange
                      : _kPrimary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pct >= 80
                ? (sw ? 'Bora sana! Endelea hivyo.' : 'Excellent! Keep it up.')
                : pct >= 50
                    ? (sw ? 'Vizuri, lakini unaweza kufanya zaidi.' : 'Good, but you can do more.')
                    : (sw ? 'Jitahidi zaidi wiki hii.' : 'Try harder this week.'),
            style: TextStyle(
              fontSize: 12,
              color: pct >= 80
                  ? const Color(0xFF4CAF50)
                  : pct >= 50
                      ? Colors.orange
                      : _kSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChoreItem(bool sw, ChoreAssignment chore, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
      onLongPress: () => _confirmDeleteChore(chore.id, chore.localizedTitle(isSwahili: sw)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: chore.isCompleted
                  ? null
                  : () => _completeChore(chore.id, index),
              child: Icon(
                chore.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: chore.isCompleted ? Colors.green : _kSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chore.localizedTitle(isSwahili: sw),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary,
                      decoration:
                          chore.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          chore.frequency,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                        ),
                      ),
                      if (chore.rewardAmount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          'TZS ${chore.rewardAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _confirmDeleteChore(int id, String label) {
    final sw = _sw;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa?' : 'Delete?'),
        content: Text(sw ? 'Futa "$label"?' : 'Delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_token == null) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final result = await _service.deleteChore(_token!, id);
                if (!mounted) return;
                if (result.success) {
                  _loadChores();
                  messenger.showSnackBar(SnackBar(
                    content: Text(
                        sw ? 'Jukumu limefutwa' : 'Chore deleted'),
                  ));
                } else {
                  messenger.showSnackBar(SnackBar(
                      content: Text(result.message ?? 'Error')));
                }
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text(
                      sw ? 'Imeshindikana kufuta' : 'Failed to delete'),
                ));
              }
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final sw = _sw;
    final titleCtrl = TextEditingController();
    final titleSwCtrl = TextEditingController();
    final rewardCtrl = TextEditingController();
    String frequency = 'daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Ongeza Jukumu' : 'Add Chore',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: sw ? 'Jina (Kiingereza)' : 'Title (English)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleSwCtrl,
                  decoration: InputDecoration(
                    labelText: sw ? 'Jina (Kiswahili)' : 'Title (Swahili)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: InputDecoration(
                    labelText: sw ? 'Mzunguko' : 'Frequency',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'daily',
                        child: Text(sw ? 'Kila siku' : 'Daily')),
                    DropdownMenuItem(
                        value: 'weekly',
                        child: Text(sw ? 'Kila wiki' : 'Weekly')),
                  ],
                  onChanged: (v) {
                    if (v != null) setSheetState(() => frequency = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rewardCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: sw ? 'Tuzo (TZS)' : 'Reward (TZS)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      _submitChore(
                        ctx,
                        title,
                        titleSwCtrl.text.trim(),
                        frequency,
                        double.tryParse(rewardCtrl.text.trim()) ?? 0,
                      );
                    },
                    child: Text(sw ? 'Hifadhi' : 'Save'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _submitChore(BuildContext ctx, String title,
      String titleSw, String frequency, double reward) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(ctx).pop();

    try {
      final result = await _service.createChore(
        token: _token!,
        childId: widget.child.id,
        title: title,
        titleSwahili: titleSw.isNotEmpty ? titleSw : null,
        frequency: frequency,
        rewardAmount: reward,
      );
      if (!mounted) return;
      if (result.success) {
        _loadChores();
        messenger.showSnackBar(
          SnackBar(
            content:
                Text(_sw ? 'Jukumu limeongezwa' : 'Chore added'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              _sw ? 'Imeshindikana kuhifadhi' : 'Failed to save'),
        ),
      );
    }
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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
