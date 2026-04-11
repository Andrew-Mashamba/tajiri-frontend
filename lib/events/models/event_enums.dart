// lib/events/models/event_enums.dart
import 'package:flutter/material.dart';

// ── Event Status ──
enum EventStatus {
  draft,
  published,
  cancelled,
  completed,
  postponed;

  String get displayName {
    switch (this) {
      case EventStatus.draft: return 'Rasimu';
      case EventStatus.published: return 'Imechapishwa';
      case EventStatus.cancelled: return 'Imefutwa';
      case EventStatus.completed: return 'Imekamilika';
      case EventStatus.postponed: return 'Imeahirishwa';
    }
  }

  String get subtitle {
    switch (this) {
      case EventStatus.draft: return 'Draft';
      case EventStatus.published: return 'Published';
      case EventStatus.cancelled: return 'Cancelled';
      case EventStatus.completed: return 'Completed';
      case EventStatus.postponed: return 'Postponed';
    }
  }
}

// ── Event Type ──
enum EventType {
  inPerson,
  virtual,
  hybrid;

  String get displayName {
    switch (this) {
      case EventType.inPerson: return 'Ana kwa Ana';
      case EventType.virtual: return 'Mtandaoni';
      case EventType.hybrid: return 'Mseto';
    }
  }

  String get subtitle {
    switch (this) {
      case EventType.inPerson: return 'In Person';
      case EventType.virtual: return 'Virtual';
      case EventType.hybrid: return 'Hybrid';
    }
  }

  String get apiValue {
    switch (this) {
      case EventType.inPerson: return 'in_person';
      case EventType.virtual: return 'virtual';
      case EventType.hybrid: return 'hybrid';
    }
  }

  static EventType fromApi(String? value) {
    switch (value) {
      case 'in_person': return EventType.inPerson;
      case 'virtual': return EventType.virtual;
      case 'hybrid': return EventType.hybrid;
      default: return EventType.inPerson;
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.inPerson: return Icons.location_on_rounded;
      case EventType.virtual: return Icons.videocam_rounded;
      case EventType.hybrid: return Icons.swap_horiz_rounded;
    }
  }
}

// ── Event Privacy ──
enum EventPrivacy {
  public,
  private,
  inviteOnly,
  groupOnly;

  String get displayName {
    switch (this) {
      case EventPrivacy.public: return 'Umma';
      case EventPrivacy.private: return 'Binafsi';
      case EventPrivacy.inviteOnly: return 'Kwa Mwaliko';
      case EventPrivacy.groupOnly: return 'Kikundi Tu';
    }
  }

  String get subtitle {
    switch (this) {
      case EventPrivacy.public: return 'Public';
      case EventPrivacy.private: return 'Private';
      case EventPrivacy.inviteOnly: return 'Invite Only';
      case EventPrivacy.groupOnly: return 'Group Only';
    }
  }

  String get apiValue {
    switch (this) {
      case EventPrivacy.public: return 'public';
      case EventPrivacy.private: return 'private';
      case EventPrivacy.inviteOnly: return 'invite_only';
      case EventPrivacy.groupOnly: return 'group_only';
    }
  }

  static EventPrivacy fromApi(String? value) {
    switch (value) {
      case 'public': return EventPrivacy.public;
      case 'private': return EventPrivacy.private;
      case 'invite_only': return EventPrivacy.inviteOnly;
      case 'group_only': return EventPrivacy.groupOnly;
      default: return EventPrivacy.public;
    }
  }

  IconData get icon {
    switch (this) {
      case EventPrivacy.public: return Icons.public_rounded;
      case EventPrivacy.private: return Icons.lock_rounded;
      case EventPrivacy.inviteOnly: return Icons.mail_rounded;
      case EventPrivacy.groupOnly: return Icons.group_rounded;
    }
  }
}

// ── Event Category ──
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
  entertainment,
  nightlife,
  health,
  charity,
  bongoFlava,
  gospel,
  ngoma,
  sherehe,
  harusi,
  msiba,
  harambee,
  ibada,
  michezo,
  maonyesho,
  other;

  String get displayName {
    switch (this) {
      case EventCategory.music: return 'Muziki';
      case EventCategory.sports: return 'Michezo';
      case EventCategory.business: return 'Biashara';
      case EventCategory.education: return 'Elimu';
      case EventCategory.social: return 'Jamii';
      case EventCategory.religious: return 'Dini';
      case EventCategory.cultural: return 'Utamaduni';
      case EventCategory.food: return 'Chakula';
      case EventCategory.tech: return 'Teknolojia';
      case EventCategory.entertainment: return 'Burudani';
      case EventCategory.nightlife: return 'Usiku';
      case EventCategory.health: return 'Afya';
      case EventCategory.charity: return 'Hisani';
      case EventCategory.bongoFlava: return 'Bongo Flava';
      case EventCategory.gospel: return 'Gospel';
      case EventCategory.ngoma: return 'Ngoma';
      case EventCategory.sherehe: return 'Sherehe';
      case EventCategory.harusi: return 'Harusi';
      case EventCategory.msiba: return 'Msiba';
      case EventCategory.harambee: return 'Harambee';
      case EventCategory.ibada: return 'Ibada';
      case EventCategory.michezo: return 'Michezo';
      case EventCategory.maonyesho: return 'Maonyesho';
      case EventCategory.other: return 'Nyingine';
    }
  }

  String get subtitle {
    switch (this) {
      case EventCategory.music: return 'Music';
      case EventCategory.sports: return 'Sports';
      case EventCategory.business: return 'Business';
      case EventCategory.education: return 'Education';
      case EventCategory.social: return 'Social';
      case EventCategory.religious: return 'Religious';
      case EventCategory.cultural: return 'Cultural';
      case EventCategory.food: return 'Food & Drink';
      case EventCategory.tech: return 'Technology';
      case EventCategory.entertainment: return 'Entertainment';
      case EventCategory.nightlife: return 'Nightlife';
      case EventCategory.health: return 'Health & Wellness';
      case EventCategory.charity: return 'Charity';
      case EventCategory.bongoFlava: return 'Bongo Flava';
      case EventCategory.gospel: return 'Gospel';
      case EventCategory.ngoma: return 'Traditional Dance';
      case EventCategory.sherehe: return 'Celebration';
      case EventCategory.harusi: return 'Wedding';
      case EventCategory.msiba: return 'Memorial';
      case EventCategory.harambee: return 'Fundraiser';
      case EventCategory.ibada: return 'Worship';
      case EventCategory.michezo: return 'Local Sports';
      case EventCategory.maonyesho: return 'Exhibition';
      case EventCategory.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case EventCategory.music: return Icons.music_note_rounded;
      case EventCategory.sports: return Icons.sports_soccer_rounded;
      case EventCategory.business: return Icons.business_center_rounded;
      case EventCategory.education: return Icons.school_rounded;
      case EventCategory.social: return Icons.people_rounded;
      case EventCategory.religious: return Icons.church_rounded;
      case EventCategory.cultural: return Icons.theater_comedy_rounded;
      case EventCategory.food: return Icons.restaurant_rounded;
      case EventCategory.tech: return Icons.computer_rounded;
      case EventCategory.entertainment: return Icons.celebration_rounded;
      case EventCategory.nightlife: return Icons.nightlife_rounded;
      case EventCategory.health: return Icons.favorite_rounded;
      case EventCategory.charity: return Icons.volunteer_activism_rounded;
      case EventCategory.bongoFlava: return Icons.music_note_rounded;
      case EventCategory.gospel: return Icons.mic_rounded;
      case EventCategory.ngoma: return Icons.music_note_rounded;
      case EventCategory.sherehe: return Icons.celebration_rounded;
      case EventCategory.harusi: return Icons.favorite_rounded;
      case EventCategory.msiba: return Icons.brightness_low_rounded;
      case EventCategory.harambee: return Icons.handshake_rounded;
      case EventCategory.ibada: return Icons.church_rounded;
      case EventCategory.michezo: return Icons.sports_rounded;
      case EventCategory.maonyesho: return Icons.art_track_rounded;
      case EventCategory.other: return Icons.event_rounded;
    }
  }

  String get apiValue => name;

  static EventCategory fromApi(String? value) {
    if (value == null || value.isEmpty) return EventCategory.other;
    for (final c in EventCategory.values) {
      if (c.name == value || c.apiValue == value) return c;
    }
    return EventCategory.other;
  }
}

// ── Refund Policy ──
enum RefundPolicy {
  fullRefund,
  partialRefund,
  noRefund,
  conditional;

  String get displayName {
    switch (this) {
      case RefundPolicy.fullRefund: return 'Rudisha Yote';
      case RefundPolicy.partialRefund: return 'Rudisha Sehemu';
      case RefundPolicy.noRefund: return 'Hakuna Kurudisha';
      case RefundPolicy.conditional: return 'Kwa Masharti';
    }
  }

  String get subtitle {
    switch (this) {
      case RefundPolicy.fullRefund: return 'Full Refund';
      case RefundPolicy.partialRefund: return 'Partial Refund';
      case RefundPolicy.noRefund: return 'No Refund';
      case RefundPolicy.conditional: return 'Conditional';
    }
  }

  String get apiValue {
    switch (this) {
      case RefundPolicy.fullRefund: return 'full_refund';
      case RefundPolicy.partialRefund: return 'partial_refund';
      case RefundPolicy.noRefund: return 'no_refund';
      case RefundPolicy.conditional: return 'conditional';
    }
  }

  static RefundPolicy fromApi(String? value) {
    switch (value) {
      case 'full_refund': return RefundPolicy.fullRefund;
      case 'partial_refund': return RefundPolicy.partialRefund;
      case 'no_refund': return RefundPolicy.noRefund;
      case 'conditional': return RefundPolicy.conditional;
      default: return RefundPolicy.noRefund;
    }
  }
}

// ── RSVP Status ──
enum RSVPStatus {
  going,
  interested,
  notGoing;

  String get displayName {
    switch (this) {
      case RSVPStatus.going: return 'Nahudhuria';
      case RSVPStatus.interested: return 'Napendezwa';
      case RSVPStatus.notGoing: return 'Sihudhuri';
    }
  }

  String get subtitle {
    switch (this) {
      case RSVPStatus.going: return 'Going';
      case RSVPStatus.interested: return 'Interested';
      case RSVPStatus.notGoing: return 'Not Going';
    }
  }

  String get apiValue {
    switch (this) {
      case RSVPStatus.going: return 'going';
      case RSVPStatus.interested: return 'interested';
      case RSVPStatus.notGoing: return 'not_going';
    }
  }

  static RSVPStatus fromApi(String? value) {
    switch (value) {
      case 'going': return RSVPStatus.going;
      case 'interested': return RSVPStatus.interested;
      case 'not_going': return RSVPStatus.notGoing;
      default: return RSVPStatus.interested;
    }
  }

  IconData get icon {
    switch (this) {
      case RSVPStatus.going: return Icons.check_circle_rounded;
      case RSVPStatus.interested: return Icons.star_rounded;
      case RSVPStatus.notGoing: return Icons.cancel_rounded;
    }
  }
}

// ── Ticket Status ──
enum TicketStatus {
  active,
  used,
  cancelled,
  transferred,
  expired,
  refunded;

  String get displayName {
    switch (this) {
      case TicketStatus.active: return 'Hai';
      case TicketStatus.used: return 'Imetumika';
      case TicketStatus.cancelled: return 'Imefutwa';
      case TicketStatus.transferred: return 'Imehamishwa';
      case TicketStatus.expired: return 'Imeisha Muda';
      case TicketStatus.refunded: return 'Imerudishwa';
    }
  }

  String get subtitle {
    switch (this) {
      case TicketStatus.active: return 'Active';
      case TicketStatus.used: return 'Used';
      case TicketStatus.cancelled: return 'Cancelled';
      case TicketStatus.transferred: return 'Transferred';
      case TicketStatus.expired: return 'Expired';
      case TicketStatus.refunded: return 'Refunded';
    }
  }

  static TicketStatus fromApi(String? value) {
    switch (value) {
      case 'active': return TicketStatus.active;
      case 'used': return TicketStatus.used;
      case 'cancelled': return TicketStatus.cancelled;
      case 'transferred': return TicketStatus.transferred;
      case 'expired': return TicketStatus.expired;
      case 'refunded': return TicketStatus.refunded;
      default: return TicketStatus.active;
    }
  }
}

// ── Team Role ──
enum TeamRole {
  host,
  coHost,
  manager,
  doorStaff,
  volunteer;

  String get displayName {
    switch (this) {
      case TeamRole.host: return 'Mwenyeji';
      case TeamRole.coHost: return 'Msaidizi';
      case TeamRole.manager: return 'Meneja';
      case TeamRole.doorStaff: return 'Mlangoni';
      case TeamRole.volunteer: return 'Kujitolea';
    }
  }

  String get subtitle {
    switch (this) {
      case TeamRole.host: return 'Host';
      case TeamRole.coHost: return 'Co-Host';
      case TeamRole.manager: return 'Manager';
      case TeamRole.doorStaff: return 'Door Staff';
      case TeamRole.volunteer: return 'Volunteer';
    }
  }

  String get apiValue {
    switch (this) {
      case TeamRole.host: return 'host';
      case TeamRole.coHost: return 'co_host';
      case TeamRole.manager: return 'manager';
      case TeamRole.doorStaff: return 'door_staff';
      case TeamRole.volunteer: return 'volunteer';
    }
  }

  static TeamRole fromApi(String? value) {
    switch (value) {
      case 'host': return TeamRole.host;
      case 'co_host': return TeamRole.coHost;
      case 'manager': return TeamRole.manager;
      case 'door_staff': return TeamRole.doorStaff;
      case 'volunteer': return TeamRole.volunteer;
      default: return TeamRole.volunteer;
    }
  }
}

// ── Sponsor Tier ──
enum SponsorTier {
  platinum,
  gold,
  silver,
  bronze,
  community;

  String get displayName {
    switch (this) {
      case SponsorTier.platinum: return 'Platini';
      case SponsorTier.gold: return 'Dhahabu';
      case SponsorTier.silver: return 'Fedha';
      case SponsorTier.bronze: return 'Shaba';
      case SponsorTier.community: return 'Jamii';
    }
  }

  String get subtitle {
    switch (this) {
      case SponsorTier.platinum: return 'Platinum';
      case SponsorTier.gold: return 'Gold';
      case SponsorTier.silver: return 'Silver';
      case SponsorTier.bronze: return 'Bronze';
      case SponsorTier.community: return 'Community';
    }
  }

  static SponsorTier fromApi(String? value) {
    switch (value) {
      case 'platinum': return SponsorTier.platinum;
      case 'gold': return SponsorTier.gold;
      case 'silver': return SponsorTier.silver;
      case 'bronze': return SponsorTier.bronze;
      case 'community': return SponsorTier.community;
      default: return SponsorTier.community;
    }
  }
}

// ── Payment Method ──
enum PaymentMethod {
  mpesa,
  tigoPesa,
  airtelMoney,
  haloPesa,
  wallet,
  card;

  String get displayName {
    switch (this) {
      case PaymentMethod.mpesa: return 'M-Pesa';
      case PaymentMethod.tigoPesa: return 'Tigo Pesa';
      case PaymentMethod.airtelMoney: return 'Airtel Money';
      case PaymentMethod.haloPesa: return 'Halo Pesa';
      case PaymentMethod.wallet: return 'TAJIRI Wallet';
      case PaymentMethod.card: return 'Kadi / Card';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethod.mpesa: return 'mpesa';
      case PaymentMethod.tigoPesa: return 'tigo_pesa';
      case PaymentMethod.airtelMoney: return 'airtel_money';
      case PaymentMethod.haloPesa: return 'halo_pesa';
      case PaymentMethod.wallet: return 'wallet';
      case PaymentMethod.card: return 'card';
    }
  }

  static PaymentMethod fromApi(String? value) {
    switch (value) {
      case 'mpesa': return PaymentMethod.mpesa;
      case 'tigo_pesa': return PaymentMethod.tigoPesa;
      case 'airtel_money': return PaymentMethod.airtelMoney;
      case 'halo_pesa': return PaymentMethod.haloPesa;
      case 'wallet': return PaymentMethod.wallet;
      case 'card': return PaymentMethod.card;
      default: return PaymentMethod.mpesa;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.mpesa: return Icons.phone_android_rounded;
      case PaymentMethod.tigoPesa: return Icons.phone_android_rounded;
      case PaymentMethod.airtelMoney: return Icons.phone_android_rounded;
      case PaymentMethod.haloPesa: return Icons.phone_android_rounded;
      case PaymentMethod.wallet: return Icons.account_balance_wallet_rounded;
      case PaymentMethod.card: return Icons.credit_card_rounded;
    }
  }
}

// ── Share Target ──
enum ShareTarget {
  whatsapp,
  sms,
  copyLink,
  tajiriDm,
  instagram,
  twitter,
  facebook;

  String get displayName {
    switch (this) {
      case ShareTarget.whatsapp: return 'WhatsApp';
      case ShareTarget.sms: return 'SMS';
      case ShareTarget.copyLink: return 'Nakili Kiungo';
      case ShareTarget.tajiriDm: return 'TAJIRI DM';
      case ShareTarget.instagram: return 'Instagram';
      case ShareTarget.twitter: return 'Twitter / X';
      case ShareTarget.facebook: return 'Facebook';
    }
  }
}

// ── Event Wall Post Type ──
enum EventWallPostType {
  text,
  photo,
  update,
  poll,
  announcement;

  static EventWallPostType fromApi(String? value) {
    switch (value) {
      case 'text': return EventWallPostType.text;
      case 'photo': return EventWallPostType.photo;
      case 'update': return EventWallPostType.update;
      case 'poll': return EventWallPostType.poll;
      case 'announcement': return EventWallPostType.announcement;
      default: return EventWallPostType.text;
    }
  }
}

// ── Waitlist Status ──
enum WaitlistStatus {
  waiting,
  offered,
  accepted,
  expired,
  declined;

  String get displayName {
    switch (this) {
      case WaitlistStatus.waiting: return 'Unasubiri';
      case WaitlistStatus.offered: return 'Umepewa Nafasi';
      case WaitlistStatus.accepted: return 'Umekubali';
      case WaitlistStatus.expired: return 'Imeisha Muda';
      case WaitlistStatus.declined: return 'Umekataa';
    }
  }

  static WaitlistStatus fromApi(String? value) {
    switch (value) {
      case 'waiting': return WaitlistStatus.waiting;
      case 'offered': return WaitlistStatus.offered;
      case 'accepted': return WaitlistStatus.accepted;
      case 'expired': return WaitlistStatus.expired;
      case 'declined': return WaitlistStatus.declined;
      default: return WaitlistStatus.waiting;
    }
  }
}

// ── Promo Type ──
enum PromoType {
  percentage,
  fixedAmount;

  String get apiValue {
    switch (this) {
      case PromoType.percentage: return 'percentage';
      case PromoType.fixedAmount: return 'fixed_amount';
    }
  }

  static PromoType fromApi(String? value) {
    switch (value) {
      case 'percentage': return PromoType.percentage;
      case 'fixed_amount': return PromoType.fixedAmount;
      default: return PromoType.percentage;
    }
  }
}

// ── Announcement Channel ──
enum AnnouncementChannel {
  push,
  sms,
  whatsapp,
  all;

  String get apiValue => name;
}

// ── Recurrence Frequency ──
enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  custom;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily: return 'Kila Siku';
      case RecurrenceFrequency.weekly: return 'Kila Wiki';
      case RecurrenceFrequency.biweekly: return 'Kila Wiki Mbili';
      case RecurrenceFrequency.monthly: return 'Kila Mwezi';
      case RecurrenceFrequency.custom: return 'Maalum';
    }
  }

  String get subtitle {
    switch (this) {
      case RecurrenceFrequency.daily: return 'Daily';
      case RecurrenceFrequency.weekly: return 'Weekly';
      case RecurrenceFrequency.biweekly: return 'Biweekly';
      case RecurrenceFrequency.monthly: return 'Monthly';
      case RecurrenceFrequency.custom: return 'Custom';
    }
  }

  static RecurrenceFrequency fromApi(String? value) {
    switch (value) {
      case 'daily': return RecurrenceFrequency.daily;
      case 'weekly': return RecurrenceFrequency.weekly;
      case 'biweekly': return RecurrenceFrequency.biweekly;
      case 'monthly': return RecurrenceFrequency.monthly;
      case 'custom': return RecurrenceFrequency.custom;
      default: return RecurrenceFrequency.weekly;
    }
  }
}

// ── Event Price Filter (for browse/search) ──
enum EventPriceFilter {
  all,
  free,
  paid;
}

// ── Event Sort ──
enum EventSortBy {
  date,
  popularity,
  distance,
  price;

  String get apiValue => name;
}

// ── Ticket Filter ──
enum TicketFilter {
  all,
  upcoming,
  past;

  String get apiValue => name;
}
