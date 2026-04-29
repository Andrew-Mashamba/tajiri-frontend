// lib/myjob/models/myjob_models.dart
export '../../team/models/work_models.dart';
export '../../team/models/task_models.dart';

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class MyPayslip {
  final int? id;
  final String businessName;
  final int month;
  final int year;
  final double grossSalary;
  final double paye;
  final double nssfEmployee;
  final double nssfEmployer;
  final double sdl;
  final double wcf;
  final double netSalary;
  final String status;

  const MyPayslip({
    this.id,
    required this.businessName,
    required this.month,
    required this.year,
    required this.grossSalary,
    required this.paye,
    required this.nssfEmployee,
    required this.nssfEmployer,
    required this.sdl,
    required this.wcf,
    required this.netSalary,
    required this.status,
  });

  double get totalDeductions => paye + nssfEmployee;
  double get totalEmployerCost => grossSalary + nssfEmployer + sdl + wcf;

  factory MyPayslip.fromJson(Map<String, dynamic> j) => MyPayslip(
        id: _parseInt(j['id']),
        businessName: j['business_name']?.toString() ?? '',
        month: _parseInt(j['month']) ?? 0,
        year: _parseInt(j['year']) ?? 0,
        grossSalary: _parseDouble(j['gross_salary']),
        paye: _parseDouble(j['paye']),
        nssfEmployee: _parseDouble(j['nssf_employee']),
        nssfEmployer: _parseDouble(j['nssf_employer']),
        sdl: _parseDouble(j['sdl']),
        wcf: _parseDouble(j['wcf']),
        netSalary: _parseDouble(j['net_salary']),
        status: j['status']?.toString() ?? 'draft',
      );
}
