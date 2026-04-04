class user {
  final int id;
  final String userId;
  final String name;
  final String mobNumber;

  user({required this.id, required this.userId, required this.name, required this.mobNumber});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'mobNumber': mobNumber,
    };
  }
}