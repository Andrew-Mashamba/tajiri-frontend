import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/flywheel_models.dart';
import '../../models/collaboration_models.dart';
import '../../services/creator_service.dart';
import '../../services/collaboration_service.dart';
import '../../services/payment_service.dart';
import '../../services/local_storage_service.dart';
import '../../models/payment_models.dart';
import '../../widgets/creator_tier_badge.dart';
import '../../widgets/streak_indicator.dart';
import '../../widgets/collaboration_card.dart';
import '../../l10n/app_strings_scope.dart';

class CreatorDashboardSection extends StatefulWidget {
  final int userId;

  const CreatorDashboardSection({super.key, required this.userId});

  @override
  State<CreatorDashboardSection> createState() => _CreatorDashboardSectionState();
}

class _CreatorDashboardSectionState extends State<CreatorDashboardSection> {
  final CreatorService _creatorService = CreatorService();
  final CollaborationService _collaborationService = CollaborationService();
  final PaymentService _paymentService = PaymentService();
  CreatorScore? _score;
  CreatorStreak? _streak;
  ViewerStreak? _viewerStreak;
  FundPayoutProjection? _projection;
  CreatorFundPool? _fundPool;
  List<CollaborationSuggestion> _collaborations = [];
  ContentCalendar? _calendar;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (kDebugMode) debugPrint('[CreatorDashboard] Loading data for user ${widget.userId}');
    try {
      final results = await Future.wait<dynamic>([
        _creatorService.getCreatorScore(creatorId: widget.userId),
        _creatorService.getCreatorStreak(creatorId: widget.userId),
        _creatorService.getFundPayoutProjection(creatorId: widget.userId),
        _collaborationService.getSuggestions(creatorId: widget.userId),
        _creatorService.getViewerStreak(userId: widget.userId),
        _paymentService.getCurrentPool(),
        _creatorService.getContentCalendar(creatorId: widget.userId),
      ]);

      if (mounted) {
        setState(() {
          _score = results[0] as CreatorScore?;
          _streak = results[1] as CreatorStreak?;
          _projection = results[2] as FundPayoutProjection?;
          _collaborations = (results[3] is List<CollaborationSuggestion>)
              ? results[3] as List<CollaborationSuggestion>
              : <CollaborationSuggestion>[];
          _viewerStreak = results[4] as ViewerStreak?;
          _fundPool = results[5] as CreatorFundPool?;
          _calendar = results[6] as ContentCalendar?;
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorDashboard] _loadData error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)),
        )),
      );
    }
    // Always show the dashboard for own profile — even with default/empty data
    // so the user knows the section exists and can access Analytics/Weekly Report.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Creator Dashboard title
            Text(
              strings?.creatorDashboard ?? 'Creator Dashboard',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            // Tier badge + streak row
            Row(
              children: [
                if (_score != null)
                  CreatorTierBadge(tier: _score!.tier, multiplier: _score!.tierMultiplier),
                if (_score != null && _streak != null) const SizedBox(width: 12),
                if (_streak != null)
                  StreakIndicator(days: _streak!.currentStreakDays, isFrozen: _streak!.isFrozen),
                if (_streak != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    strings?.streakDays ?? 'day streak',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ],
            ),
            // Viewer streak row
            if (_viewerStreak != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  StreakIndicator(days: _viewerStreak!.currentStreakDays, isFrozen: _viewerStreak!.isFrozen),
                  const SizedBox(width: 4),
                  Text(
                    strings?.viewingStreak ?? 'Viewing Streak',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ],
            // Multiplier breakdown
            if (_streak != null || _score != null) ...[
              const SizedBox(height: 12),
              Text(
                strings?.multipliers ?? 'Multipliers',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (_score != null)
                    _buildMultiplierItem(strings?.tierMultiplier ?? 'Tier', _score!.tierMultiplier),
                  if (_streak != null)
                    _buildMultiplierItem(strings?.streakMultiplier ?? 'Streak', _streak!.streakMultiplier),
                  if (_projection?.multipliers['community'] != null)
                    _buildMultiplierItem(
                      'Community',
                      (_projection!.multipliers['community'] as num?)?.toDouble() ?? 1.0,
                      subtitle: _buildCommunitySubtitle(),
                    ),
                  if (_projection?.multipliers['virality'] != null)
                    _buildMultiplierItem('Virality',
                        (_projection!.multipliers['virality'] as num?)?.toDouble() ?? 1.0),
                ],
              ),
            ],
            // Projected payout
            if (_projection != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings?.projectedPayout ?? 'Projected Payout',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                  Text(
                    'TSh ${_formatAmount(_projection!.projectedPayout)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
            ],
            // Fund pool info
            if (_fundPool != null && !_fundPool!.isDistributed) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings?.fundPool ?? 'Creator Fund',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                  Text(
                    'TSh ${_formatAmount(_fundPool!.totalAmount)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
              if (_fundPool!.month.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _fundPool!.month,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                  ),
                ),
            ],
            // Collaboration radar
            if (_collaborations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                strings?.collaborationRadar ?? 'Collaboration Radar',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 8),
              ..._collaborations.take(2).map((c) => CollaborationCard(
                suggestion: c,
                onAccept: () => _respondToCollab(c.id, 'accepted'),
                onDismiss: () => _respondToCollab(c.id, 'dismissed'),
              )),
            ],
            // Content calendar
            if (_calendar != null) ...[
              const SizedBox(height: 12),
              Text(
                strings?.contentCalendar ?? 'Content Calendar',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCalendarStat(Icons.description_outlined, '${_calendar!.draftsCount}', strings?.drafts ?? 'Drafts'),
                  const SizedBox(width: 16),
                  _buildCalendarStat(Icons.check_circle_outline, '${_calendar!.postsThisWeek}', strings?.thisWeek ?? 'This Week'),
                  if (_calendar!.scheduledCount > 0) ...[
                    const SizedBox(width: 16),
                    _buildCalendarStat(Icons.schedule_rounded, '${_calendar!.scheduledCount}', strings?.scheduled ?? 'Scheduled'),
                  ],
                ],
              ),
              if (_calendar!.suggestedPostTime != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${strings?.bestTimeToPost ?? "Best time to post"}: ${_calendar!.suggestedPostTime}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ],
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/weekly-report/${widget.userId}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(strings?.weeklyReport ?? 'Weekly Report', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/analytics/${widget.userId}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(strings?.viewAnalytics ?? 'Analytics', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToCollab(int suggestionId, String action) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return;
    await _collaborationService.respond(token: token, suggestionId: suggestionId, action: action);
    if (mounted) {
      setState(() {
        _collaborations.removeWhere((c) => c.id == suggestionId);
      });
    }
  }

  String? _buildCommunitySubtitle() {
    final multipliers = _projection?.multipliers;
    if (multipliers == null) return null;
    final replies = multipliers['community_replies'];
    final totalComments = multipliers['community_total_comments'];
    if (replies != null && totalComments != null) {
      return 'Replied to $replies of $totalComments comments';
    }
    return 'Reply to comments to boost this';
  }

  Widget _buildCalendarStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF999999)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
      ],
    );
  }

  Widget _buildMultiplierItem(String label, double value, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            const SizedBox(width: 4),
            Text('${value.toStringAsFixed(1)}x',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
            ),
          ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}
