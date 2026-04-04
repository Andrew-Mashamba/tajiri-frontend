import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../HttpService.dart';
import '../DataStore.dart';

/// Model for a pending vote
class PendingVote {
  final String caseId;
  final String type;
  final String vote;
  final String position;
  final String userId;
  final DateTime createdAt;
  int retryCount;

  PendingVote({
    required this.caseId,
    required this.type,
    required this.vote,
    required this.position,
    required this.userId,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'caseId': caseId,
    'type': type,
    'vote': vote,
    'position': position,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory PendingVote.fromJson(Map<String, dynamic> json) => PendingVote(
    caseId: json['caseId'] ?? '',
    type: json['type'] ?? '',
    vote: json['vote'] ?? '',
    position: json['position'] ?? '',
    userId: json['userId'] ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    retryCount: json['retryCount'] ?? 0,
  );
}

/// Service to handle offline vote queuing and sync
class OfflineVoteQueue {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: true, printEmojis: true),
  );

  static const String _queueKey = 'pending_votes_queue';
  static const int _maxRetries = 3;
  static bool _isProcessing = false;

  // Callbacks
  static void Function(int pendingCount)? onQueueChanged;
  static void Function(PendingVote vote, bool success)? onVoteSynced;

  /// Queue a vote for later sync (when offline)
  static Future<void> queueVote({
    required String caseId,
    required String type,
    required String vote,
    String? position,
    String? userId,
  }) async {
    final pendingVote = PendingVote(
      caseId: caseId,
      type: type,
      vote: vote,
      position: position ?? '1',
      userId: userId ?? DataStore.currentUserId ?? '',
    );

    _logger.i('📥 Queuing vote for offline sync: ${pendingVote.caseId}');

    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode(pendingVote.toJson()));
    await prefs.setStringList(_queueKey, queue);

    onQueueChanged?.call(queue.length);
    _logger.i('📥 Vote queued. Total pending: ${queue.length}');
  }

  /// Get all pending votes
  static Future<List<PendingVote>> getPendingVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    return queue.map((s) {
      try {
        return PendingVote.fromJson(jsonDecode(s));
      } catch (e) {
        return null;
      }
    }).whereType<PendingVote>().toList();
  }

  /// Get pending votes count
  static Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    return queue.length;
  }

  /// Clear all pending votes
  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    onQueueChanged?.call(0);
    _logger.i('🗑️ Vote queue cleared');
  }

  /// Remove a specific vote from queue
  static Future<void> _removeVote(PendingVote vote) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];

    queue.removeWhere((s) {
      try {
        final v = PendingVote.fromJson(jsonDecode(s));
        return v.caseId == vote.caseId && v.userId == vote.userId;
      } catch (e) {
        return false;
      }
    });

    await prefs.setStringList(_queueKey, queue);
    onQueueChanged?.call(queue.length);
  }

  /// Update retry count for a vote
  static Future<void> _updateRetryCount(PendingVote vote) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];

    final updatedQueue = queue.map((s) {
      try {
        final v = PendingVote.fromJson(jsonDecode(s));
        if (v.caseId == vote.caseId && v.userId == vote.userId) {
          v.retryCount = vote.retryCount + 1;
          return jsonEncode(v.toJson());
        }
        return s;
      } catch (e) {
        return s;
      }
    }).toList();

    await prefs.setStringList(_queueKey, updatedQueue);
  }

  /// Sync all pending votes to server
  /// Call this when connectivity is restored
  static Future<void> syncPendingVotes() async {
    if (_isProcessing) {
      _logger.w('⏳ Already processing queue');
      return;
    }

    _isProcessing = true;
    _logger.i('🔄 Starting to sync pending votes...');

    try {
      final votes = await getPendingVotes();

      if (votes.isEmpty) {
        _logger.i('✅ No pending votes to sync');
        return;
      }

      _logger.i('📤 Syncing ${votes.length} pending votes');

      for (var vote in votes) {
        // Skip if too many retries
        if (vote.retryCount >= _maxRetries) {
          _logger.w('⚠️ Vote exceeded max retries, removing: ${vote.caseId}');
          await _removeVote(vote);
          onVoteSynced?.call(vote, false);
          continue;
        }

        try {
          _logger.d('📤 Syncing vote: ${vote.caseId} (attempt ${vote.retryCount + 1})');

          final result = await HttpService.vote(
            vote.type,
            vote.position,
            vote.caseId,
            vote.vote,
            vote.userId,
          );

          final data = jsonDecode(result);
          final status = data['status']?.toString().trim();
          final message = data['message']?.toString().trim();

          if (status == 'success' || message == 'voted') {
            _logger.i('✅ Vote synced successfully: ${vote.caseId}');
            await _removeVote(vote);
            onVoteSynced?.call(vote, true);
          } else if (status == 'error' && message == 'ALREADY_VOTED') {
            // Already voted, remove from queue
            _logger.i('ℹ️ Already voted, removing from queue: ${vote.caseId}');
            await _removeVote(vote);
            onVoteSynced?.call(vote, true);
          } else {
            _logger.w('⚠️ Vote sync failed: $message');
            await _updateRetryCount(vote);
          }
        } catch (e) {
          _logger.e('❌ Error syncing vote: $e');
          await _updateRetryCount(vote);

          // If network error, stop processing (will retry when online)
          if (e.toString().contains('SocketException') ||
              e.toString().contains('Connection')) {
            _logger.w('🔌 Network error, stopping queue processing');
            break;
          }
        }

        // Small delay between votes to avoid overwhelming server
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      _isProcessing = false;
      final remaining = await getPendingCount();
      _logger.i('🔄 Queue sync complete. Remaining: $remaining');
    }
  }

  /// Check if there are pending votes
  static Future<bool> hasPendingVotes() async {
    final count = await getPendingCount();
    return count > 0;
  }
}
