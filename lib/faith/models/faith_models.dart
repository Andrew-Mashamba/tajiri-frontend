// lib/faith/models/faith_models.dart

// ─── Faith Preference ──────────────────────────────────────────

enum FaithType {
  islam,
  christianity,
  other;

  String get displayName {
    switch (this) {
      case FaithType.islam:
        return 'Uislamu';
      case FaithType.christianity:
        return 'Ukristo';
      case FaithType.other:
        return 'Nyingine';
    }
  }

  String get subtitle {
    switch (this) {
      case FaithType.islam:
        return 'Islam';
      case FaithType.christianity:
        return 'Christianity';
      case FaithType.other:
        return 'Other';
    }
  }
}

class FaithPreference {
  final int userId;
  final FaithType faith;

  FaithPreference({required this.userId, required this.faith});

  factory FaithPreference.fromJson(Map<String, dynamic> json) {
    return FaithPreference(
      userId: _parseInt(json['user_id']),
      faith: _parseFaithType(json['faith']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'faith': faith.name,
      };
}

// ─── Prayer Times (Islamic) ────────────────────────────────────

class PrayerTimes {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;
  final String? sunrise;

  PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    this.sunrise,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    return PrayerTimes(
      fajr: json['fajr']?.toString() ?? '--:--',
      dhuhr: json['dhuhr']?.toString() ?? '--:--',
      asr: json['asr']?.toString() ?? '--:--',
      maghrib: json['maghrib']?.toString() ?? '--:--',
      isha: json['isha']?.toString() ?? '--:--',
      date: json['date']?.toString() ?? '',
      sunrise: json['sunrise']?.toString(),
    );
  }

  /// Returns prayer names and times as an ordered list of pairs.
  List<MapEntry<String, String>> get allPrayers => [
        MapEntry('Alfajiri (Fajr)', fajr),
        if (sunrise != null) MapEntry('Jua kuchomoza (Sunrise)', sunrise!),
        MapEntry('Adhuhuri (Dhuhr)', dhuhr),
        MapEntry('Alasiri (Asr)', asr),
        MapEntry('Magharibi (Maghrib)', maghrib),
        MapEntry('Ishaa (Isha)', isha),
      ];
}

// ─── Place of Worship ──────────────────────────────────────────

enum WorshipPlaceType {
  mosque,
  church,
  temple;

  String get displayName {
    switch (this) {
      case WorshipPlaceType.mosque:
        return 'Msikiti';
      case WorshipPlaceType.church:
        return 'Kanisa';
      case WorshipPlaceType.temple:
        return 'Hekalu';
    }
  }

  String get subtitle {
    switch (this) {
      case WorshipPlaceType.mosque:
        return 'Mosque';
      case WorshipPlaceType.church:
        return 'Church';
      case WorshipPlaceType.temple:
        return 'Temple';
    }
  }
}

class PlaceOfWorship {
  final int id;
  final String name;
  final WorshipPlaceType type;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final String? phone;
  final String? imageUrl;

  PlaceOfWorship({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.phone,
    this.imageUrl,
  });

  factory PlaceOfWorship.fromJson(Map<String, dynamic> json) {
    return PlaceOfWorship(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: _parseWorshipPlaceType(json['type']),
      address: json['address']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distanceKm: json['distance_km'] != null
          ? _parseDouble(json['distance_km'])
          : null,
      phone: json['phone']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

// ─── Daily Inspiration ─────────────────────────────────────────

class DailyInspiration {
  final String text;
  final String source;
  final String date;
  final FaithType? faith;

  DailyInspiration({
    required this.text,
    required this.source,
    required this.date,
    this.faith,
  });

  factory DailyInspiration.fromJson(Map<String, dynamic> json) {
    return DailyInspiration(
      text: json['text']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      faith: json['faith'] != null ? _parseFaithType(json['faith']) : null,
    );
  }
}

// ─── Result wrappers ───────────────────────────────────────────

class FaithResult<T> {
  final bool success;
  final T? data;
  final String? message;

  FaithResult({required this.success, this.data, this.message});
}

class FaithListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  FaithListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ─────────────────────────────────────────────

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

FaithType _parseFaithType(dynamic v) {
  final s = v?.toString().toLowerCase() ?? '';
  switch (s) {
    case 'islam':
      return FaithType.islam;
    case 'christianity':
      return FaithType.christianity;
    default:
      return FaithType.other;
  }
}

WorshipPlaceType _parseWorshipPlaceType(dynamic v) {
  final s = v?.toString().toLowerCase() ?? '';
  switch (s) {
    case 'mosque':
      return WorshipPlaceType.mosque;
    case 'church':
      return WorshipPlaceType.church;
    case 'temple':
      return WorshipPlaceType.temple;
    default:
      return WorshipPlaceType.church;
  }
}
