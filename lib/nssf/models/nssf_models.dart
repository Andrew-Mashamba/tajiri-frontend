// lib/nssf/models/nssf_models.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

class SingleResult<T> { final bool success; final T? data; final String? message; SingleResult({required this.success, this.data, this.message}); }
class PaginatedResult<T> { final bool success; final List<T> items; final String? message; final int currentPage; final int lastPage;
  PaginatedResult({required this.success, this.items = const [], this.message, this.currentPage = 1, this.lastPage = 1}); bool get hasMore => currentPage < lastPage; }

class NssfMembership {
  final int id; final String memberNumber; final double totalContributions; final int monthsContributed;
  final String? employerName; final bool employerCompliant; final DateTime? registrationDate;
  NssfMembership({required this.id, required this.memberNumber, this.totalContributions = 0,
    this.monthsContributed = 0, this.employerName, this.employerCompliant = true, this.registrationDate});
  factory NssfMembership.fromJson(Map<String, dynamic> json) => NssfMembership(
    id: _parseInt(json['id']), memberNumber: json['member_number'] ?? '',
    totalContributions: _parseDouble(json['total_contributions']),
    monthsContributed: _parseInt(json['months_contributed']),
    employerName: json['employer_name'], employerCompliant: _parseBool(json['employer_compliant']),
    registrationDate: json['registration_date'] != null ? DateTime.tryParse(json['registration_date']) : null);
}

class Contribution {
  final int id; final String month; final int year; final double employeeAmount; final double employerAmount;
  final String? employerName; final String status;
  Contribution({required this.id, required this.month, required this.year,
    required this.employeeAmount, required this.employerAmount, this.employerName, required this.status});
  factory Contribution.fromJson(Map<String, dynamic> json) => Contribution(
    id: _parseInt(json['id']), month: json['month'] ?? '', year: _parseInt(json['year']),
    employeeAmount: _parseDouble(json['employee_amount']), employerAmount: _parseDouble(json['employer_amount']),
    employerName: json['employer_name'], status: json['status'] ?? '');
}

class PensionProjection {
  final int currentAge; final int retirementAge; final double totalContributions;
  final double projectedMonthly; final double projectedLump;
  PensionProjection({required this.currentAge, required this.retirementAge,
    required this.totalContributions, required this.projectedMonthly, required this.projectedLump});
  factory PensionProjection.fromJson(Map<String, dynamic> json) => PensionProjection(
    currentAge: _parseInt(json['current_age']), retirementAge: _parseInt(json['retirement_age']),
    totalContributions: _parseDouble(json['total_contributions']),
    projectedMonthly: _parseDouble(json['projected_monthly']),
    projectedLump: _parseDouble(json['projected_lump']));
}

class Nominee {
  final int id; final String name; final String relationship; final double percentage;
  final String? idNumber; final String? phone;
  Nominee({required this.id, required this.name, required this.relationship,
    required this.percentage, this.idNumber, this.phone});
  factory Nominee.fromJson(Map<String, dynamic> json) => Nominee(
    id: _parseInt(json['id']), name: json['name'] ?? '', relationship: json['relationship'] ?? '',
    percentage: _parseDouble(json['percentage']), idNumber: json['id_number'], phone: json['phone']);
}

class EmployerCompliance {
  final String employerName; final String? tin; final bool registered; final bool contributing;
  final String? lastContribution; final int monthsOwed;
  EmployerCompliance({required this.employerName, this.tin, this.registered = false,
    this.contributing = false, this.lastContribution, this.monthsOwed = 0});
  factory EmployerCompliance.fromJson(Map<String, dynamic> json) => EmployerCompliance(
    employerName: json['employer_name'] ?? '', tin: json['tin'],
    registered: _parseBool(json['registered']), contributing: _parseBool(json['contributing']),
    lastContribution: json['last_contribution'], monthsOwed: _parseInt(json['months_owed']));
}
