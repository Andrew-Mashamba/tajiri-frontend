class NameOne{

  String id,dateTime, maelezo, amount, balance;

  NameOne({
    required this.id,
    required this.dateTime,
    required this.maelezo,
    required this.amount,
    required this.balance
  });
  //constructor

  factory NameOne.fromJSON(Map<String, dynamic> json){
    //print("HAPAA");
    //print(json.keys);
    return NameOne(
        id: json["id"],
        dateTime: json["dateTime"].toString(),
        maelezo: json["maelezo"].toString(),
        amount: json["amount"].toString(),
        balance: json["balance"].toString()
    );
  }
}