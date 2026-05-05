// lib/subscriptions/pages/subscriptions_home_page.dart
//
// Subscriptions hub (subscriber-side only) — landing surface that
// aggregates everything the user pays for. Strictly subscriber-facing;
// the creator side (manage subscribers/tiers/earnings) lives behind
// the **Subscribers** stat chip on the profile header.
//
// Sections:
//   • CREATORS — subs to creators (subscription_tiers backend)
//   • PLATFORM SERVICES — TAJIRIKA Plus, ambulance, insurance,
//     training plans, partner memberships, car insurance, NHIF.

import 'package:flutter/material.dart';

import '../../ambulance/models/ambulance_models.dart' as amb;
import '../../ambulance/pages/subscription_plans_page.dart';
import '../../ambulance/services/ambulance_service.dart';
import '../../car_insurance/car_insurance_module.dart';
import '../../fitness/models/training_plan.dart';
import '../../fitness/pages/training_plans_page.dart';
import '../../fitness/services/training_plan_service.dart';
import '../../insurance/models/insurance_models.dart' as ins;
import '../../insurance/pages/my_policies_page.dart';
import '../../insurance/services/insurance_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/subscription_models.dart';
import '../../nhif/nhif_module.dart';
import '../../screens/wallet/my_subscriptions_screen.dart';
import '../../services/subscription_service.dart';
import '../../tajirika/pages/tajirika_home_page.dart';
import '../../tajirika/pages/tajirika_plus_subscribe_page.dart';
import '../../tajirika/services/membership_service.dart';
import '../../tajirika/services/tajirika_plus_service.dart';
import '../widgets/subscription_hub_card.dart';
import '../widgets/subscription_section_label.dart';
import '../widgets/subscription_spending_header.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);

class SubscriptionsHomePage extends StatefulWidget {
  final int userId;
  const SubscriptionsHomePage({super.key, required this.userId});

  @override
  State<SubscriptionsHomePage> createState() => _SubscriptionsHomePageState();
}

class _SubscriptionsHomePageState extends State<SubscriptionsHomePage> {
  final SubscriptionService _subs = SubscriptionService();
  final AmbulanceService _ambulance = AmbulanceService();
  final InsuranceService _insurance = InsuranceService();

  bool _loading = true;
  String? _error;

  // Creator subscriptions
  List<Subscription> _mySubs = const [];

  // Platform services (state-aware)
  TajirikaPlusStatus? _tajirikaPlus;
  amb.Subscription? _ambulanceSub;
  List<ins.InsurancePolicy> _policies = const [];
  List<TrainingPlan> _trainingPlans = const [];
  List<Membership> _memberships = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _mySubs.isEmpty &&
          _ambulanceSub == null &&
          _tajirikaPlus == null &&
          _policies.isEmpty &&
          _trainingPlans.isEmpty &&
          _memberships.isEmpty;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _subs.getMySubscriptions(userId: widget.userId),               // 0
        _ambulance.getCurrentSubscription(),                            // 1
        TajirikaPlusService.getStatus(widget.userId),                   // 2
        _insurance.getMyPolicies(widget.userId),                        // 3
        TrainingPlanService.listForCustomer(widget.userId),             // 4
        MembershipService.myMemberships(userId: widget.userId),         // 5
      ]);
      if (!mounted) return;
      final mySubs = results[0] as SubscriptionListResult;
      final ambResult = results[1] as amb.SingleResult<amb.Subscription>;
      final plusResult = results[2] as TajirikaPlusResult;
      final policiesResult =
          results[3] as ins.InsuranceListResult<ins.InsurancePolicy>;
      final plans = results[4] as List<TrainingPlan>;
      final memberships = results[5] as List<Membership>;

      setState(() {
        _mySubs = mySubs.success ? mySubs.subscriptions : const [];
        _ambulanceSub = ambResult.success ? ambResult.data : null;
        _tajirikaPlus = plusResult.success ? plusResult.status : null;
        _policies = policiesResult.success ? policiesResult.items : const [];
        _trainingPlans = plans;
        _memberships = memberships;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _sanitizeError(e);
          _loading = false;
        });
      }
    }
  }

  // ── helpers ──

  /// Strips developer noise from exception messages so the user sees
  /// a clean phrase. Per playbook §100 — never raw error strings.
  String _sanitizeError(Object e) {
    final raw = e.toString();
    final stripped =
        raw.startsWith('Exception: ') ? raw.substring(11) : raw;
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (stripped.contains('SocketException') ||
        stripped.contains('Failed host lookup')) {
      return isSw
          ? 'Hakuna intaneti. Hakikisha umeunganishwa.'
          : "Can't reach the server. Check your connection.";
    }
    if (stripped.contains('TimeoutException')) {
      return isSw ? 'Muda umeisha. Jaribu tena.' : 'Request timed out. Try again.';
    }
    return isSw ? 'Imeshindwa kupakia.' : 'Failed to load.';
  }

  double get _monthlySpend {
    double total = 0;
    for (final s in _mySubs) {
      if (s.status != 'active' || s.tier == null) continue;
      final p = s.tier!.price;
      total += s.tier!.billingPeriod == 'yearly' ? p / 12.0 : p;
    }
    for (final p in _policies) {
      if (p.status != ins.PolicyStatus.active) continue;
      total += p.premiumFrequency == 'monthly'
          ? p.premiumAmount
          : p.premiumAmount / 12.0;
    }
    return total;
  }

  int get _activeCreatorCount =>
      _mySubs.where((s) => s.status == 'active').length;

  int get _activePoliciesCount =>
      _policies.where((p) => p.status == ins.PolicyStatus.active).length;

  int get _activeTrainingPlansCount =>
      _trainingPlans.where((p) => p.isActive).length;

  int get _activeMembershipsCount =>
      _memberships.where((m) => m.status == 'active').length;

  /// Format TZS per playbook §161 — `1.5M` / `450K` for >=10K, comma
  /// separators below.
  String _fmtTzs(num v) {
    final n = v.toDouble();
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n >= 10000000 ? 0 : 1)}M';
    }
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}K';
    final s = n.toStringAsFixed(0);
    final reversed = s.split('').reversed.toList();
    final out = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) out.write(',');
      out.write(reversed[i]);
    }
    return out.toString().split('').reversed.join('');
  }

  String _spendSubtitle(bool isSw) {
    final parts = <String>[];
    if (_activeCreatorCount > 0) {
      parts.add('$_activeCreatorCount ${isSw ? "watayarishaji" : "creators"}');
    }
    if (_activePoliciesCount > 0) {
      parts.add('$_activePoliciesCount ${isSw ? "bima" : "policies"}');
    }
    if (parts.isEmpty) {
      return isSw ? 'Hakuna usajili wa sasa' : 'No active subscriptions';
    }
    return parts.join(' · ');
  }

  String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Usajili' : 'Subscriptions',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              )
            : _error != null
                ? _buildError(isSw)
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      SubscriptionSpendingHeader(
                        monthlySpendLabel: isSw
                            ? 'Matumizi ya kila mwezi'
                            : 'Monthly spend',
                        monthlySpendValue:
                            '${_fmtTzs(_monthlySpend)} TZS',
                        subtitle: _spendSubtitle(isSw),
                      ),
                      const SizedBox(height: 20),
                      SubscriptionSectionLabel(
                        label: isSw ? 'WATAYARISHAJI' : 'CREATORS',
                      ),
                      const SizedBox(height: 8),
                      _buildCreatorSubsCard(isSw),
                      const SizedBox(height: 24),
                      SubscriptionSectionLabel(
                        label:
                            isSw ? 'HUDUMA ZA JUKWAA' : 'PLATFORM SERVICES',
                      ),
                      const SizedBox(height: 8),
                      _buildTajirikaPlusCard(isSw),
                      const SizedBox(height: 8),
                      _buildAmbulanceCard(isSw),
                      const SizedBox(height: 8),
                      _buildInsuranceCard(isSw),
                      const SizedBox(height: 8),
                      _buildTrainingPlansCard(isSw),
                      const SizedBox(height: 8),
                      _buildMembershipsCard(isSw),
                      const SizedBox(height: 8),
                      _buildCarInsuranceCard(isSw),
                      const SizedBox(height: 8),
                      _buildNhifCard(isSw),
                    ],
                  ),
      ),
    );
  }

  // ── card builders ──

  Widget _buildCreatorSubsCard(bool isSw) {
    final empty = _activeCreatorCount == 0;
    return SubscriptionHubCard(
      icon: Icons.workspace_premium_rounded,
      title: isSw ? 'Watayarishaji' : 'Creators',
      headline: empty
          ? (isSw ? 'Hakuna usajili' : 'No subscriptions')
          : '$_activeCreatorCount ${isSw ? "wanaolipwa" : "active"}',
      subtitle: empty
          ? (isSw
              ? 'Tafuta watayarishaji wa kuwasajili'
              : 'Find creators to subscribe to')
          : (isSw
              ? 'Simamia, sitisha, au angalia historia'
              : 'Manage, cancel, or view history'),
      cta: isSw ? 'Tazama' : 'View',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MySubscriptionsScreen(currentUserId: widget.userId),
        ),
      ),
    );
  }

  Widget _buildTajirikaPlusCard(bool isSw) {
    final s = _tajirikaPlus;
    final hasActive = s != null && s.active;
    return SubscriptionHubCard(
      icon: Icons.auto_awesome_rounded,
      title: 'TAJIRIKA Plus',
      headline: hasActive
          ? ((s.tier ?? '').isNotEmpty
              ? s.tier!
              : (isSw ? 'Inafanya kazi' : 'Active'))
          : (isSw ? 'Haijawashwa' : 'Inactive'),
      subtitle: hasActive
          ? (s.expiresAt != null
              ? (isSw
                  ? 'Inaisha ${_fmtDate(s.expiresAt!)}'
                  : 'Renews ${_fmtDate(s.expiresAt!)}')
              : (isSw
                  ? 'Manufaa ya washirika'
                  : 'Partner premium benefits'))
          : (isSw
              ? 'Manufaa ya washirika wa TAJIRIKA'
              : 'Premium partner benefits'),
      cta: hasActive
          ? (isSw ? 'Simamia' : 'Manage')
          : (isSw ? 'Jiunge' : 'Subscribe'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TajirikaPlusSubscribePage(partnerUserId: widget.userId),
        ),
      ),
    );
  }

  Widget _buildAmbulanceCard(bool isSw) {
    final sub = _ambulanceSub;
    final hasActive = sub != null && sub.isActive;
    return SubscriptionHubCard(
      icon: Icons.local_hospital_outlined,
      title: isSw ? 'Gari la wagonjwa' : 'Ambulance',
      headline: hasActive
          ? (isSw ? 'Inafanya kazi' : 'Active')
          : (isSw ? 'Haina mpango' : 'No plan'),
      subtitle: hasActive
          ? sub.planType
          : (isSw
              ? 'Jiunge na mpango wa gari la wagonjwa'
              : 'Subscribe to an ambulance plan'),
      cta: hasActive
          ? (isSw ? 'Simamia' : 'Manage')
          : (isSw ? 'Jiunge' : 'Subscribe'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
      ),
    );
  }

  Widget _buildInsuranceCard(bool isSw) {
    final n = _activePoliciesCount;
    final empty = n == 0;
    return SubscriptionHubCard(
      icon: Icons.shield_outlined,
      title: isSw ? 'Bima' : 'Insurance',
      headline: empty
          ? (isSw ? 'Hakuna bima' : 'No policies')
          : '$n ${isSw ? "bima zinazofanya kazi" : "active"}',
      subtitle: empty
          ? (isSw
              ? 'Tafuta bima ya afya, mali, au maisha'
              : 'Find a health, property, or life policy')
          : (isSw ? 'Simamia, lipa, au dai' : 'Manage, pay, or claim'),
      cta: empty
          ? (isSw ? 'Tafuta' : 'Browse')
          : (isSw ? 'Tazama' : 'View'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MyPoliciesPage(userId: widget.userId),
        ),
      ),
    );
  }

  Widget _buildTrainingPlansCard(bool isSw) {
    final n = _activeTrainingPlansCount;
    final empty = n == 0;
    return SubscriptionHubCard(
      icon: Icons.fitness_center_rounded,
      title: isSw ? 'Mipango ya mazoezi' : 'Training plans',
      headline: empty
          ? (isSw ? 'Hakuna mpango' : 'No plans')
          : '$n ${isSw ? "mpango unaofanya kazi" : "active"}',
      subtitle: empty
          ? (isSw ? 'Pata mwalimu wa mazoezi' : 'Find a 1:1 trainer')
          : (isSw
              ? 'Andika mahudhurio na ukue'
              : 'Log check-ins and progress'),
      cta: empty
          ? (isSw ? 'Tafuta' : 'Browse')
          : (isSw ? 'Tazama' : 'View'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TrainingPlansPage(customerUserId: widget.userId),
        ),
      ),
    );
  }

  Widget _buildMembershipsCard(bool isSw) {
    final n = _activeMembershipsCount;
    final empty = n == 0;
    return SubscriptionHubCard(
      icon: Icons.card_membership_rounded,
      title: isSw ? 'Uanachama' : 'Memberships',
      headline: empty
          ? (isSw ? 'Hakuna uanachama' : 'No memberships')
          : '$n ${isSw ? "anachama" : "active"}',
      subtitle: empty
          ? (isSw
              ? 'Nunua uanachama wa washirika'
              : 'Buy partner credit packages')
          : (isSw
              ? 'Tazama mikupuo iliyobaki'
              : 'View remaining credits'),
      cta: empty
          ? (isSw ? 'Tafuta' : 'Browse')
          : (isSw ? 'Tazama' : 'View'),
      // No dedicated "my memberships" screen yet — push to TAJIRIKA
      // home which surfaces the membership listing.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TajirikaHomePage()),
      ),
    );
  }

  Widget _buildCarInsuranceCard(bool isSw) {
    return SubscriptionHubCard(
      icon: Icons.directions_car_rounded,
      title: isSw ? 'Bima ya gari' : 'Car insurance',
      headline: isSw ? 'Simamia magari yako' : 'Manage your vehicles',
      subtitle: isSw
          ? 'Bima na vibali kwa magari yote'
          : 'Cover and renewals for all vehicles',
      cta: isSw ? 'Tazama' : 'View',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CarInsuranceModule(userId: widget.userId),
        ),
      ),
    );
  }

  Widget _buildNhifCard(bool isSw) {
    return SubscriptionHubCard(
      icon: Icons.health_and_safety_outlined,
      title: 'NHIF',
      headline: isSw ? 'Bima ya afya ya taifa' : 'National health insurance',
      subtitle: isSw
          ? 'Lipa malipo ya kila mwezi'
          : 'Manage monthly premiums',
      cta: isSw ? 'Tazama' : 'View',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NhifModule(userId: widget.userId),
        ),
      ),
    );
  }

  // ── error state ──

  Widget _buildError(bool isSw) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 64),
        const Icon(Icons.error_outline, size: 48, color: _kTertiary),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _error!,
            style: const TextStyle(color: _kSecondary, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: _load,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(isSw ? 'Jaribu tena' : 'Retry'),
          ),
        ),
      ],
    );
  }
}
