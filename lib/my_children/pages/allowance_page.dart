// lib/my_children/pages/allowance_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/wallet_service.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';
import '../services/my_children_service.dart';
import 'financial_literacy_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AllowancePage extends StatefulWidget {
  final Child child;
  final int userId;

  const AllowancePage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<AllowancePage> createState() => _AllowancePageState();
}

class _AllowancePageState extends State<AllowancePage> {
  final MyChildrenService _service = MyChildrenService();
  final WalletService _walletService = WalletService();

  bool _isLoading = true;
  AllowanceBalance? _balance;
  List<AllowanceTransaction> _transactions = [];
  String? _token;

  // Wallet integration
  double? _parentWalletBalance;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
    _loadParentWallet();
  }

  /// Fire-and-forget: load parent's wallet balance
  Future<void> _loadParentWallet() async {
    try {
      final result = await _walletService.getWallet(widget.userId);
      if (!mounted) return;
      if (result.success && result.wallet != null) {
        setState(() => _parentWalletBalance = result.wallet!.balance);
      }
    } catch (_) {
      // Wallet fetch is best-effort
    }
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getAllowanceBalance(_token!, widget.child.id),
        _service.getAllowanceHistory(_token!, widget.child.id),
      ]);

      if (!mounted) return;

      final balResult = results[0] as MyBabyResult<AllowanceBalance>;
      final txResult = results[1] as MyBabyListResult<AllowanceTransaction>;

      setState(() {
        _isLoading = false;
        if (balResult.success) _balance = balResult.data;
        if (txResult.success) _transactions = txResult.items;
      });
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
          sw ? 'Posho' : 'Allowance',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.remove_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_parentWalletBalance != null) ...[
                      _buildParentWalletCard(sw),
                      const SizedBox(height: 16),
                    ],
                    _buildBalanceCard(sw),
                    const SizedBox(height: 16),
                    _buildBreakdownRow(sw),
                    const SizedBox(height: 16),
                    _buildSendToChildCard(sw),
                    const SizedBox(height: 16),
                    _buildPieChart(sw),
                    const SizedBox(height: 16),
                    _buildTransactionHistory(sw),
                    const SizedBox(height: 16),
                    _buildMonthlyTrend(sw),
                    const SizedBox(height: 16),
                    _buildSpendingInsights(sw),
                    const SizedBox(height: 16),
                    _buildTajiriPayCard(sw),

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
                      icon: Icons.shopping_bag_rounded,
                      label: sw
                          ? '${widget.child.name} anaweza kununua nini kwa TZS ${(_balance?.balance ?? 0).toStringAsFixed(0)}?'
                          : 'What can ${widget.child.name} buy with TZS ${(_balance?.balance ?? 0).toStringAsFixed(0)}?',
                      onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.school_rounded,
                      label: sw
                          ? 'Elimu ya Fedha'
                          : 'Financial Literacy',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => FinancialLiteracyPage(child: widget.child, userId: widget.userId))),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
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

  /// Parent's wallet balance (read-only)
  Widget _buildParentWalletCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 22, color: _kSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Salio la Pochi Yako' : 'Your Wallet Balance',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'TZS ${_formatMoney(_parentWalletBalance ?? 0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Send to Child's Phone" card — opens a pre-filled transfer dialog
  Widget _buildSendToChildCard(bool sw) {
    return GestureDetector(
      onTap: _showTransferToChildDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.send_rounded, color: _kPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Tuma kwa Simu ya Mtoto' : "Send to Child's Phone",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sw ? 'Hamisha pesa kutoka pochi yako' : 'Transfer from your wallet',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  void _showTransferToChildDialog() {
    final sw = _sw;
    final amountCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sw ? 'Tuma kwa ${widget.child.name}' : 'Send to ${widget.child.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              if (_parentWalletBalance != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${sw ? "Salio" : "Balance"}: TZS ${_formatMoney(_parentWalletBalance!)}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: sw ? 'Nambari ya Simu ya Mtoto' : "Child's Phone Number",
                  hintText: '0712345678',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
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
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: sw ? 'PIN ya Pochi' : 'Wallet PIN',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    final phone = phoneCtrl.text.trim();
                    final pin = pinCtrl.text.trim();
                    if (amount == null || amount <= 0 || phone.isEmpty || pin.isEmpty) return;
                    Navigator.of(ctx).pop();
                    _executeTransferToChild(phone, amount, pin);
                  },
                  child: Text(sw ? 'Tuma' : 'Send'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeTransferToChild(String phone, double amount, String pin) async {
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    try {
      final result = await _walletService.transfer(
        userId: widget.userId,
        recipientPhone: phone,
        amount: amount,
        pin: pin,
        description: '${sw ? "Posho kwa" : "Allowance for"} ${widget.child.name}',
        budgetCategory: 'watoto',
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(SnackBar(content: Text(sw ? 'Pesa zimetumwa' : 'Transfer successful')));
        _loadParentWallet(); // Refresh balance
      } else {
        messenger.showSnackBar(SnackBar(content: Text(result.message ?? (sw ? 'Imeshindikana' : 'Transfer failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')));
    }
  }

  Widget _buildBalanceCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            sw ? 'Salio la Posho' : 'Allowance Balance',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'TZS ${_formatMoney(_balance?.balance ?? 0)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(bool sw) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            sw ? 'Kilichopatikana' : 'Earned',
            _balance?.totalEarned ?? 0,
            Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniCard(
            sw ? 'Kilichotumika' : 'Spent',
            _balance?.totalSpent ?? 0,
            Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniCard(
            sw ? 'Kilichohifadhiwa' : 'Saved',
            _balance?.totalSaved ?? 0,
            Icons.savings_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard(String label, double amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: _kSecondary),
          const SizedBox(height: 4),
          Text(
            _formatMoney(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(bool sw) {
    final earned = _balance?.totalEarned ?? 0;
    final spent = _balance?.totalSpent ?? 0;
    final saved = _balance?.totalSaved ?? 0;
    final total = earned + spent + saved;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Muhtasari' : 'Summary',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Simple bar chart representation
          _buildBar(sw ? 'Kilichopatikana' : 'Earned', earned, total,
              _kPrimary),
          const SizedBox(height: 8),
          _buildBar(sw ? 'Kilichotumika' : 'Spent', spent, total,
              Colors.grey.shade600),
          const SizedBox(height: 8),
          _buildBar(sw ? 'Kilichohifadhiwa' : 'Saved', saved, total,
              Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double value, double total, Color color) {
    final fraction = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            Text('${(fraction * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory(bool sw) {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          sw ? 'Hakuna muamala bado' : 'No transactions yet',
          style: const TextStyle(fontSize: 14, color: _kSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Historia ya Muamala' : 'Transaction History',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._transactions.map((tx) {
          final isIncome = tx.type == 'earned' || tx.type == 'given';
          final dateStr =
              '${tx.date.day}/${tx.date.month}/${tx.date.year}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onLongPress: () => _confirmDeleteAllowance(
                  tx.id, tx.description ?? tx.type),
              child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description ?? tx.type,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? "+" : "-"} TZS ${tx.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _confirmDeleteAllowance(int id, String label) {
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
                final result =
                    await _service.deleteAllowance(_token!, id);
                if (!mounted) return;
                if (result.success) {
                  _loadData();
                  messenger.showSnackBar(SnackBar(
                    content: Text(
                        sw ? 'Muamala umefutwa' : 'Transaction deleted'),
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

  Widget _buildMonthlyTrend(bool sw) {
    if (_transactions.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    // Last 3 months
    final months = <DateTime>[];
    for (int i = 2; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    final monthNames = sw
        ? ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final rows = <Widget>[];
    for (final month in months) {
      final nextMonth = DateTime(month.year, month.month + 1, 1);
      final monthTx = _transactions.where((tx) {
        return tx.date.isAfter(month.subtract(const Duration(days: 1))) &&
            tx.date.isBefore(nextMonth);
      }).toList();

      final earned = monthTx
          .where((tx) => tx.type == 'earned' || tx.type == 'given')
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      final spent = monthTx
          .where((tx) => tx.type == 'spent')
          .fold<double>(0, (sum, tx) => sum + tx.amount);

      final label = '${monthNames[month.month - 1]} ${month.year}';

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${sw ? "Pato" : "In"}: ${_formatMoney(earned)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${sw ? "Matumizi" : "Out"}: ${_formatMoney(spent)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

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
              const Icon(Icons.calendar_month_rounded, size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw ? 'Mwenendo wa Miezi' : 'Monthly Trend',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildSpendingInsights(bool sw) {
    final earned = _balance?.totalEarned ?? 0;
    final spent = _balance?.totalSpent ?? 0;
    final saved = _balance?.totalSaved ?? 0;

    if (earned == 0 && spent == 0 && saved == 0) return const SizedBox.shrink();

    // Savings rate
    final savingsRate = earned > 0 ? (saved / earned * 100).round() : 0;

    // Weekly spending from transactions
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekTransactions = _transactions.where((tx) {
      return tx.date.isAfter(weekStart) || tx.date.isAtSameMomentAs(weekStart);
    }).toList();
    final weekEarned = weekTransactions
        .where((tx) => tx.type == 'earned' || tx.type == 'given')
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final weekSpent = weekTransactions
        .where((tx) => tx.type == 'spent')
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded,
                    size: 18, color: _kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw ? 'Muhtasari wa Matumizi' : 'Spending Insights',
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
          const SizedBox(height: 14),

          // Savings Rate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: savingsRate >= 20
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.06)
                  : Colors.orange.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  savingsRate >= 20
                      ? Icons.trending_up_rounded
                      : Icons.trending_flat_rounded,
                  size: 20,
                  color: savingsRate >= 20
                      ? const Color(0xFF2E7D32)
                      : Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sw ? 'Kiwango cha Akiba' : 'Savings Rate',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                      ),
                      Text(
                        '$savingsRate%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: savingsRate >= 20
                              ? const Color(0xFF2E7D32)
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                // Visual progress
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (savingsRate / 100).clamp(0, 1),
                        strokeWidth: 4,
                        backgroundColor: Colors.grey.shade200,
                        color: savingsRate >= 20
                            ? const Color(0xFF2E7D32)
                            : Colors.orange,
                      ),
                      Icon(
                        Icons.savings_rounded,
                        size: 18,
                        color: savingsRate >= 20
                            ? const Color(0xFF2E7D32)
                            : Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // This week summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Wiki Hii' : 'This Week',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sw ? 'Kilichopatikana' : 'Earned',
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                          ),
                          Text(
                            'TZS ${_formatMoney(weekEarned)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sw ? 'Kilichotumika' : 'Spent',
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                          ),
                          Text(
                            'TZS ${_formatMoney(weekSpent)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTajiriPayCard(bool sw) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Tajiri Pay inakuja hivi karibuni' : 'Tajiri Pay coming soon')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: _kPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw
                        ? 'Unganisha na Tajiri Pay'
                        : 'Connect to Tajiri Pay',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sw
                        ? 'Mtoto akiwa tayari, unganisha posho yake na Tajiri Pay'
                        : 'When your child is ready, connect their allowance to Tajiri Pay',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog() {
    final sw = _sw;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sw ? 'Ongeza Matumizi' : 'Add Expense',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
              const SizedBox(height: 16),
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
                    final amount =
                        double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    _submitExpense(
                        ctx, amount, descCtrl.text.trim());
                  },
                  child: Text(sw ? 'Hifadhi' : 'Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitExpense(
      BuildContext ctx, double amount, String desc) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(ctx).pop();

    try {
      final result = await _service.logAllowance(
        token: _token!,
        childId: widget.child.id,
        amount: amount,
        type: 'spent',
        description: desc.isNotEmpty ? desc : null,
      );
      if (!mounted) return;
      if (result.success) {
        _loadData();
        messenger.showSnackBar(
          SnackBar(
            content:
                Text(_sw ? 'Matumizi yameongezwa' : 'Expense added'),
          ),
        );
        // Fire-and-forget: report allowance given as parent expenditure
        if (_token != null) {
          ExpenditureService.recordExpenditure(
            token: _token!,
            amount: amount,
            category: 'watoto',
            description: 'Child expense: ${widget.child.name} — allowance: ${desc.isNotEmpty ? desc : "manual"}',
            referenceId: 'child_expense_${widget.child.id}_${DateTime.now().millisecondsSinceEpoch}',
            sourceModule: 'my_children',
          ).catchError((_) => null);
        }
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

  String _formatMoney(double amount) {
    final s = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
