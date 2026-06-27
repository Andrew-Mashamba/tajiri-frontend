import '../../models/page_models.dart';
import '../../models/post_models.dart';
import 'graphql_post_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL creator/business pages marketplace (Phase 43).
class GraphqlPageService {
  static const _pageFields = r'''
    id
    name
    slug
    category
    subcategory
    description
    profilePhotoPath
    profilePhotoUrl
    coverPhotoPath
    coverPhotoUrl
    website
    phone
    email
    address
    latitude
    longitude
    hours
    socialLinks
    creatorId
    likesCount
    followersCount
    postsCount
    isVerified
    createdAt
    isFollowing
    isLiked
    userRole
    canManage
    averageRating
    reviewsCount
    creator {
      id
      firstName
      lastName
      username
      profilePhotoPath
      profilePhotoUrl
    }
  ''';

  static Map<String, dynamic> _creatorToLegacy(Map<String, dynamic>? row) {
    if (row == null) return {};
    return {
      'id': int.parse(row['id'].toString()),
      'first_name': row['firstName'],
      'last_name': row['lastName'],
      'username': row['username'],
      'profile_photo_path': row['profilePhotoPath'],
    };
  }

  static Map<String, dynamic> _pageToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'slug': row['slug'],
      'category': row['category'],
      'subcategory': row['subcategory'],
      'description': row['description'],
      'profile_photo_path': row['profilePhotoPath'],
      'profile_photo_url': row['profilePhotoUrl'],
      'cover_photo_path': row['coverPhotoPath'],
      'cover_photo_url': row['coverPhotoUrl'],
      'website': row['website'],
      'phone': row['phone'],
      'email': row['email'],
      'address': row['address'],
      'latitude': row['latitude'],
      'longitude': row['longitude'],
      'hours': row['hours'],
      'social_links': row['socialLinks'],
      'creator_id': int.parse(row['creatorId'].toString()),
      'likes_count': row['likesCount'],
      'followers_count': row['followersCount'],
      'posts_count': row['postsCount'],
      'is_verified': row['isVerified'],
      'created_at': row['createdAt'],
      'is_following': row['isFollowing'],
      'is_liked': row['isLiked'],
      'user_role': row['userRole'],
      'can_manage': row['canManage'],
      'average_rating': row['averageRating'],
      'reviews_count': row['reviewsCount'],
      'creator': row['creator'] != null
          ? _creatorToLegacy(row['creator'] as Map<String, dynamic>)
          : null,
    };
  }

  static PageModel _parsePage(Map<String, dynamic> row) {
    return PageModel.fromJson(_pageToLegacy(row));
  }

  static Future<List<PageModel>> getPages({
    int page = 1,
    int perPage = 20,
    String? category,
    String? search,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query Pages(\$page: Int, \$perPage: Int, \$category: String, \$search: String) {
          pages(page: \$page, perPage: \$perPage, category: \$category, search: \$search) {
            $_pageFields
          }
        }
        ''',
        variables: {
          'page': page,
          'perPage': perPage,
          'category': category,
          'search': search,
        },
        auth: false,
      );
      final rows = data['pages'] as List<dynamic>? ?? [];
      return rows.map((row) => _parsePage(row as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<PageCategory>> getCategories() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PageCategories {
          pageCategories {
            value
            label
          }
        }
        ''',
        auth: false,
      );
      final rows = data['pageCategories'] as List<dynamic>? ?? [];
      return rows
          .map((row) => PageCategory.fromJson({
                'value': (row as Map<String, dynamic>)['value'],
                'label': row['label'],
              }))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<PageModel>> getUserPages() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyPages {
          myPages {
            $_pageFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myPages'] as List<dynamic>? ?? [];
      return rows.map((row) => _parsePage(row as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<PageModel>> getLikedPages() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyLikedPages {
          myLikedPages {
            $_pageFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myLikedPages'] as List<dynamic>? ?? [];
      return rows.map((row) => _parsePage(row as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<PageModel?> getPage(String identifier) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query Page(\$identifier: String!) {
          page(identifier: \$identifier) {
            $_pageFields
          }
        }
        ''',
        variables: {'identifier': identifier},
        auth: false,
      );
      final row = data['page'] as Map<String, dynamic>?;
      if (row == null) return null;
      return _parsePage(row);
    } catch (_) {
      return null;
    }
  }

  static Future<PageModel?> createPage({
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
    String? profilePhotoPath,
    String? coverPhotoPath,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreatePage(\$input: CreatePageInput!) {
          createPage(input: \$input) {
            $_pageFields
          }
        }
        ''',
        variables: {
          'input': {
            'name': name,
            'category': category,
            if (subcategory != null) 'subcategory': subcategory,
            if (description != null) 'description': description,
            if (profilePhotoPath != null) 'profilePhotoPath': profilePhotoPath,
            if (coverPhotoPath != null) 'coverPhotoPath': coverPhotoPath,
            if (website != null) 'website': website,
            if (phone != null) 'phone': phone,
            if (email != null) 'email': email,
            if (address != null) 'address': address,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          },
        },
        auth: true,
      );
      final row = result['createPage'] as Map<String, dynamic>?;
      if (row == null) return null;
      return _parsePage(row);
    } catch (_) {
      return null;
    }
  }

  static Future<int?> followPage(int pageId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation FollowPage(\$pageId: ID!) {
          followPage(pageId: \$pageId) {
            followersCount
          }
        }
        ''',
        variables: {'pageId': pageId.toString()},
        auth: true,
      );
      final row = result['followPage'] as Map<String, dynamic>?;
      return (row?['followersCount'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  static Future<int?> unfollowPage(int pageId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UnfollowPage(\$pageId: ID!) {
          unfollowPage(pageId: \$pageId) {
            followersCount
          }
        }
        ''',
        variables: {'pageId': pageId.toString()},
        auth: true,
      );
      final row = result['unfollowPage'] as Map<String, dynamic>?;
      return (row?['followersCount'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  static Future<int?> likePage(int pageId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation LikePage(\$pageId: ID!) {
          likePage(pageId: \$pageId) {
            likesCount
          }
        }
        ''',
        variables: {'pageId': pageId.toString()},
        auth: true,
      );
      final row = result['likePage'] as Map<String, dynamic>?;
      return (row?['likesCount'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  static Future<int?> unlikePage(int pageId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UnlikePage(\$pageId: ID!) {
          unlikePage(pageId: \$pageId) {
            likesCount
          }
        }
        ''',
        variables: {'pageId': pageId.toString()},
        auth: true,
      );
      final row = result['unlikePage'] as Map<String, dynamic>?;
      return (row?['likesCount'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  static Future<({List<PageReview> reviews, double? averageRating})?> getReviews(
    int pageId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PageReviews(\$pageId: ID!, \$page: Int, \$perPage: Int) {
          pageReviews(pageId: \$pageId, page: \$page, perPage: \$perPage) {
            averageRating
            items {
              id
              pageId
              userId
              rating
              content
              createdAt
              user {
                id
                firstName
                lastName
                username
                profilePhotoPath
              }
            }
          }
        }
        ''',
        variables: {
          'pageId': pageId.toString(),
          'page': page,
          'perPage': perPage,
        },
        auth: false,
      );
      final conn = data['pageReviews'] as Map<String, dynamic>?;
      if (conn == null) return null;
      final items = conn['items'] as List<dynamic>? ?? [];
      final reviews = items.map((row) {
        final r = row as Map<String, dynamic>;
        return PageReview.fromJson({
          'id': int.parse(r['id'].toString()),
          'page_id': int.parse(r['pageId'].toString()),
          'user_id': int.parse(r['userId'].toString()),
          'rating': r['rating'],
          'content': r['content'],
          'created_at': r['createdAt'],
          'user': r['user'] != null
              ? _creatorToLegacy(r['user'] as Map<String, dynamic>)
              : null,
        });
      }).toList();
      return (
        reviews: reviews,
        averageRating: (conn['averageRating'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static const _postFields = r'''
    id
    caption
    publishedAt
    author {
      id
      username
      displayName
      avatarUrl
    }
    media {
      type
      url
      thumbnailUrl
      blurhash
      width
      height
    }
    counts {
      likes
      comments
      saves
      views
    }
    viewerState {
      liked
      saved
      subscribed
    }
  ''';

  static Future<List<Post>> getPagePosts(
    int pageId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PagePosts(\$pageId: ID!, \$page: Int, \$perPage: Int) {
          pagePosts(pageId: \$pageId, page: \$page, perPage: \$perPage) {
            $_postFields
          }
        }
        ''',
        variables: {
          'pageId': pageId.toString(),
          'page': page,
          'perPage': perPage,
        },
        auth: false,
      );
      final rows = data['pagePosts'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(GraphqlPostMapper.fromGraphql)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<PageReview?> addReview(
    int pageId,
    int rating, {
    String? content,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddPageReview(\$pageId: ID!, \$rating: Int!, \$content: String) {
          addPageReview(pageId: \$pageId, rating: \$rating, content: \$content) {
            id
            pageId
            userId
            rating
            content
            createdAt
            user {
              id
              firstName
              lastName
              username
              profilePhotoPath
            }
          }
        }
        ''',
        variables: {
          'pageId': pageId.toString(),
          'rating': rating,
          if (content != null) 'content': content,
        },
        auth: true,
      );
      final row = result['addPageReview'] as Map<String, dynamic>?;
      if (row == null) return null;
      return PageReview.fromJson({
        'id': int.parse(row['id'].toString()),
        'page_id': int.parse(row['pageId'].toString()),
        'user_id': int.parse(row['userId'].toString()),
        'rating': row['rating'],
        'content': row['content'],
        'created_at': row['createdAt'],
        'user': row['user'] != null
            ? _creatorToLegacy(row['user'] as Map<String, dynamic>)
            : null,
      });
    } catch (_) {
      return null;
    }
  }

  static Future<List<PageModel>> searchPages(String query) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query SearchPages(\$q: String!) {
          searchPages(q: \$q) {
            $_pageFields
          }
        }
        ''',
        variables: {'q': query},
        auth: false,
      );
      final rows = data['searchPages'] as List<dynamic>? ?? [];
      return rows.map((row) => _parsePage(row as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
