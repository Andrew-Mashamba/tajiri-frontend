import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';
import '../../services/biometric_service.dart';
import '../../services/wallet_service.dart';
import 'subscription_tiers_setup_screen.dart';
import 'my_subscriptions_screen.dart';
import 'earnings_dashboard_screen.dart';

class WalletScreen extends StatefulWidget {
  final int currentUserId;

  const WalletScreen({super.key, required this.currentUserId});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  bool _showBalance = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final walletResult = await _walletService.getWallet(widget.currentUserId);
    final transResult = await _walletService.getTransactions(
      userId: widget.currentUserId,
      perPage: 10,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (walletResult.success) _wallet = walletResult.wallet;
        if (transResult.success) _transactions = transResult.transactions;
      });
    }
  }

  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Tajiri Pay'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showTransactionHistory(),
            tooltip: 'Historia ya miamala',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showWalletSettings(),
            tooltip: 'Mipangilio',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _wallet == null
                ? _buildErrorState()
                : RefreshIndicator(
                onRefresh: _loadData,
                color: _primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildBalanceCard(),
                        _buildMySubscriptionsCard(),
                        _buildCreatorEarningsCard(),
                        _buildCreatorSubscriptionCard(),
                        _buildQuickActions(),
                        _buildRecentTransactions(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 48, color: _accent),
            const SizedBox(height: 16),
            Text(
              'Imeshindwa kupakia pochi',
              style: const TextStyle(color: _primary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _loadData,
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Salio Lako',
                style: TextStyle(color: _secondary, fontSize: 14),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (mounted) setState(() => _showBalance = !_showBalance);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: _secondary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _showBalance
                ? _wallet?.balanceFormatted ?? 'TZS 0'
                : '••••••••',
            style: const TextStyle(
              color: _primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (_wallet != null && _wallet!.pendingBalance > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Inasubiri: ${_wallet!.pendingFormatted}',
              style: const TextStyle(color: _secondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
          if (!(_wallet?.hasPin ?? false)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: _primary),
                  SizedBox(width: 6),
                  Text(
                    'Weka PIN',
                    style: TextStyle(color: _primary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMySubscriptionsCard() {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MySubscriptionsScreen(
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_membership_outlined,
                    color: Color(0xFF22C55E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s?.mySubscriptions ?? 'Usajili Wangu',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        s?.viewYourSubscriptions ?? 'Angalia usajili wako kwa waundaji',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _accent, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorEarningsCard() {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => EarningsDashboardScreen(
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on_outlined,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s?.creatorEarnings ?? 'Mapato ya Maudhui',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        s?.viewYourEarnings ?? 'Angalia mapato na wasajili wako',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _accent, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorSubscriptionCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SubscriptionTiersSetupScreen(
                  creatorId: widget.currentUserId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Viwango vya Usajili',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Unda viwango na faida kwa wafuasi',
                        style: TextStyle(
                          fontSize: 11,
                          color: _secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _accent, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            icon: Icons.add,
            label: 'Ingiza',
            onTap: () => _showDepositSheet(),
          ),
          _buildActionButton(
            icon: Icons.arrow_upward,
            label: 'Toa',
            onTap: () => _showWithdrawSheet(),
          ),
          _buildActionButton(
            icon: Icons.send,
            label: 'Tuma',
            onTap: () => _showTransferSheet(),
          ),
          _buildActionButton(
            icon: Icons.request_page,
            label: 'Omba',
            onTap: () => _showRequestSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Miamala ya Hivi Karibuni',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
            TextButton(
              onPressed: () => _showTransactionHistory(),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: _primary,
              ),
              child: const Text('Ona zote'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: _accent),
                const SizedBox(height: 8),
                const Text(
                  'Hakuna miamala bado',
                  style: TextStyle(color: _secondary, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...(_transactions.take(5).map((t) => _buildTransactionTile(t))),
      ],
    );
  }

  Widget _buildTransactionTile(WalletTransaction transaction) {
    final isCredit = transaction.isCredit;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 48,
      leading: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: _primary,
          size: 20,
        ),
      ),
      title: Text(
        transaction.typeName,
        style: const TextStyle(color: _primary, fontSize: 14),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Text(
        transaction.description ?? transaction.providerName,
        style: const TextStyle(color: _secondary, fontSize: 12),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isCredit ? '+' : '-'} TZS ${transaction.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            _formatDate(transaction.createdAt),
            style: const TextStyle(color: _secondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Leo ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDepositSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DepositSheet(
        userId: widget.currentUserId,
        onSuccess: _loadData,
      ),
    );
  }

  void _showWithdrawSheet() {
    if (!(_wallet?.hasPin ?? false)) {
      _showSetPinFirst();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WithdrawSheet(
        userId: widget.currentUserId,
        balance: _wallet?.balance ?? 0,
        onSuccess: _loadData,
      ),
    );
  }

  void _showTransferSheet() {
    if (!(_wallet?.hasPin ?? false)) {
      _showSetPinFirst();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TransferSheet(
        userId: widget.currentUserId,
        balance: _wallet?.balance ?? 0,
        onSuccess: _loadData,
      ),
    );
  }

  void _showRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RequestPaymentSheet(
        userId: widget.currentUserId,
        onSuccess: _loadData,
      ),
    );
  }

  void _showSetPinFirst() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weka PIN Kwanza'),
        content: const Text('Unahitaji kuweka PIN ya pochi yako kwanza ili kufanya muamala huu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Baadaye'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSetPinDialog();
            },
            child: const Text('Weka PIN'),
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weka PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN (tarakimu 4)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Thibitisha PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () async {
              if (pinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN lazima iwe tarakimu 4')),
                );
                return;
              }
              if (pinController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN hazifanani')),
                );
                return;
              }

              final result = await _walletService.setPin(
                userId: widget.currentUserId,
                pin: pinController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message ?? 'PIN imewekwa')),
                );
                if (result.success) _loadData();
              }
            },
            child: const Text('Weka'),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen(userId: widget.currentUserId),
      ),
    );
  }

  void _showWalletSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Viwango vya Usajili'),
              subtitle: const Text('Unda/usimamishe viwango vya usajili'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SubscriptionTiersSetupScreen(
                      creatorId: widget.currentUserId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('Badilisha PIN'),
              onTap: () {
                Navigator.pop(context);
                _showSetPinDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Akaunti za Simu'),
              onTap: () {
                Navigator.pop(context);
                _showMobileAccounts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Maombi ya Malipo'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to payment requests
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileAccounts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MobileAccountsScreen(userId: widget.currentUserId),
      ),
    );
  }
}

// ============== DEPOSIT SHEET ==============
class _DepositSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onSuccess;

  const _DepositSheet({required this.userId, required this.onSuccess});

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final WalletService _walletService = WalletService();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  String _provider = 'mpesa';
  bool _isLoading = false;

  static const Color _primary = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingiza Pesa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'M-Pesa, Tigo Pesa, Airtel Money (ClickPesa)',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kiasi (TZS)',
                  border: OutlineInputBorder(),
                  prefixText: 'TZS ',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chagua Mtoa Huduma',
                style: TextStyle(fontSize: 14, color: _primary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildProviderChip('mpesa', 'M-Pesa'),
                  const SizedBox(width: 8),
                  _buildProviderChip('tigopesa', 'Tigo Pesa'),
                  const SizedBox(width: 8),
                  _buildProviderChip('airtelmoney', 'Airtel Money'),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Namba ya Simu',
                  border: OutlineInputBorder(),
                  hintText: '0712345678',
                ),
              ),
              const SizedBox(height: 24),
              _buildPrimaryButton(
                label: 'Ingiza',
                onPressed: _isLoading ? null : _deposit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderChip(String value, String label) {
    final isSelected = _provider == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1A1A1A),
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        if (selected) setState(() => _provider = value);
      },
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      showCheckmark: true,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _deposit() async {
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kuweka pesa',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiasi cha chini ni TZS 1,000')),
      );
      return;
    }

    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza namba sahihi ya simu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _walletService.deposit(
      userId: widget.userId,
      amount: amount,
      provider: _provider,
      phoneNumber: _phoneController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      widget.onSuccess();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ombi limetumwa. Utapokea ujumbe wa kuthibitisha.')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa')),
      );
    }
  }
}

// ============== WITHDRAW SHEET ==============
class _WithdrawSheet extends StatefulWidget {
  final int userId;
  final double balance;
  final VoidCallback onSuccess;

  const _WithdrawSheet({required this.userId, required this.balance, required this.onSuccess});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final WalletService _walletService = WalletService();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  String _provider = 'mpesa';
  bool _isLoading = false;

  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toa Pesa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Salio: TZS ${widget.balance.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: _secondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'M-Pesa, Tigo Pesa, Airtel Money (ClickPesa)',
                style: TextStyle(fontSize: 12, color: _secondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kiasi (TZS)',
                  border: OutlineInputBorder(),
                  prefixText: 'TZS ',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Chagua Mtoa Huduma', style: TextStyle(fontSize: 14, color: _primary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildProviderChip('mpesa', 'M-Pesa'),
                  const SizedBox(width: 8),
                  _buildProviderChip('tigopesa', 'Tigo Pesa'),
                  const SizedBox(width: 8),
                  _buildProviderChip('airtelmoney', 'Airtel Money'),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Namba ya Simu',
                  border: OutlineInputBorder(),
                  hintText: '0712345678',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  child: InkWell(
                    onTap: _isLoading ? null : _withdraw,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                            )
                          : const Text(
                              'Toa',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primary),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _provider == value,
      selectedColor: _primary,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        if (selected) setState(() => _provider = value);
      },
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      showCheckmark: true,
    );
  }

  Future<void> _withdraw() async {
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kutoa pesa',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiasi cha chini ni TZS 5,000')),
      );
      return;
    }

    if (amount > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salio halitoshi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _walletService.withdraw(
      userId: widget.userId,
      amount: amount,
      provider: _provider,
      phoneNumber: _phoneController.text,
      pin: _pinController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      widget.onSuccess();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uondoaji umekamilika')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa')),
      );
    }
  }
}

// ============== TRANSFER SHEET (P2P) ==============
class _TransferSheet extends StatefulWidget {
  final int userId;
  final double balance;
  final VoidCallback onSuccess;

  const _TransferSheet({required this.userId, required this.balance, required this.onSuccess});

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);

  final WalletService _walletService = WalletService();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _pinController = TextEditingController();
  final _descController = TextEditingController();

  /// true = by user ID, false = by phone number
  bool _recipientByUserId = true;
  bool _isLoading = false;
  double _fee = 0;

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _pinController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tuma Pesa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Salio: TZS ${widget.balance.toStringAsFixed(0)}',
              style: const TextStyle(color: _secondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            // Recipient type: User ID or Phone (min touch 48dp)
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: _recipientByUserId ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _recipientByUserId = true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Kwa ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _recipientByUserId ? Colors.white : _primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: !_recipientByUserId ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    child: InkWell(
                      onTap: () => setState(() => _recipientByUserId = false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Kwa Simu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !_recipientByUserId ? Colors.white : _primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientController,
              keyboardType: _recipientByUserId ? TextInputType.number : TextInputType.phone,
              decoration: InputDecoration(
                labelText: _recipientByUserId ? 'ID ya Mpokeaji' : 'Namba ya Simu ya Mpokeaji',
                border: const OutlineInputBorder(),
                hintText: _recipientByUserId ? 'Ingiza ID ya mtumiaji' : '07XXXXXXXX',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateFee(),
              decoration: InputDecoration(
                labelText: 'Kiasi (TZS)',
                border: const OutlineInputBorder(),
                prefixText: 'TZS ',
                helperText: _fee > 0 ? 'Ada: TZS ${_fee.toStringAsFixed(0)}' : null,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Maelezo (hiari)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Thibitisha PIN (tarakimu 4)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Button: DESIGN.md min height 72, full width
            SizedBox(
              width: double.infinity,
              child: Container(
                constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  child: InkWell(
                    onTap: _isLoading ? null : _transfer,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                            )
                          : const Text(
                              'Tuma',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _calculateFee() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _fee = 0);
      return;
    }

    final result = await _walletService.calculateFee(amount: amount, type: 'transfer');
    if (result.success) {
      setState(() => _fee = result.fee);
    }
  }

  Future<void> _transfer() async {
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kutuma pesa',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountController.text);
    final recipientText = _recipientController.text.trim();

    if (recipientText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_recipientByUserId ? 'Ingiza ID ya mpokeaji' : 'Ingiza namba ya simu ya mpokeaji'),
        ),
      );
      return;
    }

    if (_recipientByUserId && int.tryParse(recipientText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID ya mpokeaji lazima iwe namba')),
      );
      return;
    }

    if (amount == null || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiasi cha chini ni TZS 100')),
      );
      return;
    }

    if (amount + _fee > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salio halitoshi (pamoja na ada)')),
      );
      return;
    }

    final pin = _pinController.text;
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza PIN sahihi (tarakimu 4)')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await _walletService.transfer(
      userId: widget.userId,
      recipientId: _recipientByUserId ? int.tryParse(recipientText) : null,
      recipientPhone: _recipientByUserId ? null : recipientText,
      amount: amount,
      pin: pin,
      description: _descController.text.isEmpty ? null : _descController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      widget.onSuccess();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesa imetumwa!')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa')),
        );
      }
    }
  }
}

// ============== REQUEST PAYMENT SHEET ==============
class _RequestPaymentSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onSuccess;

  const _RequestPaymentSheet({required this.userId, required this.onSuccess});

  @override
  State<_RequestPaymentSheet> createState() => _RequestPaymentSheetState();
}

class _RequestPaymentSheetState extends State<_RequestPaymentSheet> {
  final WalletService _walletService = WalletService();
  final _amountController = TextEditingController();
  final _payerController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Omba Malipo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _payerController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ID ya Mlipaji',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kiasi (TZS)',
              border: OutlineInputBorder(),
              prefixText: 'TZS ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Sababu (hiari)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _request,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Tuma Ombi'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _request() async {
    final amount = double.tryParse(_amountController.text);
    final payerId = int.tryParse(_payerController.text);

    if (payerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza ID sahihi ya mlipaji')),
      );
      return;
    }

    if (amount == null || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiasi cha chini ni TZS 100')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _walletService.createPaymentRequest(
      userId: widget.userId,
      payerId: payerId,
      amount: amount,
      description: _descController.text.isEmpty ? null : _descController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      widget.onSuccess();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ombi limetumwa!')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa')),
      );
    }
  }
}

// ============== TRANSACTION HISTORY SCREEN ==============
class TransactionHistoryScreen extends StatefulWidget {
  final int userId;

  const TransactionHistoryScreen({super.key, required this.userId});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final WalletService _walletService = WalletService();
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final result = await _walletService.getTransactions(
      userId: widget.userId,
      type: _filterType,
      perPage: 50,
    );

    setState(() {
      _isLoading = false;
      if (result.success) _transactions = result.transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia ya Miamala'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterType = value == 'all' ? null : value);
              _loadTransactions();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Zote')),
              const PopupMenuItem(value: 'deposit', child: Text('Uingizaji')),
              const PopupMenuItem(value: 'withdrawal', child: Text('Uondoaji')),
              const PopupMenuItem(value: 'transfer_in', child: Text('Uliopokea')),
              const PopupMenuItem(value: 'transfer_out', child: Text('Uliotuma')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('Hakuna miamala'))
              : ListView.separated(
                  itemCount: _transactions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = _transactions[index];
                    final isCredit = t.isCredit;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(t.typeName),
                      subtitle: Text('${t.transactionId}\n${t.description ?? t.providerName}'),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? '+' : '-'} TZS ${t.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isCredit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            t.status,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ============== MOBILE ACCOUNTS SCREEN ==============
class MobileAccountsScreen extends StatefulWidget {
  final int userId;

  const MobileAccountsScreen({super.key, required this.userId});

  @override
  State<MobileAccountsScreen> createState() => _MobileAccountsScreenState();
}

class _MobileAccountsScreenState extends State<MobileAccountsScreen> {
  final WalletService _walletService = WalletService();
  List<MobileMoneyAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);

    final result = await _walletService.getMobileAccounts(widget.userId);

    setState(() {
      _isLoading = false;
      if (result.success) _accounts = result.accounts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akaunti za Simu'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wallet_accounts_fab',
        onPressed: () => _showAddAccountDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Hakuna akaunti zilizohifadhiwa'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _showAddAccountDialog(),
                        child: const Text('Ongeza Akaunti'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: const Icon(Icons.phone_android, color: Colors.blue),
                      ),
                      title: Text(account.providerName),
                      subtitle: Text('${account.maskedPhone}\n${account.accountName}'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (account.isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Msingi',
                                style: TextStyle(fontSize: 11, color: Colors.green),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAccount(account.id),
                          ),
                        ],
                      ),
                      onTap: () => _setPrimary(account.id),
                    );
                  },
                ),
    );
  }

  void _showAddAccountDialog() {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    String provider = 'mpesa';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ongeza Akaunti'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: provider,
                decoration: const InputDecoration(
                  labelText: 'Mtoa Huduma',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                  DropdownMenuItem(value: 'tigopesa', child: Text('Tigo Pesa')),
                  DropdownMenuItem(value: 'airtelmoney', child: Text('Airtel Money')),
                  DropdownMenuItem(value: 'halopesa', child: Text('Halo Pesa')),
                ],
                onChanged: (value) {
                  setDialogState(() => provider = value!);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Namba ya Simu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Jina la Akaunti',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            TextButton(
              onPressed: () async {
                final result = await _walletService.addMobileAccount(
                  userId: widget.userId,
                  provider: provider,
                  phoneNumber: phoneController.text,
                  accountName: nameController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (result.success) {
                    _loadAccounts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Akaunti imeongezwa')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.message ?? 'Imeshindwa')),
                    );
                  }
                }
              },
              child: const Text('Ongeza'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(int accountId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Akaunti'),
        content: const Text('Una uhakika unataka kufuta akaunti hii?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hapana')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ndiyo')),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _walletService.deleteMobileAccount(
        userId: widget.userId,
        accountId: accountId,
      );
      if (success) {
        _loadAccounts();
      }
    }
  }

  Future<void> _setPrimary(int accountId) async {
    final success = await _walletService.setPrimaryAccount(
      userId: widget.userId,
      accountId: accountId,
    );
    if (success) {
      _loadAccounts();
    }
  }
}
