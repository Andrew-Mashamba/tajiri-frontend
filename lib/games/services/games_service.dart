// lib/games/services/games_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../core/game_enums.dart';
import '../models/game_session.dart';
import '../models/game_escrow.dart';
import '../models/leaderboard_entry.dart';
import '../models/game_result.dart';

String get _baseUrl => ApiConfig.baseUrl;

class GamesService {
  // ─── Sessions ──────────────────────────────────────────────────

  /// Create a new game session.
  Future<GameResult<GameSession>> createSession({
    required String gameId,
    required GameMode mode,
    required int userId,
    StakeTier? stakeTier,
    double? stakeAmount,
    int? opponentId,
  }) async {
    try {
      final body = <String, dynamic>{
        'game_id': gameId,
        'mode': mode.name,
        'user_id': userId,
      };
      if (stakeTier != null) body['stake_tier'] = stakeTier.name;
      if (stakeAmount != null) body['stake_amount'] = stakeAmount;
      if (opponentId != null) body['opponent_id'] = opponentId;

      final response = await http.post(
        Uri.parse('$_baseUrl/games/sessions'),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true && data['data'] != null) {
          return GameResult(
            success: true,
            data: GameSession.fromJson(data['data'] as Map<String, dynamic>),
          );
        }
      }
      return GameResult(
        success: false,
        message: data['message']?.toString() ?? 'Failed to create session',
      );
    } catch (e) {
      return GameResult(success: false, message: 'Error: $e');
    }
  }

  /// Get a session by ID.
  Future<GameResult<GameSession>> getSession(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/games/sessions/$id'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return GameResult(
            success: true,
            data: GameSession.fromJson(data['data'] as Map<String, dynamic>),
          );
        }
      }
      return GameResult(success: false, message: 'Session not found');
    } catch (e) {
      return GameResult(success: false, message: 'Error: $e');
    }
  }

  /// Join an existing session.
  Future<GameResult<GameSession>> joinSession(int id, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/games/sessions/$id/join'),
        headers: ApiConfig.headers,
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        return GameResult(
          success: true,
          data: GameSession.fromJson(data['data'] as Map<String, dynamic>),
        );
      }
      return GameResult(
        success: false,
        message: data['message']?.toString() ?? 'Failed to join session',
      );
    } catch (e) {
      return GameResult(success: false, message: 'Error: $e');
    }
  }

  /// Submit a game move.
  Future<GameResult<void>> submitMove(
    int sessionId,
    int userId,
    Map<String, dynamic> moveData, {
    Map<String, dynamic>? gameState,
  }) async {
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'move_data': moveData,
      };
      if (gameState != null) body['game_state'] = gameState;

      final response = await http.post(
        Uri.parse('$_baseUrl/games/sessions/$sessionId/move'),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return GameResult(success: true);
      }
      return GameResult(
        success: false,
        message: data['message']?.toString() ?? 'Failed to submit move',
      );
    } catch (e) {
      return GameResult(success: false, message: 'Error: $e');
    }
  }

  /// End a game session with final scores.
  Future<GameResult<GameSession>> endGame(
    int sessionId, {
    int? winnerId,
    required int player1Score,
    required int player2Score,
  }) async {
    try {
      final body = <String, dynamic>{
        'player_1_score': player1Score,
        'player_2_score': player2Score,
      };
      if (winnerId != null) body['winner_id'] = winnerId;

      final response = await http.post(
        Uri.parse('$_baseUrl/games/sessions/$sessionId/end'),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        return GameResult(
          success: true,
          data: GameSession.fromJson(data['data'] as Map<String, dynamic>),
        );
      }
      return GameResult(
        success: false,
        message: data['message']?.toString() ?? 'Failed to end game',
      );
    } catch (e) {
      return GameResult(success: false, message: 'Error: $e');
    }
  }

  /// Get active sessions for a user.
  Future<GameListResult<GameSession>> getActiveSessions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/games/sessions/active?user_id=$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final list = data['data'];
          if (list is List) {
            final items = list
                .map((j) => GameSession.fromJson(j as Map<String, dynamic>))
                .toList();
            return GameListResult(success: true, items: items);
          }
        }
      }
      return GameListResult(success: false, message: 'Failed to load sessions');
    } catch (e) {
      return GameListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get game history for a user (paginated).
  Future<GameListResult<GameSession>> getHistory(int userId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/games/sessions/history?user_id=$userId&page=$page'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final list = data['data'];
          if (list is List) {
            final items = list
                .map((j) => GameSession.fromJson(j as Map<String, dynamic>))
                .toList();
            return GameListResult(success: true, items: items);
          }
        }
      }
      return GameListResult(success: false, message: 'Failed to load history');
    } catch (e) {
      return GameListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Leaderboard ───────────────────────────────────────────────

  /// Get global leaderboard.
  Future<GameListResult<LeaderboardEntry>> getLeaderboard({
    String? gameId,
    String period = 'alltime',
    int limit = 50,
  }) async {
    try {
      final params = <String, String>{
        'period': period,
        'limit': '$limit',
      };
      if (gameId != null) params['game_id'] = gameId;

      final uri = Uri.parse('$_baseUrl/games/leaderboard/global')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final list = data['data'];
          if (list is List) {
            final items = list
                .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
                .toList();
            return GameListResult(success: true, items: items);
          }
        }
      }
      return GameListResult(success: false, message: 'Failed to load leaderboard');
    } catch (e) {
      return GameListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get friends leaderboard.
  Future<GameListResult<LeaderboardEntry>> getFriendsLeaderboard(
    int userId, {
    String? gameId,
    String period = 'alltime',
  }) async {
    try {
      final params = <String, String>{
        'user_id': '$userId',
        'period': period,
      };
      if (gameId != null) params['game_id'] = gameId;

      final uri = Uri.parse('$_baseUrl/games/leaderboard/friends')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final list = data['data'];
          if (list is List) {
            final items = list
                .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
                .toList();
            return GameListResult(success: true, items: items);
          }
        }
      }
      return GameListResult(success: false, message: 'Failed to load friends leaderboard');
    } catch (e) {
      return GameListResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Escrow ────────────────────────────────────────────────────

  /// Lock funds in escrow for a game session.
  Future<GameResult<GameEscrow>> lockEscrow({
    required int sessionId,
    required int userId,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/games/escrow/lock'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'session_id': sessionId,
          'user_id': userId,
          'amount': amount,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        return GameResult(
          success: true,
          data: GameEscrow.fromJson(data['data'] as Map<String, dynamic>),
        );
      }
      return GameResult(
        success: false,
        message: data['message']?.toString() ?? 'Failed to lock escrow',
      );
    } catch (e) {
      return GameResult(success: false, message: 'Error: $e');
    }
  }

  /// Settle escrow — pay the winner.
  Future<GameResult<void>> settleEscrow({
    required int sessionId,
    required int winnerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/games/escrow/settle'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'session_id': sessionId,
          'winner_id': winnerId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return GameResult(success: true);
      }
      return GameResult(
        success: false,
        message: data['message']?.toString() ?? 'Failed to settle escrow',
      );
    } catch (e) {
      return GameResult(success: false, message: 'Error: $e');
    }
  }

  // ─── Challenge helpers ─────────────────────────────────────────

  /// Get pending challenges where [userId] is the invited player.
  /// Filters active sessions for status==pending AND player_2_id == userId.
  Future<GameListResult<GameSession>> getPendingChallenges(int userId) async {
    final result = await getActiveSessions(userId);
    if (!result.success) return result;
    final pending = result.items
        .where((s) =>
            s.status == SessionStatus.pending && s.player2Id == userId)
        .toList();
    return GameListResult(success: true, items: pending);
  }

  /// Accept a challenge by joining the session.
  Future<GameResult<GameSession>> acceptChallenge(int sessionId, int userId) async {
    return joinSession(sessionId, userId);
  }

  /// Decline a challenge by ending the session with 0-0 scores (cancelled).
  Future<GameResult<GameSession>> declineChallenge(int sessionId) async {
    return endGame(sessionId, player1Score: 0, player2Score: 0);
  }

  // ─── Wallet ────────────────────────────────────────────────────

  /// Fetch the user's wallet balance.
  Future<double> getWalletBalance(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final balance = data['data']['balance'];
          if (balance is num) return balance.toDouble();
          if (balance is String) return double.tryParse(balance) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── Friends (for friend picker) ──────────────────────────────

  /// Fetch user's accepted friends for the game challenge picker.
  Future<List<Map<String, dynamic>>> getFriendsForPicker(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/friends?user_id=$userId&per_page=100'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .map((f) => f as Map<String, dynamic>)
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Refund escrow for a cancelled session.
  Future<GameResult<void>> refundEscrow({required int sessionId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/games/escrow/refund'),
        headers: ApiConfig.headers,
        body: jsonEncode({'session_id': sessionId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return GameResult(success: true);
      }
      return GameResult(
        success: false,
        message: data['message']?.toString() ?? 'Failed to refund escrow',
      );
    } catch (e) {
      return GameResult(success: false, message: 'Error: $e');
    }
  }
}
