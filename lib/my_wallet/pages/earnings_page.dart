// lib/my_wallet/pages/earnings_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EarningsPage extends StatefulWidget {
  final int userId;
  const EarningsPage({super.key, required this.userId});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  bool _isLoading = true;
  EarningsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    try {
      final service = SubscriptionService();
      final result = await service.getEarningsSummary(widget.userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _summary = result.summary;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final s = _summary;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSwahili ? 'Mapato Yangu' : 'My Earnings',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadEarnings,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Total earnings card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSwahili ? 'Jumla ya Mapato (Halisi)' : 'Total Earnings (Net)',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TZS ${_formatAmount(s?.totalNet ?? 0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _MiniStat(
                                label: isSwahili ? 'Inasubiri' : 'Pending',
                                value: 'TZS ${_formatAmount(s?.pending ?? 0)}',
                              ),
                              const SizedBox(width: 16),
                              _MiniStat(
                                label: isSwahili ? 'Mwezi Huu' : 'This Month',
                                value: 'TZS ${_formatAmount(s?.thisMonth ?? 0)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary breakdown
                    Text(
                      isSwahili ? 'Muhtasari' : 'Summary',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                    const SizedBox(height: 12),

                    _EarningSourceCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: isSwahili ? 'Jumla (Ghafi)' : 'Total Gross',
                      subtitle: isSwahili ? 'Total Gross' : 'Jumla (Ghafi)',
                      amount: s?.totalGross ?? 0,
                      formatAmount: _formatAmount,
                    ),
                    _EarningSourceCard(
                      icon: Icons.check_circle_rounded,
                      title: isSwahili ? 'Jumla (Halisi)' : 'Total Net',
                      subtitle: isSwahili ? 'Total Net' : 'Jumla (Halisi)',
                      amount: s?.totalNet ?? 0,
                      formatAmount: _formatAmount,
                    ),
                    _EarningSourceCard(
                      icon: Icons.hourglass_empty_rounded,
                      title: isSwahili ? 'Inasubiri Malipo' : 'Pending Payments',
                      subtitle: isSwahili ? 'Pending' : 'Inasubiri',
                      amount: s?.pending ?? 0,
                      formatAmount: _formatAmount,
                    ),
                    _EarningSourceCard(
                      icon: Icons.calendar_month_rounded,
                      title: isSwahili ? 'Mapato ya Mwezi Huu' : 'This Month Earnings',
                      subtitle: isSwahili ? 'This Month' : 'Mwezi Huu',
                      amount: s?.thisMonth ?? 0,
                      formatAmount: _formatAmount,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EarningSourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final String Function(double) formatAmount;

  const _EarningSourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
          Text(
            'TZS ${formatAmount(amount)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
    );
  }
}
