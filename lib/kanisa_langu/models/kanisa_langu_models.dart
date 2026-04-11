// lib/kanisa_langu/models/kanisa_langu_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

// ─── Result wrappers ───────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Church Profile ───────────────────────────────────────────

class ChurchProfile {
  final int id;
  final String name;
  final String denomination;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? pastorName;
  final String? phone;
  final String? imageUrl;
  final String? description;
  final int memberCount;
  final List<String> serviceTimes;
  final bool isMember;

  ChurchProfile({
    required this.id,
    required this.name,
    required this.denomination,
    this.address,
    this.latitude,
    this.longitude,
    this.pastorName,
    this.phone,
    this.imageUrl,
    this.description,
    required this.memberCount,
    required this.serviceTimes,
    this.isMember = false,
  });

  factory ChurchProfile.fromJson(Map<String, dynamic> json) {
    return ChurchProfile(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      denomination: json['denomination']?.toString() ?? '',
      address: json['address']?.toString(),
      latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _parseDouble(json['longitude']) : null,
      pastorName: json['pastor_name']?.toString(),
      phone: json['phone']?.toString(),
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString(),
      memberCount: _parseInt(json['member_count']),
      serviceTimes: (json['service_times'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isMember: _parseBool(json['is_member']),
    );
  }
}

// ─── Announcement ─────────────────────────────────────────────

class ChurchAnnouncement {
  final int id;
  final String title;
  final String content;
  final String? authorName;
  final String createdAt;
  final bool isPinned;

  ChurchAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    this.authorName,
    required this.createdAt,
    this.isPinned = false,
  });

  factory ChurchAnnouncement.fromJson(Map<String, dynamic> json) {
    return ChurchAnnouncement(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorName: json['author_name']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      isPinned: _parseBool(json['is_pinned']),
    );
  }
}

// ─── Church Event ─────────────────────────────────────────────

class ChurchEvent {
  final int id;
  final String title;
  final String? description;
  final String date;
  final String? time;
  final String? location;
  final int rsvpCount;

  ChurchEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.location,
    required this.rsvpCount,
  });

  factory ChurchEvent.fromJson(Map<String, dynamic> json) {
    return ChurchEvent(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString(),
      location: json['location']?.toString(),
      rsvpCount: _parseInt(json['rsvp_count']),
    );
  }
}

// ─── Church Member ────────────────────────────────────────────

class ChurchMember {
  final int id;
  final String name;
  final String? role;
  final String? photoUrl;

  ChurchMember({
    required this.id,
    required this.name,
    this.role,
    this.photoUrl,
  });

  factory ChurchMember.fromJson(Map<String, dynamic> json) {
    return ChurchMember(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString(),
      photoUrl: json['photo_url']?.toString(),
    );
  }
}
