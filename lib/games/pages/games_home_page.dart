// lib/games/pages/games_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/game_enums.dart';
import '../core/game_registry.dart';
import '../core/game_definition.dart';
import '../models/game_session.dart';
import '../models/challenge.dart';
import '../services/games_service.dart';
import '../widgets/game_card.dart';
import '../widgets/match_card.dart';
import '../widgets/challenge_card.dart';
import 'game_lobby_page.dart';
import 'game_leaderboard_page.dart';
import 'game_play_page.dart';
import 'game_room_page.dart';
import 'game_result_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Challenge expiration duration — challenges older than this are hidden.
const Duration _kChallengeExpiry = Duration(minutes: 5);

Color _categoryTint(GameDefinition def) {
  switch (def.category.name) {
    case 'puzzle': return const Color(0xFF6366F1);
    case 'trivia': return const Color(0xFF8B5CF6);
    case 'word': return const Color(0xFF06B6D4);
    case 'card': return const Color(0xFFF59E0B);
    case 'board': return const Color(0xFF10B981);
    case 'arcade': return const Color(0xFFEF4444);
    case 'math': return const Color(0xFF3B82F6);
    case 'strategy': return const Color(0xFFEC4899);
    default: return _kSecondary;
  }
}

/// Games home page. Rendered inside _ProfileTabPage (no AppBar).
class GamesHomePage extends StatefulWidget {
  final int userId;
  const GamesHomePage({super.key, required this.userId});

  @override
  State<GamesHomePage> createState() => _GamesHomePageState();
}

class _GamesHomePageState extends State<GamesHomePage> {
  final GamesService _service = GamesService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  Timer? _expiryTimer;

  GameCategory _selectedCategory = GameCategory.all;
  String _searchQuery = '';

  List<GameSession> _activeSessions = [];
  List<Challenge> _pendingChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Tick every 15s to update challenge countdown timers and expire old ones
    _expiryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _service.getActiveSessions(widget.userId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        final now = DateTime.now();

        // Active sessions: games I'm actively playing (not pending challenges for me)
        _activeSessions = result.items
            .where((s) =>
                s.isActive ||
                (s.isPending && s.player1Id == widget.userId))
            .toList();

        // Pending challenges: sessions where I'm player_2 and status is pending,
        // filtered by expiry (5 minutes)
        _pendingChallenges = result.items
            .where((s) =>
                s.isPending &&
                s.player2Id == widget.userId &&
                now.difference(s.createdAt).inMinutes < _kChallengeExpiry.inMinutes)
            .map((s) => Challenge(
                  sessionId: s.id,
                  gameId: s.gameId,
                  challengerId: s.player1Id,
                  challengerName: 'Player ${s.player1Id}',
                  stakeTier: s.stakeTier,
                  stakeAmount: s.stakeAmount,
                  createdAt: s.createdAt,
                ))
            .toList();
      } else {
        _activeSessions = [];
        _pendingChallenges = [];
      }
    });
  }

  Future<void> _acceptChallenge(Challenge challenge) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.acceptChallenge(
        challenge.sessionId, widget.userId);

    if (!mounted) return;

    if (result.success && result.data != null) {
      final def = GameRegistry.instance.get(challenge.gameId);
      if (def != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameRoomPage(
              session: result.data!,
              definition: def,
              userId: widget.userId,
            ),
          ),
        );
      }
      _loadData();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to accept challenge'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _declineChallenge(Challenge challenge) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.declineChallenge(challenge.sessionId);

    if (!mounted) return;

    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Challenge declined')),
      );
      _loadData();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to decline challenge'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  List<GameDefinition> _getFilteredGames() {
    if (_searchQuery.isNotEmpty) {
      return GameRegistry.instance.search(_searchQuery);
    }
    return GameRegistry.instance.byCategory(_selectedCategory);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim());
      }
    });
  }

  void _openGame(GameDefinition def) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameLobbyPage(
          definition: def,
          userId: widget.userId,
        ),
      ),
    );
    // Refresh on pop
    _loadData();
  }

  void _openActiveSession(GameSession session) {
    final def = GameRegistry.instance.get(session.gameId);
    if (def == null) return;

    Widget page;
    switch (session.status) {
      case SessionStatus.active:
        // Resume an in-progress game
        page = GamePlayPage(
          session: session,
          definition: def,
          userId: widget.userId,
        );
        break;
      case SessionStatus.pending:
      case SessionStatus.matching:
        // Still waiting for opponent
        page = GameRoomPage(
          session: session,
          definition: def,
          userId: widget.userId,
        );
        break;
      case SessionStatus.completed:
      case SessionStatus.forfeited:
        // Show result screen
        page = GameResultPage(
          session: session,
          userId: widget.userId,
          definition: def,
        );
        break;
      case SessionStatus.cancelled:
        // Cancelled sessions shouldn't appear, but handle gracefully
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    final registry = GameRegistry.instance;
    final filteredGames = _getFilteredGames();
    final featured = registry.allGames.take(5).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ─── Dark Header ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sports_esports_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Michezo / Games',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Play, compete, and win with friends',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _HeaderStat(
                      value: '${registry.count}',
                      label: 'Games',
                    ),
                    const SizedBox(width: 20),
                    _HeaderStat(
                      value: '${_activeSessions.length}',
                      label: 'Active',
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameLeaderboardPage(
                            userId: widget.userId,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.leaderboard_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Leaderboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Search ──────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search games...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: _kSecondary),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          // ─── Category Filter Chips ───────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: GameCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = GameCategory.values[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      _searchQuery = '';
                      _searchCtrl.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _kPrimary : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? Colors.white : _kPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ─── Pending Challenges ────────────────────────────────────
          if (_pendingChallenges.isNotEmpty) ...[
            const Text(
              'Challenges / Changamoto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ..._pendingChallenges.map((challenge) {
              final now = DateTime.now();
              final elapsed = now.difference(challenge.createdAt);
              final remaining = _kChallengeExpiry - elapsed;
              final remainingMinutes = remaining.inMinutes;
              final remainingSeconds = remaining.inSeconds % 60;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChallengeCard(
                      challenge: challenge,
                      onAccept: () => _acceptChallenge(challenge),
                      onDecline: () => _declineChallenge(challenge),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 4),
                      child: Text(
                        remaining.isNegative
                            ? 'Expired'
                            : 'Expires in ${remainingMinutes}m ${remainingSeconds}s',
                        style: TextStyle(
                          fontSize: 11,
                          color: remaining.inSeconds < 60
                              ? const Color(0xFFEF4444)
                              : _kSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // ─── My Matches ──────────────────────────────────────────
          if (_activeSessions.isNotEmpty) ...[
            const Text(
              'My Matches / Mechi Zangu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ..._activeSessions.map((session) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MatchCard(
                    session: session,
                    currentUserId: widget.userId,
                    onTap: () => _openActiveSession(session),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // ─── Featured (horizontal scroll — gradient overlay style) ──
          if (featured.isNotEmpty && _searchQuery.isEmpty) ...[
            const Text(
              'Featured / Pendekezo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final def = featured[i];
                  final tint = _categoryTint(def);
                  final hasImage = def.imagePath != null;
                  return GestureDetector(
                    onTap: () => _openGame(def),
                    child: Container(
                      width: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background
                            if (hasImage)
                              Image.asset(
                                def.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: tint.withValues(alpha: 0.15),
                                  child: Center(child: Icon(def.icon, size: 48, color: tint)),
                                ),
                              )
                            else
                              Container(
                                color: tint.withValues(alpha: 0.15),
                                child: Center(child: Icon(def.icon, size: 48, color: tint)),
                              ),
                            // Gradient overlay
                            Positioned(
                              left: 0, right: 0, bottom: 0, height: 70,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Text
                            Positioned(
                              left: 10, right: 10, bottom: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    def.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    def.category.displayName,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ─── Game Grid ───────────────────────────────────────────
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${filteredGames.length} result${filteredGames.length == 1 ? '' : 's'} for "$_searchQuery"',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
            ),

          if (filteredGames.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: filteredGames.length,
              itemBuilder: (_, i) => GameCard(
                definition: filteredGames[i],
                onTap: () => _openGame(filteredGames[i]),
              ),
            ),

          if (filteredGames.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.sports_esports_outlined,
                    size: 48,
                    color: _kSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Hakuna matokeo / No results found'
                        : 'Hakuna michezo kwa sasa / No games yet',
                    style: const TextStyle(color: _kSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Games will appear here when registered',
                      style: TextStyle(color: _kSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
