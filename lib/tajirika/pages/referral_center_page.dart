import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/partner_stat_card.dart';
import '../widgets/referral_card.dart';

class ReferralCenterPage extends StatefulWidget {
  const ReferralCenterPage({super.key});

  @override
  State<ReferralCenterPage> createState() => _ReferralCenterPageState();
}

class _ReferralCenterPageState extends State<ReferralCenterPage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  ReferralStats _stats = ReferralStats(referralCode: '');
  List<Referral> _referrals = [];
  bool _isLoading = true;
  String? _error;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    _userId ??= storage.getUser()?.userId;
    return storage.getAuthToken();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null || _userId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      final results = await Future.wait([
        TajirikaService.getReferralStats(token, _userId!),
        TajirikaService.getReferrals(token, _userId!),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as ReferralStats;
        final listResult = results[1] as ReferralListResult;
        _referrals = listResult.success ? listResult.referrals : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _copyReferralCode() {
    if (_stats.referralCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _stats.referralCode));
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sw ? 'Msimbo umenakiliwa' : 'Code copied to clipboard',
        ),
      ),
    );
  }

  void _shareReferralCode() {
    if (_stats.referralCode.isEmpty) return;
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final message = sw
        ? 'Jiunge na TAJIRI kama mtaalamu! Tumia msimbo wangu: ${_stats.referralCode}'
        : 'Join TAJIRI as a professional partner! Use my referral code: ${_stats.referralCode}';
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sw ? 'Ujumbe umenakiliwa' : 'Message copied to clipboard',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          sw ? 'Kituo cha Rufaa' : 'Referral Center',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kPrimary),
        elevation: 0.5,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _error != null
                ? _buildError(sw)
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReferralCodeCard(sw),
                          const SizedBox(height: 16),
                          _buildStatsRow(sw),
                          const SizedBox(height: 24),
                          _buildReferralList(sw),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildError(bool sw) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
          const SizedBox(height: 12),
          Text(
            _error ?? (sw ? 'Hitilafu' : 'Error'),
            style: const TextStyle(fontSize: 14, color: _kSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadData,
            child: Text(
              sw ? 'Jaribu tena' : 'Try again',
              style: const TextStyle(color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard(bool sw) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            sw ? 'Msimbo wako wa rufaa' : 'Your referral code',
            style: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 10),
          Text(
            _stats.referralCode.isNotEmpty ? _stats.referralCode : '---',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _copyReferralCode,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    sw ? 'Nakili' : 'Copy',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF555555)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _shareReferralCode,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(sw ? 'Shiriki' : 'Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool sw) {
    return Row(
      children: [
        Expanded(
          child: PartnerStatCard(
            label: sw ? 'Jumla' : 'Total Referred',
            value: _stats.totalReferred.toString(),
            icon: Icons.people_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PartnerStatCard(
            label: sw ? 'Waliothibitishwa' : 'Verified',
            value: _stats.verified.toString(),
            icon: Icons.verified_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PartnerStatCard(
            label: sw ? 'Kiasi' : 'Earned',
            value: 'TZS ${_stats.totalBonusEarned.toStringAsFixed(0)}',
            icon: Icons.monetization_on_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildReferralList(bool sw) {
    if (_referrals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.group_add_rounded,
              size: 48,
              color: _kSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              sw
                  ? 'Alika wataalamu wenzako'
                  : 'Invite fellow professionals',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              sw
                  ? 'Shiriki msimbo wako na upate bonasi'
                  : 'Share your code and earn bonuses',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _shareReferralCode,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(sw ? 'Shiriki Sasa' : 'Share Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Rufaa zako' : 'Your Referrals',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_referrals.length, (i) {
          return ReferralCard(
            referral: _referrals[i],
            isSwahili: sw,
          );
        }),
      ],
    );
  }
}
