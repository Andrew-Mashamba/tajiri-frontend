// lib/business/models/business_models.dart
// All data models for the Biashara Yangu (My Business) module.

// ---------------------------------------------------------------------------
// Null-safe parsing helpers
// ---------------------------------------------------------------------------
int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

// ---------------------------------------------------------------------------
// Result wrappers
// ---------------------------------------------------------------------------
class BusinessResult<T> {
  final bool success;
  final T? data;
  final String? message;
  BusinessResult({required this.success, this.data, this.message});
}

class BusinessListResult<T> {
  final bool success;
  final List<T> data;
  final String? message;
  final int? total;
  BusinessListResult({required this.success, this.data = const [], this.message, this.total});
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------
enum BusinessType { sole_proprietor, llc, partnership }

BusinessType _parseBusinessType(dynamic v) {
  if (v == null) return BusinessType.sole_proprietor;
  final s = v.toString().toLowerCase();
  if (s == 'llc') return BusinessType.llc;
  if (s == 'partnership') return BusinessType.partnership;
  return BusinessType.sole_proprietor;
}

String businessTypeLabel(BusinessType t, {bool swahili = false}) {
  switch (t) {
    case BusinessType.sole_proprietor:
      return swahili ? 'Biashara Binafsi' : 'Sole Proprietor';
    case BusinessType.llc:
      return swahili ? 'Kampuni (LLC)' : 'Company (LLC)';
    case BusinessType.partnership:
      return swahili ? 'Ubia (Partnership)' : 'Partnership';
  }
}

enum DocumentType {
  certificate_of_registration,
  tin_certificate,
  business_license,
  memart,
  vat_certificate,
  nssf_certificate,
  wcf_certificate,
  director_id,
  company_profile,
  tax_return,
  financial_statement,
  contract,
  insurance_policy,
  other,
}

DocumentType _parseDocumentType(dynamic v) {
  if (v == null) return DocumentType.other;
  final s = v.toString().toLowerCase();
  for (final dt in DocumentType.values) {
    if (dt.name == s) return dt;
  }
  return DocumentType.other;
}

String documentTypeLabel(DocumentType t, {bool swahili = false}) {
  switch (t) {
    case DocumentType.certificate_of_registration:
      return swahili ? 'Cheti cha Usajili (BRELA)' : 'Certificate of Registration';
    case DocumentType.tin_certificate:
      return swahili ? 'Cheti cha TIN (TRA)' : 'TIN Certificate';
    case DocumentType.business_license:
      return swahili ? 'Leseni ya Biashara' : 'Business License';
    case DocumentType.memart:
      return 'MEMART';
    case DocumentType.vat_certificate:
      return swahili ? 'Cheti cha VAT' : 'VAT Certificate';
    case DocumentType.nssf_certificate:
      return swahili ? 'Cheti cha NSSF' : 'NSSF Certificate';
    case DocumentType.wcf_certificate:
      return swahili ? 'Cheti cha WCF' : 'WCF Certificate';
    case DocumentType.director_id:
      return swahili ? 'Kitambulisho cha Mkurugenzi' : 'Director ID';
    case DocumentType.company_profile:
      return swahili ? 'Wasifu wa Kampuni' : 'Company Profile';
    case DocumentType.tax_return:
      return swahili ? 'Tamko la Kodi' : 'Tax Return';
    case DocumentType.financial_statement:
      return swahili ? 'Taarifa za Fedha' : 'Financial Statement';
    case DocumentType.contract:
      return swahili ? 'Mkataba' : 'Contract';
    case DocumentType.insurance_policy:
      return swahili ? 'Bima ya Biashara' : 'Insurance Policy';
    case DocumentType.other:
      return swahili ? 'Nyingine' : 'Other';
  }
}

/// Required documents based on business type.
List<DocumentType> requiredDocuments(BusinessType type, {bool hasVrn = false}) {
  final docs = <DocumentType>[
    DocumentType.certificate_of_registration,
    DocumentType.tin_certificate,
    DocumentType.business_license,
  ];
  if (type == BusinessType.llc || type == BusinessType.partnership) {
    docs.add(DocumentType.memart);
    docs.add(DocumentType.director_id);
  }
  if (hasVrn) docs.add(DocumentType.vat_certificate);
  return docs;
}

/// Whether this document type has an expiry date.
bool documentExpires(DocumentType t) {
  return [
    DocumentType.business_license,
    DocumentType.wcf_certificate,
    DocumentType.director_id,
    DocumentType.contract,
    DocumentType.insurance_policy,
  ].contains(t);
}

enum DebtStatus { pending, partial, paid, overdue }

DebtStatus _parseDebtStatus(dynamic v) {
  if (v == null) return DebtStatus.pending;
  final s = v.toString().toLowerCase();
  for (final ds in DebtStatus.values) {
    if (ds.name == s) return ds;
  }
  return DebtStatus.pending;
}

String debtStatusLabel(DebtStatus s, {bool swahili = false}) {
  switch (s) {
    case DebtStatus.pending:
      return swahili ? 'Inasubiri' : 'Pending';
    case DebtStatus.partial:
      return swahili ? 'Sehemu' : 'Partial';
    case DebtStatus.paid:
      return swahili ? 'Limelipwa' : 'Paid';
    case DebtStatus.overdue:
      return swahili ? 'Limechelewa' : 'Overdue';
  }
}

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

InvoiceStatus _parseInvoiceStatus(dynamic v) {
  if (v == null) return InvoiceStatus.draft;
  final s = v.toString().toLowerCase();
  for (final is_ in InvoiceStatus.values) {
    if (is_.name == s) return is_;
  }
  return InvoiceStatus.draft;
}

String invoiceStatusLabel(InvoiceStatus s, {bool swahili = false}) {
  switch (s) {
    case InvoiceStatus.draft:
      return swahili ? 'Rasimu' : 'Draft';
    case InvoiceStatus.sent:
      return swahili ? 'Imetumwa' : 'Sent';
    case InvoiceStatus.paid:
      return swahili ? 'Imelipwa' : 'Paid';
    case InvoiceStatus.overdue:
      return swahili ? 'Imechelewa' : 'Overdue';
    case InvoiceStatus.cancelled:
      return swahili ? 'Imefutwa' : 'Cancelled';
  }
}

enum PayrollStatus { draft, approved, paid }

PayrollStatus _parsePayrollStatus(dynamic v) {
  if (v == null) return PayrollStatus.draft;
  final s = v.toString().toLowerCase();
  for (final ps in PayrollStatus.values) {
    if (ps.name == s) return ps;
  }
  return PayrollStatus.draft;
}

String payrollStatusLabel(PayrollStatus s, {bool swahili = false}) {
  switch (s) {
    case PayrollStatus.draft:
      return swahili ? 'Rasimu' : 'Draft';
    case PayrollStatus.approved:
      return swahili ? 'Imeidhinishwa' : 'Approved';
    case PayrollStatus.paid:
      return swahili ? 'Imelipwa' : 'Paid';
  }
}

// ---------------------------------------------------------------------------
// Director (embedded in Business)
// ---------------------------------------------------------------------------
class Director {
  final String name;
  final String? idNumber;
  final double shares;

  Director({required this.name, this.idNumber, this.shares = 0});

  factory Director.fromJson(Map<String, dynamic> json) {
    return Director(
      name: json['name']?.toString() ?? '',
      idNumber: json['id_number']?.toString(),
      shares: _parseDouble(json['shares']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'id_number': idNumber,
        'shares': shares,
      };
}

// ---------------------------------------------------------------------------
// Business
// ---------------------------------------------------------------------------
class Business {
  final int? id;
  final int? userId;
  final String name;
  final BusinessType type;
  final String? registrationNumber;
  final String? tinNumber;
  final String? vrn;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? sector;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final List<Director> directors;
  final double shareCapital;
  final DateTime? incorporationDate;
  final bool isActive;
  final DateTime? createdAt;

  // Email service
  final bool hasEmailService;
  final String? emailDomainType; // 'tajiri' or 'custom'
  final String? emailDomain; // e.g. 'tajiri.co.tz' or 'zima.co.tz'
  final List<BusinessEmail> emailAccounts;

  Business({
    this.id,
    this.userId,
    required this.name,
    this.type = BusinessType.sole_proprietor,
    this.registrationNumber,
    this.tinNumber,
    this.vrn,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.sector,
    this.licenseNumber,
    this.licenseExpiry,
    this.directors = const [],
    this.shareCapital = 0,
    this.incorporationDate,
    this.isActive = true,
    this.createdAt,
    this.hasEmailService = false,
    this.emailDomainType,
    this.emailDomain,
    this.emailAccounts = const [],
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    List<Director> dirs = [];
    if (json['directors'] is List) {
      dirs = (json['directors'] as List)
          .map((d) => Director.fromJson(d is Map<String, dynamic> ? d : {}))
          .toList();
    }
    return Business(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      name: json['name']?.toString() ?? '',
      type: _parseBusinessType(json['type']),
      registrationNumber: json['registration_number']?.toString(),
      tinNumber: json['tin_number']?.toString(),
      vrn: json['vrn']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      sector: json['sector']?.toString(),
      licenseNumber: json['license_number']?.toString(),
      licenseExpiry: _parseDate(json['license_expiry']),
      directors: dirs,
      shareCapital: _parseDouble(json['share_capital']),
      incorporationDate: _parseDate(json['incorporation_date']),
      isActive: _parseBool(json['is_active'], true),
      createdAt: _parseDate(json['created_at']),
      hasEmailService: _parseBool(json['has_email_service']),
      emailDomainType: json['email_domain_type']?.toString(),
      emailDomain: json['email_domain']?.toString(),
      emailAccounts: (json['email_accounts'] as List?)
              ?.map((e) => BusinessEmail.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'name': name,
        'type': type.name,
        'registration_number': registrationNumber,
        'tin_number': tinNumber,
        'vrn': vrn,
        'address': address,
        'phone': phone,
        'email': email,
        'logo_url': logoUrl,
        'sector': sector,
        'license_number': licenseNumber,
        'license_expiry': licenseExpiry?.toIso8601String(),
        'directors': directors.map((d) => d.toJson()).toList(),
        'share_capital': shareCapital,
        'incorporation_date': incorporationDate?.toIso8601String(),
        'is_active': isActive,
        'has_email_service': hasEmailService,
        'email_domain_type': emailDomainType,
        'email_domain': emailDomain,
      };

  bool get isLicenseExpiringSoon {
    if (licenseExpiry == null) return false;
    return licenseExpiry!.difference(DateTime.now()).inDays <= 30;
  }

  bool get isLicenseExpired {
    if (licenseExpiry == null) return false;
    return licenseExpiry!.isBefore(DateTime.now());
  }
}

// ---------------------------------------------------------------------------
// BusinessEmail — email accounts under the business domain
// ---------------------------------------------------------------------------
class BusinessEmail {
  final int? id;
  final int? businessId;
  final String address; // e.g. info@zima.co.tz or andrew@tajiri.co.tz
  final String displayName;
  final String? role; // admin, info, support, sales, custom
  final bool isActive;
  final DateTime? createdAt;

  BusinessEmail({
    this.id,
    this.businessId,
    required this.address,
    required this.displayName,
    this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory BusinessEmail.fromJson(Map<String, dynamic> json) {
    return BusinessEmail(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      address: json['address']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      role: json['role']?.toString(),
      isActive: _parseBool(json['is_active'], true),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

// ---------------------------------------------------------------------------
// BusinessDocument
// ---------------------------------------------------------------------------
class BusinessDocument {
  final int? id;
  final int? businessId;
  final DocumentType type;
  final String name;
  final String? fileUrl;
  final DateTime? expiryDate;
  final DateTime? uploadedAt;

  BusinessDocument({
    this.id,
    this.businessId,
    required this.type,
    required this.name,
    this.fileUrl,
    this.expiryDate,
    this.uploadedAt,
  });

  factory BusinessDocument.fromJson(Map<String, dynamic> json) {
    return BusinessDocument(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      type: _parseDocumentType(json['type']),
      name: json['name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString(),
      expiryDate: _parseDate(json['expiry_date']),
      uploadedAt: _parseDate(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'type': type.name,
        'name': name,
        'file_url': fileUrl,
        'expiry_date': expiryDate?.toIso8601String(),
      };
}

// ---------------------------------------------------------------------------
// Customer
// ---------------------------------------------------------------------------
class Customer {
  final int? id;
  final int? businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double totalPurchases;
  final double totalDebt;
  final String? notes;
  final DateTime? createdAt;

  Customer({
    this.id,
    this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.totalPurchases = 0,
    this.totalDebt = 0,
    this.notes,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      totalPurchases: _parseDouble(json['total_purchases']),
      totalDebt: _parseDouble(json['total_debt']),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
      };
}

// ---------------------------------------------------------------------------
// Debt (Deni)
// ---------------------------------------------------------------------------
class Debt {
  final int? id;
  final int? businessId;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final double amount;
  final double paidAmount;
  final String? description;
  final DateTime? dueDate;
  final DebtStatus status;
  final DateTime? createdAt;

  Debt({
    this.id,
    this.businessId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.amount = 0,
    this.paidAmount = 0,
    this.description,
    this.dueDate,
    this.status = DebtStatus.pending,
    this.createdAt,
  });

  double get remainingAmount => amount - paidAmount;

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      customerId: _parseInt(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      amount: _parseDouble(json['amount']),
      paidAmount: _parseDouble(json['paid_amount']),
      description: json['description']?.toString(),
      dueDate: _parseDate(json['due_date']),
      status: _parseDebtStatus(json['status']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'amount': amount,
        'paid_amount': paidAmount,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'status': status.name,
      };
}

// ---------------------------------------------------------------------------
// DebtSummary
// ---------------------------------------------------------------------------
class DebtSummary {
  final double totalOutstanding;
  final double totalOverdue;
  final int overdueCount;
  final int pendingCount;
  final int partialCount;

  DebtSummary({
    this.totalOutstanding = 0,
    this.totalOverdue = 0,
    this.overdueCount = 0,
    this.pendingCount = 0,
    this.partialCount = 0,
  });

  factory DebtSummary.fromJson(Map<String, dynamic> json) {
    return DebtSummary(
      totalOutstanding: _parseDouble(json['total_outstanding']),
      totalOverdue: _parseDouble(json['total_overdue']),
      overdueCount: _parseInt(json['overdue_count']) ?? 0,
      pendingCount: _parseInt(json['pending_count']) ?? 0,
      partialCount: _parseInt(json['partial_count']) ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// InvoiceItem
// ---------------------------------------------------------------------------
class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    double? totalPrice,
  }) : totalPrice = totalPrice ?? (quantity * unitPrice);

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final qty = _parseDouble(json['quantity'], 1);
    final price = _parseDouble(json['unit_price']);
    return InvoiceItem(
      description: json['description']?.toString() ?? '',
      quantity: qty,
      unitPrice: price,
      totalPrice: _parseDouble(json['total_price'], qty * price),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };
}

// ---------------------------------------------------------------------------
// Invoice
// ---------------------------------------------------------------------------
class Invoice {
  final int? id;
  final int? businessId;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double vatAmount;
  final double vatRate;
  final double totalAmount;
  final InvoiceStatus status;
  final DateTime? dueDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? paidAt;

  Invoice({
    this.id,
    this.businessId,
    this.invoiceNumber = '',
    this.customerId,
    this.customerName,
    this.items = const [],
    this.subtotal = 0,
    this.vatAmount = 0,
    this.vatRate = 18.0,
    this.totalAmount = 0,
    this.status = InvoiceStatus.draft,
    this.dueDate,
    this.notes,
    this.createdAt,
    this.paidAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    List<InvoiceItem> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List)
          .map((i) => InvoiceItem.fromJson(i is Map<String, dynamic> ? i : {}))
          .toList();
    }
    return Invoice(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      customerId: _parseInt(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      items: items,
      subtotal: _parseDouble(json['subtotal']),
      vatAmount: _parseDouble(json['vat_amount']),
      vatRate: _parseDouble(json['vat_rate'], 18.0),
      totalAmount: _parseDouble(json['total_amount']),
      status: _parseInvoiceStatus(json['status']),
      dueDate: _parseDate(json['due_date']),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
      paidAt: _parseDate(json['paid_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'invoice_number': invoiceNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'vat_amount': vatAmount,
        'vat_rate': vatRate,
        'total_amount': totalAmount,
        'status': status.name,
        'due_date': dueDate?.toIso8601String(),
        'notes': notes,
      };
}

// ---------------------------------------------------------------------------
// Employee
// ---------------------------------------------------------------------------
class Employee {
  final int? id;
  final int? businessId;
  final String name;
  final String? phone;
  final String? nidaNumber;
  final String? position;
  final double grossSalary;
  final DateTime? startDate;
  final String? bankAccount;
  final String? bankName;
  final bool isActive;

  Employee({
    this.id,
    this.businessId,
    required this.name,
    this.phone,
    this.nidaNumber,
    this.position,
    this.grossSalary = 0,
    this.startDate,
    this.bankAccount,
    this.bankName,
    this.isActive = true,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      nidaNumber: json['nida_number']?.toString(),
      position: json['position']?.toString(),
      grossSalary: _parseDouble(json['gross_salary']),
      startDate: _parseDate(json['start_date']),
      bankAccount: json['bank_account']?.toString(),
      bankName: json['bank_name']?.toString(),
      isActive: _parseBool(json['is_active'], true),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'nida_number': nidaNumber,
        'position': position,
        'gross_salary': grossSalary,
        'start_date': startDate?.toIso8601String(),
        'bank_account': bankAccount,
        'bank_name': bankName,
        'is_active': isActive,
      };
}

// ---------------------------------------------------------------------------
// PayrollEntry
// ---------------------------------------------------------------------------
class PayrollEntry {
  final int? employeeId;
  final String employeeName;
  final double grossSalary;
  final double paye;
  final double nssfEmployee;
  final double nssfEmployer;
  final double sdl;
  final double wcf;
  final double netSalary;

  PayrollEntry({
    this.employeeId,
    this.employeeName = '',
    this.grossSalary = 0,
    this.paye = 0,
    this.nssfEmployee = 0,
    this.nssfEmployer = 0,
    this.sdl = 0,
    this.wcf = 0,
    this.netSalary = 0,
  });

  factory PayrollEntry.fromJson(Map<String, dynamic> json) {
    return PayrollEntry(
      employeeId: _parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString() ?? '',
      grossSalary: _parseDouble(json['gross_salary']),
      paye: _parseDouble(json['paye']),
      nssfEmployee: _parseDouble(json['nssf_employee']),
      nssfEmployer: _parseDouble(json['nssf_employer']),
      sdl: _parseDouble(json['sdl']),
      wcf: _parseDouble(json['wcf']),
      netSalary: _parseDouble(json['net_salary']),
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'gross_salary': grossSalary,
        'paye': paye,
        'nssf_employee': nssfEmployee,
        'nssf_employer': nssfEmployer,
        'sdl': sdl,
        'wcf': wcf,
        'net_salary': netSalary,
      };

  /// Total employer cost for this employee
  double get totalEmployerCost => grossSalary + nssfEmployer + sdl + wcf;
}

// ---------------------------------------------------------------------------
// PayrollRun
// ---------------------------------------------------------------------------
class PayrollRun {
  final int? id;
  final int? businessId;
  final int month;
  final int year;
  final List<PayrollEntry> employees;
  final double totalGross;
  final double totalNet;
  final double totalPaye;
  final double totalNssf;
  final double totalSdl;
  final double totalWcf;
  final PayrollStatus status;
  final DateTime? createdAt;

  PayrollRun({
    this.id,
    this.businessId,
    this.month = 1,
    this.year = 2026,
    this.employees = const [],
    this.totalGross = 0,
    this.totalNet = 0,
    this.totalPaye = 0,
    this.totalNssf = 0,
    this.totalSdl = 0,
    this.totalWcf = 0,
    this.status = PayrollStatus.draft,
    this.createdAt,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    List<PayrollEntry> emps = [];
    if (json['employees'] is List) {
      emps = (json['employees'] as List)
          .map((e) => PayrollEntry.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return PayrollRun(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      month: _parseInt(json['month']) ?? 1,
      year: _parseInt(json['year']) ?? 2026,
      employees: emps,
      totalGross: _parseDouble(json['total_gross']),
      totalNet: _parseDouble(json['total_net']),
      totalPaye: _parseDouble(json['total_paye']),
      totalNssf: _parseDouble(json['total_nssf']),
      totalSdl: _parseDouble(json['total_sdl']),
      totalWcf: _parseDouble(json['total_wcf']),
      status: _parsePayrollStatus(json['status']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'month': month,
        'year': year,
        'employees': employees.map((e) => e.toJson()).toList(),
        'total_gross': totalGross,
        'total_net': totalNet,
        'total_paye': totalPaye,
        'total_nssf': totalNssf,
        'total_sdl': totalSdl,
        'total_wcf': totalWcf,
        'status': status.name,
      };
}

// ---------------------------------------------------------------------------
// TaxCalculation
// ---------------------------------------------------------------------------
class TaxCalculation {
  final int? businessId;
  final String period;
  final double revenue;
  final double expenses;
  final double profit;
  final double corporateTax;
  final double vatCollected;
  final double vatPaid;
  final double vatDue;
  final double payeTotal;
  final double nssfTotal;
  final double sdlTotal;
  final double wcfTotal;

  TaxCalculation({
    this.businessId,
    this.period = '',
    this.revenue = 0,
    this.expenses = 0,
    this.profit = 0,
    this.corporateTax = 0,
    this.vatCollected = 0,
    this.vatPaid = 0,
    this.vatDue = 0,
    this.payeTotal = 0,
    this.nssfTotal = 0,
    this.sdlTotal = 0,
    this.wcfTotal = 0,
  });

  double get totalTaxObligation =>
      corporateTax + vatDue + payeTotal + nssfTotal + sdlTotal + wcfTotal;

  factory TaxCalculation.fromJson(Map<String, dynamic> json) {
    return TaxCalculation(
      businessId: _parseInt(json['business_id']),
      period: json['period']?.toString() ?? '',
      revenue: _parseDouble(json['revenue']),
      expenses: _parseDouble(json['expenses']),
      profit: _parseDouble(json['profit']),
      corporateTax: _parseDouble(json['corporate_tax']),
      vatCollected: _parseDouble(json['vat_collected']),
      vatPaid: _parseDouble(json['vat_paid']),
      vatDue: _parseDouble(json['vat_due']),
      payeTotal: _parseDouble(json['paye_total']),
      nssfTotal: _parseDouble(json['nssf_total']),
      sdlTotal: _parseDouble(json['sdl_total']),
      wcfTotal: _parseDouble(json['wcf_total']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'period': period,
        'revenue': revenue,
        'expenses': expenses,
        'profit': profit,
        'corporate_tax': corporateTax,
        'vat_collected': vatCollected,
        'vat_paid': vatPaid,
        'vat_due': vatDue,
        'paye_total': payeTotal,
        'nssf_total': nssfTotal,
        'sdl_total': sdlTotal,
        'wcf_total': wcfTotal,
      };
}

// ---------------------------------------------------------------------------
// RegistrationStep (for the guide)
// ---------------------------------------------------------------------------
class RegistrationStep {
  final int stepNumber;
  final String title;
  final String description;
  final List<String> documentsNeeded;
  final String? costRange;
  final String? guidance;
  final bool isCompleted;

  RegistrationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.documentsNeeded = const [],
    this.costRange,
    this.guidance,
    this.isCompleted = false,
  });

  factory RegistrationStep.fromJson(Map<String, dynamic> json) {
    return RegistrationStep(
      stepNumber: _parseInt(json['step_number']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      documentsNeeded: (json['documents_needed'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      costRange: json['cost_range']?.toString(),
      guidance: json['guidance']?.toString(),
      isCompleted: _parseBool(json['is_completed']),
    );
  }
}

// ---------------------------------------------------------------------------
// Tanzania PAYE Calculator — accurate progressive tax table
// ---------------------------------------------------------------------------
class TanzaniaPAYE {
  /// Calculate monthly PAYE for a given monthly gross salary (TZS).
  /// Tanzania 2024/2025 progressive tax brackets:
  ///   0 - 270,000: 0%
  ///   270,001 - 520,000: 8%
  ///   520,001 - 760,000: 20%
  ///   760,001 - 1,000,000: 25%
  ///   Above 1,000,000: 30%
  static double calculateMonthlyPAYE(double grossMonthly) {
    if (grossMonthly <= 270000) return 0;

    double paye = 0;

    if (grossMonthly > 1000000) {
      paye += (grossMonthly - 1000000) * 0.30;
      paye += (1000000 - 760000) * 0.25; // 60,000
      paye += (760000 - 520000) * 0.20;  // 48,000
      paye += (520000 - 270000) * 0.08;  // 20,000
    } else if (grossMonthly > 760000) {
      paye += (grossMonthly - 760000) * 0.25;
      paye += (760000 - 520000) * 0.20;
      paye += (520000 - 270000) * 0.08;
    } else if (grossMonthly > 520000) {
      paye += (grossMonthly - 520000) * 0.20;
      paye += (520000 - 270000) * 0.08;
    } else {
      // 270,001 - 520,000
      paye += (grossMonthly - 270000) * 0.08;
    }

    return paye;
  }

  /// Calculate NSSF employee contribution (10% of gross).
  static double nssfEmployee(double gross) => gross * 0.10;

  /// Calculate NSSF employer contribution (10% of gross).
  static double nssfEmployer(double gross) => gross * 0.10;

  /// Calculate SDL (Skills Development Levy) — 3.5% of gross payroll.
  static double sdl(double gross) => gross * 0.035;

  /// Calculate WCF (Workers Compensation Fund) — 0.5% of gross payroll.
  static double wcf(double gross) => gross * 0.005;

  /// Net salary = Gross - PAYE - NSSF employee (10%)
  static double netSalary(double gross) {
    return gross - calculateMonthlyPAYE(gross) - nssfEmployee(gross);
  }

  /// Total employer cost = Gross + NSSF employer (10%) + SDL (3.5%) + WCF (0.5%)
  static double totalEmployerCost(double gross) {
    return gross + nssfEmployer(gross) + sdl(gross) + wcf(gross);
  }

  /// Build a full PayrollEntry for one employee.
  static PayrollEntry buildPayrollEntry(Employee emp) {
    final gross = emp.grossSalary;
    return PayrollEntry(
      employeeId: emp.id,
      employeeName: emp.name,
      grossSalary: gross,
      paye: calculateMonthlyPAYE(gross),
      nssfEmployee: nssfEmployee(gross),
      nssfEmployer: nssfEmployer(gross),
      sdl: sdl(gross),
      wcf: wcf(gross),
      netSalary: netSalary(gross),
    );
  }
}

// ===========================================================================
// QUOTES / ESTIMATES (Makadirio)
// ===========================================================================

enum QuoteStatus { draft, sent, accepted, rejected, converted }

QuoteStatus _parseQuoteStatus(dynamic v) {
  if (v == null) return QuoteStatus.draft;
  final s = v.toString().toLowerCase();
  for (final qs in QuoteStatus.values) {
    if (qs.name == s) return qs;
  }
  return QuoteStatus.draft;
}

String quoteStatusLabel(QuoteStatus s, {bool swahili = false}) {
  switch (s) {
    case QuoteStatus.draft:
      return swahili ? 'Rasimu' : 'Draft';
    case QuoteStatus.sent:
      return swahili ? 'Imetumwa' : 'Sent';
    case QuoteStatus.accepted:
      return swahili ? 'Imekubaliwa' : 'Accepted';
    case QuoteStatus.rejected:
      return swahili ? 'Imekataliwa' : 'Rejected';
    case QuoteStatus.converted:
      return swahili ? 'Imebadilishwa' : 'Converted';
  }
}

class Quote {
  final int? id;
  final int? businessId;
  final String quoteNumber;
  final int? customerId;
  final String? customerName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double vatAmount;
  final double vatRate;
  final double totalAmount;
  final QuoteStatus status;
  final DateTime? validUntil;
  final String? notes;
  final DateTime? createdAt;
  final int? convertedInvoiceId;

  Quote({
    this.id,
    this.businessId,
    this.quoteNumber = '',
    this.customerId,
    this.customerName,
    this.items = const [],
    this.subtotal = 0,
    this.vatAmount = 0,
    this.vatRate = 18.0,
    this.totalAmount = 0,
    this.status = QuoteStatus.draft,
    this.validUntil,
    this.notes,
    this.createdAt,
    this.convertedInvoiceId,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    List<InvoiceItem> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List)
          .map((i) => InvoiceItem.fromJson(i is Map<String, dynamic> ? i : {}))
          .toList();
    }
    return Quote(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      quoteNumber: json['quote_number']?.toString() ?? '',
      customerId: _parseInt(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      items: items,
      subtotal: _parseDouble(json['subtotal']),
      vatAmount: _parseDouble(json['vat_amount']),
      vatRate: _parseDouble(json['vat_rate'], 18.0),
      totalAmount: _parseDouble(json['total_amount']),
      status: _parseQuoteStatus(json['status']),
      validUntil: _parseDate(json['valid_until']),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
      convertedInvoiceId: _parseInt(json['converted_invoice_id']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'quote_number': quoteNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'vat_amount': vatAmount,
        'vat_rate': vatRate,
        'total_amount': totalAmount,
        'status': status.name,
        'valid_until': validUntil?.toIso8601String(),
        'notes': notes,
      };
}

// ===========================================================================
// EXPENSE TRACKING (Matumizi)
// ===========================================================================

enum ExpenseCategory {
  rent,
  utilities,
  supplies,
  transport,
  salary,
  marketing,
  food,
  communication,
  maintenance,
  tax,
  insurance,
  other,
}

String expenseCategoryLabel(ExpenseCategory c) {
  switch (c) {
    case ExpenseCategory.rent:
      return 'Kodi ya Nyumba';
    case ExpenseCategory.utilities:
      return 'Umeme/Maji';
    case ExpenseCategory.supplies:
      return 'Vifaa';
    case ExpenseCategory.transport:
      return 'Usafiri';
    case ExpenseCategory.salary:
      return 'Mishahara';
    case ExpenseCategory.marketing:
      return 'Matangazo';
    case ExpenseCategory.food:
      return 'Chakula';
    case ExpenseCategory.communication:
      return 'Mawasiliano';
    case ExpenseCategory.maintenance:
      return 'Matengenezo';
    case ExpenseCategory.tax:
      return 'Kodi';
    case ExpenseCategory.insurance:
      return 'Bima';
    case ExpenseCategory.other:
      return 'Nyingine';
  }
}

String expenseCategoryIcon(ExpenseCategory c) {
  switch (c) {
    case ExpenseCategory.rent:
      return 'home';
    case ExpenseCategory.utilities:
      return 'bolt';
    case ExpenseCategory.supplies:
      return 'inventory';
    case ExpenseCategory.transport:
      return 'directions_car';
    case ExpenseCategory.salary:
      return 'people';
    case ExpenseCategory.marketing:
      return 'campaign';
    case ExpenseCategory.food:
      return 'restaurant';
    case ExpenseCategory.communication:
      return 'phone';
    case ExpenseCategory.maintenance:
      return 'build';
    case ExpenseCategory.tax:
      return 'account_balance';
    case ExpenseCategory.insurance:
      return 'shield';
    case ExpenseCategory.other:
      return 'more_horiz';
  }
}

ExpenseCategory _parseExpenseCategory(dynamic v) {
  if (v == null) return ExpenseCategory.other;
  final s = v.toString().toLowerCase();
  for (final ec in ExpenseCategory.values) {
    if (ec.name == s) return ec;
  }
  return ExpenseCategory.other;
}

class Expense {
  final int? id;
  final int? businessId;
  final ExpenseCategory category;
  final String? description;
  final double amount;
  final DateTime? date;
  final String? receiptPhotoUrl;
  final String? vendorName;
  final String? paymentMethod; // cash, mpesa, bank
  final String? reference;
  final bool isRecurring;
  final String? notes;
  final DateTime? createdAt;

  Expense({
    this.id,
    this.businessId,
    this.category = ExpenseCategory.other,
    this.description,
    this.amount = 0,
    this.date,
    this.receiptPhotoUrl,
    this.vendorName,
    this.paymentMethod,
    this.reference,
    this.isRecurring = false,
    this.notes,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      category: _parseExpenseCategory(json['category']),
      description: json['description']?.toString(),
      amount: _parseDouble(json['amount']),
      date: _parseDate(json['date']),
      receiptPhotoUrl: json['receipt_photo_url']?.toString(),
      vendorName: json['vendor_name']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      reference: json['reference']?.toString(),
      isRecurring: _parseBool(json['is_recurring']),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'category': category.name,
        'description': description,
        'amount': amount,
        'date': date?.toIso8601String(),
        'vendor_name': vendorName,
        'payment_method': paymentMethod,
        'reference': reference,
        'is_recurring': isRecurring,
        'notes': notes,
      };
}

class ExpenseSummary {
  final double totalThisMonth;
  final double totalLastMonth;
  final double changePercent;
  final Map<String, double> byCategory;

  ExpenseSummary({
    this.totalThisMonth = 0,
    this.totalLastMonth = 0,
    this.changePercent = 0,
    this.byCategory = const {},
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    final catMap = <String, double>{};
    if (json['by_category'] is Map) {
      (json['by_category'] as Map).forEach((k, v) {
        catMap[k.toString()] = _parseDouble(v);
      });
    }
    return ExpenseSummary(
      totalThisMonth: _parseDouble(json['total_this_month']),
      totalLastMonth: _parseDouble(json['total_last_month']),
      changePercent: _parseDouble(json['change_percent']),
      byCategory: catMap,
    );
  }
}

// ===========================================================================
// TRA VFD INTEGRATION (Risiti za TRA)
// ===========================================================================

class VfdConfig {
  final int? id;
  final int? businessId;
  final String? tin;
  final String? vrn;
  final String? serialNumber;
  final String? registrationId;
  final String? certificateKey;
  final bool isActive;
  final DateTime? registeredAt;

  VfdConfig({
    this.id,
    this.businessId,
    this.tin,
    this.vrn,
    this.serialNumber,
    this.registrationId,
    this.certificateKey,
    this.isActive = false,
    this.registeredAt,
  });

  factory VfdConfig.fromJson(Map<String, dynamic> json) {
    return VfdConfig(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      tin: json['tin']?.toString(),
      vrn: json['vrn']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      registrationId: json['registration_id']?.toString(),
      certificateKey: json['certificate_key']?.toString(),
      isActive: _parseBool(json['is_active']),
      registeredAt: _parseDate(json['registered_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'tin': tin,
        'vrn': vrn,
        'serial_number': serialNumber,
        'registration_id': registrationId,
        'certificate_key': certificateKey,
      };
}

class FiscalReceipt {
  final int? id;
  final int? invoiceId;
  final String? receiptNumber;
  final String? fiscalCode;
  final String? qrCode;
  final String? tin;
  final String? vrn;
  final double totalAmount;
  final double vatAmount;
  final DateTime? issuedAt;
  final String? verificationUrl;

  FiscalReceipt({
    this.id,
    this.invoiceId,
    this.receiptNumber,
    this.fiscalCode,
    this.qrCode,
    this.tin,
    this.vrn,
    this.totalAmount = 0,
    this.vatAmount = 0,
    this.issuedAt,
    this.verificationUrl,
  });

  factory FiscalReceipt.fromJson(Map<String, dynamic> json) {
    return FiscalReceipt(
      id: _parseInt(json['id']),
      invoiceId: _parseInt(json['invoice_id']),
      receiptNumber: json['receipt_number']?.toString(),
      fiscalCode: json['fiscal_code']?.toString(),
      qrCode: json['qr_code']?.toString(),
      tin: json['tin']?.toString(),
      vrn: json['vrn']?.toString(),
      totalAmount: _parseDouble(json['total_amount']),
      vatAmount: _parseDouble(json['vat_amount']),
      issuedAt: _parseDate(json['issued_at']),
      verificationUrl: json['verification_url']?.toString(),
    );
  }
}

// ===========================================================================
// RECURRING INVOICES (Ankara za Mara kwa Mara)
// ===========================================================================

enum RecurringFrequency { weekly, monthly, quarterly, yearly }

RecurringFrequency _parseRecurringFrequency(dynamic v) {
  if (v == null) return RecurringFrequency.monthly;
  final s = v.toString().toLowerCase();
  for (final rf in RecurringFrequency.values) {
    if (rf.name == s) return rf;
  }
  return RecurringFrequency.monthly;
}

String recurringFrequencyLabel(RecurringFrequency f, {bool swahili = false}) {
  switch (f) {
    case RecurringFrequency.weekly:
      return swahili ? 'Kila Wiki' : 'Weekly';
    case RecurringFrequency.monthly:
      return swahili ? 'Kila Mwezi' : 'Monthly';
    case RecurringFrequency.quarterly:
      return swahili ? 'Kila Robo Mwaka' : 'Quarterly';
    case RecurringFrequency.yearly:
      return swahili ? 'Kila Mwaka' : 'Yearly';
  }
}

class RecurringInvoice {
  final int? id;
  final int? businessId;
  final int? customerId;
  final String? customerName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final RecurringFrequency frequency;
  final DateTime? nextIssueDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int totalIssued;
  final DateTime? createdAt;

  RecurringInvoice({
    this.id,
    this.businessId,
    this.customerId,
    this.customerName,
    this.items = const [],
    this.subtotal = 0,
    this.vatAmount = 0,
    this.totalAmount = 0,
    this.frequency = RecurringFrequency.monthly,
    this.nextIssueDate,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.totalIssued = 0,
    this.createdAt,
  });

  factory RecurringInvoice.fromJson(Map<String, dynamic> json) {
    List<InvoiceItem> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List)
          .map((i) => InvoiceItem.fromJson(i is Map<String, dynamic> ? i : {}))
          .toList();
    }
    return RecurringInvoice(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      customerId: _parseInt(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      items: items,
      subtotal: _parseDouble(json['subtotal']),
      vatAmount: _parseDouble(json['vat_amount']),
      totalAmount: _parseDouble(json['total_amount']),
      frequency: _parseRecurringFrequency(json['frequency']),
      nextIssueDate: _parseDate(json['next_issue_date']),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      isActive: _parseBool(json['is_active'], true),
      totalIssued: _parseInt(json['total_issued']) ?? 0,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'customer_id': customerId,
        'customer_name': customerName,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'vat_amount': vatAmount,
        'total_amount': totalAmount,
        'frequency': frequency.name,
        'next_issue_date': nextIssueDate?.toIso8601String(),
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': isActive,
      };
}

// ===========================================================================
// CRB CREDIT REPORT & CREDIT SCORE (Ripoti ya Mkopo)
// ===========================================================================

class CreditReport {
  final int? id;
  final int? businessId;
  final DateTime? reportDate;
  final int creditScore;
  final String riskGrade;
  final int totalActiveLoanAccounts;
  final int totalClosedAccounts;
  final double totalOutstandingBalance;
  final double totalOverdueAmount;
  final String? worstArrearStatus;
  final int inquiriesLast90Days;
  final List<PaymentRecord> paymentHistory;
  final String? reportPdfUrl;

  CreditReport({
    this.id,
    this.businessId,
    this.reportDate,
    this.creditScore = 0,
    this.riskGrade = 'E',
    this.totalActiveLoanAccounts = 0,
    this.totalClosedAccounts = 0,
    this.totalOutstandingBalance = 0,
    this.totalOverdueAmount = 0,
    this.worstArrearStatus,
    this.inquiriesLast90Days = 0,
    this.paymentHistory = const [],
    this.reportPdfUrl,
  });

  factory CreditReport.fromJson(Map<String, dynamic> json) {
    List<PaymentRecord> history = [];
    if (json['payment_history'] is List) {
      history = (json['payment_history'] as List)
          .map((e) => PaymentRecord.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return CreditReport(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      reportDate: _parseDate(json['report_date']),
      creditScore: _parseInt(json['credit_score']) ?? 0,
      riskGrade: json['risk_grade']?.toString() ?? 'E',
      totalActiveLoanAccounts: _parseInt(json['total_active_loan_accounts']) ?? 0,
      totalClosedAccounts: _parseInt(json['total_closed_accounts']) ?? 0,
      totalOutstandingBalance: _parseDouble(json['total_outstanding_balance']),
      totalOverdueAmount: _parseDouble(json['total_overdue_amount']),
      worstArrearStatus: json['worst_arrear_status']?.toString(),
      inquiriesLast90Days: _parseInt(json['inquiries_last_90_days']) ?? 0,
      paymentHistory: history,
      reportPdfUrl: json['report_pdf_url']?.toString(),
    );
  }
}

class PaymentRecord {
  final String? lender;
  final String? accountType;
  final DateTime? openDate;
  final double balance;
  final int arrearsDays;
  final String? status;

  PaymentRecord({
    this.lender,
    this.accountType,
    this.openDate,
    this.balance = 0,
    this.arrearsDays = 0,
    this.status,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      lender: json['lender']?.toString(),
      accountType: json['account_type']?.toString(),
      openDate: _parseDate(json['open_date']),
      balance: _parseDouble(json['balance']),
      arrearsDays: _parseInt(json['arrears_days']) ?? 0,
      status: json['status']?.toString(),
    );
  }
}

class CreditScore {
  final int score;
  final String grade;
  final DateTime? lastUpdated;
  final List<ScoreFactor> factors;
  final String trend; // up, down, stable

  CreditScore({
    this.score = 0,
    this.grade = 'E',
    this.lastUpdated,
    this.factors = const [],
    this.trend = 'stable',
  });

  factory CreditScore.fromJson(Map<String, dynamic> json) {
    List<ScoreFactor> factors = [];
    if (json['factors'] is List) {
      factors = (json['factors'] as List)
          .map((e) => ScoreFactor.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return CreditScore(
      score: _parseInt(json['score']) ?? 0,
      grade: json['grade']?.toString() ?? 'E',
      lastUpdated: _parseDate(json['last_updated']),
      factors: factors,
      trend: json['trend']?.toString() ?? 'stable',
    );
  }
}

class ScoreFactor {
  final String? factor;
  final String? impact; // positive, negative
  final String? description;

  ScoreFactor({this.factor, this.impact, this.description});

  factory ScoreFactor.fromJson(Map<String, dynamic> json) {
    return ScoreFactor(
      factor: json['factor']?.toString(),
      impact: json['impact']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

// ===========================================================================
// PAYMENT REMINDERS (Vikumbusho vya Malipo)
// ===========================================================================

class ReminderConfig {
  final int? id;
  final int? businessId;
  final bool isEnabled;
  final List<int> reminderDays;
  final List<String> channels;
  final String? customMessage;

  ReminderConfig({
    this.id,
    this.businessId,
    this.isEnabled = false,
    this.reminderDays = const [0, 7, 14, 30],
    this.channels = const ['sms', 'tajiri'],
    this.customMessage,
  });

  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    return ReminderConfig(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      isEnabled: _parseBool(json['is_enabled']),
      reminderDays: (json['reminder_days'] as List?)
              ?.map((e) => _parseInt(e) ?? 0)
              .toList() ??
          [0, 7, 14, 30],
      channels: (json['channels'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          ['sms', 'tajiri'],
      customMessage: json['custom_message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_enabled': isEnabled,
        'reminder_days': reminderDays,
        'channels': channels,
        'custom_message': customMessage,
      };
}

// ===========================================================================
// PURCHASE ORDERS / SUPPLIERS (Maagizo ya Manunuzi)
// ===========================================================================

class Supplier {
  final int? id;
  final int? businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? tinNumber;
  final String? notes;
  final DateTime? createdAt;

  Supplier({
    this.id,
    this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.tinNumber,
    this.notes,
    this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      tinNumber: json['tin_number']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'tin_number': tinNumber,
        'notes': notes,
      };
}

enum PurchaseOrderStatus { draft, sent, received, cancelled }

PurchaseOrderStatus _parsePOStatus(dynamic v) {
  if (v == null) return PurchaseOrderStatus.draft;
  final s = v.toString().toLowerCase();
  for (final ps in PurchaseOrderStatus.values) {
    if (ps.name == s) return ps;
  }
  return PurchaseOrderStatus.draft;
}

String poStatusLabel(PurchaseOrderStatus s) {
  switch (s) {
    case PurchaseOrderStatus.draft:
      return 'Rasimu';
    case PurchaseOrderStatus.sent:
      return 'Imetumwa';
    case PurchaseOrderStatus.received:
      return 'Imepokelewa';
    case PurchaseOrderStatus.cancelled:
      return 'Imefutwa';
  }
}

class PurchaseOrder {
  final int? id;
  final int? businessId;
  final String poNumber;
  final int? supplierId;
  final String? supplierName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final PurchaseOrderStatus status;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final DateTime? createdAt;

  PurchaseOrder({
    this.id,
    this.businessId,
    this.poNumber = '',
    this.supplierId,
    this.supplierName,
    this.items = const [],
    this.subtotal = 0,
    this.vatAmount = 0,
    this.totalAmount = 0,
    this.status = PurchaseOrderStatus.draft,
    this.expectedDeliveryDate,
    this.notes,
    this.createdAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    List<InvoiceItem> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List)
          .map((i) => InvoiceItem.fromJson(i is Map<String, dynamic> ? i : {}))
          .toList();
    }
    return PurchaseOrder(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      poNumber: json['po_number']?.toString() ?? '',
      supplierId: _parseInt(json['supplier_id']),
      supplierName: json['supplier_name']?.toString(),
      items: items,
      subtotal: _parseDouble(json['subtotal']),
      vatAmount: _parseDouble(json['vat_amount']),
      totalAmount: _parseDouble(json['total_amount']),
      status: _parsePOStatus(json['status']),
      expectedDeliveryDate: _parseDate(json['expected_delivery_date']),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'po_number': poNumber,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'vat_amount': vatAmount,
        'total_amount': totalAmount,
        'status': status.name,
        'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
        'notes': notes,
      };
}

// ===========================================================================
// APPOINTMENT BOOKING (Miadi ya Wateja)
// ===========================================================================

enum AppointmentStatus { pending, confirmed, completed, cancelled, noShow }

AppointmentStatus _parseAppointmentStatus(dynamic v) {
  if (v == null) return AppointmentStatus.pending;
  final s = v.toString().toLowerCase();
  if (s == 'no_show' || s == 'noshow') return AppointmentStatus.noShow;
  for (final as_ in AppointmentStatus.values) {
    if (as_.name == s) return as_;
  }
  return AppointmentStatus.pending;
}

String appointmentStatusLabel(AppointmentStatus s) {
  switch (s) {
    case AppointmentStatus.pending:
      return 'Inasubiri';
    case AppointmentStatus.confirmed:
      return 'Imethibitishwa';
    case AppointmentStatus.completed:
      return 'Imekamilika';
    case AppointmentStatus.cancelled:
      return 'Imefutwa';
    case AppointmentStatus.noShow:
      return 'Hakuja';
  }
}

class BusinessAppointment {
  final int? id;
  final int? businessId;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? serviceName;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final int durationMinutes;
  final AppointmentStatus status;
  final double depositAmount;
  final String? notes;
  final DateTime? createdAt;

  BusinessAppointment({
    this.id,
    this.businessId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.serviceName,
    this.date,
    this.startTime,
    this.endTime,
    this.durationMinutes = 60,
    this.status = AppointmentStatus.pending,
    this.depositAmount = 0,
    this.notes,
    this.createdAt,
  });

  factory BusinessAppointment.fromJson(Map<String, dynamic> json) {
    return BusinessAppointment(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      customerId: _parseInt(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      serviceName: json['service_name']?.toString(),
      date: _parseDate(json['date']),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      durationMinutes: _parseInt(json['duration_minutes']) ?? 60,
      status: _parseAppointmentStatus(json['status']),
      depositAmount: _parseDouble(json['deposit_amount']),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'service_name': serviceName,
        'date': date?.toIso8601String(),
        'start_time': startTime,
        'end_time': endTime,
        'duration_minutes': durationMinutes,
        'status': status.name,
        'deposit_amount': depositAmount,
        'notes': notes,
      };
}
