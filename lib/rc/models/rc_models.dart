// lib/rc/models/rc_models.dart
import '../../config/api_config.dart';

// ─── Parse helpers ──────────────────────────────────────────────
int _parseInt(dynamic v, [int fallback = 0]) =>
    (v is num) ? v.toInt() : int.tryParse('$v') ?? fallback;

double _parseDouble(dynamic v, [double fallback = 0.0]) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? fallback;

String _buildUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return ApiConfig.sanitizeUrl(path) ?? path;
  return '${ApiConfig.storageUrl}/$path';
}

// ─── Result wrappers ────────────────────────────────────────────
class SingleResult<T> {
  final bool success;
  final T? data;
  final String message;
  SingleResult({this.success = false, this.data, this.message = ''});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int total;
  final int page;
  final String message;
  PaginatedResult({
    this.success = false,
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.message = '',
  });
}

// ─── Regional Commissioner ──────────────────────────────────────
class RegionalCommissioner {
  final int id;
  final int userId;
  final int regionId;
  final String name;
  final String photo;
  final String bio;
  final String appointmentDate;
  final List<String> careerHistory;
  final String phone;
  final String email;
  final String officeLocation;

  RegionalCommissioner({
    required this.id,
    this.userId = 0,
    this.regionId = 0,
    this.name = '',
    this.photo = '',
    this.bio = '',
    this.appointmentDate = '',
    this.careerHistory = const [],
    this.phone = '',
    this.email = '',
    this.officeLocation = '',
  });

  factory RegionalCommissioner.fromJson(Map<String, dynamic> json) =>
      RegionalCommissioner(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        regionId: _parseInt(json['region_id']),
        name: json['name'] as String? ?? '',
        photo: _buildUrl(json['photo'] as String?),
        bio: json['bio'] as String? ?? '',
        appointmentDate: json['appointment_date'] as String? ?? '',
        careerHistory: (json['career_history'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        officeLocation: json['office_location'] as String? ?? '',
      );
}

// ─── Region ─────────────────────────────────────────────────────
class Region {
  final int id;
  final String name;
  final int population;
  final int districtCount;
  final double area;
  final double gdpContribution;
  final List<String> majorIndustries;

  Region({
    required this.id,
    this.name = '',
    this.population = 0,
    this.districtCount = 0,
    this.area = 0,
    this.gdpContribution = 0,
    this.majorIndustries = const [],
  });

  factory Region.fromJson(Map<String, dynamic> json) => Region(
        id: _parseInt(json['id']),
        name: json['name'] as String? ?? '',
        population: _parseInt(json['population']),
        districtCount: _parseInt(json['district_count']),
        area: _parseDouble(json['area']),
        gdpContribution: _parseDouble(json['gdp_contribution']),
        majorIndustries: (json['major_industries'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ─── Mega Project ───────────────────────────────────────────────
class MegaProject {
  final int id;
  final int regionId;
  final String name;
  final double budget;
  final List<String> contractors;
  final String startDate;
  final String endDate;
  final int progressPercent;
  final String type;
  final List<String> photos;

  MegaProject({
    required this.id,
    this.regionId = 0,
    this.name = '',
    this.budget = 0,
    this.contractors = const [],
    this.startDate = '',
    this.endDate = '',
    this.progressPercent = 0,
    this.type = '',
    this.photos = const [],
  });

  factory MegaProject.fromJson(Map<String, dynamic> json) => MegaProject(
        id: _parseInt(json['id']),
        regionId: _parseInt(json['region_id']),
        name: json['name'] as String? ?? '',
        budget: _parseDouble(json['budget']),
        contractors: (json['contractors'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String? ?? '',
        progressPercent: _parseInt(json['progress_percent']),
        type: json['type'] as String? ?? '',
        photos: (json['photos'] as List?)
                ?.map((e) => _buildUrl(e as String?))
                .toList() ??
            [],
      );
}

// ─── Regional Budget ────────────────────────────────────────────
class SectorAllocation {
  final String name;
  final double allocated;
  final double disbursed;
  final double spent;

  SectorAllocation({
    this.name = '',
    this.allocated = 0,
    this.disbursed = 0,
    this.spent = 0,
  });

  factory SectorAllocation.fromJson(Map<String, dynamic> json) =>
      SectorAllocation(
        name: json['name'] as String? ?? '',
        allocated: _parseDouble(json['allocated']),
        disbursed: _parseDouble(json['disbursed']),
        spent: _parseDouble(json['spent']),
      );
}

class RegionalBudget {
  final int regionId;
  final int year;
  final List<SectorAllocation> sectors;

  RegionalBudget({
    this.regionId = 0,
    this.year = 0,
    this.sectors = const [],
  });

  factory RegionalBudget.fromJson(Map<String, dynamic> json) => RegionalBudget(
        regionId: _parseInt(json['region_id']),
        year: _parseInt(json['year']),
        sectors: (json['sectors'] as List?)
                ?.map((e) => SectorAllocation.fromJson(e))
                .toList() ??
            [],
      );
}

// ─── Investment Opportunity ─────────────────────────────────────
class InvestmentOpportunity {
  final int id;
  final int regionId;
  final String title;
  final String sector;
  final String description;
  final String landInfo;
  final String incentives;
  final Map<String, dynamic> contactInfo;

  InvestmentOpportunity({
    required this.id,
    this.regionId = 0,
    this.title = '',
    this.sector = '',
    this.description = '',
    this.landInfo = '',
    this.incentives = '',
    this.contactInfo = const {},
  });

  factory InvestmentOpportunity.fromJson(Map<String, dynamic> json) =>
      InvestmentOpportunity(
        id: _parseInt(json['id']),
        regionId: _parseInt(json['region_id']),
        title: json['title'] as String? ?? '',
        sector: json['sector'] as String? ?? '',
        description: json['description'] as String? ?? '',
        landInfo: json['land_info'] as String? ?? '',
        incentives: json['incentives'] as String? ?? '',
        contactInfo: (json['contact_info'] as Map<String, dynamic>?) ?? {},
      );
}

// ─── Regional Stats ─────────────────────────────────────────────
class RegionalStats {
  final int regionId;
  final Map<String, dynamic> education;
  final Map<String, dynamic> health;
  final Map<String, dynamic> economy;
  final Map<String, dynamic> infrastructure;

  RegionalStats({
    this.regionId = 0,
    this.education = const {},
    this.health = const {},
    this.economy = const {},
    this.infrastructure = const {},
  });

  factory RegionalStats.fromJson(Map<String, dynamic> json) => RegionalStats(
        regionId: _parseInt(json['region_id']),
        education: (json['education'] as Map<String, dynamic>?) ?? {},
        health: (json['health'] as Map<String, dynamic>?) ?? {},
        economy: (json['economy'] as Map<String, dynamic>?) ?? {},
        infrastructure: (json['infrastructure'] as Map<String, dynamic>?) ?? {},
      );
}

// ─── Report ─────────────────────────────────────────────────────
class RcReport {
  final int id;
  final int reporterId;
  final int regionId;
  final String category;
  final String description;
  final List<String> attachments;
  final String status;
  final String trackingNumber;
  final bool escalated;
  final String createdAt;

  RcReport({
    required this.id,
    this.reporterId = 0,
    this.regionId = 0,
    this.category = '',
    this.description = '',
    this.attachments = const [],
    this.status = 'received',
    this.trackingNumber = '',
    this.escalated = false,
    this.createdAt = '',
  });

  factory RcReport.fromJson(Map<String, dynamic> json) => RcReport(
        id: _parseInt(json['id']),
        reporterId: _parseInt(json['reporter_id']),
        regionId: _parseInt(json['region_id']),
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        attachments: (json['attachments'] as List?)
                ?.map((e) => _buildUrl(e as String?))
                .toList() ??
            [],
        status: json['status'] as String? ?? 'received',
        trackingNumber: json['tracking_number'] as String? ?? '',
        escalated: json['escalated'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );
}
