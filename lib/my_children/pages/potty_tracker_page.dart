// lib/my_children/pages/potty_tracker_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../services/my_children_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kSuccess = Color(0xFF2E7D32);
const Color _kAmber = Color(0xFFE65100);

class PottyTrackerPage extends StatefulWidget {
  final Child child;
  final int userId;

  const PottyTrackerPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<PottyTrackerPage> createState() => _PottyTrackerPageState();
}

class _PottyTrackerPageState extends State<PottyTrackerPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _history = [];
  String? _token;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

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
    setState(() => _isLoading = true);
    try {
      final result = await _service.getPottyHistory(
        widget.child.id,
        token: _token,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _history = result.items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sw
                ? 'Imeshindikana kupakia data'
                : 'Failed to load data'),
          ),
        );
      }
    }
  }

  Future<void> _logPotty(String type) async {
    if (_token == null || _isSaving) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _service.logPotty(
        widget.child.id,
        type,
        token: _token,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (result.success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(type == 'success'
                  ? (_sw ? 'Hongera! Imerekodiwa' : 'Great job! Logged')
                  : (_sw ? 'Ajali imerekodiwa' : 'Accident logged')),
            ),
          );
          _loadData();
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(result.message ??
                  (_sw ? 'Imeshindwa kuhifadhi' : 'Failed to save')),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(
            content:
                Text(_sw ? 'Hitilafu imetokea' : 'An error occurred'),
          ),
        );
      }
    }
  }

  // ─── Stats ─────────────────────────────────────────────────

  List<Map<String, dynamic>> get _todayEntries {
    final now = DateTime.now();
    return _history.where((p) {
      final d = DateTime.tryParse(p['logged_at']?.toString() ?? '');
      return d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();
  }

  int get _todaySuccesses =>
      _todayEntries.where((p) => p['type'] == 'success').length;

  int get _todayAccidents =>
      _todayEntries.where((p) => p['type'] == 'accident').length;

  int get _dryDayStreak {
    // Count consecutive days without accidents (looking back from today)
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 90; i++) {
      final day = now.subtract(Duration(days: i));
      final dayEntries = _history.where((p) {
        final d = DateTime.tryParse(p['logged_at']?.toString() ?? '');
        return d != null &&
            d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).toList();
      // Skip today if no entries yet
      if (i == 0 && dayEntries.isEmpty) continue;
      // If no entries on past day, skip (no data)
      if (i > 0 && dayEntries.isEmpty) break;
      final hasAccident = dayEntries.any((p) => p['type'] == 'accident');
      if (hasAccident) break;
      streak++;
    }
    return streak;
  }

  // Weekly chart data: success rate per day for last 7 days
  List<_DayStats> get _weeklyStats {
    final now = DateTime.now();
    final stats = <_DayStats>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayEntries = _history.where((p) {
        final d = DateTime.tryParse(p['logged_at']?.toString() ?? '');
        return d != null &&
            d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).toList();
      final successes =
          dayEntries.where((p) => p['type'] == 'success').length;
      final total = dayEntries.length;
      stats.add(_DayStats(
        day: day,
        successes: successes,
        total: total,
        rate: total > 0 ? successes / total : 0,
      ));
    }
    return stats;
  }

  String _encouragement(bool sw) {
    if (_todaySuccesses >= 5) {
      return sw ? 'Ajabu! Mtoto anafanya vizuri sana!' : 'Amazing! Your child is doing great!';
    }
    if (_todaySuccesses >= 3) {
      return sw ? 'Vizuri sana! Endelea hivyo!' : 'Very good! Keep it up!';
    }
    if (_dryDayStreak >= 3) {
      return sw
          ? 'Siku $_dryDayStreak bila ajali! Pongezi!'
          : '$_dryDayStreak dry days! Congratulations!';
    }
    if (_todaySuccesses >= 1) {
      return sw ? 'Mwanzo mzuri! Endelea!' : 'Good start! Keep going!';
    }
    return sw
        ? 'Kila siku ni fursa mpya ya kujifunza!'
        : 'Every day is a new chance to learn!';
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Kufunza Choo' : 'Potty Training',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  children: [
                    // ─── Log Buttons ──────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 80,
                            child: Material(
                              color: _kSuccess.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: _isSaving
                                    ? null
                                    : () => _logPotty('success'),
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🎉',
                                        style: TextStyle(fontSize: 24)),
                                    const SizedBox(height: 4),
                                    Text(
                                      sw ? 'Mafanikio!' : 'Success!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _kSuccess,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 80,
                            child: Material(
                              color: _kAmber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: _isSaving
                                    ? null
                                    : () => _logPotty('accident'),
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('😅',
                                        style: TextStyle(fontSize: 24)),
                                    const SizedBox(height: 4),
                                    Text(
                                      sw ? 'Ajali' : 'Accident',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _kAmber,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Encouragement ────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _encouragement(sw),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _kPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Today's Stats ────────────────────
                    _buildSectionTitle(
                        sw ? 'Takwimu za Leo' : "Today's Stats"),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: sw ? 'Mafanikio' : 'Successes',
                              value: '$_todaySuccesses',
                              color: _kSuccess,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: sw ? 'Ajali' : 'Accidents',
                              value: '$_todayAccidents',
                              color: _kAmber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: sw ? 'Siku Safi' : 'Dry Days',
                              value: '$_dryDayStreak',
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Weekly Chart ─────────────────────
                    _buildSectionTitle(
                        sw ? 'Chati ya Wiki' : 'Weekly Chart'),
                    const SizedBox(height: 8),
                    _buildWeeklyChart(sw),
                    const SizedBox(height: 16),

                    // ─── Weekly Progress Insights ────────
                    _buildWeeklyProgressInsights(sw),
                    const SizedBox(height: 16),

                    // ─── History ──────────────────────────
                    _buildSectionTitle(sw ? 'Historia' : 'History'),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          sw
                              ? 'Hakuna rekodi bado'
                              : 'No records yet',
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      ..._history.take(20).map((entry) =>
                          GestureDetector(
                            onLongPress: () => _confirmDeletePotty(entry),
                            child: _buildHistoryItem(entry, sw),
                          )),
                    // ─── Cross-module links ──────────────
                    const SizedBox(height: 20),
                    Text(
                      sw ? 'Viunganishi' : 'Related',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCrossModuleLink(
                      icon: Icons.shopping_bag_rounded,
                      label: sw
                          ? 'Nunua vifaa vya kufunza choo'
                          : 'Shop potty training supplies',
                      onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.chat_rounded,
                      label: sw
                          ? 'Uliza Shangazi kuhusu vidokezo vya kufunza choo'
                          : 'Ask Shangazi for potty training tips',
                      onTap: () => Navigator.pushNamed(context, '/chat/0'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  Widget _buildWeeklyProgressInsights(bool sw) {
    final stats = _weeklyStats;
    if (stats.every((s) => s.total == 0)) return const SizedBox.shrink();

    // This week vs last week success rate
    final now = DateTime.now();
    final thisWeekEntries = _history.where((p) {
      final d = DateTime.tryParse(p['logged_at']?.toString() ?? '');
      if (d == null) return false;
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return d.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();
    final lastWeekEntries = _history.where((p) {
      final d = DateTime.tryParse(p['logged_at']?.toString() ?? '');
      if (d == null) return false;
      final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
      return d.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
          d.isBefore(thisWeekStart);
    }).toList();

    final thisWeekSuccesses =
        thisWeekEntries.where((p) => p['type'] == 'success').length;
    final thisWeekTotal = thisWeekEntries.length;
    final thisWeekRate =
        thisWeekTotal > 0 ? (thisWeekSuccesses / thisWeekTotal * 100).round() : 0;

    final lastWeekSuccesses =
        lastWeekEntries.where((p) => p['type'] == 'success').length;
    final lastWeekTotal = lastWeekEntries.length;
    final lastWeekRate =
        lastWeekTotal > 0 ? (lastWeekSuccesses / lastWeekTotal * 100).round() : 0;

    final rateDiff = thisWeekRate - lastWeekRate;

    // Best day this week
    String? bestDayLabel;
    int bestDaySuccesses = 0;
    final dayNames = sw
        ? ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili']
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    for (final s in stats) {
      if (s.successes > bestDaySuccesses) {
        bestDaySuccesses = s.successes;
        bestDayLabel = dayNames[(s.day.weekday - 1) % 7];
      }
    }

    // Consecutive success streak
    int streak = 0;
    final sorted = List<Map<String, dynamic>>.from(_history)
      ..sort((a, b) {
        final da = DateTime.tryParse(a['logged_at']?.toString() ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['logged_at']?.toString() ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });
    for (final entry in sorted) {
      if (entry['type'] == 'success') {
        streak++;
      } else {
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded,
                    size: 18, color: _kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw ? 'Maendeleo ya Wiki' : 'Weekly Progress',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Success rate comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw ? 'Kiwango cha Mafanikio' : 'Success Rate',
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$thisWeekRate%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: thisWeekRate >= 70
                            ? _kSuccess
                            : thisWeekRate >= 40
                                ? _kAmber
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Trend badge
              if (lastWeekTotal > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: rateDiff >= 0
                        ? _kSuccess.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rateDiff > 0
                            ? '\u2191'
                            : rateDiff < 0
                                ? '\u2193'
                                : '\u2192',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: rateDiff > 0
                              ? _kSuccess
                              : rateDiff < 0
                                  ? Colors.red
                                  : _kSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rateDiff == 0
                            ? (sw ? 'Sawa' : 'Same')
                            : '${rateDiff.abs()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: rateDiff > 0
                              ? _kSuccess
                              : rateDiff < 0
                                  ? Colors.red
                                  : _kSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Best day
          if (bestDayLabel != null && bestDaySuccesses > 0)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kSuccess.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 16, color: _kSuccess),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Siku bora wiki hii: $bestDayLabel ($bestDaySuccesses ${bestDaySuccesses == 1 ? "mafanikio" : "mafanikio"})'
                          : 'Best day: $bestDayLabel ($bestDaySuccesses ${bestDaySuccesses == 1 ? "success" : "successes"})',
                      style: const TextStyle(
                          fontSize: 12, color: _kSuccess),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Streak
          if (streak > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 16, color: _kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Mfululizo: $streak mafanikio mfululizo!'
                          : 'Streak: $streak successes in a row!',
                      style:
                          const TextStyle(fontSize: 12, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(bool sw) {
    final stats = _weeklyStats;
    final dayNames = sw
        ? ['Jt', 'Jm', 'Jt', 'Al', 'Ij', 'Jm', 'Jp']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: stats.map((s) {
          final dayIdx = s.day.weekday - 1;
          return Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        s.total > 0
                            ? '${(s.rate * 100).round()}%'
                            : '-',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: s.total > 0 ? (s.rate * 60).clamp(4, 60) : 4,
                        width: 20,
                        decoration: BoxDecoration(
                          color: s.total > 0
                              ? (s.rate >= 0.7
                                  ? _kSuccess.withValues(alpha: 0.6)
                                  : _kAmber.withValues(alpha: 0.4))
                              : _kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayNames[dayIdx % 7],
                  style: const TextStyle(fontSize: 10, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmDeletePotty(Map<String, dynamic> entry) {
    final sw = _sw;
    final type = entry['type']?.toString() ?? '';
    final label = type == 'success'
        ? (sw ? 'Mafanikio' : 'Success')
        : (sw ? 'Ajali' : 'Accident');
    final id = entry['id'];
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa?' : 'Delete?'),
        content: Text(sw ? 'Futa "$label"?' : 'Delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deletePotty(_token!, id is int ? id : int.parse(id.toString()));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imefutwa' : 'Deleted')),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imeshindikana kufuta' : 'Failed to delete')),
                  );
                }
              }
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> entry, bool sw) {
    final type = entry['type']?.toString() ?? '';
    final loggedAt =
        DateTime.tryParse(entry['logged_at']?.toString() ?? '');
    final notes = entry['notes']?.toString();
    final isSuccess = type == 'success';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 20,
              color: isSuccess ? _kSuccess : _kAmber,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSuccess
                        ? (sw ? 'Mafanikio' : 'Success')
                        : (sw ? 'Ajali' : 'Accident'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notes != null && notes.isNotEmpty)
                    Text(
                      notes,
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (loggedAt != null)
              Text(
                '${loggedAt.hour.toString().padLeft(2, '0')}:${loggedAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _kPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _kSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DayStats {
  final DateTime day;
  final int successes;
  final int total;
  final double rate;
  const _DayStats({
    required this.day,
    required this.successes,
    required this.total,
    required this.rate,
  });
}
