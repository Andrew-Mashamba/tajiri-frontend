import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../models/friend_models.dart';
import '../../models/subscription_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL creator subscriptions — tiers, subscribe, tips, earnings (Phase 29).
class GraphqlSubscriptionService {
  static const _tierFields = r'''
    id
    creatorId
    name
    description
    price
    billingPeriod
    benefits
    isActive
    subscriberCount
  ''';

  static const _userFields = r'''
    id
    firstName
    lastName
    username
    profilePhotoUrl
  ''';

  static const _subscriptionFields = '''
    id
    subscriberId
    creatorId
    tierId
    status
    amountPaid
    startedAt
    expiresAt
    cancelledAt
    autoRenew
    tier {
      $_tierFields
    }
    creator {
      $_userFields
    }
    subscriber {
      $_userFields
    }
  ''';

  static const _earningFields = r'''
    id
    creatorId
    type
    grossAmount
    platformFee
    netAmount
    status
    paidAt
    createdAt
  ''';

  static final Map<String, String?> _subscriptionCursors = {};
  static final Map<String, String?> _subscriberCursors = {};
  static final Map<String, String?> _earningCursors = {};
  static final Map<String, String?> _payoutCursors = {};
  static String? _managedSubscriberCursor;
  static String? _managedSubscriberKey;
  static final Map<int, String?> _publicSubscriberCursors = {};

  static Map<String, dynamic> _tierToLegacy(Map<String, dynamic> tier) {
    return {
      'id': int.parse(tier['id'].toString()),
      'creator_id': int.parse(tier['creatorId'].toString()),
      'name': tier['name'],
      'description': tier['description'],
      'price': (tier['price'] as num).toDouble(),
      'billing_period': tier['billingPeriod'],
      'benefits': tier['benefits'],
      'is_active': tier['isActive'] == true,
      'subscriber_count': tier['subscriberCount'] ?? 0,
    };
  }

  static Map<String, dynamic> _userToLegacy(Map<String, dynamic> user) {
    return {
      'id': int.parse(user['id'].toString()),
      'first_name': user['firstName'] ?? '',
      'last_name': user['lastName'] ?? '',
      'username': user['username'],
      'profile_photo_path': user['profilePhotoUrl'],
    };
  }

  static Map<String, dynamic> _subscriptionToLegacy(Map<String, dynamic> sub) {
    return {
      'id': int.parse(sub['id'].toString()),
      'subscriber_id': int.parse(sub['subscriberId'].toString()),
      'creator_id': int.parse(sub['creatorId'].toString()),
      'tier_id': int.parse(sub['tierId'].toString()),
      'status': sub['status'],
      'amount_paid': (sub['amountPaid'] as num).toDouble(),
      'started_at': sub['startedAt'],
      'expires_at': sub['expiresAt'],
      'cancelled_at': sub['cancelledAt'],
      'auto_renew': sub['autoRenew'] == true,
      if (sub['tier'] != null) 'tier': _tierToLegacy(sub['tier'] as Map<String, dynamic>),
      if (sub['creator'] != null)
        'creator': _userToLegacy(sub['creator'] as Map<String, dynamic>),
      if (sub['subscriber'] != null)
        'subscriber': _userToLegacy(sub['subscriber'] as Map<String, dynamic>),
    };
  }

  static Map<String, dynamic> _subscriptionToSubscriberEntry(
    Map<String, dynamic> sub,
  ) {
    final subscriber = sub['subscriber'] as Map<String, dynamic>? ?? {};
    final tier = sub['tier'] as Map<String, dynamic>? ?? {};
    return {
      'subscription_id': int.parse(sub['id'].toString()),
      'id': int.parse(sub['subscriberId'].toString()),
      'first_name': subscriber['firstName'] ?? '',
      'last_name': subscriber['lastName'] ?? '',
      'username': subscriber['username'],
      'profile_photo_url': subscriber['profilePhotoUrl'],
      'status': sub['status'],
      'amount_paid': (sub['amountPaid'] as num).toDouble(),
      'started_at': sub['startedAt'],
      'expires_at': sub['expiresAt'],
      'auto_renew': sub['autoRenew'] == true,
      'tier_name': tier['name'],
      'tier_price': (tier['price'] as num?)?.toDouble(),
      'tier_period': tier['billingPeriod'],
    };
  }

  static Map<String, dynamic> _followUserToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'first_name': row['firstName'] ?? '',
      'last_name': row['lastName'] ?? '',
      'username': row['username'],
      'profile_photo_path': row['profilePhotoUrl'],
      'is_following': row['isFollowing'] == true,
      'is_followed_by': row['isFollowedBy'] == true,
    };
  }

  static Map<String, dynamic> _earningToLegacy(Map<String, dynamic> earning) {
    return {
      'id': int.parse(earning['id'].toString()),
      'creator_id': int.parse(earning['creatorId'].toString()),
      'type': earning['type'],
      'gross_amount': (earning['grossAmount'] as num).toDouble(),
      'platform_fee': (earning['platformFee'] as num).toDouble(),
      'net_amount': (earning['netAmount'] as num).toDouble(),
      'status': earning['status'],
      'paid_at': earning['paidAt'],
      'created_at': earning['createdAt'],
    };
  }

  static Map<String, dynamic> _payoutToLegacy(Map<String, dynamic> payout) {
    return {
      'id': int.parse(payout['id'].toString()),
      'creator_id': int.parse(payout['creatorId'].toString()),
      'amount': (payout['amount'] as num).toDouble(),
      'payment_method': payout['paymentMethod'],
      'account_number': payout['accountNumber'],
      'account_name': payout['accountName'],
      'provider': payout['provider'],
      'status': payout['status'],
      'transaction_id': payout['transactionId'],
      'failure_reason': payout['failureReason'],
      'processed_at': payout['processedAt'],
      'created_at': payout['createdAt'],
    };
  }

  static const _payoutFields = r'''
    id
    creatorId
    amount
    paymentMethod
    accountNumber
    accountName
    provider
    status
    transactionId
    failureReason
    processedAt
    createdAt
  ''';

  static Future<TierListResult> getCreatorTiers(int creatorId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorSubscriptionTiers(\$creatorId: ID!) {
          creatorSubscriptionTiers(creatorId: \$creatorId) {
            $_tierFields
          }
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
      );
      final tiers = (data['creatorSubscriptionTiers'] as List? ?? [])
          .map((t) => SubscriptionTier.fromJson(_tierToLegacy(t as Map<String, dynamic>)))
          .toList();
      return TierListResult(success: true, tiers: tiers);
    } catch (e) {
      return TierListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<TierResult> createTier({
    required int userId,
    required String name,
    String? description,
    required double price,
    String billingPeriod = 'monthly',
    List<String>? benefits,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateSubscriptionTier(\$input: CreateSubscriptionTierInput!) {
          createSubscriptionTier(input: \$input) {
            $_tierFields
          }
        }
        ''',
        variables: {
          'input': {
            'name': name,
            if (description != null) 'description': description,
            'price': price,
            'billingPeriod': billingPeriod,
            if (benefits != null) 'benefits': benefits,
          },
        },
        auth: true,
      );
      final tier = data['createSubscriptionTier'] as Map<String, dynamic>? ?? {};
      return TierResult(
        success: true,
        tier: SubscriptionTier.fromJson(_tierToLegacy(tier)),
      );
    } catch (e) {
      return TierResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<TierResult> updateTier({
    required int userId,
    required int tierId,
    String? name,
    String? description,
    double? price,
    List<String>? benefits,
    bool? isActive,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateSubscriptionTier(\$tierId: ID!, \$input: UpdateSubscriptionTierInput!) {
          updateSubscriptionTier(tierId: \$tierId, input: \$input) {
            $_tierFields
          }
        }
        ''',
        variables: {
          'tierId': tierId.toString(),
          'input': {
            if (name != null) 'name': name,
            if (description != null) 'description': description,
            if (price != null) 'price': price,
            if (benefits != null) 'benefits': benefits,
            if (isActive != null) 'isActive': isActive,
          },
        },
        auth: true,
      );
      final tier = data['updateSubscriptionTier'] as Map<String, dynamic>? ?? {};
      return TierResult(
        success: true,
        tier: SubscriptionTier.fromJson(_tierToLegacy(tier)),
      );
    } catch (e) {
      return TierResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> deleteTier({
    required int userId,
    required int tierId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteSubscriptionTier(\$tierId: ID!) {
          deleteSubscriptionTier(tierId: \$tierId)
        }
        ''',
        variables: {'tierId': tierId.toString()},
        auth: true,
      );
      return data['deleteSubscriptionTier'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<SubscriptionResult> subscribe({
    required int userId,
    required int tierId,
    required String paymentMethod,
    String? provider,
    String? phoneNumber,
    String? pin,
    int? originPostId,
    int? originStreamId,
    String? shareUid,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubscribeToCreator(\$input: SubscribeToCreatorInput!) {
          subscribeToCreator(input: \$input) {
            $_subscriptionFields
          }
        }
        ''',
        variables: {
          'input': {
            'tierId': tierId.toString(),
            'paymentMethod': paymentMethod,
            if (pin != null) 'pin': pin,
            if (originPostId != null) 'originPostId': originPostId.toString(),
            if (originStreamId != null) 'originStreamId': originStreamId.toString(),
            if (shareUid != null && shareUid.isNotEmpty) 'shareUid': shareUid,
          },
        },
        auth: true,
      );
      final sub = data['subscribeToCreator'] as Map<String, dynamic>? ?? {};
      return SubscriptionResult(
        success: true,
        subscription: Subscription.fromJson(_subscriptionToLegacy(sub)),
      );
    } catch (e) {
      return SubscriptionResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<SubscriptionResult> cancelSubscription({
    required int userId,
    required int subscriptionId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelCreatorSubscription(\$subscriptionId: ID!) {
          cancelCreatorSubscription(subscriptionId: \$subscriptionId) {
            $_subscriptionFields
          }
        }
        ''',
        variables: {'subscriptionId': subscriptionId.toString()},
        auth: true,
      );
      final sub = data['cancelCreatorSubscription'] as Map<String, dynamic>? ?? {};
      return SubscriptionResult(
        success: true,
        subscription: Subscription.fromJson(_subscriptionToLegacy(sub)),
      );
    } catch (e) {
      return SubscriptionResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<SubscriptionResult> toggleAutoRenew({
    required int userId,
    required int subscriptionId,
    required bool autoRenew,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SetCreatorSubscriptionAutoRenew(\$subscriptionId: ID!, \$autoRenew: Boolean!) {
          setCreatorSubscriptionAutoRenew(subscriptionId: \$subscriptionId, autoRenew: \$autoRenew) {
            $_subscriptionFields
          }
        }
        ''',
        variables: {
          'subscriptionId': subscriptionId.toString(),
          'autoRenew': autoRenew,
        },
        auth: true,
      );
      final sub = data['setCreatorSubscriptionAutoRenew'] as Map<String, dynamic>? ?? {};
      return SubscriptionResult(
        success: true,
        subscription: Subscription.fromJson(_subscriptionToLegacy(sub)),
      );
    } catch (e) {
      return SubscriptionResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<SubscriptionListResult> getMySubscriptions({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final cacheKey = 'my:$userId:${status ?? 'all'}';
      final cursor = page <= 1 ? null : _subscriptionCursors[cacheKey];
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyCreatorSubscriptions(\$status: String, \$cursor: String) {
          myCreatorSubscriptions(status: \$status, cursor: \$cursor) {
            items {
              $_subscriptionFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (status != null) 'status': status,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final pageData = data['myCreatorSubscriptions'] as Map<String, dynamic>? ?? {};
      final items = (pageData['items'] as List? ?? [])
          .map((s) => Subscription.fromJson(_subscriptionToLegacy(s as Map<String, dynamic>)))
          .toList();
      _subscriptionCursors[cacheKey] = pageData['nextCursor']?.toString();
      return SubscriptionListResult(success: true, subscriptions: items);
    } catch (e) {
      return SubscriptionListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<SubscriptionListResult> getSubscribers({
    required int userId,
    int page = 1,
    int perPage = 20,
    int? tierId,
  }) async {
    try {
      final cacheKey = 'subs:$userId:${tierId ?? 'all'}';
      final cursor = page <= 1 ? null : _subscriberCursors[cacheKey];
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyCreatorSubscribers(\$tierId: ID, \$cursor: String) {
          myCreatorSubscribers(tierId: \$tierId, cursor: \$cursor) {
            items {
              $_subscriptionFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (tierId != null) 'tierId': tierId.toString(),
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final pageData = data['myCreatorSubscribers'] as Map<String, dynamic>? ?? {};
      final items = (pageData['items'] as List? ?? [])
          .map((s) => Subscription.fromJson(_subscriptionToLegacy(s as Map<String, dynamic>)))
          .toList();
      _subscriberCursors[cacheKey] = pageData['nextCursor']?.toString();
      return SubscriptionListResult(success: true, subscriptions: items);
    } catch (e) {
      return SubscriptionListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<SubscriberListResult> getManagedSubscribers({
    int page = 1,
    int perPage = 30,
    String? q,
    String? filter,
    String? sort,
  }) async {
    try {
      final key = '${q ?? ''}|${filter ?? ''}|${sort ?? ''}|$perPage';
      if (page == 1) {
        _managedSubscriberCursor = null;
        _managedSubscriberKey = key;
      } else if (_managedSubscriberKey != key) {
        return const SubscriberListResult(
          success: false,
          message: 'Filter changed — restart from page 1',
        );
      }
      final data = await TajiriGraphqlClient.instance.query(
        r'''
        query ManagedCreatorSubscribers($q: String, $filter: String, $sort: String, $cursor: String, $limit: Int!) {
          managedCreatorSubscribers(q: $q, filter: $filter, sort: $sort, cursor: $cursor, limit: $limit) {
            totalCount
            hasMore
            nextCursor
            items {
              $_subscriptionFields
            }
          }
        }
        ''',
        variables: {
          'limit': perPage,
          if (q != null && q.isNotEmpty) 'q': q,
          if (filter != null) 'filter': filter,
          if (sort != null) 'sort': sort,
          if (page > 1 && _managedSubscriberCursor != null)
            'cursor': _managedSubscriberCursor,
        },
        auth: true,
      );
      final conn =
          data['managedCreatorSubscribers'] as Map<String, dynamic>? ?? {};
      final entries = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) =>
              SubscriberEntry.fromJson(_subscriptionToSubscriberEntry(row)))
          .toList();
      _managedSubscriberCursor = conn['nextCursor']?.toString();
      return SubscriberListResult(
        success: true,
        entries: entries,
        totalCount: (conn['totalCount'] as num?)?.toInt() ?? entries.length,
      );
    } catch (e) {
      return SubscriberListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<SubscriberInsights?> getSubscriberInsights() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        r'''
        query SubscriberListInsights {
          subscriberListInsights {
            totalActive
            newThisMonth
            expiringSoon
            churned
            mrrTzs
          }
        }
        ''',
        auth: true,
      );
      final row = data['subscriberListInsights'] as Map<String, dynamic>?;
      if (row == null) return null;
      return SubscriberInsights.fromJson({
        'total_active': row['totalActive'],
        'new_this_month': row['newThisMonth'],
        'expiring_soon': row['expiringSoon'],
        'churned': row['churned'],
        'mrr_tzs': row['mrrTzs'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<bool> revokeSubscriber(int subscriptionId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation RevokeCreatorSubscriber($subscriptionId: ID!) {
          revokeCreatorSubscriber(subscriptionId: $subscriptionId)
        }
        ''',
        variables: {'subscriptionId': subscriptionId.toString()},
        auth: true,
      );
      return data['revokeCreatorSubscriber'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> bulkRevokeSubscribers(List<int> subscriptionIds) async {
    if (subscriptionIds.isEmpty) return 0;
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation BulkRevokeCreatorSubscribers($subscriptionIds: [ID!]!) {
          bulkRevokeCreatorSubscribers(subscriptionIds: $subscriptionIds)
        }
        ''',
        variables: {
          'subscriptionIds':
              subscriptionIds.map((id) => id.toString()).toList(),
        },
        auth: true,
      );
      return (data['bulkRevokeCreatorSubscribers'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<String?> exportSubscribersCsv({
    String? q,
    String? filter,
    String? sort,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        r'''
        query SubscriberListExportCsv($q: String, $filter: String, $sort: String) {
          subscriberListExportCsv(q: $q, filter: $filter, sort: $sort)
        }
        ''',
        variables: {
          if (q != null) 'q': q,
          if (filter != null) 'filter': filter,
          if (sort != null) 'sort': sort,
        },
        auth: true,
      );
      final csv = data['subscriberListExportCsv'] as String?;
      if (csv == null || csv.isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final path = '${dir.path}${Platform.pathSeparator}subscribers-$today.csv';
      await File(path).writeAsString(csv);
      return path;
    } catch (_) {
      return null;
    }
  }

  static Future<
      ({
        bool success,
        List<FollowUser> users,
        int currentPage,
        int lastPage,
        String? message,
      })> getPublicSubscribers({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      if (page == 1) _publicSubscriberCursors.remove(userId);
      final cursor = page > 1 ? _publicSubscriberCursors[userId] : null;
      if (page > 1 && cursor == null) {
        return (
          success: true,
          users: <FollowUser>[],
          currentPage: page,
          lastPage: page,
          message: null,
        );
      }
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query UserSubscribers(\$userId: ID!, \$cursor: String, \$limit: Int!) {
          userSubscribers(userId: \$userId, cursor: \$cursor, limit: \$limit) {
            items {
              id
              firstName
              lastName
              username
              profilePhotoUrl
              isFollowing
              isFollowedBy
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'userId': userId.toString(),
          'limit': perPage,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['userSubscribers'] as Map<String, dynamic>? ?? {};
      final users = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => FollowUser.fromJson(_followUserToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      _publicSubscriberCursors[userId] = conn['nextCursor']?.toString();
      final lastPage = hasMore ? page + 1 : page;
      return (
        success: true,
        users: users,
        currentPage: page,
        lastPage: lastPage,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        users: <FollowUser>[],
        currentPage: page,
        lastPage: page,
        message: 'Kosa: $e',
      );
    }
  }

  static Future<TipResult> sendTip({
    required int userId,
    required int creatorId,
    required double amount,
    String? message,
    required String paymentMethod,
    String? provider,
    String? phoneNumber,
    String? pin,
    int? streamId,
    int? postId,
    String? idempotencyKey,
  }) async {
    try {
      final key = idempotencyKey ??
          'tip_${userId}_${creatorId}_${DateTime.now().microsecondsSinceEpoch}';
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SendCreatorTip(\$input: SendCreatorTipInput!) {
          sendCreatorTip(input: \$input) {
            success
            message
            id
            idempotentReplay
          }
        }
        ''',
        variables: {
          'input': {
            'creatorId': creatorId.toString(),
            'amount': amount,
            'paymentMethod': paymentMethod,
            if (pin != null) 'pin': pin,
            'idempotencyKey': key,
            if (postId != null) 'postId': postId.toString(),
            if (streamId != null) 'streamId': streamId.toString(),
          },
        },
        auth: true,
      );
      final result = data['sendCreatorTip'] as Map<String, dynamic>? ?? {};
      return TipResult(
        success: result['success'] == true,
        message: result['message']?.toString(),
        idempotentReplay: result['idempotentReplay'] == true,
      );
    } catch (e) {
      return TipResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EarningsListResult> getEarnings({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? type,
    String? status,
  }) async {
    try {
      final cacheKey = 'earn:$userId:${type ?? 'all'}:${status ?? 'all'}';
      final cursor = page <= 1 ? null : _earningCursors[cacheKey];
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorEarnings(\$type: String, \$status: String, \$cursor: String) {
          creatorEarnings(type: \$type, status: \$status, cursor: \$cursor) {
            items {
              $_earningFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (type != null) 'type': type,
          if (status != null) 'status': status,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final pageData = data['creatorEarnings'] as Map<String, dynamic>? ?? {};
      final items = (pageData['items'] as List? ?? [])
          .map((e) => CreatorEarning.fromJson(_earningToLegacy(e as Map<String, dynamic>)))
          .toList();
      _earningCursors[cacheKey] = pageData['nextCursor']?.toString();
      return EarningsListResult(success: true, earnings: items);
    } catch (e) {
      return EarningsListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EarningsSummaryResult> getEarningsSummary(int userId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorEarningsSummary {
          creatorEarningsSummary {
            totalGross
            totalNet
            pending
            thisMonth
          }
        }
        ''',
        auth: true,
      );
      final summary = data['creatorEarningsSummary'] as Map<String, dynamic>? ?? {};
      return EarningsSummaryResult(
        success: true,
        summary: EarningsSummary.fromJson({
          'total_gross': summary['totalGross'],
          'total_net': summary['totalNet'],
          'pending': summary['pending'],
          'this_month': summary['thisMonth'],
        }),
      );
    } catch (e) {
      return EarningsSummaryResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> isSubscribed({
    required int userId,
    required int creatorId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query IsSubscribedToCreator(\$creatorId: ID!) {
          isSubscribedToCreator(creatorId: \$creatorId)
        }
        ''',
        variables: {'creatorId': creatorId.toString()},
        auth: true,
      );
      return data['isSubscribedToCreator'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<PayoutResult> requestPayout({
    required int userId,
    required double amount,
    required String paymentMethod,
    required String accountNumber,
    required String accountName,
    String? provider,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RequestCreatorPayout(\$input: RequestCreatorPayoutInput!) {
          requestCreatorPayout(input: \$input) {
            $_payoutFields
          }
        }
        ''',
        variables: {
          'input': {
            'amount': amount,
            'paymentMethod': paymentMethod,
            'accountNumber': accountNumber,
            'accountName': accountName,
            if (provider != null) 'provider': provider,
          },
        },
        auth: true,
      );
      final payout = data['requestCreatorPayout'] as Map<String, dynamic>? ?? {};
      return PayoutResult(
        success: true,
        payout: CreatorPayout.fromJson(_payoutToLegacy(payout)),
      );
    } catch (e) {
      return PayoutResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PayoutListResult> getPayouts({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final cacheKey = 'payout:$userId:${status ?? 'all'}';
      final cursor = page <= 1 ? null : _payoutCursors[cacheKey];
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CreatorPayouts(\$status: String, \$cursor: String) {
          creatorPayouts(status: \$status, cursor: \$cursor) {
            items {
              $_payoutFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (status != null) 'status': status,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final pageData = data['creatorPayouts'] as Map<String, dynamic>? ?? {};
      final items = (pageData['items'] as List? ?? [])
          .map((p) => CreatorPayout.fromJson(_payoutToLegacy(p as Map<String, dynamic>)))
          .toList();
      _payoutCursors[cacheKey] = pageData['nextCursor']?.toString();
      return PayoutListResult(success: true, payouts: items);
    } catch (e) {
      return PayoutListResult(success: false, message: 'Kosa: $e');
    }
  }
}
