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

/// Category grouping for profile tabs display
class ProfileTabCategory {
  final String id;
  final String label;
  final List<String> tabIds;

  const ProfileTabCategory({
    required this.id,
    required this.label,
    required this.tabIds,
  });
}

/// Default tab configurations
class ProfileTabDefaults {
  static const List<ProfileTabConfig> defaultTabs = [
    // ── Social & Media ──────────────────────────────────────────────
    ProfileTabConfig(id: 'posts', label: 'Machapisho', icon: 'article', enabled: true, order: 0),
    ProfileTabConfig(id: 'photos', label: 'Picha', icon: 'photo_library', enabled: true, order: 1),
    ProfileTabConfig(id: 'videos', label: 'Video', icon: 'video_library', enabled: true, order: 2),
    ProfileTabConfig(id: 'music', label: 'Muziki', icon: 'music_note', enabled: true, order: 3),
    ProfileTabConfig(id: 'live', label: 'Live', icon: 'live_tv', enabled: true, order: 4),
    ProfileTabConfig(id: 'groups', label: 'Vikundi', icon: 'group', enabled: true, order: 5),
    ProfileTabConfig(id: 'friends', label: 'Marafiki', icon: 'people', enabled: true, order: 6),
    ProfileTabConfig(id: 'about', label: 'Kuhusu', icon: 'info', enabled: true, order: 7),

    // ── Commerce ────────────────────────────────────────────────────
    ProfileTabConfig(id: 'shop', label: 'Duka', icon: 'storefront', enabled: true, order: 8),
    ProfileTabConfig(id: 'michango', label: 'Michango', icon: 'volunteer_activism', enabled: true, order: 9),
    ProfileTabConfig(id: 'documents', label: 'Nyaraka', icon: 'folder', enabled: true, order: 10),

    // ── Finance & Money ─────────────────────────────────────────────
    ProfileTabConfig(id: 'budget', label: 'Bajeti', icon: 'account_balance_wallet', enabled: true, order: 11),
    ProfileTabConfig(id: 'kikoba', label: 'Kikoba', icon: 'savings', enabled: true, order: 12),
    ProfileTabConfig(id: 'banking', label: 'Benki', icon: 'account_balance', enabled: true, order: 13),
    ProfileTabConfig(id: 'investments', label: 'Uwekezaji', icon: 'trending_up', enabled: true, order: 14),
    ProfileTabConfig(id: 'loans', label: 'Mikopo', icon: 'request_quote', enabled: true, order: 15),

    // ── Health & Wellness ───────────────────────────────────────────
    ProfileTabConfig(id: 'doctor', label: 'Daktari', icon: 'medical_services', enabled: true, order: 16),
    ProfileTabConfig(id: 'pharmacy', label: 'Dawa', icon: 'local_pharmacy', enabled: true, order: 17),
    ProfileTabConfig(id: 'insurance', label: 'Bima', icon: 'health_and_safety', enabled: true, order: 18),
    ProfileTabConfig(id: 'fitness', label: 'Afya', icon: 'fitness_center', enabled: true, order: 19),

    // ── Family & Education ──────────────────────────────────────────
    ProfileTabConfig(id: 'family', label: 'Familia', icon: 'family_restroom', enabled: true, order: 20),
    ProfileTabConfig(id: 'school', label: 'Shule', icon: 'school', enabled: true, order: 21),
    ProfileTabConfig(id: 'childcare', label: 'Malezi', icon: 'child_care', enabled: true, order: 22),
    ProfileTabConfig(id: 'learning', label: 'Masomo', icon: 'menu_book', enabled: true, order: 23),

    // ── Work & Career ───────────────────────────────────────────────
    ProfileTabConfig(id: 'jobs', label: 'Kazi', icon: 'work', enabled: true, order: 24),
    ProfileTabConfig(id: 'business', label: 'Biashara', icon: 'business_center', enabled: true, order: 25),

    // ── Daily Life & Home ───────────────────────────────────────────
    ProfileTabConfig(id: 'food', label: 'Chakula', icon: 'restaurant', enabled: true, order: 26),
    ProfileTabConfig(id: 'transport', label: 'Usafiri', icon: 'directions_car', enabled: true, order: 27),
    ProfileTabConfig(id: 'services', label: 'Fundi', icon: 'home_repair_service', enabled: true, order: 28),
    ProfileTabConfig(id: 'housing', label: 'Nyumba', icon: 'home', enabled: true, order: 29),
    ProfileTabConfig(id: 'bills', label: 'Bili', icon: 'receipt_long', enabled: true, order: 30),
    ProfileTabConfig(id: 'vehicle', label: 'Gari', icon: 'two_wheeler', enabled: true, order: 31),

    // ── Planning & Productivity ─────────────────────────────────────
    ProfileTabConfig(id: 'calendar', label: 'Kalenda', icon: 'calendar_month', enabled: true, order: 32),
    ProfileTabConfig(id: 'notes', label: 'Kumbukumbu', icon: 'edit_note', enabled: true, order: 33),

    // ── Government & Legal ──────────────────────────────────────────
    ProfileTabConfig(id: 'government', label: 'Serikali', icon: 'assured_workload', enabled: true, order: 34),
    ProfileTabConfig(id: 'lawyer', label: 'Wakili', icon: 'gavel', enabled: true, order: 35),

    // ── Community & Lifestyle ───────────────────────────────────────
    ProfileTabConfig(id: 'faith', label: 'Imani', icon: 'mosque', enabled: true, order: 36),
    ProfileTabConfig(id: 'community', label: 'Jamii', icon: 'diversity_3', enabled: true, order: 37),
    ProfileTabConfig(id: 'events', label: 'Matukio', icon: 'event', enabled: true, order: 38),
    ProfileTabConfig(id: 'travel', label: 'Safari', icon: 'flight', enabled: true, order: 39),
    ProfileTabConfig(id: 'news', label: 'Habari', icon: 'newspaper', enabled: true, order: 40),
    ProfileTabConfig(id: 'games', label: 'Michezo', icon: 'sports_esports', enabled: true, order: 41),
  ];

  /// Ordered category definitions for the profile tab grid.
  /// First category (social) shows without a divider header.
  static const List<ProfileTabCategory> categories = [
    ProfileTabCategory(
      id: 'social',
      label: '', // No header for social — it's the top section
      tabIds: ['posts', 'photos', 'videos', 'music', 'live', 'groups', 'friends', 'about'],
    ),
    ProfileTabCategory(
      id: 'commerce',
      label: 'BIASHARA', // Commerce
      tabIds: ['shop', 'michango', 'documents'],
    ),
    ProfileTabCategory(
      id: 'finance',
      label: 'FEDHA', // Finance
      tabIds: ['budget', 'kikoba', 'banking', 'investments', 'loans'],
    ),
    ProfileTabCategory(
      id: 'health',
      label: 'AFYA', // Health
      tabIds: ['doctor', 'pharmacy', 'insurance', 'fitness'],
    ),
    ProfileTabCategory(
      id: 'family',
      label: 'FAMILIA & ELIMU', // Family & Education
      tabIds: ['family', 'school', 'childcare', 'learning'],
    ),
    ProfileTabCategory(
      id: 'work',
      label: 'KAZI', // Work
      tabIds: ['jobs', 'business'],
    ),
    ProfileTabCategory(
      id: 'daily',
      label: 'MAISHA YA KILA SIKU', // Daily Life
      tabIds: ['food', 'transport', 'services', 'housing', 'bills', 'vehicle'],
    ),
    ProfileTabCategory(
      id: 'planning',
      label: 'MPANGO', // Planning
      tabIds: ['calendar', 'notes'],
    ),
    ProfileTabCategory(
      id: 'official',
      label: 'SERIKALI & SHERIA', // Government & Legal
      tabIds: ['government', 'lawyer'],
    ),
    ProfileTabCategory(
      id: 'lifestyle',
      label: 'JAMII & BURUDANI', // Community & Lifestyle
      tabIds: ['faith', 'community', 'events', 'travel', 'news', 'games'],
    ),
  ];

  static List<ProfileTabConfig> getDefaults() {
    return List.from(defaultTabs);
  }
}
