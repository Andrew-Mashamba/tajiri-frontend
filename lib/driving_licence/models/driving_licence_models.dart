// lib/driving_licence/models/driving_licence_models.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

class SingleResult<T> {
  final bool success; final T? data; final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success; final List<T> items; final String? message;
  final int currentPage; final int lastPage;
  PaginatedResult({required this.success, this.items = const [], this.message,
    this.currentPage = 1, this.lastPage = 1});
  bool get hasMore => currentPage < lastPage;
}

// ─── Driving Licence ──────────────────────────────────────────

class DrivingLicence {
  final int id;
  final String licenceNumber;
  final List<LicenceClass> classes;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String status; // provisional, full
  final int points;

  DrivingLicence({
    required this.id, required this.licenceNumber, this.classes = const [],
    required this.issueDate, required this.expiryDate,
    required this.status, this.points = 0,
  });

  factory DrivingLicence.fromJson(Map<String, dynamic> json) {
    return DrivingLicence(
      id: _parseInt(json['id']),
      licenceNumber: json['licence_number'] ?? '',
      classes: (json['classes'] as List?)
          ?.map((j) => LicenceClass.fromJson(j)).toList() ?? [],
      issueDate: DateTime.tryParse(json['issue_date'] ?? '') ?? DateTime.now(),
      expiryDate: DateTime.tryParse(json['expiry_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'provisional',
      points: _parseInt(json['points']),
    );
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpiring => daysUntilExpiry <= 90;
  bool get isExpired => daysUntilExpiry < 0;
}

class LicenceClass {
  final String code; // A, B, C, D, E, F
  final String type; // provisional, full
  final DateTime? obtainedDate;

  LicenceClass({required this.code, required this.type, this.obtainedDate});

  factory LicenceClass.fromJson(Map<String, dynamic> json) {
    return LicenceClass(
      code: json['code'] ?? '',
      type: json['type'] ?? 'provisional',
      obtainedDate: json['obtained_date'] != null
          ? DateTime.tryParse(json['obtained_date']) : null,
    );
  }
}

// ─── Theory Question ──────────────────────────────────────────

class TheoryQuestion {
  final int id;
  final String questionSw;
  final String questionEn;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String category;

  TheoryQuestion({
    required this.id, required this.questionSw, required this.questionEn,
    required this.options, required this.correctIndex,
    this.explanation, required this.category,
  });

  factory TheoryQuestion.fromJson(Map<String, dynamic> json) {
    return TheoryQuestion(
      id: _parseInt(json['id']),
      questionSw: json['question_sw'] ?? '',
      questionEn: json['question_en'] ?? '',
      options: (json['options'] as List?)?.map((e) => '$e').toList() ?? [],
      correctIndex: _parseInt(json['correct_index']),
      explanation: json['explanation'],
      category: json['category'] ?? '',
    );
  }
}

// ─── Traffic Fine ─────────────────────────────────────────────

class TrafficFine {
  final int id;
  final String violation;
  final double amount;
  final DateTime date;
  final String? location;
  final String status; // outstanding, paid
  final int points;

  TrafficFine({
    required this.id, required this.violation, required this.amount,
    required this.date, this.location, required this.status,
    this.points = 0,
  });

  factory TrafficFine.fromJson(Map<String, dynamic> json) {
    return TrafficFine(
      id: _parseInt(json['id']),
      violation: json['violation'] ?? '',
      amount: _parseDouble(json['amount']),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      location: json['location'],
      status: json['status'] ?? 'outstanding',
      points: _parseInt(json['points']),
    );
  }

  bool get isPaid => status == 'paid';
}

// ─── Driving School ───────────────────────────────────────────

class DrivingSchool {
  final int id;
  final String name;
  final String? location;
  final double rating;
  final String? priceRange;
  final List<String> classesOffered;
  final String? phone;

  DrivingSchool({
    required this.id, required this.name, this.location,
    this.rating = 0, this.priceRange, this.classesOffered = const [],
    this.phone,
  });

  factory DrivingSchool.fromJson(Map<String, dynamic> json) {
    return DrivingSchool(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      location: json['location'],
      rating: _parseDouble(json['rating']),
      priceRange: json['price_range'],
      classesOffered: (json['classes_offered'] as List?)
          ?.map((e) => '$e').toList() ?? [],
      phone: json['phone'],
    );
  }
}
