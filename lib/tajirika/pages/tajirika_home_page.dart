import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/tier_badge.dart';
import '../widgets/partner_stat_card.dart';
import '../widgets/tier_progress_bar.dart';
import '../widgets/earnings_module_breakdown.dart';
import 'registration_page.dart';
import 'partner_profile_page.dart';
import 'verification_status_page.dart';
import 'training_hub_page.dart';
import 'earnings_overview_page.dart';
import 'referral_center_page.dart';
import 'skill_certification_page.dart';
import 'partner_settings_page.dart';
import 'portfolio_manager_page.dart';

class TajirikaHomePage extends StatefulWidget {
  const TajirikaHomePage({super.key});

  @override
  State<TajirikaHomePage> createState() => _TajirikaHomePageState();
}

class _TajirikaHomePageState extends State<TajirikaHomePage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  TajirikaPartner? _partner;
  PartnerEarnings? _earnings;
  TierProgress? _tierProgress;
  PartnerStats? _stats;
  bool _isLoading = true;
  bool _notRegistered = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) {
        if (!mounted) return;
        setState(() { _isLoading = false; _error = 'Not authenticated'; });
        return;
      }

      final profileResult = await TajirikaService.getMyPartnerProfile(token, userId);
      if (!mounted) return;

      if (!profileResult.success) {
        if (profileResult.message == 'not_registered') {
          setState(() { _isLoading = false; _notRegistered = true; });
          return;
        }
        setState(() { _isLoading = false; _error = profileResult.message; });
        return;
      }

      _partner = profileResult.partner;

      final results = await Future.wait([
        TajirikaService.getEarnings(token, userId),
        TajirikaService.getTierProgress(token, userId),
        TajirikaService.getPartnerStats(token, userId),
      ]);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _earnings = results[0] as PartnerEarnings;
        _tierProgress = results[1] as TierProgress;
        _stats = results[2] as PartnerStats;
      });
    } catch (e) {
      if (!mounted) return;
      final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
      setState(() { _isLoading = false; _error = isSwahili ? 'Hitilafu: $e' : 'Error: $e'; });
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _notRegistered
                ? _buildRegistrationCta(isSwahili)
                : _error != null
                    ? _buildError(isSwahili)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: _kPrimary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPartnerCard(isSwahili),
                              const SizedBox(height: 16),
                              _buildStatsRow(isSwahili),
                              const SizedBox(height: 16),
                              if (_tierProgress != null)
                                TierProgressBar(progress: _tierProgress!, isSwahili: isSwahili),
                              const SizedBox(height: 16),
                              _buildEarningsCard(isSwahili),
                              const SizedBox(height: 16),
                              _buildQuickActions(isSwahili),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildRegistrationCta(bool isSwahili) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_rounded, size: 64, color: _kSecondary),
            const SizedBox(height: 24),
            Text(
              isSwahili ? 'Jiunge na Tajirika' : 'Join Tajirika',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              isSwahili
                  ? 'Sajili ujuzi wako na uanze kupata wateja kupitia jukwaa la TAJIRI.'
                  : 'Register your skills and start getting customers through the TAJIRI platform.',
              style: const TextStyle(fontSize: 14, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrationPage()),
                  );
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isSwahili ? 'Jisajili Sasa' : 'Register Now',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool isSwahili) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? (isSwahili ? 'Imeshindwa kupakia' : 'Failed to load'),
              style: const TextStyle(color: _kPrimary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadData,
              child: Text(isSwahili ? 'Jaribu tena' : 'Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(bool isSwahili) {
    final p = _partner!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateTo(PartnerProfilePage(partnerId: p.id)),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
              child: p.photoUrl.isEmpty
                  ? const Icon(Icons.person_rounded, size: 30, color: _kSecondary)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TierBadge(tier: p.tier, fontSize: 10),
                    const SizedBox(width: 8),
                    if (p.aggregateRating > 0) ...[
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(
                        p.aggregateRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.isActive ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.isActive
                          ? (isSwahili ? 'Hai' : 'Active')
                          : (isSwahili ? 'Siyo Hai' : 'Inactive'),
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
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

  Widget _buildStatsRow(bool isSwahili) {
    final s = _stats ?? PartnerStats();
    return Row(
      children: [
        Expanded(
          child: PartnerStatCard(
            label: isSwahili ? 'Kazi' : 'Jobs',
            value: s.jobsCompleted.toString(),
            icon: Icons.work_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PartnerStatCard(
            label: isSwahili ? 'Ukadiriaji' : 'Rating',
            value: s.averageRating > 0 ? s.averageRating.toStringAsFixed(1) : '-',
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PartnerStatCard(
            label: isSwahili ? 'Majibu' : 'Response',
            value: s.responseTimeMinutes > 0 ? '${s.responseTimeMinutes}m' : '-',
            icon: Icons.timer_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PartnerStatCard(
            label: isSwahili ? 'Moduli' : 'Modules',
            value: s.activeModules.length.toString(),
            icon: Icons.apps_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(bool isSwahili) {
    final e = _earnings ?? PartnerEarnings();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Mapato' : 'Earnings',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              GestureDetector(
                onTap: () => _navigateTo(const EarningsOverviewPage()),
                child: Text(
                  isSwahili ? 'Ona yote' : 'View all',
                  style: const TextStyle(fontSize: 12, color: _kSecondary, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'TZS ${e.totalEarnings.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili ? 'Jumla ya mapato' : 'Total earnings',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          if (e.byModule.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            EarningsModuleBreakdown(byModule: e.byModule),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isSwahili) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _quickAction(Icons.person_rounded, isSwahili ? 'Wasifu' : 'Profile',
            () => _navigateTo(PartnerProfilePage(partnerId: _partner!.id))),
        _quickAction(Icons.photo_library_rounded, isSwahili ? 'Kazi Zangu' : 'Portfolio',
            () => _navigateTo(PortfolioManagerPage(partnerId: _partner!.id))),
        _quickAction(Icons.verified_rounded, isSwahili ? 'Uthibitisho' : 'Verification',
            () => _navigateTo(const VerificationStatusPage())),
        _quickAction(Icons.school_rounded, isSwahili ? 'Mafunzo' : 'Training',
            () => _navigateTo(const TrainingHubPage())),
        _quickAction(Icons.monetization_on_rounded, isSwahili ? 'Mapato' : 'Earnings',
            () => _navigateTo(const EarningsOverviewPage())),
        _quickAction(Icons.people_rounded, isSwahili ? 'Rufaa' : 'Referrals',
            () => _navigateTo(const ReferralCenterPage())),
        _quickAction(Icons.workspace_premium_rounded, isSwahili ? 'Ujuzi' : 'Skills',
            () => _navigateTo(const SkillCertificationPage())),
        _quickAction(Icons.settings_rounded, isSwahili ? 'Mipangilio' : 'Settings',
            () => _navigateTo(const PartnerSettingsPage())),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 56) / 4,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(icon, size: 22, color: _kPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: _kSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
