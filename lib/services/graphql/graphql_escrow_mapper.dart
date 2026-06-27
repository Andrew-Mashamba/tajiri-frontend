import '../../shop/escrow/models/escrow_models.dart';

/// Maps greenfield GraphQL escrow types → legacy REST JSON.
class GraphqlEscrowMapper {
  static Map<String, dynamic> escrowInfoToLegacy(Map<String, dynamic> gql) {
    final dispute = gql['dispute'] as Map<String, dynamic>?;
    return {
      'escrow_status': gql['escrowStatus'] ?? 'pending',
      if (gql['escrowHeldAt'] != null) 'escrow_held_at': gql['escrowHeldAt'].toString(),
      if (gql['escrowAutoReleaseAt'] != null)
        'escrow_auto_release_at': gql['escrowAutoReleaseAt'].toString(),
      if (gql['escrowReleasedAt'] != null)
        'escrow_released_at': gql['escrowReleasedAt'].toString(),
      if (dispute != null) 'dispute': disputeToLegacy(dispute),
    };
  }

  static EscrowInfo escrowInfoFromGraphql(Map<String, dynamic> gql) {
    return EscrowInfo.fromJson(escrowInfoToLegacy(gql));
  }

  static Map<String, dynamic> disputeToLegacy(Map<String, dynamic> gql) {
    final urls = (gql['evidenceUrls'] as List? ?? []).map((e) => e.toString()).toList();
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'order_id': int.tryParse(gql['orderId']?.toString() ?? '') ?? 0,
      'raised_by': int.tryParse(gql['raisedBy']?.toString() ?? '') ?? 0,
      'reason': gql['reason'] ?? '',
      if (gql['description'] != null) 'description': gql['description'],
      'evidence_urls': urls,
      'status': gql['status'] ?? 'open',
      if (gql['resolutionNotes'] != null) 'resolution_notes': gql['resolutionNotes'],
      if (gql['sellerResponse'] != null) 'seller_response': gql['sellerResponse'],
      if (gql['sellerRespondedAt'] != null)
        'seller_responded_at': gql['sellerRespondedAt'].toString(),
      if (gql['adminNotes'] != null) 'admin_notes': gql['adminNotes'],
      'priority': gql['priority'] ?? 'normal',
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      if (gql['resolvedAt'] != null) 'resolved_at': gql['resolvedAt'].toString(),
    };
  }

  static EscrowDispute disputeFromGraphql(Map<String, dynamic> gql) {
    return EscrowDispute.fromJson(disputeToLegacy(gql));
  }

  static EscrowWalletSummary walletSummaryFromGraphql(Map<String, dynamic> gql) {
    return EscrowWalletSummary.fromJson({
      'held_amount': gql['heldAmount'] ?? 0,
      'pending_release_count': gql['pendingReleaseCount'] ?? 0,
    });
  }
}
