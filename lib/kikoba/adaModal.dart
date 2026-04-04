class adaModal{

  String name,id,adaId, month, value, reg_date;

  adaModal({
    required this.name,
    required this.id,
    required this.adaId,
    required this.month,
    required this.value,
    required this.reg_date
  });
  //constructor

  factory adaModal.fromJSON(Map<String, dynamic> json){
    //print("HAPAA");
    //print(json.keys);
    return adaModal(
        name: json["name"],
        id: json["id"],
        adaId: json["adaId"].toString(),
        month: json["month"].toString(),
        value: json["value"].toString(),
        reg_date: json["reg_date"].toString()
    );
  }
}