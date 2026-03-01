import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/poll_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class PollService {
  /// Get list of polls
  Future<PollListResult> getPolls({
    int page = 1,
    int perPage = 20,
    String status = 'active', // active, ended, all
    int? groupId,
    int? pageId,
    int? currentUserId,
  }) async {
    try {
      String url = '$_baseUrl/polls?page=$page&per_page=$perPage&status=$status';
      if (groupId != null) url += '&group_id=$groupId';
      if (pageId != null) url += '&page_id=$pageId';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final polls = (data['data'] as List)
              .map((p) => Poll.fromJson(p))
              .toList();
          return PollListResult(success: true, polls: polls);
        }
      }
      return PollListResult(success: false, message: 'Failed to load polls');
    } catch (e) {
      return PollListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get user's polls
  Future<PollListResult> getUserPolls(int userId, {String? filter}) async {
    try {
      String url = '$_baseUrl/polls/user?user_id=$userId';
      if (filter != null) url += '&filter=$filter';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final polls = (data['data'] as List)
              .map((p) => Poll.fromJson(p))
              .toList();
          return PollListResult(success: true, polls: polls);
        }
      }
      return PollListResult(success: false, message: 'Failed to load polls');
    } catch (e) {
      return PollListResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a new poll
  Future<PollResult> createPoll({
    required int creatorId,
    required String question,
    required List<String> options,
    String? description,
    int? postId,
    int? groupId,
    int? pageId,
    DateTime? endsAt,
    bool isMultipleChoice = false,
    bool isAnonymous = false,
    bool showResultsBeforeVoting = true,
    bool allowAddOptions = false,
    bool allowMultipleVotes = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/polls'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'creator_id': creatorId,
          'question': question,
          'options': options,
          if (description != null) 'description': description,
          if (postId != null) 'post_id': postId,
          if (groupId != null) 'group_id': groupId,
          if (pageId != null) 'page_id': pageId,
          if (endsAt != null) 'ends_at': endsAt.toIso8601String(),
          'is_multiple_choice': isMultipleChoice || allowMultipleVotes,
          'is_anonymous': isAnonymous,
          'show_results_before_voting': showResultsBeforeVoting,
          'allow_add_options': allowAddOptions,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return PollResult(
          success: true,
          poll: Poll.fromJson(data['data']),
          message: data['message'],
        );
      }
      return PollResult(success: false, message: data['message'] ?? 'Failed to create poll');
    } catch (e) {
      return PollResult(success: false, message: 'Error: $e');
    }
  }

  /// Get a single poll
  Future<PollResult> getPoll(String identifier, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/polls/$identifier';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return PollResult(success: true, poll: Poll.fromJson(data['data']));
        }
      }
      return PollResult(success: false, message: 'Poll not found');
    } catch (e) {
      return PollResult(success: false, message: 'Error: $e');
    }
  }

  /// Vote on a poll
  Future<PollResult> vote(int pollId, int userId, List<int> optionIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/polls/$pollId/vote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'option_ids': optionIds,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PollResult(
          success: true,
          poll: Poll.fromJson(data['data']),
        );
      }
      return PollResult(success: false, message: data['message'] ?? 'Failed to vote');
    } catch (e) {
      return PollResult(success: false, message: 'Error: $e');
    }
  }

  /// Remove vote from a poll
  Future<PollResult> unvote(int pollId, int userId, {int? optionId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/polls/$pollId/vote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (optionId != null) 'option_id': optionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PollResult(
          success: true,
          poll: Poll.fromJson(data['data']),
        );
      }
      return PollResult(success: false, message: data['message'] ?? 'Failed to remove vote');
    } catch (e) {
      return PollResult(success: false, message: 'Error: $e');
    }
  }

  /// Add an option to a poll
  Future<OptionResult> addOption(int pollId, int userId, String optionText) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/polls/$pollId/options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'option_text': optionText,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return OptionResult(
          success: true,
          option: PollOption.fromJson(data['data']),
        );
      }
      return OptionResult(success: false, message: data['message'] ?? 'Failed to add option');
    } catch (e) {
      return OptionResult(success: false, message: 'Error: $e');
    }
  }

  /// Get voters for an option
  Future<VoterListResult> getOptionVoters(int pollId, int optionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/polls/$pollId/options/$optionId/voters'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final voters = (data['data'] as List)
              .map((v) => PollVoter.fromJson(v))
              .toList();
          return VoterListResult(success: true, voters: voters);
        }
      }
      return VoterListResult(success: false, message: 'Failed to load voters');
    } catch (e) {
      return VoterListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get all voters for a poll
  Future<VoterListResult> getVoters(int pollId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/polls/$pollId/voters'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final voters = (data['data'] as List)
              .map((v) => PollVoter.fromJson(v))
              .toList();
          return VoterListResult(success: true, voters: voters);
        }
      }
      return VoterListResult(success: false, message: 'Failed to load voters');
    } catch (e) {
      return VoterListResult(success: false, message: 'Error: $e');
    }
  }

  /// End a poll early
  Future<bool> endPoll(int pollId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/polls/$pollId/end'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Close a poll
  Future<bool> closePoll(int pollId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/polls/$pollId/close'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete a poll
  Future<bool> deletePoll(int pollId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/polls/$pollId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Result classes
class PollListResult {
  final bool success;
  final List<Poll> polls;
  final String? message;

  PollListResult({required this.success, this.polls = const [], this.message});
}

class PollResult {
  final bool success;
  final Poll? poll;
  final String? message;

  PollResult({required this.success, this.poll, this.message});
}

class OptionResult {
  final bool success;
  final PollOption? option;
  final String? message;

  OptionResult({required this.success, this.option, this.message});
}

class VoterListResult {
  final bool success;
  final List<PollVoter> voters;
  final String? message;

  VoterListResult({required this.success, this.voters = const [], this.message});
}
