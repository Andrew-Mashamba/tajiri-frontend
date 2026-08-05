import 'dart:async';

import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);

class CreatorMembershipScreen extends StatefulWidget {
  const CreatorMembershipScreen({super.key});

  @override
  State<CreatorMembershipScreen> createState() =>
      _CreatorMembershipScreenState();
}

class _CreatorMembershipScreenState extends State<CreatorMembershipScreen> {
  bool _loading = true;
  late Timer _shimmerTimer;

  final _tiers = const [
    _MemberTier(
      name: 'Free',
      color: Color(0xFF9E9E9E),
      price: 0,
      benefits: [
        'Access to public content',
        'Basic community features',
        'Monthly newsletter',
      ],
    ),
    _MemberTier(
      name: 'Silver',
      color: Color(0xFF757575),
      price: 5000,
      benefits: [
        'Everything in Free',
        'Exclusive posts & updates',
        'Early product access',
        'Members-only discount 5%',
      ],
    ),
    _MemberTier(
      name: 'Gold',
      color: Color(0xFF1A1A1A),
      price: 15000,
      benefits: [
        'Everything in Silver',
        'Direct message with creator',
        'Monthly live Q&A session',
        'Members-only discount 15%',
        'Priority customer support',
      ],
    ),
  ];

  final _subscribers = const [
    _Subscriber(name: 'Amina K.', tier: 'Gold', joined: '2 days ago'),
    _Subscriber(name: 'John M.', tier: 'Silver', joined: '1 week ago'),
    _Subscriber(name: 'Fatuma S.', tier: 'Silver', joined: '2 weeks ago'),
    _Subscriber(name: 'David O.', tier: 'Free', joined: '3 weeks ago'),
    _Subscriber(name: 'Grace N.', tier: 'Gold', joined: '1 month ago'),
    _Subscriber(name: 'Hassan A.', tier: 'Free', joined: '1 month ago'),
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

  String _formatTzs(int amount) {
    if (amount == 0) return 'Free';
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TZS ${buf.toString()}/mo';
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Gold':
        return const Color(0xFF1A1A1A);
      case 'Silver':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Creator Membership',
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
        _buildProfileHeader(),
        const SizedBox(height: 20),
        _buildStatsRow(),
        const SizedBox(height: 24),
        _buildSectionTitle('Membership Tiers'),
        const SizedBox(height: 12),
        ..._tiers.map(_buildTierCard),
        const SizedBox(height: 24),
        _buildSectionTitle('Current Subscribers'),
        const SizedBox(height: 12),
        ..._subscribers.map(_buildSubscriberRow),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey.shade200,
            child: Icon(
              Icons.person_rounded,
              size: 32,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Creator Profile',
                  style: TextStyle(
                    color: _kText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  '@creator_handle',
                  style: TextStyle(color: _kSubtext, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kText,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Gold',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Members', '247', Icons.group_rounded),
        const SizedBox(width: 12),
        _buildStatCard('Earnings', 'TZS 1,245,000', Icons.payments_rounded),
        const SizedBox(width: 12),
        _buildStatCard('This Month', '+18', Icons.trending_up_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: _kText),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: _kText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: _kSubtext, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _kText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTierCard(_MemberTier tier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: tier.name == 'Gold'
            ? Border.all(color: _kText, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tier.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tier.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTzs(tier.price),
                style: const TextStyle(
                  color: _kText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tier.benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Color(0xFF1A1A1A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: _kSubtext,
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
        ],
      ),
    );
  }

  Widget _buildSubscriberRow(_Subscriber sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade100,
            child: Text(
              sub.name[0],
              style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Joined ${sub.joined}',
                  style: const TextStyle(color: _kSubtext, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _tierColor(sub.tier),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sub.tier,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTier {
  final String name;
  final Color color;
  final int price;
  final List<String> benefits;
  const _MemberTier({
    required this.name,
    required this.color,
    required this.price,
    required this.benefits,
  });
}

class _Subscriber {
  final String name;
  final String tier;
  final String joined;
  const _Subscriber({
    required this.name,
    required this.tier,
    required this.joined,
  });
}
