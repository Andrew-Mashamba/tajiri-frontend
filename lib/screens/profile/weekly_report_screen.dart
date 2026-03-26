import 'package:flutter/material.dart';
import '../../models/payment_models.dart';
import '../../services/creator_service.dart';
import '../../services/local_storage_service.dart';
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
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final report = await _creatorService.getWeeklyReport(widget.userId, token);
      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
          if (report == null) _error = 'No report available';
        });
      }
    } catch (e) {
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
          strings?.weeklyReport ?? 'Weekly Report',
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
                      TextButton(onPressed: _loadReport, child: Text(strings?.retry ?? 'Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReport,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
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
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(context, '/post/${_report!.bestPostId}'),
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
                    ],
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
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: child,
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
        color: isUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isUp ? "+" : ""}${percent.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
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
