class adapaymentModal {
  String date;
  double amount;

  adapaymentModal({
    required this.date,
    required this.amount
  });
  //constructor

  factory adapaymentModal.fromJSON(Map<String, dynamic> json){
    //print("HAPAA");
    //print(json.keys);
    return adapaymentModal(
        date: json["date"],
        amount: json["amount"]
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'date': date,
        'amount': amount,
      };
}
