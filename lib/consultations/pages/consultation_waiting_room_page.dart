import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/consultation.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec line 740 — pre-call virtual waiting room. Surfaces countdown to
/// `starts_at`, a mic/camera self-check placeholder, and a Join button that
/// becomes active 5 min before the slot. Returns true when user taps Join.
class ConsultationWaitingRoomPage extends StatefulWidget {
  final Consultation consultation;
  final int userId;
  const ConsultationWaitingRoomPage({
    super.key,
    required this.consultation,
    required this.userId,
  });

  @override
  State<ConsultationWaitingRoomPage> createState() => _ConsultationWaitingRoomPageState();
}

class _ConsultationWaitingRoomPageState extends State<ConsultationWaitingRoomPage> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _micOn = true;
  bool _cameraOn = true;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _recompute() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.consultation.startsAt.difference(now);
    });
  }

  bool get _canJoin {
    // Spec — Join button active from T-5min to T+30min.
    return _remaining.inMinutes <= 5 && _remaining.inMinutes >= -30;
  }

  String _fmtCountdown(Duration d) {
    if (d.isNegative) {
      final p = -d;
      return '+${p.inMinutes.toString().padLeft(2, '0')}:${(p.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    final c = widget.consultation;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Chumba cha kusubiri' : 'Waiting room'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: _kPrimary.withValues(alpha: 0.06),
                child: Text(
                  (c.partnerName ?? '?').characters.first,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                c.partnerName ?? '—',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                isSw ? c.vertical.labelSwahili : c.vertical.label,
                style: const TextStyle(fontSize: 13, color: _kMuted),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: _canJoin
                      ? _kAccent.withValues(alpha: 0.10)
                      : _kPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _canJoin
                          ? (isSw ? 'Sasa unaweza kujiunga' : 'You can join now')
                          : (isSw ? 'Inaanza ndani ya' : 'Starts in'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _canJoin ? _kAccent : _kMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmtCountdown(_remaining),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _canJoin ? _kAccent : _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isSw ? 'Hakikisha vifaa vinafanya kazi' : 'Test your devices',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _micOn = !_micOn),
                    icon: Icon(
                      _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      color: _micOn ? _kAccent : _kMuted,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: () => setState(() => _cameraOn = !_cameraOn),
                    icon: Icon(
                      _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      color: _cameraOn ? _kAccent : _kMuted,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canJoin ? () => Navigator.of(context).pop(true) : null,
                  icon: const Icon(Icons.video_call_rounded),
                  label: Text(isSw ? 'Jiunge sasa' : 'Join now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
