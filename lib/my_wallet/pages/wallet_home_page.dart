// lib/my_wallet/pages/wallet_home_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/earnings_summary_card.dart';
import 'deposit_page.dart';
import 'withdraw_page.dart';
import 'transfer_page.dart';
import 'transactions_page.dart';
import 'earnings_page.dart';
import 'payment_requests_page.dart';
import 'mobile_accounts_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class WalletHomePage extends StatefulWidget {
  final int userId;
  final Wallet wallet;
  final String authToken;

  const WalletHomePage({
    super.key,
    required this.userId,
    required this.wallet,
    required this.authToken,
  });

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  final WalletService _walletService = WalletService();
  late Wallet _wallet;
  List<WalletTransaction> _recentTransactions = [];
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
    _loadRecentTransactions();
  }

  Future<void> _refresh() async {
    try {
      final result = await _walletService.getWallet(widget.userId);
      if (mounted && result.success && result.wallet != null) {
        setState(() => _wallet = result.wallet!);
      }
      await _loadRecentTransactions();
    } catch (_) {
      // Silently handle refresh errors
    }
  }

  Future<void> _loadRecentTransactions() async {
    if (_isLoadingTransactions) return;
    setState(() => _isLoadingTransactions = true);

    try {
      final result = await _walletService.getTransactions(
        userId: widget.userId,
        page: 1,
        perPage: 5,
      );

      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
          if (result.success) {
            _recentTransactions = result.transactions;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  void _navigateAndRefresh(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Tajiri Pay',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: _kPrimary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Balance card
              BalanceCard(
                wallet: _wallet,
                onTapDetails: () => _navigateAndRefresh(
                  TransactionsPage(userId: widget.userId),
                ),
              ),
              const SizedBox(height: 20),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.add_rounded,
                      label: isSwahili ? 'Ingiza' : 'Deposit',
                      subtitle: isSwahili ? 'Deposit' : 'Ingiza',
                      onTap: () => _navigateAndRefresh(
                        DepositPage(userId: widget.userId),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.arrow_upward_rounded,
                      label: isSwahili ? 'Toa' : 'Withdraw',
                      subtitle: isSwahili ? 'Withdraw' : 'Toa',
                      onTap: () => _navigateAndRefresh(
                        WithdrawPage(userId: widget.userId, wallet: _wallet),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.send_rounded,
                      label: isSwahili ? 'Tuma' : 'Transfer',
                      subtitle: isSwahili ? 'Transfer' : 'Tuma',
                      onTap: () => _navigateAndRefresh(
                        TransferPage(userId: widget.userId, wallet: _wallet),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Services row
              Row(
                children: [
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.receipt_long_rounded,
                      label: isSwahili ? 'Maombi' : 'Requests',
                      subtitle: isSwahili ? 'Requests' : 'Maombi',
                      onTap: () => _navigateAndRefresh(
                        PaymentRequestsPage(userId: widget.userId),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.phone_android_rounded,
                      label: isSwahili ? 'Akaunti' : 'Accounts',
                      subtitle: isSwahili ? 'Accounts' : 'Akaunti',
                      onTap: () => _navigateAndRefresh(
                        MobileAccountsPage(userId: widget.userId),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.trending_up_rounded,
                      label: isSwahili ? 'Mapato' : 'Earnings',
                      subtitle: isSwahili ? 'Earnings' : 'Mapato',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EarningsPage(userId: widget.userId),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Earnings summary
              EarningsSummaryCard(userId: widget.userId),
              const SizedBox(height: 24),

              // Recent transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSwahili ? 'Miamala ya Hivi Karibuni' : 'Recent Transactions',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => _navigateAndRefresh(
                      TransactionsPage(userId: widget.userId),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Text(
                        isSwahili ? 'Ona Zote' : 'View All',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoadingTransactions && _recentTransactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                  ),
                )
              else if (_recentTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        isSwahili ? 'Hakuna miamala bado' : 'No transactions yet',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_recentTransactions.length, (index) {
                  return TransactionTile(transaction: _recentTransactions[index]);
                }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: _kSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
