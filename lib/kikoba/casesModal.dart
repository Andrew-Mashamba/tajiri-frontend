class thecase{

  // Legacy fields
  String id,kikobaID, userID, caseID, date,type,maelezo,numberOfVoters,fiftyPercentCheck,seventyFivePercentCheck,
      aHundredPercentCheck,chairmansVote,secretarysVote,quarantorsVote,othersVote,othersVoteNo,status,dateTime;

  // New voting case fields
  String? title;
  String? votingType; // yes_no or multiple_choice
  List<String>? options; // For multiple choice
  Map<String, int>? optionVotes; // Vote counts per option
  String? deadline;
  String? category;
  int? yesCount;
  int? noCount;
  int? abstainCount;
  int? totalVotes;
  double? approvalPercentage;
  double? approvalThreshold;
  bool? hasReachedThreshold;

  thecase({
    required this.id,
    required this.kikobaID,
    required this.userID,
    required this.caseID,
    required this.date,

    required this.type,
    required this.maelezo,
    required this.numberOfVoters,

    required this.dateTime,
    required this.fiftyPercentCheck,
    required this.seventyFivePercentCheck,

    required this.aHundredPercentCheck,
    required this.chairmansVote,
    required this.secretarysVote,

    required this.quarantorsVote,
    required this.othersVote,
    required this.othersVoteNo,
    required this.status,

    // New optional fields
    this.title,
    this.votingType,
    this.options,
    this.optionVotes,
    this.deadline,
    this.category,
    this.yesCount,
    this.noCount,
    this.abstainCount,
    this.totalVotes,
    this.approvalPercentage,
    this.approvalThreshold,
    this.hasReachedThreshold,
  });

  // Helper to check if this is a multiple choice voting case
  bool get isMultipleChoice => votingType == 'multiple_choice' && options != null && options!.isNotEmpty;

  // Get display title (use title if available, fallback to maelezo)
  String get displayTitle => title ?? maelezo;

  factory thecase.fromJSON(Map<String, dynamic> json){
    // Parse options list
    List<String>? optionsList;
    if (json['options'] != null) {
      if (json['options'] is List) {
        optionsList = (json['options'] as List).map((e) => e.toString()).toList();
      }
    }

    // Parse option_votes map
    Map<String, int>? optionVotesMap;
    if (json['option_votes'] != null && json['option_votes'] is Map) {
      optionVotesMap = {};
      (json['option_votes'] as Map).forEach((key, value) {
        optionVotesMap![key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    // Parse voting summary
    final voting = json['voting'];
    int? yesCount, noCount, abstainCount, totalVotes;
    double? approvalPercentage, approvalThreshold;
    bool? hasReachedThreshold;

    if (voting != null && voting is Map) {
      yesCount = voting['yes_count'] is int ? voting['yes_count'] : int.tryParse(voting['yes_count']?.toString() ?? '');
      noCount = voting['no_count'] is int ? voting['no_count'] : int.tryParse(voting['no_count']?.toString() ?? '');
      abstainCount = voting['abstain_count'] is int ? voting['abstain_count'] : int.tryParse(voting['abstain_count']?.toString() ?? '');
      totalVotes = voting['total_votes'] is int ? voting['total_votes'] : int.tryParse(voting['total_votes']?.toString() ?? '');
      approvalPercentage = voting['approval_percentage'] is double ? voting['approval_percentage'] : double.tryParse(voting['approval_percentage']?.toString() ?? '');
      approvalThreshold = voting['approval_threshold'] is double ? voting['approval_threshold'] : double.tryParse(voting['approval_threshold']?.toString() ?? '');
      hasReachedThreshold = voting['has_reached_threshold'] == true || voting['has_reached_threshold'] == 'true';
    }

    return thecase(
        id: json["id"]?.toString() ?? '',
        kikobaID: json["kikobaID"]?.toString() ?? json["kikoba_id"]?.toString() ?? '',
        userID: json["userID"]?.toString() ?? json["user_id"]?.toString() ?? json["created_by"]?.toString() ?? '',
        caseID: json["caseID"]?.toString() ?? json["case_id"]?.toString() ?? '',
        date: json["date"]?.toString() ?? json["created_at"]?.toString() ?? '',

        type: json["type"]?.toString() ?? 'voting_case',
        maelezo: json["maelezo"]?.toString() ?? json["description"]?.toString() ?? '',
        numberOfVoters: json["numberOfVoters"]?.toString() ?? '0',
        dateTime: json["dateTime"]?.toString() ?? json["created_at"]?.toString() ?? '',
        fiftyPercentCheck: json["fiftyPercentCheck"]?.toString() ?? '',

        seventyFivePercentCheck: json["seventyFivePercentCheck"]?.toString() ?? '',
        aHundredPercentCheck: json["aHundredPercentCheck"]?.toString() ?? '',
        chairmansVote: json["chairmansVote"]?.toString() ?? '',
        secretarysVote: json["secretarysVote"]?.toString() ?? '',
        quarantorsVote: json["quarantorsVote"]?.toString() ?? '',

        othersVote: json["othersVote"]?.toString() ?? '0',
        othersVoteNo: json["othersVoteNo"]?.toString() ?? '0',
        status: json["status"]?.toString() ?? 'pending',

        // New fields
        title: json["title"]?.toString(),
        votingType: json["voting_type"]?.toString(),
        options: optionsList,
        optionVotes: optionVotesMap,
        deadline: json["deadline"]?.toString(),
        category: json["category"]?.toString(),
        yesCount: yesCount,
        noCount: noCount,
        abstainCount: abstainCount,
        totalVotes: totalVotes,
        approvalPercentage: approvalPercentage,
        approvalThreshold: approvalThreshold,
        hasReachedThreshold: hasReachedThreshold,
    );
  }
}