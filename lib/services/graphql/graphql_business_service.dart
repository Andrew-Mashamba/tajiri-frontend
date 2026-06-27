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

  static const _invoicePaymentFields = r'''
    id invoiceId amount method reference notes paidAt createdAt
  ''';

  static const _invoiceDeliveryFields = r'''
    id invoiceId deliveryType status recipient sentAt createdAt
  ''';

  static const _creditNoteFields = r'''
    id invoiceId businessId creditNoteNumber reason reasonText items
    subtotal vatAmount totalAmount status applicationMethod issuedAt createdAt
  ''';

  static const _invoiceSettingsFields = r'''
    numberPrefix nextSequence defaultPaymentTerms defaultIncludeVat
    defaultPaymentInstructions defaultNotes autoReminderEnabled
    reminderDaysAfterDue reminderChannels logoUrl
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

  static const _payableFields = r'''
    id businessId poId supplierId supplierName poNumber
    amount paidAmount remainingAmount dueDate status notes createdAt
  ''';

  static const _recurringPoFields = r'''
    id businessId supplierId supplierName items frequency nextRunDate endDate
    totalAmount totalGenerated maxOrders deliveryOffsetDays autoSend isActive
    notes createdAt
  ''';

  static const _recurringInvoiceFields = r'''
    id businessId customerId customerName items subtotal vatAmount vatRate
    totalAmount frequency customIntervalDays nextIssueDate startDate endDate
    maxInvoices totalIssued isActive autoSend autoSendChannels createdAt
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

  static Map<String, dynamic> _invoicePaymentFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'invoice_id': row['invoiceId'],
        'amount': row['amount'],
        'method': row['method'],
        'reference': row['reference'],
        'notes': row['notes'],
        'paid_at': row['paidAt'],
        'created_at': row['createdAt'],
      };

  static Map<String, dynamic> _invoiceDeliveryFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'invoice_id': row['invoiceId'],
        'delivery_type': row['deliveryType'],
        'status': row['status'],
        'recipient': row['recipient'],
        'sent_at': row['sentAt'],
        'created_at': row['createdAt'],
      };

  static Map<String, dynamic> _creditNoteFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'invoice_id': row['invoiceId'],
        'credit_note_number': row['creditNoteNumber'],
        'reason': row['reason'],
        'total_amount': row['totalAmount'],
        'status': row['status'],
        'issued_at': row['issuedAt'],
        'created_at': row['createdAt'],
        'items': row['items'] ?? [],
      };

  static Map<String, dynamic> _invoiceSettingsFromGql(Map<String, dynamic> row) => {
        'number_prefix': row['numberPrefix'],
        'next_sequence': row['nextSequence'],
        'default_payment_terms': row['defaultPaymentTerms'],
        'default_include_vat': row['defaultIncludeVat'],
        'default_payment_instructions': row['defaultPaymentInstructions'],
        'default_notes': row['defaultNotes'],
        'auto_reminder_enabled': row['autoReminderEnabled'],
        'reminder_days_after_due': row['reminderDaysAfterDue'] ?? [],
        'logo_url': row['logoUrl'],
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

  static Future<Map<String, dynamic>?> getInvoice(int invoiceId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessInvoice(\$invoiceId: ID!) {
          businessInvoice(invoiceId: \$invoiceId) { $_invoiceFields }
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      final row = data['businessInvoice'];
      if (row is Map<String, dynamic>) return _invoiceFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getInvoicePayments(int invoiceId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessInvoicePayments(\$invoiceId: ID!) {
          businessInvoicePayments(invoiceId: \$invoiceId) { $_invoicePaymentFields }
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      final rows = data['businessInvoicePayments'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_invoicePaymentFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getInvoiceDeliveries(int invoiceId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessInvoiceDeliveries(\$invoiceId: ID!) {
          businessInvoiceDeliveries(invoiceId: \$invoiceId) { $_invoiceDeliveryFields }
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      final rows = data['businessInvoiceDeliveries'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_invoiceDeliveryFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getInvoiceCreditNotes(int invoiceId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessInvoiceCreditNotes(\$invoiceId: ID!) {
          businessInvoiceCreditNotes(invoiceId: \$invoiceId) { $_creditNoteFields }
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      final rows = data['businessInvoiceCreditNotes'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_creditNoteFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> updateInvoice(
    int invoiceId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessInvoice(\$invoiceId: ID!, \$input: UpdateBusinessInvoiceInput!) {
          updateBusinessInvoice(invoiceId: \$invoiceId, input: \$input) { $_invoiceFields }
        }
        ''',
        variables: {
          'invoiceId': invoiceId.toString(),
          'input': {
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
            if (body['status'] != null) 'status': body['status'],
          },
        },
        auth: true,
      );
      final row = result['updateBusinessInvoice'];
      if (row is Map<String, dynamic>) return _invoiceFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> voidInvoice(int invoiceId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation VoidBusinessInvoice(\$invoiceId: ID!) {
          voidBusinessInvoice(invoiceId: \$invoiceId) { id }
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      return result['voidBusinessInvoice'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> recordInvoicePayment(
    int invoiceId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RecordBusinessInvoicePayment(\$invoiceId: ID!, \$input: RecordBusinessInvoicePaymentInput!) {
          recordBusinessInvoicePayment(invoiceId: \$invoiceId, input: \$input) { $_invoicePaymentFields }
        }
        ''',
        variables: {
          'invoiceId': invoiceId.toString(),
          'input': {
            'amount': body['amount'],
            'method': body['method'] ?? 'cash',
            if (body['reference'] != null) 'reference': body['reference'],
            if (body['notes'] != null) 'notes': body['notes'],
            if (body['paid_at'] != null) 'paidAt': body['paid_at'],
          },
        },
        auth: true,
      );
      final row = result['recordBusinessInvoicePayment'];
      if (row is Map<String, dynamic>) return _invoicePaymentFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> sendInvoiceMultiChannel(
    int invoiceId,
    List<String> channels,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SendBusinessInvoiceMultiChannel(\$invoiceId: ID!, \$input: SendBusinessInvoiceMultiChannelInput!) {
          sendBusinessInvoiceMultiChannel(invoiceId: \$invoiceId, input: \$input) { id }
        }
        ''',
        variables: {
          'invoiceId': invoiceId.toString(),
          'input': {'channels': channels},
        },
        auth: true,
      );
      return result['sendBusinessInvoiceMultiChannel'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendInvoiceReminder(
    int invoiceId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SendBusinessInvoiceReminder(\$invoiceId: ID!, \$input: SendBusinessInvoiceReminderInput!) {
          sendBusinessInvoiceReminder(invoiceId: \$invoiceId, input: \$input) { id }
        }
        ''',
        variables: {
          'invoiceId': invoiceId.toString(),
          'input': {
            'channel': body['channel'] ?? 'whatsapp',
            if (body['message'] != null) 'message': body['message'],
          },
        },
        auth: true,
      );
      return result['sendBusinessInvoiceReminder'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getInvoiceSettings(int businessId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessInvoiceSettings(\$businessId: ID!) {
          businessInvoiceSettings(businessId: \$businessId) { $_invoiceSettingsFields }
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final row = data['businessInvoiceSettings'];
      if (row is Map<String, dynamic>) return _invoiceSettingsFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateInvoiceSettings(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessInvoiceSettings(\$businessId: ID!, \$settings: JSON!) {
          updateBusinessInvoiceSettings(businessId: \$businessId, settings: \$settings) { $_invoiceSettingsFields }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          'settings': {
            if (body['number_prefix'] != null) 'number_prefix': body['number_prefix'],
            if (body['next_sequence'] != null) 'next_sequence': body['next_sequence'],
            if (body['default_payment_terms'] != null)
              'default_payment_terms': body['default_payment_terms'],
            if (body.containsKey('default_include_vat'))
              'default_include_vat': body['default_include_vat'],
            if (body.containsKey('default_payment_instructions'))
              'default_payment_instructions': body['default_payment_instructions'],
            if (body.containsKey('default_notes')) 'default_notes': body['default_notes'],
            if (body.containsKey('auto_reminder_enabled'))
              'auto_reminder_enabled': body['auto_reminder_enabled'],
            if (body['reminder_days_after_due'] != null)
              'reminder_days_after_due': body['reminder_days_after_due'],
            if (body['reminder_channels'] != null)
              'reminder_channels': body['reminder_channels'],
            if (body.containsKey('logo_url')) 'logo_url': body['logo_url'],
          },
        },
        auth: true,
      );
      final row = result['updateBusinessInvoiceSettings'];
      if (row is Map<String, dynamic>) return _invoiceSettingsFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getReceivedInvoices() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessReceivedInvoices {
          businessReceivedInvoices { $_invoiceFields }
        }
        ''',
        auth: true,
      );
      final rows = data['businessReceivedInvoices'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_invoiceFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createCreditNote(
    int invoiceId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessCreditNote(\$invoiceId: ID!, \$input: CreateBusinessCreditNoteInput!) {
          createBusinessCreditNote(invoiceId: \$invoiceId, input: \$input) { $_creditNoteFields }
        }
        ''',
        variables: {
          'invoiceId': invoiceId.toString(),
          'input': {
            if (body['items'] != null) 'items': body['items'],
            if (body['reason'] != null) 'reason': body['reason'],
            if (body['reason_text'] != null) 'reasonText': body['reason_text'],
            if (body['subtotal'] != null) 'subtotal': body['subtotal'],
            if (body['vat_amount'] != null) 'vatAmount': body['vat_amount'],
            if (body['total_amount'] != null) 'totalAmount': body['total_amount'],
            if (body['application_method'] != null)
              'applicationMethod': body['application_method'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessCreditNote'];
      if (row is Map<String, dynamic>) return _creditNoteFromGql(row);
      return null;
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

  static Map<String, dynamic> _payableFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'supplier_name': row['supplierName'],
        'po_number': row['poNumber'],
        'amount': row['amount'],
        'paid_amount': row['paidAmount'],
        'remaining_amount': row['remainingAmount'],
        'due_date': row['dueDate'],
        'status': row['status'],
      };

  static Map<String, dynamic> _recurringPoFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'supplier_id': row['supplierId'],
        'supplier_name': row['supplierName'],
        'items': row['items'] ?? [],
        'frequency': row['frequency'],
        'next_run_date': row['nextRunDate'],
        'end_date': row['endDate'],
        'total_amount': row['totalAmount'],
        'total_generated': row['totalGenerated'],
        'max_orders': row['maxOrders'],
        'delivery_offset_days': row['deliveryOffsetDays'],
        'auto_send': row['autoSend'],
        'is_active': row['isActive'],
        'notes': row['notes'],
      };

  static Future<List<Map<String, dynamic>>> getPayables(
    int businessId, {
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessSupplierPayables(\$businessId: ID!, \$status: String) {
          businessSupplierPayables(businessId: \$businessId, status: \$status) {
            $_payableFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (status != null) 'status': status,
        },
        auth: true,
      );
      final rows = data['businessSupplierPayables'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_payableFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createPayable(
    int poId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessSupplierPayable(
          \$poId: ID!
          \$input: CreateBusinessSupplierPayableInput!
        ) {
          createBusinessSupplierPayable(poId: \$poId, input: \$input) {
            $_payableFields
          }
        }
        ''',
        variables: {
          'poId': poId.toString(),
          'input': {
            if (body['due_date'] != null) 'dueDate': body['due_date'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessSupplierPayable'];
      if (row is Map<String, dynamic>) return _payableFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deletePayable(int payableId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteBusinessSupplierPayable(\$payableId: ID!) {
          deleteBusinessSupplierPayable(payableId: \$payableId)
        }
        ''',
        variables: {'payableId': payableId.toString()},
        auth: true,
      );
      return result['deleteBusinessSupplierPayable'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> recordPayablePayment(
    int payableId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RecordBusinessSupplierPayablePayment(
          \$payableId: ID!
          \$input: RecordBusinessSupplierPayablePaymentInput!
        ) {
          recordBusinessSupplierPayablePayment(payableId: \$payableId, input: \$input) {
            $_payableFields
          }
        }
        ''',
        variables: {
          'payableId': payableId.toString(),
          'input': {
            'amount': body['amount'],
            if (body['payment_date'] != null) 'paymentDate': body['payment_date'],
            if (body['payment_method'] != null) 'paymentMethod': body['payment_method'],
            if (body['reference'] != null) 'reference': body['reference'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['recordBusinessSupplierPayablePayment'];
      if (row is Map<String, dynamic>) return _payableFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getRecurringPurchaseOrders(
    int businessId, {
    int? supplierId,
    bool activeOnly = true,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessRecurringPurchaseOrders(
          \$businessId: ID!
          \$supplierId: ID
          \$activeOnly: Boolean
        ) {
          businessRecurringPurchaseOrders(
            businessId: \$businessId
            supplierId: \$supplierId
            activeOnly: \$activeOnly
          ) {
            $_recurringPoFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (supplierId != null) 'supplierId': supplierId.toString(),
          'activeOnly': activeOnly,
        },
        auth: true,
      );
      final rows = data['businessRecurringPurchaseOrders'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_recurringPoFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createRecurringPurchaseOrder(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessRecurringPurchaseOrder(
          \$input: CreateBusinessRecurringPurchaseOrderInput!
        ) {
          createBusinessRecurringPurchaseOrder(input: \$input) {
            $_recurringPoFields
          }
        }
        ''',
        variables: {
          'input': {
            'businessId': businessId.toString(),
            if (body['supplier_id'] != null)
              'supplierId': body['supplier_id'].toString(),
            if (body['supplier_name'] != null) 'supplierName': body['supplier_name'],
            if (body['items'] != null) 'items': body['items'],
            if (body['frequency'] != null) 'frequency': body['frequency'],
            if (body['next_run_date'] != null) 'nextRunDate': body['next_run_date'],
            if (body['end_date'] != null) 'endDate': body['end_date'],
            if (body['max_orders'] != null) 'maxOrders': body['max_orders'],
            if (body['delivery_offset_days'] != null)
              'deliveryOffsetDays': body['delivery_offset_days'],
            if (body['auto_send'] != null) 'autoSend': body['auto_send'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessRecurringPurchaseOrder'];
      if (row is Map<String, dynamic>) return _recurringPoFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateRecurringPurchaseOrder(
    int recurringId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessRecurringPurchaseOrder(
          \$recurringId: ID!
          \$input: UpdateBusinessRecurringPurchaseOrderInput!
        ) {
          updateBusinessRecurringPurchaseOrder(
            recurringId: \$recurringId
            input: \$input
          ) {
            $_recurringPoFields
          }
        }
        ''',
        variables: {
          'recurringId': recurringId.toString(),
          'input': {
            if (body['supplier_id'] != null)
              'supplierId': body['supplier_id'].toString(),
            if (body['supplier_name'] != null) 'supplierName': body['supplier_name'],
            if (body['items'] != null) 'items': body['items'],
            if (body['frequency'] != null) 'frequency': body['frequency'],
            if (body['next_run_date'] != null) 'nextRunDate': body['next_run_date'],
            if (body['end_date'] != null) 'endDate': body['end_date'],
            if (body['max_orders'] != null) 'maxOrders': body['max_orders'],
            if (body['delivery_offset_days'] != null)
              'deliveryOffsetDays': body['delivery_offset_days'],
            if (body['auto_send'] != null) 'autoSend': body['auto_send'],
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['updateBusinessRecurringPurchaseOrder'];
      if (row is Map<String, dynamic>) return _recurringPoFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> cancelRecurringPurchaseOrder(int recurringId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelBusinessRecurringPurchaseOrder(\$recurringId: ID!) {
          cancelBusinessRecurringPurchaseOrder(recurringId: \$recurringId) {
            id isActive
          }
        }
        ''',
        variables: {'recurringId': recurringId.toString()},
        auth: true,
      );
      final row = result['cancelBusinessRecurringPurchaseOrder'];
      return row is Map<String, dynamic> && row['isActive'] == false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> runRecurringPurchaseOrderNow(int recurringId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RunBusinessRecurringPurchaseOrderNow(\$recurringId: ID!) {
          runBusinessRecurringPurchaseOrderNow(recurringId: \$recurringId) {
            id totalGenerated
          }
        }
        ''',
        variables: {'recurringId': recurringId.toString()},
        auth: true,
      );
      return result['runBusinessRecurringPurchaseOrderNow'] is Map<String, dynamic>;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> _recurringInvoiceFromGql(Map<String, dynamic> row) =>
      {
        'id': row['id'],
        'business_id': row['businessId'],
        'customer_id': row['customerId'],
        'customer_name': row['customerName'],
        'items': row['items'] ?? [],
        'subtotal': row['subtotal'],
        'vat_amount': row['vatAmount'],
        'vat_rate': row['vatRate'],
        'total_amount': row['totalAmount'],
        'frequency': row['frequency'],
        'custom_interval_days': row['customIntervalDays'],
        'next_issue_date': row['nextIssueDate'],
        'start_date': row['startDate'],
        'end_date': row['endDate'],
        'max_invoices': row['maxInvoices'],
        'total_issued': row['totalIssued'],
        'is_active': row['isActive'],
        'auto_send': row['autoSend'],
        'auto_send_channels': row['autoSendChannels'] ?? [],
        'created_at': row['createdAt'],
      };

  static Future<List<Map<String, dynamic>>> getRecurringInvoices(
    int businessId, {
    bool activeOnly = false,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessRecurringInvoices(\$businessId: ID!, \$activeOnly: Boolean) {
          businessRecurringInvoices(
            businessId: \$businessId
            activeOnly: \$activeOnly
          ) {
            $_recurringInvoiceFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          'activeOnly': activeOnly,
        },
        auth: true,
      );
      final rows = data['businessRecurringInvoices'];
      if (rows is List) {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(_recurringInvoiceFromGql)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createRecurringInvoice(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessRecurringInvoice(
          \$input: CreateBusinessRecurringInvoiceInput!
        ) {
          createBusinessRecurringInvoice(input: \$input) {
            $_recurringInvoiceFields
          }
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
            if (body['frequency'] != null) 'frequency': body['frequency'],
            if (body['custom_interval_days'] != null)
              'customIntervalDays': body['custom_interval_days'],
            if (body['next_issue_date'] != null)
              'nextIssueDate': _dateOnly(body['next_issue_date']),
            if (body['start_date'] != null)
              'startDate': _dateOnly(body['start_date']),
            if (body['end_date'] != null) 'endDate': _dateOnly(body['end_date']),
            if (body['max_invoices'] != null) 'maxInvoices': body['max_invoices'],
            if (body['auto_send'] == true) 'autoSend': true,
            if (body['auto_send_channels'] is List)
              'autoSendChannels': body['auto_send_channels'],
          },
        },
        auth: true,
      );
      final row = result['createBusinessRecurringInvoice'];
      if (row is Map<String, dynamic>) return _recurringInvoiceFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateRecurringInvoice(
    int recurringId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessRecurringInvoice(
          \$recurringId: ID!
          \$input: UpdateBusinessRecurringInvoiceInput!
        ) {
          updateBusinessRecurringInvoice(recurringId: \$recurringId, input: \$input) {
            $_recurringInvoiceFields
          }
        }
        ''',
        variables: {
          'recurringId': recurringId.toString(),
          'input': {
            if (body['customer_id'] != null)
              'customerId': body['customer_id'].toString(),
            if (body['customer_name'] != null) 'customerName': body['customer_name'],
            if (body['items'] != null) 'items': body['items'],
            if (body['subtotal'] != null) 'subtotal': body['subtotal'],
            if (body['vat_amount'] != null) 'vatAmount': body['vat_amount'],
            if (body['vat_rate'] != null) 'vatRate': body['vat_rate'],
            if (body['total_amount'] != null) 'totalAmount': body['total_amount'],
            if (body['frequency'] != null) 'frequency': body['frequency'],
            if (body['custom_interval_days'] != null)
              'customIntervalDays': body['custom_interval_days'],
            if (body['next_issue_date'] != null)
              'nextIssueDate': _dateOnly(body['next_issue_date']),
            if (body['start_date'] != null)
              'startDate': _dateOnly(body['start_date']),
            if (body['end_date'] != null) 'endDate': _dateOnly(body['end_date']),
            if (body['max_invoices'] != null) 'maxInvoices': body['max_invoices'],
            if (body.containsKey('is_active')) 'isActive': body['is_active'] == true,
            if (body['auto_send'] != null) 'autoSend': body['auto_send'] == true,
            if (body['auto_send_channels'] is List)
              'autoSendChannels': body['auto_send_channels'],
          },
        },
        auth: true,
      );
      final row = result['updateBusinessRecurringInvoice'];
      if (row is Map<String, dynamic>) return _recurringInvoiceFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> cancelRecurringInvoice(int recurringId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelBusinessRecurringInvoice(\$recurringId: ID!) {
          cancelBusinessRecurringInvoice(recurringId: \$recurringId) {
            id isActive
          }
        }
        ''',
        variables: {'recurringId': recurringId.toString()},
        auth: true,
      );
      final row = result['cancelBusinessRecurringInvoice'];
      return row is Map<String, dynamic> && row['isActive'] == false;
    } catch (_) {
      return false;
    }
  }

  static String? _dateOnly(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  static const _catalogItemFields = r'''
    id businessId supplierId name description detail kind imageUrl imageUrls
    unitPrice compareAtPrice currency stockQuantity defaultQuantity category
    condition availability durationMinutes pricingType allowDelivery allowPickup
    allowShipping deliveryFee locationName isActive createdAt
  ''';

  static const _supplierAnalyticsFields = r'''
    totalSpent orderCount poCount currentMonthSpent lastMonthSpent thisYearSpent
    topItems monthlyTrend recentPos
  ''';

  static const _vfdConfigFields = r'''
    id businessId tin vrn serialNumber registrationId certificateKey isActive registeredAt
  ''';

  static const _fiscalReceiptFields = r'''
    id invoiceId receiptNumber fiscalCode qrCode tin vrn totalAmount vatAmount
    issuedAt verificationUrl
  ''';

  static const _vfdOutboxFields = r'''
    id payloadType status attemptCount nextRetryAt lastError requestHash retryLogs
  ''';

  static const _vfdZReportFields = r'''
    id businessDate status totalDailyAmount vatTotal receiptCount submittedAt payload
  ''';

  static Map<String, dynamic> _catalogItemFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'name': row['name'],
        'description': row['description'],
        'detail': row['detail'],
        'kind': row['kind'],
        'image_url': row['imageUrl'],
        'image_urls': row['imageUrls'] ?? [],
        'unit_price': row['unitPrice'],
        'compare_at_price': row['compareAtPrice'],
        'currency': row['currency'],
        'stock_quantity': row['stockQuantity'],
        'default_quantity': row['defaultQuantity'],
        'category': row['category'],
        'condition': row['condition'],
        'availability': row['availability'],
        'duration_minutes': row['durationMinutes'],
        'pricing_type': row['pricingType'],
        'allow_delivery': row['allowDelivery'],
        'allow_pickup': row['allowPickup'],
        'allow_shipping': row['allowShipping'],
        'delivery_fee': row['deliveryFee'],
        'location_name': row['locationName'],
      };

  static Map<String, dynamic> _supplierAnalyticsFromGql(Map<String, dynamic> row) {
    final topItems = (row['topItems'] as List?)?.map((item) {
      if (item is! Map) return item;
      final spent = item['totalSpent'] ?? item['total_spent'] ?? 0;
      final desc = item['description']?.toString() ?? '';
      return {
        'name': item['name']?.toString() ?? desc,
        'description': desc,
        'spent': spent,
        'total_value': spent,
        'count': item['count'] ?? item['orderCount'] ?? item['order_count'] ?? 0,
        'order_count': item['orderCount'] ?? item['order_count'] ?? 0,
      };
    }).toList();

    final monthlyTrend = (row['monthlyTrend'] as List?)?.map((point) {
      if (point is! Map) return point;
      final monthNum = point['month'];
      final year = point['year'];
      final monthLabel = (monthNum != null && year != null)
          ? '$year-${monthNum.toString().padLeft(2, '0')}'
          : (point['month']?.toString() ?? '');
      return {
        'month': monthLabel,
        'spent': point['totalSpent'] ?? point['total_spent'] ?? 0,
        'order_count': point['orderCount'] ?? point['order_count'] ?? 0,
      };
    }).toList();

    return {
        'total_spent': row['totalSpent'],
        'order_count': row['orderCount'],
        'po_count': row['poCount'],
        'current_month_spent': row['currentMonthSpent'],
        'last_month_spent': row['lastMonthSpent'],
        'this_year_spent': row['thisYearSpent'],
        'top_items': topItems ?? [],
        'monthly_trend': monthlyTrend ?? [],
        'recent_pos': row['recentPos'] ?? [],
      };
  }

  static Map<String, dynamic> _vfdConfigFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'business_id': row['businessId'],
        'tin': row['tin'],
        'vrn': row['vrn'],
        'serial_number': row['serialNumber'],
        'registration_id': row['registrationId'],
        'certificate_key': row['certificateKey'],
        'is_active': row['isActive'],
        'registered_at': row['registeredAt'],
      };

  static Map<String, dynamic> _fiscalReceiptFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'invoice_id': row['invoiceId'],
        'receipt_number': row['receiptNumber'],
        'fiscal_code': row['fiscalCode'],
        'qr_code': row['qrCode'],
        'tin': row['tin'],
        'vrn': row['vrn'],
        'total_amount': row['totalAmount'],
        'vat_amount': row['vatAmount'],
        'issued_at': row['issuedAt'],
        'verification_url': row['verificationUrl'],
      };

  static Map<String, dynamic> _vfdOutboxFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'payload_type': row['payloadType'],
        'status': row['status'],
        'attempt_count': row['attemptCount'],
        'next_retry_at': row['nextRetryAt'],
        'last_error': row['lastError'],
        'request_hash': row['requestHash'],
        'retry_logs': row['retryLogs'] ?? [],
      };

  static Map<String, dynamic> _vfdZReportFromGql(Map<String, dynamic> row) {
    final payload = row['payload'];
    final base = {
      'id': row['id'],
      'business_date': row['businessDate'],
      'status': row['status'],
      'total_daily_amount': row['totalDailyAmount'],
      'vat_total': row['vatTotal'],
      'receipt_count': row['receiptCount'],
      'submitted_at': row['submittedAt'],
    };
    if (payload is Map<String, dynamic>) {
      base.addAll(payload);
    }
    return base;
  }

  static Future<Map<String, dynamic>?> markPurchaseOrderSent(int poId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation MarkBusinessPurchaseOrderSent(\$poId: ID!) {
          markBusinessPurchaseOrderSent(poId: \$poId) { $_purchaseOrderFields }
        }
        ''',
        variables: {'poId': poId.toString()},
        auth: true,
      );
      final row = result['markBusinessPurchaseOrderSent'];
      if (row is Map<String, dynamic>) return _purchaseOrderFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updatePurchaseOrder(
    int poId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessPurchaseOrder(
          \$poId: ID!
          \$input: UpdateBusinessPurchaseOrderInput!
        ) {
          updateBusinessPurchaseOrder(poId: \$poId, input: \$input) {
            $_purchaseOrderFields
          }
        }
        ''',
        variables: {
          'poId': poId.toString(),
          'input': {
            if (body['supplier_id'] != null)
              'supplierId': body['supplier_id'].toString(),
            if (body['supplier_name'] != null) 'supplierName': body['supplier_name'],
            if (body['items'] != null) 'items': body['items'],
            if (body['subtotal'] != null) 'subtotal': body['subtotal'],
            if (body['vat_amount'] != null) 'vatAmount': body['vat_amount'],
            if (body['total_amount'] != null) 'totalAmount': body['total_amount'],
            if (body['status'] != null) 'status': body['status'],
            if (body['expected_delivery_date'] != null)
              'expectedDeliveryDate': _dateOnly(body['expected_delivery_date']),
            if (body['notes'] != null) 'notes': body['notes'],
          },
        },
        auth: true,
      );
      final row = result['updateBusinessPurchaseOrder'];
      if (row is Map<String, dynamic>) return _purchaseOrderFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getSupplierCatalog(int supplierId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessSupplierCatalog(\$supplierId: ID!) {
          businessSupplierCatalog(supplierId: \$supplierId) { $_catalogItemFields }
        }
        ''',
        variables: {'supplierId': supplierId.toString()},
        auth: true,
      );
      final rows = data['businessSupplierCatalog'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_catalogItemFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getSupplierAnalytics(
    int businessId,
    int supplierId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessSupplierAnalytics(\$businessId: ID!, \$supplierId: ID!) {
          businessSupplierAnalytics(businessId: \$businessId, supplierId: \$supplierId) {
            $_supplierAnalyticsFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          'supplierId': supplierId.toString(),
        },
        auth: true,
      );
      final row = data['businessSupplierAnalytics'];
      if (row is Map<String, dynamic>) return _supplierAnalyticsFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getVfdConfig(int businessId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessVfdConfig(\$businessId: ID!) {
          businessVfdConfig(businessId: \$businessId) { $_vfdConfigFields }
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final row = data['businessVfdConfig'];
      if (row is Map<String, dynamic>) return _vfdConfigFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> registerVfd(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RegisterBusinessVfd(
          \$businessId: ID!
          \$input: RegisterBusinessVfdInput!
        ) {
          registerBusinessVfd(businessId: \$businessId, input: \$input) {
            $_vfdConfigFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          'input': {
            'tin': body['tin'],
            if (body['vrn'] != null) 'vrn': body['vrn'],
            if (body['serial_number'] != null) 'serialNumber': body['serial_number'],
            if (body['registration_id'] != null)
              'registrationId': body['registration_id'],
            if (body['certificate_key'] != null)
              'certificateKey': body['certificate_key'],
          },
        },
        auth: true,
      );
      final row = result['registerBusinessVfd'];
      if (row is Map<String, dynamic>) return _vfdConfigFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getFiscalReceipts(
    int businessId, {
    int page = 1,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessFiscalReceipts(\$businessId: ID!, \$page: Int) {
          businessFiscalReceipts(businessId: \$businessId, page: \$page) {
            $_fiscalReceiptFields
          }
        }
        ''',
        variables: {'businessId': businessId.toString(), 'page': page},
        auth: true,
      );
      final rows = data['businessFiscalReceipts'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_fiscalReceiptFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> issueFiscalReceipt(int invoiceId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation IssueBusinessFiscalReceipt(\$invoiceId: ID!) {
          issueBusinessFiscalReceipt(invoiceId: \$invoiceId) { $_fiscalReceiptFields }
        }
        ''',
        variables: {'invoiceId': invoiceId.toString()},
        auth: true,
      );
      final row = result['issueBusinessFiscalReceipt'];
      if (row is Map<String, dynamic>) return _fiscalReceiptFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getVfdSettings(int businessId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessVfdSettings(\$businessId: ID!) {
          businessVfdSettings(businessId: \$businessId)
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final row = data['businessVfdSettings'];
      if (row is Map<String, dynamic>) return row;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> updateVfdSettings(
    int businessId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessVfdSettings(
          \$businessId: ID!
          \$settings: JSON!
        ) {
          updateBusinessVfdSettings(businessId: \$businessId, settings: \$settings)
        }
        ''',
        variables: {'businessId': businessId.toString(), 'settings': settings},
        auth: true,
      );
      final row = result['updateBusinessVfdSettings'];
      if (row is Map<String, dynamic>) return row;
      return settings;
    } catch (_) {
      return settings;
    }
  }

  static Future<Map<String, dynamic>> rotateVfdCredentials(int businessId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RotateBusinessVfdCredentials(\$businessId: ID!) {
          rotateBusinessVfdCredentials(businessId: \$businessId)
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final row = result['rotateBusinessVfdCredentials'];
      if (row is Map<String, dynamic>) return row;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getVfdComplianceDashboard(
    int businessId, {
    String period = '30d',
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessVfdComplianceDashboard(\$businessId: ID!, \$period: String) {
          businessVfdComplianceDashboard(businessId: \$businessId, period: \$period)
        }
        ''',
        variables: {'businessId': businessId.toString(), 'period': period},
        auth: true,
      );
      final row = data['businessVfdComplianceDashboard'];
      if (row is Map<String, dynamic>) return row;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getVfdOutbox(
    int businessId, {
    String? status,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessVfdOutbox(\$businessId: ID!, \$status: String) {
          businessVfdOutbox(businessId: \$businessId, status: \$status) {
            $_vfdOutboxFields
          }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (status != null) 'status': status,
        },
        auth: true,
      );
      final rows = data['businessVfdOutbox'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_vfdOutboxFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getVfdZReports(int businessId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessVfdZReports(\$businessId: ID!) {
          businessVfdZReports(businessId: \$businessId) { $_vfdZReportFields }
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final rows = data['businessVfdZReports'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_vfdZReportFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> submitVfdZReport(
    int businessId, {
    String? businessDate,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitBusinessVfdZReport(
          \$businessId: ID!
          \$businessDate: String
          \$payload: JSON
        ) {
          submitBusinessVfdZReport(
            businessId: \$businessId
            businessDate: \$businessDate
            payload: \$payload
          ) { id status }
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          if (businessDate != null) 'businessDate': businessDate,
          if (payload != null) 'payload': payload,
        },
        auth: true,
      );
      return result['submitBusinessVfdZReport'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> retryVfdOutboxItem(int outboxId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RetryBusinessVfdOutboxItem(\$outboxId: ID!) {
          retryBusinessVfdOutboxItem(outboxId: \$outboxId) { id status }
        }
        ''',
        variables: {'outboxId': outboxId.toString()},
        auth: true,
      );
      return result['retryBusinessVfdOutboxItem'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> retryAllEligibleVfdOutbox(int businessId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RetryAllEligibleBusinessVfdOutbox(\$businessId: ID!) {
          retryAllEligibleBusinessVfdOutbox(businessId: \$businessId)
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      return result['retryAllEligibleBusinessVfdOutbox'] is int;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> exportVfdComplianceReport(
    int businessId, {
    String format = 'pdf',
    String period = '30d',
    bool includeDetailLogs = false,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ExportBusinessVfdComplianceReport(
          \$businessId: ID!
          \$reportFormat: String
          \$period: String
          \$includeDetailLogs: Boolean
        ) {
          exportBusinessVfdComplianceReport(
            businessId: \$businessId
            reportFormat: \$reportFormat
            period: \$period
            includeDetailLogs: \$includeDetailLogs
          )
        }
        ''',
        variables: {
          'businessId': businessId.toString(),
          'reportFormat': format,
          'period': period,
          'includeDetailLogs': includeDetailLogs,
        },
        auth: true,
      );
      final url = result['exportBusinessVfdComplianceReport'];
      return url?.toString();
    } catch (_) {
      return null;
    }
  }
}
