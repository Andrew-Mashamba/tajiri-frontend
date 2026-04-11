// lib/ambulance/pages/subscription_plans_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/budget_context_banner.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kGreen = Color(0xFF2E7D32);

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});
  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  final AmbulanceService _service = AmbulanceService();
  List<SubscriptionPlan> _plans = [];
  Subscription? _currentSub;
  bool _isLoading = true;
  bool _isSubscribing = false;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getSubscriptionPlans(),
        _service.getCurrentSubscription(),
      ]);
      if (!mounted) return;

      final plansResult = results[0] as PaginatedResult<SubscriptionPlan>;
      final subResult = results[1] as SingleResult<Subscription>;

      setState(() {
        _isLoading = false;
        if (plansResult.success) _plans = plansResult.items;
        if (subResult.success) _currentSub = subResult.data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            _isSwahili ? 'Chagua Njia ya Malipo' : 'Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BudgetContextBanner(
              category: 'afya',
              paymentAmount: plan.priceMonthly,
              isSwahili: _isSwahili,
            ),
            const SizedBox(height: 12),
            _PaymentOption(
              icon: Icons.phone_android_rounded,
              label: 'M-Pesa',
              onTap: () => Navigator.pop(ctx, 'mpesa'),
            ),
            const SizedBox(height: 8),
            _PaymentOption(
              icon: Icons.account_balance_rounded,
              label: _isSwahili ? 'Benki' : 'Bank',
              onTap: () => Navigator.pop(ctx, 'bank'),
            ),
            const SizedBox(height: 8),
            _PaymentOption(
              icon: Icons.account_balance_wallet_rounded,
              label: _isSwahili ? 'Pochi ya Tajiri' : 'Tajiri Wallet',
              onTap: () => Navigator.pop(ctx, 'wallet'),
            ),
          ],
        ),
      ),
    );

    if (paymentMethod == null) return;

    setState(() => _isSubscribing = true);
    try {
      final result = await _service.subscribePlan(
        planId: plan.id,
        paymentMethod: paymentMethod,
      );
      if (!mounted) return;
      setState(() => _isSubscribing = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        _load();
        messenger.showSnackBar(
          SnackBar(
              content: Text(
                  _isSwahili ? 'Umejisajili!' : 'Subscribed successfully!'),
              backgroundColor: _kPrimary),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubscribing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  IconData _planIcon(String type) {
    switch (type.toLowerCase()) {
      case 'family':
        return Icons.family_restroom_rounded;
      case 'corporate':
        return Icons.business_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Mipango ya Usajili' : 'Subscription Plans',
          style:
              const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Current plan
                  if (_currentSub != null && _currentSub!.isActive) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _kGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: _kGreen, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSwahili
                                      ? 'Mpango Wako wa Sasa'
                                      : 'Your Current Plan',
                                  style: const TextStyle(
                                      fontSize: 12, color: _kGreen),
                                ),
                                Text(
                                  _currentSub!.planType[0].toUpperCase() +
                                      _currentSub!.planType.substring(1),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_currentSub!.endDate != null)
                                  Text(
                                    '${_isSwahili ? 'Inaisha' : 'Expires'}: ${_currentSub!.endDate!.day}/${_currentSub!.endDate!.month}/${_currentSub!.endDate!.year}',
                                    style: const TextStyle(
                                        fontSize: 12, color: _kSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Plan cards
                  Text(
                    _isSwahili ? 'Mipango Inayopatikana' : 'Available Plans',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 12),

                  if (_plans.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          _isSwahili
                              ? 'Hakuna mipango'
                              : 'No plans available',
                          style: const TextStyle(
                              color: _kSecondary, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ..._plans.map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: _currentSub?.planType == plan.planType &&
                                      _currentSub?.isActive == true
                                  ? Border.all(color: _kGreen, width: 1.5)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                          _planIcon(plan.planType),
                                          color: _kPrimary,
                                          size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isSwahili
                                                ? plan.nameSw
                                                : plan.name,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: _kPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${_isSwahili ? 'Wanachama' : 'Members'}: ${plan.maxMembers}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: _kSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Pricing
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isSwahili
                                              ? 'Kwa mwezi'
                                              : 'Monthly',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _kSecondary),
                                        ),
                                        Text(
                                          'TZS ${plan.priceMonthly.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: _kPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isSwahili
                                              ? 'Kwa mwaka'
                                              : 'Yearly',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _kSecondary),
                                        ),
                                        Text(
                                          'TZS ${plan.priceYearly.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: _kSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Features
                                ...((_isSwahili
                                        ? plan.featuresSw
                                        : plan.features)
                                    .take(5)
                                    .map((f) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons
                                                      .check_circle_rounded,
                                                  size: 16,
                                                  color: _kGreen),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  f,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: _kPrimary),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))),

                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: _isSubscribing
                                        ? null
                                        : () => _subscribe(plan),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _kPrimary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: _isSubscribing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : Text(
                                            _currentSub?.planType ==
                                                        plan.planType &&
                                                    _currentSub?.isActive ==
                                                        true
                                                ? (_isSwahili
                                                    ? 'Ongeza Muda'
                                                    : 'Renew')
                                                : (_isSwahili
                                                    ? 'Jisajili'
                                                    : 'Subscribe'),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PaymentOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF1A1A1A)),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A))),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF666666)),
            ],
          ),
        ),
      ),
    );
  }
}
