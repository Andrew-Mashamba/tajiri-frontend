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
    ProfileTabConfig(id: 'posts', label: 'Posts', icon: 'article', enabled: true, order: 0),
    ProfileTabConfig(id: 'photos', label: 'Photos', icon: 'photo_library', enabled: true, order: 1),
    ProfileTabConfig(id: 'videos', label: 'Videos', icon: 'video_library', enabled: true, order: 2),
    ProfileTabConfig(id: 'music', label: 'Music', icon: 'music_note', enabled: true, order: 3),
    ProfileTabConfig(id: 'live', label: 'Live', icon: 'live_tv', enabled: true, order: 4),
    ProfileTabConfig(id: 'groups', label: 'Groups', icon: 'group', enabled: true, order: 5),
    ProfileTabConfig(id: 'friends', label: 'Friends', icon: 'people', enabled: true, order: 6),
    ProfileTabConfig(id: 'about', label: 'About', icon: 'info', enabled: true, order: 7),

    // ── Commerce ────────────────────────────────────────────────────
    ProfileTabConfig(id: 'shop', label: 'Shop', icon: 'storefront', enabled: true, order: 8),
    ProfileTabConfig(id: 'michango', label: 'Fundraise', icon: 'volunteer_activism', enabled: true, order: 9),
    ProfileTabConfig(id: 'documents', label: 'Files', icon: 'folder', enabled: true, order: 10),
    ProfileTabConfig(id: 'tajirika', label: 'Tajirika', icon: 'handshake', enabled: true, order: 11),

    // ── Finance & Money ─────────────────────────────────────────────
    ProfileTabConfig(id: 'budget', label: 'Budget', icon: 'account_balance_wallet', enabled: true, order: 11),
    ProfileTabConfig(id: 'kikoba', label: 'Kikoba', icon: 'savings', enabled: true, order: 12),
    ProfileTabConfig(id: 'investments', label: 'Invest', icon: 'trending_up', enabled: true, order: 14),
    ProfileTabConfig(id: 'loans', label: 'Loans', icon: 'request_quote', enabled: true, order: 15),

    // ── Health & Wellness ───────────────────────────────────────────
    ProfileTabConfig(id: 'doctor', label: 'Doctor', icon: 'medical_services', enabled: true, order: 16),
    ProfileTabConfig(id: 'pharmacy', label: 'Pharmacy', icon: 'local_pharmacy', enabled: true, order: 17),
    ProfileTabConfig(id: 'insurance', label: 'Insurance', icon: 'health_and_safety', enabled: true, order: 18),
    ProfileTabConfig(id: 'fitness', label: 'Fitness', icon: 'fitness_center', enabled: true, order: 19),
    ProfileTabConfig(id: 'ambulance', label: 'Ambulance', icon: 'emergency', enabled: true, order: 20),

    // ── Women & Family Care ────────────────────────────────────────
    ProfileTabConfig(id: 'my_circle', label: 'Circle', icon: 'spa', enabled: true, order: 20),
    ProfileTabConfig(id: 'my_pregnancy', label: 'Pregnancy', icon: 'pregnant_woman', enabled: true, order: 21),
    ProfileTabConfig(id: 'my_baby', label: 'Baby', icon: 'child_care', enabled: true, order: 22),
    ProfileTabConfig(id: 'family', label: 'Family', icon: 'family_restroom', enabled: true, order: 22),
    ProfileTabConfig(id: 'skincare', label: 'Skin Care', icon: 'face', enabled: true, order: 23),
    ProfileTabConfig(id: 'hair_nails', label: 'Hair & Nails', icon: 'content_cut', enabled: true, order: 24),

    // ── Business ────────────────────────────────────────────────────
    // Core
    ProfileTabConfig(id: 'biz_profile', label: 'My Businesses', icon: 'business_center', enabled: true, order: 25),
    ProfileTabConfig(id: 'biz_docs', label: 'Documents', icon: 'folder', enabled: true, order: 26),
    ProfileTabConfig(id: 'biz_email', label: 'Email', icon: 'email', enabled: true, order: 28),
    ProfileTabConfig(id: 'biz_card', label: 'QR Card', icon: 'qr_code_2', enabled: true, order: 29),
    // Sales & Revenue
    ProfileTabConfig(id: 'biz_quotes', label: 'Quotes', icon: 'request_quote', enabled: true, order: 30),
    ProfileTabConfig(id: 'biz_invoices', label: 'Invoices', icon: 'receipt_long', enabled: true, order: 31),
    ProfileTabConfig(id: 'biz_recurring', label: 'Recurring', icon: 'repeat', enabled: true, order: 32),
    ProfileTabConfig(id: 'biz_vfd', label: 'TRA VFD', icon: 'verified', enabled: true, order: 33),
    // Customers & Debts
    ProfileTabConfig(id: 'biz_customers', label: 'Customers', icon: 'people', enabled: true, order: 34),
    ProfileTabConfig(id: 'biz_debts', label: 'Debts', icon: 'account_balance_wallet', enabled: true, order: 35),
    ProfileTabConfig(id: 'biz_reminders', label: 'Reminders', icon: 'notifications_active', enabled: true, order: 36),
    // Expenses & Finance
    ProfileTabConfig(id: 'biz_expenses', label: 'Expenses', icon: 'money_off', enabled: true, order: 37),
    ProfileTabConfig(id: 'biz_tax', label: 'Tax', icon: 'calculate', enabled: true, order: 38),
    ProfileTabConfig(id: 'biz_credit', label: 'CRB', icon: 'credit_score', enabled: true, order: 39),
    // Employees
    ProfileTabConfig(id: 'biz_employees', label: 'Team', icon: 'badge', enabled: true, order: 40),
    ProfileTabConfig(id: 'biz_payroll', label: 'Payroll', icon: 'payments', enabled: true, order: 41),
    // Procurement
    ProfileTabConfig(id: 'biz_suppliers', label: 'Suppliers', icon: 'local_shipping', enabled: true, order: 42),
    ProfileTabConfig(id: 'biz_po', label: 'Orders', icon: 'shopping_cart', enabled: true, order: 43),
    ProfileTabConfig(id: 'biz_tenders', label: 'Tenders', icon: 'gavel', enabled: true, order: 44),
    // Operations
    ProfileTabConfig(id: 'biz_appointments', label: 'Booking', icon: 'event', enabled: true, order: 45),

    // ── Daily Life & Home ───────────────────────────────────────────
    ProfileTabConfig(id: 'food', label: 'Food', icon: 'restaurant', enabled: true, order: 46),
    ProfileTabConfig(id: 'transport', label: 'Transport', icon: 'directions_car', enabled: true, order: 47),
    ProfileTabConfig(id: 'services', label: 'Mafundi', icon: 'home_repair_service', enabled: true, order: 48),
    ProfileTabConfig(id: 'housing', label: 'Housing', icon: 'home', enabled: true, order: 49),
    ProfileTabConfig(id: 'bills', label: 'Bills', icon: 'receipt_long', enabled: true, order: 50),
    // ── My Cars ─────────────────────────────────────────────────────
    ProfileTabConfig(id: 'my_cars', label: 'My Cars', icon: 'directions_car_filled', enabled: true, order: 50),
    ProfileTabConfig(id: 'car_insurance', label: 'Car Insurance', icon: 'verified_user', enabled: true, order: 51),
    ProfileTabConfig(id: 'buy_car', label: 'Buy a Car', icon: 'time_to_leave', enabled: true, order: 52),
    ProfileTabConfig(id: 'fuel_delivery', label: 'Fuel Delivery', icon: 'local_gas_station', enabled: true, order: 53),
    ProfileTabConfig(id: 'service_garage', label: 'Service & Garage', icon: 'car_repair', enabled: true, order: 54),
    ProfileTabConfig(id: 'sell_car', label: 'Sell Your Car', icon: 'storefront', enabled: true, order: 55),
    ProfileTabConfig(id: 'rent_car', label: 'Rent a Car', icon: 'car_rental', enabled: true, order: 56),
    ProfileTabConfig(id: 'owners_club', label: 'Owners Club', icon: 'groups', enabled: true, order: 57),
    ProfileTabConfig(id: 'spare_parts', label: 'Spare Parts', icon: 'handyman', enabled: true, order: 58),

    // ── Planning & Productivity ─────────────────────────────────────
    ProfileTabConfig(id: 'calendar', label: 'Calendar', icon: 'calendar_month', enabled: true, order: 64),
    ProfileTabConfig(id: 'notes', label: 'Notes', icon: 'edit_note', enabled: true, order: 65),

    // ── Government & Legal ──────────────────────────────────────────
    ProfileTabConfig(id: 'government', label: 'Govt', icon: 'assured_workload', enabled: true, order: 66),
    ProfileTabConfig(id: 'lawyer', label: 'Lawyer', icon: 'gavel', enabled: true, order: 67),
    // Leadership
    ProfileTabConfig(id: 'barozi_wangu', label: 'Barozi Wangu', icon: 'person_pin', enabled: true, order: 68),
    ProfileTabConfig(id: 'ofisi_mtaa', label: 'Ofisi za Mtaa', icon: 'location_city', enabled: true, order: 69),
    ProfileTabConfig(id: 'dc', label: 'Mkuu wa Wilaya', icon: 'account_balance', enabled: true, order: 70),
    ProfileTabConfig(id: 'rc', label: 'Mkuu wa Mkoa', icon: 'domain', enabled: true, order: 71),
    ProfileTabConfig(id: 'katiba', label: 'Katiba', icon: 'description', enabled: true, order: 72),
    ProfileTabConfig(id: 'legal_gpt', label: 'LegalGPT', icon: 'psychology', enabled: true, order: 73),
    // Government services
    ProfileTabConfig(id: 'nida', label: 'NIDA', icon: 'badge', enabled: true, order: 74),
    ProfileTabConfig(id: 'rita', label: 'RITA', icon: 'family_restroom', enabled: true, order: 75),
    ProfileTabConfig(id: 'tra', label: 'TRA', icon: 'calculate', enabled: true, order: 75),
    ProfileTabConfig(id: 'brela', label: 'BRELA', icon: 'business', enabled: true, order: 76),
    ProfileTabConfig(id: 'passport', label: 'Passport', icon: 'card_travel', enabled: true, order: 77),
    ProfileTabConfig(id: 'driving_licence', label: 'Leseni', icon: 'credit_card', enabled: true, order: 78),
    ProfileTabConfig(id: 'land_office', label: 'Ardhi', icon: 'landscape', enabled: true, order: 79),
    ProfileTabConfig(id: 'nhif', label: 'NHIF', icon: 'health_and_safety', enabled: true, order: 80),
    ProfileTabConfig(id: 'nssf', label: 'NSSF', icon: 'security', enabled: true, order: 81),
    ProfileTabConfig(id: 'latra', label: 'LATRA', icon: 'directions_bus', enabled: true, order: 82),
    ProfileTabConfig(id: 'tira', label: 'TIRA', icon: 'policy', enabled: true, order: 83),
    ProfileTabConfig(id: 'ewura', label: 'EWURA', icon: 'gas_meter', enabled: true, order: 84),
    ProfileTabConfig(id: 'heslb', label: 'HESLB', icon: 'school', enabled: true, order: 85),
    ProfileTabConfig(id: 'necta', label: 'NECTA', icon: 'grading', enabled: true, order: 86),
    ProfileTabConfig(id: 'tanesco', label: 'TANESCO', icon: 'bolt', enabled: true, order: 87),
    ProfileTabConfig(id: 'dawasco', label: 'DAWASCO', icon: 'water_drop', enabled: true, order: 88),

    // ── Community & Lifestyle ───────────────────────────────────────
    // ── Faith ──────────────────────────────────────────────────────
    ProfileTabConfig(id: 'my_faith', label: 'My Faith', icon: 'favorite', enabled: true, order: 70),
    // Christian
    ProfileTabConfig(id: 'biblia', label: 'Bible', icon: 'menu_book', enabled: true, order: 71),
    ProfileTabConfig(id: 'sala', label: 'Prayer', icon: 'back_hand', enabled: true, order: 72),
    ProfileTabConfig(id: 'fungu_la_kumi', label: 'Tithe', icon: 'volunteer_activism', enabled: true, order: 73),
    ProfileTabConfig(id: 'kanisa_langu', label: 'My Church', icon: 'church', enabled: true, order: 74),
    ProfileTabConfig(id: 'huduma', label: 'Sermons', icon: 'record_voice_over', enabled: true, order: 75),
    ProfileTabConfig(id: 'jumuiya', label: 'Jumuiya', icon: 'diversity_3', enabled: true, order: 76),
    ProfileTabConfig(id: 'ibada', label: 'Worship', icon: 'music_note', enabled: true, order: 77),
    ProfileTabConfig(id: 'shule_ya_jumapili', label: 'Sunday School', icon: 'school', enabled: true, order: 78),
    ProfileTabConfig(id: 'tafuta_kanisa', label: 'Church Finder', icon: 'location_on', enabled: true, order: 79),
    // Islamic
    ProfileTabConfig(id: 'wakati_wa_sala', label: 'Prayer Times', icon: 'schedule', enabled: true, order: 80),
    ProfileTabConfig(id: 'qibla', label: 'Qibla', icon: 'explore', enabled: true, order: 81),
    ProfileTabConfig(id: 'quran', label: 'Quran', icon: 'auto_stories', enabled: true, order: 82),
    ProfileTabConfig(id: 'kalenda_hijri', label: 'Hijri Calendar', icon: 'calendar_month', enabled: true, order: 83),
    ProfileTabConfig(id: 'ramadan', label: 'Ramadan', icon: 'dark_mode', enabled: true, order: 84),
    ProfileTabConfig(id: 'zaka', label: 'Zakat', icon: 'payments', enabled: true, order: 85),
    ProfileTabConfig(id: 'dua', label: 'Dua', icon: 'self_improvement', enabled: true, order: 86),
    ProfileTabConfig(id: 'hadith', label: 'Hadith', icon: 'format_quote', enabled: true, order: 87),
    ProfileTabConfig(id: 'tafuta_msikiti', label: 'Mosque Finder', icon: 'mosque', enabled: true, order: 88),
    ProfileTabConfig(id: 'maulid', label: 'Maulid', icon: 'celebration', enabled: true, order: 89),
    // ── Community & Lifestyle ───────────────────────────────────────
    ProfileTabConfig(id: 'nightlife', label: 'Night Life', icon: 'nightlife', enabled: true, order: 60),
    ProfileTabConfig(id: 'events', label: 'Events', icon: 'event', enabled: true, order: 61),
    ProfileTabConfig(id: 'travel', label: 'Travel', icon: 'flight', enabled: true, order: 62),
    ProfileTabConfig(id: 'games', label: 'Games', icon: 'sports_esports', enabled: true, order: 63),

    // ── Education ─────────────────────────────────────────────────────
    ProfileTabConfig(id: 'my_class', label: 'My Class', icon: 'school', enabled: true, order: 100),
    ProfileTabConfig(id: 'timetable', label: 'Timetable', icon: 'calendar_today', enabled: true, order: 101),
    ProfileTabConfig(id: 'assignments', label: 'Assignments', icon: 'assignment', enabled: true, order: 102),
    ProfileTabConfig(id: 'class_chat', label: 'Class Chat', icon: 'forum', enabled: true, order: 103),
    ProfileTabConfig(id: 'class_notes', label: 'Notes', icon: 'note_alt', enabled: true, order: 104),
    ProfileTabConfig(id: 'exam_prep', label: 'Exam Prep', icon: 'quiz', enabled: true, order: 105),
    ProfileTabConfig(id: 'results', label: 'Results', icon: 'grade', enabled: true, order: 106),
    ProfileTabConfig(id: 'fee_status', label: 'Fee Status', icon: 'account_balance_wallet', enabled: true, order: 107),
    ProfileTabConfig(id: 'library', label: 'Library', icon: 'local_library', enabled: true, order: 108),
    ProfileTabConfig(id: 'campus_news', label: 'Campus News', icon: 'campaign', enabled: true, order: 109),
    ProfileTabConfig(id: 'study_groups', label: 'Study Groups', icon: 'groups', enabled: true, order: 110),
    ProfileTabConfig(id: 'past_papers', label: 'Past Papers', icon: 'history_edu', enabled: true, order: 111),
    ProfileTabConfig(id: 'newton', label: 'Newton', icon: 'psychology', enabled: true, order: 112),
    ProfileTabConfig(id: 'career', label: 'Career', icon: 'work_outline', enabled: true, order: 113),

    // ── Security ──────────────────────────────────────────────────────
    ProfileTabConfig(id: 'police', label: 'Police', icon: 'local_police', enabled: true, order: 120),
    ProfileTabConfig(id: 'traffic', label: 'Traffic', icon: 'traffic', enabled: true, order: 121),
    ProfileTabConfig(id: 'neighbourhood_watch', label: 'Neighbourhood Watch', icon: 'shield', enabled: true, order: 122),
    ProfileTabConfig(id: 'alerts', label: 'Alerts', icon: 'notifications_active', enabled: true, order: 123),
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
      label: 'COMMERCE',
      tabIds: ['shop', 'michango', 'documents', 'tajirika'],
    ),
    ProfileTabCategory(
      id: 'finance',
      label: 'FINANCE',
      tabIds: ['budget', 'kikoba', 'investments', 'loans', 'bills'],
    ),
    ProfileTabCategory(
      id: 'health',
      label: 'HEALTH',
      tabIds: ['doctor', 'pharmacy', 'insurance', 'fitness', 'ambulance'],
    ),
    ProfileTabCategory(
      id: 'family',
      label: 'WOMEN & FAMILY',
      tabIds: ['my_circle', 'my_pregnancy', 'my_baby', 'family', 'skincare', 'hair_nails'],
    ),
    ProfileTabCategory(
      id: 'work',
      label: 'BUSINESS',
      tabIds: [
        'biz_profile', 'biz_docs', 'biz_email', 'biz_card',
        'biz_quotes', 'biz_invoices', 'biz_recurring', 'biz_vfd',
        'biz_customers', 'biz_debts', 'biz_reminders',
        'biz_expenses', 'biz_tax', 'biz_credit',
        'biz_employees', 'biz_payroll',
        'biz_suppliers', 'biz_po', 'biz_tenders',
        'biz_appointments',
      ],
    ),
    ProfileTabCategory(
      id: 'lifestyle',
      label: 'LIFESTYLE',
      tabIds: ['food', 'transport', 'services', 'housing', 'nightlife', 'events', 'travel', 'games'],
    ),
    ProfileTabCategory(
      id: 'official',
      label: 'GOVERNMENT & LEGAL',
      tabIds: [
        'government', 'lawyer',
        'barozi_wangu', 'ofisi_mtaa', 'dc', 'rc', 'katiba', 'legal_gpt',
        'nida', 'rita', 'tra', 'brela', 'passport', 'driving_licence', 'land_office',
        'nhif', 'nssf', 'latra', 'tira', 'ewura', 'heslb', 'necta',
        'tanesco', 'dawasco',
      ],
    ),
    ProfileTabCategory(
      id: 'faith',
      label: 'FAITH',
      tabIds: [
        'my_faith',
        // Christian
        'biblia', 'sala', 'fungu_la_kumi', 'kanisa_langu', 'huduma',
        'jumuiya', 'ibada', 'shule_ya_jumapili', 'tafuta_kanisa',
        // Islamic
        'wakati_wa_sala', 'qibla', 'quran', 'kalenda_hijri', 'ramadan',
        'zaka', 'dua', 'hadith', 'tafuta_msikiti', 'maulid',
      ],
    ),
    ProfileTabCategory(
      id: 'my_cars',
      label: 'MY CARS',
      tabIds: ['my_cars', 'car_insurance', 'buy_car', 'fuel_delivery', 'service_garage', 'sell_car', 'rent_car', 'owners_club', 'spare_parts'],
    ),
    ProfileTabCategory(
      id: 'education',
      label: 'EDUCATION',
      tabIds: ['my_class', 'timetable', 'assignments', 'class_chat', 'class_notes', 'exam_prep', 'past_papers', 'newton', 'results', 'fee_status', 'library', 'campus_news', 'study_groups', 'career'],
    ),
    ProfileTabCategory(
      id: 'security',
      label: 'SECURITY',
      tabIds: ['police', 'traffic', 'neighbourhood_watch', 'alerts'],
    ),
  ];

  static List<ProfileTabConfig> getDefaults() {
    return List.from(defaultTabs);
  }
}
