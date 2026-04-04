

class loginUser {

  String id = "";
  String userId = "";
  String kikobaId = "";
  String membershipStatus = "";
  String source = "";

  String host = "";
  String cheo = "";
  String namba = "";
  String name = "";
  String otp = "";

  String is_expired = "";
  String create_at = "";
  String reg_date = "";

  loginUser({
  required this.id,
  required this.userId,
  required this.kikobaId,
  required this.membershipStatus,
  required this.source,

  required this.host,
  required this.cheo,
  required this.namba,
  required this.name,
  required this.otp,

  required this.is_expired,
  required this.create_at,
  required this.reg_date

  });

  loginUser.fromMap(Map<String, dynamic> data) {

    id = data['id'].toString();
    userId = data['userId'].toString();
    kikobaId = data['kikobaId'].toString();
    membershipStatus = data['membershipStatus'].toString();
    source = data['source'].toString();

    host = data['host'].toString();
    cheo = data['cheo'].toString();
    namba = data['namba'].toString();
    name = data['name'].toString();
    otp = data['otp'].toString();

    is_expired = data['is_expired'].toString();
    create_at = data['create_at'].toString();
    reg_date = data['reg_date'].toString();
  }

  loginUser.fromNetwork(Map<String, dynamic> data) : this.fromMap(data);

  toMap() => {
    'id' : id,
    'userId' : userId,
    'kikobaId' : kikobaId,
    'membershipStatus' : membershipStatus,
    'source' : source,
    'host' : host,
    'cheo' : cheo,
    'namba' : namba,
    'name' : name,
    'otp' : otp,
    'is_expired' : is_expired,
    'create_at' : create_at,
    'reg_date' : reg_date

  };


  factory loginUser.fromJson(Map<dynamic, dynamic> json) {
    // Extract kikobaId from vicoba array if present
    String extractedKikobaId = '';
    if (json['vicoba'] != null && json['vicoba'] is List && (json['vicoba'] as List).isNotEmpty) {
      extractedKikobaId = json['vicoba'][0]['kikobaid']?.toString() ?? '';
    }

    return loginUser(
        id : json['id'].toString(),
        userId : json['userId'].toString(),
        kikobaId : json['kikobaId']?.toString() ?? extractedKikobaId,
        membershipStatus : json['membershipStatus']?.toString() ?? 'pending',
        source : json['source']?.toString() ?? '',

        host : json['host']?.toString() ?? '',
        cheo : json['cheo']?.toString() ?? '',
        // API returns 'phone', map to 'namba'
        namba : json['phone']?.toString() ?? json['namba']?.toString() ?? '',
        name : json['name']?.toString() ?? '',
        otp : json['otp']?.toString() ?? '',

        is_expired : json['is_expired']?.toString() ?? '',
        create_at : json['create_at']?.toString() ?? '',
        reg_date : json['reg_date']?.toString() ?? ''
    );
  }
}