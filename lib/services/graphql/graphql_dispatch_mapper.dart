import '../../shop/shipping/models/delivery_models.dart';

/// Maps greenfield GraphQL dispatch types → legacy REST JSON / models.
class GraphqlDispatchMapper {
  static DeliveryQuote quoteFromGraphql(Map<String, dynamic> gql) {
    final providerSlug = gql['provider'] as String? ?? 'self';
    return DeliveryQuote(
      provider: slugToProvider(providerSlug),
      priceTzs: (gql['priceTzs'] as num?)?.toDouble() ?? 0,
      available: gql['available'] as bool? ?? false,
      vehicleType: gql['vehicleType'] as String?,
      estimatedDuration: gql['etaMinutes'] != null
          ? Duration(minutes: (gql['etaMinutes'] as num).toInt())
          : null,
      unavailableReason: gql['unavailableReason'] as String?,
    );
  }

  static DeliveryResult resultFromGraphql(
    Map<String, dynamic> gql,
    DeliveryProviderType provider,
  ) {
    return DeliveryResult(
      success: true,
      provider: provider,
      trackingId: gql['trackingId'] as String?,
      trackingUrl: gql['trackingUrl'] as String?,
      message: gql['message'] as String?,
      rawResponse: {
        'tracking_id': gql['trackingId'],
        'tracking_url': gql['trackingUrl'],
      },
    );
  }

  static DeliveryTracking trackingFromGraphql(Map<String, dynamic> gql) {
    final providerSlug = gql['provider'] as String? ?? 'self';
    final detail = gql['tracking'] as Map<String, dynamic>? ?? {};
    return DeliveryTracking(
      provider: slugToProvider(providerSlug),
      trackingId: gql['trackingId'] as String? ?? '',
      status: parseTrackingStatus(detail['status'] as String? ?? ''),
      statusLabel: detail['statusLabel'] as String? ?? '',
      riderName: detail['riderName'] as String?,
      riderPhone: detail['riderPhone'] as String?,
      riderLat: (detail['riderLat'] as num?)?.toDouble(),
      riderLng: (detail['riderLng'] as num?)?.toDouble(),
      updatedAt: detail['updatedAt'] != null
          ? DateTime.tryParse(detail['updatedAt'] as String)
          : null,
    );
  }

  static String providerSlug(DeliveryProviderType p) {
    switch (p) {
      case DeliveryProviderType.tajiri:
        return 'tajiri';
      case DeliveryProviderType.sendy:
        return 'sendy';
      case DeliveryProviderType.whatsapp:
        return 'whatsapp';
      case DeliveryProviderType.piki:
        return 'piki';
      case DeliveryProviderType.afriDelivery:
        return 'afridelivery';
      case DeliveryProviderType.lori:
        return 'lori';
      case DeliveryProviderType.selfDelivery:
        return 'self';
    }
  }

  static DeliveryProviderType slugToProvider(String slug) {
    switch (slug) {
      case 'tajiri':
        return DeliveryProviderType.tajiri;
      case 'sendy':
        return DeliveryProviderType.sendy;
      case 'whatsapp':
        return DeliveryProviderType.whatsapp;
      case 'piki':
        return DeliveryProviderType.piki;
      case 'afridelivery':
        return DeliveryProviderType.afriDelivery;
      case 'lori':
        return DeliveryProviderType.lori;
      default:
        return DeliveryProviderType.selfDelivery;
    }
  }

  static TrackingStatus parseTrackingStatus(String s) {
    switch (s) {
      case 'assigned':
        return TrackingStatus.assigned;
      case 'picked_up':
        return TrackingStatus.pickedUp;
      case 'in_transit':
        return TrackingStatus.inTransit;
      case 'delivered':
        return TrackingStatus.delivered;
      case 'failed':
        return TrackingStatus.failed;
      case 'cancelled':
        return TrackingStatus.cancelled;
      default:
        return TrackingStatus.pending;
    }
  }
}
