import 'dart:async';

import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _loading = true;
  bool _annual = false;
  late Timer _shimmerTimer;

  // Current plan index: 0=Free, 1=Pro, 2=Business
  final int _currentPlanIndex = 1;

  final _plans = const [
    _Plan(
      name: 'Free',
      monthlyTzs: 0,
      annualMonthlyTzs: 0,
      description: 'Get started with the basics',
      features: [
        'Up to 10 product listings',
        'Basic shop profile',
        'Standard search placement',
        'Community support',
        'Basic analytics',
      ],
    ),
    _Plan(
      name: 'Pro',
      monthlyTzs: 15000,
      annualMonthlyTzs: 11500,
      description: 'For growing sellers and buyers',
      features: [
        'Unlimited product listings',
        'Featured shop profile',
        'Priority search placement',
        'Email & chat support',
        'Advanced analytics',
        'Verified seller badge',
        'Lower transaction fees (3%)',
      ],
    ),
    _Plan(
      name: 'Business',
      monthlyTzs: 45000,
      annualMonthlyTzs: 34500,
      description: 'For high-volume businesses',
      features: [
        'Everything in Pro',
        'Dedicated account manager',
        'API access & integrations',
        'Custom storefront branding',
        'Lowest transaction fees (1%)',
        'Priority customer support 24/7',
        'Multi-staff account access',
        'Bulk product import/export',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _shimmerTimer.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _formatPrice(int tzs) {
    if (tzs == 0) return 'Free';
    final s = tzs.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TZS ${buf.toString()}';
  }

  int _savingsPercent(int monthly, int annualMonthly) {
    if (monthly == 0) return 0;
    return (((monthly - annualMonthly) / monthly) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Subscription Plans',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: _refresh,
          child: _loading ? _buildShimmer() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (_) => Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildBillingToggle(),
        const SizedBox(height: 20),
        ..._plans.asMap().entries.map(
              (e) => _buildPlanCard(e.value, e.key, _currentPlanIndex),
            ),
        const SizedBox(height: 16),
        _buildEnterpriseLink(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBillingToggle() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => _annual = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: !_annual ? _kText : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(24),
                  ),
                  border: Border.all(color: _kText),
                ),
                child: Text(
                  'Monthly',
                  style: TextStyle(
                    color: !_annual ? Colors.white : _kText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _annual = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _annual ? _kText : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                  border: Border.all(color: _kText),
                ),
                child: Text(
                  'Annual',
                  style: TextStyle(
                    color: _annual ? Colors.white : _kText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_annual) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Save up to 24% with annual billing',
              style: TextStyle(color: _kSubtext, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanCard(_Plan plan, int index, int currentIndex) {
    final isCurrent = index == currentIndex;
    final price =
        _annual ? plan.annualMonthlyTzs : plan.monthlyTzs;
    final savings = _annual
        ? _savingsPercent(plan.monthlyTzs, plan.annualMonthlyTzs)
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrent ? _kText : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: !isCurrent
            ? Border.all(color: Colors.grey.shade200)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isCurrent ? 0.12 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  color: isCurrent ? Colors.white : _kText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (_annual && savings > 0 && !isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$savings% off',
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plan.description,
            style: TextStyle(
              color: isCurrent ? Colors.white70 : _kSubtext,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(price),
                style: TextStyle(
                  color: isCurrent ? Colors.white : _kText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (price > 0) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '/mo',
                    style: TextStyle(
                      color: isCurrent ? Colors.white70 : _kSubtext,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: isCurrent ? Colors.white70 : _kText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        color: isCurrent ? Colors.white70 : _kSubtext,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Current Plan',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kText,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      index < currentIndex
                          ? 'Downgrade to ${plan.name}'
                          : 'Upgrade to ${plan.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseLink() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text(
          'Need more? Contact Sales for Enterprise →',
          style: TextStyle(
            color: _kText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Plan {
  final String name;
  final int monthlyTzs;
  final int annualMonthlyTzs;
  final String description;
  final List<String> features;
  const _Plan({
    required this.name,
    required this.monthlyTzs,
    required this.annualMonthlyTzs,
    required this.description,
    required this.features,
  });
}
