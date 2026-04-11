// lib/my_pregnancy/pages/kick_counter_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';
import '../widgets/kick_counter_widget.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class KickCounterPage extends StatefulWidget {
  final Pregnancy pregnancy;

  const KickCounterPage({super.key, required this.pregnancy});

  @override
  State<KickCounterPage> createState() => _KickCounterPageState();
}

class _KickCounterPageState extends State<KickCounterPage> {
  final MyPregnancyService _service = MyPregnancyService();

  int _kickCount = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  List<KickCount> _history = [];
  bool _isLoadingHistory = true;
  bool _isSaving = false;

  // Sophisticated kick alert state
  bool _kickDecreaseAlert = false;
  String? _kickAlertMessage;
  bool _kickAlertUrgent = false;

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  bool get _sw =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final result =
          await _service.getKickHistory(widget.pregnancy.id, token: _token);
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          if (result.success) _history = result.items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _startSession() {
    setState(() {
      _isRunning = true;
      _kickCount = 0;
      _elapsedSeconds = 0;
      _startTime = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _recordKick() {
    if (!_isRunning) return;
    HapticFeedback.lightImpact();
    setState(() => _kickCount++);

    // Goal snackbar fires exactly once at 10 kicks
    if (_kickCount == 10) {
      final sw = _sw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sw
              ? 'Hongera! Mtoto amepiga mateke 10. Hii ni dalili nzuri!'
              : 'Congratulations! Baby reached 10 kicks. This is a good sign!'),
          backgroundColor: _kPrimary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _stopAndSave() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isSaving = true;
    });

    final durationMinutes = (_elapsedSeconds / 60).ceil();
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _service.saveKickCount(
        pregnancyId: widget.pregnancy.id,
        count: _kickCount,
        durationMinutes: durationMinutes,
        startTime: _startTime ?? DateTime.now(),
        token: _token,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result.success) {
          messenger.showSnackBar(
            SnackBar(
                content:
                    Text(sw ? 'Mateke yamehifadhiwa' : 'Kicks saved')),
          );
          await _loadHistory();
          _checkKickPattern();
        } else {
          messenger.showSnackBar(
            SnackBar(
                content: Text(result.message ??
                    (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kosa: $e' : 'Error: $e')),
        );
      }
    }
  }

  void _checkKickPattern() {
    if (_history.length < 5) {
      // Need at least 5 sessions for meaningful trend analysis
      // Fall back to simple check for fewer sessions
      if (_history.length >= 3) {
        _simpleKickCheck();
      }
      return;
    }

    final sw = _sw;

    // Sort by date descending
    final sorted = List<KickCount>.of(_history)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Recent 3 sessions vs prior sessions
    final recent3 = sorted.take(3).map((h) => h.count).toList();
    final prior = sorted.skip(3).map((h) => h.count).toList();

    final recentAvg = recent3.reduce((a, b) => a + b) / recent3.length;
    final priorAvg = prior.reduce((a, b) => a + b) / prior.length;

    String? alertMessage;
    bool isUrgent = false;

    // Check for zero-kick sessions (most urgent)
    if (recent3.any((c) => c == 0)) {
      alertMessage = sw
          ? 'Kulikuwa na kipindi bila mateke yoyote. Wasiliana na daktari wako HARAKA.'
          : 'There was a session with zero kicks. Contact your doctor IMMEDIATELY.';
      isUrgent = true;
    }
    // Alert condition 1: Recent average < 50% of prior average
    else if (priorAvg > 0 && recentAvg < priorAvg * 0.5) {
      alertMessage = sw
          ? 'Mateke ya mtoto yamepungua sana. Wasiliana na daktari wako.'
          : 'Baby\'s kicks have significantly decreased. Contact your doctor.';
      isUrgent = true;
    }
    // Alert condition 2: All recent sessions below 70% of prior average
    else if (priorAvg > 0 && recent3.every((c) => c < priorAvg * 0.7)) {
      alertMessage = sw
          ? 'Mateke ya mtoto yanaonekana kupungua. Fuatilia kwa makini.'
          : 'Baby\'s kicks appear to be decreasing. Monitor closely.';
    }
    // Alert condition 3: Consistent downward trend in last 3 sessions
    else if (recent3.length >= 3 &&
        recent3[0] < recent3[1] &&
        recent3[1] < recent3[2]) {
      alertMessage = sw
          ? 'Mateke ya mtoto yanapungua kwa mfululizo. Endelea kufuatilia.'
          : 'Baby\'s kicks are trending downward. Continue monitoring.';
    }

    setState(() {
      if (alertMessage != null) {
        _kickDecreaseAlert = true;
        _kickAlertMessage = alertMessage;
        _kickAlertUrgent = isUrgent;
      } else {
        _kickDecreaseAlert = false;
        _kickAlertMessage = null;
        _kickAlertUrgent = false;
      }
    });
  }

  /// Simple check for when we have 3-4 sessions (not enough for full trend)
  void _simpleKickCheck() {
    final totalKicks = _history.map((h) => h.count).reduce((a, b) => a + b);
    final avgKicks = totalKicks / _history.length;
    final sw = _sw;

    if (_kickCount > 0 && _kickCount < avgKicks * 0.5) {
      setState(() {
        _kickDecreaseAlert = true;
        _kickAlertMessage = sw
            ? 'Mateke ya mtoto wako ni machache kuliko kawaida. Kama una wasiwasi, wasiliana na daktari wako.'
            : 'Your baby\'s kicks are lower than usual. If concerned, contact your doctor.';
        _kickAlertUrgent = false;
      });
    } else {
      setState(() {
        _kickDecreaseAlert = false;
        _kickAlertMessage = null;
        _kickAlertUrgent = false;
      });
    }
  }

  void _resetSession() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _kickCount = 0;
      _elapsedSeconds = 0;
      _startTime = null;
    });
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Build a simple bar chart of kicks for the last 7 days
  Widget _buildKickTrendChart() {
    final sw = _sw;

    // Group history by date (day), take last 7 days
    final now = DateTime.now();
    final dayMap = <String, int>{};
    for (final kick in _history) {
      final key =
          '${kick.date.year}-${kick.date.month.toString().padLeft(2, '0')}-${kick.date.day.toString().padLeft(2, '0')}';
      dayMap[key] = (dayMap[key] ?? 0) + kick.count;
    }

    // Build last 7 days
    final days = <_DayKick>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final shortLabel = _shortDayLabel(d.weekday, sw);
      days.add(_DayKick(label: shortLabel, count: dayMap[key] ?? 0));
    }

    final maxCount =
        days.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return const SizedBox.shrink();

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
            sw ? 'Mwenendo wa Mateke (Siku 7)' : 'Kick Trend (7 Days)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final fraction = maxCount > 0 ? day.count / maxCount : 0.0;
                final barHeight = math.max(4.0, fraction * 90);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${day.count}',
                          style: TextStyle(
                            fontSize: 10,
                            color: day.count > 0 ? _kPrimary : _kSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: day.count > 0
                                ? _kPrimary.withValues(alpha: 0.7)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day.label,
                          style: const TextStyle(
                              fontSize: 10, color: _kSecondary),
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

  String _shortDayLabel(int weekday, bool sw) {
    if (sw) {
      const labels = ['Jtt', 'Jnn', 'Jtn', 'Alh', 'Ijm', 'Jms', 'Jpi'];
      return labels[weekday - 1];
    }
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final goalReached = _kickCount >= 10;
    final twoHoursReached = _elapsedSeconds >= 7200;

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
          sw ? 'Hesabu Mateke' : 'Kick Counter',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: _kSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sw
                              ? 'Lengo: Mateke 10 ndani ya masaa 2. Hesabu kila mtoto anaposogea.'
                              : 'Goal: 10 kicks within 2 hours. Count each time the baby moves.',
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Kick decrease alert (sophisticated)
                if (_kickDecreaseAlert && _kickAlertMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kickAlertUrgent
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kickAlertUrgent
                            ? Colors.red.shade300
                            : Colors.orange.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _kickAlertUrgent
                                  ? Icons.error_rounded
                                  : Icons.warning_amber_rounded,
                              size: 20,
                              color: _kickAlertUrgent
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _kickAlertMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kickAlertUrgent
                                      ? Colors.red.shade800
                                      : Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_kickAlertUrgent) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                try {
                                  Navigator.pushNamed(context, '/doctor');
                                } catch (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_sw
                                          ? 'Huduma hii itapatikana hivi karibuni'
                                          : 'This service will be available soon'),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.local_hospital_rounded,
                                  size: 14, color: Colors.red.shade700),
                              label: Text(
                                sw
                                    ? 'Wasiliana na Daktari'
                                    : 'Contact Doctor',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Timer display
                Center(
                  child: Text(
                    _formatDuration(_elapsedSeconds),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: twoHoursReached && !goalReached
                          ? Colors.red
                          : _kPrimary,
                    ),
                  ),
                ),
                if (twoHoursReached && !goalReached)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        sw
                            ? 'Masaa 2 yamepita. Mtoto hajapiga mateke 10. Wasiliana na daktari.'
                            : '2 hours passed. Baby has not reached 10 kicks. Contact your doctor.',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                const SizedBox(height: 28),

                // Kick counter circle
                Center(
                  child: KickCounterWidget(
                    count: _kickCount,
                    isRunning: _isRunning,
                    onTap: _recordKick,
                  ),
                ),
                const SizedBox(height: 12),

                // Progress to 10
                if (_isRunning)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_kickCount / 10).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                _kPrimary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          goalReached
                              ? (sw
                                  ? 'Lengo limefikiwa!'
                                  : 'Goal reached!')
                              : (sw
                                  ? '${10 - _kickCount} mateke bado'
                                  : '${10 - _kickCount} kicks to go'),
                          style: TextStyle(
                            fontSize: 12,
                            color: goalReached ? _kPrimary : _kSecondary,
                            fontWeight:
                                goalReached ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),

                // Buttons
                if (!_isRunning && _kickCount == 0)
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 48,
                      child: FilledButton(
                        onPressed: _startSession,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                            sw ? 'Anza Kuhesabu' : 'Start Counting',
                            style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                if (_isRunning || _kickCount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRunning)
                        SizedBox(
                          width: 140,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _resetSession,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kPrimary,
                              side: const BorderSide(color: _kPrimary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(sw ? 'Futa' : 'Reset',
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      if (_isRunning) const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSaving
                              ? null
                              : (_isRunning ? _stopAndSave : _startSession),
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isRunning
                                      ? (sw ? 'Hifadhi' : 'Save')
                                      : (sw ? 'Anza Tena' : 'Start Again'),
                                  style: const TextStyle(fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 28),

                // Kick trend chart
                if (_history.isNotEmpty) ...[
                  _buildKickTrendChart(),
                  const SizedBox(height: 20),
                ],

                // History
                Text(
                  sw ? 'Historia' : 'History',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary),
                ),
                const SizedBox(height: 10),
                if (_isLoadingHistory)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary),
                    ),
                  )
                else if (_history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 36, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          sw ? 'Bado hakuna rekodi' : 'No records yet',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                else
                  ..._history.map(
                      (kick) => _KickHistoryItem(kick: kick, isSwahili: sw)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayKick {
  final String label;
  final int count;
  const _DayKick({required this.label, required this.count});
}

class _KickHistoryItem extends StatelessWidget {
  final KickCount kick;
  final bool isSwahili;

  const _KickHistoryItem({required this.kick, this.isSwahili = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kick.reachedGoal
                  ? _kPrimary.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                '${kick.count}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kick.reachedGoal ? _kPrimary : Colors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili
                      ? 'Mateke ${kick.count}'
                      : '${kick.count} Kicks',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  isSwahili
                      ? 'Dakika ${kick.durationMinutes}'
                      : '${kick.durationMinutes} minutes',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(kick.date),
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
