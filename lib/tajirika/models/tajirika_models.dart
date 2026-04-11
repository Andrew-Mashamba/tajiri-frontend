import 'package:flutter/material.dart';
import '../../config/api_config.dart';

// ==================== PARSING HELPERS ====================

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

String _buildStorageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return '${ApiConfig.storageUrl}/$cleanPath';
}

// ==================== ENUMS ====================

enum PartnerTier {
  mwanafunzi,
  mtaalamu,
  bingwa;

  String get label {
    switch (this) {
      case PartnerTier.mwanafunzi: return 'Apprentice';
      case PartnerTier.mtaalamu: return 'Verified Professional';
      case PartnerTier.bingwa: return 'Expert';
    }
  }

  String get labelSwahili {
    switch (this) {
      case PartnerTier.mwanafunzi: return 'Mwanafunzi';
      case PartnerTier.mtaalamu: return 'Mtaalamu';
      case PartnerTier.bingwa: return 'Bingwa';
    }
  }

  IconData get icon {
    switch (this) {
      case PartnerTier.mwanafunzi: return Icons.school_rounded;
      case PartnerTier.mtaalamu: return Icons.verified_rounded;
      case PartnerTier.bingwa: return Icons.workspace_premium_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PartnerTier.mwanafunzi: return const Color(0xFF9E9E9E);
      case PartnerTier.mtaalamu: return const Color(0xFF616161);
      case PartnerTier.bingwa: return const Color(0xFF212121);
    }
  }

  static PartnerTier fromString(String? value) {
    switch (value) {
      case 'mtaalamu': return PartnerTier.mtaalamu;
      case 'bingwa': return PartnerTier.bingwa;
      default: return PartnerTier.mwanafunzi;
    }
  }
}

enum SkillCategory {
  // Mafundi trades
  plumbing,
  electrical,
  carpentry,
  painting,
  welding,
  masonry,
  roofing,
  tiling,
  solarInstallation,
  // Auto
  autoMechanic,
  autoElectrician,
  panelBeating,
  sprayPainting,
  // Beauty & Wellness
  hairstyling,
  barbering,
  nailTechnician,
  skincare,
  makeup,
  // Professional
  legal,
  medical,
  nursing,
  pharmacy,
  accounting,
  taxAdvisory,
  // Property
  realEstate,
  propertyManagement,
  homeInspection,
  interiorDesign,
  // Fitness & Food
  personalTraining,
  nutrition,
  cooking,
  catering,
  baking,
  // Events & Creative
  eventPlanning,
  photography,
  videography,
  djing,
  mc,
  // Travel & Transport
  tourGuide,
  travelAgent,
  safariOperator,
  // Business
  businessConsulting,
  hrConsulting,
  careerCoaching;

  String get label {
    switch (this) {
      case SkillCategory.plumbing: return 'Plumbing';
      case SkillCategory.electrical: return 'Electrical';
      case SkillCategory.carpentry: return 'Carpentry';
      case SkillCategory.painting: return 'Painting';
      case SkillCategory.welding: return 'Welding';
      case SkillCategory.masonry: return 'Masonry';
      case SkillCategory.roofing: return 'Roofing';
      case SkillCategory.tiling: return 'Tiling';
      case SkillCategory.solarInstallation: return 'Solar Installation';
      case SkillCategory.autoMechanic: return 'Auto Mechanic';
      case SkillCategory.autoElectrician: return 'Auto Electrician';
      case SkillCategory.panelBeating: return 'Panel Beating';
      case SkillCategory.sprayPainting: return 'Spray Painting';
      case SkillCategory.hairstyling: return 'Hairstyling';
      case SkillCategory.barbering: return 'Barbering';
      case SkillCategory.nailTechnician: return 'Nail Technician';
      case SkillCategory.skincare: return 'Skincare';
      case SkillCategory.makeup: return 'Makeup';
      case SkillCategory.legal: return 'Legal';
      case SkillCategory.medical: return 'Medical';
      case SkillCategory.nursing: return 'Nursing';
      case SkillCategory.pharmacy: return 'Pharmacy';
      case SkillCategory.accounting: return 'Accounting';
      case SkillCategory.taxAdvisory: return 'Tax Advisory';
      case SkillCategory.realEstate: return 'Real Estate';
      case SkillCategory.propertyManagement: return 'Property Management';
      case SkillCategory.homeInspection: return 'Home Inspection';
      case SkillCategory.interiorDesign: return 'Interior Design';
      case SkillCategory.personalTraining: return 'Personal Training';
      case SkillCategory.nutrition: return 'Nutrition';
      case SkillCategory.cooking: return 'Cooking';
      case SkillCategory.catering: return 'Catering';
      case SkillCategory.baking: return 'Baking';
      case SkillCategory.eventPlanning: return 'Event Planning';
      case SkillCategory.photography: return 'Photography';
      case SkillCategory.videography: return 'Videography';
      case SkillCategory.djing: return 'DJ';
      case SkillCategory.mc: return 'MC';
      case SkillCategory.tourGuide: return 'Tour Guide';
      case SkillCategory.travelAgent: return 'Travel Agent';
      case SkillCategory.safariOperator: return 'Safari Operator';
      case SkillCategory.businessConsulting: return 'Business Consulting';
      case SkillCategory.hrConsulting: return 'HR Consulting';
      case SkillCategory.careerCoaching: return 'Career Coaching';
    }
  }

  String get labelSwahili {
    switch (this) {
      case SkillCategory.plumbing: return 'Bomba';
      case SkillCategory.electrical: return 'Umeme';
      case SkillCategory.carpentry: return 'Useremala';
      case SkillCategory.painting: return 'Upakaji Rangi';
      case SkillCategory.welding: return 'Uchomeleaji';
      case SkillCategory.masonry: return 'Uashi';
      case SkillCategory.roofing: return 'Paa';
      case SkillCategory.tiling: return 'Utandikaji Vigae';
      case SkillCategory.solarInstallation: return 'Ufungaji Sola';
      case SkillCategory.autoMechanic: return 'Fundi Magari';
      case SkillCategory.autoElectrician: return 'Fundi Umeme wa Gari';
      case SkillCategory.panelBeating: return 'Fundi Bati';
      case SkillCategory.sprayPainting: return 'Fundi Spray';
      case SkillCategory.hairstyling: return 'Ususi';
      case SkillCategory.barbering: return 'Kinyozi';
      case SkillCategory.nailTechnician: return 'Fundi Kucha';
      case SkillCategory.skincare: return 'Utunzaji Ngozi';
      case SkillCategory.makeup: return 'Mapambo';
      case SkillCategory.legal: return 'Sheria';
      case SkillCategory.medical: return 'Tiba';
      case SkillCategory.nursing: return 'Uuguzi';
      case SkillCategory.pharmacy: return 'Famasia';
      case SkillCategory.accounting: return 'Uhasibu';
      case SkillCategory.taxAdvisory: return 'Ushauri wa Kodi';
      case SkillCategory.realEstate: return 'Mali Isiyohamishika';
      case SkillCategory.propertyManagement: return 'Usimamizi Mali';
      case SkillCategory.homeInspection: return 'Ukaguzi Nyumba';
      case SkillCategory.interiorDesign: return 'Ubunifu wa Ndani';
      case SkillCategory.personalTraining: return 'Mazoezi Binafsi';
      case SkillCategory.nutrition: return 'Lishe';
      case SkillCategory.cooking: return 'Upishi';
      case SkillCategory.catering: return 'Upishi wa Hafla';
      case SkillCategory.baking: return 'Uokaji';
      case SkillCategory.eventPlanning: return 'Upangaji Hafla';
      case SkillCategory.photography: return 'Upigaji Picha';
      case SkillCategory.videography: return 'Upigaji Video';
      case SkillCategory.djing: return 'DJ';
      case SkillCategory.mc: return 'MC';
      case SkillCategory.tourGuide: return 'Kiongozi wa Utalii';
      case SkillCategory.travelAgent: return 'Wakala wa Safari';
      case SkillCategory.safariOperator: return 'Opereta wa Safari';
      case SkillCategory.businessConsulting: return 'Ushauri wa Biashara';
      case SkillCategory.hrConsulting: return 'Ushauri wa HR';
      case SkillCategory.careerCoaching: return 'Kocha wa Kazi';
    }
  }

  IconData get icon {
    switch (this) {
      case SkillCategory.plumbing: return Icons.plumbing_rounded;
      case SkillCategory.electrical: return Icons.electrical_services_rounded;
      case SkillCategory.carpentry: return Icons.carpenter_rounded;
      case SkillCategory.painting: return Icons.format_paint_rounded;
      case SkillCategory.welding: return Icons.construction_rounded;
      case SkillCategory.masonry: return Icons.domain_rounded;
      case SkillCategory.roofing: return Icons.roofing_rounded;
      case SkillCategory.tiling: return Icons.grid_on_rounded;
      case SkillCategory.solarInstallation: return Icons.solar_power_rounded;
      case SkillCategory.autoMechanic: return Icons.build_rounded;
      case SkillCategory.autoElectrician: return Icons.cable_rounded;
      case SkillCategory.panelBeating: return Icons.car_repair_rounded;
      case SkillCategory.sprayPainting: return Icons.format_paint_rounded;
      case SkillCategory.hairstyling: return Icons.content_cut_rounded;
      case SkillCategory.barbering: return Icons.content_cut_rounded;
      case SkillCategory.nailTechnician: return Icons.spa_rounded;
      case SkillCategory.skincare: return Icons.face_retouching_natural_rounded;
      case SkillCategory.makeup: return Icons.brush_rounded;
      case SkillCategory.legal: return Icons.gavel_rounded;
      case SkillCategory.medical: return Icons.medical_services_rounded;
      case SkillCategory.nursing: return Icons.local_hospital_rounded;
      case SkillCategory.pharmacy: return Icons.medication_rounded;
      case SkillCategory.accounting: return Icons.calculate_rounded;
      case SkillCategory.taxAdvisory: return Icons.receipt_long_rounded;
      case SkillCategory.realEstate: return Icons.home_work_rounded;
      case SkillCategory.propertyManagement: return Icons.apartment_rounded;
      case SkillCategory.homeInspection: return Icons.search_rounded;
      case SkillCategory.interiorDesign: return Icons.design_services_rounded;
      case SkillCategory.personalTraining: return Icons.fitness_center_rounded;
      case SkillCategory.nutrition: return Icons.restaurant_rounded;
      case SkillCategory.cooking: return Icons.soup_kitchen_rounded;
      case SkillCategory.catering: return Icons.dinner_dining_rounded;
      case SkillCategory.baking: return Icons.bakery_dining_rounded;
      case SkillCategory.eventPlanning: return Icons.event_rounded;
      case SkillCategory.photography: return Icons.camera_alt_rounded;
      case SkillCategory.videography: return Icons.videocam_rounded;
      case SkillCategory.djing: return Icons.headphones_rounded;
      case SkillCategory.mc: return Icons.mic_rounded;
      case SkillCategory.tourGuide: return Icons.tour_rounded;
      case SkillCategory.travelAgent: return Icons.flight_rounded;
      case SkillCategory.safariOperator: return Icons.nature_people_rounded;
      case SkillCategory.businessConsulting: return Icons.business_center_rounded;
      case SkillCategory.hrConsulting: return Icons.people_rounded;
      case SkillCategory.careerCoaching: return Icons.trending_up_rounded;
    }
  }

  String get domainModule {
    switch (this) {
      case SkillCategory.plumbing:
      case SkillCategory.electrical:
      case SkillCategory.carpentry:
      case SkillCategory.painting:
      case SkillCategory.welding:
      case SkillCategory.masonry:
      case SkillCategory.roofing:
      case SkillCategory.tiling:
      case SkillCategory.solarInstallation:
        return 'mafundi';
      case SkillCategory.autoMechanic:
      case SkillCategory.autoElectrician:
      case SkillCategory.panelBeating:
      case SkillCategory.sprayPainting:
        return 'service_garage';
      case SkillCategory.hairstyling:
      case SkillCategory.barbering:
      case SkillCategory.nailTechnician:
        return 'hair_nails';
      case SkillCategory.skincare:
      case SkillCategory.makeup:
        return 'skincare';
      case SkillCategory.legal:
        return 'lawyer';
      case SkillCategory.medical:
      case SkillCategory.nursing:
      case SkillCategory.pharmacy:
        return 'doctor';
      case SkillCategory.accounting:
      case SkillCategory.taxAdvisory:
      case SkillCategory.businessConsulting:
      case SkillCategory.hrConsulting:
      case SkillCategory.careerCoaching:
        return 'business';
      case SkillCategory.realEstate:
      case SkillCategory.propertyManagement:
      case SkillCategory.homeInspection:
      case SkillCategory.interiorDesign:
        return 'housing';
      case SkillCategory.personalTraining:
      case SkillCategory.nutrition:
        return 'fitness';
      case SkillCategory.cooking:
      case SkillCategory.catering:
      case SkillCategory.baking:
        return 'food';
      case SkillCategory.eventPlanning:
      case SkillCategory.photography:
      case SkillCategory.videography:
      case SkillCategory.djing:
      case SkillCategory.mc:
        return 'events';
      case SkillCategory.tourGuide:
      case SkillCategory.travelAgent:
      case SkillCategory.safariOperator:
        return 'travel';
    }
  }

  static SkillCategory? fromString(String? value) {
    if (value == null) return null;
    try {
      return SkillCategory.values.firstWhere(
        (e) => e.name == value || e.label.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== MODELS ====================

class TajirikaPartner {
  final int id;
  final int userId;
  final String name;
  final String? photo;
  final String? phone;
  final String? bio;
  final List<SkillCategory> skills;
  final List<SkillSpecialization> specializations;
  final PartnerTier tier;
  final VerificationStatus verifications;
  final PartnerServiceArea serviceArea;
  final List<PortfolioItem> portfolio;
  final double aggregateRating;
  final int jobsCompleted;
  final int responseTimeMinutes;
  final String? referralCode;
  final String? payoutAccount;
  final String? payoutMethod;
  final bool isActive;
  final DateTime? createdAt;

  TajirikaPartner({
    required this.id,
    required this.userId,
    required this.name,
    this.photo,
    this.phone,
    this.bio,
    this.skills = const [],
    this.specializations = const [],
    this.tier = PartnerTier.mwanafunzi,
    VerificationStatus? verifications,
    PartnerServiceArea? serviceArea,
    this.portfolio = const [],
    this.aggregateRating = 0.0,
    this.jobsCompleted = 0,
    this.responseTimeMinutes = 0,
    this.referralCode,
    this.payoutAccount,
    this.payoutMethod,
    this.isActive = false,
    this.createdAt,
  })  : verifications = verifications ?? VerificationStatus.empty(),
        serviceArea = serviceArea ?? PartnerServiceArea.empty();

  String get photoUrl => photo != null ? _buildStorageUrl(photo!) : '';

  factory TajirikaPartner.fromJson(Map<String, dynamic> json) {
    return TajirikaPartner(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      name: json['name'] as String? ?? '',
      photo: json['photo'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      skills: (json['skills'] as List?)
              ?.map((s) => SkillCategory.fromString(s as String?))
              .whereType<SkillCategory>()
              .toList() ??
          [],
      specializations: (json['specializations'] as List?)
              ?.map((s) => SkillSpecialization.fromJson(s))
              .toList() ??
          [],
      tier: PartnerTier.fromString(json['tier'] as String?),
      verifications: json['verifications'] != null
          ? VerificationStatus.fromJson(json['verifications'])
          : VerificationStatus.empty(),
      serviceArea: json['service_area'] != null
          ? PartnerServiceArea.fromJson(json['service_area'])
          : PartnerServiceArea.empty(),
      portfolio: (json['portfolio'] as List?)
              ?.map((p) => PortfolioItem.fromJson(p))
              .toList() ??
          [],
      aggregateRating: _parseDouble(json['aggregate_rating']),
      jobsCompleted: _parseInt(json['jobs_completed']),
      responseTimeMinutes: _parseInt(json['response_time_minutes']),
      referralCode: json['referral_code'] as String?,
      payoutAccount: json['payout_account'] as String?,
      payoutMethod: json['payout_method'] as String?,
      isActive: _parseBool(json['is_active']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class SkillSpecialization {
  final int id;
  final String categoryKey;
  final String name;
  final String nameSwahili;

  SkillSpecialization({
    required this.id,
    required this.categoryKey,
    required this.name,
    required this.nameSwahili,
  });

  factory SkillSpecialization.fromJson(Map<String, dynamic> json) {
    return SkillSpecialization(
      id: _parseInt(json['id']),
      categoryKey: json['category_key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameSwahili: json['name_sw'] as String? ?? '',
    );
  }
}

class VerificationStatus {
  final VerificationItem nida;
  final VerificationItem tin;
  final VerificationItem professional;
  final VerificationItem background;

  VerificationStatus({
    required this.nida,
    required this.tin,
    required this.professional,
    required this.background,
  });

  factory VerificationStatus.empty() {
    return VerificationStatus(
      nida: VerificationItem.empty('nida'),
      tin: VerificationItem.empty('tin'),
      professional: VerificationItem.empty('professional'),
      background: VerificationItem.empty('background'),
    );
  }

  String get overall {
    final items = [nida, tin, professional, background];
    final verified = items.where((i) => i.status == 'verified').length;
    if (verified == items.length) return 'verified';
    if (verified > 0) return 'partial';
    final submitted = items.where((i) => i.status == 'submitted').length;
    if (submitted > 0) return 'submitted';
    return 'pending';
  }

  List<VerificationItem> get asList => [nida, tin, professional, background];

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      nida: json['nida'] != null
          ? VerificationItem.fromJson(json['nida'])
          : VerificationItem.empty('nida'),
      tin: json['tin'] != null
          ? VerificationItem.fromJson(json['tin'])
          : VerificationItem.empty('tin'),
      professional: json['professional'] != null
          ? VerificationItem.fromJson(json['professional'])
          : VerificationItem.empty('professional'),
      background: json['background'] != null
          ? VerificationItem.fromJson(json['background'])
          : VerificationItem.empty('background'),
    );
  }
}

class VerificationItem {
  final String type;
  final String status; // pending, submitted, verified, failed, expired
  final String? number;
  final String? documentUrl;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;

  VerificationItem({
    required this.type,
    required this.status,
    this.number,
    this.documentUrl,
    this.submittedAt,
    this.verifiedAt,
    this.expiresAt,
    this.rejectionReason,
  });

  factory VerificationItem.empty(String type) {
    return VerificationItem(type: type, status: 'pending');
  }

  bool get isPending => status == 'pending';
  bool get isSubmitted => status == 'submitted';
  bool get isVerified => status == 'verified';
  bool get isFailed => status == 'failed';
  bool get isExpired => status == 'expired';
  bool get needsAction => isPending || isFailed || isExpired;

  String get typeLabel {
    switch (type) {
      case 'nida': return 'National ID (NIDA)';
      case 'tin': return 'Tax ID (TIN)';
      case 'professional': return 'Professional License';
      case 'background': return 'Background Check';
      default: return type;
    }
  }

  String get typeLabelSwahili {
    switch (type) {
      case 'nida': return 'Kitambulisho cha Taifa (NIDA)';
      case 'tin': return 'Namba ya Kodi (TIN)';
      case 'professional': return 'Leseni ya Kitaalamu';
      case 'background': return 'Ukaguzi wa Historia';
      default: return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Not Submitted';
      case 'submitted': return 'Under Review';
      case 'verified': return 'Verified';
      case 'failed': return 'Failed';
      case 'expired': return 'Expired';
      default: return status;
    }
  }

  String get statusLabelSwahili {
    switch (status) {
      case 'pending': return 'Haijawasilishwa';
      case 'submitted': return 'Inakaguliwa';
      case 'verified': return 'Imethibitishwa';
      case 'failed': return 'Imeshindwa';
      case 'expired': return 'Imeisha Muda';
      default: return status;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending': return Icons.radio_button_unchecked_rounded;
      case 'submitted': return Icons.hourglass_top_rounded;
      case 'verified': return Icons.check_circle_rounded;
      case 'failed': return Icons.cancel_rounded;
      case 'expired': return Icons.warning_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending': return const Color(0xFF9E9E9E);
      case 'submitted': return const Color(0xFF757575);
      case 'verified': return const Color(0xFF4CAF50);
      case 'failed': return const Color(0xFFF44336);
      case 'expired': return const Color(0xFFFF9800);
      default: return const Color(0xFF9E9E9E);
    }
  }

  factory VerificationItem.fromJson(Map<String, dynamic> json) {
    return VerificationItem(
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      number: json['number'] as String?,
      documentUrl: json['document_url'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}

class PartnerServiceArea {
  final List<int> regionIds;
  final List<int> districtIds;
  final List<int> wardIds;
  final List<String> regionNames;
  final List<String> districtNames;
  final List<String> wardNames;

  PartnerServiceArea({
    this.regionIds = const [],
    this.districtIds = const [],
    this.wardIds = const [],
    this.regionNames = const [],
    this.districtNames = const [],
    this.wardNames = const [],
  });

  factory PartnerServiceArea.empty() => PartnerServiceArea();

  bool get isEmpty => regionIds.isEmpty && districtIds.isEmpty && wardIds.isEmpty;

  String get displayText {
    if (wardNames.isNotEmpty) return wardNames.join(', ');
    if (districtNames.isNotEmpty) return districtNames.join(', ');
    if (regionNames.isNotEmpty) return regionNames.join(', ');
    return '';
  }

  factory PartnerServiceArea.fromJson(Map<String, dynamic> json) {
    return PartnerServiceArea(
      regionIds: (json['region_ids'] as List?)?.map((e) => _parseInt(e)).toList() ?? [],
      districtIds: (json['district_ids'] as List?)?.map((e) => _parseInt(e)).toList() ?? [],
      wardIds: (json['ward_ids'] as List?)?.map((e) => _parseInt(e)).toList() ?? [],
      regionNames: (json['region_names'] as List?)?.cast<String>() ?? [],
      districtNames: (json['district_names'] as List?)?.cast<String>() ?? [],
      wardNames: (json['ward_names'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'region_ids': regionIds,
        'district_ids': districtIds,
        'ward_ids': wardIds,
      };
}

class PortfolioItem {
  final int id;
  final String type; // photo, video
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final SkillCategory? skillCategory;
  final DateTime? createdAt;

  PortfolioItem({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.skillCategory,
    this.createdAt,
  });

  String get displayUrl => _buildStorageUrl(url);
  String get displayThumbnailUrl => thumbnailUrl != null ? _buildStorageUrl(thumbnailUrl!) : displayUrl;
  bool get isVideo => type == 'video';

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: _parseInt(json['id']),
      type: json['type'] as String? ?? 'photo',
      url: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      skillCategory: SkillCategory.fromString(json['skill_category'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class TrainingCourse {
  final int id;
  final String title;
  final String titleSwahili;
  final String description;
  final String descriptionSwahili;
  final SkillCategory? category;
  final int durationMinutes;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool isRequired;
  final double progress;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? certificateUrl;

  TrainingCourse({
    required this.id,
    required this.title,
    this.titleSwahili = '',
    this.description = '',
    this.descriptionSwahili = '',
    this.category,
    this.durationMinutes = 0,
    this.videoUrl,
    this.thumbnailUrl,
    this.isRequired = false,
    this.progress = 0.0,
    this.isCompleted = false,
    this.completedAt,
    this.certificateUrl,
  });

  String get displayThumbnail => thumbnailUrl != null ? _buildStorageUrl(thumbnailUrl!) : '';
  String get durationText {
    if (durationMinutes < 60) return '$durationMinutes min';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  factory TrainingCourse.fromJson(Map<String, dynamic> json) {
    return TrainingCourse(
      id: _parseInt(json['id']),
      title: json['title'] as String? ?? '',
      titleSwahili: json['title_sw'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionSwahili: json['description_sw'] as String? ?? '',
      category: SkillCategory.fromString(json['category'] as String?),
      durationMinutes: _parseInt(json['duration_minutes']),
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isRequired: _parseBool(json['is_required']),
      progress: _parseDouble(json['progress']),
      isCompleted: _parseBool(json['is_completed']),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      certificateUrl: json['certificate_url'] as String?,
    );
  }
}

class Referral {
  final int id;
  final int referrerId;
  final int referredId;
  final String referredName;
  final String? referredPhoto;
  final List<SkillCategory> referredSkills;
  final String status; // pending, registered, verified
  final double bonus;
  final DateTime createdAt;

  Referral({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.referredName,
    this.referredPhoto,
    this.referredSkills = const [],
    required this.status,
    this.bonus = 0.0,
    required this.createdAt,
  });

  String get photoUrl => referredPhoto != null ? _buildStorageUrl(referredPhoto!) : '';

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'registered': return 'Registered';
      case 'verified': return 'Verified';
      default: return status;
    }
  }

  String get statusLabelSwahili {
    switch (status) {
      case 'pending': return 'Inasubiri';
      case 'registered': return 'Amesajiliwa';
      case 'verified': return 'Amethibitishwa';
      default: return status;
    }
  }

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: _parseInt(json['id']),
      referrerId: _parseInt(json['referrer_id']),
      referredId: _parseInt(json['referred_id']),
      referredName: json['referred_name'] as String? ?? '',
      referredPhoto: json['referred_photo'] as String?,
      referredSkills: (json['referred_skills'] as List?)
              ?.map((s) => SkillCategory.fromString(s as String?))
              .whereType<SkillCategory>()
              .toList() ??
          [],
      status: json['status'] as String? ?? 'pending',
      bonus: _parseDouble(json['bonus']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class TierProgress {
  final PartnerTier currentTier;
  final PartnerTier? nextTier;
  final int jobsCompleted;
  final int jobsNeeded;
  final double currentRating;
  final double ratingNeeded;
  final int trainingCompleted;
  final int trainingNeeded;
  final List<String> verificationsPending;

  TierProgress({
    required this.currentTier,
    this.nextTier,
    this.jobsCompleted = 0,
    this.jobsNeeded = 0,
    this.currentRating = 0.0,
    this.ratingNeeded = 0.0,
    this.trainingCompleted = 0,
    this.trainingNeeded = 0,
    this.verificationsPending = const [],
  });

  double get progress {
    if (nextTier == null) return 1.0;
    int met = 0;
    int total = 0;
    if (jobsNeeded > 0) {
      total++;
      if (jobsCompleted >= jobsNeeded) met++;
    }
    if (ratingNeeded > 0) {
      total++;
      if (currentRating >= ratingNeeded) met++;
    }
    if (trainingNeeded > 0) {
      total++;
      if (trainingCompleted >= trainingNeeded) met++;
    }
    if (verificationsPending.isNotEmpty) {
      total++;
    }
    return total > 0 ? met / total : 0.0;
  }

  factory TierProgress.fromJson(Map<String, dynamic> json) {
    return TierProgress(
      currentTier: PartnerTier.fromString(json['current_tier'] as String?),
      nextTier: json['next_tier'] != null
          ? PartnerTier.fromString(json['next_tier'] as String?)
          : null,
      jobsCompleted: _parseInt(json['jobs_completed']),
      jobsNeeded: _parseInt(json['jobs_needed']),
      currentRating: _parseDouble(json['current_rating']),
      ratingNeeded: _parseDouble(json['rating_needed']),
      trainingCompleted: _parseInt(json['training_completed']),
      trainingNeeded: _parseInt(json['training_needed']),
      verificationsPending:
          (json['verifications_pending'] as List?)?.cast<String>() ?? [],
    );
  }
}

class PartnerEarnings {
  final double totalEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double pendingPayout;
  final Map<String, double> byModule;
  final List<Payout> recentPayouts;

  PartnerEarnings({
    this.totalEarnings = 0.0,
    this.weeklyEarnings = 0.0,
    this.monthlyEarnings = 0.0,
    this.pendingPayout = 0.0,
    this.byModule = const {},
    this.recentPayouts = const [],
  });

  factory PartnerEarnings.fromJson(Map<String, dynamic> json) {
    final moduleMap = <String, double>{};
    if (json['by_module'] is Map) {
      (json['by_module'] as Map).forEach((key, value) {
        moduleMap[key.toString()] = _parseDouble(value);
      });
    }
    return PartnerEarnings(
      totalEarnings: _parseDouble(json['total_earnings']),
      weeklyEarnings: _parseDouble(json['weekly_earnings']),
      monthlyEarnings: _parseDouble(json['monthly_earnings']),
      pendingPayout: _parseDouble(json['pending_payout']),
      byModule: moduleMap,
      recentPayouts: (json['recent_payouts'] as List?)
              ?.map((p) => Payout.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class Payout {
  final int id;
  final double amount;
  final String status;
  final String method;
  final DateTime? paidAt;
  final DateTime createdAt;

  Payout({
    required this.id,
    required this.amount,
    required this.status,
    required this.method,
    this.paidAt,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'processing': return 'Processing';
      case 'completed': return 'Completed';
      case 'failed': return 'Failed';
      default: return status;
    }
  }

  String get statusLabelSwahili {
    switch (status) {
      case 'pending': return 'Inasubiri';
      case 'processing': return 'Inachakatwa';
      case 'completed': return 'Imekamilika';
      case 'failed': return 'Imeshindwa';
      default: return status;
    }
  }

  String get methodLabel {
    switch (method) {
      case 'mpesa': return 'M-Pesa';
      case 'tigopesa': return 'Tigo Pesa';
      case 'airtelmoney': return 'Airtel Money';
      case 'bank': return 'Bank Transfer';
      default: return method;
    }
  }

  IconData get methodIcon {
    switch (method) {
      case 'mpesa': return Icons.phone_android_rounded;
      case 'tigopesa': return Icons.phone_android_rounded;
      case 'airtelmoney': return Icons.phone_android_rounded;
      case 'bank': return Icons.account_balance_rounded;
      default: return Icons.payment_rounded;
    }
  }

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: _parseInt(json['id']),
      amount: _parseDouble(json['amount']),
      status: json['status'] as String? ?? 'pending',
      method: json['method'] as String? ?? 'mpesa',
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class PartnerStats {
  final int jobsCompleted;
  final double averageRating;
  final int responseTimeMinutes;
  final double repeatCustomerRate;
  final List<String> activeModules;

  PartnerStats({
    this.jobsCompleted = 0,
    this.averageRating = 0.0,
    this.responseTimeMinutes = 0,
    this.repeatCustomerRate = 0.0,
    this.activeModules = const [],
  });

  factory PartnerStats.fromJson(Map<String, dynamic> json) {
    return PartnerStats(
      jobsCompleted: _parseInt(json['jobs_completed']),
      averageRating: _parseDouble(json['average_rating']),
      responseTimeMinutes: _parseInt(json['response_time_minutes']),
      repeatCustomerRate: _parseDouble(json['repeat_customer_rate']),
      activeModules: (json['active_modules'] as List?)?.cast<String>() ?? [],
    );
  }
}

class MentorshipMatch {
  final int id;
  final int mentorId;
  final String mentorName;
  final String? mentorPhoto;
  final PartnerTier mentorTier;
  final int menteeId;
  final String menteeName;
  final String? menteePhoto;
  final String status;
  final DateTime createdAt;

  MentorshipMatch({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    this.mentorPhoto,
    this.mentorTier = PartnerTier.bingwa,
    required this.menteeId,
    required this.menteeName,
    this.menteePhoto,
    required this.status,
    required this.createdAt,
  });

  factory MentorshipMatch.fromJson(Map<String, dynamic> json) {
    return MentorshipMatch(
      id: _parseInt(json['id']),
      mentorId: _parseInt(json['mentor_id']),
      mentorName: json['mentor_name'] as String? ?? '',
      mentorPhoto: json['mentor_photo'] as String?,
      mentorTier: PartnerTier.fromString(json['mentor_tier'] as String?),
      menteeId: _parseInt(json['mentee_id']),
      menteeName: json['mentee_name'] as String? ?? '',
      menteePhoto: json['mentee_photo'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class AvailabilitySlot {
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  AvailabilitySlot({
    required this.dayOfWeek,
    this.startTime = '08:00',
    this.endTime = '17:00',
    this.isAvailable = true,
  });

  String get dayLabel {
    switch (dayOfWeek) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String get dayLabelSwahili {
    switch (dayOfWeek) {
      case 1: return 'Jumatatu';
      case 2: return 'Jumanne';
      case 3: return 'Jumatano';
      case 4: return 'Alhamisi';
      case 5: return 'Ijumaa';
      case 6: return 'Jumamosi';
      case 7: return 'Jumapili';
      default: return '';
    }
  }

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      dayOfWeek: _parseInt(json['day_of_week']),
      startTime: json['start_time'] as String? ?? '08:00',
      endTime: json['end_time'] as String? ?? '17:00',
      isAvailable: _parseBool(json['is_available'], true),
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_available': isAvailable,
      };
}

class ReferralStats {
  final String referralCode;
  final int totalReferred;
  final int registered;
  final int verified;
  final double totalBonusEarned;

  ReferralStats({
    required this.referralCode,
    this.totalReferred = 0,
    this.registered = 0,
    this.verified = 0,
    this.totalBonusEarned = 0.0,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      referralCode: json['referral_code'] as String? ?? '',
      totalReferred: _parseInt(json['total_referred']),
      registered: _parseInt(json['registered']),
      verified: _parseInt(json['verified']),
      totalBonusEarned: _parseDouble(json['total_bonus_earned']),
    );
  }
}

class Badge {
  final int id;
  final String name;
  final String nameSwahili;
  final String? iconUrl;
  final String description;
  final DateTime? earnedAt;

  Badge({
    required this.id,
    required this.name,
    this.nameSwahili = '',
    this.iconUrl,
    this.description = '',
    this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? '',
      nameSwahili: json['name_sw'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      description: json['description'] as String? ?? '',
      earnedAt: json['earned_at'] != null
          ? DateTime.tryParse(json['earned_at'].toString())
          : null,
    );
  }
}

// ==================== RESULT CLASSES ====================

class TajirikaResult {
  final bool success;
  final String? message;

  TajirikaResult({required this.success, this.message});
}

class PartnerResult {
  final bool success;
  final TajirikaPartner? partner;
  final String? message;

  PartnerResult({required this.success, this.partner, this.message});
}

class PortfolioListResult {
  final bool success;
  final List<PortfolioItem> items;
  final String? message;

  PortfolioListResult({required this.success, this.items = const [], this.message});
}

class TrainingListResult {
  final bool success;
  final List<TrainingCourse> courses;
  final String? message;

  TrainingListResult({required this.success, this.courses = const [], this.message});
}

class ReferralListResult {
  final bool success;
  final List<Referral> referrals;
  final String? message;

  ReferralListResult({required this.success, this.referrals = const [], this.message});
}

class PayoutListResult {
  final bool success;
  final List<Payout> payouts;
  final String? message;

  PayoutListResult({required this.success, this.payouts = const [], this.message});
}

class BadgeListResult {
  final bool success;
  final List<Badge> badges;
  final String? message;

  BadgeListResult({required this.success, this.badges = const [], this.message});
}
