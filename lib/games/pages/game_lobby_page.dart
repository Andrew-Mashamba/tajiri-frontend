// lib/games/pages/game_lobby_page.dart
import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../core/game_definition.dart';
import '../core/game_enums.dart';
import '../services/games_service.dart';
import '../widgets/stake_selector.dart';
import 'game_room_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Lobby page for a specific game.
/// User selects mode, stake tier, then starts a match.
class GameLobbyPage extends StatefulWidget {
  final GameDefinition definition;
  final int userId;

  const GameLobbyPage({
    super.key,
    required this.definition,
    required this.userId,
  });

  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> {
  final GamesService _service = GamesService();

  GameMode _selectedMode = GameMode.practice;
  StakeTier _selectedTier = StakeTier.free;
  double _customAmount = 0;
  bool _isStarting = false;

  // Wallet balance — loaded from API
  double _walletBalance = 0;
  bool _isLoadingBalance = true;

  // Selected friend for challenge mode
  int? _selectedFriendId;
  String? _selectedFriendName;
  String? _selectedFriendAvatar;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final balance = await _service.getWalletBalance(widget.userId);
    if (!mounted) return;
    setState(() {
      _walletBalance = balance;
      _isLoadingBalance = false;
    });
  }

  bool get _showStakeSelector =>
      _selectedMode == GameMode.friend || _selectedMode == GameMode.ranked;

  bool get _isFriendMode => _selectedMode == GameMode.friend;

  double get _effectiveStakeAmount {
    if (_selectedTier == StakeTier.custom) return _customAmount;
    return _selectedTier.amount;
  }

  Future<void> _showFriendPicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FriendPickerSheet(
        userId: widget.userId,
        service: _service,
        onFriendSelected: (int id, String name, String? avatar) {
          setState(() {
            _selectedFriendId = id;
            _selectedFriendName = name;
            _selectedFriendAvatar = avatar;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _startMatch() async {
    if (_isStarting) return;

    // Require friend selection in friend mode
    if (_isFriendMode && _selectedFriendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a friend to challenge'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    // Check wallet balance for staked games
    if (_showStakeSelector && _effectiveStakeAmount > 0) {
      if (_walletBalance < _effectiveStakeAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient wallet balance for this stake'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    setState(() => _isStarting = true);

    final result = await _service.createSession(
      gameId: widget.definition.id,
      mode: _selectedMode,
      userId: widget.userId,
      stakeTier: _showStakeSelector ? _selectedTier : null,
      stakeAmount: _showStakeSelector ? _effectiveStakeAmount : null,
      opponentId: _isFriendMode ? _selectedFriendId : null,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      final session = result.data!;

      // Lock escrow if this is a staked game
      if (_showStakeSelector && _effectiveStakeAmount > 0) {
        final escrowResult = await _service.lockEscrow(
          sessionId: session.id,
          userId: widget.userId,
          amount: _effectiveStakeAmount,
        );

        if (!mounted) return;

        if (!escrowResult.success) {
          // Escrow lock failed (e.g. insufficient balance) — cancel the session
          await _service.endGame(
            session.id,
            player1Score: 0,
            player2Score: 0,
          );
          if (!mounted) return;
          setState(() => _isStarting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(escrowResult.message ?? 'Failed to lock funds — session cancelled'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isStarting = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameRoomPage(
            session: session,
            definition: widget.definition,
            userId: widget.userId,
          ),
        ),
      );
    } else {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to create session'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(def.name),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Game Info Card ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(def.icon, size: 28, color: _kPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        def.description,
                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 13, color: _kSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '~${def.estimatedMinutes} min',
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.people_outline_rounded, size: 13, color: _kSecondary),
                          const SizedBox(width: 3),
                          Text(
                            def.playerCountLabel,
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Mode Selection ────────────────────────────────────
          const Text(
            'Chagua Aina / Select Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 10),

          ...GameMode.values
              .where((m) => def.modes.contains(m))
              .map((mode) => _ModeCard(
                    mode: mode,
                    selected: mode == _selectedMode,
                    onTap: () => setState(() => _selectedMode = mode),
                  )),

          // ─── Friend Selector (friend mode) ─────────────────────
          if (_isFriendMode) ...[
            const SizedBox(height: 24),
            const Text(
              'Chagua Rafiki / Select Friend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showFriendPicker,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFriendId != null
                        ? _kPrimary
                        : Colors.grey.shade300,
                    width: _selectedFriendId != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedFriendId != null) ...[
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _selectedFriendAvatar != null
                            ? NetworkImage(_selectedFriendAvatar!)
                            : null,
                        child: _selectedFriendAvatar == null
                            ? Text(
                                (_selectedFriendName ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFriendName ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.swap_horiz_rounded,
                          size: 20, color: _kSecondary),
                    ] else ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_add_rounded,
                            size: 20, color: _kPrimary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tap to select a friend',
                          style: TextStyle(fontSize: 14, color: _kSecondary),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 20, color: _kSecondary),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // ─── Stake Selector ────────────────────────────────────
          if (_showStakeSelector) ...[
            const SizedBox(height: 24),
            const Text(
              'Kiasi cha Dau / Stake Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 10),
            StakeSelector(
              selectedTier: _selectedTier,
              walletBalance: _walletBalance,
              maxTier: def.stakeSafe ? def.maxStakeTier : StakeTier.free,
              onTierChanged: (tier) => setState(() => _selectedTier = tier),
              onCustomAmountChanged: (amount) =>
                  setState(() => _customAmount = amount),
            ),
            if (!def.stakeSafe) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This game does not support real-money stakes',
                        style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 80), // Space for bottom button
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_isStarting || _isLoadingBalance) ? null : _startMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isStarting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Start Match / Anza Mechi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final GameMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? _kPrimary.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(mode.icon, size: 24, color: selected ? _kPrimary : _kSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: _kPrimary,
                      ),
                    ),
                    Text(
                      mode.displayNameSwahili,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, size: 22, color: _kPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Friend Picker Bottom Sheet ──────────────────────────────────────────

class _FriendPickerSheet extends StatefulWidget {
  final int userId;
  final GamesService service;
  final void Function(int id, String name, String? avatar) onFriendSelected;

  const _FriendPickerSheet({
    required this.userId,
    required this.service,
    required this.onFriendSelected,
  });

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final friends = await widget.service.getFriendsForPicker(widget.userId);
    if (!mounted) return;
    setState(() {
      _friends = friends;
      _filtered = friends;
      _isLoading = false;
    });
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _friends);
      return;
    }
    setState(() {
      _filtered = _friends.where((f) {
        final name =
            '${f['first_name'] ?? ''} ${f['last_name'] ?? ''}'.toLowerCase();
        final username = (f['username'] ?? '').toString().toLowerCase();
        return name.contains(q) || username.contains(q);
      }).toList();
    });
  }

  String _friendName(Map<String, dynamic> f) {
    final first = f['first_name']?.toString() ?? '';
    final last = f['last_name']?.toString() ?? '';
    return '$first $last'.trim();
  }

  String? _friendAvatar(Map<String, dynamic> f) {
    final path = f['profile_photo_path']?.toString();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConfig.storageUrl}/$path';
  }

  int _friendId(Map<String, dynamic> f) {
    final id = f['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Chagua Rafiki / Select Friend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _kSecondary, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          ),
          const SizedBox(height: 8),

          // Friends list
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary),
                    ),
                  )
                : _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline_rounded,
                                size: 40, color: _kSecondary),
                            const SizedBox(height: 8),
                            Text(
                              _friends.isEmpty
                                  ? 'No friends found'
                                  : 'No matching friends',
                              style: const TextStyle(
                                  fontSize: 14, color: _kSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final f = _filtered[i];
                          final name = _friendName(f);
                          final avatar = _friendAvatar(f);
                          final id = _friendId(f);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: avatar != null
                                    ? NetworkImage(avatar)
                                    : null,
                                child: avatar == null
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _kPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: f['username'] != null
                                  ? Text(
                                      '@${f['username']}',
                                      style: const TextStyle(
                                          fontSize: 12, color: _kSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onTap: () {
                                widget.onFriendSelected(id, name, avatar);
                              },
                            ),
                          );
                        },
                      ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
