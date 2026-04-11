// lib/events/models/events_models.dart

// ─── Event Category ────────────────────────────────────────────

enum EventCategory {
  music,
  sports,
  business,
  education,
  social,
  religious,
  cultural,
  food,
  tech,
  other;

  String get displayName {
    switch (this) {
      case EventCategory.music:
        return 'Muziki';
      case EventCategory.sports:
        return 'Michezo';
      case EventCategory.business:
        return 'Biashara';
      case EventCategory.education:
        return 'Elimu';
      case EventCategory.social:
        return 'Jamii';
      case EventCategory.religious:
        return 'Dini';
      case EventCategory.cultural:
        return 'Utamaduni';
      case EventCategory.food:
        return 'Chakula';
      case EventCategory.tech:
        return 'Teknolojia';
      case EventCategory.other:
        return 'Nyingine';
    }
  }

  String get subtitle {
    switch (this) {
      case EventCategory.music:
        return 'Music';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.business:
        return 'Business';
      case EventCategory.education:
        return 'Education';
      case EventCategory.social:
        return 'Social';
      case EventCategory.religious:
        return 'Religious';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.food:
        return 'Food & Drink';
      case EventCategory.tech:
        return 'Technology';
      case EventCategory.other:
        return 'Other';
    }
  }
}

// ─── Event ─────────────────────────────────────────────────────

class Event {
  final int id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? address;
  final String? imageUrl;
  final String organizerName;
  final int organizerId;
  final double ticketPrice;
  final bool isFree;
  final int totalTickets;
  final int soldTickets;
  final String status;
  final double? latitude;
  final double? longitude;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.address,
    this.imageUrl,
    required this.organizerName,
    required this.organizerId,
    this.ticketPrice = 0,
    this.isFree = true,
    this.totalTickets = 0,
    this.soldTickets = 0,
    this.status = 'upcoming',
    this.latitude,
    this.longitude,
  });

  int get availableTickets => totalTickets - soldTickets;
  bool get isSoldOut => totalTickets > 0 && soldTickets >= totalTickets;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: _parseCategory(json['category']),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      location: json['location']?.toString(),
      address: json['address']?.toString(),
      imageUrl: json['image_url']?.toString(),
      organizerName: json['organizer_name']?.toString() ?? '',
      organizerId: _parseInt(json['organizer_id']),
      ticketPrice: _parseDouble(json['ticket_price']),
      isFree: _parseBool(json['is_free']),
      totalTickets: _parseInt(json['total_tickets']),
      soldTickets: _parseInt(json['sold_tickets']),
      status: json['status']?.toString() ?? 'upcoming',
      latitude:
          json['latitude'] != null ? _parseDouble(json['latitude']) : null,
      longitude:
          json['longitude'] != null ? _parseDouble(json['longitude']) : null,
    );
  }
}

// ─── Event Ticket ──────────────────────────────────────────────

class EventTicket {
  final int id;
  final int eventId;
  final int userId;
  final String ticketNumber;
  final String? qrCode;
  final DateTime purchaseDate;
  final String status;
  final Event? event;

  EventTicket({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.ticketNumber,
    this.qrCode,
    required this.purchaseDate,
    this.status = 'active',
    this.event,
  });

  factory EventTicket.fromJson(Map<String, dynamic> json) {
    return EventTicket(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: _parseInt(json['user_id']),
      ticketNumber: json['ticket_number']?.toString() ?? '',
      qrCode: json['qr_code']?.toString(),
      purchaseDate:
          DateTime.tryParse(json['purchase_date']?.toString() ?? '') ??
              DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
    );
  }
}

// ─── Result wrappers ───────────────────────────────────────────

class EventResult<T> {
  final bool success;
  final T? data;
  final String? message;

  EventResult({required this.success, this.data, this.message});
}

class EventListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  EventListResult({
    required this.success,
    this.items = const [],
    this.message,
  });
}

// ─── Parse helpers ─────────────────────────────────────────────

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

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

EventCategory _parseCategory(dynamic v) {
  final s = v?.toString().toLowerCase() ?? '';
  for (final c in EventCategory.values) {
    if (c.name == s) return c;
  }
  return EventCategory.other;
}
