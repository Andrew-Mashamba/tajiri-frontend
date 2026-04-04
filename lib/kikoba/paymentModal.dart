class paymentModal {
  String date;
  double ppmt, ipmt, pmt;

  paymentModal({
    required this.date,
    required this.ppmt,
    required this.ipmt,
    required this.pmt
  });
  //constructor

  factory paymentModal.fromJSON(Map<String, dynamic> json){
    //print("HAPAA");
    //print(json.keys);
    return paymentModal(
        date: json["date"],
        ppmt: json["ppmt"],
        ipmt: json["ipmt"],
        pmt: json["pmt"]
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'date': date,
        'ppmt': ppmt,
        'ipmt': ipmt,
        'pmt': pmt,
      };
}
