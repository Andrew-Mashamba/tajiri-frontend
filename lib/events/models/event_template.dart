// lib/events/models/event_template.dart
// Central registry: event type → feature configuration
// Controls: create wizard steps, dashboard tabs, pillar configs
import 'package:flutter/material.dart';

// ── Pillar Configs ──

class KamatiConfig {
  final bool enabled;
  final bool hasSubCommittees;
  final List<String> defaultSubCommittees;
  final List<String> defaultRoles;
  final bool hasMeetings;
  final bool hasTaskTracking;
  final bool autoCreate;

  const KamatiConfig({
    this.enabled = false,
    this.hasSubCommittees = false,
    this.defaultSubCommittees = const [],
    this.defaultRoles = const ['Mwenyekiti', 'Katibu', 'Mhazini'],
    this.hasMeetings = false,
    this.hasTaskTracking = false,
    this.autoCreate = false,
  });

  static const disabled = KamatiConfig();

  static const wedding = KamatiConfig(
    enabled: true,
    hasSubCommittees: true,
    defaultSubCommittees: ['Chakula', 'Mapambo', 'Burudani', 'Usafiri', 'Usalama', 'Mapokezi', 'Picha/Video', 'Michango', 'Kadi/Mwaliko', 'Mavazi'],
    hasMeetings: true,
    hasTaskTracking: true,
  );

  static const funeral = KamatiConfig(
    enabled: true,
    hasSubCommittees: true,
    defaultSubCommittees: ['Chakula', 'Usafiri', 'Mawasiliano', 'Fedha', 'Mazishi'],
    autoCreate: true,
  );

  static const basic = KamatiConfig(
    enabled: true,
    defaultSubCommittees: [],
  );

  static const conference = KamatiConfig(
    enabled: true,
    hasSubCommittees: true,
    defaultSubCommittees: ['Program', 'Usajili', 'Vifaa', 'Wadhamini', 'Burudani', 'Mapokezi'],
    hasMeetings: true,
    hasTaskTracking: true,
  );
}

class MichangoConfig {
  final bool enabled;
  final bool hasGoal;
  final bool hasPledges;
  final bool hasCategories;
  final bool hasFollowUp;
  final bool hasReciprocity;
  final bool isUrgent;
  final String collectionLabel;
  final List<String> defaultCategories;

  const MichangoConfig({
    this.enabled = false,
    this.hasGoal = false,
    this.hasPledges = false,
    this.hasCategories = false,
    this.hasFollowUp = false,
    this.hasReciprocity = false,
    this.isUrgent = false,
    this.collectionLabel = 'Michango',
    this.defaultCategories = const [],
  });

  static const disabled = MichangoConfig();

  static const wedding = MichangoConfig(
    enabled: true,
    hasGoal: true,
    hasPledges: true,
    hasCategories: true,
    hasFollowUp: true,
    hasReciprocity: true,
    defaultCategories: ['Ndugu wa karibu', 'Ndugu wa mbali', 'Marafiki', 'Wafanyakazi', 'Waumini', 'Majirani'],
  );

  static const funeral = MichangoConfig(
    enabled: true,
    hasGoal: false,
    hasPledges: false,
    hasReciprocity: true,
    isUrgent: true,
    collectionLabel: 'Mchango wa Msiba',
  );

  static const harambee = MichangoConfig(
    enabled: true,
    hasGoal: true,
    hasPledges: true,
    hasFollowUp: true,
    collectionLabel: 'Michango ya Harambee',
  );

  static const church = MichangoConfig(
    enabled: true,
    hasGoal: true,
    collectionLabel: 'Sadaka',
  );

  static const giftFund = MichangoConfig(
    enabled: true,
    hasGoal: true,
    collectionLabel: 'Mchango wa Zawadi',
  );
}

class BajetiConfig {
  final bool enabled;
  final List<String> defaultCategories;
  final bool hasSubCommitteeAllocation;
  final bool hasDisbursement;
  final bool hasReceiptCapture;
  final bool hasFinancialReport;
  final String currency;

  const BajetiConfig({
    this.enabled = false,
    this.defaultCategories = const [],
    this.hasSubCommitteeAllocation = false,
    this.hasDisbursement = false,
    this.hasReceiptCapture = false,
    this.hasFinancialReport = false,
    this.currency = 'TZS',
  });

  static const disabled = BajetiConfig();

  static const wedding = BajetiConfig(
    enabled: true,
    defaultCategories: ['Chakula', 'Ukumbi/Hema', 'Mapambo', 'Picha/Video', 'Burudani', 'Usafiri', 'Mavazi', 'Keki', 'Kadi', 'Ada ya Kanisa/Msikiti', 'Mshereheshaji', 'Usalama', 'Hifadhi'],
    hasSubCommitteeAllocation: true,
    hasDisbursement: true,
    hasReceiptCapture: true,
    hasFinancialReport: true,
  );

  static const funeral = BajetiConfig(
    enabled: true,
    defaultCategories: ['Jeneza', 'Chakula', 'Usafiri', 'Kanisa/Msikiti', 'Mazishi', 'Mengineyo'],
    hasReceiptCapture: true,
    hasFinancialReport: true,
  );

  static const harambee = BajetiConfig(
    enabled: true,
    defaultCategories: ['Sababu Kuu', 'Usafiri', 'Mawasiliano', 'Mengineyo'],
    hasFinancialReport: true,
  );

  static const conference = BajetiConfig(
    enabled: true,
    defaultCategories: ['Ukumbi', 'Chakula', 'Wasemaji', 'Vifaa', 'Matangazo', 'Teknolojia', 'Usafiri', 'Hifadhi'],
    hasReceiptCapture: true,
    hasFinancialReport: true,
  );
}

// ── Event Template ──

enum EventTemplateType {
  harusi,
  msiba,
  harambee,
  sherehe,
  mkutano,
  tamasha,
  ibada,
  shule,
  agm,
  maonyesho,
  nyingine;

  String get displayName {
    switch (this) {
      case EventTemplateType.harusi: return 'Harusi';
      case EventTemplateType.msiba: return 'Msiba';
      case EventTemplateType.harambee: return 'Harambee';
      case EventTemplateType.sherehe: return 'Sherehe';
      case EventTemplateType.mkutano: return 'Mkutano';
      case EventTemplateType.tamasha: return 'Tamasha';
      case EventTemplateType.ibada: return 'Ibada';
      case EventTemplateType.shule: return 'Shule';
      case EventTemplateType.agm: return 'AGM/SACCOS';
      case EventTemplateType.maonyesho: return 'Maonyesho';
      case EventTemplateType.nyingine: return 'Nyingine';
    }
  }

  String get subtitle {
    switch (this) {
      case EventTemplateType.harusi: return 'Wedding';
      case EventTemplateType.msiba: return 'Funeral';
      case EventTemplateType.harambee: return 'Fundraiser';
      case EventTemplateType.sherehe: return 'Party';
      case EventTemplateType.mkutano: return 'Conference';
      case EventTemplateType.tamasha: return 'Concert';
      case EventTemplateType.ibada: return 'Worship';
      case EventTemplateType.shule: return 'School';
      case EventTemplateType.agm: return 'Meeting';
      case EventTemplateType.maonyesho: return 'Exhibition';
      case EventTemplateType.nyingine: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case EventTemplateType.harusi: return Icons.favorite_rounded;
      case EventTemplateType.msiba: return Icons.brightness_low_rounded;
      case EventTemplateType.harambee: return Icons.handshake_rounded;
      case EventTemplateType.sherehe: return Icons.celebration_rounded;
      case EventTemplateType.mkutano: return Icons.business_center_rounded;
      case EventTemplateType.tamasha: return Icons.music_note_rounded;
      case EventTemplateType.ibada: return Icons.church_rounded;
      case EventTemplateType.shule: return Icons.school_rounded;
      case EventTemplateType.agm: return Icons.groups_rounded;
      case EventTemplateType.maonyesho: return Icons.art_track_rounded;
      case EventTemplateType.nyingine: return Icons.event_rounded;
    }
  }

  static EventTemplateType fromApi(String? value) {
    if (value == null) return EventTemplateType.nyingine;
    for (final t in EventTemplateType.values) {
      if (t.name == value) return t;
    }
    return EventTemplateType.nyingine;
  }
}

// ── Sub-types for Sherehe (Party) ──

enum SherehSubType {
  birthday,
  babyShower,
  graduation,
  sendOff,
  housewarming,
  retirement;

  String get displayName {
    switch (this) {
      case SherehSubType.birthday: return 'Kuzaliwa';
      case SherehSubType.babyShower: return 'Baby Shower';
      case SherehSubType.graduation: return 'Kuhitimu';
      case SherehSubType.sendOff: return 'Kuaga';
      case SherehSubType.housewarming: return 'Nyumba Mpya';
      case SherehSubType.retirement: return 'Kustaafu';
    }
  }

  String get subtitle {
    switch (this) {
      case SherehSubType.birthday: return 'Birthday';
      case SherehSubType.babyShower: return 'Baby Shower';
      case SherehSubType.graduation: return 'Graduation';
      case SherehSubType.sendOff: return 'Send-off';
      case SherehSubType.housewarming: return 'Housewarming';
      case SherehSubType.retirement: return 'Retirement';
    }
  }
}

class EventTemplate {
  final EventTemplateType type;
  final KamatiConfig kamatiConfig;
  final MichangoConfig michangoConfig;
  final BajetiConfig bajetiConfig;
  final bool hasTicketing;
  final bool hasGuestCategories;
  final bool hasGiftRegistry;
  final bool hasLinkedEvents;
  final bool isEmergency;
  final List<String> createSteps;
  final List<String> dashboardTabs;
  final Duration? defaultPlanningWindow;

  const EventTemplate({
    required this.type,
    required this.kamatiConfig,
    required this.michangoConfig,
    required this.bajetiConfig,
    this.hasTicketing = false,
    this.hasGuestCategories = false,
    this.hasGiftRegistry = false,
    this.hasLinkedEvents = false,
    this.isEmergency = false,
    this.createSteps = const ['basics', 'review'],
    this.dashboardTabs = const ['overview'],
    this.defaultPlanningWindow,
  });
}

// ── Template Registry — Single Source of Truth ──

class EventTemplateRegistry {
  static const Map<EventTemplateType, EventTemplate> templates = {
    EventTemplateType.harusi: EventTemplate(
      type: EventTemplateType.harusi,
      kamatiConfig: KamatiConfig.wedding,
      michangoConfig: MichangoConfig.wedding,
      bajetiConfig: BajetiConfig.wedding,
      hasTicketing: false,
      hasGuestCategories: true,
      hasGiftRegistry: true,
      hasLinkedEvents: true,
      isEmergency: false,
      createSteps: ['basics', 'kamati', 'bajeti', 'michango', 'wageni', 'linked', 'review'],
      dashboardTabs: ['overview', 'kamati', 'michango', 'bajeti', 'wageni', 'vikao', 'matukio', 'picha'],
      defaultPlanningWindow: Duration(days: 180),
    ),

    EventTemplateType.msiba: EventTemplate(
      type: EventTemplateType.msiba,
      kamatiConfig: KamatiConfig.funeral,
      michangoConfig: MichangoConfig.funeral,
      bajetiConfig: BajetiConfig.funeral,
      hasLinkedEvents: true,
      isEmergency: true,
      createSteps: ['emergency'],
      dashboardTabs: ['overview', 'michango', 'gharama', 'kumbukumbu'],
    ),

    EventTemplateType.harambee: EventTemplate(
      type: EventTemplateType.harambee,
      kamatiConfig: KamatiConfig.basic,
      michangoConfig: MichangoConfig.harambee,
      bajetiConfig: BajetiConfig.harambee,
      createSteps: ['basics', 'kamati', 'michango', 'review'],
      dashboardTabs: ['overview', 'michango', 'gharama', 'matangazo'],
      defaultPlanningWindow: Duration(days: 60),
    ),

    EventTemplateType.sherehe: EventTemplate(
      type: EventTemplateType.sherehe,
      kamatiConfig: KamatiConfig.disabled,
      michangoConfig: MichangoConfig.disabled,
      bajetiConfig: BajetiConfig.disabled,
      hasGiftRegistry: true,
      createSteps: ['basics', 'wageni', 'extras', 'review'],
      dashboardTabs: ['overview', 'wageni', 'zawadi', 'picha'],
      defaultPlanningWindow: Duration(days: 21),
    ),

    EventTemplateType.mkutano: EventTemplate(
      type: EventTemplateType.mkutano,
      kamatiConfig: KamatiConfig.conference,
      michangoConfig: MichangoConfig.disabled,
      bajetiConfig: BajetiConfig.conference,
      hasTicketing: true,
      hasGuestCategories: true,
      createSteps: ['basics', 'tickets', 'agenda', 'kamati', 'bajeti', 'review'],
      dashboardTabs: ['overview', 'usajili', 'ratiba', 'wasemaji', 'wadhamini', 'bajeti'],
      defaultPlanningWindow: Duration(days: 120),
    ),

    EventTemplateType.tamasha: EventTemplate(
      type: EventTemplateType.tamasha,
      kamatiConfig: KamatiConfig.disabled,
      michangoConfig: MichangoConfig.disabled,
      bajetiConfig: BajetiConfig(enabled: true, defaultCategories: ['Ukumbi', 'Wasanii', 'Sauti/Mwanga', 'Usalama', 'Matangazo', 'Vibali', 'Hifadhi']),
      hasTicketing: true,
      hasGuestCategories: true,
      createSteps: ['basics', 'tickets', 'bajeti', 'review'],
      dashboardTabs: ['overview', 'tiketi', 'mauzo', 'checkin'],
      defaultPlanningWindow: Duration(days: 90),
    ),

    EventTemplateType.ibada: EventTemplate(
      type: EventTemplateType.ibada,
      kamatiConfig: KamatiConfig.basic,
      michangoConfig: MichangoConfig.church,
      bajetiConfig: BajetiConfig(enabled: true, defaultCategories: ['Ukumbi', 'Sauti', 'Mapambo', 'Mgeni/Mhubiri', 'Usafiri', 'Chakula']),
      createSteps: ['basics', 'kamati', 'michango', 'bajeti', 'review'],
      dashboardTabs: ['overview', 'sadaka', 'mahudhurio', 'bajeti', 'matangazo'],
      defaultPlanningWindow: Duration(days: 60),
    ),

    EventTemplateType.shule: EventTemplate(
      type: EventTemplateType.shule,
      kamatiConfig: KamatiConfig(enabled: true, hasSubCommittees: true, defaultSubCommittees: ['Chakula', 'Vifaa', 'Program', 'Fedha']),
      michangoConfig: MichangoConfig(enabled: true, hasGoal: true, collectionLabel: 'Michango ya Shule'),
      bajetiConfig: BajetiConfig(enabled: true, defaultCategories: ['Chakula', 'Vifaa', 'Mapambo', 'Burudani', 'Hifadhi'], hasFinancialReport: true),
      createSteps: ['basics', 'kamati', 'michango', 'bajeti', 'review'],
      dashboardTabs: ['overview', 'kamati', 'michango', 'bajeti', 'wageni'],
      defaultPlanningWindow: Duration(days: 60),
    ),

    EventTemplateType.agm: EventTemplate(
      type: EventTemplateType.agm,
      kamatiConfig: KamatiConfig(enabled: true),
      michangoConfig: MichangoConfig.disabled,
      bajetiConfig: BajetiConfig.disabled,
      hasGuestCategories: true,
      createSteps: ['basics', 'wajumbe', 'ajenda', 'review'],
      dashboardTabs: ['overview', 'wajumbe', 'kura', 'hatua', 'taarifa'],
      defaultPlanningWindow: Duration(days: 30),
    ),

    EventTemplateType.maonyesho: EventTemplate(
      type: EventTemplateType.maonyesho,
      kamatiConfig: KamatiConfig(enabled: true, hasSubCommittees: true, defaultSubCommittees: ['Vibanda', 'Usajili', 'Usalama', 'Matangazo']),
      michangoConfig: MichangoConfig.disabled,
      bajetiConfig: BajetiConfig(enabled: true, defaultCategories: ['Ukumbi', 'Vifaa', 'Matangazo', 'Usalama', 'Usafiri', 'Hifadhi'], hasFinancialReport: true),
      hasTicketing: true,
      hasGuestCategories: true,
      createSteps: ['basics', 'vibanda', 'tickets', 'bajeti', 'review'],
      dashboardTabs: ['overview', 'vibanda', 'tiketi', 'bajeti', 'wadhamini'],
      defaultPlanningWindow: Duration(days: 90),
    ),

    EventTemplateType.nyingine: EventTemplate(
      type: EventTemplateType.nyingine,
      kamatiConfig: KamatiConfig.disabled,
      michangoConfig: MichangoConfig.disabled,
      bajetiConfig: BajetiConfig.disabled,
      createSteps: ['basics', 'optional_pillars', 'review'],
      dashboardTabs: ['overview', 'wageni', 'picha'],
    ),
  };

  static EventTemplate getTemplate(EventTemplateType type) {
    return templates[type] ?? templates[EventTemplateType.nyingine]!;
  }

  static List<EventTemplateType> get allTypes => EventTemplateType.values;
}
