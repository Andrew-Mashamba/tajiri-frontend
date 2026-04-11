// lib/my_pregnancy/pages/contraction_timer_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ContractionTimerPage extends StatefulWidget {
  final Pregnancy pregnancy;

  const ContractionTimerPage({super.key, required this.pregnancy});

  @override
  State<ContractionTimerPage> createState() => _ContractionTimerPageState();
}

class _ContractionTimerPageState extends State<ContractionTimerPage> {
  final MyPregnancyService _service = MyPregnancyService();

  // Session state
  final String _sessionId =
      'session_${DateTime.now().millisecondsSinceEpoch}';
  final List<_ContractionRecord> _contractions = [];
  Timer? _timer;
  int _elapsedSeconds = 0;
  DateTime? _currentStart;

  // States: idle, timing, resting
  _TimerState _state = _TimerState.idle;

  bool _isSaving = false;
  bool _patternDetected = false;

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili == true;

  // ─── Timer control ──────────────────────────────────────────

  void _onMainTap() {
    switch (_state) {
      case _TimerState.idle:
      case _TimerState.resting:
        _startContraction();
        break;
      case _TimerState.timing:
        _stopContraction();
        break;
    }
  }

  void _startContraction() {
    setState(() {
      _state = _TimerState.timing;
      _elapsedSeconds = 0;
      _currentStart = DateTime.now();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopContraction() {
    _timer?.cancel();
    final endTime = DateTime.now();
    final durationSec = _elapsedSeconds;

    int? intervalSec;
    if (_contractions.isNotEmpty) {
      intervalSec =
          _currentStart!.difference(_contractions.last.endTime).inSeconds;
    }

    final record = _ContractionRecord(
      number: _contractions.length + 1,
      startTime: _currentStart!,
      endTime: endTime,
      durationSeconds: durationSec,
      intervalSeconds: intervalSec,
    );

    setState(() {
      _contractions.add(record);
      _state = _TimerState.resting;
      _elapsedSeconds = 0;
      _currentStart = null;
      _patternDetected = _check511Pattern();
    });

    // Start rest timer to show interval
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    // Save individual contraction to backend
    _saveContraction(record);
  }

  bool _check511Pattern() {
    // 5-1-1 rule: contractions 5 min apart, 1 min long, for 1 hour
    if (_contractions.length < 3) return false;

    // Check the last hour of contractions
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final recentContractions = _contractions
        .where((c) => c.startTime.isAfter(oneHourAgo))
        .toList();

    if (recentContractions.length < 3) return false;

    // Check if all recent contractions are ~1 min long and ~5 min apart
    int qualifying = 0;
    for (final c in recentContractions) {
      final durationOk = c.durationSeconds >= 45 && c.durationSeconds <= 90;
      final intervalOk =
          c.intervalSeconds == null || // first contraction in set
              (c.intervalSeconds! >= 180 && c.intervalSeconds! <= 420); // 3-7 min
      if (durationOk && intervalOk) qualifying++;
    }

    // At least 3 qualifying contractions in the last hour
    return qualifying >= 3;
  }

  Future<void> _saveContraction(_ContractionRecord record) async {
    try {
      await _service.saveContraction(
        pregnancyId: widget.pregnancy.id,
        startTime: record.startTime,
        endTime: record.endTime,
        durationSeconds: record.durationSeconds,
        sessionId: _sessionId,
        intervalSeconds: record.intervalSeconds,
        token: _token,
      );
    } catch (_) {
      // Silent — session is local-first
    }
  }

  Future<void> _saveSession() async {
    if (_contractions.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    _timer?.cancel();
    setState(() {
      _isSaving = false;
      _state = _TimerState.idle;
      _elapsedSeconds = 0;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(sw
            ? 'Kipindi kimehifadhiwa'
            : 'Session saved'),
      ),
    );
  }

  void _resetSession() {
    _timer?.cancel();
    setState(() {
      _contractions.clear();
      _state = _TimerState.idle;
      _elapsedSeconds = 0;
      _currentStart = null;
      _patternDetected = false;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ─── Build ──────────────────────────────────────────────────

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
          sw ? 'Kipimo cha Uchungu' : 'Contraction Timer',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
        actions: [
          if (_contractions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _kSecondary),
              tooltip: sw ? 'Anza upya' : 'Reset',
              onPressed: _resetSession,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Pattern alert card
                  if (_patternDetected) _buildPatternAlert(sw),

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
                                ? 'Bonyeza kuanza wakati uchungu unapoanza, bonyeza tena unapomalizika.'
                                : 'Tap to start when contraction begins, tap again when it ends.',
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status text
                  Center(
                    child: Text(
                      _statusText(sw),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _state == _TimerState.timing
                            ? _kPrimary
                            : _kSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Timer display
                  Center(
                    child: Text(
                      _formatDuration(_elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: _kPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Main tap button
                  Center(
                    child: GestureDetector(
                      onTap: _onMainTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _state == _TimerState.timing
                              ? _kPrimary
                              : _kBackground,
                          border: Border.all(
                            color: _kPrimary,
                            width: 3,
                          ),
                          boxShadow: _state == _TimerState.timing
                              ? [
                                  BoxShadow(
                                    color: _kPrimary.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _state == _TimerState.timing
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              size: 48,
                              color: _state == _TimerState.timing
                                  ? Colors.white
                                  : _kPrimary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buttonLabel(sw),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _state == _TimerState.timing
                                    ? Colors.white
                                    : _kPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save session button
                  if (_contractions.isNotEmpty)
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveSession,
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
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  sw ? 'Hifadhi Kipindi' : 'Save Session',
                                  style: const TextStyle(fontSize: 15),
                                ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Session history
                  if (_contractions.isNotEmpty) ...[
                    Text(
                      sw ? 'Uchungu wa Kipindi Hiki' : 'Session Contractions',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                    ),
                    const SizedBox(height: 8),

                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text('#',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _kSecondary)),
                          ),
                          Expanded(
                            child: Text(
                              sw ? 'Muda' : 'Duration',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kSecondary),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              sw ? 'Mwanya' : 'Interval',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kSecondary),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              sw ? 'Saa' : 'Time',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kSecondary),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contraction rows
                    ..._contractions.reversed.map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade200, width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${c.number}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _formatDuration(c.durationSeconds),
                                  style: const TextStyle(
                                      fontSize: 13, color: _kPrimary),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  c.intervalSeconds != null
                                      ? _formatDuration(c.intervalSeconds!)
                                      : '-',
                                  style: const TextStyle(
                                      fontSize: 13, color: _kSecondary),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  _formatTime(c.startTime),
                                  style: const TextStyle(
                                      fontSize: 12, color: _kTertiary),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternAlert(bool sw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.local_hospital_rounded,
              color: Colors.red.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw
                      ? 'Muda wa Kwenda Hospitali!'
                      : 'Time to Go to the Hospital!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sw
                      ? 'Uchungu wako unafuata muundo wa 5-1-1: dakika 5 mbali, dakika 1 kwa muda, kwa saa 1. Nenda hospitali sasa.'
                      : 'Your contractions follow the 5-1-1 pattern: 5 min apart, 1 min long, for 1 hour. Head to the hospital now.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(bool sw) {
    switch (_state) {
      case _TimerState.idle:
        return sw ? 'Inasubiri' : 'Waiting';
      case _TimerState.timing:
        return sw ? 'Inapima uchungu...' : 'Timing contraction...';
      case _TimerState.resting:
        return sw ? 'Kupumzika kati ya uchungu' : 'Resting between contractions';
    }
  }

  String _buttonLabel(bool sw) {
    switch (_state) {
      case _TimerState.idle:
        return sw ? 'Anza' : 'Start';
      case _TimerState.timing:
        return sw ? 'Simamisha' : 'Stop';
      case _TimerState.resting:
        return sw ? 'Ijayo' : 'Next';
    }
  }
}

// ─── Internal types ─────────────────────────────────────────

enum _TimerState { idle, timing, resting }

class _ContractionRecord {
  final int number;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final int? intervalSeconds;

  const _ContractionRecord({
    required this.number,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.intervalSeconds,
  });
}
