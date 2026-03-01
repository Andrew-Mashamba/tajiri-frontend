class Poll {
  final int id;
  final String question;
  final String? description;
  final int creatorId;
  final int? postId;
  final int? groupId;
  final int? pageId;
  final DateTime? endsAt;
  final bool isMultipleChoice;
  final bool isAnonymous;
  final bool showResultsBeforeVoting;
  final bool allowAddOptions;
  final int totalVotes;
  final String status; // active, closed, ended
  final DateTime createdAt;
  final PollCreator? creator;
  final List<PollOption> options;
  final bool? hasVoted;
  final List<int>? userVotes;
  final int? userVotedOptionId; // Convenience for single-choice polls
  final bool? canVote;
  final bool? canSeeResults;
  final bool? isEnded;

  Poll({
    required this.id,
    required this.question,
    this.description,
    required this.creatorId,
    this.postId,
    this.groupId,
    this.pageId,
    this.endsAt,
    this.isMultipleChoice = false,
    this.isAnonymous = false,
    this.showResultsBeforeVoting = true,
    this.allowAddOptions = false,
    this.totalVotes = 0,
    this.status = 'active',
    required this.createdAt,
    this.creator,
    this.options = const [],
    this.hasVoted,
    this.userVotes,
    this.userVotedOptionId,
    this.canVote,
    this.canSeeResults,
    this.isEnded,
  });

  // Convenience getter for multiple votes support
  bool get allowMultipleVotes => isMultipleChoice;

  factory Poll.fromJson(Map<String, dynamic> json) {
    final userVotes = json['user_votes'] != null
        ? List<int>.from(json['user_votes'])
        : null;
    return Poll(
      id: json['id'],
      question: json['question'] ?? '',
      description: json['description'],
      creatorId: json['creator_id'] ?? 0,
      postId: json['post_id'],
      groupId: json['group_id'],
      pageId: json['page_id'],
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at']) : null,
      isMultipleChoice: json['is_multiple_choice'] ?? false,
      isAnonymous: json['is_anonymous'] ?? false,
      showResultsBeforeVoting: json['show_results_before_voting'] ?? true,
      allowAddOptions: json['allow_add_options'] ?? false,
      totalVotes: json['total_votes'] ?? 0,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      creator: json['creator'] != null
          ? PollCreator.fromJson(json['creator'])
          : null,
      options: json['options'] != null
          ? (json['options'] as List).map((o) => PollOption.fromJson(o)).toList()
          : [],
      hasVoted: json['has_voted'],
      userVotes: userVotes,
      userVotedOptionId: json['user_voted_option_id'] ?? (userVotes != null && userVotes.isNotEmpty ? userVotes.first : null),
      canVote: json['can_vote'],
      canSeeResults: json['can_see_results'],
      isEnded: json['is_ended'],
    );
  }

  Poll copyWith({
    int? id,
    String? question,
    String? description,
    int? creatorId,
    int? postId,
    int? groupId,
    int? pageId,
    DateTime? endsAt,
    bool? isMultipleChoice,
    bool? isAnonymous,
    bool? showResultsBeforeVoting,
    bool? allowAddOptions,
    int? totalVotes,
    String? status,
    DateTime? createdAt,
    PollCreator? creator,
    List<PollOption>? options,
    bool? hasVoted,
    List<int>? userVotes,
    int? userVotedOptionId,
    bool? canVote,
    bool? canSeeResults,
    bool? isEnded,
  }) {
    return Poll(
      id: id ?? this.id,
      question: question ?? this.question,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      postId: postId ?? this.postId,
      groupId: groupId ?? this.groupId,
      pageId: pageId ?? this.pageId,
      endsAt: endsAt ?? this.endsAt,
      isMultipleChoice: isMultipleChoice ?? this.isMultipleChoice,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      showResultsBeforeVoting: showResultsBeforeVoting ?? this.showResultsBeforeVoting,
      allowAddOptions: allowAddOptions ?? this.allowAddOptions,
      totalVotes: totalVotes ?? this.totalVotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      creator: creator ?? this.creator,
      options: options ?? this.options,
      hasVoted: hasVoted ?? this.hasVoted,
      userVotes: userVotes ?? this.userVotes,
      userVotedOptionId: userVotedOptionId ?? this.userVotedOptionId,
      canVote: canVote ?? this.canVote,
      canSeeResults: canSeeResults ?? this.canSeeResults,
      isEnded: isEnded ?? this.isEnded,
    );
  }

  bool get hasEnded {
    if (isEnded == true) return true;
    if (endsAt == null) return false;
    return endsAt!.isBefore(DateTime.now());
  }

  bool get isActive => !hasEnded;
}

class PollOption {
  final int id;
  final int pollId;
  final String optionText;
  final String? imagePath;
  final int votesCount;
  final int order;
  final int? addedBy;
  final double? percentage;

  PollOption({
    required this.id,
    required this.pollId,
    required this.optionText,
    this.imagePath,
    this.votesCount = 0,
    this.order = 0,
    this.addedBy,
    this.percentage,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'],
      pollId: json['poll_id'],
      optionText: json['option_text'] ?? '',
      imagePath: json['image_path'],
      votesCount: json['votes_count'] ?? 0,
      order: json['order'] ?? 0,
      addedBy: json['added_by'],
      percentage: json['percentage']?.toDouble(),
    );
  }

  PollOption copyWith({
    int? id,
    int? pollId,
    String? optionText,
    String? imagePath,
    int? votesCount,
    int? order,
    int? addedBy,
    double? percentage,
  }) {
    return PollOption(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      optionText: optionText ?? this.optionText,
      imagePath: imagePath ?? this.imagePath,
      votesCount: votesCount ?? this.votesCount,
      order: order ?? this.order,
      addedBy: addedBy ?? this.addedBy,
      percentage: percentage ?? this.percentage,
    );
  }
}

class PollCreator {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  PollCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory PollCreator.fromJson(Map<String, dynamic> json) {
    return PollCreator(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class PollVoter {
  final int id;
  final int optionId;
  final DateTime votedAt;
  final PollVoterUser? user;

  PollVoter({
    required this.id,
    required this.optionId,
    required this.votedAt,
    this.user,
  });

  factory PollVoter.fromJson(Map<String, dynamic> json) {
    return PollVoter(
      id: json['id'] ?? 0,
      optionId: json['option_id'] ?? json['poll_option_id'] ?? 0,
      votedAt: json['voted_at'] != null
          ? DateTime.parse(json['voted_at'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      user: json['user'] != null ? PollVoterUser.fromJson(json['user']) : null,
    );
  }
}

class PollVoterUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  PollVoterUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory PollVoterUser.fromJson(Map<String, dynamic> json) {
    return PollVoterUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName';
}
