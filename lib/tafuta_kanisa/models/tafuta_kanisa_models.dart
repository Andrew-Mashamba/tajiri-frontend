// lib/tafuta_kanisa/models/tafuta_kanisa_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

// ─── Result wrappers ───────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Church Listing ───────────────────────────────────────────

class ChurchListing {
  final int id;
  final String name;
  final String denomination;
  final String? address;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final String? pastorName;
  final String? phone;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final List<String> serviceTimes;
  final List<String> languages;
  final String? serviceStyle;
  final bool isSaved;

  ChurchListing({
    required this.id,
    required this.name,
    required this.denomination,
    this.address,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.pastorName,
    this.phone,
    this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.serviceTimes,
    required this.languages,
    this.serviceStyle,
    this.isSaved = false,
  });

  factory ChurchListing.fromJson(Map<String, dynamic> json) {
    return ChurchListing(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      denomination: json['denomination']?.toString() ?? '',
      address: json['address']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distanceKm: json['distance_km'] != null
          ? _parseDouble(json['distance_km'])
          : null,
      pastorName: json['pastor_name']?.toString(),
      phone: json['phone']?.toString(),
      imageUrl: json['image_url']?.toString(),
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['review_count']),
      serviceTimes: (json['service_times'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      languages: (json['languages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      serviceStyle: json['service_style']?.toString(),
      isSaved: _parseBool(json['is_saved']),
    );
  }
}

// ─── Church Review ────────────────────────────────────────────

class ChurchReview {
  final int id;
  final String authorName;
  final String? authorPhoto;
  final int stars;
  final String? text;
  final String createdAt;

  ChurchReview({
    required this.id,
    required this.authorName,
    this.authorPhoto,
    required this.stars,
    this.text,
    required this.createdAt,
  });

  factory ChurchReview.fromJson(Map<String, dynamic> json) {
    return ChurchReview(
      id: _parseInt(json['id']),
      authorName: json['author_name']?.toString() ?? '',
      authorPhoto: json['author_photo']?.toString(),
      stars: _parseInt(json['stars']),
      text: json['text']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
