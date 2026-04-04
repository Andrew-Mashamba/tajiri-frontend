class member{

  String id,name, phone, reg_date, userId, userStatus;

  // Member's personal bank account details
  String? accountNumber;
  String? bankName;
  String? bankCode;

  member({
    required this.id,
    required this.name,
    required this.phone,
    required this.reg_date,
    required this.userStatus,
    required this.userId,
    this.accountNumber,
    this.bankName,
    this.bankCode,
  });
  //constructor

  factory member.fromJSON(Map<String, dynamic> json){
    //print("HAPAA");
    //print(json.keys);
    return member(
        id: json["id"],
        name: json["name"].toString(),
        phone: json["phone"].toString(),
        reg_date: json["reg_date"].toString(),
        userStatus: json["userStatus"].toString(),
        userId: json["userId"].toString(),
        accountNumber: json["bank_account"]?.toString(),
        bankName: json["bank_name"]?.toString(),
        bankCode: json["bank_code"]?.toString(),
    );
  }
}