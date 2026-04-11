// lib/ambulance/models/ambulance_models.dart
import '../../config/api_config.dart';

// ─── Helpers ───────────────────────────────────────────────────

int _parseInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

String? _imageUrl(dynamic v) {
  if (v == null) return null;
  return ApiConfig.sanitizeUrl(v.toString());
}

// ─── Result wrappers ──────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final String? message;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.message,
  });
}

// ─── Emergency ────────────────────────────────────────────────

enum EmergencyStatus {
  dispatched,
  enRoute,
  arrived,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case dispatched:
        return 'Imetumwa';
      case enRoute:
        return 'Njiani';
      case arrived:
        return 'Imefika';
      case completed:
        return 'Imekamilika';
      case cancelled:
        return 'Imeghairiwa';
    }
  }

  String get labelEn {
    switch (this) {
      case dispatched:
        return 'Dispatched';
      case enRoute:
        return 'En Route';
      case arrived:
        return 'Arrived';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
    }
  }

  static EmergencyStatus fromString(String? s) {
    if (s == 'en_route') return EmergencyStatus.enRoute;
    return EmergencyStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => EmergencyStatus.dispatched,
    );
  }
}

class Emergency {
  final int id;
  final int userId;
  final double latitude;
  final double longitude;
  final String? address;
  final EmergencyStatus status;
  final AmbulanceUnit? ambulance;
  final int? hospitalId;
  final String? hospitalName;
  final String? type;
  final double? cost;
  final String? ambulanceProvider;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final bool isPaid;

  Emergency({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.status = EmergencyStatus.dispatched,
    this.ambulance,
    this.hospitalId,
    this.hospitalName,
    this.type,
    this.cost,
    this.ambulanceProvider,
    this.createdAt,
    this.resolvedAt,
    this.isPaid = false,
  });

  factory Emergency.fromJson(Map<String, dynamic> json) {
    return Emergency(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      address: json['address'],
      status: EmergencyStatus.fromString(json['status']),
      ambulance: json['ambulance'] != null
          ? AmbulanceUnit.fromJson(json['ambulance'])
          : null,
      hospitalId:
          json['hospital_id'] != null ? _parseInt(json['hospital_id']) : null,
      hospitalName: json['hospital_name'],
      type: json['type'],
      cost: json['cost'] != null ? _parseDouble(json['cost']) : null,
      ambulanceProvider: json['ambulance_provider'] ??
          (json['ambulance'] != null
              ? (json['ambulance'] as Map<String, dynamic>)['provider']
              : null),
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      resolvedAt: DateTime.tryParse(json['resolved_at'] ?? ''),
      isPaid: _parseBool(json['is_paid']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        'status': status.name,
        if (hospitalId != null) 'hospital_id': hospitalId,
        if (hospitalName != null) 'hospital_name': hospitalName,
        if (type != null) 'type': type,
        if (cost != null) 'cost': cost,
        if (ambulanceProvider != null) 'ambulance_provider': ambulanceProvider,
      };
}

// ─── Ambulance Unit ───────────────────────────────────────────

class AmbulanceUnit {
  final int id;
  final String provider;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final String? qualifications;
  final double latitude;
  final double longitude;
  final int? etaMinutes;

  AmbulanceUnit({
    required this.id,
    required this.provider,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.qualifications,
    this.latitude = 0,
    this.longitude = 0,
    this.etaMinutes,
  });

  factory AmbulanceUnit.fromJson(Map<String, dynamic> json) {
    return AmbulanceUnit(
      id: _parseInt(json['id']),
      provider: json['provider'] ?? '',
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      driverPhoto: _imageUrl(json['driver_photo']),
      qualifications: json['qualifications'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      etaMinutes:
          json['eta_minutes'] != null ? _parseInt(json['eta_minutes']) : null,
    );
  }
}

// ─── Ambulance Tracking ──────────────────────────────────────

class AmbulanceTracking {
  final int ambulanceId;
  final double latitude;
  final double longitude;
  final int? etaMinutes;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final EmergencyStatus status;
  final String? shareUrl;
  final String? ambulanceProvider;
  final double? estimatedCost;

  AmbulanceTracking({
    required this.ambulanceId,
    this.latitude = 0,
    this.longitude = 0,
    this.etaMinutes,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.status = EmergencyStatus.dispatched,
    this.shareUrl,
    this.ambulanceProvider,
    this.estimatedCost,
  });

  factory AmbulanceTracking.fromJson(Map<String, dynamic> json) {
    return AmbulanceTracking(
      ambulanceId: _parseInt(json['ambulance_id']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      etaMinutes:
          json['eta_minutes'] != null ? _parseInt(json['eta_minutes']) : null,
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      driverPhoto: _imageUrl(json['driver_photo']),
      status: EmergencyStatus.fromString(json['status']),
      shareUrl: json['share_url'],
      ambulanceProvider: json['ambulance_provider'] ?? json['provider'],
      estimatedCost: json['estimated_cost'] != null
          ? _parseDouble(json['estimated_cost'])
          : null,
    );
  }
}

// ─── Medical Profile ──────────────────────────────────────────

class MedicalProfile {
  final int id;
  final int userId;
  final String? bloodType;
  final List<String> allergies;
  final List<String> conditions;
  final List<String> medications;
  final List<EmergencyContact> emergencyContacts;
  final String? insuranceProvider;
  final String? insurancePolicyNo;

  MedicalProfile({
    required this.id,
    required this.userId,
    this.bloodType,
    this.allergies = const [],
    this.conditions = const [],
    this.medications = const [],
    this.emergencyContacts = const [],
    this.insuranceProvider,
    this.insurancePolicyNo,
  });

  factory MedicalProfile.fromJson(Map<String, dynamic> json) {
    return MedicalProfile(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      bloodType: json['blood_type'],
      allergies: (json['allergies'] as List?)?.cast<String>() ?? [],
      conditions: (json['conditions'] as List?)?.cast<String>() ?? [],
      medications: (json['medications'] as List?)?.cast<String>() ?? [],
      emergencyContacts: (json['emergency_contacts'] as List?)
              ?.map((c) => EmergencyContact.fromJson(c))
              .toList() ??
          [],
      insuranceProvider: json['insurance_provider'],
      insurancePolicyNo: json['insurance_policy_no'],
    );
  }

  Map<String, dynamic> toJson() => {
        'blood_type': bloodType,
        'allergies': allergies,
        'conditions': conditions,
        'medications': medications,
        'emergency_contacts':
            emergencyContacts.map((c) => c.toJson()).toList(),
        'insurance_provider': insuranceProvider,
        'insurance_policy_no': insurancePolicyNo,
      };
}

class EmergencyContact {
  final int? id;
  final String name;
  final String phone;
  final String relationship;
  final bool autoNotify;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    this.relationship = '',
    this.autoNotify = true,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? '',
      autoNotify: _parseBool(json['auto_notify'], true),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'auto_notify': autoNotify,
      };
}

// ─── Insurance Info ──────────────────────────────────────────

class InsuranceInfo {
  final int? id;
  final String provider;
  final String policyNumber;
  final String? memberId;
  final String? coverageType;
  final String? cardPhotoUrl;
  final bool isVerified;
  final DateTime? expiryDate;

  InsuranceInfo({
    this.id,
    required this.provider,
    required this.policyNumber,
    this.memberId,
    this.coverageType,
    this.cardPhotoUrl,
    this.isVerified = false,
    this.expiryDate,
  });

  factory InsuranceInfo.fromJson(Map<String, dynamic> json) {
    return InsuranceInfo(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      provider: json['provider'] ?? '',
      policyNumber: json['policy_number'] ?? '',
      memberId: json['member_id'],
      coverageType: json['coverage_type'],
      cardPhotoUrl: _imageUrl(json['card_photo_url']),
      isVerified: _parseBool(json['is_verified']),
      expiryDate: DateTime.tryParse(json['expiry_date'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'policy_number': policyNumber,
        if (memberId != null) 'member_id': memberId,
        if (coverageType != null) 'coverage_type': coverageType,
      };
}

// ─── Family Profile ──────────────────────────────────────────

class FamilyProfile {
  final int? id;
  final String name;
  final String relationship;
  final String? bloodType;
  final List<String> allergies;
  final List<String> conditions;
  final List<String> medications;

  FamilyProfile({
    this.id,
    required this.name,
    required this.relationship,
    this.bloodType,
    this.allergies = const [],
    this.conditions = const [],
    this.medications = const [],
  });

  factory FamilyProfile.fromJson(Map<String, dynamic> json) {
    return FamilyProfile(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      bloodType: json['blood_type'],
      allergies: (json['allergies'] as List?)?.cast<String>() ?? [],
      conditions: (json['conditions'] as List?)?.cast<String>() ?? [],
      medications: (json['medications'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'relationship': relationship,
        if (bloodType != null) 'blood_type': bloodType,
        'allergies': allergies,
        'conditions': conditions,
        'medications': medications,
      };
}

// ─── Subscription ────────────────────────────────────────────

class SubscriptionPlan {
  final int id;
  final String name;
  final String nameSw;
  final String planType;
  final double priceMonthly;
  final double priceYearly;
  final int maxMembers;
  final List<String> features;
  final List<String> featuresSw;

  SubscriptionPlan({
    required this.id,
    required this.name,
    this.nameSw = '',
    required this.planType,
    this.priceMonthly = 0,
    this.priceYearly = 0,
    this.maxMembers = 1,
    this.features = const [],
    this.featuresSw = const [],
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      nameSw: json['name_sw'] ?? json['name'] ?? '',
      planType: json['plan_type'] ?? 'individual',
      priceMonthly: _parseDouble(json['price_monthly']),
      priceYearly: _parseDouble(json['price_yearly']),
      maxMembers: _parseInt(json['max_members'], 1),
      features: (json['features'] as List?)?.cast<String>() ?? [],
      featuresSw: (json['features_sw'] as List?)?.cast<String>() ??
          (json['features'] as List?)?.cast<String>() ??
          [],
    );
  }
}

class Subscription {
  final int? id;
  final String planType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int membersCount;
  final bool isActive;

  Subscription({
    this.id,
    required this.planType,
    this.startDate,
    this.endDate,
    this.membersCount = 1,
    this.isActive = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      planType: json['plan_type'] ?? 'individual',
      startDate: DateTime.tryParse(json['start_date'] ?? ''),
      endDate: DateTime.tryParse(json['end_date'] ?? ''),
      membersCount: _parseInt(json['members_count'], 1),
      isActive: _parseBool(json['is_active']),
    );
  }
}

// ─── First Responder ─────────────────────────────────────────

class FirstResponder {
  final int userId;
  final String name;
  final String? phone;
  final String? photoUrl;
  final List<String> certifications;
  final bool isAvailable;
  final double? distanceKm;

  FirstResponder({
    required this.userId,
    required this.name,
    this.phone,
    this.photoUrl,
    this.certifications = const [],
    this.isAvailable = true,
    this.distanceKm,
  });

  factory FirstResponder.fromJson(Map<String, dynamic> json) {
    return FirstResponder(
      userId: _parseInt(json['user_id']),
      name: json['name'] ?? '',
      phone: json['phone'],
      photoUrl: _imageUrl(json['photo_url']),
      certifications:
          (json['certifications'] as List?)?.cast<String>() ?? [],
      isAvailable: _parseBool(json['is_available'], true),
      distanceKm: json['distance_km'] != null
          ? _parseDouble(json['distance_km'])
          : null,
    );
  }
}

// ─── Accident Report ─────────────────────────────────────────

class AccidentReport {
  final int? id;
  final double latitude;
  final double longitude;
  final String? address;
  final String description;
  final String severity;
  final List<String> photoUrls;
  final DateTime? reportedAt;

  AccidentReport({
    this.id,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.description,
    this.severity = 'moderate',
    this.photoUrls = const [],
    this.reportedAt,
  });

  factory AccidentReport.fromJson(Map<String, dynamic> json) {
    return AccidentReport(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      address: json['address'],
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'moderate',
      photoUrls: (json['photo_urls'] as List?)?.cast<String>() ?? [],
      reportedAt: DateTime.tryParse(json['reported_at'] ?? ''),
    );
  }
}

// ─── Hospital ─────────────────────────────────────────────────

class Hospital {
  final int id;
  final String name;
  final String? type;
  final List<String> capabilities;
  final double latitude;
  final double longitude;
  final String? phone;
  final int bedCount;
  final double rating;
  final double? distanceKm;
  final int? waitTimeMinutes;

  Hospital({
    required this.id,
    required this.name,
    this.type,
    this.capabilities = const [],
    this.latitude = 0,
    this.longitude = 0,
    this.phone,
    this.bedCount = 0,
    this.rating = 0,
    this.distanceKm,
    this.waitTimeMinutes,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      type: json['type'],
      capabilities: (json['capabilities'] as List?)?.cast<String>() ?? [],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      phone: json['phone'],
      bedCount: _parseInt(json['bed_count']),
      rating: _parseDouble(json['rating']),
      distanceKm: json['distance_km'] != null
          ? _parseDouble(json['distance_km'])
          : null,
      waitTimeMinutes: json['wait_time_minutes'] != null
          ? _parseInt(json['wait_time_minutes'])
          : null,
    );
  }
}

// ─── First Aid Guide ──────────────────────────────────────────

class FirstAidGuide {
  final int id;
  final String title;
  final String titleSw;
  final String category;
  final String content;
  final String contentSw;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final List<String> steps;
  final List<String> stepsSw;

  FirstAidGuide({
    required this.id,
    required this.title,
    this.titleSw = '',
    this.category = 'general',
    this.content = '',
    this.contentSw = '',
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.steps = const [],
    this.stepsSw = const [],
  });

  factory FirstAidGuide.fromJson(Map<String, dynamic> json) {
    return FirstAidGuide(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      titleSw: json['title_sw'] ?? json['title'] ?? '',
      category: json['category'] ?? 'general',
      content: json['content'] ?? '',
      contentSw: json['content_sw'] ?? json['content'] ?? '',
      imageUrl: _imageUrl(json['image_url']),
      audioUrl: json['audio_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      steps: (json['steps'] as List?)?.cast<String>() ?? [],
      stepsSw: (json['steps_sw'] as List?)?.cast<String>() ??
          (json['steps'] as List?)?.cast<String>() ??
          [],
    );
  }
}

// ─── AED Location ────────────────────────────────────────────

class AedLocation {
  final int? id;
  final double latitude;
  final double longitude;
  final String name;
  final String? address;

  AedLocation({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
    this.address,
  });

  factory AedLocation.fromJson(Map<String, dynamic> json) {
    return AedLocation(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      name: json['name'] ?? '',
      address: json['address'],
    );
  }
}

// ─── Insurance Pre-Auth Result ───────────────────────────────

class InsurancePreAuth {
  final bool approved;
  final String? authorizationCode;
  final String? message;
  final double? coveredAmount;

  InsurancePreAuth({
    required this.approved,
    this.authorizationCode,
    this.message,
    this.coveredAmount,
  });

  factory InsurancePreAuth.fromJson(Map<String, dynamic> json) {
    return InsurancePreAuth(
      approved: _parseBool(json['approved']),
      authorizationCode: json['authorization_code'],
      message: json['message'],
      coveredAmount: json['covered_amount'] != null
          ? _parseDouble(json['covered_amount'])
          : null,
    );
  }
}
