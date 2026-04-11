// lib/games/pages/game_leaderboard_page.dart
import 'package:flutter/material.dart';
import '../core/game_registry.dart';
import '../core/game_definition.dart';
import '../models/leaderboard_entry.dart';
import '../services/games_service.dart';
import '../widgets/leaderboard_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Leaderboard page showing global and friends rankings.
class GameLeaderboardPage extends StatefulWidget {
  final int userId;

  const GameLeaderboardPage({super.key, required this.userId});

  @override
  State<GameLeaderboardPage> createState() => _GameLeaderboardPageState();
}

class _GameLeaderboardPageState extends State<GameLeaderboardPage>
    with SingleTickerProviderStateMixin {
  final GamesService _service = GamesService();
  late TabController _tabCtrl;

  // Filter state
  String? _selectedGameId; // null = All Games
  String _period = 'alltime';

  // Data
  List<LeaderboardEntry> _globalEntries = [];
  List<LeaderboardEntry> _friendsEntries = [];
  bool _isLoading = true;
  String? _error;

  static const List<_PeriodOption> _periods = [
    _PeriodOption(value: 'weekly', label: 'Weekly', labelSw: 'Wiki'),
    _PeriodOption(value: 'monthly', label: 'Monthly', labelSw: 'Mwezi'),
    _PeriodOption(value: 'alltime', label: 'All-Time', labelSw: 'Yote'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_tabCtrl.index == 0) {
      final result = await _service.getLeaderboard(
        gameId: _selectedGameId,
        period: _period,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _globalEntries = result.items;
        } else {
          _error = result.message ?? 'Failed to load leaderboard';
        }
      });
    } else {
      final result = await _service.getFriendsLeaderboard(
        widget.userId,
        gameId: _selectedGameId,
        period: _period,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _friendsEntries = result.items;
        } else {
          _error = result.message ?? 'Failed to load friends leaderboard';
        }
      });
    }
  }

  List<GameDefinition> get _allGames => GameRegistry.instance.allGames;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Leaderboard / Ubingwa'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends / Marafiki'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Filters ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Game selector dropdown
                _buildGameDropdown(),
                const SizedBox(height: 10),
                // Period chips
                _buildPeriodChips(),
              ],
            ),
          ),

          // ─── List ─────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_globalEntries),
                _buildList(_friendsEntries),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        color: const Color(0xFFFAFAFA),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedGameId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kSecondary),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Games / Michezo Yote',
                style: TextStyle(fontSize: 14, color: _kPrimary),
              ),
            ),
            ..._allGames.map((g) => DropdownMenuItem<String?>(
                  value: g.id,
                  child: Row(
                    children: [
                      Icon(g.icon, size: 18, color: _kSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          g.name,
                          style: const TextStyle(fontSize: 14, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          onChanged: (value) {
            setState(() => _selectedGameId = value);
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    return Row(
      children: _periods.map((p) {
        final selected = p.value == _period;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() => _period = p.value);
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? _kPrimary : Colors.grey.shade300,
                ),
              ),
              child: Text(
                '${p.label} / ${p.labelSw}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : _kPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildList(List<LeaderboardEntry> entries) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 14, color: _kSecondary),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: _loadData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Retry / Jaribu Tena'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.leaderboard_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'No rankings yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hakuna cheo bado',
                style: TextStyle(fontSize: 13, color: _kSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final entry = entries[i];
          return LeaderboardTile(
            entry: entry,
            isCurrentUser: entry.userId == widget.userId,
          );
        },
      ),
    );
  }
}

class _PeriodOption {
  final String value;
  final String label;
  final String labelSw;

  const _PeriodOption({
    required this.value,
    required this.label,
    required this.labelSw,
  });
}
