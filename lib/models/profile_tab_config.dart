/// Configuration for profile tabs - order and visibility
class ProfileTabConfig {
  final String id;
  final String label;
  final String icon;
  final bool enabled;
  final int order;

  const ProfileTabConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.order,
  });

  ProfileTabConfig copyWith({
    String? id,
    String? label,
    String? icon,
    bool? enabled,
    int? order,
  }) {
    return ProfileTabConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'icon': icon,
      'enabled': enabled,
      'order': order,
    };
  }

  factory ProfileTabConfig.fromJson(Map<String, dynamic> json) {
    return ProfileTabConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String,
      enabled: json['enabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileTabConfig &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Default tab configurations
class ProfileTabDefaults {
  static const List<ProfileTabConfig> defaultTabs = [
    ProfileTabConfig(id: 'posts', label: 'Machapisho', icon: 'article', enabled: true, order: 0),
    ProfileTabConfig(id: 'photos', label: 'Picha', icon: 'photo_library', enabled: true, order: 1),
    ProfileTabConfig(id: 'videos', label: 'Video', icon: 'video_library', enabled: true, order: 2),
    ProfileTabConfig(id: 'music', label: 'Muziki', icon: 'music_note', enabled: true, order: 3),
    ProfileTabConfig(id: 'live', label: 'Live', icon: 'live_tv', enabled: true, order: 4),
    ProfileTabConfig(id: 'michango', label: 'Michango', icon: 'volunteer_activism', enabled: true, order: 5),
    ProfileTabConfig(id: 'groups', label: 'Vikundi', icon: 'group', enabled: true, order: 6),
    ProfileTabConfig(id: 'documents', label: 'Nyaraka', icon: 'folder', enabled: true, order: 7),
    ProfileTabConfig(id: 'shop', label: 'Duka', icon: 'storefront', enabled: true, order: 8),
    ProfileTabConfig(id: 'friends', label: 'Marafiki', icon: 'people', enabled: true, order: 9),
    ProfileTabConfig(id: 'about', label: 'Kuhusu', icon: 'info', enabled: true, order: 10),
  ];

  static List<ProfileTabConfig> getDefaults() {
    return List.from(defaultTabs);
  }
}
