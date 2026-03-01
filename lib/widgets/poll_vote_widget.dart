import 'package:flutter/material.dart';
import '../models/poll_models.dart';
import '../services/poll_service.dart';

/// Inline poll widget for post cards: tap option to vote, then results are shown.
/// Touch targets min 48dp per DOCS/DESIGN.md.
class PollVoteWidget extends StatefulWidget {
  final int pollId;
  final int currentUserId;
  /// Optional initial poll (e.g. from embedded post response) to avoid initial load.
  final Poll? initialPoll;

  const PollVoteWidget({
    super.key,
    required this.pollId,
    required this.currentUserId,
    this.initialPoll,
  });

  @override
  State<PollVoteWidget> createState() => _PollVoteWidgetState();
}

class _PollVoteWidgetState extends State<PollVoteWidget> {
  final PollService _pollService = PollService();

  Poll? _poll;
  bool _isLoading = true;
  bool _isVoting = false;
  int? _pendingOptionId; // Show selection while vote request is in flight
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPoll != null && widget.initialPoll!.id == widget.pollId) {
      _poll = widget.initialPoll;
      _isLoading = false;
    } else {
      _loadPoll();
    }
  }

  Future<void> _loadPoll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _pollService.getPoll(
      '${widget.pollId}',
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _poll = result.poll;
      } else {
        _error = result.message ?? 'Imeshindwa kupakia kura';
      }
    });
  }

  Future<void> _vote(int optionId) async {
    if (_poll == null) return;

    setState(() {
      _isVoting = true;
      _pendingOptionId = optionId;
    });

    final result = await _pollService.vote(
      widget.pollId,
      widget.currentUserId,
      [optionId],
    );

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _poll = result.poll;
        _pendingOptionId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Umepiga kura. Asante!')),
      );
    } else {
      setState(() => _pendingOptionId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindikana kupiga kura')),
      );
    }
    setState(() => _isVoting = false);
  }

  Future<void> _unvote() async {
    if (_poll == null || _poll!.userVotedOptionId == null) return;

    setState(() => _isVoting = true);

    final result = await _pollService.unvote(widget.pollId, widget.currentUserId);

    if (!mounted) return;
    if (result.success) {
      setState(() => _poll = result.poll);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kura yako imeondolewa')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindikana kuondoa kura')),
      );
    }
    setState(() => _isVoting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Inapakia kura...', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    if (_error != null || _poll == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error ?? 'Kura haipatikani',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _loadPoll,
              child: const Text('Jaribu tena'),
            ),
          ],
        ),
      );
    }

    final totalVotes = _poll!.totalVotes;
    final hasVoted = _poll!.userVotedOptionId != null;
    final isExpired = _poll!.hasEnded;
    final canVote = !isExpired && _poll!.status == 'active' && !_isVoting;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll_outlined, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _poll!.question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_poll!.description != null && _poll!.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _poll!.description!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(_poll!.options.length, (index) {
            final option = _poll!.options[index];
            final percentage =
                totalVotes > 0 ? (option.votesCount / totalVotes * 100) : 0.0;
            final wasVoted = option.id == _poll!.userVotedOptionId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 0,
                child: InkWell(
                  onTap: canVote ? () => _vote(option.id) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: wasVoted
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey.shade300,
                        width: wasVoted ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (canVote)
                              Radio<int>(
                                value: option.id,
                                groupValue: _poll!.userVotedOptionId ??
                                    _pendingOptionId,
                                onChanged: canVote
                                    ? (v) => _vote(option.id)
                                    : null,
                                activeColor: const Color(0xFF1A1A1A),
                              )
                            else if (wasVoted)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1A1A1A),
                                size: 22,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.optionText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      wasVoted ? FontWeight.w600 : FontWeight.normal,
                                  color: const Color(0xFF1A1A1A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasVoted || isExpired)
                              Text(
                                '${option.votesCount} (${percentage.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 12,
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
                                wasVoted
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.grey.shade400,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (hasVoted && canVote) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: _isVoting ? null : _unvote,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Ondoa kura yangu'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ),
          ],
          if (totalVotes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Jumla: $totalVotes kura',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
