

class Userx {

  String id = "";
  String name = "";
  String phone = "";
  String password = "";
  String reg_date = "";

  String userId = "";
  String userStatus = "";
  String udid = "";
  String otp = "";
  String is_expired = "";

  String localpostImage = "";
  String remotepostImage = "";
  String create_at = "";

  Userx({
  required this.id,
  required this.name,
  required this.phone,
  required this.password,
  required this.reg_date,
  required this.userId,
  required this.userStatus,
  required this.udid,
  required this.otp,
  required this.is_expired,
  required this.localpostImage,
  required this.remotepostImage,
  required this.create_at
  });

  Userx.fromMap(Map<String, dynamic> data) {
    id = data['id'].toString();
    name = data['name'].toString();
    phone = data['phone'].toString();
    password = data['password'].toString();
    reg_date = data['reg_date'].toString();

    userId = data['userId'].toString();
    userStatus = data['userStatus'].toString();
    udid = data['udid'].toString();
    otp = data['otp'].toString();

    is_expired = data['is_expired'].toString();
    localpostImage = data['localpostImage'].toString();
    remotepostImage = data['remotepostImage'].toString();
    create_at = data['create_at'].toString();
  }

  Userx.fromNetwork(Map<String, dynamic> data) : this.fromMap(data);

  toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'password': password,
    'reg_date' : reg_date,

    'userId': userId,
    'userStatus': userStatus,
    'udid': udid,
    'otp': otp,
    'is_expired' : is_expired,

    'localpostImage': localpostImage,
    'remotepostImage': remotepostImage,
    'create_at': create_at
  };


  factory Userx.fromJson(Map<dynamic, dynamic> json) {
    return Userx(
        id: (json["id"] ?? "").toString(),
        name: (json["name"] ?? "").toString(),
        phone: (json["phone"] ?? "").toString(),
        password: (json["password"] ?? "").toString(),
        reg_date: (json["reg_date"] ?? "").toString(),

        userId: (json["userId"] ?? "").toString(),
        userStatus: (json["userStatus"] ?? "").toString(),
        udid: (json["udid"] ?? "").toString(),
        otp: (json["otp"] ?? "").toString(),
        is_expired: (json["is_expired"] ?? "").toString(),

        localpostImage: (json["localpostImage"] ?? "").toString(),
        remotepostImage: (json["remotepostImage"] ?? "").toString(),
        create_at: (json["create_at"] ?? "").toString()
    );
  }
}