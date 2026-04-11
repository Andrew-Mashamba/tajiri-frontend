// lib/my_baby/pages/summary_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SummaryPage extends StatefulWidget {
  final Baby baby;

  const SummaryPage({super.key, required this.baby});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final MyBabyService _service = MyBabyService();

  bool _isLoading = true;
  String? _token;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Today's summary
  DailySummary? _todaySummary;

  // Last week's summary for comparison
  DailySummary? _lastWeekSummary;

  // Milestones for alert
  List<BabyMilestone> _milestones = [];

  // Pattern data (from multiple days)
  Map<String, dynamic>? _rawSummaryData;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getDailySummary(_token!, widget.baby.id, date: _selectedDate),
        _service.getDailySummary(
          _token!,
          widget.baby.id,
          date: _selectedDate.subtract(const Duration(days: 7)),
        ),
        _service.getMilestones(_token!, widget.baby.id),
      ]);

      if (!mounted) return;

      final todayData = results[0] as Map<String, dynamic>?;
      final lastWeekData = results[1] as Map<String, dynamic>?;
      final milestonesResult = results[2] as MyBabyListResult<BabyMilestone>;

      setState(() {
        _isLoading = false;
        _rawSummaryData = todayData;

        if (todayData != null) {
          _todaySummary = DailySummary.fromJson(todayData);
        }
        if (lastWeekData != null) {
          _lastWeekSummary = DailySummary.fromJson(lastWeekData);
        }
        if (milestonesResult.success) {
          _milestones = milestonesResult.items;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.baby.dateOfBirth,
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  List<BabyMilestone> get _upcomingMilestones {
    final babyMonths = widget.baby.ageInMonths;
    return _milestones
        .where((m) => !m.isDone && m.ageMonths >= babyMonths && m.ageMonths <= babyMonths + 1)
        .toList();
  }

  // ─── Pattern Detection from raw data ────────────────────────

  /// Detect feeding pattern: find the most common feeding hour.
  String? _detectFeedingPattern() {
    final feedingsRaw = _rawSummaryData?['feedings'] as List?;
    if (feedingsRaw == null || feedingsRaw.length < 3) {
      // Fall back to count-based insight
      if (_todaySummary != null && _todaySummary!.feedCount > 8) {
        return _sw
            ? 'Mtoto ananyonya mara nyingi leo - hii ni kawaida wakati wa ukuaji wa haraka.'
            : 'Baby is feeding frequently today - this is normal during growth spurts.';
      }
      return null;
    }

    final hours = <int>[];
    for (final f in feedingsRaw) {
      if (f is Map) {
        final dateStr = f['date'] as String? ?? f['logged_at'] as String?;
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null) hours.add(dt.hour);
        }
      }
    }
    if (hours.length < 3) return null;

    final hourCounts = <int, int>{};
    for (final h in hours) {
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    final topHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b);

    return _sw
        ? 'Mtoto ananyonya zaidi saa ${_formatHour(topHour.key)}'
        : 'Baby feeds most around ${_formatHour(topHour.key)}';
  }

  /// Detect sleep pattern: compare actual sleep to age-appropriate recommendations.
  String? _detectSleepPattern() {
    if (_todaySummary == null || _todaySummary!.sleepMinutes <= 0) return null;
    final sleepHours = _todaySummary!.sleepMinutes / 60.0;
    final months = widget.baby.ageInMonths;

    // Age-appropriate sleep recommendations (total daily hours)
    final String recRange;
    final double recMin;
    if (months < 3) {
      recRange = '14-17';
      recMin = 14;
    } else if (months < 12) {
      recRange = '12-15';
      recMin = 12;
    } else {
      recRange = '11-14';
      recMin = 11;
    }

    if (sleepHours < recMin * 0.7) {
      return _sw
          ? 'Usingizi wa leo (${sleepHours.toStringAsFixed(1)}h) ni chini ya mapendekezo ($recRange masaa). Hakikisha mtoto anapumzika vizuri.'
          : "Today's sleep (${sleepHours.toStringAsFixed(1)}h) is below the recommended $recRange hours. Ensure baby gets enough rest.";
    }
    return null;
  }

  /// Detect diaper pattern: dehydration alert.
  String? _detectDiaperPattern() {
    if (_todaySummary == null) return null;
    final s = _todaySummary!;
    if (s.diaperWet > 0 && s.diaperWet < 6) {
      return _sw
          ? 'Nepi za mkojo ni chini ya 6 - hakikisha mtoto anapata maji ya kutosha.'
          : 'Wet diapers below 6 - ensure baby is getting enough fluids.';
    }
    return null;
  }

  /// Collect all detected pattern insights.
  List<String> get _patternInsights {
    final insights = <String>[];

    // Check API-provided pattern first
    if (_rawSummaryData != null) {
      final feedPattern = _rawSummaryData!['feed_pattern'] as String?;
      if (feedPattern != null && feedPattern.isNotEmpty) {
        insights.add(feedPattern);
      }
    }

    final feeding = _detectFeedingPattern();
    if (feeding != null && !insights.contains(feeding)) insights.add(feeding);

    final sleep = _detectSleepPattern();
    if (sleep != null) insights.add(sleep);

    final diaper = _detectDiaperPattern();
    if (diaper != null) insights.add(diaper);

    return insights.take(3).toList();
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Muhtasari' : 'Summary',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _loadData,
                            child: Text(sw ? 'Jaribu tena' : 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _kPrimary,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      children: [
                        // Date selector
                        _buildDateSelector(sw),
                        const SizedBox(height: 16),

                        // Daily summary stat cards
                        _buildDailySummary(sw),
                        const SizedBox(height: 16),

                        // Weekly comparison
                        if (_lastWeekSummary != null && _todaySummary != null) ...[
                          _buildWeeklyComparison(sw),
                          const SizedBox(height: 16),
                        ],

                        // Pattern insights (2-3 cards)
                        if (_patternInsights.isNotEmpty) ...[
                          ..._patternInsights.map((insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildPatternCardForInsight(sw, insight),
                          )),
                          const SizedBox(height: 6),
                        ],

                        // Milestone alerts
                        if (_upcomingMilestones.isNotEmpty) ...[
                          _buildMilestoneAlert(sw),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDateSelector(bool sw) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: _kPrimary),
            const SizedBox(width: 10),
            Text(
              isToday
                  ? (sw ? 'Leo' : 'Today')
                  : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary),
            ),
            if (!isToday) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = DateTime.now());
                  _loadData();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sw ? 'Leo' : 'Today',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                ),
              ),
            ],
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary(bool sw) {
    final s = _todaySummary;
    final feedCount = s?.feedCount ?? 0;
    final feedMinutes = s?.totalFeedingMinutes ?? 0;
    final bottleMl = s?.totalBottleMl ?? 0;
    final sleepHours = (s?.sleepMinutes ?? 0) / 60.0;
    final napCount = s?.napCount ?? 0;
    final diaperWet = s?.diaperWet ?? 0;
    final diaperDirty = s?.diaperDirty ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Muhtasari wa Siku' : 'Daily Summary',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Feeds
            Expanded(
              child: _StatCard(
                icon: Icons.restaurant_rounded,
                value: '$feedCount',
                label: sw ? 'Kulisha' : 'Feeds',
                subtitle: feedMinutes > 0
                    ? '${feedMinutes}min'
                    : bottleMl > 0
                        ? '${bottleMl}ml'
                        : '',
              ),
            ),
            const SizedBox(width: 10),
            // Sleep
            Expanded(
              child: _StatCard(
                icon: Icons.bedtime_rounded,
                value: sleepHours.toStringAsFixed(1),
                label: sw ? 'Masaa' : 'Hours',
                subtitle: napCount > 0
                    ? (sw
                        ? 'Usingizi $napCount'
                        : '$napCount naps')
                    : '',
              ),
            ),
            const SizedBox(width: 10),
            // Diapers
            Expanded(
              child: _StatCard(
                icon: Icons.baby_changing_station_rounded,
                value: '${diaperWet + diaperDirty}',
                label: sw ? 'Nepi' : 'Diapers',
                subtitle: sw
                    ? 'M:$diaperWet C:$diaperDirty'
                    : 'W:$diaperWet D:$diaperDirty',
              ),
            ),
          ],
        ),
        if (s == null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sw
                        ? 'Bado hakuna data kwa tarehe hii'
                        : 'No data available for this date',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyComparison(bool sw) {
    final today = _todaySummary!;
    final lastWeek = _lastWeekSummary!;

    final feedDiff = today.feedCount - lastWeek.feedCount;
    final sleepDiff =
        ((today.sleepMinutes - lastWeek.sleepMinutes) / 60.0);
    final diaperDiff = (today.diaperWet + today.diaperDirty) -
        (lastWeek.diaperWet + lastWeek.diaperDirty);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Wiki Hii vs Wiki Iliyopita' : 'This Week vs Last Week',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          _ComparisonRow(
            label: sw ? 'Kulisha' : 'Feeds',
            diff: feedDiff,
            unit: '',
            isSwahili: sw,
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: sw ? 'Usingizi' : 'Sleep',
            diff: sleepDiff.round(),
            unit: sw ? ' masaa' : ' hrs',
            isSwahili: sw,
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: sw ? 'Nepi' : 'Diapers',
            diff: diaperDiff,
            unit: '',
            isSwahili: sw,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCardForInsight(bool sw, String insight) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_rounded, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Muundo Uliogunduliwa' : 'Pattern Detected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight,
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneAlert(bool sw) {
    final babyMonths = widget.baby.ageInMonths;
    final upcoming = _upcomingMilestones;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw
                      ? 'Mtoto ana miezi $babyMonths! Hatua zinazokuja:'
                      : 'Baby is $babyMonths months! Upcoming milestones:',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...upcoming.take(5).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _kSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.title,
                        style: const TextStyle(
                            fontSize: 13, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: _kPrimary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: _kPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Comparison Row ───────────────────────────────────────────────

class _ComparisonRow extends StatelessWidget {
  final String label;
  final int diff;
  final String unit;
  final bool isSwahili;

  const _ComparisonRow({
    required this.label,
    required this.diff,
    required this.unit,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = diff > 0;
    final isSame = diff == 0;

    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: _kPrimary),
        ),
        const Spacer(),
        if (isSame)
          Text(
            isSwahili ? 'Sawa' : 'Same',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          )
        else ...[
          Icon(
            isUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: _kPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            '${isUp ? '+' : ''}$diff$unit',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
