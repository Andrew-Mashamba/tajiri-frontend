// lib/qibla/models/qibla_models.dart

// ─── Qibla Direction Data ─────────────────────────────────────
class QiblaDirection {
  final double bearing;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String locationName;
  final double magneticDeclination;

  QiblaDirection({
    required this.bearing,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.magneticDeclination = 0,
  });

  factory QiblaDirection.fromJson(Map<String, dynamic> json) {
    return QiblaDirection(
      bearing: _parseDouble(json['bearing']),
      distanceKm: _parseDouble(json['distance_km']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      locationName: json['location_name']?.toString() ?? '',
      magneticDeclination: _parseDouble(json['magnetic_declination']),
    );
  }

  /// True bearing adjusted for magnetic declination
  double get magneticBearing => bearing - magneticDeclination;
}

// ─── Calibration Quality ──────────────────────────────────────
enum CalibrationQuality {
  good,
  fair,
  poor;

  String get label {
    switch (this) {
      case CalibrationQuality.good:
        return 'Nzuri';
      case CalibrationQuality.fair:
        return 'Wastani';
      case CalibrationQuality.poor:
        return 'Hafifu';
    }
  }

  String get labelEn {
    switch (this) {
      case CalibrationQuality.good:
        return 'Good';
      case CalibrationQuality.fair:
        return 'Fair';
      case CalibrationQuality.poor:
        return 'Poor';
    }
  }
}

// ─── Calculation Method ───────────────────────────────────────
enum QiblaCalcMethod {
  greatCircle,
  rhumbLine;

  String get displayName {
    switch (this) {
      case QiblaCalcMethod.greatCircle:
        return 'Great Circle (Sahihi zaidi)';
      case QiblaCalcMethod.rhumbLine:
        return 'Rhumb Line';
    }
  }
}

// ─── Saved Location ───────────────────────────────────────────
class SavedLocation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double qiblaBearing;

  SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.qiblaBearing,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      qiblaBearing: _parseDouble(json['qibla_bearing']),
    );
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
