import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/ad_models.dart';
import '../../services/ad_service.dart';
import '../../services/local_storage_service.dart';

class BiasharaHomeScreen extends StatefulWidget {
  const BiasharaHomeScreen({super.key});

  @override
  State<BiasharaHomeScreen> createState() => _BiasharaHomeScreenState();
}

class _BiasharaHomeScreenState extends State<BiasharaHomeScreen> {
  List<AdCampaign> _campaigns = [];
  double _balance = 0.0;
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (_token == null) return;

    final results = await Future.wait([
      AdService.getCampaigns(_token),
      AdService.getAdBalance(_token),
    ]);

    if (!mounted) return;
    setState(() {
      _campaigns = results[0] as List<AdCampaign>;
      _balance = results[1] as double;
      _loading = false;
    });
  }

  int get _todayImpressions {
    // Sum from all active campaigns' daily stats would need performance data.
    // For now show a placeholder based on campaign count.
    return 0;
  }

  int get _todayClicks => 0;

  double get _todaySpend {
    return _campaigns
        .where((c) => c.status == 'active')
        .fold(0.0, (sum, c) => sum + c.spentAmount);
  }

  String _statusLabel(String status) {
    final s = AppStringsScope.of(context)!;
    switch (status) {
      case 'draft':
        return s.rasimu;
      case 'pending_review':
        return s.inakaguliwa;
      case 'active':
        return s.inatumika;
      case 'paused':
        return s.imesimamishwa;
      case 'completed':
        return s.imekamilika;
      case 'rejected':
        return s.imekataliwa;
      case 'cancelled':
        return s.imefutwa;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF1A1A1A);
      case 'paused':
        return const Color(0xFF999999);
      case 'draft':
        return const Color(0xFFCCCCCC);
      case 'pending_review':
        return const Color(0xFF666666);
      case 'completed':
        return const Color(0xFF444444);
      case 'rejected':
        return const Color(0xFF8B0000);
      case 'cancelled':
        return const Color(0xFFAAAAAA);
      default:
        return const Color(0xFF999999);
    }
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.biashara, maxLines: 1, overflow: TextOverflow.ellipsis),
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Balance card
                    _buildBalanceCard(s, isDark),
                    const SizedBox(height: 16),

                    // Today's summary
                    _buildSummaryRow(s, isDark),
                    const SizedBox(height: 24),

                    // Campaign list header
                    Text(
                      s.kampeni,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    if (_campaigns.isEmpty) _buildEmptyState(s, isDark),

                    ..._campaigns.map((c) => _buildCampaignTile(c, s, isDark)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/biashara/create').then((_) => _loadData()),
        backgroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
        foregroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.tengenezaKampeni, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildBalanceCard(AppStrings s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.salio,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'TZS ${_formatNumber(_balance)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/biashara/deposit').then((_) => _loadData()),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDark ? const Color(0xFF555555) : const Color(0xFF1A1A1A),
                ),
              ),
              child: Text(
                s.ongezaSalio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(AppStrings s, bool isDark) {
    return Row(
      children: [
        _summaryCard(s.maonyesho, _todayImpressions.toString(), isDark),
        const SizedBox(width: 8),
        _summaryCard(s.mibofyo, _todayClicks.toString(), isDark),
        const SizedBox(width: 8),
        _summaryCard(s.matumizi, 'TZS ${_formatNumber(_todaySpend)}', isDark),
      ],
    );
  }

  Widget _summaryCard(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 64,
            color: isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 16),
          Text(
            s.hakupaKampeni,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            s.anzaKutangaza,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignTile(AdCampaign campaign, AppStrings s, bool isDark) {
    final statusColor = _statusColor(campaign.status);
    final progress = campaign.totalBudget > 0
        ? (campaign.spentAmount / campaign.totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/biashara/campaign/${campaign.id}')
              .then((_) => _loadData());
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      campaign.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(campaign.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Budget progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'TZS ${_formatNumber(campaign.spentAmount)} / ${_formatNumber(campaign.totalBudget)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    campaign.campaignType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
