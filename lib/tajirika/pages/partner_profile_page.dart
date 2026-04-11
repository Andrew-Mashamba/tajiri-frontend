import 'package:flutter/material.dart' hide Badge;
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/tier_badge.dart';
import '../widgets/skill_category_chip.dart';
import '../widgets/partner_stat_card.dart';
import '../widgets/portfolio_item_card.dart';
import '../widgets/badge_chip.dart';
import 'partner_settings_page.dart';
import 'portfolio_manager_page.dart';

class PartnerProfilePage extends StatefulWidget {
  final int partnerId;

  const PartnerProfilePage({super.key, required this.partnerId});

  @override
  State<PartnerProfilePage> createState() => _PartnerProfilePageState();
}

class _PartnerProfilePageState extends State<PartnerProfilePage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  TajirikaPartner? _partner;
  List<PortfolioItem> _portfolio = [];
  List<Badge> _badges = [];
  bool _isLoading = true;
  String? _token;
  int? _currentUserId;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final storage = await LocalStorageService.getInstance();
      _token = storage.getAuthToken();
      _currentUserId = storage.getUser()?.userId;
      if (_token == null) return;

      final results = await Future.wait([
        TajirikaService.getPartnerProfile(_token!, widget.partnerId),
        TajirikaService.getPortfolio(_token!, widget.partnerId),
        TajirikaService.getBadges(_token!, _currentUserId!),
      ]);

      if (!mounted) return;

      final partnerResult = results[0] as PartnerResult;
      final portfolioResult = results[1] as PortfolioListResult;
      final badgeResult = results[2] as BadgeListResult;

      setState(() {
        _partner = partnerResult.partner;
        _portfolio = portfolioResult.items;
        _badges = badgeResult.badges;
        _isOwnProfile =
            _partner != null && _partner!.userId == _currentUserId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    if (_token == null) return;
    try {
      final results = await Future.wait([
        TajirikaService.getPartnerProfile(_token!, widget.partnerId),
        TajirikaService.getPortfolio(_token!, widget.partnerId),
      ]);
      if (!mounted) return;
      final partnerResult = results[0] as PartnerResult;
      final portfolioResult = results[1] as PortfolioListResult;
      setState(() {
        if (partnerResult.partner != null) _partner = partnerResult.partner;
        _portfolio = portfolioResult.items;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSwahili ? 'Wasifu wa Mshirika' : 'Partner Profile',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _partner == null
                ? Center(
                    child: Text(
                      isSwahili ? 'Mshirika hajapatikana' : 'Partner not found',
                      style: const TextStyle(color: _kSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: _kPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isSwahili),
                          const SizedBox(height: 20),
                          if (_partner!.skills.isNotEmpty) ...[
                            _buildSkillsSection(isSwahili),
                            const SizedBox(height: 20),
                          ],
                          _buildAboutSection(isSwahili),
                          const SizedBox(height: 20),
                          if (_portfolio.isNotEmpty) ...[
                            _buildPortfolioSection(isSwahili),
                            const SizedBox(height: 20),
                          ],
                          if (_badges.isNotEmpty) ...[
                            _buildCredentialsSection(isSwahili),
                            const SizedBox(height: 20),
                          ],
                          _buildStatsSection(isSwahili),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
      ),
      floatingActionButton: _isOwnProfile
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartnerSettingsPage(),
                  ),
                );
                _refresh();
              },
              backgroundColor: _kPrimary,
              child: const Icon(Icons.edit_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isSwahili) {
    final p = _partner!;
    final isVerified = p.verifications.overall == 'verified';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
            child: p.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded,
                    color: _kSecondary, size: 32)
                : null,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded,
                    color: Color(0xFF4CAF50), size: 18),
              ],
            ],
          ),
          const SizedBox(height: 6),
          TierBadge(tier: p.tier),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFC107), size: 18),
              const SizedBox(width: 4),
              Text(
                '${p.aggregateRating.toStringAsFixed(1)} ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              Text(
                isSwahili
                    ? '· ${p.jobsCompleted} kazi'
                    : '· ${p.jobsCompleted} jobs',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(bool isSwahili) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSwahili ? 'Ujuzi' : 'Skills',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _partner!.skills.map((skill) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SkillCategoryChip(
                  category: skill,
                  isSwahili: isSwahili,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isSwahili) {
    final p = _partner!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Kuhusu' : 'About',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.bio?.isNotEmpty == true
                ? p.bio!
                : (isSwahili ? 'Hakuna maelezo' : 'No bio available'),
            style: const TextStyle(
              fontSize: 13,
              color: _kSecondary,
              height: 1.5,
            ),
          ),
          if (!p.serviceArea.isEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: _kSecondary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.serviceArea.displayText,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.isActive
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF9E9E9E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                p.isActive
                    ? (isSwahili ? 'Anapatikana' : 'Available')
                    : (isSwahili ? 'Hapatikani' : 'Unavailable'),
                style: TextStyle(
                  fontSize: 12,
                  color: p.isActive
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(bool isSwahili) {
    final displayItems =
        _portfolio.length > 6 ? _portfolio.sublist(0, 6) : _portfolio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSwahili ? 'Kazi Zilizopita' : 'Portfolio',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            if (_portfolio.length > 6)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PortfolioManagerPage(
                        partnerId: widget.partnerId,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: _kPrimary,
                  minimumSize: const Size(48, 36),
                ),
                child: Text(
                  isSwahili ? 'Tazama Zote' : 'View All',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            return PortfolioItemCard(item: displayItems[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCredentialsSection(bool isSwahili) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSwahili ? 'Tuzo na Vyeti' : 'Credentials',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _badges.map((badge) {
            return BadgeChip(badge: badge, isSwahili: isSwahili);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isSwahili) {
    final p = _partner!;
    final responseText = p.responseTimeMinutes < 60
        ? '${p.responseTimeMinutes}m'
        : '${(p.responseTimeMinutes / 60).toStringAsFixed(1)}h';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSwahili ? 'Takwimu' : 'Stats',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PartnerStatCard(
                label: isSwahili ? 'Kazi' : 'Jobs',
                value: '${p.jobsCompleted}',
                icon: Icons.work_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PartnerStatCard(
                label: isSwahili ? 'Kiwango' : 'Rating',
                value: p.aggregateRating.toStringAsFixed(1),
                icon: Icons.star_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PartnerStatCard(
                label: isSwahili ? 'Muda wa Kujibu' : 'Response',
                value: responseText,
                icon: Icons.timer_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
