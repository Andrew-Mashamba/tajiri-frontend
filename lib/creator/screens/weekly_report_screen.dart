import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/payment_models.dart';
import '../services/creator_service.dart';
import '../../l10n/app_strings_scope.dart';

class WeeklyReportScreen extends StatefulWidget {
  final int userId;

  const WeeklyReportScreen({super.key, required this.userId});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final CreatorService _creatorService = CreatorService();
  WeeklyReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() { _loading = true; _error = null; });
    if (kDebugMode) debugPrint('[WeeklyReportScreen] Loading report for user ${widget.userId}');
    try {
      final report = await _creatorService.getWeeklyReport(widget.userId);
      if (kDebugMode) debugPrint('[WeeklyReportScreen] Report loaded: ${report != null}');
      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
          if (report == null) _error = 'No report available';
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[WeeklyReportScreen] Error: $e');
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          strings?.weeklyReport ?? 'Weekly Report',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              )
            : _error != null
                ? _buildErrorState(strings)
                : RefreshIndicator(
                    onRefresh: _loadReport,
                    color: const Color(0xFF1A1A1A),
                    child: ListView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                      // Week range
                      Text(
                        '${_report!.weekStart} — ${_report!.weekEnd}',
                        style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      // Earnings card
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(strings?.totalEarnings ?? 'Total Earnings',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TSh ${_formatAmount(_report!.totalEarnings)}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                                ),
                                const SizedBox(width: 8),
                                _buildTrendChip(_report!.earningsChangePercent),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Stats grid
                      Row(
                        children: [
                          Expanded(child: _buildStatTile(strings?.engagementTrend ?? 'Trend',
                              _trendLabel(_report!.engagementTrend, strings), _trendIcon(_report!.engagementTrend))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatTile(strings?.followerChange ?? 'Followers',
                              '${_report!.followerChange >= 0 ? "+" : ""}${_report!.followerChange}', Icons.people_outline_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStatTile(strings?.threadsTriggered ?? 'Threads',
                              '${_report!.threadsTriggered}', Icons.local_fire_department_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatTile('Views',
                              _formatAmount(_report!.totalViews.toDouble()), Icons.visibility_outlined)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Best post
                      if (_report!.bestPostId != null && _report!.bestPostId! > 0)
                        _buildCard(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, '/post/${_report!.bestPostId}'),
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: [
                                const Icon(Icons.emoji_events_rounded, size: 24, color: Color(0xFF1A1A1A)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(strings?.bestPost ?? 'Best Post',
                                          style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                                      Text('${_report!.bestPostLikes} likes',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF999999)),
                              ],
                            ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Posting tip
                      _buildCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, size: 20, color: Color(0xFF999999)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings?.postingTip ?? 'Tip of the Week',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _report!.postingTip ?? (strings?.defaultPostingTip ?? 'Post during peak hours when your audience is most active for better engagement.'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A), height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildErrorState(AppStrings? s) {
    final isSw = s?.isSwahili ?? false;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              isSw ? 'Imeshindwa kupakua ripoti' : 'Could not load report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _loadReport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFFE5E5E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(s?.retry ?? 'Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF999999)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildTrendChip(double percent) {
    final isUp = percent >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUp ? const Color(0xFFF5F5F5) : const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isUp ? "+" : ""}${percent.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isUp ? const Color(0xFF1A1A1A) : const Color(0xFFD32F2F),
        ),
      ),
    );
  }

  String _trendLabel(String trend, dynamic strings) {
    switch (trend) {
      case 'up': return strings?.trendUp ?? 'Trending Up';
      case 'down': return strings?.trendDown ?? 'Trending Down';
      default: return strings?.trendStable ?? 'Stable';
    }
  }

  IconData _trendIcon(String trend) {
    switch (trend) {
      case 'up': return Icons.trending_up_rounded;
      case 'down': return Icons.trending_down_rounded;
      default: return Icons.trending_flat_rounded;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}
