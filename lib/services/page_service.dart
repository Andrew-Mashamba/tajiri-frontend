import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/page_models.dart';
import '../models/post_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class PageService {
  /// Get list of pages
  Future<PageListResult> getPages({
    int page = 1,
    int perPage = 20,
    String? category,
    String? search,
    int? currentUserId,
  }) async {
    try {
      String url = '$_baseUrl/pages?page=$page&per_page=$perPage';
      if (category != null) url += '&category=$category';
      if (search != null) url += '&search=$search';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final pages = (data['data'] as List)
              .map((p) => PageModel.fromJson(p))
              .toList();
          return PageListResult(success: true, pages: pages);
        }
      }
      return PageListResult(success: false, message: 'Failed to load pages');
    } catch (e) {
      return PageListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get page categories
  Future<List<PageCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pages/categories'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((c) => PageCategory.fromJson(c))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get user's managed pages
  Future<PageListResult> getUserPages(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pages/user?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final pages = (data['data'] as List)
              .map((p) => PageModel.fromJson(p))
              .toList();
          return PageListResult(success: true, pages: pages);
        }
      }
      return PageListResult(success: false, message: 'Failed to load pages');
    } catch (e) {
      return PageListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get pages liked by user
  Future<PageListResult> getLikedPages(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pages/liked?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final pages = (data['data'] as List)
              .map((p) => PageModel.fromJson(p))
              .toList();
          return PageListResult(success: true, pages: pages);
        }
      }
      return PageListResult(success: false, message: 'Failed to load pages');
    } catch (e) {
      return PageListResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a new page
  Future<PageResult> createPage({
    required int creatorId,
    required String name,
    required String category,
    String? subcategory,
    String? description,
    String? website,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    File? profilePhoto,
    File? coverPhoto,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/pages'));
      request.fields['creator_id'] = creatorId.toString();
      request.fields['name'] = name;
      request.fields['category'] = category;
      if (subcategory != null) request.fields['subcategory'] = subcategory;
      if (description != null) request.fields['description'] = description;
      if (website != null) request.fields['website'] = website;
      if (phone != null) request.fields['phone'] = phone;
      if (email != null) request.fields['email'] = email;
      if (address != null) request.fields['address'] = address;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();

      if (profilePhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('profile_photo', profilePhoto.path));
      }
      if (coverPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_photo', coverPhoto.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return PageResult(
          success: true,
          page: PageModel.fromJson(data['data']),
          message: data['message'],
        );
      }
      return PageResult(success: false, message: data['message'] ?? 'Failed to create page');
    } catch (e) {
      return PageResult(success: false, message: 'Error: $e');
    }
  }

  /// Get a single page
  Future<PageResult> getPage(String identifier, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/pages/$identifier';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return PageResult(success: true, page: PageModel.fromJson(data['data']));
        }
      }
      return PageResult(success: false, message: 'Page not found');
    } catch (e) {
      return PageResult(success: false, message: 'Error: $e');
    }
  }

  /// Follow a page
  Future<FollowResult> followPage(int pageId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pages/$pageId/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return FollowResult(
          success: true,
          followersCount: data['data']?['followers_count'],
        );
      }
      return FollowResult(success: false, message: data['message']);
    } catch (e) {
      return FollowResult(success: false, message: 'Error: $e');
    }
  }

  /// Unfollow a page
  Future<FollowResult> unfollowPage(int pageId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/pages/$pageId/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return FollowResult(
          success: true,
          followersCount: data['data']?['followers_count'],
        );
      }
      return FollowResult(success: false, message: data['message']);
    } catch (e) {
      return FollowResult(success: false, message: 'Error: $e');
    }
  }

  /// Like a page
  Future<LikeResult> likePage(int pageId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pages/$pageId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return LikeResult(
          success: true,
          likesCount: data['data']?['likes_count'],
        );
      }
      return LikeResult(success: false, message: data['message']);
    } catch (e) {
      return LikeResult(success: false, message: 'Error: $e');
    }
  }

  /// Unlike a page
  Future<LikeResult> unlikePage(int pageId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/pages/$pageId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return LikeResult(
          success: true,
          likesCount: data['data']?['likes_count'],
        );
      }
      return LikeResult(success: false, message: data['message']);
    } catch (e) {
      return LikeResult(success: false, message: 'Error: $e');
    }
  }

  /// Get page posts
  Future<PostListResult> getPagePosts(int pageId, {int page = 1, int perPage = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pages/$pageId/posts?page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final posts = (data['data'] as List)
              .map((p) => Post.fromJson(p))
              .toList();
          return PostListResult(success: true, posts: posts);
        }
      }
      return PostListResult(success: false, message: 'Failed to load posts');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get page reviews
  Future<ReviewListResult> getReviews(int pageId, {int page = 1, int perPage = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pages/$pageId/reviews?page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final reviews = (data['data'] as List)
              .map((r) => PageReview.fromJson(r))
              .toList();
          return ReviewListResult(
            success: true,
            reviews: reviews,
            averageRating: data['meta']?['average_rating']?.toDouble(),
          );
        }
      }
      return ReviewListResult(success: false, message: 'Failed to load reviews');
    } catch (e) {
      return ReviewListResult(success: false, message: 'Error: $e');
    }
  }

  /// Add a review
  Future<ReviewResult> addReview(int pageId, int userId, int rating, {String? content}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pages/$pageId/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'rating': rating,
          'content': content,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ReviewResult(
          success: true,
          review: PageReview.fromJson(data['data']),
        );
      }
      return ReviewResult(success: false, message: data['message']);
    } catch (e) {
      return ReviewResult(success: false, message: 'Error: $e');
    }
  }

  /// Search pages
  Future<PageListResult> searchPages(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pages/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final pages = (data['data'] as List)
              .map((p) => PageModel.fromJson(p))
              .toList();
          return PageListResult(success: true, pages: pages);
        }
      }
      return PageListResult(success: false, message: 'Search failed');
    } catch (e) {
      return PageListResult(success: false, message: 'Error: $e');
    }
  }
}

// Result classes
class PageListResult {
  final bool success;
  final List<PageModel> pages;
  final String? message;

  PageListResult({required this.success, this.pages = const [], this.message});
}

class PageResult {
  final bool success;
  final PageModel? page;
  final String? message;

  PageResult({required this.success, this.page, this.message});
}

class FollowResult {
  final bool success;
  final int? followersCount;
  final String? message;

  FollowResult({required this.success, this.followersCount, this.message});
}

class LikeResult {
  final bool success;
  final int? likesCount;
  final String? message;

  LikeResult({required this.success, this.likesCount, this.message});
}

class PostListResult {
  final bool success;
  final List<Post> posts;
  final String? message;

  PostListResult({required this.success, this.posts = const [], this.message});
}

class ReviewListResult {
  final bool success;
  final List<PageReview> reviews;
  final double? averageRating;
  final String? message;

  ReviewListResult({required this.success, this.reviews = const [], this.averageRating, this.message});
}

class ReviewResult {
  final bool success;
  final PageReview? review;
  final String? message;

  ReviewResult({required this.success, this.review, this.message});
}
