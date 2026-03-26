import 'package:flutter/material.dart';
import '../../models/battle_models.dart';
import '../../models/gossip_models.dart';
import '../../services/battle_service.dart';
import '../../services/gossip_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/post_card.dart';
import '../../l10n/app_strings_scope.dart';

class BattleThreadScreen extends StatefulWidget {
  final int battleId;
  final int currentUserId;

  const BattleThreadScreen({super.key, required this.battleId, required this.currentUserId});

  @override
  State<BattleThreadScreen> createState() => _BattleThreadScreenState();
}

class _BattleThreadScreenState extends State<BattleThreadScreen> {
  final BattleService _battleService = BattleService();
  final GossipService _gossipService = GossipService();
  CreatorBattle? _battle;
  GossipThreadDetail? _threadDetail;
  bool _loading = true;
  String? _error;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final battle = await _battleService.getBattle(token: token, battleId: widget.battleId);
      GossipThreadDetail? thread;
      if (battle?.threadId != null) {
        thread = await _gossipService.getThread(token: token, threadId: battle!.threadId!);
      }
      if (mounted) {
        setState(() {
          _battle = battle;
          _threadDetail = thread;
          _loading = false;
          if (battle == null) _error = 'Battle not found';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  Future<void> _vote(String side) async {
    if (_voting || _battle == null) return;
    setState(() => _voting = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) { setState(() => _voting = false); return; }
    final success = await _battleService.vote(token: token, battleId: _battle!.id, side: side);
    if (mounted) {
      setState(() => _voting = false);
      if (success) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStringsScope.of(context)?.voteCast ?? 'Vote cast!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          strings?.creatorBattles ?? 'Creator Battle',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFF666666))))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF1A1A1A),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_battle!.topic,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildVoteSide(
                                  name: _battle!.creatorAName ?? (strings?.sideA ?? 'Side A'),
                                  percent: _battle!.percentA,
                                  side: 'a',
                                  isSelected: _battle!.userVote == 'a',
                                )),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(strings?.vs ?? 'vs',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF999999))),
                                ),
                                Expanded(child: _buildVoteSide(
                                  name: _battle!.creatorBName ?? (strings?.sideB ?? 'Side B'),
                                  percent: _battle!.percentB,
                                  side: 'b',
                                  isSelected: _battle!.userVote == 'b',
                                )),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: _battle!.percentA.round().clamp(1, 99),
                                    child: Container(height: 8, color: const Color(0xFF1A1A1A)),
                                  ),
                                  Expanded(
                                    flex: _battle!.percentB.round().clamp(1, 99),
                                    child: Container(height: 8, color: const Color(0xFFCCCCCC)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text('${_battle!.totalVotes} ${strings?.votes ?? "votes"}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                            ),
                          ],
                        ),
                      ),
                      if (_threadDetail != null)
                        ..._threadDetail!.posts.map((post) => PostCard(
                              key: ValueKey('battle_post_${post.id}'),
                              post: post,
                              currentUserId: widget.currentUserId,
                            )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVoteSide({
    required String name,
    required double percent,
    required String side,
    required bool isSelected,
  }) {
    final canVote = _battle!.userVote == null && _battle!.status == BattleStatus.open;
    return GestureDetector(
      onTap: canVote && !_voting ? () => _vote(side) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                )),
            const SizedBox(height: 4),
            Text('${percent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                )),
            if (canVote) ...[
              const SizedBox(height: 6),
              Text(AppStringsScope.of(context)?.castVote ?? 'Tap to vote',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : const Color(0xFF999999),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
