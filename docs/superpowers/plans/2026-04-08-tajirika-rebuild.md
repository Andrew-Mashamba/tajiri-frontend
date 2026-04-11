# Tajirika Module — Full Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scrap and rebuild `lib/tajirika/` as TAJIRI's partner program hub — registration, verification, certification, portfolio, training, referrals, earnings, and analytics for skilled professionals.

**Architecture:** Flutter module with static-method service, single models file, 10 pages, 10 widgets. Follows TAJIRI conventions: setState, monochrome Material 3, bilingual Swahili/English, SafeArea, 48dp touch targets. No external state management.

**Tech Stack:** Flutter/Dart, http package, Hive (LocalStorageService), existing PhotoService/VideoUploadService for media uploads.

**Spec:** `docs/superpowers/specs/2026-04-08-tajirika-rebuild-design.md`
**Design doc:** `docs/modules/tajirika.md`

---

## Task 1: Delete Old Code and Create Models

**Files:**
- Delete: `lib/tajirika/` (entire directory)
- Create: `lib/tajirika/models/tajirika_models.dart`

- [ ] **Step 1: Delete old tajirika directory**

```bash
rm -rf lib/tajirika/
mkdir -p lib/tajirika/models lib/tajirika/services lib/tajirika/pages lib/tajirika/widgets
```

- [ ] **Step 2: Create models file**

Create `lib/tajirika/models/tajirika_models.dart`:

```dart
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
      case SkillCategory.sprayPainting: return Icons.spray_rounded;
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
```

- [ ] **Step 3: Verify models file compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/models/tajirika_models.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/tajirika/models/
git commit -m "feat(tajirika): add complete models for partner program rebuild"
```

---

## Task 2: Service Layer

**Files:**
- Create: `lib/tajirika/services/tajirika_service.dart`

- [ ] **Step 1: Create service file**

Create `lib/tajirika/services/tajirika_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/tajirika_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String message) {
  debugPrint('[TajirikaService] $message');
}

class TajirikaService {
  // ==================== REGISTRATION & PROFILE ====================

  static Future<PartnerResult> registerPartner(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/partners'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 && body['success'] == true) {
        return PartnerResult(
          success: true,
          partner: TajirikaPartner.fromJson(body['data']),
        );
      }
      return PartnerResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kusajili',
      );
    } catch (e) {
      _log('registerPartner error: $e');
      return PartnerResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<PartnerResult> getMyPartnerProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/me'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerResult(
          success: true,
          partner: TajirikaPartner.fromJson(body['data']),
        );
      }
      if (response.statusCode == 404) {
        return PartnerResult(success: false, message: 'not_registered');
      }
      return PartnerResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kupakia',
      );
    } catch (e) {
      _log('getMyPartnerProfile error: $e');
      return PartnerResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<PartnerResult> getPartnerProfile(
    String token,
    int partnerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/$partnerId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerResult(
          success: true,
          partner: TajirikaPartner.fromJson(body['data']),
        );
      }
      return PartnerResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kupakia',
      );
    } catch (e) {
      _log('getPartnerProfile error: $e');
      return PartnerResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<PartnerResult> updatePartnerProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerResult(
          success: true,
          partner: TajirikaPartner.fromJson(body['data']),
        );
      }
      return PartnerResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kubadilisha',
      );
    } catch (e) {
      _log('updatePartnerProfile error: $e');
      return PartnerResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> updateServiceArea(
    String token,
    List<int> regionIds,
    List<int> districtIds,
    List<int> wardIds,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me/service-area'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'region_ids': regionIds,
          'district_ids': districtIds,
          'ward_ids': wardIds,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kubadilisha eneo',
      );
    } catch (e) {
      _log('updateServiceArea error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> updateAvailability(
    String token,
    List<AvailabilitySlot> schedule,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me/availability'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'slots': schedule.map((s) => s.toJson()).toList(),
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kubadilisha ratiba',
      );
    } catch (e) {
      _log('updateAvailability error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> updatePayoutAccount(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me/payout-account'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kubadilisha akaunti',
      );
    } catch (e) {
      _log('updatePayoutAccount error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  // ==================== VERIFICATION ====================

  static Future<TajirikaResult> submitNidaVerification(
    String token,
    String nidaNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/verifications/nida'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'nida_number': nidaNumber}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kuwasilisha NIDA',
      );
    } catch (e) {
      _log('submitNidaVerification error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> submitTinVerification(
    String token,
    String tinNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/verifications/tin'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'tin_number': tinNumber}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kuwasilisha TIN',
      );
    } catch (e) {
      _log('submitTinVerification error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> submitProfessionalLicense(
    String token,
    String licenseType,
    File file,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/tajirika/verifications/professional'),
      );
      request.headers.addAll(ApiConfig.authHeaders(token));
      request.fields['license_type'] = licenseType;
      request.files.add(
        await http.MultipartFile.fromPath('document', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kuwasilisha leseni',
      );
    } catch (e) {
      _log('submitProfessionalLicense error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> submitBackgroundCheck(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/verifications/background'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kuwasilisha',
      );
    } catch (e) {
      _log('submitBackgroundCheck error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<VerificationStatus> getVerificationStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/verifications'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return VerificationStatus.fromJson(body['data']);
      }
      return VerificationStatus.empty();
    } catch (e) {
      _log('getVerificationStatus error: $e');
      return VerificationStatus.empty();
    }
  }

  static Future<TajirikaResult> submitPeerVouch(
    String token,
    int partnerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/partners/$partnerId/vouch'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa',
      );
    } catch (e) {
      _log('submitPeerVouch error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  // ==================== SKILLS & CERTIFICATION ====================

  static Future<TajirikaResult> updateSkills(
    String token,
    List<String> skills,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me/skills'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'skills': skills}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kubadilisha ujuzi',
      );
    } catch (e) {
      _log('updateSkills error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> submitSkillTest(
    String token,
    String categoryKey,
    File file,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/tajirika/skills/test'),
      );
      request.headers.addAll(ApiConfig.authHeaders(token));
      request.fields['category'] = categoryKey;
      request.files.add(
        await http.MultipartFile.fromPath('video', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kuwasilisha mtihani',
      );
    } catch (e) {
      _log('submitSkillTest error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TierProgress> getTierProgress(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/me/tier-progress'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TierProgress.fromJson(body['data']);
      }
      return TierProgress(currentTier: PartnerTier.mwanafunzi);
    } catch (e) {
      _log('getTierProgress error: $e');
      return TierProgress(currentTier: PartnerTier.mwanafunzi);
    }
  }

  static Future<BadgeListResult> getBadges(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/me/badges'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final badges = (body['data'] as List)
            .map((b) => Badge.fromJson(b))
            .toList();
        return BadgeListResult(success: true, badges: badges);
      }
      return BadgeListResult(success: false);
    } catch (e) {
      _log('getBadges error: $e');
      return BadgeListResult(success: false, message: 'Hitilafu: $e');
    }
  }

  // ==================== PORTFOLIO ====================

  static Future<PortfolioListResult> getPortfolio(
    String token,
    int partnerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/$partnerId/portfolio'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .map((p) => PortfolioItem.fromJson(p))
            .toList();
        return PortfolioListResult(success: true, items: items);
      }
      return PortfolioListResult(success: false);
    } catch (e) {
      _log('getPortfolio error: $e');
      return PortfolioListResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> uploadPortfolioItem(
    String token,
    File file,
    String? caption,
    String? skillCategory,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/tajirika/portfolio'),
      );
      request.headers.addAll(ApiConfig.authHeaders(token));
      if (caption != null) request.fields['caption'] = caption;
      if (skillCategory != null) request.fields['skill_category'] = skillCategory;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kupakia',
      );
    } catch (e) {
      _log('uploadPortfolioItem error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> deletePortfolioItem(
    String token,
    int itemId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tajirika/portfolio/$itemId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kufuta',
      );
    } catch (e) {
      _log('deletePortfolioItem error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  // ==================== TRAINING ====================

  static Future<TrainingListResult> getTrainingCourses(
    String token, {
    String? category,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (category != null) params['category'] = category;

      final uri = Uri.parse('$_baseUrl/tajirika/training')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final courses = (body['data'] as List)
            .map((c) => TrainingCourse.fromJson(c))
            .toList();
        return TrainingListResult(success: true, courses: courses);
      }
      return TrainingListResult(success: false);
    } catch (e) {
      _log('getTrainingCourses error: $e');
      return TrainingListResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<TajirikaResult> updateCourseProgress(
    String token,
    int courseId,
    double progress,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/training/$courseId/progress'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'progress': progress}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(success: false);
    } catch (e) {
      _log('updateCourseProgress error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<List<MentorshipMatch>> getMentorshipMatches(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/mentorship'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return (body['data'] as List)
            .map((m) => MentorshipMatch.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      _log('getMentorshipMatches error: $e');
      return [];
    }
  }

  // ==================== REFERRALS ====================

  static Future<ReferralListResult> getReferrals(
    String token, {
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/referrals?page=$page'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final referrals = (body['data'] as List)
            .map((r) => Referral.fromJson(r))
            .toList();
        return ReferralListResult(success: true, referrals: referrals);
      }
      return ReferralListResult(success: false);
    } catch (e) {
      _log('getReferrals error: $e');
      return ReferralListResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<ReferralStats> getReferralStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/referrals/stats'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return ReferralStats.fromJson(body['data']);
      }
      return ReferralStats(referralCode: '');
    } catch (e) {
      _log('getReferralStats error: $e');
      return ReferralStats(referralCode: '');
    }
  }

  // ==================== EARNINGS & ANALYTICS ====================

  static Future<PartnerEarnings> getEarnings(
    String token, {
    String period = 'monthly',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/earnings?period=$period'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerEarnings.fromJson(body['data']);
      }
      return PartnerEarnings();
    } catch (e) {
      _log('getEarnings error: $e');
      return PartnerEarnings();
    }
  }

  static Future<Map<String, double>> getEarningsByModule(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/earnings/by-module'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final map = <String, double>{};
        (body['data'] as Map).forEach((key, value) {
          map[key.toString()] = _parseDouble(value);
        });
        return map;
      }
      return {};
    } catch (e) {
      _log('getEarningsByModule error: $e');
      return {};
    }
  }

  static Future<TajirikaResult> requestPayout(
    String token,
    double amount,
    String method,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/payouts'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'amount': amount, 'method': method}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Imeshindwa kuomba malipo',
      );
    } catch (e) {
      _log('requestPayout error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<PayoutListResult> getPayoutHistory(
    String token, {
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/payouts?page=$page'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final payouts = (body['data'] as List)
            .map((p) => Payout.fromJson(p))
            .toList();
        return PayoutListResult(success: true, payouts: payouts);
      }
      return PayoutListResult(success: false);
    } catch (e) {
      _log('getPayoutHistory error: $e');
      return PayoutListResult(success: false, message: 'Hitilafu: $e');
    }
  }

  static Future<PartnerStats> getPartnerStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/me/stats'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerStats.fromJson(body['data']);
      }
      return PartnerStats();
    } catch (e) {
      _log('getPartnerStats error: $e');
      return PartnerStats();
    }
  }

  // ==================== PARTNER DISCOVERY (for domain modules) ====================

  static Future<List<TajirikaPartner>> searchPartners(
    String token, {
    List<String>? skills,
    int? regionId,
    String? tier,
    double? minRating,
    bool? available,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (skills != null && skills.isNotEmpty) params['skills'] = skills.join(',');
      if (regionId != null) params['region_id'] = regionId.toString();
      if (tier != null) params['tier'] = tier;
      if (minRating != null) params['min_rating'] = minRating.toString();
      if (available != null) params['available'] = available.toString();

      final uri = Uri.parse('$_baseUrl/tajirika/partners')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return (body['data'] as List)
            .map((p) => TajirikaPartner.fromJson(p))
            .toList();
      }
      return [];
    } catch (e) {
      _log('searchPartners error: $e');
      return [];
    }
  }

  static Future<TajirikaResult> reportJobCompleted(
    String token,
    int partnerId,
    String module,
    String jobId,
    double rating,
    double earnings,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/partners/$partnerId/job-completed'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'module': module,
          'job_id': jobId,
          'rating': rating,
          'earnings': earnings,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(success: false);
    } catch (e) {
      _log('reportJobCompleted error: $e');
      return TajirikaResult(success: false, message: 'Hitilafu: $e');
    }
  }
}
```

- [ ] **Step 2: Verify service compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/services/tajirika_service.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/tajirika/services/
git commit -m "feat(tajirika): add complete service layer for partner program"
```

---

## Task 3: All Widgets

**Files:**
- Create: `lib/tajirika/widgets/tier_badge.dart`
- Create: `lib/tajirika/widgets/verification_step_card.dart`
- Create: `lib/tajirika/widgets/skill_category_chip.dart`
- Create: `lib/tajirika/widgets/partner_stat_card.dart`
- Create: `lib/tajirika/widgets/training_course_card.dart`
- Create: `lib/tajirika/widgets/referral_card.dart`
- Create: `lib/tajirika/widgets/portfolio_item_card.dart`
- Create: `lib/tajirika/widgets/tier_progress_bar.dart`
- Create: `lib/tajirika/widgets/earnings_module_breakdown.dart`
- Create: `lib/tajirika/widgets/badge_chip.dart`

- [ ] **Step 1: Create all 10 widget files**

Each widget is a focused StatelessWidget following TAJIRI's monochrome Material 3 pattern. Create all 10 files as specified in the spec at `docs/superpowers/specs/2026-04-08-tajirika-rebuild-design.md` under "Widget Specifications".

Key conventions for all widgets:
- Import `package:flutter/material.dart` and `../models/tajirika_models.dart`
- Use `const` constructors with `super.key`
- Monochrome color scheme: primary `Color(0xFF1A1A1A)`, secondary `Color(0xFF666666)`, bg `Color(0xFFFAFAFA)`
- `mainAxisSize: MainAxisSize.min` for row/column widgets
- `maxLines` + `TextOverflow.ellipsis` on dynamic text
- Bilingual support via `isSwahili` parameter or direct Swahili/English getters on model enums

**tier_badge.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class TierBadge extends StatelessWidget {
  final PartnerTier tier;
  final double fontSize;
  final bool showIcon;

  const TierBadge({
    super.key,
    required this.tier,
    this.fontSize = 11,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tier.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(tier.icon, color: Colors.white, size: fontSize + 3),
            const SizedBox(width: 4),
          ],
          Text(
            tier.labelSwahili,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
```

**verification_step_card.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class VerificationStepCard extends StatelessWidget {
  final VerificationItem item;
  final bool isSwahili;
  final VoidCallback? onAction;

  const VerificationStepCard({
    super.key,
    required this.item,
    this.isSwahili = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(item.statusIcon, color: item.statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili ? item.typeLabelSwahili : item.typeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isSwahili ? item.statusLabelSwahili : item.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.rejectionReason!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFF44336)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (item.needsAction && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(48, 36),
              ),
              child: Text(
                item.isPending
                    ? (isSwahili ? 'Wasilisha' : 'Submit')
                    : (isSwahili ? 'Wasilisha Tena' : 'Resubmit'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
```

**skill_category_chip.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class SkillCategoryChip extends StatelessWidget {
  final SkillCategory category;
  final bool selected;
  final bool isSwahili;
  final VoidCallback? onTap;

  const SkillCategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.isSwahili = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1A1A1A) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: selected ? Colors.white : const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Text(
              isSwahili ? category.labelSwahili : category.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**partner_stat_card.dart:**
```dart
import 'package:flutter/material.dart';

class PartnerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const PartnerStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF666666)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

**training_course_card.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class TrainingCourseCard extends StatelessWidget {
  final TrainingCourse course;
  final bool isSwahili;
  final VoidCallback? onTap;

  const TrainingCourseCard({
    super.key,
    required this.course,
    this.isSwahili = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade200,
                child: course.displayThumbnail.isNotEmpty
                    ? Image.network(
                        course.displayThumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF666666)),
                      )
                    : const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF666666)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isSwahili && course.titleSwahili.isNotEmpty
                              ? course.titleSwahili
                              : course.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (course.isRequired)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSwahili ? 'Lazima' : 'Required',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.durationText,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                  if (course.progress > 0 && !course.isCompleted) ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: course.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A1A)),
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                  if (course.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 4),
                          Text(
                            isSwahili ? 'Imekamilika' : 'Completed',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}
```

**referral_card.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';
import 'skill_category_chip.dart';

class ReferralCard extends StatelessWidget {
  final Referral referral;
  final bool isSwahili;

  const ReferralCard({
    super.key,
    required this.referral,
    this.isSwahili = false,
  });

  Color get _statusColor {
    switch (referral.status) {
      case 'verified': return const Color(0xFF4CAF50);
      case 'registered': return const Color(0xFF1A1A1A);
      default: return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: referral.photoUrl.isNotEmpty
                ? NetworkImage(referral.photoUrl)
                : null,
            child: referral.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded, color: Color(0xFF9E9E9E))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.referredName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (referral.referredSkills.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    referral.referredSkills
                        .map((s) => isSwahili ? s.labelSwahili : s.label)
                        .join(', '),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSwahili ? referral.statusLabelSwahili : referral.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
              if (referral.bonus > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'TZS ${referral.bonus.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
```

**portfolio_item_card.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class PortfolioItemCard extends StatelessWidget {
  final PortfolioItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PortfolioItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.grey.shade200,
              child: Image.network(
                item.displayThumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_rounded, color: Color(0xFF9E9E9E), size: 32),
                ),
              ),
            ),
            if (item.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            if (item.caption != null && item.caption!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    item.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (item.skillCategory != null)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.skillCategory!.icon, size: 10, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(
                        item.skillCategory!.labelSwahili,
                        style: const TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

**tier_progress_bar.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';
import 'tier_badge.dart';

class TierProgressBar extends StatelessWidget {
  final TierProgress progress;
  final bool isSwahili;

  const TierProgressBar({
    super.key,
    required this.progress,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TierBadge(tier: progress.currentTier),
              if (progress.nextTier != null) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(progress.currentTier.color),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                TierBadge(tier: progress.nextTier!),
              ] else
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    isSwahili ? 'Kiwango cha juu!' : 'Highest tier!',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (progress.nextTier != null) ...[
            const SizedBox(height: 16),
            _buildRequirement(
              Icons.work_rounded,
              isSwahili ? 'Kazi zilizokamilika' : 'Jobs completed',
              '${progress.jobsCompleted}/${progress.jobsNeeded}',
              progress.jobsCompleted >= progress.jobsNeeded,
            ),
            const SizedBox(height: 8),
            _buildRequirement(
              Icons.star_rounded,
              isSwahili ? 'Kiwango cha ukadiriaji' : 'Rating',
              '${progress.currentRating.toStringAsFixed(1)}/${progress.ratingNeeded.toStringAsFixed(1)}',
              progress.currentRating >= progress.ratingNeeded,
            ),
            const SizedBox(height: 8),
            _buildRequirement(
              Icons.school_rounded,
              isSwahili ? 'Mafunzo yaliyokamilika' : 'Training completed',
              '${progress.trainingCompleted}/${progress.trainingNeeded}',
              progress.trainingCompleted >= progress.trainingNeeded,
            ),
            if (progress.verificationsPending.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRequirement(
                Icons.verified_rounded,
                isSwahili ? 'Uthibitisho unaohitajika' : 'Verifications needed',
                progress.verificationsPending.join(', '),
                false,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRequirement(IconData icon, String label, String value, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: met ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: met ? const Color(0xFF4CAF50) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
```

**earnings_module_breakdown.dart:**
```dart
import 'package:flutter/material.dart';

class EarningsModuleBreakdown extends StatelessWidget {
  final Map<String, double> byModule;

  const EarningsModuleBreakdown({super.key, required this.byModule});

  static const Map<String, String> _moduleLabels = {
    'mafundi': 'Mafundi',
    'hair_nails': 'Hair & Nails',
    'skincare': 'Skin Care',
    'lawyer': 'Wakili',
    'housing': 'Nyumba',
    'doctor': 'Daktari',
    'service_garage': 'Karakana',
    'fitness': 'Mazoezi',
    'food': 'Chakula',
    'events': 'Hafla',
    'travel': 'Safari',
    'business': 'Biashara',
  };

  static const Map<String, IconData> _moduleIcons = {
    'mafundi': Icons.construction_rounded,
    'hair_nails': Icons.content_cut_rounded,
    'skincare': Icons.face_retouching_natural_rounded,
    'lawyer': Icons.gavel_rounded,
    'housing': Icons.home_work_rounded,
    'doctor': Icons.medical_services_rounded,
    'service_garage': Icons.car_repair_rounded,
    'fitness': Icons.fitness_center_rounded,
    'food': Icons.restaurant_rounded,
    'events': Icons.event_rounded,
    'travel': Icons.flight_rounded,
    'business': Icons.business_center_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (byModule.isEmpty) return const SizedBox.shrink();

    final total = byModule.values.fold(0.0, (sum, v) => sum + v);
    final sorted = byModule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.map((entry) {
        final fraction = total > 0 ? entry.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                _moduleIcons[entry.key] ?? Icons.work_rounded,
                size: 18,
                color: const Color(0xFF666666),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  _moduleLabels[entry.key] ?? entry.key,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A1A)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  'TZS ${entry.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
```

**badge_chip.dart:**
```dart
import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class BadgeChip extends StatelessWidget {
  final Badge badge;
  final bool isSwahili;

  const BadgeChip({
    super.key,
    required this.badge,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Image.network(
                badge.iconUrl!,
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1A1A1A)),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1A1A1A)),
            ),
          Text(
            isSwahili && badge.nameSwahili.isNotEmpty ? badge.nameSwahili : badge.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify widgets compile**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/widgets/
```

- [ ] **Step 3: Commit**

```bash
git add lib/tajirika/widgets/
git commit -m "feat(tajirika): add all 10 partner program widgets"
```

---

## Task 4: Module Entry Point + Partner Dashboard

**Files:**
- Create: `lib/tajirika/tajirika_module.dart`
- Create: `lib/tajirika/pages/tajirika_home_page.dart`

- [ ] **Step 1: Create module entry point**

Create `lib/tajirika/tajirika_module.dart`:

```dart
import 'package:flutter/material.dart';
import 'pages/tajirika_home_page.dart';

class TajirikaModule extends StatelessWidget {
  const TajirikaModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TajirikaHomePage();
  }
}
```

- [ ] **Step 2: Create Partner Dashboard page**

Create `lib/tajirika/pages/tajirika_home_page.dart`:

```dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/tier_badge.dart';
import '../widgets/partner_stat_card.dart';
import '../widgets/tier_progress_bar.dart';
import '../widgets/earnings_module_breakdown.dart';
import 'registration_page.dart';
import 'partner_profile_page.dart';
import 'verification_status_page.dart';
import 'training_hub_page.dart';
import 'earnings_overview_page.dart';
import 'referral_center_page.dart';
import 'skill_certification_page.dart';
import 'partner_settings_page.dart';
import 'portfolio_manager_page.dart';

class TajirikaHomePage extends StatefulWidget {
  const TajirikaHomePage({super.key});

  @override
  State<TajirikaHomePage> createState() => _TajirikaHomePageState();
}

class _TajirikaHomePageState extends State<TajirikaHomePage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  TajirikaPartner? _partner;
  PartnerEarnings? _earnings;
  TierProgress? _tierProgress;
  PartnerStats? _stats;
  bool _isLoading = true;
  bool _notRegistered = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() { _isLoading = false; _error = 'Not authenticated'; });
        return;
      }

      final profileResult = await TajirikaService.getMyPartnerProfile(token);
      if (!mounted) return;

      if (!profileResult.success) {
        if (profileResult.message == 'not_registered') {
          setState(() { _isLoading = false; _notRegistered = true; });
          return;
        }
        setState(() { _isLoading = false; _error = profileResult.message; });
        return;
      }

      _partner = profileResult.partner;

      final results = await Future.wait([
        TajirikaService.getEarnings(token),
        TajirikaService.getTierProgress(token),
        TajirikaService.getPartnerStats(token),
      ]);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _earnings = results[0] as PartnerEarnings;
        _tierProgress = results[1] as TierProgress;
        _stats = results[2] as PartnerStats;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = 'Hitilafu: $e'; });
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(isSwahili ? 'Tajirika' : 'Tajirika'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        actions: [
          if (_partner != null)
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => _navigateTo(const PartnerSettingsPage()),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _notRegistered
                ? _buildRegistrationCta(isSwahili)
                : _error != null
                    ? _buildError(isSwahili)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: _kPrimary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPartnerCard(isSwahili),
                              const SizedBox(height: 16),
                              _buildStatsRow(isSwahili),
                              const SizedBox(height: 16),
                              if (_tierProgress != null)
                                TierProgressBar(progress: _tierProgress!, isSwahili: isSwahili),
                              const SizedBox(height: 16),
                              _buildEarningsCard(isSwahili),
                              const SizedBox(height: 16),
                              _buildQuickActions(isSwahili),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildRegistrationCta(bool isSwahili) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_rounded, size: 64, color: _kSecondary),
            const SizedBox(height: 24),
            Text(
              isSwahili ? 'Jiunge na Tajirika' : 'Join Tajirika',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              isSwahili
                  ? 'Sajili ujuzi wako na uanze kupata wateja kupitia jukwaa la TAJIRI.'
                  : 'Register your skills and start getting customers through the TAJIRI platform.',
              style: const TextStyle(fontSize: 14, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrationPage()),
                  );
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isSwahili ? 'Jisajili Sasa' : 'Register Now',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool isSwahili) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? (isSwahili ? 'Imeshindwa kupakia' : 'Failed to load'),
              style: const TextStyle(color: _kPrimary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadData,
              child: Text(isSwahili ? 'Jaribu tena' : 'Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(bool isSwahili) {
    final p = _partner!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateTo(PartnerProfilePage(partnerId: p.id)),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
              child: p.photoUrl.isEmpty
                  ? const Icon(Icons.person_rounded, size: 30, color: _kSecondary)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TierBadge(tier: p.tier, fontSize: 10),
                    const SizedBox(width: 8),
                    if (p.aggregateRating > 0) ...[
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(
                        p.aggregateRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.isActive ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.isActive
                          ? (isSwahili ? 'Hai' : 'Active')
                          : (isSwahili ? 'Siyo Hai' : 'Inactive'),
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isSwahili) {
    final s = _stats ?? PartnerStats();
    return Row(
      children: [
        Expanded(
          child: PartnerStatCard(
            label: isSwahili ? 'Kazi' : 'Jobs',
            value: s.jobsCompleted.toString(),
            icon: Icons.work_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PartnerStatCard(
            label: isSwahili ? 'Ukadiriaji' : 'Rating',
            value: s.averageRating > 0 ? s.averageRating.toStringAsFixed(1) : '-',
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PartnerStatCard(
            label: isSwahili ? 'Majibu' : 'Response',
            value: s.responseTimeMinutes > 0 ? '${s.responseTimeMinutes}m' : '-',
            icon: Icons.timer_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PartnerStatCard(
            label: isSwahili ? 'Moduli' : 'Modules',
            value: s.activeModules.length.toString(),
            icon: Icons.apps_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(bool isSwahili) {
    final e = _earnings ?? PartnerEarnings();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Mapato' : 'Earnings',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              GestureDetector(
                onTap: () => _navigateTo(const EarningsOverviewPage()),
                child: Text(
                  isSwahili ? 'Ona yote' : 'View all',
                  style: const TextStyle(fontSize: 12, color: _kSecondary, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'TZS ${e.totalEarnings.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili ? 'Jumla ya mapato' : 'Total earnings',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          if (e.byModule.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            EarningsModuleBreakdown(byModule: e.byModule),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isSwahili) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _quickAction(Icons.person_rounded, isSwahili ? 'Wasifu' : 'Profile',
            () => _navigateTo(PartnerProfilePage(partnerId: _partner!.id))),
        _quickAction(Icons.photo_library_rounded, isSwahili ? 'Kazi Zangu' : 'Portfolio',
            () => _navigateTo(PortfolioManagerPage(partnerId: _partner!.id))),
        _quickAction(Icons.verified_rounded, isSwahili ? 'Uthibitisho' : 'Verification',
            () => _navigateTo(const VerificationStatusPage())),
        _quickAction(Icons.school_rounded, isSwahili ? 'Mafunzo' : 'Training',
            () => _navigateTo(const TrainingHubPage())),
        _quickAction(Icons.monetization_on_rounded, isSwahili ? 'Mapato' : 'Earnings',
            () => _navigateTo(const EarningsOverviewPage())),
        _quickAction(Icons.people_rounded, isSwahili ? 'Rufaa' : 'Referrals',
            () => _navigateTo(const ReferralCenterPage())),
        _quickAction(Icons.workspace_premium_rounded, isSwahili ? 'Ujuzi' : 'Skills',
            () => _navigateTo(const SkillCertificationPage())),
        _quickAction(Icons.settings_rounded, isSwahili ? 'Mipangilio' : 'Settings',
            () => _navigateTo(const PartnerSettingsPage())),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 56) / 4,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(icon, size: 22, color: _kPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: _kSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/tajirika_module.dart lib/tajirika/pages/tajirika_home_page.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/tajirika/tajirika_module.dart lib/tajirika/pages/tajirika_home_page.dart
git commit -m "feat(tajirika): add module entry point and partner dashboard"
```

---

## Task 5: Registration Page

**Files:**
- Create: `lib/tajirika/pages/registration_page.dart`

- [ ] **Step 1: Create registration page**

Create `lib/tajirika/pages/registration_page.dart` — a multi-step PageView stepper with 8 steps: Personal Info, Skill Selection, ID Verification, License Upload, Portfolio Upload, Service Area, Payout Account, Terms & Submit.

The file follows the exact screen pattern from the spec. Key implementation details:
- Uses `PageController` with `PageView` for step navigation
- Step indicator at top showing current step out of 8
- Back/Next buttons at bottom with validation per step
- Collects all data in local state variables, calls `TajirikaService.registerPartner()` on final submit
- Skill selection uses `SkillCategoryChip` widgets in a `Wrap` (multi-select, minimum 1)
- NIDA/TIN are text fields with input formatters
- License upload uses `ImagePicker` (camera/gallery)
- Portfolio upload allows up to 10 items
- Service area uses Tanzania hierarchy dropdowns (regions loaded from `LocationService`)
- Payout account has method selector (M-Pesa/Tigo Pesa/Airtel Money/Bank) + account number field

This is the largest single page (~500 lines). Build each step as a separate `_buildStep*` method.

- [ ] **Step 2: Verify compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/pages/registration_page.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/tajirika/pages/registration_page.dart
git commit -m "feat(tajirika): add multi-step partner registration flow"
```

---

## Task 6: Verification Status + Partner Profile Pages

**Files:**
- Create: `lib/tajirika/pages/verification_status_page.dart`
- Create: `lib/tajirika/pages/partner_profile_page.dart`

- [ ] **Step 1: Create verification status page**

Displays verification progress for NIDA, TIN, Professional License, and Background Check using `VerificationStepCard` widgets. Top banner shows overall status. Bottom section for peer vouching.

- [ ] **Step 2: Create partner profile page**

Public partner profile with header (photo, name, tier badge, rating), skills chips, portfolio grid, credentials, service areas. Edit button navigates to profile edit. Accepts `partnerId` parameter.

- [ ] **Step 3: Verify compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/pages/verification_status_page.dart lib/tajirika/pages/partner_profile_page.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/tajirika/pages/verification_status_page.dart lib/tajirika/pages/partner_profile_page.dart
git commit -m "feat(tajirika): add verification status and partner profile pages"
```

---

## Task 7: Portfolio Manager + Training Hub Pages

**Files:**
- Create: `lib/tajirika/pages/portfolio_manager_page.dart`
- Create: `lib/tajirika/pages/training_hub_page.dart`

- [ ] **Step 1: Create portfolio manager page**

Grid of `PortfolioItemCard` widgets with add FAB. Upload flow: pick photo/video, add caption, select skill category, upload with progress. Long-press delete with confirmation.

- [ ] **Step 2: Create training hub page**

TabBar with Available/In Progress/Completed tabs. `TrainingCourseCard` list per tab. Category filter chips. Mentorship section at bottom.

- [ ] **Step 3: Verify compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/pages/portfolio_manager_page.dart lib/tajirika/pages/training_hub_page.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/tajirika/pages/portfolio_manager_page.dart lib/tajirika/pages/training_hub_page.dart
git commit -m "feat(tajirika): add portfolio manager and training hub pages"
```

---

## Task 8: Earnings Overview + Referral Center Pages

**Files:**
- Create: `lib/tajirika/pages/earnings_overview_page.dart`
- Create: `lib/tajirika/pages/referral_center_page.dart`

- [ ] **Step 1: Create earnings overview page**

Period toggle (weekly/monthly), total earnings card, `EarningsModuleBreakdown`, payout history list, withdraw button with amount/method dialog.

- [ ] **Step 2: Create referral center page**

Referral code card with copy/share, stats row, `ReferralCard` list.

- [ ] **Step 3: Verify compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/pages/earnings_overview_page.dart lib/tajirika/pages/referral_center_page.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/tajirika/pages/earnings_overview_page.dart lib/tajirika/pages/referral_center_page.dart
git commit -m "feat(tajirika): add earnings overview and referral center pages"
```

---

## Task 9: Skill Certification + Partner Settings Pages

**Files:**
- Create: `lib/tajirika/pages/skill_certification_page.dart`
- Create: `lib/tajirika/pages/partner_settings_page.dart`

- [ ] **Step 1: Create skill certification page**

Current tier card with `TierBadge`, `TierProgressBar`, skills list with edit button, badges grid using `BadgeChip`, skill test submission section.

- [ ] **Step 2: Create partner settings page**

Service area editor with location pickers, availability schedule (day-by-day with time pickers and toggles), payout account editor, notification toggles, deactivate account button.

- [ ] **Step 3: Verify compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/pages/skill_certification_page.dart lib/tajirika/pages/partner_settings_page.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/tajirika/pages/skill_certification_page.dart lib/tajirika/pages/partner_settings_page.dart
git commit -m "feat(tajirika): add skill certification and partner settings pages"
```

---

## Task 10: Platform Wiring (Profile Tab + App Strings)

**Files:**
- Modify: `lib/models/profile_tab_config.dart` — add Tajirika tab to defaults
- Modify: `lib/l10n/app_strings.dart` — add Tajirika bilingual strings

- [ ] **Step 1: Add Tajirika tab to profile tab config**

In `lib/models/profile_tab_config.dart`, add the `tajirika` tab to `ProfileTabDefaults.defaultTabs` if it doesn't already exist:

```dart
ProfileTabConfig(id: 'tajirika', label: 'Tajirika', icon: 'handshake', enabled: true, order: N),
```

And ensure `'tajirika'` is in the `commerce` category `tabIds` list in `ProfileTabDefaults.categories`.

- [ ] **Step 2: Add Tajirika strings to app_strings.dart**

Add these string getters to the `AppStrings` class in `lib/l10n/app_strings.dart`:

```dart
// ——— Tajirika (Partner Program) ———
String get tajirika => 'Tajirika';
String get partnerDashboard => isSwahili ? 'Dashibodi ya Mshirika' : 'Partner Dashboard';
String get joinTajirika => isSwahili ? 'Jiunge na Tajirika' : 'Join Tajirika';
String get registerNow => isSwahili ? 'Jisajili Sasa' : 'Register Now';
String get partnerRegistration => isSwahili ? 'Usajili wa Mshirika' : 'Partner Registration';
String get personalInfo => isSwahili ? 'Taarifa Binafsi' : 'Personal Info';
String get skillSelection => isSwahili ? 'Chagua Ujuzi' : 'Select Skills';
String get idVerification => isSwahili ? 'Uthibitisho wa Kitambulisho' : 'ID Verification';
String get licenseUpload => isSwahili ? 'Pakia Leseni' : 'Upload License';
String get portfolioUpload => isSwahili ? 'Pakia Kazi Zako' : 'Upload Portfolio';
String get serviceArea => isSwahili ? 'Eneo la Huduma' : 'Service Area';
String get payoutAccount => isSwahili ? 'Akaunti ya Malipo' : 'Payout Account';
String get termsAcceptance => isSwahili ? 'Masharti' : 'Terms';
String get verificationStatus => isSwahili ? 'Hali ya Uthibitisho' : 'Verification Status';
String get partnerProfile => isSwahili ? 'Wasifu wa Mshirika' : 'Partner Profile';
String get portfolioManager => isSwahili ? 'Kazi Zangu' : 'My Portfolio';
String get trainingHub => isSwahili ? 'Kituo cha Mafunzo' : 'Training Hub';
String get earningsOverview => isSwahili ? 'Muhtasari wa Mapato' : 'Earnings Overview';
String get referralCenter => isSwahili ? 'Kituo cha Rufaa' : 'Referral Center';
String get skillCertification => isSwahili ? 'Ujuzi na Vyeti' : 'Skills & Certification';
String get partnerSettings => isSwahili ? 'Mipangilio ya Mshirika' : 'Partner Settings';
String get totalEarnings => isSwahili ? 'Jumla ya Mapato' : 'Total Earnings';
String get weeklyEarnings => isSwahili ? 'Mapato ya Wiki' : 'Weekly Earnings';
String get monthlyEarnings => isSwahili ? 'Mapato ya Mwezi' : 'Monthly Earnings';
String get requestPayout => isSwahili ? 'Omba Malipo' : 'Request Payout';
String get withdraw => isSwahili ? 'Toa Pesa' : 'Withdraw';
String get referralCode => isSwahili ? 'Nambari ya Rufaa' : 'Referral Code';
String get copyCode => isSwahili ? 'Nakili' : 'Copy';
String get shareCode => isSwahili ? 'Shiriki' : 'Share';
String get available => isSwahili ? 'Inapatikana' : 'Available';
String get inProgressLabel => isSwahili ? 'Inaendelea' : 'In Progress';
String get completed => isSwahili ? 'Imekamilika' : 'Completed';
String get submitForReview => isSwahili ? 'Wasilisha kwa Ukaguzi' : 'Submit for Review';
String get deactivateAccount => isSwahili ? 'Zima Akaunti' : 'Deactivate Account';
String get availability => isSwahili ? 'Upatikanaji' : 'Availability';
String get notifications => isSwahili ? 'Arifa' : 'Notifications';
```

- [ ] **Step 3: Wire TajirikaModule into profile screen**

In the profile screen (`lib/screens/profile/profile_screen.dart`), ensure the `tajirika` tab renders `TajirikaModule()` when selected. Check how other module tabs (like `michango`, `kikoba`) are wired and follow the same pattern.

- [ ] **Step 4: Verify full module compiles**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/tajirika/
```

- [ ] **Step 5: Commit**

```bash
git add lib/models/profile_tab_config.dart lib/l10n/app_strings.dart lib/screens/profile/profile_screen.dart lib/tajirika/
git commit -m "feat(tajirika): wire partner program into platform — profile tab + bilingual strings"
```

---

## Task 11: Final Verification

- [ ] **Step 1: Run full flutter analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze
```

Fix any warnings or errors.

- [ ] **Step 2: Verify all files exist**

```bash
find lib/tajirika -name '*.dart' | sort
```

Expected output:
```
lib/tajirika/models/tajirika_models.dart
lib/tajirika/pages/earnings_overview_page.dart
lib/tajirika/pages/partner_profile_page.dart
lib/tajirika/pages/partner_settings_page.dart
lib/tajirika/pages/portfolio_manager_page.dart
lib/tajirika/pages/referral_center_page.dart
lib/tajirika/pages/registration_page.dart
lib/tajirika/pages/skill_certification_page.dart
lib/tajirika/pages/tajirika_home_page.dart
lib/tajirika/pages/training_hub_page.dart
lib/tajirika/pages/verification_status_page.dart
lib/tajirika/services/tajirika_service.dart
lib/tajirika/tajirika_module.dart
lib/tajirika/widgets/badge_chip.dart
lib/tajirika/widgets/earnings_module_breakdown.dart
lib/tajirika/widgets/partner_stat_card.dart
lib/tajirika/widgets/portfolio_item_card.dart
lib/tajirika/widgets/referral_card.dart
lib/tajirika/widgets/skill_category_chip.dart
lib/tajirika/widgets/tier_badge.dart
lib/tajirika/widgets/tier_progress_bar.dart
lib/tajirika/widgets/training_course_card.dart
lib/tajirika/widgets/verification_step_card.dart
```

23 files total.

- [ ] **Step 3: Commit any final fixes**

```bash
git add -A lib/tajirika/
git commit -m "fix(tajirika): resolve any remaining analysis issues"
```
