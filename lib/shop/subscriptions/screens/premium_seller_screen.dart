import 'dart:async';

import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);

class PremiumSellerScreen extends StatefulWidget {
  const PremiumSellerScreen({super.key});

  @override
  State<PremiumSellerScreen> createState() => _PremiumSellerScreenState();
}

class _PremiumSellerScreenState extends State<PremiumSellerScreen> {
  bool _loading = true;
  bool _annual = false;
  int _expandedFaq = -1;
  late Timer _shimmerTimer;

  static const _features = [
    _Feature('Featured product placement', false, true),
    _Feature('Advanced analytics dashboard', false, true),
    _Feature('Reduced transaction fees (2%)', false, true),
    _Feature('Priority customer support', false, true),
    _Feature('Verified seller badge', false, true),
    _Feature('Unlimited product listings', true, true),
    _Feature('Basic analytics', true, true),
    _Feature('Standard support', true, true),
  ];

  static const _faqs = [
    _Faq(
      'Can I cancel anytime?',
      'Yes. You can cancel your Premium subscription at any time. You will retain access until the end of your current billing period.',
    ),
    _Faq(
      'What is the verified badge?',
      'The verified badge appears on your shop and product listings, signalling to buyers that you are a trusted, authenticated seller on TAJIRI.',
    ),
    _Faq(
      'How does the lower fee work?',
      'Free sellers pay a 5% transaction fee per sale. Premium sellers pay just 2%, saving you money on every transaction.',
    ),
    _Faq(
      'Is there a free trial?',
      'Yes — new sellers get a 14-day free trial of Premium. No credit card required to start.',
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

  String get _monthlyPrice => 'TZS 29,000';
  String get _annualMonthlyPrice => 'TZS 22,000';
  String get _annualTotalPrice => 'TZS 264,000';
  String get _annualSavings => 'Save TZS 84,000/year';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Premium Seller',
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
        5,
        (_) => Container(
          height: 80,
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
        _buildCurrentPlanBanner(),
        const SizedBox(height: 20),
        _buildBillingToggle(),
        const SizedBox(height: 16),
        _buildPricingCard(),
        const SizedBox(height: 24),
        _buildComparisonTable(),
        const SizedBox(height: 24),
        _buildFaqs(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCurrentPlanBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 32,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Plan: Free',
                  style: TextStyle(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '5% transaction fee · Standard listing',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() => _annual = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                fontSize: 13,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _annual = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _annual ? _kText : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(24),
              ),
              border: Border.all(color: _kText),
            ),
            child: Row(
              children: [
                Text(
                  'Annual',
                  style: TextStyle(
                    color: _annual ? Colors.white : _kText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _annual ? Colors.white24 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '24% off',
                    style: TextStyle(
                      color: _annual ? Colors.white : _kSubtext,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kText,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _annual ? _annualMonthlyPrice : _monthlyPrice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '/mo',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          if (_annual) ...[
            const SizedBox(height: 4),
            Text(
              '$_annualTotalPrice billed annually · $_annualSavings',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upgrade to Premium',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Feature',
                    style: TextStyle(
                      color: _kSubtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _tableHeader('Free'),
                _tableHeader('Premium'),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._features.asMap().entries.map((e) => _buildFeatureRow(
                e.value,
                isLast: e.key == _features.length - 1,
              )),
        ],
      ),
    );
  }

  Widget _tableHeader(String label) {
    return SizedBox(
      width: 64,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: _kText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(_Feature f, {required bool isLast}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  f.name,
                  style: const TextStyle(color: _kText, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 64,
                child: Center(child: _checkIcon(f.free)),
              ),
              SizedBox(
                width: 64,
                child: Center(child: _checkIcon(f.premium)),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _checkIcon(bool enabled) {
    return Icon(
      enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
      size: 20,
      color: enabled ? _kText : Colors.grey.shade300,
    );
  }

  Widget _buildFaqs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FAQs',
          style: TextStyle(
            color: _kText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _faqs.asMap().entries.map((e) {
              final i = e.key;
              final faq = e.value;
              final expanded = _expandedFaq == i;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(
                      () => _expandedFaq = expanded ? -1 : i,
                    ),
                    borderRadius: i == 0
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : i == _faqs.length - 1
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(16))
                            : BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              faq.question,
                              style: const TextStyle(
                                color: _kText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: _kSubtext,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          color: _kSubtext,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (i < _faqs.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Feature {
  final String name;
  final bool free;
  final bool premium;
  const _Feature(this.name, this.free, this.premium);
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}
