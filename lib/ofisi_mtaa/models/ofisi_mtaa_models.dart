// lib/ofisi_mtaa/models/ofisi_mtaa_models.dart
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

// ─── Request Status ─────────────────────────────────────────────
enum RequestStatus { received, underReview, ready, collected }

RequestStatus _parseRequestStatus(dynamic v) {
  switch ('$v') {
    case 'under_review':
      return RequestStatus.underReview;
    case 'ready':
      return RequestStatus.ready;
    case 'collected':
      return RequestStatus.collected;
    default:
      return RequestStatus.received;
  }
}

// ─── Mtaa Official ──────────────────────────────────────────────
class MtaaOfficial {
  final int id;
  final int userId;
  final int mtaaId;
  final String name;
  final String role; // mwenyekiti, mtendaji, mjumbe
  final String phone;
  final String photo;
  final String availabilityStatus; // available, out_of_office, on_leave

  MtaaOfficial({
    required this.id,
    this.userId = 0,
    this.mtaaId = 0,
    this.name = '',
    this.role = '',
    this.phone = '',
    this.photo = '',
    this.availabilityStatus = 'available',
  });

  factory MtaaOfficial.fromJson(Map<String, dynamic> json) => MtaaOfficial(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        mtaaId: _parseInt(json['mtaa_id']),
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        photo: _buildUrl(json['photo'] as String?),
        availabilityStatus:
            json['availability_status'] as String? ?? 'available',
      );

  String get roleLabel {
    switch (role) {
      case 'mwenyekiti':
        return 'Mwenyekiti wa Mtaa';
      case 'mtendaji':
        return 'Mtendaji wa Mtaa';
      case 'mjumbe':
        return 'Mjumbe';
      default:
        return role;
    }
  }
}

// ─── Service Catalog ────────────────────────────────────────────
class ServiceCatalog {
  final int id;
  final String name;
  final String description;
  final List<String> requiredDocs;
  final double officialFee;
  final String processingTime;

  ServiceCatalog({
    required this.id,
    this.name = '',
    this.description = '',
    this.requiredDocs = const [],
    this.officialFee = 0,
    this.processingTime = '',
  });

  factory ServiceCatalog.fromJson(Map<String, dynamic> json) => ServiceCatalog(
        id: _parseInt(json['id']),
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        requiredDocs: (json['required_docs'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        officialFee: _parseDouble(json['official_fee']),
        processingTime: json['processing_time'] as String? ?? '',
      );
}

// ─── Service Request ────────────────────────────────────────────
class ServiceRequest {
  final int id;
  final int userId;
  final int mtaaId;
  final String serviceType;
  final RequestStatus status;
  final List<String> documents;
  final double feeAmount;
  final String estimatedDate;
  final String submittedAt;
  final String updatedAt;

  ServiceRequest({
    required this.id,
    this.userId = 0,
    this.mtaaId = 0,
    this.serviceType = '',
    this.status = RequestStatus.received,
    this.documents = const [],
    this.feeAmount = 0,
    this.estimatedDate = '',
    this.submittedAt = '',
    this.updatedAt = '',
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        mtaaId: _parseInt(json['mtaa_id']),
        serviceType: json['service_type'] as String? ?? '',
        status: _parseRequestStatus(json['status']),
        documents: (json['documents'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        feeAmount: _parseDouble(json['fee_amount']),
        estimatedDate: json['estimated_date'] as String? ?? '',
        submittedAt: json['submitted_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  String get statusLabel {
    switch (status) {
      case RequestStatus.received:
        return 'Imepokelewa';
      case RequestStatus.underReview:
        return 'Inakaguliwa';
      case RequestStatus.ready:
        return 'Tayari kuchukuliwa';
      case RequestStatus.collected:
        return 'Imechukuliwa';
    }
  }
}

// ─── Appointment ────────────────────────────────────────────────
class Appointment {
  final int id;
  final int userId;
  final int officialId;
  final String dateTime;
  final String purpose;
  final String status; // booked, completed, cancelled

  Appointment({
    required this.id,
    this.userId = 0,
    this.officialId = 0,
    this.dateTime = '',
    this.purpose = '',
    this.status = 'booked',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        officialId: _parseInt(json['official_id']),
        dateTime: json['date_time'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
        status: json['status'] as String? ?? 'booked',
      );
}

// ─── Community Notice ───────────────────────────────────────────
class CommunityNotice {
  final int id;
  final String title;
  final String body;
  final int authorId;
  final String type; // announcement, alert, meeting
  final String createdAt;

  CommunityNotice({
    required this.id,
    this.title = '',
    this.body = '',
    this.authorId = 0,
    this.type = 'announcement',
    this.createdAt = '',
  });

  factory CommunityNotice.fromJson(Map<String, dynamic> json) =>
      CommunityNotice(
        id: _parseInt(json['id']),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        authorId: _parseInt(json['author_id']),
        type: json['type'] as String? ?? 'announcement',
        createdAt: json['created_at'] as String? ?? '',
      );
}

// ─── Time Slot ──────────────────────────────────────────────────
class TimeSlot {
  final String time;
  final bool available;

  TimeSlot({required this.time, this.available = true});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        time: json['time'] as String? ?? '',
        available: json['available'] as bool? ?? true,
      );
}
