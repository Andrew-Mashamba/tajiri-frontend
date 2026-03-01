import 'package:flutter/material.dart';
import '../../models/poll_models.dart';
import '../../services/poll_service.dart';

class PollDetailScreen extends StatefulWidget {
  final int pollId;
  final int currentUserId;

  const PollDetailScreen({
    super.key,
    required this.pollId,
    required this.currentUserId,
  });

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  final PollService _pollService = PollService();

  Poll? _poll;
  List<PollVoter> _voters = [];
  bool _isLoading = true;
  bool _isVoting = false;
  int? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  Future<void> _loadPoll() async {
    setState(() => _isLoading = true);
    final result = await _pollService.getPoll(
      '${widget.pollId}',
      currentUserId: widget.currentUserId,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _poll = result.poll;
          _selectedOptionId = result.poll?.userVotedOptionId;
        }
      });
      if (result.success) _loadVoters();
    }
  }

  Future<void> _loadVoters() async {
    final result = await _pollService.getVoters(widget.pollId);
    if (mounted && result.success) {
      setState(() => _voters = result.voters);
    }
  }

  Future<void> _vote(int optionId) async {
    if (_poll == null) return;

    setState(() {
      _isVoting = true;
      _selectedOptionId = optionId;
    });

    final result = await _pollService.vote(widget.pollId, widget.currentUserId, [optionId]);

    if (mounted) {
      if (result.success) {
        _loadPoll();
      } else {
        setState(() => _selectedOptionId = _poll?.userVotedOptionId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindikana kupiga kura')),
        );
      }
      setState(() => _isVoting = false);
    }
  }

  Future<void> _unvote() async {
    if (_poll == null || _poll!.userVotedOptionId == null) return;

    setState(() => _isVoting = true);

    final result = await _pollService.unvote(widget.pollId, widget.currentUserId);

    if (mounted) {
      if (result.success) {
        setState(() => _selectedOptionId = null);
        _loadPoll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindikana kuondoa kura')),
        );
      }
      setState(() => _isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_poll == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Kura haipatikani')),
      );
    }

    final totalVotes = _poll!.totalVotes;
    final hasVoted = _poll!.userVotedOptionId != null;
    final isExpired = _poll!.endsAt != null && _poll!.endsAt!.isBefore(DateTime.now());
    final canVote = !isExpired && _poll!.status == 'active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kura ya Maoni'),
        actions: [
          if (_poll!.creatorId == widget.currentUserId)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'close') {
                  await _pollService.closePoll(widget.pollId);
                  _loadPoll();
                } else if (value == 'delete') {
                  await _pollService.deletePoll(widget.pollId);
                  Navigator.pop(context, true);
                }
              },
              itemBuilder: (context) => [
                if (_poll!.status == 'active')
                  const PopupMenuItem(value: 'close', child: Text('Funga kura')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Futa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPoll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Creator info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: _poll!.creator?.profilePhotoPath != null
                        ? NetworkImage(_poll!.creator!.profilePhotoPath!)
                        : null,
                    child: _poll!.creator?.profilePhotoPath == null
                        ? Text(_poll!.creator?.firstName[0] ?? '?')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _poll!.creator?.fullName ?? 'Mtumiaji',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _formatDateTime(_poll!.createdAt),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(isExpired),
                ],
              ),
              const SizedBox(height: 20),

              // Question
              Text(
                _poll!.question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_poll!.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  _poll!.description!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                ),
              ],
              const SizedBox(height: 24),

              // Poll info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(Icons.how_to_vote, '$totalVotes', 'Kura'),
                    if (_poll!.endsAt != null)
                      _buildInfoItem(
                        Icons.timer,
                        isExpired ? 'Imekwisha' : _formatTimeRemaining(_poll!.endsAt!),
                        'Muda',
                      ),
                    if (_poll!.allowMultipleVotes)
                      _buildInfoItem(Icons.check_box, 'Ndiyo', 'Chaguo nyingi'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Options
              const Text(
                'Chaguo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...List.generate(_poll!.options.length, (index) {
                final option = _poll!.options[index];
                final percentage = totalVotes > 0 ? (option.votesCount / totalVotes * 100) : 0.0;
                final isSelected = option.id == _selectedOptionId;
                final wasVoted = option.id == _poll!.userVotedOptionId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: canVote && !_isVoting ? () => _vote(option.id) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.purple : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? Colors.purple.shade50 : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (canVote)
                                Radio<int>(
                                  value: option.id,
                                  groupValue: _selectedOptionId,
                                  onChanged: _isVoting ? null : (v) => _vote(option.id),
                                  activeColor: Colors.purple,
                                )
                              else if (wasVoted)
                                const Icon(Icons.check_circle, color: Colors.purple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  option.optionText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: wasVoted ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasVoted || isExpired)
                                Text(
                                  '${option.votesCount} (${percentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          if (hasVoted || isExpired) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  wasVoted ? Colors.purple : Colors.purple.shade200,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Unvote button
              if (hasVoted && canVote) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _isVoting ? null : _unvote,
                    icon: const Icon(Icons.undo),
                    label: const Text('Ondoa kura yangu'),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Voters list
              if (_voters.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Waliopiga Kura',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_voters.length} watu',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _voters.length,
                    itemBuilder: (context, index) {
                      final voter = _voters[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: voter.user?.profilePhotoPath != null
                                  ? NetworkImage(voter.user!.profilePhotoPath!)
                                  : null,
                              child: voter.user?.profilePhotoPath == null
                                  ? Text(voter.user?.firstName[0] ?? '?')
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voter.user?.firstName ?? '',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired) {
    if (_poll!.status == 'closed' || isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Imefungwa', style: TextStyle(fontSize: 12)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Inaendelea',
        style: TextStyle(fontSize: 12, color: Colors.green.shade700),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeRemaining(DateTime endDate) {
    final diff = endDate.difference(DateTime.now());
    if (diff.inDays > 0) return 'Siku ${diff.inDays}';
    if (diff.inHours > 0) return 'Masaa ${diff.inHours}';
    if (diff.inMinutes > 0) return 'Dakika ${diff.inMinutes}';
    return 'Inakaribia';
  }
}
