import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/people_search_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Result of a people search call (success or validation/API error).
class PeopleSearchResult {
  final bool success;
  final PeopleSearchResponse? response;
  final String? message;
  final int? statusCode;

  PeopleSearchResult.success(PeopleSearchResponse r)
      : success = true,
        response = r,
        message = null,
        statusCode = 200;

  PeopleSearchResult.failure(this.message, [this.statusCode])
      : success = false,
        response = null;

  bool get isValidationError => statusCode == 400;
}

/// Service for GET /api/people/search.
/// No Bearer token required. Pass user_id for mutual friends, friendship status, in_common.
///
/// Backend behavior:
/// - GET with empty q and no filters → discovery feed (composite scoring: friends-of-friends,
///   same district/school/employer/region, recent activity, profile quality; day-seeded randomness).
/// - GET ?q=... → text search.
/// - GET ?gender=... (or other filters) → filtered browse.
class PeopleSearchService {
  /// Search people. Empty q with no filters returns discovery feed; with q (2+ chars) or filters, returns filtered results.
  /// Sort: relevance | newest | last_seen | most_active | friends_count | least_connected |
  ///       least_male_friends | least_female_friends | most_mutual_friends | similar_to_me |
  ///       single_first | same_area_first | most_shared_interests
  Future<PeopleSearchResult> search({
    required int userId,
    String? query,
    int page = 1,
    int perPage = 20,
    String sort = 'relevance',
    String? gender,
    String? relationshipStatus,
    bool? online,
    String? location,
    String? employer,
    String? school,
    String? sector,
    bool? hasPhoto,
    int? ageMin,
    int? ageMax,
    bool? hasBusiness,
    bool? student,
    bool? hasInterests,
    bool? profileComplete,
    bool? friendsOfFriendsOnly,
    bool? verified,
    bool? possibleBusinessConnection,
    bool? possibleEmployer,
    List<String>? sortValues,
  }) async {
    try {
      // Multiple sort/relevance: send comma-separated (e.g. sort=single_first,same_area_first)
      final effectiveSort = (sortValues != null && sortValues.isNotEmpty)
          ? sortValues.join(',')
          : sort;
      final params = <String, String>{
        'user_id': userId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort': effectiveSort,
      };

      final q = query?.trim() ?? '';
      if (q.length >= 2) params['q'] = q;
      if (gender != null && gender.isNotEmpty) params['gender'] = gender;
      if (relationshipStatus != null && relationshipStatus!.isNotEmpty) params['relationship_status'] = relationshipStatus;
      if (online == true) params['online'] = '1';
      if (location != null && location.isNotEmpty) params['location'] = location;
      if (employer != null && employer.isNotEmpty) params['employer'] = employer;
      if (school != null && school.isNotEmpty) params['school'] = school;
      if (sector != null && sector.isNotEmpty) params['sector'] = sector;
      if (hasPhoto == true) params['has_photo'] = '1';
      if (ageMin != null) params['age_min'] = ageMin.toString();
      if (ageMax != null) params['age_max'] = ageMax.toString();
      if (hasBusiness == true) params['has_business'] = '1';
      if (student == true) params['student'] = '1';
      if (hasInterests == true) params['has_interests'] = '1';
      if (profileComplete == true) params['profile_complete'] = '1';
      if (friendsOfFriendsOnly == true) params['friends_of_friends_only'] = '1';
      if (verified == true) params['verified'] = '1';
      if (possibleBusinessConnection == true) params['possible_business_connection'] = '1';
      if (possibleEmployer == true) params['possible_employer'] = '1';

      final uri = Uri.parse('$_baseUrl/people/search').replace(queryParameters: params);
      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final meta = body['meta'] as Map<String, dynamic>? ?? {};
        final list = (body['data'] as List<dynamic>?)
            ?.map((e) => PersonSearchResult.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        return PeopleSearchResult.success(PeopleSearchResponse(
          people: list,
          currentPage: meta['current_page'] as int? ?? 1,
          lastPage: meta['last_page'] as int? ?? 1,
          total: meta['total'] as int? ?? 0,
          perPage: meta['per_page'] as int? ?? 20,
        ));
      }

      final message = body['message'] as String? ?? 'Search failed';
      return PeopleSearchResult.failure(message, response.statusCode);
    } catch (e) {
      return PeopleSearchResult.failure('Error: $e');
    }
  }
}
