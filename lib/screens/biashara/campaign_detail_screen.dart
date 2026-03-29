import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/ad_models.dart';
import '../../services/ad_service.dart';
import '../../services/local_storage_service.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  AdCampaign? _campaign;
  AdPerformance? _performance;
  bool _loading = true;
  bool _actionLoading = false;
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
      AdService.getCampaign(_token, widget.campaignId),
      AdService.getCampaignPerformance(_token, widget.campaignId),
    ]);

    if (!mounted) return;
    setState(() {
      _campaign = results[0] as AdCampaign?;
      _performance = results[1] as AdPerformance?;
      _loading = false;
    });
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
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  Future<void> _performAction(Future<bool> Function() action) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    final success = await action();
    if (success) {
      await _loadData();
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Action failed')));
    }

    if (mounted) setState(() => _actionLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _campaign?.title ?? s.kampeni,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _campaign == null
                ? Center(
                    child: Text(
                      s.noData,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Status badge
                        _buildStatusHeader(isDark),
                        const SizedBox(height: 20),

                        // Metric cards
                        _buildMetricCards(s, isDark),
                        const SizedBox(height: 20),

                        // Budget progress
                        _buildBudgetProgress(s, isDark),
                        const SizedBox(height: 20),

                        // Creative preview
                        if (_campaign!.creatives != null &&
                            _campaign!.creatives!.isNotEmpty)
                          _buildCreativePreview(s, isDark),

                        const SizedBox(height: 20),

                        // Actions
                        _buildActions(s, isDark),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isDark) {
    final campaign = _campaign!;
    final color = _statusColor(campaign.status);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _statusLabel(campaign.status),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          campaign.campaignType.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (campaign.rejectionReason != null) ...[
          const Spacer(),
          Flexible(
            child: Text(
              campaign.rejectionReason!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B0000)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCards(AppStrings s, bool isDark) {
    final perf = _performance;
    return Row(
      children: [
        _metricCard(s.maonyesho, _formatNumber((perf?.totalImpressions ?? 0).toDouble()), isDark),
        const SizedBox(width: 8),
        _metricCard(s.mibofyo, _formatNumber((perf?.totalClicks ?? 0).toDouble()), isDark),
        const SizedBox(width: 8),
        _metricCard(s.ctr, '${(perf?.ctr ?? 0).toStringAsFixed(2)}%', isDark),
        const SizedBox(width: 8),
        _metricCard(s.matumizi, 'TZS ${_formatNumber(perf?.totalSpend ?? 0)}', isDark),
      ],
    );
  }

  Widget _metricCard(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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

  Widget _buildBudgetProgress(AppStrings s, bool isDark) {
    final campaign = _campaign!;
    final progress = campaign.totalBudget > 0
        ? (campaign.spentAmount / campaign.totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
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
          Text(
            s.bajeti,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TZS ${_formatNumber(campaign.spentAmount)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'TZS ${_formatNumber(campaign.totalBudget)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreativePreview(AppStrings s, bool isDark) {
    final creative = _campaign!.creatives!.first;

    return Container(
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
          Text(
            s.tangazoLako,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (creative.mediaUrl != null && creative.mediaUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                creative.mediaUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 140,
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                  child: const Center(child: Icon(Icons.broken_image_rounded)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            creative.headline,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (creative.bodyText != null && creative.bodyText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              creative.bodyText!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(AppStrings s, bool isDark) {
    final status = _campaign!.status;
    final List<Widget> buttons = [];

    if (status == 'active') {
      buttons.add(_actionButton(
        s.simamisha,
        Icons.pause_rounded,
        () => _performAction(() => AdService.pauseCampaign(_token, widget.campaignId)),
        isDark,
      ));
      buttons.add(const SizedBox(width: 12));
      buttons.add(_actionButton(
        s.ghairi,
        Icons.cancel_rounded,
        () => _performAction(() => AdService.cancelCampaign(_token, widget.campaignId)),
        isDark,
        outlined: true,
      ));
    } else if (status == 'paused') {
      buttons.add(_actionButton(
        s.endeleza,
        Icons.play_arrow_rounded,
        () => _performAction(() => AdService.resumeCampaign(_token, widget.campaignId)),
        isDark,
      ));
      buttons.add(const SizedBox(width: 12));
      buttons.add(_actionButton(
        s.ghairi,
        Icons.cancel_rounded,
        () => _performAction(() => AdService.cancelCampaign(_token, widget.campaignId)),
        isDark,
        outlined: true,
      ));
    } else if (status == 'draft') {
      buttons.add(_actionButton(
        s.edit,
        Icons.edit_rounded,
        () {
          // Could navigate to edit screen; for now just show a message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit coming soon')),
          );
        },
        isDark,
      ));
      buttons.add(const SizedBox(width: 12));
      buttons.add(_actionButton(
        s.delete,
        Icons.delete_rounded,
        () => _performAction(() => AdService.cancelCampaign(_token, widget.campaignId)),
        isDark,
        outlined: true,
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return _actionLoading
        ? const Center(child: CircularProgressIndicator())
        : Row(children: buttons.map((b) => b is SizedBox ? b : Expanded(child: b)).toList());
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDark, {
    bool outlined = false,
  }) {
    if (outlined) {
      return SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
          foregroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
