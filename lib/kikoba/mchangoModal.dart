class mchangoModal{


  String id,userId, mchangoId, mchangiwaId, maelezo,kikobaId,tareheyamwisho,kiasichachini,lengo,performance,blockedStatus,generalStatus,blockedReason,amountPaid,reg_date;

  mchangoModal({
    required this.id,
    required this.userId,
    required this.mchangoId,
    required this.mchangiwaId,
    required this.maelezo,

    required this.kikobaId,
    required this.tareheyamwisho,
    required this.kiasichachini,
    required this.lengo,

    required this.performance,
    required this.blockedStatus,
    required this.generalStatus,
    required this.blockedReason,
    required this.amountPaid,
    required this.reg_date,



  });
  //constructor

  factory mchangoModal.fromJSON(Map<String, dynamic> json){
    //print("HAPAA");
    //print(json.keys);


    return mchangoModal(
        id: json["id"],
        userId: json["userId"].toString(),
        mchangoId: json["mchangoId"].toString(),
        mchangiwaId: json["mchangiwaId"].toString(),
        maelezo: json["maelezo"].toString(),

        kikobaId: json["kikobaId"].toString(),
        tareheyamwisho: json["tareheyamwisho"].toString(),
        kiasichachini: json["kiasichachini"].toString(),
        lengo: json["lengo"].toString(),

        performance: json["performance"].toString(),
        blockedStatus: json["blockedStatus"].toString(),
        generalStatus: json["generalStatus"].toString(),
        blockedReason: json["blockedReason"].toString(),
        amountPaid: json["amountPaid"].toString(),
        reg_date: json["reg_date"].toString()
    );
  }
}