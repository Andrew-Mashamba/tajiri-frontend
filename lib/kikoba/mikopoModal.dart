/// @deprecated This model is deprecated. Use [LoanApplication] from `lib/models/loan_models.dart` instead.
/// The new LoanApplication model provides comprehensive loan lifecycle tracking.
/// Keeping for backward compatibility with legacy code paths.
class mkopo {


  String id,loanID, tenure, mdhaminiId, interest,disbursementNumber,amount,month,accountsDateTime,dateTime,
  mdhaminiVote,mkitiVote,katibuVote,blockedStatus,blockedById,blockedReason,performance,generalStatus,rejesho;


  mkopo({
    required this.id,
    required this.loanID,
    required this.tenure,
    required this.interest,
    required this.disbursementNumber,

    required this.amount,
    required this.month,
    required this.accountsDateTime,

    required this.dateTime,
    required this.mdhaminiVote,
    required this.mkitiVote,

    required this.katibuVote,
    required this.blockedStatus,
    required this.blockedById,

    required this.blockedReason,
    required this.performance,
    required this.generalStatus,
    required this.mdhaminiId,
    required this.rejesho,

  });
  //constructor

  factory mkopo.fromJSON(Map<String, dynamic> json){
    //print("HAPAA");
    //print(json.keys);


    return mkopo(
        id: json["id"],
        loanID: json["loanID"].toString(),
        tenure: json["tenure"].toString(),
        mdhaminiId: json["mdhaminiId"].toString(),
        disbursementNumber: json["disbursementNumber"].toString(),

        amount: json["amount"].toString(),
        month: json["month"].toString(),
        accountsDateTime: json["accountsDateTime"].toString(),
        dateTime: json["dateTime"].toString(),
        mdhaminiVote: json["mdhaminiVote"].toString(),

        mkitiVote: json["mkitiVote"],
        katibuVote: json["katibuVote"].toString(),
        blockedStatus: json["blockedStatus"].toString(),
        blockedById: json["blockedById"].toString(),
        blockedReason: json["blockedReason"].toString(),

        performance: json["performance"],
        generalStatus: json["generalStatus"].toString(),
        rejesho: json["rejesho"].toString(),
        interest: json["interest"].toString()
    );
  }
}