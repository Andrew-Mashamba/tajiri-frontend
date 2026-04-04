
class Ada {
  String amount;
  String mwezi;
  String penati;
  String id;

  Ada(
      {
        required this.amount,
        required this.mwezi,
        required this.penati,
        required this.id});

  factory Ada.fromJson(Map<String, dynamic> json) {
    return Ada(
        amount: json["amount"].toString(),
        mwezi: json["mwezi"],
        penati: json["penati"],
        id: json["id"]);
  }
}
