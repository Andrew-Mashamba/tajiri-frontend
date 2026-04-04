

class Kikoba {
  String kikobaid;
  String kikobaname;
  String creatorname;
  String reg_date;
  String location;
  String maelezokuhusukikoba;
  String membersNo;
  String kikobaImage;


  Kikoba(
      {
        required this.kikobaid,
        required this.kikobaname,
        required this.location,
        required this.creatorname,
        required this.maelezokuhusukikoba,
        required this.membersNo,
        required this.kikobaImage,
        required this.reg_date
      });

  factory Kikoba.fromJson(Map<String, dynamic> json) {
    return Kikoba(
        kikobaid: json["kikobaid"],
        kikobaname: json["kikobaname"],
        location: json["location"],
        creatorname: json["creatorname"],
        maelezokuhusukikoba: json["maelezokuhusukikoba"],
        membersNo: json["membersNo"],
        kikobaImage: json["kikobaImage"],
        reg_date: json["reg_date"]);
  }
}
