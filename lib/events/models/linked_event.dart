// lib/events/models/linked_event.dart

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

class EventSeries {
  final int id;
  final int parentEventId;
  final String name;
  final List<LinkedEvent> events;
  final bool sharedCommittee;
  final bool sharedBudget;
  final bool sharedGuestList;
  final bool sharedContributions;

  EventSeries({
    required this.id,
    required this.parentEventId,
    required this.name,
    this.events = const [],
    this.sharedCommittee = true,
    this.sharedBudget = false,
    this.sharedGuestList = true,
    this.sharedContributions = true,
  });

  factory EventSeries.fromJson(Map<String, dynamic> json) {
    return EventSeries(
      id: _parseInt(json['id']),
      parentEventId: _parseInt(json['parent_event_id']),
      name: json['name']?.toString() ?? '',
      events: (json['events'] as List?)?.map((e) => LinkedEvent.fromJson(e)).toList() ?? [],
      sharedCommittee: json['shared_committee'] != null ? _parseBool(json['shared_committee']) : true,
      sharedBudget: _parseBool(json['shared_budget']),
      sharedGuestList: json['shared_guest_list'] != null ? _parseBool(json['shared_guest_list']) : true,
      sharedContributions: json['shared_contributions'] != null ? _parseBool(json['shared_contributions']) : true,
    );
  }
}

class LinkedEvent {
  final int eventId;
  final String name;
  final String? subType;        // kitchen_party, kupamba, send_off, kesha, main
  final DateTime date;
  final String? location;
  final bool isCompleted;
  final int goingCount;

  LinkedEvent({
    required this.eventId,
    required this.name,
    this.subType,
    required this.date,
    this.location,
    this.isCompleted = false,
    this.goingCount = 0,
  });

  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isPast => date.isBefore(DateTime.now());

  factory LinkedEvent.fromJson(Map<String, dynamic> json) {
    return LinkedEvent(
      eventId: _parseInt(json['event_id'] ?? json['id']),
      name: json['name']?.toString() ?? '',
      subType: json['sub_type']?.toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? json['start_date']?.toString() ?? '') ?? DateTime.now(),
      location: json['location']?.toString(),
      isCompleted: _parseBool(json['is_completed']),
      goingCount: _parseInt(json['going_count']),
    );
  }
}

// Pre-defined linked event types for weddings
class WeddingLinkedEventDefaults {
  static const List<Map<String, String>> defaults = [
    {'sub_type': 'uchumba', 'name_sw': 'Uchumba', 'name_en': 'Engagement'},
    {'sub_type': 'kitchen_party', 'name_sw': 'Kitchen Party', 'name_en': 'Kitchen Party'},
    {'sub_type': 'send_off', 'name_sw': 'Send-off', 'name_en': 'Send-off Party'},
    {'sub_type': 'kupamba', 'name_sw': 'Kupamba', 'name_en': 'Bridal Preparation'},
    {'sub_type': 'kesha', 'name_sw': 'Kesha', 'name_en': 'Night Vigil'},
    {'sub_type': 'main', 'name_sw': 'Harusi', 'name_en': 'Main Wedding'},
  ];

  // For funerals
  static const List<Map<String, String>> funeralDefaults = [
    {'sub_type': 'mazishi', 'name_sw': 'Mazishi', 'name_en': 'Burial'},
    {'sub_type': 'siku_3', 'name_sw': 'Siku ya 3', 'name_en': '3-Day Memorial'},
    {'sub_type': 'siku_7', 'name_sw': 'Siku ya 7', 'name_en': '7-Day Memorial'},
    {'sub_type': 'siku_40', 'name_sw': 'Siku ya 40', 'name_en': '40-Day Memorial'},
    {'sub_type': 'mwaka_1', 'name_sw': 'Mwaka 1', 'name_en': '1-Year Anniversary'},
  ];
}
