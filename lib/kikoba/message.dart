class message {
  final String postId;
  final String posterId;
  final String posterName;
  final String postComment;
  final String posterNumber;
  final String postType;
  final String posterPhoto;
  final String postImage;

  message({
    required this.postId,
    required this.posterId,
    required this.posterName,
    required this.postComment,
    required this.posterNumber,
    required this.postType,
    required this.posterPhoto,
    required this.postImage
  });

  Map<String, Object?> toJson() {
    return {
      'postId': postId,
      'posterId': posterId,
      'posterName': posterName,
      'postComment': postComment,
      'posterNumber': posterNumber,
      'postType': postType,
      'posterPhoto': posterPhoto,
      'postImage': postImage,
    };
  }
  String getposterName(){
    return posterName;
  }

  message.fromJson(Map<String, Object?> json)
      : this(
    postId: json['postId']! as String,
    posterId: json['posterId']! as String,
    posterName: json['posterName']! as String,
    postComment: json['postComment']! as String,
    posterNumber: json['posterNumber']! as String,
    postType: json['postType']! as String,
    posterPhoto: json['posterPhoto']! as String,
    postImage: json['postImage']! as String,
  );


  }

