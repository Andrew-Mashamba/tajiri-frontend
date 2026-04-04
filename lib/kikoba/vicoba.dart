class vicoba {

  String id;
  String kikobaid;
  String kikobaname;

  String creatorid;
  String creatorname;
  String creatorphone;

  String password;
  String reg_date;
  String maelezokuhusukikoba;

  String location;
  String membersNo;
  String endOfTermDate;
  String kikobaImage;
  String membershipStatus;
  String requestId;

  String source;

  // Group bank account details
  String? groupAccountNumber;
  String? groupBankName;
  String? groupBankCode;



  vicoba({
    required this.id,
    required this.kikobaid,
    required this.kikobaname,

    required this.creatorid,
    required this.creatorname,
    required this.creatorphone,

    required this.password,
    required this.reg_date,
    required this.maelezokuhusukikoba,

    required this.location,
    required this.membersNo,
    required this.kikobaImage,
    required this.endOfTermDate,
    required this.membershipStatus,
    required this.requestId,
    required this.source,

    this.groupAccountNumber,
    this.groupBankName,
    this.groupBankCode,
  });

  factory vicoba.fromJson(Map<String, dynamic> json) {
    return vicoba(
        id: json['id'].toString(),
        kikobaid: json['kikobaid'].toString(),
        kikobaname: json['kikobaname'].toString(),

        creatorid: json['creatorid'].toString(),
        creatorname: json['creatorname'].toString(),
        creatorphone: json['creatorphone'].toString(),

        password: json['password'].toString(),
        reg_date: json['reg_date'].toString(),
        maelezokuhusukikoba: json['maelezokuhusukikoba'].toString(),

        location: json['location'].toString(),
        membersNo: json['membersNo'].toString(),
        kikobaImage: json["kikobaImage"].toString(),
        endOfTermDate: json['endOfTermDate'].toString(),
        membershipStatus: json['membershipStatus'].toString(),
        requestId: json['requestId'].toString(),
        source: json['source'].toString(),

        groupAccountNumber: json['group_account_number']?.toString(),
        groupBankName: json['group_bank_name']?.toString(),
        groupBankCode: json['group_bank_code']?.toString(),
    );
  }

  /// Convert vicoba to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kikobaid': kikobaid,
      'kikobaname': kikobaname,
      'creatorid': creatorid,
      'creatorname': creatorname,
      'creatorphone': creatorphone,
      'password': password,
      'reg_date': reg_date,
      'maelezokuhusukikoba': maelezokuhusukikoba,
      'location': location,
      'membersNo': membersNo,
      'kikobaImage': kikobaImage,
      'endOfTermDate': endOfTermDate,
      'membershipStatus': membershipStatus,
      'requestId': requestId,
      'source': source,
      'group_account_number': groupAccountNumber,
      'group_bank_name': groupBankName,
      'group_bank_code': groupBankCode,
    };
  }
}