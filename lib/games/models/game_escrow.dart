// lib/games/models/game_escrow.dart

class GameEscrow {
  final int id;
  final int sessionId;
  final int userId;
  final double amount;
  final String currency;
  final String status;
  final double settledAmount;

  GameEscrow({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.amount,
    this.currency = 'TZS',
    required this.status,
    this.settledAmount = 0,
  });

  bool get isLocked => status == 'locked';
  bool get isSettled => status == 'settled';
  bool get isRefunded => status == 'refunded';

  factory GameEscrow.fromJson(Map<String, dynamic> json) {
    return GameEscrow(
      id: _parseInt(json['id']),
      sessionId: _parseInt(json['session_id']),
      userId: _parseInt(json['user_id']),
      amount: _parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'TZS',
      status: json['status']?.toString() ?? 'pending',
      settledAmount: _parseDouble(json['settled_amount']),
    );
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
