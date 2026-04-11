// lib/events/models/event.dart
import '../../config/api_config.dart';
import 'event_enums.dart';
import 'event_ticket.dart';
import 'event_session.dart';
import 'event_rsvp.dart';

// ── Parse Helpers ──
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

// ── Event ──
class Event {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final EventStatus status;
  final EventType type;
  final EventPrivacy privacy;
  final EventCategory category;
  final List<String> tags;

  // Date & Time
  final DateTime startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;
  final String timezone;
  final bool isAllDay;
  final bool isRecurring;

  // Location
  final String? locationName;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final int? regionId;
  final int? districtId;

  // Online
  final bool isOnline;
  final String? onlineLink;
  final String? onlinePlatform;

  // Media
  final String? coverPhotoUrl;
  final List<String> galleryUrls;
  final String? trailerVideoUrl;

  // Organizer
  final int creatorId;
  final EventCreator? creator;
  final List<EventCoHost> coHosts;
  final int? groupId;
  final EventGroup? group;

  // Ticketing
  final bool isFree;
  final double? ticketPrice;
  final String ticketCurrency;
  final List<TicketTier> ticketTiers;
  final int totalCapacity;
  final int soldCount;
  final bool hasWaitlist;
  final RefundPolicy refundPolicy;

  // Social Counts
  final int goingCount;
  final int interestedCount;
  final int notGoingCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;

  // User State
  final String? userResponse;
  final bool isHost;
  final bool isCoHost;
  final bool hasPurchasedTicket;
  final bool isSaved;

  // Agenda
  final List<EventSession> sessions;
  final List<EventSpeaker> speakers;
  final List<EventSponsor> sponsors;

  // Friends
  final List<EventAttendee> friendsGoing;
  final int friendsGoingCount;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  Event({
    required this.id,
    required this.name,
    this.slug = '',
    this.description,
    this.status = EventStatus.published,
    this.type = EventType.inPerson,
    this.privacy = EventPrivacy.public,
    this.category = EventCategory.other,
    this.tags = const [],
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.timezone = 'Africa/Dar_es_Salaam',
    this.isAllDay = false,
    this.isRecurring = false,
    this.locationName,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.regionId,
    this.districtId,
    this.isOnline = false,
    this.onlineLink,
    this.onlinePlatform,
    this.coverPhotoUrl,
    this.galleryUrls = const [],
    this.trailerVideoUrl,
    required this.creatorId,
    this.creator,
    this.coHosts = const [],
    this.groupId,
    this.group,
    this.isFree = true,
    this.ticketPrice,
    this.ticketCurrency = 'TZS',
    this.ticketTiers = const [],
    this.totalCapacity = 0,
    this.soldCount = 0,
    this.hasWaitlist = false,
    this.refundPolicy = RefundPolicy.noRefund,
    this.goingCount = 0,
    this.interestedCount = 0,
    this.notGoingCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.userResponse,
    this.isHost = false,
    this.isCoHost = false,
    this.hasPurchasedTicket = false,
    this.isSaved = false,
    this.sessions = const [],
    this.speakers = const [],
    this.sponsors = const [],
    this.friendsGoing = const [],
    this.friendsGoingCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  // ── Computed ──
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isPast => (endDate ?? startDate).isBefore(DateTime.now());
  bool get isHappeningNow =>
      startDate.isBefore(DateTime.now()) &&
      (endDate?.isAfter(DateTime.now()) ?? true);
  bool get isSoldOut => totalCapacity > 0 && soldCount >= totalCapacity;
  int get availableSpots =>
      totalCapacity > 0 ? totalCapacity - soldCount : -1;
  bool get isGoing => userResponse == 'going';
  bool get isInterested => userResponse == 'interested';
  bool get hasTicketTiers => ticketTiers.isNotEmpty;
  bool get isMultiDay =>
      endDate != null && endDate!.difference(startDate).inDays >= 1;
  bool get canRSVP => status == EventStatus.published && !isPast;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      status: _parseStatus(json['status']),
      type: EventType.fromApi(json['type']?.toString()),
      privacy: EventPrivacy.fromApi(json['privacy']?.toString()),
      category: EventCategory.fromApi(json['category']?.toString()),
      tags: _parseStringList(json['tags']),
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString()) : null,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      timezone: json['timezone']?.toString() ?? 'Africa/Dar_es_Salaam',
      isAllDay: _parseBool(json['is_all_day']),
      isRecurring: _parseBool(json['is_recurring']),
      locationName: json['location_name']?.toString() ?? json['location']?.toString(),
      locationAddress: json['location_address']?.toString() ?? json['address']?.toString(),
      latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _parseDouble(json['longitude']) : null,
      regionId: json['region_id'] != null ? _parseInt(json['region_id']) : null,
      districtId: json['district_id'] != null ? _parseInt(json['district_id']) : null,
      isOnline: _parseBool(json['is_online']),
      onlineLink: json['online_link']?.toString(),
      onlinePlatform: json['online_platform']?.toString(),
      coverPhotoUrl: ApiConfig.sanitizeUrl(json['cover_photo_url']?.toString()),
      galleryUrls: _parseStringList(json['gallery_urls']),
      trailerVideoUrl: ApiConfig.sanitizeUrl(json['trailer_video_url']?.toString()),
      creatorId: _parseInt(json['creator_id']),
      creator: json['creator'] != null ? EventCreator.fromJson(json['creator']) : null,
      coHosts: (json['co_hosts'] as List?)?.map((e) => EventCoHost.fromJson(e)).toList() ?? [],
      groupId: json['group_id'] != null ? _parseInt(json['group_id']) : null,
      group: json['group'] != null ? EventGroup.fromJson(json['group']) : null,
      isFree: _parseBool(json['is_free']),
      ticketPrice: json['ticket_price'] != null ? _parseDouble(json['ticket_price']) : null,
      ticketCurrency: json['ticket_currency']?.toString() ?? 'TZS',
      ticketTiers: (json['ticket_tiers'] as List?)?.map((e) => TicketTier.fromJson(e)).toList() ?? [],
      totalCapacity: _parseInt(json['total_capacity']),
      soldCount: _parseInt(json['sold_count']),
      hasWaitlist: _parseBool(json['has_waitlist']),
      refundPolicy: RefundPolicy.fromApi(json['refund_policy']?.toString()),
      goingCount: _parseInt(json['going_count']),
      interestedCount: _parseInt(json['interested_count']),
      notGoingCount: _parseInt(json['not_going_count']),
      commentsCount: _parseInt(json['comments_count']),
      sharesCount: _parseInt(json['shares_count']),
      viewsCount: _parseInt(json['views_count']),
      userResponse: json['user_response']?.toString(),
      isHost: _parseBool(json['is_host']),
      isCoHost: _parseBool(json['is_co_host']),
      hasPurchasedTicket: _parseBool(json['has_purchased_ticket']),
      isSaved: _parseBool(json['is_saved']),
      sessions: (json['sessions'] as List?)?.map((e) => EventSession.fromJson(e)).toList() ?? [],
      speakers: (json['speakers'] as List?)?.map((e) => EventSpeaker.fromJson(e)).toList() ?? [],
      sponsors: (json['sponsors'] as List?)?.map((e) => EventSponsor.fromJson(e)).toList() ?? [],
      friendsGoing: (json['friends_going'] as List?)?.map((e) => EventAttendee.fromJson(e)).toList() ?? [],
      friendsGoingCount: _parseInt(json['friends_going_count']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'status': status.name,
    'type': type.apiValue,
    'privacy': privacy.apiValue,
    'category': category.apiValue,
    'tags': tags,
    'start_date': startDate.toIso8601String().split('T').first,
    'end_date': endDate?.toIso8601String().split('T').first,
    'start_time': startTime,
    'end_time': endTime,
    'timezone': timezone,
    'is_all_day': isAllDay,
    'is_recurring': isRecurring,
    'location_name': locationName,
    'location_address': locationAddress,
    'latitude': latitude,
    'longitude': longitude,
    'is_online': isOnline,
    'online_link': onlineLink,
    'online_platform': onlinePlatform,
    'cover_photo_url': coverPhotoUrl,
    'gallery_urls': galleryUrls,
    'creator_id': creatorId,
    'group_id': groupId,
    'is_free': isFree,
    'ticket_price': ticketPrice,
    'ticket_currency': ticketCurrency,
    'total_capacity': totalCapacity,
    'has_waitlist': hasWaitlist,
    'refund_policy': refundPolicy.apiValue,
    'going_count': goingCount,
    'interested_count': interestedCount,
    'not_going_count': notGoingCount,
    'user_response': userResponse,
    'is_host': isHost,
    'is_saved': isSaved,
    'friends_going_count': friendsGoingCount,
    'created_at': createdAt.toIso8601String(),
  };

  Event copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    EventStatus? status,
    EventType? type,
    EventPrivacy? privacy,
    EventCategory? category,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? timezone,
    bool? isAllDay,
    bool? isRecurring,
    String? locationName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    int? regionId,
    int? districtId,
    bool? isOnline,
    String? onlineLink,
    String? onlinePlatform,
    String? coverPhotoUrl,
    List<String>? galleryUrls,
    String? trailerVideoUrl,
    int? creatorId,
    EventCreator? creator,
    List<EventCoHost>? coHosts,
    int? groupId,
    EventGroup? group,
    bool? isFree,
    double? ticketPrice,
    String? ticketCurrency,
    List<TicketTier>? ticketTiers,
    int? totalCapacity,
    int? soldCount,
    bool? hasWaitlist,
    RefundPolicy? refundPolicy,
    int? goingCount,
    int? interestedCount,
    int? notGoingCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    String? userResponse,
    bool? isHost,
    bool? isCoHost,
    bool? hasPurchasedTicket,
    bool? isSaved,
    List<EventSession>? sessions,
    List<EventSpeaker>? speakers,
    List<EventSponsor>? sponsors,
    List<EventAttendee>? friendsGoing,
    int? friendsGoingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      privacy: privacy ?? this.privacy,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      regionId: regionId ?? this.regionId,
      districtId: districtId ?? this.districtId,
      isOnline: isOnline ?? this.isOnline,
      onlineLink: onlineLink ?? this.onlineLink,
      onlinePlatform: onlinePlatform ?? this.onlinePlatform,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      trailerVideoUrl: trailerVideoUrl ?? this.trailerVideoUrl,
      creatorId: creatorId ?? this.creatorId,
      creator: creator ?? this.creator,
      coHosts: coHosts ?? this.coHosts,
      groupId: groupId ?? this.groupId,
      group: group ?? this.group,
      isFree: isFree ?? this.isFree,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      ticketCurrency: ticketCurrency ?? this.ticketCurrency,
      ticketTiers: ticketTiers ?? this.ticketTiers,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      soldCount: soldCount ?? this.soldCount,
      hasWaitlist: hasWaitlist ?? this.hasWaitlist,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      goingCount: goingCount ?? this.goingCount,
      interestedCount: interestedCount ?? this.interestedCount,
      notGoingCount: notGoingCount ?? this.notGoingCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      userResponse: userResponse ?? this.userResponse,
      isHost: isHost ?? this.isHost,
      isCoHost: isCoHost ?? this.isCoHost,
      hasPurchasedTicket: hasPurchasedTicket ?? this.hasPurchasedTicket,
      isSaved: isSaved ?? this.isSaved,
      sessions: sessions ?? this.sessions,
      speakers: speakers ?? this.speakers,
      sponsors: sponsors ?? this.sponsors,
      friendsGoing: friendsGoing ?? this.friendsGoing,
      friendsGoingCount: friendsGoingCount ?? this.friendsGoingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

// ── EventCreator ──
class EventCreator {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoUrl;

  EventCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoUrl,
  });

  String get fullName => '$firstName $lastName';

  String? get avatarUrl => profilePhotoUrl != null
      ? ApiConfig.sanitizeUrl(profilePhotoUrl)
      : null;

  factory EventCreator.fromJson(Map<String, dynamic> json) {
    return EventCreator(
      id: _parseInt(json['id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      username: json['username']?.toString(),
      profilePhotoUrl: ApiConfig.sanitizeUrl(json['profile_photo_url']?.toString()),
    );
  }
}

// ── EventCoHost ──
class EventCoHost {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoUrl;

  EventCoHost({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoUrl,
  });

  String get fullName => '$firstName $lastName';

  factory EventCoHost.fromJson(Map<String, dynamic> json) {
    return EventCoHost(
      id: _parseInt(json['id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      username: json['username']?.toString(),
      profilePhotoUrl: ApiConfig.sanitizeUrl(json['profile_photo_url']?.toString()),
    );
  }
}

// ── EventGroup ──
class EventGroup {
  final int id;
  final String name;
  final String slug;
  final String? coverPhotoUrl;

  EventGroup({
    required this.id,
    required this.name,
    this.slug = '',
    this.coverPhotoUrl,
  });

  factory EventGroup.fromJson(Map<String, dynamic> json) {
    return EventGroup(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      coverPhotoUrl: ApiConfig.sanitizeUrl(json['cover_photo_url']?.toString() ?? json['cover_photo_path']?.toString()),
    );
  }
}

// ── PaginatedResult ──
class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.perPage = 20,
  });

  bool get hasMore => currentPage < lastPage;
}

// ── SingleResult ──
class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;

  SingleResult({required this.success, this.data, this.message});
}

// ── Private helpers ──
EventStatus _parseStatus(dynamic v) {
  final s = v?.toString().toLowerCase() ?? '';
  for (final status in EventStatus.values) {
    if (status.name == s) return status;
  }
  return EventStatus.published;
}

List<String> _parseStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}
