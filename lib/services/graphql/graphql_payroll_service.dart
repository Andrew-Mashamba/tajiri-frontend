import '../models/payroll_models.dart';
import '../../services/graphql/graphql_business_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL payroll / statutory (Phase 67).
class GraphqlPayrollService {
  static const _payrollRunFields = r'''
    id
    businessId
    month
    year
    employees {
      employeeId
      employeeName
      grossSalary
      paye
      nssfEmployee
      nssfEmployer
      sdl
      wcf
      netSalary
    }
    totalGross
    totalNet
    totalPaye
    totalNssf
    totalSdl
    totalWcf
    status
    createdAt
  ''';

  static const _statutoryFields = r'''
    id
    type
    month
    year
    amount
    dueDate
    remitted
    remittedAt
  ''';

  static Map<String, dynamic> _payrollRunToLegacy(Map<String, dynamic> row) {
    final entries = row['employees'] as List? ?? [];
    return {
      'id': int.parse(row['id'].toString()),
      'business_id': int.parse(row['businessId'].toString()),
      'month': row['month'],
      'year': row['year'],
      'employees': entries.whereType<Map<String, dynamic>>().map((e) => {
            'employee_id': e['employeeId'] != null
                ? int.parse(e['employeeId'].toString())
                : null,
            'employee_name': e['employeeName'],
            'gross_salary': e['grossSalary'],
            'paye': e['paye'],
            'nssf_employee': e['nssfEmployee'],
            'nssf_employer': e['nssfEmployer'],
            'sdl': e['sdl'],
            'wcf': e['wcf'],
            'net_salary': e['netSalary'],
          }).toList(),
      'total_gross': row['totalGross'],
      'total_net': row['totalNet'],
      'total_paye': row['totalPaye'],
      'total_nssf': row['totalNssf'],
      'total_sdl': row['totalSdl'],
      'total_wcf': row['totalWcf'],
      'status': row['status'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _statutoryToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'type': row['type'],
      'month': row['month'],
      'year': row['year'],
      'amount': row['amount'],
      'due_date': row['dueDate'],
      'remitted': row['remitted'] == true,
      'remitted_at': row['remittedAt'],
    };
  }

  static Future<List<PayrollRun>> getHistory(int businessId) async {
    final rows = await GraphqlBusinessService.getPayrollHistory(businessId);
    return rows.map((row) => PayrollRun.fromJson(row)).toList();
  }

  static Future<PayrollRun?> calculate(
      int businessId, int month, int year) async {
    final row = await GraphqlBusinessService.calculatePayroll(businessId, month, year);
    if (row == null) return null;
    return PayrollRun.fromJson(row);
  }

  static Future<bool> approve(int payrollId) async {
    final row = await GraphqlBusinessService.approvePayroll(payrollId);
    return row != null;
  }

  static Future<List<StatutoryObligation>> getStatutory(int businessId) async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query BusinessPayrollStatutory(\$businessId: ID!) {
        businessPayrollStatutory(businessId: \$businessId) {
          $_statutoryFields
        }
      }
      ''',
      variables: {'businessId': businessId.toString()},
      auth: true,
    );
    final rows = data['businessPayrollStatutory'] as List? ?? [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => StatutoryObligation.fromJson(_statutoryToLegacy(row)))
        .toList();
  }

  static Future<bool> markRemitted(int obligationId) async {
    final data = await TajiriGraphqlClient.instance.mutate(
      '''
      mutation RemitBusinessPayrollStatutory(\$obligationId: ID!) {
        remitBusinessPayrollStatutory(obligationId: \$obligationId) {
          $_statutoryFields
        }
      }
      ''',
      variables: {'obligationId': obligationId.toString()},
      auth: true,
    );
    final row = data['remitBusinessPayrollStatutory'];
    return row is Map<String, dynamic> && row['remitted'] == true;
  }
}
