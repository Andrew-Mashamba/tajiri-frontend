import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F7 #53 — Virtual waiting room.
///
/// Customer joins queue → polls every 5 s → page resolves with `admit` once
/// the partner promotes them.
class VirtualWaitingRoomPage extends StatefulWidget {
  final int userId;
  final int consultationId;
  const VirtualWaitingRoomPage({
    super.key,
    required this.userId,
    required this.consultationId,
  });

  @override
  State<VirtualWaitingRoomPage> createState() => _VirtualWaitingRoomPageState();
}

class _VirtualWaitingRoomPageState extends State<VirtualWaitingRoomPage> {
  Timer? _poller;
  int? _position;
  bool _admitted = false;

  @override
  void initState() {
    super.initState();
    _join();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _join() async {
    final res = await WaitingRoomService.join(
      userId: widget.userId,
      consultationId: widget.consultationId,
    );
    if (!mounted) return;
    setState(() => _position = (res?['queue_position'] as num?)?.toInt());
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final queue = await WaitingRoomService.queue(widget.consultationId);
    if (!mounted) return;
    final mine = queue.firstWhere(
        (m) => (m['user_id'] as num?)?.toInt() == widget.userId,
        orElse: () => const {});
    final position = (mine['queue_position'] as num?)?.toInt();
    if (mine.isEmpty) {
      // We've been admitted (or kicked). Treat as admit.
      _poller?.cancel();
      setState(() => _admitted = true);
      return;
    }
    setState(() => _position = position);
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Chumba cha kusubiri' : 'Waiting room'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_admitted) ...[
              const Icon(Icons.check_circle_rounded,
                  size: 80, color: Color(0xFF1B5E20)),
              const SizedBox(height: 16),
              Text(
                isSw ? 'Karibu! Daktari yuko tayari.' : 'You\'re in!',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A)),
                onPressed: () => Navigator.pop(context, true),
                child: Text(isSw ? 'Endelea' : 'Continue'),
              ),
            ] else ...[
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              const SizedBox(height: 24),
              if (_position != null)
                Text(
                  '#$_position',
                  style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A)),
                ),
              const SizedBox(height: 8),
              Text(
                isSw
                    ? 'Mstari wako. Tafadhali subiri.'
                    : 'Your queue position. Please wait.',
                style: const TextStyle(color: Color(0xFF666666)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
