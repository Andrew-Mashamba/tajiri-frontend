import 'tajiri_graphql_client.dart';

/// GraphQL business module — businesses, invoices, expenses, customers, debts, employees, payroll, POs, suppliers, quotes, appointments.
class GraphqlBusinessService {
  static const _businessFields = r'''
    id userId name businessType phone email address
    registrationNumber tinNumber isActive createdAt
  ''';

  static const _invoiceFields = r'''
    id businessId invoiceNumber customerId customerName items
    subtotal vatAmount vatRate totalAmount amountPaid status
    dueDate notes createdAt paidAt
  ''';

  static const _expenseFields = r'''
    id businessId category description amount expenseDate
    vendorName paymentMethod notes isRecurring createdAt
  ''';

  static const _customerFields = r'''
    id businessId name phone email address
    totalPurchases totalDebt notes createdAt
  ''';

  static const _debtFields = r'''
    id businessId customerId customerName customerPhone
    amount paidAmount description dueDate status createdAt
  ''';

  static const _debtSummaryFields = r'''
    totalOutstanding totalOverdue overdueCount pendingCount partialCount
  ''';

  static const _employeeFields = r'''
    id businessId name phone nidaNumber position grossSalary
    startDate bankAccount bankName isActive createdAt
  ''';

  static const _payrollEntryFields = r'''
    employeeId employeeName grossSalary paye nssfEmployee nssfEmployer
    sdl wcf netSalary
  ''';

  static const _payrollRunFields = r'''
    id businessId month year employees { $_payrollEntryFields }
    totalGross totalNet totalPaye totalNssf totalSdl totalWcf status createdAt
  ''';

  static const _purchaseOrderFields = r'''
    id businessId poNumber supplierId supplierName items
    subtotal vatAmount totalAmount status expectedDeliveryDate notes createdAt
  ''';

  static const _supplierFields = r'''
    id businessId name phone email address tinNumber notes createdAt
  ''';

  static const _quoteFields = r'''
    id businessId quoteNumber customerId customerName items
    subtotal vatAmount vatRate totalAmount status validUntil notes
    convertedInvoiceId createdAt
  ''';

  static const _appointmentFields = r'''
    id businessId customerId customerName customerPhone serviceName
    date startTime endTime durationMinutes status depositAmount notes createdAt
  ''';

  static Map<String, dynamic> _businessFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'user_id': row['userId'],
        'name': row['name'],
        'type': row['businessType'],
        'phone': row['phone'],
        'email': row['email'],
        'address': row['address'],
        'registration_number': row['registrationNumber'],
        'tin_number': row['tinNumber'],
        'is_active': row['isActive'],
        'created_at': row['createdAt'],
      };

  static Map<String, dynamic> _invoiceFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'invoice_number': row['invoiceNumber'],
        'customer_id': row['customerId'],
        'customer_name': row['customerName'],
        'items': row['items'] ?? [],
        'subtotal': row['subtotal'],
        'vat_amount': row['vatAmount'],
        'vat_rate': row['vatRate'],
        'total_amount': row['totalAmount'],
        'amount_paid': row['amountPaid'],
        'status': row['status'],
        'due_date': row['dueDate'],
        'notes': row['notes'],
        'created_at': row['createdAt'],
        'paid_at': row['paidAt'],
      };

  static Map<String, dynamic> _expenseFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'category': row['category'],
        'description': row['description'],
        'amount': row['amount'],
        'date': row['expenseDate'],
        'vendor_name': row['vendorName'],
        'payment_method': row['paymentMethod'],
        'notes': row['notes'],
        'is_recurring': row['isRecurring'],
        'created_at': row['createdAt'],
      };

  static Future<List<Map<String, dynamic>>> getMyBusinesses() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBusinesses {
          myBusinesses { $_businessFields }
        }
        ''',
        auth: true,
      );
      final rows = data['myBusinesses'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_businessFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createBusiness(Map<String, dynamic> body) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusiness(\$input: CreateBusinessInput!) {
          createBusiness(input: \$input) { $_businessFields }
        }
        ''',
        variables: {
          'input': {
            'name': body['name'],
            'businessType': body['type'] ?? body['business_type'] ?? 'sole_proprietor',
            if (body['phone'] != null) 'phone': body['phone'],
            if (body['email'] != null) 'email': body['email'],
            if (body['address'] != null) 'address': body['address'],
            if (body['registration_number'] != null)
              'registrationNumber': body['registration_number'],
            if (body['tin_number'] != null) 'tinNumber': body['tin_number'],
          },
        },
        auth: true,
      );
      final row = result['createBusiness'];
      if (row is Map<String, dynamic>) return _businessFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getInvoices(
    int businessId, {
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessInvoices(\$businessId: ID!, \$status: String) {
          businessInvoices(businessId: \$businessId, status: \$status) {
            $_invoiceFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (status != null) 'status': status,
        },
        auth: true,
      );
      final rows = data['businessInvoices'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_invoiceFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createInvoice(Map<String, dynamic> body) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessInvoice(\$input: CreateBusinessInvoiceInput!) {
          createBusinessInvoice(input: \$input) { $_invoiceFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': (body['business_id'] ?? body['businessId']).toString(),
            if (body['customer_id'] != null)
              'customerId': body['customer_id'].toString(),
            if (body['customer_name'] != null) 'customerName': body['customer_name'],
            if (body['items'] != null) 'items': body['items'],
            if (body['subtotal'] != null) 'subtotal': body['subtotal'],
            if (body['vat_amount'] != null) 'vatAmount': body['vat_amount'],
            if (body['vat_rate'] != null) 'vatRate': body['vat_rate'],
            if (body['total_amount'] != null) 'totalAmount': body['total_amount'],
            if (body['due_date'] != null) 'dueDate': body['due_date'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessInvoice'];
      if (row is Map<String, dynamic>) return _invoiceFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> sendInvoice(int invoiceId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SendBusinessInvoice(\$invoiceId: ID!) {
          sendBusinessInvoice(invoiceId: \$invoiceId) { id }
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      return result['sendBusinessInvoice'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> markInvoicePaid(int invoiceId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation MarkBusinessInvoicePaid(\$invoiceId: ID!) {
          markBusinessInvoicePaid(invoiceId: \$invoiceId) { id }
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      return result['markBusinessInvoicePaid'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getInvoicePdfUrl(int invoiceId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessInvoicePdfUrl(\$invoiceId: ID!) {
          businessInvoicePdfUrl(invoiceId: \$invoiceId)
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      return data['businessInvoicePdfUrl']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getExpenses(
    int businessId, {
    String? category,
    int? month,
    int? year,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessExpenses(\$businessId: ID!, \$category: String, \$month: Int, \$year: Int) {
          businessExpenses(
            businessId: \$businessId
            category: \$category
            month: \$month
            year: \$year
          ) { $_expenseFields }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (category != null) 'category': category,
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
        auth: true,
      );
      final rows = data['businessExpenses'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_expenseFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createExpense(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessExpense(\$input: CreateBusinessExpenseInput!) {
          createBusinessExpense(input: \$input) { $_expenseFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': businessId.toString(),
            'category': body['category'] ?? 'other',
            'amount': body['amount'],
            if (body['description'] != null) 'description': body['description'],
            if (body['date'] != null) 'expenseDate': body['date'],
            if (body['vendor_name'] != null) 'vendorName': body['vendor_name'],
            if (body['payment_method'] != null)
              'paymentMethod': body['payment_method'],
            if (body['notes'] != null) 'notes': body['notes'],
            if (body['is_recurring'] != null) 'isRecurring': body['is_recurring'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessExpense'];
      if (row is Map<String, dynamic>) return _expenseFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _customerFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'name': row['name'],
        'phone': row['phone'],
        'email': row['email'],
        'address': row['address'],
        'total_purchases': row['totalPurchases'],
        'total_debt': row['totalDebt'],
        'notes': row['notes'],
        'created_at': row['createdAt'],
      };

  static Map<String, dynamic> _debtFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'customer_id': row['customerId'],
        'customer_name': row['customerName'],
        'customer_phone': row['customerPhone'],
        'amount': row['amount'],
        'paid_amount': row['paidAmount'],
        'description': row['description'],
        'due_date': row['dueDate'],
        'status': row['status'],
        'created_at': row['createdAt'],
      };

  static Map<String, dynamic> _debtSummaryFromGql(Map<String, dynamic> row) => {
        'total_outstanding': row['totalOutstanding'],
        'total_overdue': row['totalOverdue'],
        'overdue_count': row['overdueCount'],
        'pending_count': row['pendingCount'],
        'partial_count': row['partialCount'],
      };

  static Future<List<Map<String, dynamic>>> getCustomers(
    int businessId, {
    String? search,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessCustomers(\$businessId: ID!, \$search: String) {
          businessCustomers(businessId: \$businessId, search: \$search) {
            $_customerFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (search != null) 'search': search,
        },
        auth: true,
      );
      final rows = data['businessCustomers'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_customerFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createCustomer(Map<String, dynamic> body) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessCustomer(\$input: CreateBusinessCustomerInput!) {
          createBusinessCustomer(input: \$input) { $_customerFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': (body['business_id'] ?? body['businessId']).toString(),
            'name': body['name'],
            if (body['phone'] != null) 'phone': body['phone'],
            if (body['email'] != null) 'email': body['email'],
            if (body['address'] != null) 'address': body['address'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessCustomer'];
      if (row is Map<String, dynamic>) return _customerFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateCustomer(
    int customerId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessCustomer(
          \$customerId: ID!
          \$input: UpdateBusinessCustomerInput!
        ) {
          updateBusinessCustomer(customerId: \$customerId, input: \$input) {
            $_customerFields
          }
        }
        ''',
        variables: {
          'customerId': customerId.toString(),
          'input': {
            if (body['name'] != null) 'name': body['name'],
            if (body['phone'] != null) 'phone': body['phone'],
            if (body['email'] != null) 'email': body['email'],
            if (body['address'] != null) 'address': body['address'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['updateBusinessCustomer'];
      if (row is Map<String, dynamic>) return _customerFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteCustomer(int customerId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteBusinessCustomer(\$customerId: ID!) {
          deleteBusinessCustomer(customerId: \$customerId)
        }
        ''',
        variables: {'customerId': customerId.toString()},
        auth: true,
      );
      return result['deleteBusinessCustomer'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getDebts(
    int businessId, {
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessDebts(\$businessId: ID!, \$status: String) {
          businessDebts(businessId: \$businessId, status: \$status) {
            $_debtFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (status != null) 'status': status,
        },
        auth: true,
      );
      final rows = data['businessDebts'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_debtFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createDebt(Map<String, dynamic> body) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessDebt(\$input: CreateBusinessDebtInput!) {
          createBusinessDebt(input: \$input) { $_debtFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': (body['business_id'] ?? body['businessId']).toString(),
            'amount': body['amount'],
            if (body['customer_id'] != null)
              'customerId': body['customer_id'].toString(),
            if (body['customer_name'] != null) 'customerName': body['customer_name'],
            if (body['customer_phone'] != null) 'customerPhone': body['customer_phone'],
            if (body['description'] != null) 'description': body['description'],
            if (body['due_date'] != null) 'dueDate': body['due_date'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessDebt'];
      if (row is Map<String, dynamic>) return _debtFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> payDebt(int debtId, double amount) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PayBusinessDebt(\$debtId: ID!, \$amount: Float!) {
          payBusinessDebt(debtId: \$debtId, amount: \$amount) { $_debtFields }
        }
        ''',
        variables: {
          'debtId': debtId.toString(),
          'amount': amount,
        },
        auth: true,
      );
      final row = result['payBusinessDebt'];
      if (row is Map<String, dynamic>) return _debtFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDebtSummary(int businessId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessDebtSummary(\$businessId: ID!) {
          businessDebtSummary(businessId: \$businessId) { $_debtSummaryFields }
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final row = data['businessDebtSummary'];
      if (row is Map<String, dynamic>) return _debtSummaryFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _employeeFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'name': row['name'],
        'phone': row['phone'],
        'nida_number': row['nidaNumber'],
        'position': row['position'],
        'gross_salary': row['grossSalary'],
        'start_date': row['startDate'],
        'bank_account': row['bankAccount'],
        'bank_name': row['bankName'],
        'is_active': row['isActive'],
        'created_at': row['createdAt'],
      };

  static Map<String, dynamic> _payrollEntryFromGql(Map<String, dynamic> row) => {
        'employee_id': row['employeeId'],
        'employee_name': row['employeeName'],
        'gross_salary': row['grossSalary'],
        'paye': row['paye'],
        'nssf_employee': row['nssfEmployee'],
        'nssf_employer': row['nssfEmployer'],
        'sdl': row['sdl'],
        'wcf': row['wcf'],
        'net_salary': row['netSalary'],
      };

  static Map<String, dynamic> _payrollRunFromGql(Map<String, dynamic> row) {
    final entries = row['employees'];
    return {
      'id': row['id'],
      'business_id': row['businessId'],
      'month': row['month'],
      'year': row['year'],
      'employees': entries is List
          ? entries
              .whereType<Map<String, dynamic>>()
              .map(_payrollEntryFromGql)
              .toList()
          : [],
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

  static Future<List<Map<String, dynamic>>> getEmployees(int businessId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessEmployees(\$businessId: ID!) {
          businessEmployees(businessId: \$businessId) { $_employeeFields }
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final rows = data['businessEmployees'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_employeeFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createEmployee(Map<String, dynamic> body) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessEmployee(\$input: CreateBusinessEmployeeInput!) {
          createBusinessEmployee(input: \$input) { $_employeeFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': (body['business_id'] ?? body['businessId']).toString(),
            'name': body['name'],
            if (body['phone'] != null) 'phone': body['phone'],
            if (body['nida_number'] != null) 'nidaNumber': body['nida_number'],
            if (body['position'] != null) 'position': body['position'],
            'grossSalary': body['gross_salary'] ?? body['grossSalary'] ?? 0,
            if (body['start_date'] != null) 'startDate': body['start_date'],
            if (body['bank_account'] != null) 'bankAccount': body['bank_account'],
            if (body['bank_name'] != null) 'bankName': body['bank_name'],
            if (body['is_active'] != null) 'isActive': body['is_active'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessEmployee'];
      if (row is Map<String, dynamic>) return _employeeFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateEmployee(
    int employeeId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessEmployee(
          \$employeeId: ID!
          \$input: UpdateBusinessEmployeeInput!
        ) {
          updateBusinessEmployee(employeeId: \$employeeId, input: \$input) {
            $_employeeFields
          }
        }
        ''',
        variables: {
          'employeeId': employeeId.toString(),
          'input': {
            if (body['name'] != null) 'name': body['name'],
            if (body['phone'] != null) 'phone': body['phone'],
            if (body['nida_number'] != null) 'nidaNumber': body['nida_number'],
            if (body['position'] != null) 'position': body['position'],
            if (body['gross_salary'] != null) 'grossSalary': body['gross_salary'],
            if (body['start_date'] != null) 'startDate': body['start_date'],
            if (body['bank_account'] != null) 'bankAccount': body['bank_account'],
            if (body['bank_name'] != null) 'bankName': body['bank_name'],
            if (body['is_active'] != null) 'isActive': body['is_active'],
          },
        },
        auth: true,
      );
      final row = result['updateBusinessEmployee'];
      if (row is Map<String, dynamic>) return _employeeFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> removeEmployee(int employeeId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RemoveBusinessEmployee(\$employeeId: ID!) {
          removeBusinessEmployee(employeeId: \$employeeId)
        }
        ''',
        variables: {'employeeId': employeeId.toString()},
        auth: true,
      );
      return result['removeBusinessEmployee'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> calculatePayroll(
    int businessId,
    int month,
    int year,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CalculateBusinessPayroll(
          \$businessId: ID!
          \$month: Int!
          \$year: Int!
        ) {
          calculateBusinessPayroll(
            businessId: \$businessId
            month: \$month
            year: \$year
          ) { $_payrollRunFields }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          'month': month,
          'year': year,
        },
        auth: true,
      );
      final row = result['calculateBusinessPayroll'];
      if (row is Map<String, dynamic>) return _payrollRunFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> approvePayroll(int payrollId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ApproveBusinessPayroll(\$payrollId: ID!) {
          approveBusinessPayroll(payrollId: \$payrollId) { $_payrollRunFields }
        }
        ''',
        variables: {'payrollId': payrollId.toString()},
        auth: true,
      );
      final row = result['approveBusinessPayroll'];
      if (row is Map<String, dynamic>) return _payrollRunFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getPayrollHistory(int businessId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessPayrollHistory(\$businessId: ID!) {
          businessPayrollHistory(businessId: \$businessId) { $_payrollRunFields }
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final rows = data['businessPayrollHistory'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_payrollRunFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> _purchaseOrderFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'po_number': row['poNumber'],
        'supplier_id': row['supplierId'],
        'supplier_name': row['supplierName'],
        'items': row['items'] ?? [],
        'subtotal': row['subtotal'],
        'vat_amount': row['vatAmount'],
        'total_amount': row['totalAmount'],
        'status': row['status'],
        'expected_delivery_date': row['expectedDeliveryDate'],
        'notes': row['notes'],
        'created_at': row['createdAt'],
      };

  static Future<List<Map<String, dynamic>>> getPurchaseOrders(
    int businessId, {
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessPurchaseOrders(\$businessId: ID!, \$status: String) {
          businessPurchaseOrders(businessId: \$businessId, status: \$status) {
            $_purchaseOrderFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (status != null) 'status': status,
        },
        auth: true,
      );
      final rows = data['businessPurchaseOrders'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_purchaseOrderFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createPurchaseOrder(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessPurchaseOrder(\$input: CreateBusinessPurchaseOrderInput!) {
          createBusinessPurchaseOrder(input: \$input) { $_purchaseOrderFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': businessId.toString(),
            if (body['supplier_id'] != null)
              'supplierId': body['supplier_id'].toString(),
            if (body['supplier_name'] != null) 'supplierName': body['supplier_name'],
            if (body['items'] != null) 'items': body['items'],
            if (body['subtotal'] != null) 'subtotal': body['subtotal'],
            if (body['vat_amount'] != null) 'vatAmount': body['vat_amount'],
            if (body['total_amount'] != null) 'totalAmount': body['total_amount'],
            if (body['status'] != null) 'status': body['status'],
            if (body['expected_delivery_date'] != null)
              'expectedDeliveryDate': body['expected_delivery_date'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessPurchaseOrder'];
      if (row is Map<String, dynamic>) return _purchaseOrderFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> markPurchaseOrderReceived(int poId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation MarkBusinessPurchaseOrderReceived(\$poId: ID!) {
          markBusinessPurchaseOrderReceived(poId: \$poId) { $_purchaseOrderFields }
        }
        ''',
        variables: {'poId': poId.toString()},
        auth: true,
      );
      final row = result['markBusinessPurchaseOrderReceived'];
      if (row is Map<String, dynamic>) return _purchaseOrderFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> cancelPurchaseOrder(int poId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelBusinessPurchaseOrder(\$poId: ID!) {
          cancelBusinessPurchaseOrder(poId: \$poId) { $_purchaseOrderFields }
        }
        ''',
        variables: {'poId': poId.toString()},
        auth: true,
      );
      final row = result['cancelBusinessPurchaseOrder'];
      if (row is Map<String, dynamic>) return _purchaseOrderFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _supplierFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'name': row['name'],
        'phone': row['phone'],
        'email': row['email'],
        'address': row['address'],
        'tin_number': row['tinNumber'],
        'notes': row['notes'],
        'created_at': row['createdAt'],
      };

  static Map<String, dynamic> _quoteFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'quote_number': row['quoteNumber'],
        'customer_id': row['customerId'],
        'customer_name': row['customerName'],
        'items': row['items'] ?? [],
        'subtotal': row['subtotal'],
        'vat_amount': row['vatAmount'],
        'vat_rate': row['vatRate'],
        'total_amount': row['totalAmount'],
        'status': row['status'],
        'valid_until': row['validUntil'],
        'notes': row['notes'],
        'converted_invoice_id': row['convertedInvoiceId'],
        'created_at': row['createdAt'],
      };

  static Map<String, dynamic> _appointmentFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'customer_id': row['customerId'],
        'customer_name': row['customerName'],
        'customer_phone': row['customerPhone'],
        'service_name': row['serviceName'],
        'date': row['date'],
        'start_time': row['startTime'],
        'end_time': row['endTime'],
        'duration_minutes': row['durationMinutes'],
        'status': row['status'],
        'deposit_amount': row['depositAmount'],
        'notes': row['notes'],
        'created_at': row['createdAt'],
      };

  static Future<List<Map<String, dynamic>>> getSuppliers(
    int businessId, {
    String? search,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessSuppliers(\$businessId: ID!, \$search: String) {
          businessSuppliers(businessId: \$businessId, search: \$search) {
            $_supplierFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (search != null) 'search': search,
        },
        auth: true,
      );
      final rows = data['businessSuppliers'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_supplierFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createSupplier(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessSupplier(\$input: CreateBusinessSupplierInput!) {
          createBusinessSupplier(input: \$input) { $_supplierFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': businessId.toString(),
            'name': body['name'],
            if (body['phone'] != null) 'phone': body['phone'],
            if (body['email'] != null) 'email': body['email'],
            if (body['address'] != null) 'address': body['address'],
            if (body['tin_number'] != null) 'tinNumber': body['tin_number'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessSupplier'];
      if (row is Map<String, dynamic>) return _supplierFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateSupplier(
    int supplierId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessSupplier(
          \$supplierId: ID!
          \$input: UpdateBusinessSupplierInput!
        ) {
          updateBusinessSupplier(supplierId: \$supplierId, input: \$input) {
            $_supplierFields
          }
        }
        ''',
        variables: {
          'supplierId': supplierId.toString(),
          'input': {
            if (body['name'] != null) 'name': body['name'],
            if (body['phone'] != null) 'phone': body['phone'],
            if (body['email'] != null) 'email': body['email'],
            if (body['address'] != null) 'address': body['address'],
            if (body['tin_number'] != null) 'tinNumber': body['tin_number'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['updateBusinessSupplier'];
      if (row is Map<String, dynamic>) return _supplierFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteSupplier(int supplierId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteBusinessSupplier(\$supplierId: ID!) {
          deleteBusinessSupplier(supplierId: \$supplierId)
        }
        ''',
        variables: {'supplierId': supplierId.toString()},
        auth: true,
      );
      return result['deleteBusinessSupplier'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getQuotes(
    int businessId, {
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessQuotes(\$businessId: ID!, \$status: String) {
          businessQuotes(businessId: \$businessId, status: \$status) {
            $_quoteFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (status != null) 'status': status,
        },
        auth: true,
      );
      final rows = data['businessQuotes'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_quoteFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createQuote(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessQuote(\$input: CreateBusinessQuoteInput!) {
          createBusinessQuote(input: \$input) { $_quoteFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': businessId.toString(),
            if (body['customer_id'] != null)
              'customerId': body['customer_id'].toString(),
            if (body['customer_name'] != null) 'customerName': body['customer_name'],
            if (body['items'] != null) 'items': body['items'],
            if (body['subtotal'] != null) 'subtotal': body['subtotal'],
            if (body['vat_amount'] != null) 'vatAmount': body['vat_amount'],
            if (body['vat_rate'] != null) 'vatRate': body['vat_rate'],
            if (body['total_amount'] != null) 'totalAmount': body['total_amount'],
            if (body['status'] != null) 'status': body['status'],
            if (body['valid_until'] != null) 'validUntil': body['valid_until'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessQuote'];
      if (row is Map<String, dynamic>) return _quoteFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> sendQuote(int quoteId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SendBusinessQuote(\$quoteId: ID!) {
          sendBusinessQuote(quoteId: \$quoteId) { id }
        }
        ''',
        variables: {'quoteId': quoteId.toString()},
        auth: true,
      );
      return result['sendBusinessQuote'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateQuoteStatus(int quoteId, String status) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessQuoteStatus(\$quoteId: ID!, \$status: String!) {
          updateBusinessQuoteStatus(quoteId: \$quoteId, status: \$status) { id }
        }
        ''',
        variables: {'quoteId': quoteId.toString(), 'status': status},
        auth: true,
      );
      return result['updateBusinessQuoteStatus'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> convertQuoteToInvoice(int quoteId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ConvertBusinessQuoteToInvoice(\$quoteId: ID!) {
          convertBusinessQuoteToInvoice(quoteId: \$quoteId) {
            id businessId invoiceNumber customerId customerName items
            subtotal vatAmount vatRate totalAmount amountPaid status
            dueDate notes createdAt paidAt
          }
        }
        ''',
        variables: {'quoteId': quoteId.toString()},
        auth: true,
      );
      final row = result['convertBusinessQuoteToInvoice'];
      if (row is Map<String, dynamic>) {
        return {
          'id': row['id'],
          'business_id': row['businessId'],
          'invoice_number': row['invoiceNumber'],
          'customer_id': row['customerId'],
          'customer_name': row['customerName'],
          'items': row['items'] ?? [],
          'subtotal': row['subtotal'],
          'vat_amount': row['vatAmount'],
          'vat_rate': row['vatRate'],
          'total_amount': row['totalAmount'],
          'amount_paid': row['amountPaid'],
          'status': row['status'],
          'due_date': row['dueDate'],
          'notes': row['notes'],
          'created_at': row['createdAt'],
          'paid_at': row['paidAt'],
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAppointments(
    int businessId, {
    String? date,
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessAppointments(\$businessId: ID!, \$date: String, \$status: String) {
          businessAppointments(businessId: \$businessId, date: \$date, status: \$status) {
            $_appointmentFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (date != null) 'date': date,
          if (status != null) 'status': status,
        },
        auth: true,
      );
      final rows = data['businessAppointments'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_appointmentFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createAppointment(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessAppointment(\$input: CreateBusinessAppointmentInput!) {
          createBusinessAppointment(input: \$input) { $_appointmentFields }
        }
        ''',
        variables: {
          'input': {
            'businessId': businessId.toString(),
            if (body['customer_id'] != null)
              'customerId': body['customer_id'].toString(),
            if (body['customer_name'] != null) 'customerName': body['customer_name'],
            if (body['customer_phone'] != null) 'customerPhone': body['customer_phone'],
            if (body['service_name'] != null) 'serviceName': body['service_name'],
            if (body['date'] != null) 'date': body['date'],
            if (body['start_time'] != null) 'startTime': body['start_time'],
            if (body['end_time'] != null) 'endTime': body['end_time'],
            if (body['duration_minutes'] != null)
              'durationMinutes': body['duration_minutes'],
            if (body['deposit_amount'] != null) 'depositAmount': body['deposit_amount'],
            if (body['notes'] != null) 'notes': body['notes'],
            if (body['status'] != null) 'status': body['status'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessAppointment'];
      if (row is Map<String, dynamic>) return _appointmentFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateAppointmentStatus(int appointmentId, String status) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessAppointmentStatus(
          \$appointmentId: ID!
          \$status: String!
        ) {
          updateBusinessAppointmentStatus(
            appointmentId: \$appointmentId
            status: \$status
          ) { id }
        }
        ''',
        variables: {
          'appointmentId': appointmentId.toString(),
          'status': status,
        },
        auth: true,
      );
      return result['updateBusinessAppointmentStatus'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelAppointment(int appointmentId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelBusinessAppointment(\$appointmentId: ID!) {
          cancelBusinessAppointment(appointmentId: \$appointmentId) { id }
        }
        ''',
        variables: {'appointmentId': appointmentId.toString()},
        auth: true,
      );
      return result['cancelBusinessAppointment'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteExpense(int expenseId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteBusinessExpense(\$expenseId: ID!) {
          deleteBusinessExpense(expenseId: \$expenseId)
        }
        ''',
        variables: {'expenseId': expenseId.toString()},
        auth: true,
      );
      return result['deleteBusinessExpense'] == true;
    } catch (_) {
      return false;
    }
  }
}
