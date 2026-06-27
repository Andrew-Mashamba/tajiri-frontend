import 'tajiri_graphql_client.dart';

/// GraphQL business module — businesses, invoices, expenses (Phase 49).
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
