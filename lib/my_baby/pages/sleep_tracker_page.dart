// lib/my_baby/pages/sleep_tracker_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SleepTrackerPage extends StatefulWidget {
  final Baby baby;

  const SleepTrackerPage({super.key, required this.baby});

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  final MyBabyService _service = MyBabyService();
  String? _token;
  int? _currentUserId;

  List<SleepSession> _sessions = [];
  List<SleepSession> _weekSessions = []; // last 7 days
  bool _isLoading = true;
  SleepSession? _activeSession;
  Timer? _elapsedTimer;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _currentUserId = LocalStorageService.instanceSync?.getUser()?.userId;
    _loadSessions();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getSleepHistory(
        _token!,
        widget.baby.id,
        date: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _sessions = result.items;
          _activeSession = _sessions.where((s) => s.isActive).firstOrNull;
          if (_activeSession != null) {
            _startElapsedTimer();
          }
        }
      });
      // Load 7-day history in background
      _loadWeekHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindikana kupakia' : 'Failed to load')),
      );
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _startSleep(String type) async {
    if (_token == null || _activeSession != null) return;
    try {
      final result = await _service.logSleep(
        token: _token!,
        babyId: widget.baby.id,
        startTime: DateTime.now(),
        type: type,
      );
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() {
          _activeSession = result.data;
          _sessions.insert(0, result.data!);
        });
        _startElapsedTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Hitilafu imetokea' : 'An error occurred')),
      );
    }
  }

  Future<void> _stopSleep() async {
    if (_token == null || _activeSession == null || _activeSession!.id == null) return;
    try {
      final result = await _service.updateSleep(
        token: _token!,
        sessionId: _activeSession!.id!,
        endTime: DateTime.now(),
      );
      if (!mounted) return;
      if (result.success) {
        _elapsedTimer?.cancel();
        _loadSessions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (_sw ? 'Imeshindikana' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Hitilafu imetokea' : 'An error occurred')),
      );
    }
  }

  // ─── Wake Window Logic ────────────────────────────────────────

  /// Returns suggested wake window in minutes based on baby age in months
  int _wakeWindowMinutes() {
    final months = widget.baby.ageInMonths;
    if (months < 3) return 75; // 60-90 avg
    if (months < 6) return 105; // 90-120 avg
    if (months < 12) return 150; // 2-3hrs avg
    return 210; // 3-4hrs avg
  }

  String _wakeWindowLabel() {
    final months = widget.baby.ageInMonths;
    if (months < 3) return '60-90 min';
    if (months < 6) return '90-120 min';
    if (months < 12) return '2-3 hrs';
    return '3-4 hrs';
  }

  String? _nextNapSuggestion() {
    // Find the most recent ended session
    final ended = _sessions.where((s) => !s.isActive && s.endTime != null).toList();
    if (ended.isEmpty) return null;
    ended.sort((a, b) => b.endTime!.compareTo(a.endTime!));
    final lastWake = ended.first.endTime!;
    final nextNap = lastWake.add(Duration(minutes: _wakeWindowMinutes()));
    if (nextNap.isBefore(DateTime.now())) {
      return _sw ? 'Mtoto anapaswa kulala sasa!' : 'Baby should nap now!';
    }
    final h = nextNap.hour.toString().padLeft(2, '0');
    final m = nextNap.minute.toString().padLeft(2, '0');
    return _sw ? 'Usingizi unaofuata ~$h:$m' : 'Next nap ~$h:$m';
  }

  // ─── Summary Helpers ──────────────────────────────────────────

  int _totalSleepMinutesToday() {
    int total = 0;
    for (final s in _sessions) {
      if (s.endTime != null) {
        total += s.endTime!.difference(s.startTime).inMinutes;
      } else {
        total += DateTime.now().difference(s.startTime).inMinutes;
      }
    }
    return total;
  }

  int _napCount() => _sessions.where((s) => s.type == 'nap').length;

  int _longestStretchMinutes() {
    int longest = 0;
    for (final s in _sessions) {
      final dur = s.endTime != null
          ? s.endTime!.difference(s.startTime).inMinutes
          : DateTime.now().difference(s.startTime).inMinutes;
      if (dur > longest) longest = dur;
    }
    return longest;
  }

  String _formatMinutes(int mins) {
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  // ─── Weekly Chart ─────────────────────────────────────────────

  Future<void> _loadWeekHistory() async {
    if (_token == null) return;
    final now = DateTime.now();
    final allSessions = <SleepSession>[];

    // Load last 7 days in parallel
    final futures = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _service.getSleepHistory(_token!, widget.baby.id, date: day);
    });

    try {
      final results = await Future.wait(futures);
      for (final result in results) {
        if (result.success) {
          allSessions.addAll(result.items);
        }
      }
      if (mounted) {
        setState(() => _weekSessions = allSessions);
      }
    } catch (_) {}
  }

  /// Groups sessions by date and returns total sleep hours per day for last 7 days
  Map<DateTime, double> _weeklyData() {
    final now = DateTime.now();
    final data = <DateTime, double>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      data[day] = 0;
    }

    for (final s in _weekSessions) {
      final dayKey = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      if (data.containsKey(dayKey)) {
        final mins = s.endTime != null
            ? s.endTime!.difference(s.startTime).inMinutes
            : (dayKey == DateTime(now.year, now.month, now.day)
                ? now.difference(s.startTime).inMinutes
                : 0);
        data[dayKey] = (data[dayKey] ?? 0) + (mins / 60.0);
      }
    }
    return data;
  }

  Widget _buildWeeklyChart() {
    final sw = _sw;
    final data = _weeklyData();
    if (data.isEmpty) return const SizedBox.shrink();

    final maxHours = data.values.fold<double>(1, (a, b) => a > b ? a : b);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayAbbrs = sw
        ? ['Jpi', 'Jtt', 'Jnn', 'Alh', 'Ijm', 'Jmm', 'Jmm']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Muhtasari wa Wiki' : 'Weekly Overview',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.entries.map((entry) {
                final hours = entry.value;
                final barHeight = maxHours > 0 ? (hours / maxHours) * 100 : 0.0;
                final isToday = entry.key == today;
                final dayIdx = (entry.key.weekday - 1) % 7;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          hours > 0 ? '${hours.toStringAsFixed(1)}h' : '',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isToday ? _kPrimary : _kSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight.clamp(4.0, 100.0),
                          decoration: BoxDecoration(
                            color: isToday
                                ? _kPrimary
                                : _kPrimary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayAbbrs[dayIdx],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? _kPrimary : _kSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _sw ? 'Kufuatilia Usingizi' : 'Sleep Tracker',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      floatingActionButton: _activeSession == null
          ? FloatingActionButton.extended(
              backgroundColor: _kPrimary,
              onPressed: _showStartSleepSheet,
              icon: const Icon(Icons.bedtime_rounded, color: Colors.white),
              label: Text(
                _sw ? 'Anza Usingizi' : 'Start Sleep',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadSessions,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Active sleep indicator
                    if (_activeSession != null) _buildActiveCard(),

                    // Nap suggestion card
                    if (_activeSession == null) _buildNapSuggestionCard(),

                    const SizedBox(height: 16),

                    // Today's summary
                    _buildSummaryCard(),

                    const SizedBox(height: 16),

                    // Weekly chart
                    if (_weekSessions.isNotEmpty) ...[
                      _buildWeeklyChart(),
                      const SizedBox(height: 16),
                    ],

                    // History
                    _buildHistorySection(),
                  ],
                ),
              ),
      ),
    );
  }

  void _showStartSleepSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _sw ? 'Aina ya Usingizi' : 'Sleep Type',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SleepTypeButton(
                      icon: Icons.wb_sunny_rounded,
                      label: _sw ? 'Usingizi wa Mchana' : 'Nap',
                      onTap: () {
                        Navigator.pop(ctx);
                        _startSleep('nap');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SleepTypeButton(
                      icon: Icons.nightlight_round,
                      label: _sw ? 'Usingizi wa Usiku' : 'Night',
                      onTap: () {
                        Navigator.pop(ctx);
                        _startSleep('night');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCard() {
    final elapsed = DateTime.now().difference(_activeSession!.startTime);
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final isNap = _activeSession!.type == 'nap';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isNap ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            isNap
                ? (_sw ? 'Usingizi wa Mchana' : 'Nap in progress')
                : (_sw ? 'Usingizi wa Usiku' : 'Night sleep in progress'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '$h:$m:$s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _stopSleep,
              icon: const Icon(Icons.stop_rounded),
              label: Text(
                _sw ? 'Simamisha' : 'Stop',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNapSuggestionCard() {
    final suggestion = _nextNapSuggestion();
    if (suggestion == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: _kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _sw
                      ? 'Dirisha la kuamka: ${_wakeWindowLabel()}'
                      : 'Wake window: ${_wakeWindowLabel()}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalMins = _totalSleepMinutesToday();
    final naps = _napCount();
    final longest = _longestStretchMinutes();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sw ? 'Muhtasari wa Leo' : "Today's Summary",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryItem(
                label: _sw ? 'Jumla' : 'Total',
                value: _formatMinutes(totalMins),
              ),
              _SummaryItem(
                label: _sw ? 'Nap' : 'Naps',
                value: '$naps',
              ),
              _SummaryItem(
                label: _sw ? 'Refu zaidi' : 'Longest',
                value: _formatMinutes(longest),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final completed = _sessions.where((s) => !s.isActive).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sw ? 'Historia ya Leo' : "Today's History",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (completed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _sw ? 'Hakuna historia bado' : 'No sleep recorded yet',
                style: const TextStyle(fontSize: 13, color: _kTertiary),
              ),
            ),
          )
        else
          ...completed.map((s) => _buildSessionTile(s)),
      ],
    );
  }

  Widget _buildSessionTile(SleepSession session) {
    final start = session.startTime;
    final end = session.endTime;
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = end != null
        ? '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final isNap = session.type == 'nap';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kTertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isNap ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: _kPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startStr - $endStr',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  session.durationText,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Caregiver attribution
                if (session.loggedBy != null &&
                    _currentUserId != null &&
                    session.loggedBy != _currentUserId)
                  Text(
                    _sw ? 'na Mlezi' : 'by Caregiver',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isNap
                  ? (_sw ? 'Mchana' : 'Nap')
                  : (_sw ? 'Usiku' : 'Night'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────

class _SleepTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SleepTypeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimary,
          side: const BorderSide(color: _kPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
