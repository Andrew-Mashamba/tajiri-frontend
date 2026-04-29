import '../../tajirika/models/tajirika_models.dart' show SkillCategory;

enum ServiceRequestStatus {
  pending,
  quoted,
  accepted,
  enRoute,
  onSite,
  completed,
  cancelled,
  rejected;

  String get apiValue {
    switch (this) {
      case ServiceRequestStatus.pending: return 'pending';
      case ServiceRequestStatus.quoted: return 'quoted';
      case ServiceRequestStatus.accepted: return 'accepted';
      case ServiceRequestStatus.enRoute: return 'en_route';
      case ServiceRequestStatus.onSite: return 'on_site';
      case ServiceRequestStatus.completed: return 'completed';
      case ServiceRequestStatus.cancelled: return 'cancelled';
      case ServiceRequestStatus.rejected: return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ServiceRequestStatus.pending: return 'Pending';
      case ServiceRequestStatus.quoted: return 'Quoted';
      case ServiceRequestStatus.accepted: return 'Accepted';
      case ServiceRequestStatus.enRoute: return 'En route';
      case ServiceRequestStatus.onSite: return 'On site';
      case ServiceRequestStatus.completed: return 'Completed';
      case ServiceRequestStatus.cancelled: return 'Cancelled';
      case ServiceRequestStatus.rejected: return 'Rejected';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ServiceRequestStatus.pending: return 'Inasubiri';
      case ServiceRequestStatus.quoted: return 'Bei imetolewa';
      case ServiceRequestStatus.accepted: return 'Imekubaliwa';
      case ServiceRequestStatus.enRoute: return 'Yuko njiani';
      case ServiceRequestStatus.onSite: return 'Yuko site';
      case ServiceRequestStatus.completed: return 'Imekamilika';
      case ServiceRequestStatus.cancelled: return 'Imeghairiwa';
      case ServiceRequestStatus.rejected: return 'Imekataliwa';
    }
  }

  static ServiceRequestStatus fromString(String? raw) {
    switch (raw) {
      case 'pending': return ServiceRequestStatus.pending;
      case 'quoted': return ServiceRequestStatus.quoted;
      case 'accepted': return ServiceRequestStatus.accepted;
      case 'en_route': return ServiceRequestStatus.enRoute;
      case 'on_site': return ServiceRequestStatus.onSite;
      case 'completed': return ServiceRequestStatus.completed;
      case 'cancelled': return ServiceRequestStatus.cancelled;
      case 'rejected': return ServiceRequestStatus.rejected;
      default: return ServiceRequestStatus.pending;
    }
  }
}

enum ServiceRequestWindow {
  todayAm,
  todayPm,
  tomorrow,
  thisWeek;

  String get apiValue {
    switch (this) {
      case ServiceRequestWindow.todayAm: return 'today_am';
      case ServiceRequestWindow.todayPm: return 'today_pm';
      case ServiceRequestWindow.tomorrow: return 'tomorrow';
      case ServiceRequestWindow.thisWeek: return 'this_week';
    }
  }

  String get label {
    switch (this) {
      case ServiceRequestWindow.todayAm: return 'Today (AM)';
      case ServiceRequestWindow.todayPm: return 'Today (PM)';
      case ServiceRequestWindow.tomorrow: return 'Tomorrow';
      case ServiceRequestWindow.thisWeek: return 'This week';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ServiceRequestWindow.todayAm: return 'Leo (asubuhi)';
      case ServiceRequestWindow.todayPm: return 'Leo (jioni)';
      case ServiceRequestWindow.tomorrow: return 'Kesho';
      case ServiceRequestWindow.thisWeek: return 'Wiki hii';
    }
  }

  static ServiceRequestWindow fromString(String? raw) {
    switch (raw) {
      case 'today_am': return ServiceRequestWindow.todayAm;
      case 'today_pm': return ServiceRequestWindow.todayPm;
      case 'tomorrow': return ServiceRequestWindow.tomorrow;
      case 'this_week': return ServiceRequestWindow.thisWeek;
      default: return ServiceRequestWindow.todayPm;
    }
  }
}

enum QuoteEta {
  now,
  oneHour,
  threeHour,
  tomorrow;

  String get apiValue {
    switch (this) {
      case QuoteEta.now: return 'now';
      case QuoteEta.oneHour: return '1h';
      case QuoteEta.threeHour: return '3h';
      case QuoteEta.tomorrow: return 'tomorrow';
    }
  }

  String get label {
    switch (this) {
      case QuoteEta.now: return 'Within 1 hour';
      case QuoteEta.oneHour: return 'Within 1 hour';
      case QuoteEta.threeHour: return 'Within 3 hours';
      case QuoteEta.tomorrow: return 'Tomorrow';
    }
  }

  String get labelSwahili {
    switch (this) {
      case QuoteEta.now: return 'Sasa hivi';
      case QuoteEta.oneHour: return 'Saa 1';
      case QuoteEta.threeHour: return 'Saa 3';
      case QuoteEta.tomorrow: return 'Kesho';
    }
  }

  static QuoteEta fromString(String? raw) {
    switch (raw) {
      case 'now': return QuoteEta.now;
      case '1h': return QuoteEta.oneHour;
      case '3h': return QuoteEta.threeHour;
      case 'tomorrow': return QuoteEta.tomorrow;
      default: return QuoteEta.oneHour;
    }
  }
}

enum QuoteStatus {
  pending,
  accepted,
  autoRejected,
  withdrawn;

  String get apiValue {
    switch (this) {
      case QuoteStatus.pending: return 'pending';
      case QuoteStatus.accepted: return 'accepted';
      case QuoteStatus.autoRejected: return 'auto_rejected';
      case QuoteStatus.withdrawn: return 'withdrawn';
    }
  }

  static QuoteStatus fromString(String? raw) {
    switch (raw) {
      case 'pending': return QuoteStatus.pending;
      case 'accepted': return QuoteStatus.accepted;
      case 'auto_rejected': return QuoteStatus.autoRejected;
      case 'withdrawn': return QuoteStatus.withdrawn;
      default: return QuoteStatus.pending;
    }
  }
}

int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _parseDoubleN(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class ServiceRequestQuote {
  final int id;
  final int serviceRequestId;
  final int partnerUserId;
  final int? partnerId;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final int calloutFeeTzs;
  final int? estimatedCostTzs;
  final QuoteEta eta;
  final QuoteStatus status;
  final String? notes;
  final DateTime? createdAt;

  ServiceRequestQuote({
    required this.id,
    required this.serviceRequestId,
    required this.partnerUserId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.calloutFeeTzs,
    required this.estimatedCostTzs,
    required this.eta,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  factory ServiceRequestQuote.fromJson(Map<String, dynamic> json) {
    return ServiceRequestQuote(
      id: _parseIntN(json['id']) ?? 0,
      serviceRequestId: _parseIntN(json['service_request_id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      partnerId: _parseIntN(json['partner_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      calloutFeeTzs: _parseIntN(json['callout_fee_tzs']) ?? 0,
      estimatedCostTzs: _parseIntN(json['estimated_cost_tzs']),
      eta: QuoteEta.fromString(json['eta']?.toString()),
      status: QuoteStatus.fromString(json['status']?.toString()),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class PartsLineItem {
  final String name;
  final int costTzs;
  final int? markupPct;

  PartsLineItem({
    required this.name,
    required this.costTzs,
    this.markupPct,
  });

  factory PartsLineItem.fromJson(Map<String, dynamic> json) {
    return PartsLineItem(
      name: json['name']?.toString() ?? '',
      costTzs: _parseIntN(json['cost_tzs']) ?? 0,
      markupPct: _parseIntN(json['markup_pct']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'cost_tzs': costTzs,
    if (markupPct != null) 'markup_pct': markupPct,
  };
}

class ServiceRequest {
  final int id;
  final int customerUserId;
  final String? customerName;
  final String? customerPhotoUrl;
  final String? customerPhone;
  final int? targetPartnerUserId;
  final int? acceptedPartnerUserId;
  final String? acceptedPartnerName;
  final String? acceptedPartnerPhotoUrl;
  final SkillCategory? skillCategory;
  final String skillCategoryRaw;
  final String problemSummary;
  final List<String> photos;
  final String address;
  final double? lat;
  final double? lng;
  final ServiceRequestWindow preferredWindow;
  final ServiceRequestStatus status;
  final int? calloutFeeTzs;
  final int? estimatedCostTzs;
  final DateTime? acceptedAt;
  final DateTime? enRouteAt;
  final DateTime? onSiteAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? rejectionReason;
  final DateTime? createdAt;
  final int? warrantyDays;
  /// Spec line 467 — AI-derived typical cost band shown to customer pre-quote.
  final int? aiCostLowTzs;
  final int? aiCostHighTzs;
  /// Spec line 462 — diagnostic fee credited toward repair if customer proceeds.
  final int? diagnosticFeeTzs;
  final int diagnosticFeeCreditedTzs;
  /// Spec line 465 — partner submits revised quote on-site; customer must approve before work starts.
  final int? revisedQuoteTzs;
  final DateTime? revisedQuoteApprovedAt;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final List<PartsLineItem> partsLineItems;
  final int? partsMarkupPct;
  final int? siteSurveyFeeTzs;
  final int? parentRequestId;
  final List<ServiceRequestQuote> quotes;

  ServiceRequest({
    required this.id,
    required this.customerUserId,
    required this.customerName,
    required this.customerPhotoUrl,
    required this.customerPhone,
    required this.targetPartnerUserId,
    required this.acceptedPartnerUserId,
    required this.acceptedPartnerName,
    required this.acceptedPartnerPhotoUrl,
    required this.skillCategory,
    required this.skillCategoryRaw,
    required this.problemSummary,
    required this.photos,
    required this.address,
    required this.lat,
    required this.lng,
    required this.preferredWindow,
    required this.status,
    required this.calloutFeeTzs,
    required this.estimatedCostTzs,
    required this.acceptedAt,
    required this.enRouteAt,
    required this.onSiteAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.cancellationReason,
    required this.rejectionReason,
    required this.createdAt,
    required this.warrantyDays,
    this.aiCostLowTzs,
    this.aiCostHighTzs,
    this.diagnosticFeeTzs,
    this.diagnosticFeeCreditedTzs = 0,
    this.revisedQuoteTzs,
    this.revisedQuoteApprovedAt,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.partsLineItems = const [],
    this.partsMarkupPct,
    this.siteSurveyFeeTzs,
    this.parentRequestId,
    required this.quotes,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final raw = json['skill_category']?.toString() ?? '';
    final photos = (json['photos'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final quotes = (json['quotes'] as List?)
            ?.whereType<Map>()
            .map((m) => ServiceRequestQuote.fromJson(m.cast<String, dynamic>()))
            .toList() ??
        const <ServiceRequestQuote>[];
    return ServiceRequest(
      id: _parseIntN(json['id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      customerName: json['customer_name']?.toString(),
      customerPhotoUrl: json['customer_photo_url']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      targetPartnerUserId: _parseIntN(json['target_partner_user_id']),
      acceptedPartnerUserId: _parseIntN(json['accepted_partner_user_id']),
      acceptedPartnerName: json['accepted_partner_name']?.toString(),
      acceptedPartnerPhotoUrl: json['accepted_partner_photo_url']?.toString(),
      skillCategory: SkillCategory.fromString(raw),
      skillCategoryRaw: raw,
      problemSummary: json['problem_summary']?.toString() ?? '',
      photos: photos,
      address: json['address']?.toString() ?? '',
      lat: _parseDoubleN(json['lat']),
      lng: _parseDoubleN(json['lng']),
      preferredWindow:
          ServiceRequestWindow.fromString(json['preferred_window']?.toString()),
      status: ServiceRequestStatus.fromString(json['status']?.toString()),
      calloutFeeTzs: _parseIntN(json['callout_fee_tzs']),
      estimatedCostTzs: _parseIntN(json['estimated_cost_tzs']),
      acceptedAt: _parseDate(json['accepted_at']),
      enRouteAt: _parseDate(json['en_route_at']),
      onSiteAt: _parseDate(json['on_site_at']),
      completedAt: _parseDate(json['completed_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      cancellationReason: json['cancellation_reason']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: _parseDate(json['created_at']),
      warrantyDays: _parseIntN(json['warranty_days']),
      aiCostLowTzs: _parseIntN(json['ai_cost_low_tzs']),
      aiCostHighTzs: _parseIntN(json['ai_cost_high_tzs']),
      diagnosticFeeTzs: _parseIntN(json['diagnostic_fee_tzs']),
      diagnosticFeeCreditedTzs:
          _parseIntN(json['diagnostic_fee_credited_tzs']) ?? 0,
      revisedQuoteTzs: _parseIntN(json['revised_quote_tzs']),
      revisedQuoteApprovedAt: _parseDate(json['revised_quote_approved_at']),
      beforePhotos: (json['before_photos'] is List)
          ? (json['before_photos'] as List).map((e) => e.toString()).toList()
          : const [],
      afterPhotos: (json['after_photos'] is List)
          ? (json['after_photos'] as List).map((e) => e.toString()).toList()
          : const [],
      partsLineItems: (json['parts_line_items'] is List)
          ? (json['parts_line_items'] as List)
              .whereType<Map>()
              .map((m) => PartsLineItem.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const [],
      partsMarkupPct: _parseIntN(json['parts_markup_pct']),
      siteSurveyFeeTzs: _parseIntN(json['site_survey_fee_tzs']),
      parentRequestId: _parseIntN(json['parent_request_id']),
      quotes: quotes,
    );
  }

  DateTime? get warrantyExpiresAt {
    if (warrantyDays == null || warrantyDays! <= 0) return null;
    if (completedAt == null) return null;
    return completedAt!.add(Duration(days: warrantyDays!));
  }

  bool get isOpenMarketplace =>
      targetPartnerUserId == null && acceptedPartnerUserId == null;

  bool get hasFinalised =>
      status == ServiceRequestStatus.completed ||
      status == ServiceRequestStatus.cancelled ||
      status == ServiceRequestStatus.rejected;
}

class ServiceRequestResult {
  final bool success;
  final ServiceRequest? request;
  final String? message;
  final int? statusCode;
  ServiceRequestResult({
    required this.success,
    this.request,
    this.message,
    this.statusCode,
  });
}

class ServiceRequestListResult {
  final bool success;
  final List<ServiceRequest> requests;
  final String? message;
  final int? statusCode;
  ServiceRequestListResult({
    required this.success,
    this.requests = const [],
    this.message,
    this.statusCode,
  });
}

class ServiceRequestPhotoUploadResult {
  final bool success;
  final String? photoUrl;
  final String? message;
  ServiceRequestPhotoUploadResult({
    required this.success,
    this.photoUrl,
    this.message,
  });
}
