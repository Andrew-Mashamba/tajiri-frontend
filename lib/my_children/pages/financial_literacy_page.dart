// lib/my_children/pages/financial_literacy_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/income_service.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../services/my_children_service.dart';
import 'allowance_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FinancialLiteracyPage extends StatefulWidget {
  final Child child;
  final int userId;

  const FinancialLiteracyPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<FinancialLiteracyPage> createState() => _FinancialLiteracyPageState();
}

class _FinancialLiteracyPageState extends State<FinancialLiteracyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MyChildrenService _service = MyChildrenService();
  String? _token;
  bool _isLoading = false;

  // Financial data (from backend when available)
  double _choreEarnings = 0;
  double _savingsGoalTarget = 0;
  double _savingsGoalCurrent = 0;
  double _weeklyAllowance = 0;
  double _weeklySpent = 0;
  double _charityTotal = 0;

  // Spending entries (persisted locally for now)
  final List<Map<String, dynamic>> _spendingEntries = [];

  // Volunteer hours log
  List<Map<String, dynamic>> _volunteerLogs = [];
  double _totalVolunteerHours = 0;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'financial_${widget.child.id}';
      _choreEarnings = prefs.getDouble('${key}_chore_earnings') ?? 0;
      _savingsGoalTarget = prefs.getDouble('${key}_savings_target') ?? 50000;
      _savingsGoalCurrent = prefs.getDouble('${key}_savings_current') ?? 0;
      _weeklyAllowance = prefs.getDouble('${key}_weekly_allowance') ?? 0;
      _weeklySpent = prefs.getDouble('${key}_weekly_spent') ?? 0;
      _charityTotal = prefs.getDouble('${key}_charity_total') ?? 0;

      // Load volunteer logs
      final volJson = prefs.getString('${key}_volunteer_logs');
      if (volJson != null) {
        final decoded = jsonDecode(volJson);
        if (decoded is List) {
          _volunteerLogs = decoded.cast<Map<String, dynamic>>();
          _totalVolunteerHours = _volunteerLogs.fold<double>(
            0,
            (sum, log) => sum + ((log['hours'] as num?)?.toDouble() ?? 0),
          );
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveValue(String field, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'financial_${widget.child.id}';
      await prefs.setDouble('${key}_$field', value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Elimu ya Fedha' : 'Financial Literacy',
          style: const TextStyle(
            color: _kPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: sw ? 'Pata' : 'Earn'),
            Tab(text: sw ? 'Hifadhi' : 'Save'),
            Tab(text: sw ? 'Tumia' : 'Spend'),
            Tab(text: sw ? 'Toa' : 'Give'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildEarnTab(sw),
                  _buildSaveTab(sw),
                  _buildSpendTab(sw),
                  _buildGiveTab(sw),
                ],
              ),
      ),
    );
  }

  // ─── Earn Tab ────────────────────────────────────────────────

  Widget _buildEarnTab(bool sw) {
    final age = widget.child.ageInYears;
    final jobIdeas = _getJobIdeas(age, sw);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Chore earnings summary
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
                    child: const Icon(Icons.trending_up_rounded,
                        color: _kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? 'Mapato ya Kazi za Nyumbani' : 'Chore Earnings',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'TZS ${_choreEarnings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // First job ideas
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
              Text(
                sw ? 'Mawazo ya Kazi ya Kwanza' : 'First Job Ideas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                sw
                    ? 'Kazi zinazofaa umri wa miaka ${widget.child.ageInYears}:'
                    : 'Age-appropriate jobs for ${widget.child.ageInYears} year olds:',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              ...jobIdeas.map((job) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              Icon(job.icon, color: _kPrimary, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                job.description,
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Partial 26: Log Earnings button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showLogEarningsDialog(sw),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              sw ? 'Rekodi Mapato' : 'Log Earnings',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
          icon: Icons.chat_rounded,
          label: sw
              ? 'Uliza Shangazi kuhusu kufundisha vijana kuhusu fedha'
              : 'Ask Shangazi about teaching teens about money',
          onTap: () => Navigator.pushNamed(context, '/chat/0'),
        ),
        _buildCrossModuleLink(
          icon: Icons.account_balance_wallet_rounded,
          label: sw
              ? 'Fungua ukurasa wa Posho'
              : 'Open Allowance page',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AllowancePage(child: widget.child, userId: widget.userId))),
        ),
        const SizedBox(height: 24),
      ],
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

  void _showLogEarningsDialog(bool sw) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          sw ? 'Rekodi Mapato' : 'Log Earnings',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo' : 'Description',
                hintText: sw ? 'Mfano: Kufundisha' : 'e.g. Tutoring',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              final desc = descCtrl.text.trim();
              if (amount <= 0) return;

              Navigator.pop(ctx);

              // Update local chore earnings
              setState(() => _choreEarnings += amount);
              _saveValue('chore_earnings', _choreEarnings);

              // 1. Log to child's allowance
              if (_token != null) {
                _service.logAllowance(
                  token: _token!,
                  childId: widget.child.id,
                  amount: amount,
                  type: 'earned',
                  description: desc.isNotEmpty ? desc : null,
                  source: 'earnings',
                ).then((_) {}).catchError((_) {});

                // 2. Record as parent income
                IncomeService.recordIncome(
                  token: _token!,
                  amount: amount,
                  source: 'child_earnings',
                  description: '${widget.child.name}: ${desc.isNotEmpty ? desc : (sw ? 'Mapato' : 'Earnings')}',
                  sourceModule: 'my_children',
                  referenceId: 'child_earn_${widget.child.id}_${DateTime.now().millisecondsSinceEpoch}',
                ).then((_) {}).catchError((_) {});
              }

              messenger.showSnackBar(SnackBar(
                content: Text(sw
                    ? 'Mapato yamerekodiwa: TZS ${amount.toStringAsFixed(0)}'
                    : 'Earnings logged: TZS ${amount.toStringAsFixed(0)}'),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
  }

  List<_JobIdea> _getJobIdeas(int age, bool sw) {
    final jobs = <_JobIdea>[];
    if (age >= 12) {
      jobs.add(_JobIdea(
        icon: Icons.school_rounded,
        title: sw ? 'Kufundisha wadogo' : 'Tutoring younger kids',
        description: sw
            ? 'Saidia watoto wadogo kusoma na kufanya kazi za shule'
            : 'Help younger children with reading and homework',
      ));
    }
    if (age >= 13) {
      jobs.add(_JobIdea(
        icon: Icons.store_rounded,
        title: sw ? 'Kusaidia dukani' : 'Shop helper',
        description: sw
            ? 'Saidia kupanga bidhaa na kuhudumia wateja'
            : 'Help organize goods and serve customers',
      ));
    }
    if (age >= 14) {
      jobs.add(_JobIdea(
        icon: Icons.agriculture_rounded,
        title: sw ? 'Kusaidia shambani' : 'Farm helper',
        description: sw
            ? 'Saidia kazi za shamba kama kupanda na kuvuna'
            : 'Help with planting, weeding, and harvesting',
      ));
    }
    if (age >= 16) {
      jobs.add(_JobIdea(
        icon: Icons.computer_rounded,
        title: sw ? 'Kazi za mtandaoni' : 'Online freelancing',
        description: sw
            ? 'Ubunifu wa picha, kuandika makala, au kuingiza data'
            : 'Graphic design, article writing, or data entry',
      ));
    }
    return jobs;
  }

  // ─── Save Tab ────────────────────────────────────────────────

  Widget _buildSaveTab(bool sw) {
    final progress = _savingsGoalTarget > 0
        ? (_savingsGoalCurrent / _savingsGoalTarget).clamp(0.0, 1.0)
        : 0.0;

    // Compound interest example
    const monthlyDeposit = 10000.0;
    const months = 60; // 5 years
    const rate = 0.06 / 12; // 6% annually
    double futureValue = 0;
    for (int i = 0; i < months; i++) {
      futureValue = (futureValue + monthlyDeposit) * (1 + rate);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Savings goal
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
                  const Icon(Icons.flag_rounded, color: _kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw ? 'Lengo la Akiba' : 'Savings Goal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    color: _kSecondary,
                    onPressed: () => _showSetGoalDialog(sw),
                    tooltip: sw ? 'Weka lengo' : 'Set goal',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'TZS ${_savingsGoalCurrent.toStringAsFixed(0)} / ${_savingsGoalTarget.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 6),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Educational: Why saving matters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: _kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw ? 'Kwa Nini Kuhifadhi ni Muhimu' : 'Why Saving Matters',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sw
                    ? 'Kuhifadhi pesa kunakusaidia kufikia malengo yako ya baadaye. '
                      'Pesa zinazohifadhiwa benki hupata riba — pesa yako inakua!'
                    : 'Saving money helps you reach your future goals. '
                      'Money saved in a bank earns interest — your money grows!',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Interest explanation
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
                  const Icon(Icons.calculate_rounded,
                      color: _kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw ? 'Nguvu ya Riba' : 'Power of Interest',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sw
                    ? 'Ukihifadhi TZS 10,000 kwa mwezi kwa miaka 5 (riba 6%):'
                    : 'If you save TZS 10,000/month for 5 years (6% interest):',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      sw ? 'Umetoa' : 'You put in',
                      'TZS ${(monthlyDeposit * months).toStringAsFixed(0)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStat(
                      sw ? 'Utapata' : 'You get',
                      'TZS ${futureValue.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showSetGoalDialog(bool sw) {
    final targetCtrl =
        TextEditingController(text: _savingsGoalTarget.toStringAsFixed(0));
    final currentCtrl =
        TextEditingController(text: _savingsGoalCurrent.toStringAsFixed(0));
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          sw ? 'Weka Lengo la Akiba' : 'Set Savings Goal',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: sw ? 'Lengo (TZS)' : 'Target (TZS)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: sw ? 'Kiasi cha sasa (TZS)' : 'Current amount (TZS)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final target = double.tryParse(targetCtrl.text) ?? 0;
              final current = double.tryParse(currentCtrl.text) ?? 0;
              setState(() {
                _savingsGoalTarget = target;
                _savingsGoalCurrent = current;
              });
              _saveValue('savings_target', target);
              _saveValue('savings_current', current);
              Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(sw ? 'Lengo limehifadhiwa' : 'Goal saved'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
  }

  // ─── Spend Tab ───────────────────────────────────────────────

  Widget _buildSpendTab(bool sw) {
    final remaining = _weeklyAllowance - _weeklySpent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Budget overview
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
              Text(
                sw ? 'Bajeti ya Wiki Hii' : 'This Week\'s Budget',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildBudgetItem(
                      sw ? 'Posho' : 'Allowance',
                      'TZS ${_weeklyAllowance.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBudgetItem(
                      sw ? 'Umetumia' : 'Spent',
                      'TZS ${_weeklySpent.toStringAsFixed(0)}',
                      Icons.shopping_cart_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBudgetItem(
                      sw ? 'Imebaki' : 'Left',
                      'TZS ${remaining.toStringAsFixed(0)}',
                      Icons.savings_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showSetAllowanceDialog(sw),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(
                    sw ? 'Weka Posho ya Wiki' : 'Set Weekly Allowance',
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Needs vs Wants education
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sw ? 'Mahitaji dhidi ya Matakwa' : 'Needs vs Wants',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? 'MAHITAJI' : 'NEEDS',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ..._needsList(sw).map((n) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '- $n',
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: _kPrimary.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? 'MATAKWA' : 'WANTS',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ..._wantsList(sw).map((w) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '- $w',
                                style: const TextStyle(
                                    fontSize: 12, color: _kSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Log spending button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showLogSpendingDialog(sw),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              sw ? 'Rekodi Matumizi' : 'Log Spending',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
        const SizedBox(height: 16),

        // Spending log
        if (_spendingEntries.isNotEmpty) ...[
          Text(
            sw ? 'Matumizi' : 'Spending Log',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ..._spendingEntries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry['description'] as String? ?? '',
                        style:
                            const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'TZS ${entry['amount'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBudgetItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kPrimary, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<String> _needsList(bool sw) => sw
      ? ['Chakula', 'Usafiri', 'Vifaa vya shule', 'Dawa']
      : ['Food', 'Transport', 'School supplies', 'Medicine'];

  List<String> _wantsList(bool sw) => sw
      ? ['Vitafunio', 'Michezo', 'Mavazi ya mtindo', 'Burudani']
      : ['Snacks', 'Games', 'Fashion clothes', 'Entertainment'];

  void _showSetAllowanceDialog(bool sw) {
    final ctrl =
        TextEditingController(text: _weeklyAllowance.toStringAsFixed(0));
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          sw ? 'Weka Posho ya Wiki' : 'Set Weekly Allowance',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text) ?? 0;
              setState(() {
                _weeklyAllowance = amount;
                _weeklySpent = 0;
              });
              _saveValue('weekly_allowance', amount);
              _saveValue('weekly_spent', 0);
              Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content:
                      Text(sw ? 'Posho imehifadhiwa' : 'Allowance saved'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showLogSpendingDialog(bool sw) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          sw ? 'Rekodi Matumizi' : 'Log Spending',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo' : 'Description',
                hintText: sw ? 'Mfano: Usafiri' : 'e.g. Transport',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              final desc = descCtrl.text.trim();
              if (amount <= 0) return;

              Navigator.pop(ctx);

              setState(() {
                _weeklySpent += amount;
                _spendingEntries.add({
                  'amount': amount.toStringAsFixed(0),
                  'description': desc.isNotEmpty ? desc : (sw ? 'Matumizi' : 'Spending'),
                });
              });
              _saveValue('weekly_spent', _weeklySpent);

              // Log to child's allowance via API
              if (_token != null) {
                _service.logAllowance(
                  token: _token!,
                  childId: widget.child.id,
                  amount: amount,
                  type: 'spent',
                  description: desc.isNotEmpty ? desc : null,
                ).then((_) {}).catchError((_) {});
              }

              messenger.showSnackBar(SnackBar(
                content: Text(sw
                    ? 'Matumizi yamerekodiwa: TZS ${amount.toStringAsFixed(0)}'
                    : 'Spending logged: TZS ${amount.toStringAsFixed(0)}'),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
  }

  // ─── Give Tab ────────────────────────────────────────────────

  Widget _buildGiveTab(bool sw) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Charity tracking
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
                    child: const Icon(Icons.volunteer_activism_rounded,
                        color: _kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? 'Sadaka na Misaada' : 'Charity & Giving',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'TZS ${_charityTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddCharityDialog(sw),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    sw ? 'Ongeza Mchango' : 'Add Contribution',
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Volunteer hours tracking
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
                    child: const Icon(Icons.schedule_rounded,
                        color: _kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? 'Masaa ya Kujitolea' : 'Volunteer Hours',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_totalVolunteerHours.toStringAsFixed(1)} ${sw ? 'masaa jumla' : 'total hours'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Recent volunteer logs
              if (_volunteerLogs.isNotEmpty) ...[
                ..._volunteerLogs.reversed.take(5).map((log) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: _kSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${log['activity'] ?? ''} — ${log['organization'] ?? ''}',
                            style: const TextStyle(fontSize: 13, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${log['hours'] ?? 0}h',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddVolunteerDialog(sw),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    sw ? 'Sajili Masaa ya Kujitolea' : 'Log Volunteer Hours',
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Educational content
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: _kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw ? 'Kusaidia Wengine' : 'Helping Others',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sw
                    ? 'Kutoa si lazima iwe pesa tu. Unaweza kutoa muda wako, '
                      'ujuzi wako, au msaada kwa wengine. Kila mchango, hata mdogo, '
                      'unaleta tofauti kubwa.'
                    : 'Giving doesn\'t have to be just money. You can give your time, '
                      'your skills, or support to others. Every contribution, even small, '
                      'makes a big difference.',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                sw ? 'Njia za kutoa:' : 'Ways to give:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              ..._givingWays(sw).map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: _kPrimary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            w,
                            style: const TextStyle(
                                fontSize: 13, color: _kPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<String> _givingWays(bool sw) => sw
      ? [
          'Sadaka msikitini au kanisani',
          'Kusaidia jirani mzee',
          'Kusafisha mazingira',
          'Kuchangia michango ya shule',
          'Kufundisha mtoto mdogo',
        ]
      : [
          'Religious offerings (sadaka)',
          'Helping elderly neighbors',
          'Community cleanup',
          'Contributing to school funds',
          'Tutoring a younger child',
        ];

  void _showAddVolunteerDialog(bool sw) {
    final activityCtrl = TextEditingController();
    final hoursCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    DateTime logDate = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            sw ? 'Sajili Masaa ya Kujitolea' : 'Log Volunteer Hours',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: activityCtrl,
                  decoration: InputDecoration(
                    labelText: sw ? 'Shughuli' : 'Activity Name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hoursCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: sw ? 'Masaa' : 'Hours',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orgCtrl,
                  decoration: InputDecoration(
                    labelText: sw ? 'Shirika' : 'Organization',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: logDate,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => logDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: _kSecondary),
                        const SizedBox(width: 8),
                        Text(
                          '${logDate.day}/${logDate.month}/${logDate.year}',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(sw ? 'Ghairi' : 'Cancel',
                  style: const TextStyle(color: _kSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final hours = double.tryParse(hoursCtrl.text) ?? 0;
                final activity = activityCtrl.text.trim();
                if (hours > 0 && activity.isNotEmpty) {
                  final entry = <String, dynamic>{
                    'activity': activity,
                    'hours': hours,
                    'organization': orgCtrl.text.trim(),
                    'date': logDate.toIso8601String(),
                  };
                  setState(() {
                    _volunteerLogs.add(entry);
                    _totalVolunteerHours += hours;
                  });
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final key = 'financial_${widget.child.id}';
                    await prefs.setString(
                      '${key}_volunteer_logs',
                      jsonEncode(_volunteerLogs),
                    );
                  } catch (_) {}
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(sw
                          ? 'Masaa ya kujitolea yamehifadhiwa'
                          : 'Volunteer hours saved'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text(sw ? 'Hifadhi' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCharityDialog(bool sw) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          sw ? 'Ongeza Mchango' : 'Add Contribution',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo' : 'Description',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount > 0) {
                setState(() => _charityTotal += amount);
                _saveValue('charity_total', _charityTotal);
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        sw ? 'Mchango umehifadhiwa' : 'Contribution saved'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Classes ──────────────────────────────────────────────

class _JobIdea {
  final IconData icon;
  final String title;
  final String description;
  const _JobIdea({
    required this.icon,
    required this.title,
    required this.description,
  });
}
