class FoodCashDonation {
  final int id;
  final int donorUserId;
  final int orgId;
  final String orgName;
  final String donorType; // individual | institution
  final String? organizationName;
  final String? registrationNumber;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final double amount;
  final String? purpose;
  final String paymentMethod;
  final String? paymentReference;
  final String paymentStatus;
  final String? receiptNumber;
  final bool zakaTagged;
  final bool funguLaKumiTagged;
  final DateTime? createdAt;

  const FoodCashDonation({
    required this.id,
    required this.donorUserId,
    required this.orgId,
    required this.orgName,
    required this.donorType,
    required this.organizationName,
    required this.registrationNumber,
    required this.contactPerson,
    required this.contactPhone,
    required this.contactEmail,
    required this.amount,
    required this.purpose,
    required this.paymentMethod,
    required this.paymentReference,
    required this.paymentStatus,
    required this.receiptNumber,
    required this.zakaTagged,
    required this.funguLaKumiTagged,
    required this.createdAt,
  });

  bool get isInstitutional => donorType == 'institution';

  factory FoodCashDonation.fromJson(Map<String, dynamic> json) {
    return FoodCashDonation(
      id: _int(json['id']) ?? 0,
      donorUserId: _int(json['donor_user_id']) ?? 0,
      orgId: _int(json['org_id']) ?? 0,
      orgName: json['org_name']?.toString() ?? '',
      donorType: json['donor_type']?.toString() ?? 'individual',
      organizationName: json['organization_name']?.toString(),
      registrationNumber: json['registration_number']?.toString(),
      contactPerson: json['contact_person']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      amount: _double(json['amount']) ?? 0,
      purpose: json['purpose']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'wallet',
      paymentReference: json['payment_reference']?.toString(),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      receiptNumber: json['receipt_number']?.toString(),
      zakaTagged: _bool(json['zaka_tagged']),
      funguLaKumiTagged: _bool(json['fungu_la_kumi_tagged']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

int? _int(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _double(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _bool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true' || v == 't';
  return false;
}
