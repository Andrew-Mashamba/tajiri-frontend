// Unified delivery dispatch models — supports multiple providers with
// a common interface so the UI and service layer stay provider-agnostic.

// ─── Provider identity ────────────────────────────────────────────────────

enum DeliveryProviderType {
  tajiri,       // Tajiri Delivery Service — in-house, always available, DEFAULT
  sendy,        // sendyit.com — REST API, Kenya + Tanzania
  whatsapp,     // WhatsApp Business Cloud API — manual rider dispatch
  piki,         // piki.africa — Tanzania (API access via partnership)
  afriDelivery, // afridelivery.app — partnership required
  lori,         // lorisystems.com — B2B freight, partnership required
  selfDelivery, // own rider
}

extension DeliveryProviderTypeX on DeliveryProviderType {
  String get displayName {
    switch (this) {
      case DeliveryProviderType.tajiri:
        return 'Tajiri Delivery';
      case DeliveryProviderType.sendy:
        return 'Sendy';
      case DeliveryProviderType.whatsapp:
        return 'WhatsApp Dispatch';
      case DeliveryProviderType.piki:
        return 'Piki';
      case DeliveryProviderType.afriDelivery:
        return 'AfriDelivery';
      case DeliveryProviderType.lori:
        return 'Lori Systems';
      case DeliveryProviderType.selfDelivery:
        return 'Self-delivery';
    }
  }

  String get description {
    switch (this) {
      case DeliveryProviderType.tajiri:
        return 'In-house courier · Dar es Salaam · Always available';
      case DeliveryProviderType.sendy:
        return 'Motorcycle/van courier · Kenya & Tanzania';
      case DeliveryProviderType.whatsapp:
        return 'Send dispatch message to rider via WhatsApp';
      case DeliveryProviderType.piki:
        return 'Dar es Salaam courier · partnership required';
      case DeliveryProviderType.afriDelivery:
        return 'Parcel delivery service · partnership required';
      case DeliveryProviderType.lori:
        return 'B2B freight & bulk cargo · partnership required';
      case DeliveryProviderType.selfDelivery:
        return 'Your own rider or vehicle';
    }
  }

  bool get isAvailable {
    switch (this) {
      case DeliveryProviderType.tajiri:
      case DeliveryProviderType.sendy:
      case DeliveryProviderType.whatsapp:
      case DeliveryProviderType.selfDelivery:
        return true;
      case DeliveryProviderType.piki:
      case DeliveryProviderType.afriDelivery:
      case DeliveryProviderType.lori:
        return false; // requires API key from partnership
    }
  }

  bool get requiresConfig {
    switch (this) {
      case DeliveryProviderType.sendy:
      case DeliveryProviderType.whatsapp:
        return true;
      default:
        return false;
    }
  }

  bool get isTajiri => this == DeliveryProviderType.tajiri;
}

// ─── Location ─────────────────────────────────────────────────────────────

class DeliveryLocation {
  final String name;
  final String phone;
  final String address;
  final double? lat;
  final double? lng;

  const DeliveryLocation({
    required this.name,
    required this.phone,
    required this.address,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'address': address,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
}

// ─── Delivery Request ─────────────────────────────────────────────────────

class DeliveryRequest {
  final int orderId;
  final String orderNumber;
  final DeliveryLocation pickup;
  final DeliveryLocation dropoff;
  final double weightKg;
  final double itemValueTzs;
  final String? notes;
  final DateTime? preferredPickupTime;

  const DeliveryRequest({
    required this.orderId,
    required this.orderNumber,
    required this.pickup,
    required this.dropoff,
    this.weightKg = 1.0,
    this.itemValueTzs = 0,
    this.notes,
    this.preferredPickupTime,
  });
}

// ─── Delivery Quote ───────────────────────────────────────────────────────

class DeliveryQuote {
  final DeliveryProviderType provider;
  final double priceTzs;
  final Duration? estimatedDuration;
  final String? currency;
  final String? vehicleType;
  final bool available;
  final String? unavailableReason;

  const DeliveryQuote({
    required this.provider,
    required this.priceTzs,
    this.estimatedDuration,
    this.currency = 'TZS',
    this.vehicleType,
    this.available = true,
    this.unavailableReason,
  });

  String get priceFormatted {
    if (!available) return unavailableReason ?? 'Unavailable';
    if (priceTzs == 0) return 'Free';
    return 'TZS ${priceTzs.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        )}';
  }

  String get etaFormatted {
    if (estimatedDuration == null) return '—';
    final m = estimatedDuration!.inMinutes;
    if (m < 60) return '~$m min';
    final h = estimatedDuration!.inHours;
    return '~$h hr';
  }
}

// ─── Delivery Result ──────────────────────────────────────────────────────

class DeliveryResult {
  final bool success;
  final DeliveryProviderType provider;
  final String? trackingId;     // provider's reference ID
  final String? trackingUrl;    // deep-link or web URL to track
  final String? message;
  final Map<String, dynamic>? rawResponse;

  const DeliveryResult({
    required this.success,
    required this.provider,
    this.trackingId,
    this.trackingUrl,
    this.message,
    this.rawResponse,
  });

  factory DeliveryResult.failure(DeliveryProviderType provider, String message) =>
      DeliveryResult(success: false, provider: provider, message: message);
}

// ─── Tracking info ────────────────────────────────────────────────────────

enum TrackingStatus {
  pending,
  assigned,
  pickedUp,
  inTransit,
  delivered,
  failed,
  cancelled,
}

class DeliveryTracking {
  final DeliveryProviderType provider;
  final String trackingId;
  final TrackingStatus status;
  final String statusLabel;
  final String? riderName;
  final String? riderPhone;
  final double? riderLat;
  final double? riderLng;
  final DateTime? updatedAt;

  const DeliveryTracking({
    required this.provider,
    required this.trackingId,
    required this.status,
    required this.statusLabel,
    this.riderName,
    this.riderPhone,
    this.riderLat,
    this.riderLng,
    this.updatedAt,
  });
}
