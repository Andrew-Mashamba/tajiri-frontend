import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../services/analytics_service.dart';
import '../../l10n/app_strings_scope.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final int userId;

  const AnalyticsDashboardScreen({super.key, required this.userId});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsDashboard? _dashboard;
  AudienceInsight? _audience;
  String _engagementLevel = 'gentle';
  List<PostPerformance> _topPosts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    if (kDebugMode) debugPrint('[AnalyticsDashboard] Loading data for user ${widget.userId}');
    try {
      final results = await Future.wait<dynamic>([
        _analyticsService.getDashboard(creatorId: widget.userId),
        _analyticsService.getAudienceInsights(creatorId: widget.userId),
        _analyticsService.getEngagementLevel(userId: widget.userId),
        _analyticsService.getPostPerformance(creatorId: widget.userId),
      ]);
      if (kDebugMode) debugPrint('[AnalyticsDashboard] Data loaded: dashboard=${results[0] != null}, audience=${results[1] != null}');
      if (mounted) {
        setState(() {
          _dashboard = results[0] as AnalyticsDashboard?;
          _audience = results[1] as AudienceInsight?;
          _engagementLevel = (results[2] is String) ? results[2] as String : 'gentle';
          _topPosts = (results[3] is List<PostPerformance>)
              ? results[3] as List<PostPerformance>
              : <PostPerformance>[];
          _loading = false;
          if (_dashboard == null) _error = 'No analytics data';
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AnalyticsDashboard] Error: $e');
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
        title: Text(
          strings?.analyticsDashboard ?? 'Analytics Dashboard',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Color(0xFF666666))),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadData, child: Text(strings?.retry ?? 'Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(strings?.last30Days ?? 'Last 30 Days',
                          style: const TextStyle(color: Color(0xFF999999), fontSize: 13)),
                      const SizedBox(height: 12),
                      _buildStatsGrid(strings),
                      const SizedBox(height: 12),
                      // Engagement level badge
                      Row(
                        children: [
                          Text('Engagement: ',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A).withAlpha(13),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                            ),
                            child: Text(
                              _engagementLevel.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(strings?.avgEngagement ?? 'Avg Engagement',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_dashboard!.avgEngagementRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _dashboard!.engagementTrend == 'up' ? Icons.trending_up_rounded
                                      : _dashboard!.engagementTrend == 'down' ? Icons.trending_down_rounded
                                      : Icons.trending_flat_rounded,
                                  size: 20,
                                  color: const Color(0xFF666666),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInfoTile(
                            strings?.bestTime ?? 'Best Time',
                            _dashboard!.bestPostingTime.isNotEmpty ? _dashboard!.bestPostingTime : '—',
                            Icons.schedule_rounded,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInfoTile(
                            strings?.topFormat ?? 'Top Format',
                            _dashboard!.topContentFormat.isNotEmpty ? _dashboard!.topContentFormat : '—',
                            Icons.videocam_rounded,
                          )),
                        ],
                      ),
                      if (_audience != null) ...[
                        const SizedBox(height: 20),
                        Text(strings?.audienceInsights ?? 'Audience Insights',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInfoTile(
                              strings?.topCity ?? 'Top City',
                              _audience!.topCity.isNotEmpty ? _audience!.topCity : '—',
                              Icons.location_on_rounded,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInfoTile(
                              strings?.peakActivity ?? 'Peak Activity',
                              _audience!.peakActivityTime.isNotEmpty ? _audience!.peakActivityTime : '—',
                              Icons.show_chart_rounded,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(strings?.activeFollowers ?? 'Active Followers',
                                  style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                              Text(
                                _formatCount(_audience!.activeFollowersCount),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_dashboard!.dailyMetrics.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Views (30 days)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 12),
                        _buildMiniChart(),
                      ],
                      // Top posts section
                      if (_topPosts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(strings?.topPosts ?? 'Top Posts',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 12),
                        ..._topPosts.take(5).map((post) => _buildPostPerformanceTile(post)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsGrid(dynamic strings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatTile('Views', _formatCount(_dashboard!.totalViews), Icons.visibility_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile('Likes', _formatCount(_dashboard!.totalLikes), Icons.favorite_outline_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatTile('Shares', _formatCount(_dashboard!.totalShares), Icons.share_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile(strings?.postsThisMonth ?? 'Posts', '${_dashboard!.postsCount30d}', Icons.article_outlined)),
          ],
        ),
      ],
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

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF999999)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: child,
    );
  }

  Widget _buildMiniChart() {
    final metrics = _dashboard!.dailyMetrics;
    final maxViews = metrics.fold<int>(0, (max, m) => m.views > max ? m.views : max);
    if (maxViews == 0) return const SizedBox.shrink();
    return _buildCard(
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: metrics.map((m) {
            final ratio = m.views / maxViews;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: (ratio * 60).clamp(2, 60),
                  decoration: BoxDecoration(
                    color: Color.lerp(const Color(0xFF1A1A1A).withAlpha(51), const Color(0xFF1A1A1A), ratio),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPostPerformanceTile(PostPerformance post) {
    final snippet = post.threadTitle != null && post.threadTitle!.isNotEmpty
        ? post.threadTitle!
        : 'Post #${post.postId}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPostStat(Icons.visibility_outlined, _formatCount(post.views)),
                const SizedBox(width: 16),
                _buildPostStat(Icons.favorite_outline_rounded, _formatCount(post.likes)),
                const SizedBox(width: 16),
                _buildPostStat(Icons.show_chart_rounded, '${post.engagementRate.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF999999)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
