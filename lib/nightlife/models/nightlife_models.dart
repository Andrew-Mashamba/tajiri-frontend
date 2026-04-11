// lib/nightlife/models/nightlife_models.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

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

// ─── Venue ────────────────────────────────────────────────────

class Venue {
  final int id;
  final String name;
  final String type; // club, bar, lounge, restaurant, rooftop
  final String? description;
  final String address;
  final String? phone;
  final double? lat;
  final double? lng;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String? openingHours;
  final bool isOpen;

  Venue({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    required this.address,
    this.phone,
    this.lat,
    this.lng,
    this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.openingHours,
    required this.isOpen,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    final rawImg = json['image_url'] as String?;
    return Venue(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      type: json['type'] ?? 'bar',
      description: json['description'],
      address: json['address'] ?? '',
      phone: json['phone'],
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
      imageUrl: rawImg != null ? ApiConfig.sanitizeUrl(rawImg) : null,
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['review_count']),
      openingHours: json['opening_hours'],
      isOpen: _parseBool(json['is_open']),
    );
  }
}

// ─── Nightlife Event ──────────────────────────────────────────

class NightlifeEvent {
  final int id;
  final int venueId;
  final String venueName;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime date;
  final String? djName;
  final double? entryFee;
  final String? dresscode;

  NightlifeEvent({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.title,
    this.description,
    this.imageUrl,
    required this.date,
    this.djName,
    this.entryFee,
    this.dresscode,
  });

  factory NightlifeEvent.fromJson(Map<String, dynamic> json) {
    final rawImg = json['image_url'] as String?;
    return NightlifeEvent(
      id: _parseInt(json['id']),
      venueId: _parseInt(json['venue_id']),
      venueName: json['venue_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: rawImg != null ? ApiConfig.sanitizeUrl(rawImg) : null,
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      djName: json['dj_name'],
      entryFee:
          json['entry_fee'] != null ? _parseDouble(json['entry_fee']) : null,
      dresscode: json['dresscode'],
    );
  }
}

// ─── Table Reservation ───────────────────────────────────────

class TableReservation {
  final int id;
  final int venueId;
  final String venueName;
  final DateTime date;
  final String time;
  final int guests;
  final String status; // pending, confirmed, cancelled
  final double? minimumSpend;

  TableReservation({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.date,
    required this.time,
    required this.guests,
    required this.status,
    this.minimumSpend,
  });

  factory TableReservation.fromJson(Map<String, dynamic> json) {
    return TableReservation(
      id: _parseInt(json['id']),
      venueId: _parseInt(json['venue_id']),
      venueName: json['venue_name'] ?? '',
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      time: json['time'] ?? '',
      guests: _parseInt(json['guests']),
      status: json['status'] ?? 'pending',
      minimumSpend: json['minimum_spend'] != null
          ? _parseDouble(json['minimum_spend'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'venue_id': venueId,
        'date': date.toIso8601String().substring(0, 10),
        'time': time,
        'guests': guests,
      };
}
