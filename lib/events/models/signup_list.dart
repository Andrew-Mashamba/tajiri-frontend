// lib/events/models/signup_list.dart
import 'event_rsvp.dart';

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class SignupList {
  final int id;
  final int eventId;
  final String title;
  final List<SignupItem> items;

  SignupList({required this.id, required this.eventId, required this.title, this.items = const []});

  factory SignupList.fromJson(Map<String, dynamic> json) {
    return SignupList(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      title: json['title']?.toString() ?? '',
      items: (json['items'] as List?)?.map((e) => SignupItem.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'items': items.map((e) => e.name).toList(),
  };
}

class SignupItem {
  final int id;
  final String name;
  final int? quantity;
  final int? userId;
  final EventAttendee? claimedBy;

  SignupItem({required this.id, required this.name, this.quantity, this.userId, this.claimedBy});

  bool get isClaimed => userId != null;

  factory SignupItem.fromJson(Map<String, dynamic> json) {
    return SignupItem(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      quantity: json['quantity'] != null ? _parseInt(json['quantity']) : null,
      userId: json['user_id'] != null ? _parseInt(json['user_id']) : null,
      claimedBy: json['claimed_by'] != null ? EventAttendee.fromJson(json['claimed_by']) : null,
    );
  }
}
