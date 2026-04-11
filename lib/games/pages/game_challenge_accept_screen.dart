// lib/games/pages/game_challenge_accept_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/game_registry.dart';
import '../models/game_session.dart';
import '../services/games_service.dart';
import 'game_room_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Deep-link screen for accepting/declining a game challenge.
/// Navigated to via `/game/accept/:sessionId`.
class GameChallengeAcceptScreen extends StatefulWidget {
  final int sessionId;
  final int currentUserId;

  const GameChallengeAcceptScreen({
    super.key,
    required this.sessionId,
    required this.currentUserId,
  });

  @override
  State<GameChallengeAcceptScreen> createState() =>
      _GameChallengeAcceptScreenState();
}

class _GameChallengeAcceptScreenState extends State<GameChallengeAcceptScreen> {
  final GamesService _service = GamesService();

  GameSession? _session;
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _service.getSession(widget.sessionId);

    if (!mounted) return;

    if (result.success && result.data != null) {
      final session = result.data!;
      // Verify this challenge is for the current user and still pending
      if (session.player2Id != widget.currentUserId) {
        setState(() {
          _isLoading = false;
          _error = 'This challenge is not for you.';
        });
        return;
      }
      if (!session.isPending) {
        setState(() {
          _isLoading = false;
          _error = 'This challenge has already been ${session.status.displayName.toLowerCase()}.';
        });
        return;
      }
      // Check expiry (5 minutes)
      final elapsed = DateTime.now().difference(session.createdAt);
      if (elapsed.inMinutes >= 5) {
        setState(() {
          _isLoading = false;
          _error = 'This challenge has expired.';
        });
        return;
      }
      setState(() {
        _session = session;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result.message ?? 'Failed to load challenge.';
      });
    }
  }

  Future<void> _accept() async {
    if (_isActing || _session == null) return;
    setState(() => _isActing = true);

    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.acceptChallenge(
      _session!.id,
      widget.currentUserId,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      final def = GameRegistry.instance.get(_session!.gameId);
      if (def != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameRoomPage(
              session: result.data!,
              definition: def,
              userId: widget.currentUserId,
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Game not found in registry')),
        );
        setState(() => _isActing = false);
      }
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to accept challenge'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      setState(() => _isActing = false);
    }
  }

  Future<void> _decline() async {
    if (_isActing || _session == null) return;
    setState(() => _isActing = true);

    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.declineChallenge(_session!.id);

    if (!mounted) return;

    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Challenge declined')),
      );
      Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to decline'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Game Challenge'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
            )
          : _error != null
              ? _buildError()
              : _buildChallengeInfo(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeInfo() {
    final session = _session!;
    final gameDef = GameRegistry.instance.get(session.gameId);
    final gameName = gameDef?.name ?? session.gameId;
    final elapsed = DateTime.now().difference(session.createdAt);
    final remaining = const Duration(minutes: 5) - elapsed;
    final remainingText = remaining.isNegative
        ? 'Expired'
        : '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Game info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              if (gameDef != null)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(gameDef.icon, size: 32, color: _kPrimary),
                ),
              const SizedBox(height: 12),
              Text(
                gameName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Player ${session.player1Id} challenged you!',
                style: const TextStyle(fontSize: 14, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Stake info
              if (session.stakeAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          size: 16, color: _kPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Stake: TZS ${session.stakeAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),
              Text(
                'Expires in $remainingText',
                style: TextStyle(
                  fontSize: 12,
                  color: remaining.inSeconds < 60
                      ? const Color(0xFFEF4444)
                      : _kSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Accept / Decline buttons
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isActing ? null : _accept,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isActing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Accept Challenge / Kubali',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _isActing ? null : _decline,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kSecondary,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Decline / Kataa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
