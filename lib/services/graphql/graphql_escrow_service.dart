import '../../shop/escrow/models/escrow_models.dart';
import 'graphql_escrow_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL shop escrow — holds, disputes, wallet summary (Phase 17).
class GraphqlEscrowService {
  static const _escrowInfoFields = r'''
    escrowStatus
    escrowHeldAt
    escrowAutoReleaseAt
    escrowReleasedAt
    dispute {
      id
      orderId
      raisedBy
      reason
      description
      evidenceUrls
      status
      resolutionNotes
      sellerResponse
      sellerRespondedAt
      adminNotes
      priority
      createdAt
      resolvedAt
    }
  ''';

  static const _disputeFields = r'''
    id
    orderId
    raisedBy
    reason
    description
    evidenceUrls
    status
    resolutionNotes
    sellerResponse
    sellerRespondedAt
    adminNotes
    priority
    createdAt
    resolvedAt
  ''';

  static const _orderEscrowQuery = '''
    query ShopOrderEscrow(\$orderId: ID!) {
      shopOrderEscrow(orderId: \$orderId) {
        $_escrowInfoFields
      }
    }
  ''';

  static const _disputeQuery = '''
    query ShopEscrowDispute(\$orderId: ID!) {
      shopEscrowDispute(orderId: \$orderId) {
        $_disputeFields
      }
    }
  ''';

  static const _disputesQuery = '''
    query ShopEscrowDisputes(\$status: String) {
      shopEscrowDisputes(status: \$status) {
        $_disputeFields
      }
    }
  ''';

  static const _walletSummaryQuery = r'''
    query ShopEscrowWalletSummary {
      shopEscrowWalletSummary {
        heldAmount
        pendingReleaseCount
      }
    }
  ''';

  static const _releaseMutation = '''
    mutation ReleaseShopEscrow(\$orderId: ID!) {
      releaseShopEscrow(orderId: \$orderId) {
        $_escrowInfoFields
      }
    }
  ''';

  static const _raiseDisputeMutation = '''
    mutation RaiseShopEscrowDispute(\$orderId: ID!, \$input: RaiseShopEscrowDisputeInput!) {
      raiseShopEscrowDispute(orderId: \$orderId, input: \$input) {
        $_disputeFields
      }
    }
  ''';

  static const _respondMutation = '''
    mutation RespondShopEscrowDispute(\$orderId: ID!, \$response: String!) {
      respondShopEscrowDispute(orderId: \$orderId, response: \$response) {
        $_disputeFields
      }
    }
  ''';

  static Future<EscrowInfo?> getOrderEscrow(int orderId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _orderEscrowQuery,
        variables: {'orderId': orderId.toString()},
        auth: true,
      );
      final gql = data['shopOrderEscrow'] as Map<String, dynamic>?;
      if (gql == null) return null;
      return GraphqlEscrowMapper.escrowInfoFromGraphql(gql);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> releaseEscrow(int orderId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _releaseMutation,
        variables: {'orderId': orderId.toString()},
        auth: true,
      );
      return data['releaseShopEscrow'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> raiseDispute(
    int orderId, {
    required String reason,
    String? description,
    List<String> evidenceUrls = const [],
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _raiseDisputeMutation,
        variables: {
          'orderId': orderId.toString(),
          'input': {
            'reason': reason,
            if (description != null && description.isNotEmpty) 'description': description,
            if (evidenceUrls.isNotEmpty) 'evidenceUrls': evidenceUrls,
          },
        },
        auth: true,
      );
      return data['raiseShopEscrowDispute'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<EscrowDispute?> getDispute(int orderId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _disputeQuery,
        variables: {'orderId': orderId.toString()},
        auth: true,
      );
      final gql = data['shopEscrowDispute'] as Map<String, dynamic>?;
      if (gql == null) return null;
      return GraphqlEscrowMapper.disputeFromGraphql(gql);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> sellerRespondToDispute(int orderId, String response) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _respondMutation,
        variables: {
          'orderId': orderId.toString(),
          'response': response,
        },
        auth: true,
      );
      return data['respondShopEscrowDispute'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<List<EscrowDispute>> listDisputes({
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _disputesQuery,
        variables: {if (status != null) 'status': status},
        auth: true,
      );
      return (data['shopEscrowDisputes'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlEscrowMapper.disputeFromGraphql)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<EscrowWalletSummary?> getWalletSummary() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _walletSummaryQuery,
        auth: true,
      );
      final gql = data['shopEscrowWalletSummary'] as Map<String, dynamic>?;
      if (gql == null) return null;
      return GraphqlEscrowMapper.walletSummaryFromGraphql(gql);
    } catch (_) {
      return null;
    }
  }
}
