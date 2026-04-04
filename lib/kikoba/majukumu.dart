
class majukumuData {
  String kikobaID;
  String userID;
  String caseID;
  String type;
  String maelezo;
  String chairmansVote;
  String secretarysVote;
  String quarantorsVote;
  String othersVote;
  String status;
  String dateTime;
  String othersVoteNo;

  majukumuData(
      {
        required this.kikobaID,
        required this.userID,
        required this.caseID,
        required this.type,
        required this.maelezo,
        required this.chairmansVote,
        required this.secretarysVote,
        required this.quarantorsVote,
        required this.othersVote,
        required this.status,
        required this.dateTime,
        required this.othersVoteNo});

  factory majukumuData.fromJson(Map<String, dynamic> json) {
    return majukumuData(
        kikobaID: json["kikobaID"],
        userID: json["userID"],
        caseID: json["caseID"],
        type: json["type"],
        maelezo: json["maelezo"],
        chairmansVote: json["chairmansVote"],
        secretarysVote: json["secretarysVote"],
        quarantorsVote: json["quarantorsVote"],
        othersVote: json["othersVote"],
        status: json["status"],
        dateTime: json["dateTime"],
        othersVoteNo: json["othersVoteNo"]);
  }
}

