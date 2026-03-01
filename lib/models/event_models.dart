import '../config/api_config.dart';

class EventModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? coverPhotoPath;
  final String? coverPhotoUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;
  final String timezone;
  final bool isAllDay;
  final String? locationName;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final String? onlineLink;
  final String privacy;
  final String? category;
  final int creatorId;
  final int? groupId;
  final int? pageId;
  final int goingCount;
  final int interestedCount;
  final int notGoingCount;
  final double? ticketPrice;
  final String ticketCurrency;
  final String? ticketLink;
  final bool isRecurring;
  final DateTime createdAt;
  final EventCreator? creator;
  final EventGroup? group;
  final EventPage? page;
  final String? userResponse; // going, interested, not_going
  final bool? isHost;

  EventModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverPhotoPath,
    this.coverPhotoUrl,
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.timezone = 'Africa/Dar_es_Salaam',
    this.isAllDay = false,
    this.locationName,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.isOnline = false,
    this.onlineLink,
    this.privacy = 'public',
    this.category,
    required this.creatorId,
    this.groupId,
    this.pageId,
    this.goingCount = 0,
    this.interestedCount = 0,
    this.notGoingCount = 0,
    this.ticketPrice,
    this.ticketCurrency = 'TZS',
    this.ticketLink,
    this.isRecurring = false,
    required this.createdAt,
    this.creator,
    this.group,
    this.page,
    this.userResponse,
    this.isHost,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      coverPhotoPath: json['cover_photo_path'],
      coverPhotoUrl: ApiConfig.sanitizeUrl(json['cover_photo_url']),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      startTime: json['start_time'],
      endTime: json['end_time'],
      timezone: json['timezone'] ?? 'Africa/Dar_es_Salaam',
      isAllDay: json['is_all_day'] ?? false,
      locationName: json['location_name'],
      locationAddress: json['location_address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isOnline: json['is_online'] ?? false,
      onlineLink: json['online_link'],
      privacy: json['privacy'] ?? 'public',
      category: json['category'],
      creatorId: json['creator_id'] ?? 0,
      groupId: json['group_id'],
      pageId: json['page_id'],
      goingCount: json['going_count'] ?? 0,
      interestedCount: json['interested_count'] ?? 0,
      notGoingCount: json['not_going_count'] ?? 0,
      ticketPrice: json['ticket_price']?.toDouble(),
      ticketCurrency: json['ticket_currency'] ?? 'TZS',
      ticketLink: json['ticket_link'],
      isRecurring: json['is_recurring'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      creator: json['creator'] != null
          ? EventCreator.fromJson(json['creator'])
          : null,
      group: json['group'] != null ? EventGroup.fromJson(json['group']) : null,
      page: json['page'] != null ? EventPage.fromJson(json['page']) : null,
      userResponse: json['user_response'],
      isHost: json['is_host'],
    );
  }

  EventModel copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? coverPhotoPath,
    String? coverPhotoUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? timezone,
    bool? isAllDay,
    String? locationName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    bool? isOnline,
    String? onlineLink,
    String? privacy,
    String? category,
    int? creatorId,
    int? groupId,
    int? pageId,
    int? goingCount,
    int? interestedCount,
    int? notGoingCount,
    double? ticketPrice,
    String? ticketCurrency,
    String? ticketLink,
    bool? isRecurring,
    DateTime? createdAt,
    EventCreator? creator,
    EventGroup? group,
    EventPage? page,
    String? userResponse,
    bool? isHost,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
      isAllDay: isAllDay ?? this.isAllDay,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOnline: isOnline ?? this.isOnline,
      onlineLink: onlineLink ?? this.onlineLink,
      privacy: privacy ?? this.privacy,
      category: category ?? this.category,
      creatorId: creatorId ?? this.creatorId,
      groupId: groupId ?? this.groupId,
      pageId: pageId ?? this.pageId,
      goingCount: goingCount ?? this.goingCount,
      interestedCount: interestedCount ?? this.interestedCount,
      notGoingCount: notGoingCount ?? this.notGoingCount,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      ticketCurrency: ticketCurrency ?? this.ticketCurrency,
      ticketLink: ticketLink ?? this.ticketLink,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      creator: creator ?? this.creator,
      group: group ?? this.group,
      page: page ?? this.page,
      userResponse: userResponse ?? this.userResponse,
      isHost: isHost ?? this.isHost,
    );
  }

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isPast => startDate.isBefore(DateTime.now());
  bool get hasTickets => ticketPrice != null && ticketPrice! > 0;
  bool get isFree => ticketPrice == null || ticketPrice == 0;
  bool get isGoing => userResponse == 'going';
  bool get isInterested => userResponse == 'interested';
}

class EventCreator {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;
  final String? profilePhotoUrl;

  EventCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
    this.profilePhotoUrl,
  });

  factory EventCreator.fromJson(Map<String, dynamic> json) {
    return EventCreator(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
      profilePhotoUrl: ApiConfig.sanitizeUrl(json['profile_photo_url']),
    );
  }

  String get fullName => '$firstName $lastName';

  /// Avatar URL for display (prefer profile_photo_url from API, else path)
  String? get avatarUrl =>
      profilePhotoUrl ??
      (profilePhotoPath != null && profilePhotoPath!.isNotEmpty
          ? '${ApiConfig.storageUrl}/${profilePhotoPath!.replaceFirst(RegExp(r'^/'), '')}'
          : null);
}

class EventGroup {
  final int id;
  final String name;
  final String slug;
  final String? coverPhotoPath;

  EventGroup({
    required this.id,
    required this.name,
    required this.slug,
    this.coverPhotoPath,
  });

  factory EventGroup.fromJson(Map<String, dynamic> json) {
    return EventGroup(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      coverPhotoPath: json['cover_photo_path'],
    );
  }
}

class EventPage {
  final int id;
  final String name;
  final String slug;
  final String? profilePhotoPath;

  EventPage({
    required this.id,
    required this.name,
    required this.slug,
    this.profilePhotoPath,
  });

  factory EventPage.fromJson(Map<String, dynamic> json) {
    return EventPage(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      profilePhotoPath: json['profile_photo_path'],
    );
  }
}

class EventCategory {
  final String value;
  final String label;

  EventCategory({required this.value, required this.label});

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      value: json['value'],
      label: json['label'],
    );
  }
}
