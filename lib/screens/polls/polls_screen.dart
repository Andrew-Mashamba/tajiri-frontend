import 'package:flutter/material.dart';
import '../../models/poll_models.dart';
import '../../services/poll_service.dart';
import 'poll_detail_screen.dart';
import 'create_poll_screen.dart';

class PollsScreen extends StatefulWidget {
  final int currentUserId;

  const PollsScreen({super.key, required this.currentUserId});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PollService _pollService = PollService();

  List<Poll> _activePolls = [];
  List<Poll> _myPolls = [];
  List<Poll> _votedPolls = [];
  bool _isLoadingActive = true;
  bool _isLoadingMy = true;
  bool _isLoadingVoted = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPolls();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    _loadActivePolls();
    _loadMyPolls();
    _loadVotedPolls();
  }

  Future<void> _loadActivePolls() async {
    setState(() => _isLoadingActive = true);
    final result = await _pollService.getPolls(currentUserId: widget.currentUserId, status: 'active');
    if (mounted) {
      setState(() {
        _isLoadingActive = false;
        if (result.success) _activePolls = result.polls;
      });
    }
  }

  Future<void> _loadMyPolls() async {
    setState(() => _isLoadingMy = true);
    final result = await _pollService.getUserPolls(widget.currentUserId);
    if (mounted) {
      setState(() {
        _isLoadingMy = false;
        if (result.success) _myPolls = result.polls;
      });
    }
  }

  Future<void> _loadVotedPolls() async {
    setState(() => _isLoadingVoted = true);
    final result = await _pollService.getUserPolls(widget.currentUserId, filter: 'voted');
    if (mounted) {
      setState(() {
        _isLoadingVoted = false;
        if (result.success) _votedPolls = result.polls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kura za Maoni'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Zinazoendelea'),
            Tab(text: 'Zangu'),
            Tab(text: 'Nilizopigia'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildMyPollsTab(),
          _buildVotedTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'polls_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePollScreen(creatorId: widget.currentUserId),
            ),
          );
          if (result == true) _loadPolls();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_isLoadingActive) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activePolls.isEmpty) {
      return _buildEmptyState('Hakuna kura zinazoendelea');
    }
    return RefreshIndicator(
      onRefresh: _loadActivePolls,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activePolls.length,
        itemBuilder: (context, index) => _buildPollCard(_activePolls[index]),
      ),
    );
  }

  Widget _buildMyPollsTab() {
    if (_isLoadingMy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myPolls.isEmpty) {
      return _buildEmptyState('Hujafungua kura yoyote');
    }
    return RefreshIndicator(
      onRefresh: _loadMyPolls,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myPolls.length,
        itemBuilder: (context, index) => _buildPollCard(_myPolls[index]),
      ),
    );
  }

  Widget _buildVotedTab() {
    if (_isLoadingVoted) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_votedPolls.isEmpty) {
      return _buildEmptyState('Hujapiga kura yoyote');
    }
    return RefreshIndicator(
      onRefresh: _loadVotedPolls,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _votedPolls.length,
        itemBuilder: (context, index) => _buildPollCard(_votedPolls[index]),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.poll, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPollCard(Poll poll) {
    final totalVotes = poll.totalVotes;
    final hasVoted = poll.userVotedOptionId != null;
    final isExpired = poll.endsAt != null && poll.endsAt!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PollDetailScreen(
                pollId: poll.id,
                currentUserId: widget.currentUserId,
              ),
            ),
          ).then((_) => _loadPolls());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: poll.creator?.profilePhotoPath != null
                        ? NetworkImage(poll.creator!.profilePhotoPath!)
                        : null,
                    child: poll.creator?.profilePhotoPath == null
                        ? Text(poll.creator?.firstName[0] ?? '?')
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poll.creator?.fullName ?? 'Mtumiaji',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatTimeAgo(poll.createdAt),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Imekwisha', style: TextStyle(fontSize: 10)),
                    )
                  else if (poll.endsAt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Inaendelea',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Question
              Text(
                poll.question,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Options preview
              ...poll.options.take(3).map((option) {
                final percentage = totalVotes > 0 ? (option.votesCount / totalVotes * 100) : 0.0;
                final isVoted = option.id == poll.userVotedOptionId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isVoted)
                            Icon(Icons.check_circle, size: 16, color: Colors.purple.shade600),
                          if (isVoted) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              option.optionText,
                              style: TextStyle(
                                fontWeight: isVoted ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasVoted || isExpired)
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (hasVoted || isExpired)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isVoted ? Colors.purple.shade400 : Colors.grey.shade400,
                            ),
                            minHeight: 6,
                          ),
                        ),
                    ],
                  ),
                );
              }),

              if (poll.options.length > 3)
                Text(
                  '+${poll.options.length - 3} chaguo zaidi',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.how_to_vote, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$totalVotes ${totalVotes == 1 ? 'kura' : 'kura'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (poll.endsAt != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      isExpired ? 'Ilimalizika' : _formatTimeRemaining(poll.endsAt!),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                  if (poll.allowMultipleVotes) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.check_box, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Chaguo nyingi',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return 'siku ${diff.inDays} zilizopita';
    if (diff.inHours > 0) return 'masaa ${diff.inHours} yaliyopita';
    if (diff.inMinutes > 0) return 'dakika ${diff.inMinutes} zilizopita';
    return 'sasa hivi';
  }

  String _formatTimeRemaining(DateTime endDate) {
    final diff = endDate.difference(DateTime.now());
    if (diff.inDays > 0) return 'siku ${diff.inDays} zimebaki';
    if (diff.inHours > 0) return 'masaa ${diff.inHours} yamebaki';
    if (diff.inMinutes > 0) return 'dakika ${diff.inMinutes} zimebaki';
    return 'inakaribia kuisha';
  }
}
