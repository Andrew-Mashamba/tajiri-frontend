
class Article {
  String kikobaid;
  String kikobaname;
  String creatorid;
  String creatorname;
  String creatorphone;
  String reg_date;

  Article(
      {
        required this.kikobaid,
        required this.kikobaname,
        required this.creatorid,
        required this.creatorname,
        required this.creatorphone,
        required this.reg_date});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
    kikobaid: json["kikobaid"],
kikobaname: json["kikobaname"],
creatorid: json["creatorid"],
creatorname: json["creatorname"],
creatorphone: json["creatorphone"],
reg_date: json["reg_date"]);
  }
}

