// lib/tafuta_msikiti/models/tafuta_msikiti_models.dart

// ─── Mosque ───────────────────────────────────────────────────
class Mosque {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final String? phone;
  final String? imageUrl;
  final String? imamName;
  final int? capacity;
  final String? denomination;
  final List<String> facilities;
  final MosquePrayerTimes? prayerTimes;
  final double? rating;
  final int? reviewCount;

  Mosque({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.phone,
    this.imageUrl,
    this.imamName,
    this.capacity,
    this.denomination,
    this.facilities = const [],
    this.prayerTimes,
    this.rating,
    this.reviewCount,
  });

  factory Mosque.fromJson(Map<String, dynamic> json) {
    return Mosque(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distanceKm: json['distance_km'] != null
          ? _parseDouble(json['distance_km']) : null,
      phone: json['phone']?.toString(),
      imageUrl: json['image_url']?.toString(),
      imamName: json['imam_name']?.toString(),
      capacity: json['capacity'] != null ? _parseInt(json['capacity']) : null,
      denomination: json['denomination']?.toString(),
      facilities: (json['facilities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      prayerTimes: json['prayer_times'] != null
          ? MosquePrayerTimes.fromJson(json['prayer_times'])
          : null,
      rating: json['rating'] != null
          ? _parseDouble(json['rating']) : null,
      reviewCount: json['review_count'] != null
          ? _parseInt(json['review_count']) : null,
    );
  }
}

// ─── Mosque Prayer Times ──────────────────────────────────────
class MosquePrayerTimes {
  final String? fajrIqamah;
  final String? dhuhrIqamah;
  final String? asrIqamah;
  final String? maghribIqamah;
  final String? ishaIqamah;
  final String? jumuahKhutbah;
  final String? jumuahIqamah;

  MosquePrayerTimes({
    this.fajrIqamah,
    this.dhuhrIqamah,
    this.asrIqamah,
    this.maghribIqamah,
    this.ishaIqamah,
    this.jumuahKhutbah,
    this.jumuahIqamah,
  });

  factory MosquePrayerTimes.fromJson(Map<String, dynamic> json) {
    return MosquePrayerTimes(
      fajrIqamah: json['fajr_iqamah']?.toString(),
      dhuhrIqamah: json['dhuhr_iqamah']?.toString(),
      asrIqamah: json['asr_iqamah']?.toString(),
      maghribIqamah: json['maghrib_iqamah']?.toString(),
      ishaIqamah: json['isha_iqamah']?.toString(),
      jumuahKhutbah: json['jumuah_khutbah']?.toString(),
      jumuahIqamah: json['jumuah_iqamah']?.toString(),
    );
  }
}

// ─── Mosque Review ────────────────────────────────────────────
class MosqueReview {
  final int id;
  final int userId;
  final String userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  MosqueReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory MosqueReview.fromJson(Map<String, dynamic> json) {
    return MosqueReview(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      userName: json['user_name']?.toString() ?? '',
      rating: _parseDouble(json['rating']),
      comment: json['comment']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── Facility Type ────────────────────────────────────────────
enum FacilityType {
  wudhu,
  parking,
  womenSection,
  wheelchair,
  airConditioning,
  madrasa,
  library;

  String get label {
    switch (this) {
      case FacilityType.wudhu: return 'Eneo la Wudhu';
      case FacilityType.parking: return 'Maegesho';
      case FacilityType.womenSection: return 'Sehemu ya Wanawake';
      case FacilityType.wheelchair: return 'Wheelchair';
      case FacilityType.airConditioning: return 'AC';
      case FacilityType.madrasa: return 'Madrasa';
      case FacilityType.library: return 'Maktaba';
    }
  }
}

// ─── Result Wrappers ──────────────────────────────────────────
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
  final int total;
  final String? message;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message,
  });
}

// ─── Parse Helpers ────────────────────────────────────────────
int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
