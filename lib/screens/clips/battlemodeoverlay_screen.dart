/// Story 84: Livestream Battle Mode (PK Battle)
/// Screen entry for PK Battle overlay shown on StreamViewerScreen when battle is active.
/// Navigation: StreamViewerScreen → PK Battle mode (when active).
/// Design: DOCS/DESIGN.md (touch targets 48dp min, layout). Gift-based scoring.
import 'package:flutter/material.dart';
import '../../services/battle_mode_service.dart';
import '../../widgets/battle_mode_overlay.dart';

/// PK Battle overlay content shown at the top of the stream when a battle is active.
/// Displays scores, progress bars, and gift-based competition state.
/// Streamer sees forfeit action; viewers see scores and "Send gifts to win!".
class BattleModeOverlayScreen extends StatelessWidget {
  final BattleState battleState;
  final String myName;
  final int currentUserId;
  final VoidCallback? onForfeit;

  const BattleModeOverlayScreen({
    super.key,
    required this.battleState,
    required this.myName,
    required this.currentUserId,
    this.onForfeit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: BattleModeOverlay(
          battleState: battleState,
          myName: myName,
          currentUserId: currentUserId,
          onForfeit: onForfeit,
        ),
      ),
    );
  }
}
