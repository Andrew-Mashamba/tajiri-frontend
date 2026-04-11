# TAJIRI Events Module — Full Design Document

> **Module:** `lib/events/`
> **Version:** 2.0 — Complete Rebuild
> **Date:** 2026-04-07
> **Status:** Design Phase
> **Reference:** `docs/EVENTS_FEATURE_TAXONOMY.md` (200+ features from Eventbrite, Meetup, Luma, Partiful, DICE, Ticketmaster, Facebook Events, Hopin, and East African platforms)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Overview](#2-architecture-overview)
3. [TAJIRI Infrastructure Leverage Map](#3-tajiri-infrastructure-leverage-map)
4. [Data Models](#4-data-models)
5. [Service Layer](#5-service-layer)
6. [API Endpoints](#6-api-endpoints)
7. [Screen Architecture](#7-screen-architecture)
8. [Widget Library](#8-widget-library)
9. [Discovery & Recommendation Engine](#9-discovery--recommendation-engine)
10. [Ticketing System](#10-ticketing-system)
11. [Payment Integration](#11-payment-integration)
12. [Social Features](#12-social-features)
13. [Communication & Notifications](#13-communication--notifications)
14. [Media & Content](#14-media--content)
15. [Calendar Integration](#15-calendar-integration)
16. [Maps & Location](#16-maps--location)
17. [Organizer Tools](#17-organizer-tools)
18. [Virtual & Hybrid Events](#18-virtual--hybrid-events)
19. [Offline Support & Caching](#19-offline-support--caching)
20. [East Africa Localization](#20-east-africa-localization)
21. [File Structure](#21-file-structure)
22. [Phased Implementation Plan](#22-phased-implementation-plan)
23. [Backend API Contract](#23-backend-api-contract)

---

## 1. Executive Summary

The TAJIRI Events module transforms from a basic 10-file event listing into a full-featured event planning, ticketing, and social platform — the "Eventbrite of East Africa" integrated natively into a social network.

**Current state:** 10 files, ~15 features, no auth, no payments, no social, no discovery.

**Target state:** 60+ files, 150+ features, M-Pesa native, deeply social, offline-capable, Swahili-first.

**Key advantage over standalone event apps:** TAJIRI already has the social graph (friends, followers, groups), messaging infrastructure, wallet/M-Pesa integration, live streaming, media handling, notifications, and creator economy. The events module wires into ALL of this rather than building from scratch.

### Design Principles

1. **Leverage, don't duplicate** — Reuse TAJIRI's 53+ existing services wherever possible
2. **Social-first** — Every event screen shows friends going, comments, shares
3. **Mobile money native** — M-Pesa/Tigo Pesa are primary, cards are secondary
4. **Swahili-first, English-always** — All UI labels in both languages
5. **Offline-capable** — Event details, tickets, and QR codes work without connectivity
6. **Low-bandwidth** — Compressed images, lazy loading, pagination everywhere
7. **Monochromatic UI** — `#1A1A1A` dark / `#FAFAFA` light per TAJIRI design system

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        EVENTS MODULE                            │
│                         lib/events/                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   SCREENS    │  │   WIDGETS    │  │   ORGANIZER TOOLS    │  │
│  │              │  │              │  │                      │  │
│  │ Home         │  │ EventCard    │  │ Dashboard            │  │
│  │ Browse       │  │ TicketCard   │  │ CheckIn Scanner      │  │
│  │ Detail       │  │ RSVPButton   │  │ Attendee Manager     │  │
│  │ Create       │  │ AttendeePill │  │ Sales Reports        │  │
│  │ MyTickets    │  │ CountdownBar │  │ Team Management      │  │
│  │ MyEvents     │  │ EventMap     │  │ Announcement Editor  │  │
│  │ Search       │  │ TicketTier   │  │ Survey Builder       │  │
│  │ Calendar     │  │ PromoCode    │  │                      │  │
│  │ EventWall    │  │ SeatMap      │  │                      │  │
│  │ PhotoAlbum   │  │ ShareSheet   │  │                      │  │
│  │ CheckIn      │  │ InviteSheet  │  │                      │  │
│  │ LiveStream   │  │ FilterChip   │  │                      │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
│         │                 │                      │              │
├─────────┴─────────────────┴──────────────────────┴──────────────┤
│                      SERVICES LAYER                             │
│  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │ EventService    │  │ TicketService    │  │ EventCache    │  │
│  │ (CRUD, RSVP,    │  │ (purchase, tiers │  │ Service       │  │
│  │  search, feed)  │  │  transfer, QR)   │  │ (Hive-based)  │  │
│  └────────┬────────┘  └────────┬─────────┘  └───────┬───────┘  │
│           │                    │                     │          │
├───────────┴────────────────────┴─────────────────────┴──────────┤
│                  TAJIRI CORE SERVICES (REUSED)                  │
│                                                                 │
│  AuthenticatedDio  │  WalletService    │  MessageService        │
│  FriendService     │  GroupService     │  LiveUpdateService      │
│  FcmService        │  PhotoService     │  VideoUploadService     │
│  LocationService   │  ContentEngine    │  ContributionService    │
│  MediaCacheService │  NotificationSvc  │  LivestreamService      │
│  PresenceService   │  ProfileService   │  LocalStorageService    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. TAJIRI Infrastructure Leverage Map

Every row below maps a feature need to an existing TAJIRI service — avoiding reinvention.

| Feature Need | Existing TAJIRI Service | How to Leverage |
|---|---|---|
| **Authenticated API calls** | `AuthenticatedDio` singleton | Replace raw `http.get/post` with `AuthenticatedDio` for auto token injection and 401 refresh |
| **M-Pesa ticket payment** | `WalletService.deposit()` | Trigger STK push via WalletService, then confirm payment on ticket purchase endpoint |
| **"Friends going" display** | `FriendService.getFriends()` | Cross-reference event attendees with user's friend list |
| **Event group chat** | `MessageService.createGroup()` | Auto-create a Conversation (type=group) linked to event, use existing chat UI |
| **Share to WhatsApp/SMS** | `share_post_sheet.dart` pattern | Adapt existing share bottom sheet for event deep links |
| **Push notifications** | `FcmService` + `NotificationService` | Add 'events' notification channel, route event payloads to event detail screen |
| **Real-time updates** | `LiveUpdateService` (Firestore) | Add `EventUpdateEvent` sealed class subtype, listen for RSVP/comment changes |
| **Cover image upload** | `PhotoService.uploadPhoto()` | Multipart upload for event cover/gallery images |
| **Video upload** | `VideoUploadService` / `ResumableUploadService` | Event trailers, highlight reels with progress tracking |
| **Live streaming** | `LivestreamService` + Zego SDK | Embed live stream viewer in event detail page |
| **Location hierarchy** | `LocationService` (Region → District → Ward → Street) | Event location picker with Tanzania-specific hierarchy |
| **Event discovery algo** | `ContentEngineService.discover()` | Extend discover endpoint to include events alongside posts |
| **Offline caching** | `FeedCacheService` pattern + `MediaCacheService` | Cache event lists, details, and ticket QR codes in Hive |
| **Creator monetization** | `CreatorService` + `PaymentService` | Organizer payouts, tip/donation on event pages |
| **Fundraiser events** | `ContributionService` (Michango) | Harambee-type events link to campaign for crowdfunding |
| **User profiles** | `ProfileService.getProfile()` | Display organizer/attendee profiles with cached avatars |
| **Online/offline status** | `PresenceService` | Show organizer availability for Q&A |
| **Hashtags** | `HashtagService` | Event hashtag discovery and tagging |
| **Group events** | `GroupService.getGroup()` | Events belong to groups, announced to group members |
| **Language** | `LanguageNotifier` + `LocalStorageService` | Swahili/English toggle for all event strings |
| **Theme** | `ThemeNotifier` | Dark/light mode support for all event screens |
| **Calendar sync** | `lib/calendar/` module | Sync RSVPed events to personal calendar |
| **Profile tab** | `ProfileTabConfig` (events tab exists) | Events tab already in profile tab defaults (ID: 'events') |
| **Deep links** | `lib/main.dart` routing | Add `/events/:id`, `/events/browse`, `/events/my-tickets` routes |

---

## 4. Data Models

### 4.1 Primary Model: Event

> **Note:** `lib/models/event_models.dart` already has a mature `EventModel` with 35+ fields including slug, privacy, online/offline, going/interested counts, group/page refs, and `userResponse`. The events module should adopt this as the canonical model and extend it.

```dart
// lib/events/models/event.dart
// Extends the existing EventModel from lib/models/event_models.dart

class Event {
  // ── Identity ──
  final int id;
  final String name;
  final String slug;
  final String? description;
  final EventStatus status;           // draft, published, cancelled, completed
  final EventType type;               // in_person, virtual, hybrid
  final EventPrivacy privacy;         // public, private, invite_only, group_only

  // ── Category & Theme ──
  final EventCategory category;
  final EventTheme? theme;            // visual theme for event page
  final List<String> tags;

  // ── Date & Time ──
  final DateTime startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;
  final String timezone;
  final bool isAllDay;
  final bool isRecurring;
  final RecurrenceRule? recurrenceRule;

  // ── Location ──
  final String? locationName;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final int? regionId;
  final int? districtId;

  // ── Online ──
  final bool isOnline;
  final String? onlineLink;
  final String? onlinePlatform;       // zoom, google_meet, tajiri_live

  // ── Media ──
  final String? coverPhotoUrl;
  final List<String> galleryUrls;
  final String? trailerVideoUrl;

  // ── Organizer ──
  final int creatorId;
  final EventCreator? creator;
  final List<EventCoHost> coHosts;
  final int? groupId;
  final EventGroup? group;

  // ── Ticketing ──
  final bool isFree;
  final double? ticketPrice;
  final String ticketCurrency;        // TZS, KES, UGX, USD
  final List<TicketTier> ticketTiers;
  final int totalCapacity;
  final int soldCount;
  final bool hasWaitlist;
  final RefundPolicy refundPolicy;

  // ── Social Counts ──
  final int goingCount;
  final int interestedCount;
  final int notGoingCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;

  // ── User State ──
  final String? userResponse;         // going, interested, not_going, null
  final bool? isHost;
  final bool? isCoHost;
  final bool? hasPurchasedTicket;
  final bool isSaved;

  // ── Agenda ──
  final List<EventSession> sessions;
  final List<EventSpeaker> speakers;
  final List<EventSponsor> sponsors;

  // ── Friends ──
  final List<EventAttendee> friendsGoing;
  final int friendsGoingCount;

  // ── Metadata ──
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  // ── Computed ──
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isPast => endDate?.isBefore(DateTime.now()) ?? startDate.isBefore(DateTime.now());
  bool get isHappeningNow => startDate.isBefore(DateTime.now()) && (endDate?.isAfter(DateTime.now()) ?? true);
  bool get isSoldOut => totalCapacity > 0 && soldCount >= totalCapacity;
  int get availableSpots => totalCapacity > 0 ? totalCapacity - soldCount : -1; // -1 = unlimited
  bool get isGoing => userResponse == 'going';
  bool get isInterested => userResponse == 'interested';
  bool get hasTickets => ticketTiers.isNotEmpty || (ticketPrice != null && ticketPrice! > 0);
  bool get isMultiDay => endDate != null && endDate!.difference(startDate).inDays >= 1;
  bool get canRSVP => status == EventStatus.published && !isPast;
}
```

### 4.2 EventCategory Enum

```dart
enum EventCategory {
  // Standard
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

  // East Africa-specific
  bongoFlava,    // Bongo Flava concerts
  gospel,        // Gospel events
  ngoma,         // Traditional dance
  sherehe,       // Celebrations/parties
  harusi,        // Weddings
  msiba,         // Funerals/memorials
  harambee,      // Community fundraisers
  ibada,         // Church/mosque services
  michezo,       // Local sports events
  maonyesho,     // Exhibitions/shows

  other;

  String get displayName => _swahiliNames[this] ?? name;
  String get subtitle => _englishNames[this] ?? name;
  IconData get icon => _icons[this] ?? Icons.event_rounded;
}
```

### 4.3 TicketTier

```dart
class TicketTier {
  final int id;
  final int eventId;
  final String name;              // "General", "VIP", "VVIP", "Early Bird"
  final String? description;
  final double price;
  final String currency;          // TZS, KES, UGX, USD
  final int totalQuantity;
  final int soldQuantity;
  final int maxPerOrder;
  final int minPerOrder;
  final DateTime? saleStartDate;
  final DateTime? saleEndDate;
  final bool isHidden;            // invite-only tiers
  final String? accessCode;       // code required to see/buy this tier
  final List<TicketAddon> addons; // parking, food, etc.
  final bool isTransferable;
  final bool isRefundable;

  bool get isOnSale {
    final now = DateTime.now();
    if (saleStartDate != null && now.isBefore(saleStartDate!)) return false;
    if (saleEndDate != null && now.isAfter(saleEndDate!)) return false;
    return true;
  }
  bool get isSoldOut => totalQuantity > 0 && soldQuantity >= totalQuantity;
  int get available => totalQuantity > 0 ? totalQuantity - soldQuantity : -1;
}
```

### 4.4 EventTicket (Purchased)

```dart
class EventTicket {
  final int id;
  final int eventId;
  final int userId;
  final int? ticketTierId;
  final String ticketNumber;         // unique ticket code
  final String? qrCodeData;          // QR payload (rotating hash for anti-fraud)
  final TicketStatus status;         // active, used, cancelled, transferred, expired
  final DateTime purchaseDate;
  final double pricePaid;
  final String currency;
  final String paymentMethod;        // mpesa, tigo_pesa, airtel_money, card, wallet
  final String? paymentReference;    // M-Pesa transaction ID
  final List<TicketAddon> addons;
  final int? transferredFromUserId;
  final int? transferredToUserId;
  final DateTime? checkedInAt;
  final Event? event;
  final TicketTier? tier;
  final String? guestName;           // for +1/guest tickets
  final String? guestPhone;

  bool get isValid => status == TicketStatus.active;
  bool get isCheckedIn => checkedInAt != null;
  bool get isTransferred => transferredToUserId != null;
}

enum TicketStatus { active, used, cancelled, transferred, expired, refunded }
```

### 4.5 RSVP / Attendance

```dart
class EventRSVP {
  final int id;
  final int eventId;
  final int userId;
  final RSVPStatus status;           // going, interested, not_going
  final int guestCount;              // +1, +2, etc.
  final List<String> guestNames;
  final DateTime respondedAt;
  final EventAttendee? user;

  bool get isGoing => status == RSVPStatus.going;
}

enum RSVPStatus { going, interested, notGoing }

class EventAttendee {
  final int userId;
  final String firstName;
  final String lastName;
  final String? username;
  final String? avatarUrl;
  final bool isFriend;               // is the current user's friend
  final RSVPStatus? rsvpStatus;
  final bool isCheckedIn;

  String get fullName => '$firstName $lastName';
}
```

### 4.6 Event Wall / Comments

```dart
class EventComment {
  final int id;
  final int eventId;
  final int userId;
  final String content;
  final List<String> mediaUrls;      // photos in comment
  final int likesCount;
  final int repliesCount;
  final bool isLiked;
  final bool isPinned;               // host can pin comments
  final DateTime createdAt;
  final EventAttendee? user;
  final List<EventComment> replies;
}

class EventWallPost {
  final int id;
  final int eventId;
  final int userId;
  final EventWallPostType type;      // text, photo, update, poll, announcement
  final String? content;
  final List<String> mediaUrls;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isPinned;
  final DateTime createdAt;
  final EventAttendee? user;

  // For polls
  final List<PollOption>? pollOptions;

  // For announcements (host only)
  final bool? isAnnouncement;
}

enum EventWallPostType { text, photo, update, poll, announcement }
```

### 4.7 Event Session / Agenda

```dart
class EventSession {
  final int id;
  final int eventId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;            // room/stage name
  final String? track;               // for multi-track conferences
  final List<EventSpeaker> speakers;
  final int? capacity;
  final bool requiresRSVP;
}

class EventSpeaker {
  final int id;
  final String name;
  final String? title;               // "CEO, Company X"
  final String? bio;
  final String? avatarUrl;
  final int? userId;                 // if speaker is a TAJIRI user
  final List<String> socialLinks;
}

class EventSponsor {
  final int id;
  final String name;
  final String? logoUrl;
  final String? website;
  final SponsorTier tier;            // platinum, gold, silver, bronze

  // Ordering within tier
  final int order;
}

enum SponsorTier { platinum, gold, silver, bronze, community }
```

### 4.8 Waitlist

```dart
class WaitlistEntry {
  final int id;
  final int eventId;
  final int userId;
  final int? ticketTierId;
  final int position;
  final DateTime joinedAt;
  final WaitlistStatus status;       // waiting, offered, accepted, expired

  // When a spot opens up, the user gets an offer with a time limit
  final DateTime? offerExpiresAt;
}

enum WaitlistStatus { waiting, offered, accepted, expired, declined }
```

### 4.9 Promo Code

```dart
class PromoCode {
  final int id;
  final int eventId;
  final String code;
  final PromoType type;              // percentage, fixed_amount
  final double value;                // 10 = 10% or 10 TZS
  final int? maxUses;
  final int usedCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final List<int>? applicableTierIds; // null = all tiers
  final bool isActive;
}

enum PromoType { percentage, fixedAmount }
```

### 4.10 Event Review (Post-Event)

```dart
class EventReview {
  final int id;
  final int eventId;
  final int userId;
  final int rating;                  // 1-5 stars
  final String? content;
  final List<String> photoUrls;
  final int helpfulCount;
  final DateTime createdAt;
  final EventAttendee? user;
}
```

### 4.11 Signup List (Potluck)

```dart
class SignupList {
  final int id;
  final int eventId;
  final String title;                // "Chakula / Food", "Vinywaji / Drinks"
  final List<SignupItem> items;
}

class SignupItem {
  final int id;
  final String name;                 // "Pilau", "Soda", etc.
  final int? quantity;
  final int? userId;                 // who claimed this item
  final EventAttendee? claimedBy;
}
```

### 4.12 Recurring Event Rule

```dart
class RecurrenceRule {
  final RecurrenceFrequency frequency;  // daily, weekly, monthly, custom
  final int interval;                   // every N days/weeks/months
  final List<int>? daysOfWeek;          // [1,3,5] = Mon, Wed, Fri
  final int? dayOfMonth;
  final DateTime? until;                // recurrence end date
  final int? count;                     // or max occurrences
}

enum RecurrenceFrequency { daily, weekly, biweekly, monthly, custom }
```

### 4.13 Organizer Dashboard Models

```dart
class EventAnalytics {
  final int eventId;
  final int totalViews;
  final int uniqueViews;
  final int totalRSVPs;
  final int goingCount;
  final int interestedCount;
  final int ticketsSold;
  final double totalRevenue;
  final String currency;
  final int checkedInCount;
  final double checkInRate;
  final int commentsCount;
  final int sharesCount;
  final List<DailyMetric> dailyViews;
  final List<DailyMetric> dailySales;
  final Map<String, int> trafficSources;  // direct, whatsapp, link, etc.
  final Map<String, int> tierBreakdown;   // tier name → sold count
}

class DailyMetric {
  final DateTime date;
  final int value;
}

class SalesReport {
  final double grossRevenue;
  final double platformFees;
  final double netRevenue;
  final double pendingPayout;
  final double paidOut;
  final List<TicketSale> recentSales;
}

class TicketSale {
  final int ticketId;
  final String buyerName;
  final String tierName;
  final double amount;
  final String paymentMethod;
  final DateTime purchasedAt;
}
```

### 4.14 Enums Summary

```dart
enum EventStatus { draft, published, cancelled, completed, postponed }
enum EventType { inPerson, virtual, hybrid }
enum EventPrivacy { public, private, inviteOnly, groupOnly }
enum RefundPolicy { fullRefund, partialRefund, noRefund, conditional }
```

---

## 5. Service Layer

### 5.1 EventService — Core CRUD + Feed

```dart
// lib/events/services/event_service.dart
// Uses AuthenticatedDio (not raw http) for auto token handling

class EventService {
  final _dio = AuthenticatedDio.instance;

  // ── Discovery & Feed ──
  Future<PaginatedResult<Event>> getEventsFeed({int page, int perPage});
  Future<PaginatedResult<Event>> getEventsNearMe({double lat, double lng, double radiusKm, int page});
  Future<PaginatedResult<Event>> browseEvents({EventCategory? category, String? search, String? dateFrom, String? dateTo, EventPriceFilter? price, EventSortBy? sort, int page});
  Future<PaginatedResult<Event>> getTrendingEvents({int page});
  Future<PaginatedResult<Event>> getGroupEvents({required int groupId, int page});
  Future<PaginatedResult<Event>> getUserEvents({required int userId, int page}); // events user is hosting
  Future<PaginatedResult<Event>> getUserAttendingEvents({required int userId, int page});
  Future<List<Event>> getHappeningNow();
  Future<List<Event>> getFriendsEvents();
  Future<List<Event>> getSimilarEvents({required int eventId});
  Future<List<Event>> getSavedEvents();

  // ── CRUD ──
  Future<Event> getEvent({required int eventId});
  Future<Event> createEvent({required CreateEventRequest request});
  Future<Event> updateEvent({required int eventId, required UpdateEventRequest request});
  Future<void> deleteEvent({required int eventId});
  Future<Event> duplicateEvent({required int eventId});
  Future<Event> publishEvent({required int eventId});
  Future<Event> cancelEvent({required int eventId, String? reason});

  // ── RSVP ──
  Future<EventRSVP> respondToEvent({required int eventId, required RSVPStatus status, int guestCount = 0});
  Future<PaginatedResult<EventAttendee>> getAttendees({required int eventId, RSVPStatus? filter, int page});
  Future<List<EventAttendee>> getFriendsAttending({required int eventId});

  // ── Social ──
  Future<void> saveEvent({required int eventId});
  Future<void> unsaveEvent({required int eventId});
  Future<void> shareEvent({required int eventId, required ShareTarget target}); // track shares
  Future<void> reportEvent({required int eventId, required String reason});

  // ── Invite ──
  Future<void> inviteFriends({required int eventId, required List<int> userIds});
  Future<void> inviteByPhone({required int eventId, required List<String> phoneNumbers}); // SMS invite
  Future<String> getShareLink({required int eventId}); // deep link

  // ── Co-Hosting ──
  Future<void> addCoHost({required int eventId, required int userId});
  Future<void> removeCoHost({required int eventId, required int userId});
}
```

### 5.2 TicketService — Ticketing & Purchase

```dart
// lib/events/services/ticket_service.dart

class TicketService {
  final _dio = AuthenticatedDio.instance;

  // ── Ticket Tiers (Organizer) ──
  Future<TicketTier> createTier({required int eventId, required CreateTierRequest request});
  Future<TicketTier> updateTier({required int tierId, required UpdateTierRequest request});
  Future<void> deleteTier({required int tierId});
  Future<List<TicketTier>> getEventTiers({required int eventId});

  // ── Purchase ──
  Future<TicketPurchaseResult> purchaseTicket({
    required int eventId,
    required int tierId,
    required int quantity,
    required PaymentMethod paymentMethod,
    String? promoCode,
    List<GuestInfo>? guests,          // for +1/group tickets
  });
  Future<TicketPurchaseResult> purchaseFreeTicket({required int eventId, required int tierId});

  // ── My Tickets ──
  Future<PaginatedResult<EventTicket>> getMyTickets({TicketFilter? filter, int page});
  Future<EventTicket> getTicket({required int ticketId});
  Future<String> getTicketQR({required int ticketId});  // rotating QR data

  // ── Transfer & Gift ──
  Future<void> transferTicket({required int ticketId, required int toUserId});
  Future<void> giftTicket({required int ticketId, required String recipientPhone, String? message});

  // ── Refund ──
  Future<void> requestRefund({required int ticketId, String? reason});

  // ── Waitlist ──
  Future<WaitlistEntry> joinWaitlist({required int eventId, int? tierId});
  Future<void> leaveWaitlist({required int waitlistId});
  Future<void> acceptWaitlistOffer({required int waitlistId, required PaymentMethod paymentMethod});

  // ── Promo Codes (Organizer) ──
  Future<PromoCode> createPromoCode({required int eventId, required CreatePromoRequest request});
  Future<PromoValidation> validatePromoCode({required int eventId, required String code});
  Future<List<PromoCode>> getPromoCodes({required int eventId});

  // ── Check-In (Organizer) ──
  Future<CheckInResult> checkInTicket({required String qrData});
  Future<CheckInResult> manualCheckIn({required int ticketId});
  Future<List<CheckInRecord>> getCheckInLog({required int eventId});
}
```

### 5.3 EventWallService — Social Feed Within Event

```dart
// lib/events/services/event_wall_service.dart

class EventWallService {
  final _dio = AuthenticatedDio.instance;

  // ── Wall Posts ──
  Future<PaginatedResult<EventWallPost>> getWallPosts({required int eventId, int page});
  Future<EventWallPost> createWallPost({required int eventId, required CreateWallPostRequest request});
  Future<void> deleteWallPost({required int postId});
  Future<void> likeWallPost({required int postId});
  Future<void> unlikeWallPost({required int postId});
  Future<void> pinWallPost({required int postId});     // host only

  // ── Comments ──
  Future<PaginatedResult<EventComment>> getComments({required int eventId, int page});
  Future<EventComment> addComment({required int eventId, required String content, List<String>? mediaUrls});
  Future<EventComment> replyToComment({required int commentId, required String content});
  Future<void> deleteComment({required int commentId});
  Future<void> likeComment({required int commentId});
  Future<void> pinComment({required int commentId});   // host only

  // ── Photos ──
  Future<PaginatedResult<EventPhoto>> getEventPhotos({required int eventId, int page});
  Future<EventPhoto> uploadEventPhoto({required int eventId, required String filePath, String? caption});

  // ── Reviews (Post-Event) ──
  Future<PaginatedResult<EventReview>> getReviews({required int eventId, int page});
  Future<EventReview> submitReview({required int eventId, required int rating, String? content, List<String>? photoUrls});
}
```

### 5.4 EventOrganizerService — Dashboard & Management

```dart
// lib/events/services/event_organizer_service.dart

class EventOrganizerService {
  final _dio = AuthenticatedDio.instance;

  // ── Analytics ──
  Future<EventAnalytics> getAnalytics({required int eventId});
  Future<SalesReport> getSalesReport({required int eventId, String? dateFrom, String? dateTo});

  // ── Attendees ──
  Future<PaginatedResult<EventAttendee>> getAttendeeList({required int eventId, RSVPStatus? filter, String? search, int page});
  Future<List<int>> exportAttendeeIds({required int eventId});

  // ── Team ──
  Future<void> addTeamMember({required int eventId, required int userId, required TeamRole role});
  Future<void> removeTeamMember({required int eventId, required int userId});
  Future<List<TeamMember>> getTeam({required int eventId});

  // ── Announcements ──
  Future<void> sendAnnouncement({required int eventId, required String message, required AnnouncementChannel channel}); // push, sms, whatsapp

  // ── Surveys ──
  Future<void> createSurvey({required int eventId, required List<SurveyQuestion> questions});
  Future<List<SurveyResponse>> getSurveyResponses({required int eventId});

  // ── Signup Lists (Potluck) ──
  Future<SignupList> createSignupList({required int eventId, required String title, required List<String> items});
  Future<void> claimSignupItem({required int itemId});
  Future<void> unclaimSignupItem({required int itemId});

  // ── Payout ──
  Future<void> requestPayout({required int eventId, required PaymentMethod method});
}
```

### 5.5 EventCacheService — Offline Support

```dart
// lib/events/services/event_cache_service.dart
// Pattern: mirrors FeedCacheService from lib/services/feed_cache_service.dart

class EventCacheService {
  static final EventCacheService _instance = EventCacheService._();
  static EventCacheService get instance => _instance;

  late Box<Map> _eventsBox;
  late Box<Map> _ticketsBox;
  late Box<Map> _savedBox;

  Future<void> init();

  // Cache event lists (feed, browse results, etc.)
  Future<void> cacheEvents({required String key, required List<Event> events});
  Future<List<Event>?> getCachedEvents({required String key});
  Future<DateTime?> getLastFetchTime({required String key});

  // Cache single event detail
  Future<void> cacheEvent({required Event event});
  Future<Event?> getCachedEvent({required int eventId});

  // Cache user's tickets (including QR codes for offline check-in)
  Future<void> cacheTickets({required List<EventTicket> tickets});
  Future<List<EventTicket>?> getCachedTickets();
  Future<void> cacheTicketQR({required int ticketId, required String qrData});
  Future<String?> getCachedTicketQR({required int ticketId});

  // Cache saved events
  Future<void> cacheSavedEvents({required List<Event> events});
  Future<List<Event>?> getCachedSavedEvents();

  // Staleness
  bool isStale({required String key, Duration threshold = const Duration(minutes: 15)});
  Future<void> clearAll();
}
```

---

## 6. API Endpoints

All endpoints use `AuthenticatedDio` (Bearer token auto-injected). Base: `https://tajiri.zimasystems.com/api`

### 6.1 Events CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/events` | Browse events (filters: category, search, date_from, date_to, lat, lng, radius, price, sort, page) |
| `GET` | `/events/feed` | Personalized event feed (social graph, interests, location) |
| `GET` | `/events/trending` | Trending events |
| `GET` | `/events/happening-now` | Currently live events |
| `GET` | `/events/nearby` | Location-based events |
| `GET` | `/events/friends` | Events friends are attending |
| `GET` | `/events/saved` | User's saved events |
| `GET` | `/events/{id}` | Event detail (includes user_response, friends_going, ticket_tiers) |
| `GET` | `/events/{id}/similar` | Similar events |
| `POST` | `/events` | Create event (multipart for cover photo) |
| `PUT` | `/events/{id}` | Update event |
| `DELETE` | `/events/{id}` | Delete event |
| `POST` | `/events/{id}/duplicate` | Clone event |
| `POST` | `/events/{id}/publish` | Publish draft event |
| `POST` | `/events/{id}/cancel` | Cancel event |

### 6.2 RSVP & Attendance

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/events/{id}/rsvp` | RSVP (body: status, guest_count) |
| `GET` | `/events/{id}/attendees` | Attendee list (filter: going/interested, page) |
| `GET` | `/events/{id}/friends-attending` | Friends attending this event |
| `POST` | `/events/{id}/invite` | Invite friends (body: user_ids) |
| `POST` | `/events/{id}/invite-sms` | Invite by phone SMS |
| `POST` | `/events/{id}/save` | Save/bookmark event |
| `DELETE` | `/events/{id}/save` | Unsave event |
| `POST` | `/events/{id}/share` | Track share (body: target: whatsapp/sms/link) |

### 6.3 Ticketing

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/events/{id}/tiers` | Ticket tiers for event |
| `POST` | `/events/{id}/tiers` | Create tier (organizer) |
| `PUT` | `/tiers/{id}` | Update tier |
| `DELETE` | `/tiers/{id}` | Delete tier |
| `POST` | `/events/{id}/tickets/purchase` | Purchase ticket (body: tier_id, quantity, payment_method, promo_code) |
| `GET` | `/tickets` | My tickets (filter: upcoming/past/all, page) |
| `GET` | `/tickets/{id}` | Ticket detail |
| `GET` | `/tickets/{id}/qr` | Get rotating QR data |
| `POST` | `/tickets/{id}/transfer` | Transfer ticket (body: to_user_id) |
| `POST` | `/tickets/{id}/gift` | Gift ticket (body: phone, message) |
| `POST` | `/tickets/{id}/refund` | Request refund |
| `POST` | `/tickets/check-in` | Check-in via QR scan (body: qr_data) |
| `POST` | `/tickets/{id}/manual-check-in` | Manual check-in |

### 6.4 Waitlist & Promo

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/events/{id}/waitlist` | Join waitlist |
| `DELETE` | `/waitlist/{id}` | Leave waitlist |
| `POST` | `/waitlist/{id}/accept` | Accept waitlist offer |
| `POST` | `/events/{id}/promos` | Create promo code (organizer) |
| `GET` | `/events/{id}/promos` | List promo codes (organizer) |
| `POST` | `/events/{id}/promos/validate` | Validate promo code (body: code) |

### 6.5 Event Wall & Social

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/events/{id}/wall` | Wall posts (page) |
| `POST` | `/events/{id}/wall` | Create wall post (multipart) |
| `DELETE` | `/wall/{id}` | Delete wall post |
| `POST` | `/wall/{id}/like` | Like wall post |
| `POST` | `/wall/{id}/pin` | Pin wall post (host) |
| `GET` | `/events/{id}/comments` | Comments (page) |
| `POST` | `/events/{id}/comments` | Add comment |
| `POST` | `/comments/{id}/reply` | Reply to comment |
| `DELETE` | `/comments/{id}` | Delete comment |
| `POST` | `/comments/{id}/like` | Like comment |
| `GET` | `/events/{id}/photos` | Event photo album |
| `POST` | `/events/{id}/photos` | Upload event photo |
| `GET` | `/events/{id}/reviews` | Post-event reviews |
| `POST` | `/events/{id}/reviews` | Submit review |

### 6.6 Organizer Tools

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/events/{id}/analytics` | Event analytics |
| `GET` | `/events/{id}/sales-report` | Sales report |
| `GET` | `/events/{id}/check-in-log` | Check-in log |
| `POST` | `/events/{id}/announcement` | Send announcement |
| `GET` | `/events/{id}/team` | Team members |
| `POST` | `/events/{id}/team` | Add team member |
| `DELETE` | `/events/{id}/team/{userId}` | Remove team member |
| `POST` | `/events/{id}/survey` | Create survey |
| `GET` | `/events/{id}/survey/responses` | Survey responses |
| `POST` | `/events/{id}/payout` | Request payout |

### 6.7 Agenda & Sessions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/events/{id}/sessions` | Event sessions/agenda |
| `POST` | `/events/{id}/sessions` | Add session |
| `PUT` | `/sessions/{id}` | Update session |
| `DELETE` | `/sessions/{id}` | Delete session |
| `GET` | `/events/{id}/speakers` | Speakers list |
| `POST` | `/events/{id}/speakers` | Add speaker |
| `GET` | `/events/{id}/sponsors` | Sponsors list |
| `POST` | `/events/{id}/sponsors` | Add sponsor |

### 6.8 Signup Lists

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/events/{id}/signup-lists` | Get signup lists |
| `POST` | `/events/{id}/signup-lists` | Create signup list |
| `POST` | `/signup-items/{id}/claim` | Claim an item |
| `DELETE` | `/signup-items/{id}/claim` | Unclaim an item |

---

## 7. Screen Architecture

### 7.1 Screen Map

```
lib/events/pages/
├── events_home_page.dart          ← Tab 1: Personalized feed + friends' events
├── browse_events_page.dart        ← Tab 2: Search, filter, map view
├── my_events_page.dart            ← Tab 3: Events I'm hosting + attending + saved
├── event_detail_page.dart         ← Full event detail with RSVP, tickets, social
├── create_event_page.dart         ← Multi-step event creation wizard
├── edit_event_page.dart           ← Edit existing event
├── ticket_purchase_page.dart      ← Tier selection + payment flow
├── my_tickets_page.dart           ← All purchased tickets
├── ticket_detail_page.dart        ← Single ticket with QR code
├── event_wall_page.dart           ← Social feed within event (Partiful-style)
├── event_photos_page.dart         ← Crowdsourced photo album
├── event_attendees_page.dart      ← Full attendee list with filters
├── event_reviews_page.dart        ← Post-event reviews
├── event_agenda_page.dart         ← Multi-session schedule view
├── event_map_page.dart            ← Map view of event location
├── event_calendar_page.dart       ← Calendar view of RSVPed/saved events
├── event_search_page.dart         ← Dedicated search with autocomplete
├── event_invite_page.dart         ← Invite friends / phone contacts
├── signup_list_page.dart          ← Potluck / who's bringing what
├── qr_scanner_page.dart           ← QR check-in scanner (organizer)
├── organizer/
│   ├── organizer_dashboard_page.dart   ← Analytics, sales, check-in stats
│   ├── attendee_management_page.dart   ← Manage attendees, export, filter
│   ├── ticket_management_page.dart     ← Manage tiers, promo codes
│   ├── team_management_page.dart       ← Co-hosts, staff roles
│   ├── announcement_page.dart          ← Send push/SMS/WhatsApp to attendees
│   ├── sales_report_page.dart          ← Revenue, payouts, transactions
│   ├── survey_builder_page.dart        ← Post-event survey creation
│   └── payout_page.dart                ← Request payout to M-Pesa/bank
└── virtual/
    └── virtual_event_page.dart         ← Virtual event lobby (video, chat, Q&A)
```

### 7.2 Events Home Page — Personalized Feed

The landing page when entering the Events tab from the profile.

```
┌─────────────────────────────────────────┐
│ ← Events                    🔍  ➕  ≡   │  AppBar: search, create, menu
├─────────────────────────────────────────┤
│ [For You] [Friends] [Nearby] [Calendar] │  Tab bar
├─────────────────────────────────────────┤
│                                         │
│  ┌─────── Happening Now ──────────────┐ │  Red dot pulse indicator
│  │ 🔴 Live: Bongo Flava Night         │ │
│  │    Diamond Jubilee Hall • 234 going │ │
│  └────────────────────────────────────┘ │
│                                         │
│  Friends' Events                        │
│  ┌────┐ ┌────┐ ┌────┐                  │  Horizontal scroll
│  │ 👤 │ │ 👤 │ │ 👤 │                  │  Friend avatars + event name
│  │Amina│ │John│ │Sara│                  │
│  │Going│ │Int.│ │Going│                 │
│  └────┘ └────┘ └────┘                  │
│                                         │
│  ┌─── Categories ─────────────────────┐ │
│  │ 🎵 Muziki  ⚽ Michezo  💼 Biashara │ │  Horizontal chips
│  │ 🎓 Elimu   ⛪ Ibada   🎉 Sherehe  │ │
│  └────────────────────────────────────┘ │
│                                         │
│  Upcoming Events                        │
│  ┌────────────────────────────────────┐ │
│  │ [Cover Image]                      │ │  EventCard
│  │ Sat, Apr 12 • 18:00               │ │
│  │ Tech Meetup Dar es Salaam          │ │
│  │ 📍 Hyatt Regency                   │ │
│  │ 👥 3 friends going • 45 total      │ │  Friends going indicator
│  │ Bure / Free         [Interested ▼] │ │  Inline RSVP button
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ ...more events...                  │ │  Infinite scroll with pagination
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### 7.3 Event Detail Page

```
┌─────────────────────────────────────────┐
│ ← [Cover Image / Hero]          ⋮ 💾   │  SliverAppBar with cover
│                                         │
│    Sat, Apr 12 • 18:00-22:00           │
├─────────────────────────────────────────┤
│                                         │
│  Tech Meetup Dar es Salaam              │  Title (22px bold)
│  na @john_doe + @amina_m                │  Organizer + co-hosts
│                                         │
│  ┌─ Friends Going ─────────────────┐   │
│  │ 👤👤👤 Amina, John na 3 wengine  │   │  AvatarStack + names
│  └─────────────────────────────────┘   │
│                                         │
│  [Going ✓] [Interested ♡] [Not Going]  │  RSVP buttons (3-way)
│                                         │
│  ┌─ Details ───────────────────────┐   │
│  │ 📅 Jumamosi, 12 Aprili 2026     │   │  Date in Swahili
│  │ 🕕 18:00 - 22:00 EAT            │   │  Time with timezone
│  │ 📍 Hyatt Regency, Dar es Salaam │   │  Location (tappable → map)
│  │ 🗺️ [View on Map]                │   │  Mini map preview
│  │ 🎫 Bure / Free                  │   │  Price
│  │ 👥 45 going • 23 interested     │   │  Attendance counts
│  └─────────────────────────────────┘   │
│                                         │
│  [Wall] [Details] [Agenda] [Photos]     │  Tab section
│                                         │
│  ── Wall Tab (default) ──               │
│  ┌─────────────────────────────────┐   │
│  │ 📢 Host: Doors open at 17:30!   │   │  Pinned announcement
│  │ ───────────────────────────────  │   │
│  │ 👤 Amina: Can't wait! 🎉        │   │  Wall posts / comments
│  │ 👤 Sara: [Photo] Great setup     │   │
│  │ ───────────────────────────────  │   │
│  │ [Write something...]            │   │  Comment input
│  └─────────────────────────────────┘   │
│                                         │
│  ── Details Tab ──                      │
│  │ Maelezo / Description:              │
│  │ Join us for an evening of...         │
│  │                                      │
│  │ Speakers:                            │
│  │ 👤 Jane Doe — CTO, TechCo           │
│  │                                      │
│  │ Sponsors:                            │
│  │ [Logo] PlatinumCo  [Logo] GoldCo    │
│  │                                      │
│  │ Tags: #tech #daressalaam #meetup     │
│                                         │
├─────────────────────────────────────────┤
│ [Get Tickets / Pata Tiketi]             │  Bottom CTA button
│ or [Share Event / Shiriki]              │  If free: share; if paid: buy
└─────────────────────────────────────────┘
```

### 7.4 Create Event Page — Multi-Step Wizard

```
Step 1: Basics
  - Event name (required)
  - Category selector (grid of icons)
  - Event type: In-person / Virtual / Hybrid (toggle)
  - Cover photo upload (camera or gallery)

Step 2: Date & Time
  - Start date + time pickers
  - End date + time pickers (optional)
  - All-day toggle
  - Recurring toggle → recurrence rule picker
  - Timezone (defaults to Africa/Dar_es_Salaam)

Step 3: Location
  - IF in-person/hybrid:
    - Location name (text field)
    - Address (text field with autocomplete)
    - Map pin picker (interactive map)
    - Region/District selector (Tanzania hierarchy via LocationService)
  - IF virtual/hybrid:
    - Platform selector (Zoom, Google Meet, Tajiri Live)
    - Link input
    - OR "Use Tajiri Live" → auto-creates live stream

Step 4: Details
  - Description (rich text, supports @mentions)
  - Privacy: Public / Private / Invite Only / Group Only
  - Group selector (if Group Only — uses GroupService to list user's groups)
  - Tags / hashtags
  - Gallery images (multi-upload)
  - Video trailer (optional)

Step 5: Tickets (optional)
  - Free event toggle (skip if free)
  - Add ticket tiers:
    - Tier name, price, currency, quantity
    - Sale dates, max per order
    - Add-ons (parking, food, etc.)
  - Refund policy selector
  - Promo code setup (optional)
  - Waitlist toggle

Step 6: Extras (optional)
  - Agenda/sessions builder
  - Speakers (name, title, bio, photo)
  - Sponsors (name, logo, tier)
  - Signup list / potluck items
  - Co-hosts (search TAJIRI users)

Step 7: Review & Publish
  - Full preview of event page
  - Save as Draft / Publish Now / Schedule Publish
```

### 7.5 Ticket Purchase Flow

```
┌─────────────────────────────────────────┐
│ ← Pata Tiketi / Get Tickets            │
├─────────────────────────────────────────┤
│                                         │
│  Tech Meetup Dar es Salaam              │
│  Sat, Apr 12 • 18:00                   │
│                                         │
│  ── Select Tier ──                      │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ ○ General Admission                │ │
│  │   TZS 15,000  •  34 remaining     │ │
│  │   Includes: Entry + refreshments   │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ ● VIP                              │ │  Selected state
│  │   TZS 50,000  •  8 remaining      │ │
│  │   Includes: Front row + meet&greet │ │
│  │   [−] 2 [+]                        │ │  Quantity selector
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ ○ VVIP  🔒                         │ │  Locked (needs access code)
│  │   TZS 150,000  •  Enter code      │ │
│  │   [Access code: ________]          │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ── Add-ons ──                          │
│  ☐ Parking (TZS 5,000)                 │
│  ☐ Dinner plate (TZS 10,000)           │
│                                         │
│  ── Promo Code ──                       │
│  [Enter code: ________] [Apply]         │
│  ✅ "EARLY20" — 20% off applied         │
│                                         │
│  ── Summary ──                          │
│  2x VIP           TZS 100,000          │
│  Discount (-20%)  -TZS 20,000          │
│  ─────────────────────────────          │
│  Total             TZS 80,000          │
│                                         │
│  ── Payment Method ──                   │
│  ● M-Pesa (0712 XXX XXX)              │  Default from WalletService
│  ○ Tigo Pesa                            │
│  ○ Airtel Money                         │
│  ○ TAJIRI Wallet (TZS 125,000)         │  Show balance
│  ○ Credit/Debit Card                    │
│                                         │
├─────────────────────────────────────────┤
│ [Nunua Tiketi / Buy Tickets — TZS 80K] │  Purchase button
└─────────────────────────────────────────┘
```

---

## 8. Widget Library

```dart
// lib/events/widgets/

// ── Cards ──
event_card.dart              // Event list item (image, date, title, friends going, RSVP)
event_card_compact.dart      // Smaller card for horizontal scrolls
ticket_card.dart             // Ticket row with QR icon and status badge
ticket_tier_card.dart        // Tier selection card in purchase flow
attendee_pill.dart           // Small avatar + name chip
friend_avatar_stack.dart     // Overlapping friend avatars (3-4 shown + "+X more")
sponsor_card.dart            // Sponsor logo + name + tier badge
speaker_card.dart            // Speaker avatar + name + title
session_card.dart            // Agenda session item
review_card.dart             // Star rating + review text + user
wall_post_card.dart          // Event wall post (text, photo, poll)
signup_item_card.dart         // Potluck item with claim button
happening_now_banner.dart    // Red pulsing "Live" banner for active events

// ── Interactive ──
rsvp_button.dart             // 3-state: Going / Interested / Not Going
rsvp_button_inline.dart      // Compact dropdown version for cards
countdown_timer.dart         // Days:Hours:Mins:Secs countdown to event
category_chip.dart           // Category icon + label (Swahili + English)
filter_chip_row.dart         // Horizontal scrollable filter chips
price_tag.dart               // "Bure / Free" or "TZS 15,000" styled tag
event_status_badge.dart      // Draft / Published / Cancelled / Completed badge
ticket_status_badge.dart     // Active / Used / Transferred / Expired badge
promo_code_field.dart        // Input + validate button + success/error state
quantity_selector.dart       // [−] N [+] stepper for ticket quantity
payment_method_selector.dart // M-Pesa / Tigo / Airtel / Wallet / Card radio
seat_map_viewer.dart         // Interactive seat map (Phase 3)

// ── Sheets ──
event_share_sheet.dart       // Share via WhatsApp, SMS, copy link, social
event_invite_sheet.dart      // Invite friends from TAJIRI + phone contacts
event_filter_sheet.dart      // Filter bottom sheet (category, date, price, distance)
event_sort_sheet.dart        // Sort by: date, popularity, distance, price
event_actions_sheet.dart     // Report, save, share, add to calendar

// ── Map ──
event_map_preview.dart       // Mini map showing venue pin (tappable → full map)
event_map_cluster.dart       // Multiple events on map with clustering

// ── Media ──
event_cover_hero.dart        // Hero image with gradient overlay + date badge
event_gallery_grid.dart      // Photo grid for event gallery
event_photo_viewer.dart      // Full-screen photo viewer with swipe

// ── Empty States ──
no_events_placeholder.dart   // "Hakuna matukio / No events" with illustration
no_tickets_placeholder.dart  // "Huna tiketi / No tickets yet"
```

---

## 9. Discovery & Recommendation Engine

### 9.1 Feed Algorithm

The events feed leverages TAJIRI's existing `ContentEngineService` pattern to rank events:

```
Score = w1 * SocialSignal
      + w2 * LocationProximity
      + w3 * CategoryAffinity
      + w4 * RecencyBoost
      + w5 * PopularitySignal
      + w6 * OrganizerFollowBoost
```

**Signals:**
| Signal | Weight | Source |
|--------|--------|--------|
| Friends going | 0.30 | `FriendService` — cross-ref attendees with friend list |
| Location proximity | 0.20 | GPS distance from user's location / region |
| Category match | 0.15 | User's past RSVP categories + explicit interests |
| Recency | 0.10 | Newer events rank higher, events happening soon get boost |
| Popularity | 0.15 | Going count + interested count + shares |
| Following organizer | 0.10 | Events from organizers user follows |

### 9.2 Discovery Tabs

| Tab | Content | API |
|-----|---------|-----|
| **For You** | Personalized mix based on algorithm | `GET /events/feed` |
| **Friends** | Events where friends are going/interested | `GET /events/friends` |
| **Nearby** | Location-based within radius | `GET /events/nearby?lat=&lng=&radius=` |
| **Calendar** | Timeline view of user's RSVPed + saved | `GET /events/saved` + local RSVP data |
| **Trending** | Most popular this week | `GET /events/trending` |

### 9.3 Search

```
GET /events?search=<query>&category=<cat>&date_from=<date>&date_to=<date>&price=<free|paid|0-50000>&sort=<date|popularity|distance>&lat=<lat>&lng=<lng>&page=<n>
```

Features:
- Autocomplete suggestions from event titles, organizers, venues
- Recent searches (stored locally in Hive)
- Search history
- "Trending searches" from backend

---

## 10. Ticketing System

### 10.1 Ticket Lifecycle

```
                    ┌──────────┐
                    │  Created  │ (tier exists, not purchased)
                    └─────┬────┘
                          │ purchase
                    ┌─────▼────┐
               ┌───▶│  Active   │◀──── accept waitlist offer
               │    └─────┬────┘
               │          │
         refund│    ┌─────┼──────────────┐
               │    │     │              │
         ┌─────┴──┐ │  ┌──▼─────┐  ┌────▼──────┐
         │Refunded│ │  │  Used   │  │Transferred│
         └────────┘ │  │(checked │  │ (to other │
                    │  │  in)    │  │   user)   │
                    │  └────────┘  └───────────┘
                    │
              ┌─────▼─────┐
              │ Cancelled  │ (event cancelled → auto-refund)
              └───────────┘
```

### 10.2 QR Code System

Anti-fraud rotating QR (inspired by DICE and Ticketmaster Safetix):

```
QR Payload = HMAC-SHA256(ticket_id + user_id + timestamp_bucket, server_secret)
```

- QR data rotates every 30 seconds (new `timestamp_bucket`)
- Client requests fresh QR from `GET /tickets/{id}/qr` every 25 seconds
- Offline fallback: cache last 3 QR codes locally for check-in at poor-connectivity venues
- Scanner validates via `POST /tickets/check-in` (body: `{qr_data}`)

### 10.3 Waitlist Flow

```
Event sold out → User taps "Join Waitlist"
  → POST /events/{id}/waitlist
  → User gets position number

Ticket becomes available (refund/cancel/transfer)
  → Server offers to next in waitlist
  → Push notification: "Tiketi inapatikana! / Ticket available!"
  → User has 30 minutes to accept
  → POST /waitlist/{id}/accept with payment
  → If expired, offer passes to next person
```

---

## 11. Payment Integration

### 11.1 Leveraging TAJIRI WalletService

The events module does NOT build its own payment system. It reuses `WalletService` from `lib/services/wallet_service.dart`.

```dart
// Ticket purchase flow
Future<TicketPurchaseResult> purchaseTicket({...}) async {
  // 1. Create pending ticket order on backend
  final order = await _dio.post('/events/$eventId/tickets/purchase', data: {...});

  // 2. Process payment through WalletService
  if (paymentMethod == PaymentMethod.mpesa) {
    // STK push via WalletService
    final walletService = WalletService();
    final payResult = await walletService.deposit(
      amount: totalAmount,
      provider: 'mpesa',
      reference: order.data['payment_reference'],
    );
  } else if (paymentMethod == PaymentMethod.wallet) {
    // Direct wallet deduction
    final walletService = WalletService();
    await walletService.transfer(
      amount: totalAmount,
      toAccountId: 'events_pool',
      reference: order.data['payment_reference'],
    );
  }

  // 3. Confirm payment on backend
  final result = await _dio.post('/tickets/confirm-payment', data: {
    'order_id': order.data['order_id'],
    'payment_reference': paymentReference,
  });

  return TicketPurchaseResult.fromJson(result.data);
}
```

### 11.2 Supported Payment Methods

| Method | Provider | Implementation |
|--------|----------|----------------|
| **M-Pesa** | ClickPesa / Azampay | `WalletService.deposit()` with STK push |
| **Tigo Pesa** | ClickPesa / Azampay | `WalletService.deposit()` |
| **Airtel Money** | ClickPesa / Azampay | `WalletService.deposit()` |
| **Halo Pesa** | ClickPesa / Azampay | `WalletService.deposit()` |
| **TAJIRI Wallet** | Internal | Direct wallet-to-wallet transfer |
| **Credit/Debit Card** | Stripe | Card payment form |
| **Apple Pay / Google Pay** | Stripe | Platform native pay sheet |

### 11.3 Organizer Payouts

```
Event revenue → Platform holds in escrow
  → After event completes (or on organizer request)
  → Organizer requests payout via POST /events/{id}/payout
  → Funds sent to organizer's M-Pesa, bank, or TAJIRI Wallet
  → Platform takes commission (e.g., 5% of ticket sales)
```

### 11.4 Harambee / Fundraiser Events

For community contribution events, integrate with `ContributionService` (Michango module):

```dart
// Create a Harambee event that links to a Michango campaign
final event = await eventService.createEvent(
  category: EventCategory.harambee,
  linkedCampaignId: campaign.id,  // links to ContributionService campaign
);
```

The event page shows campaign progress bar, donation button (via `ContributionService.contributeToCampaign()`), and contributor list.

---

## 12. Social Features

### 12.1 RSVP System

Three-state RSVP with guest support:

```dart
// RSVP Button states:
// 1. Not responded → show all 3 options
// 2. Going → green filled, tap to change
// 3. Interested → outline, tap to change
// 4. Not Going → dimmed

// With +1 support
await eventService.respondToEvent(
  eventId: event.id,
  status: RSVPStatus.going,
  guestCount: 2,                    // +2 guests
  guestNames: ['Amina', 'John'],    // optional guest names
);
```

### 12.2 "Friends Going" — Social Proof

The most important social feature. On every event card and detail page:

```dart
// Leverages FriendService
Future<List<EventAttendee>> getFriendsAttending(int eventId) async {
  final response = await _dio.get('/events/$eventId/friends-attending');
  // Backend cross-references event attendees with user's friend list
  // Returns: [{user_id, first_name, avatar_url, rsvp_status}]
}
```

**Display:** `FriendAvatarStack` widget — 3-4 overlapping circular avatars + "Amina, John na 12 wengine / and 12 others"

### 12.3 Event Wall (Partiful-style)

A social feed embedded within each event page. Attendees can post text, photos, polls, and announcements (hosts only).

- Hosts can pin important posts (venue change, schedule update)
- Attendees can post photos from the event (crowdsourced album)
- Comment thread below each wall post
- Emoji reactions
- Real-time updates via `LiveUpdateService` (Firestore listener)

### 12.4 Sharing

Reuse the existing `share_post_sheet.dart` pattern adapted for events:

| Channel | Implementation |
|---------|----------------|
| **WhatsApp** | `url_launcher` with `whatsapp://send?text=` + deep link |
| **SMS** | `url_launcher` with `sms:?body=` + deep link |
| **Copy Link** | Clipboard + snackbar confirmation |
| **TAJIRI DM** | Open compose message with event link |
| **Instagram Story** | Share event cover image to IG Stories |
| **Twitter/X** | `url_launcher` with `twitter://post?message=` |
| **Facebook** | `url_launcher` with share dialog |

Deep link format: `https://tajiri.app/events/{slug}`

### 12.5 Invite System

```dart
// Invite from TAJIRI friends
await eventService.inviteFriends(
  eventId: event.id,
  userIds: [101, 102, 103],
);
// → Push notification to each: "Amina amekualika kwa tukio / Amina invited you"

// Invite by phone (SMS)
await eventService.inviteByPhone(
  eventId: event.id,
  phoneNumbers: ['+255712345678', '+255623456789'],
);
// → SMS sent: "Umealikwa kwa tukio: Tech Meetup — tajiri.app/events/tech-meetup"
```

### 12.6 Follow Organizer

Users can follow event organizers to get notified of new events:

```dart
// Reuse existing follow mechanism from FriendService
await friendService.followUser(userId: organizer.id);
// Push notification when organizer creates new event
```

### 12.7 Post-Event Reviews

After event ends, attendees who were "Going" can leave reviews:

- 1-5 star rating
- Text review
- Photo uploads
- Reviews appear on event page and organizer profile
- Average rating shown on organizer's future events

---

## 13. Communication & Notifications

### 13.1 FCM Integration

Add event-specific notification channels to `FcmService`:

```dart
// New channels to add in fcm_service.dart
const eventChannel = AndroidNotificationChannel(
  'events', 'Matukio / Events',
  importance: Importance.high,
);
const eventRemindersChannel = AndroidNotificationChannel(
  'event_reminders', 'Vikumbusho / Reminders',
  importance: Importance.high,
);
```

### 13.2 Notification Types

| Notification | Trigger | Channel | FCM Payload Route |
|---|---|---|---|
| Event invitation | Someone invites you | events | → Event detail page |
| RSVP update | Friend RSVPs to event you're attending | events | → Event detail page |
| Event reminder | 1 day, 1 hour, 15 min before | event_reminders | → Event detail page |
| Host announcement | Host posts announcement | events | → Event wall |
| Event update | Time/venue/cancel change | events | → Event detail page |
| Ticket confirmation | Purchase complete | events | → Ticket detail page |
| Waitlist offer | Spot opened up | events | → Ticket purchase page |
| New comment | Someone comments on event you're attending | social | → Event wall |
| Photo tagged | Someone tags you in event photo | social | → Event photos |
| Review request | Event ended, please review | events | → Review form |
| New event from followed | Organizer you follow created event | events | → Event detail page |

### 13.3 LiveUpdateService Integration

Add `EventUpdateEvent` to the existing sealed class hierarchy in `LiveUpdateService`:

```dart
// Add to lib/services/live_update_service.dart
class EventUpdateEvent extends LiveUpdateEvent {
  final int eventId;
  final String updateType; // rsvp, comment, wall_post, announcement, cancel, update
  EventUpdateEvent({required this.eventId, required this.updateType, required super.timestamp});
}
```

Screens listen:
```dart
LiveUpdateService.instance.stream.listen((event) {
  if (event is EventUpdateEvent && event.eventId == _currentEventId) {
    _refreshEventData();
  }
});
```

### 13.4 Event Group Chat

Auto-create a group conversation for events with 5+ attendees:

```dart
// On RSVP "Going" with enough participants:
final messageService = MessageService();
final conversation = await messageService.createGroup(
  name: 'Tech Meetup — Chat',
  memberIds: goingAttendeeIds,
  type: 'event_chat',
  referenceId: event.id, // links to event
);
```

---

## 14. Media & Content

### 14.1 Cover Image Upload

```dart
// Use PhotoService pattern for event cover
Future<String> uploadCoverPhoto(String filePath) async {
  final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/events/upload-cover'));
  request.files.add(await http.MultipartFile.fromPath('cover', filePath));
  // Returns URL of uploaded cover
}
```

### 14.2 Gallery

Multiple photos for event page:
- Organizer uploads during creation (Step 4)
- Attendees upload photos to event wall (crowdsourced)
- All photos viewable in dedicated photo album page
- Uses existing `PhotoService` upload pattern

### 14.3 Video Trailer

Optional promotional video:
- Upload via `VideoUploadService` (with progress)
- For large videos, use `ResumableUploadService` (chunked, pausable)
- Plays inline on event detail page
- Thumbnail auto-generated by backend

### 14.4 Live Streaming

For virtual/hybrid events, integrate with existing `LivestreamService`:

```dart
// Create a live stream linked to event
final stream = await livestreamService.createStream(
  title: event.name,
  eventId: event.id,
  scheduledAt: event.startDate,
);
// Stream viewer embedded in virtual_event_page.dart
```

### 14.5 Event Stories

Share events as TAJIRI Stories:
```dart
// Use existing StoryService
await storyService.createStory(
  type: 'event_share',
  eventId: event.id,
  coverUrl: event.coverPhotoUrl,
);
```

---

## 15. Calendar Integration

### 15.1 Personal Calendar Sync

When a user RSVPs "Going," sync to their TAJIRI calendar (existing `lib/calendar/` module):

```dart
// After RSVP "Going"
final calendarService = CalendarService();
await calendarService.createEvent(CalendarEvent(
  title: event.name,
  startDate: event.startDate,
  endDate: event.endDate,
  location: event.locationName,
  description: 'Event on TAJIRI: tajiri.app/events/${event.slug}',
));
```

### 15.2 External Calendar Export

"Add to Calendar" button generates:
- **Google Calendar:** URL scheme `https://calendar.google.com/calendar/r/eventedit?text=...&dates=...&location=...`
- **Apple Calendar:** `.ics` file opened via `url_launcher`
- **Outlook:** `.ics` file or web URL

### 15.3 Calendar View Page

`event_calendar_page.dart` — Monthly calendar showing:
- Events user is "Going" to (solid dot)
- Events user is "Interested" in (outline dot)
- Saved events (bookmark icon)
- Tapping a day shows list of events for that day

---

## 16. Maps & Location

### 16.1 Location Picker (Create Event)

Two modes:
1. **Tanzania hierarchy** — Region → District → Ward → Street (via existing `LocationService`)
2. **Map pin** — Interactive map where user drops a pin (Google Maps / OpenStreetMap)

```dart
// Reuse existing location_picker.dart widget
// Enhanced with map view for lat/lng selection
```

### 16.2 Venue Display (Event Detail)

- Mini static map showing venue pin
- Tappable → opens full `event_map_page.dart`
- "Get Directions" → opens Google Maps / Apple Maps via `url_launcher`
- "Get a Ride" → opens Uber / Bolt app with destination pre-filled

### 16.3 Map View (Browse Events)

`event_map_page.dart` — Full-screen map showing events as pins:
- Clustered pins for dense areas
- Tapping pin shows mini event card
- Tapping card opens event detail
- User location shown as blue dot
- Radius filter slider

---

## 17. Organizer Tools

### 17.1 Organizer Dashboard

```
┌─────────────────────────────────────────┐
│ ← Dashboard — Tech Meetup              │
├─────────────────────────────────────────┤
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │  234   │ │  156   │ │  78    │      │
│  │ Views  │ │ Going  │ │ Tickets│      │  Key metrics
│  └────────┘ └────────┘ └────────┘      │
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │ TZS 3.9M│ │ 67%   │ │  45   │      │
│  │ Revenue │ │CheckIn│ │ Shares │      │
│  └────────┘ └────────┘ └────────┘      │
│                                         │
│  ── Sales Chart ──                      │
│  [Line chart: daily ticket sales]       │
│                                         │
│  ── Traffic Sources ──                  │
│  WhatsApp: 45%  ██████████             │
│  Direct:   30%  ██████                 │
│  Link:     15%  ███                    │
│  Other:    10%  ██                     │
│                                         │
│  ── Quick Actions ──                    │
│  [📣 Announce] [📊 Report] [✅ Check-In] │
│  [👥 Attendees] [🎫 Tickets] [👔 Team]  │
│                                         │
│  ── Recent Sales ──                     │
│  Amina M. — VIP — TZS 50,000 — M-Pesa │
│  John D. — General — TZS 15,000       │
│  ...                                    │
└─────────────────────────────────────────┘
```

### 17.2 QR Check-In Scanner

`qr_scanner_page.dart` — Camera-based QR scanner for door staff:

```dart
// Uses mobile_scanner package (already in pubspec for other features)
// Scans QR → POST /tickets/check-in
// Shows: ✅ Valid (green) / ❌ Invalid (red) / ⚠️ Already used (yellow)
// Displays: attendee name, tier, guest count
// Offline mode: validates against cached ticket list
```

### 17.3 Team Roles

| Role | Permissions |
|------|-------------|
| **Host** | Full control — edit, cancel, payout, all below |
| **Co-Host** | Edit event details, post announcements, manage attendees |
| **Manager** | View analytics, manage check-in, send announcements |
| **Door Staff** | QR scanner check-in only |
| **Volunteer** | View attendee list, check-in |

### 17.4 Announcement Broadcast

```dart
// Organizer sends announcement to all attendees
await organizerService.sendAnnouncement(
  eventId: event.id,
  message: 'Milango yanafunguka saa 11! / Doors open at 17:00!',
  channel: AnnouncementChannel.push,  // or .sms, .whatsapp, .all
);
// → Push notification to all "Going" attendees
// → Wall post auto-created and pinned
```

---

## 18. Virtual & Hybrid Events

### 18.1 Virtual Event Page

`virtual_event_page.dart` — For online events:

```
┌─────────────────────────────────────────┐
│ Tech Meetup — Virtual        [🔴 Live]  │
├─────────────────────────────────────────┤
│                                         │
│  ┌────────────────────────────────────┐ │
│  │                                    │ │
│  │     [Live Stream / Video Feed]     │ │  Zego SDK or external embed
│  │                                    │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ── Live Chat ──                        │
│  👤 Amina: Great presentation! 🔥      │  Uses MessageService
│  👤 John: Can you share the slides?    │
│  [Type a message...]                    │
│                                         │
│  ── Q&A ──                              │
│  ▲ 12  How does this scale?  — Sara    │  Upvote Q&A
│  ▲ 8   What stack do you use? — Mike   │
│  [Ask a question...]                    │
│                                         │
│  ── Attendees (156 watching) ──         │
│  👤👤👤👤👤 + 151 more                  │
│                                         │
├─────────────────────────────────────────┤
│  [Schedule] [Speakers] [Resources]      │  Bottom tabs
└─────────────────────────────────────────┘
```

### 18.2 Hybrid Support

For hybrid events, the event detail page shows both:
- Physical location info (map, address, directions)
- Virtual link / embedded stream
- Attendees tagged as "In-person" or "Virtual"
- Chat shared between physical and virtual attendees

---

## 19. Offline Support & Caching

### 19.1 Cache Strategy

| Data | Storage | TTL | Trigger |
|------|---------|-----|---------|
| Event feed | Hive (`EventCacheService`) | 15 min | On app open, pull-to-refresh |
| Event detail | Hive | 30 min | On view, on RSVP |
| My tickets | Hive | 1 hour | On purchase, on view |
| Ticket QR codes | Hive (encrypted) | Cached permanently | On purchase, refresh every 25s when viewed |
| Saved events | Hive | 30 min | On save/unsave |
| Event photos | `MediaCacheService` (flutter_cache_manager) | 30 days | On view |
| Cover images | `MediaCacheService` | 30 days | On view |
| Search history | Hive | Permanent | On search |

### 19.2 Offline Ticket Display

Tickets work offline — critical for venue entry at poor-connectivity locations:

```dart
// Cache ticket data + last 3 QR codes
await eventCacheService.cacheTicketQR(
  ticketId: ticket.id,
  qrData: latestQR,
);

// Offline display:
// 1. Show ticket details from cache
// 2. Show most recent cached QR code
// 3. Display "Offline — QR may not rotate" warning
// 4. Door staff can use manual check-in as fallback
```

### 19.3 Background Refresh

Follow `BackgroundSyncService` pattern:
- Refresh event feed every 15 minutes in background
- Refresh ticket QR codes when app is in foreground and ticket is viewed
- Prefetch upcoming event details when on WiFi

---

## 20. East Africa Localization

### 20.1 Swahili-First UI Strings

All labels in Swahili (primary) with English (subtitle/secondary):

```dart
// Pattern matching existing AppStrings class
class EventStrings {
  final bool isSwahili;

  // ── Navigation ──
  String get events => isSwahili ? 'Matukio' : 'Events';
  String get myEvents => isSwahili ? 'Matukio Yangu' : 'My Events';
  String get myTickets => isSwahili ? 'Tiketi Zangu' : 'My Tickets';
  String get browseEvents => isSwahili ? 'Tafuta Matukio' : 'Browse Events';
  String get createEvent => isSwahili ? 'Unda Tukio' : 'Create Event';

  // ── RSVP ──
  String get going => isSwahili ? 'Nahudhuria' : 'Going';
  String get interested => isSwahili ? 'Napendezwa' : 'Interested';
  String get notGoing => isSwahili ? 'Sihudhuri' : 'Not Going';

  // ── Ticketing ──
  String get getTickets => isSwahili ? 'Pata Tiketi' : 'Get Tickets';
  String get buyTicket => isSwahili ? 'Nunua Tiketi' : 'Buy Ticket';
  String get free => isSwahili ? 'Bure' : 'Free';
  String get soldOut => isSwahili ? 'Tiketi Zimeisha' : 'Sold Out';
  String get joinWaitlist => isSwahili ? 'Jiunge na Orodha ya Kusubiri' : 'Join Waitlist';

  // ── Social ──
  String get friendsGoing => isSwahili ? 'Marafiki wanahudhuria' : 'Friends going';
  String get invite => isSwahili ? 'Alika' : 'Invite';
  String get share => isSwahili ? 'Shiriki' : 'Share';
  String get save => isSwahili ? 'Hifadhi' : 'Save';

  // ── Event types ──
  String get inPerson => isSwahili ? 'Ana kwa Ana' : 'In Person';
  String get virtual => isSwahili ? 'Mtandaoni' : 'Virtual';
  String get hybrid => isSwahili ? 'Mseto' : 'Hybrid';

  // ── Date/Time Swahili ──
  List<String> get swahiliDays => ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
  List<String> get swahiliMonths => ['Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni', 'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'];
}
```

### 20.2 Cultural Event Categories

```dart
// East Africa-specific categories with icons
EventCategory.harusi    → 💍 Harusi / Wedding
EventCategory.msiba     → 🕯️ Msiba / Memorial
EventCategory.harambee  → 🤝 Harambee / Fundraiser
EventCategory.ibada     → ⛪ Ibada / Worship
EventCategory.sherehe   → 🎉 Sherehe / Celebration
EventCategory.ngoma     → 🥁 Ngoma / Traditional Dance
EventCategory.bongoFlava→ 🎵 Bongo Flava / Local Music
EventCategory.gospel    → 🎤 Gospel
EventCategory.michezo   → ⚽ Michezo / Local Sports
EventCategory.maonyesho → 🎪 Maonyesho / Exhibition
```

### 20.3 Currency Formatting

```dart
String formatPrice(double amount, String currency) {
  final formatted = amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '$currency $formatted'; // "TZS 50,000" or "KES 1,500"
}
```

### 20.4 Date Formatting (Swahili)

```dart
String formatDateSwahili(DateTime date) {
  final days = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
  final months = ['Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni', 'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'];
  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  // "Jumamosi, 12 Aprili 2026"
}
```

---

## 21. File Structure

```
lib/events/
├── events_module.dart                    ── Module entry point
│
├── models/
│   ├── event.dart                        ── Event model (canonical)
│   ├── event_ticket.dart                 ── EventTicket, TicketTier, TicketAddon
│   ├── event_rsvp.dart                   ── EventRSVP, EventAttendee, RSVPStatus
│   ├── event_wall.dart                   ── EventComment, EventWallPost
│   ├── event_session.dart                ── EventSession, EventSpeaker, EventSponsor
│   ├── event_review.dart                 ── EventReview
│   ├── event_analytics.dart              ── EventAnalytics, SalesReport, DailyMetric
│   ├── promo_code.dart                   ── PromoCode, PromoValidation
│   ├── waitlist.dart                     ── WaitlistEntry
│   ├── signup_list.dart                  ── SignupList, SignupItem
│   ├── recurrence_rule.dart              ── RecurrenceRule, RecurrenceFrequency
│   ├── event_enums.dart                  ── EventStatus, EventType, EventPrivacy, EventCategory, RefundPolicy
│   └── event_strings.dart                ── EventStrings (Swahili + English)
│
├── services/
│   ├── event_service.dart                ── Core CRUD, feed, RSVP, search, invites
│   ├── ticket_service.dart               ── Purchase, transfer, QR, waitlist, promo codes, check-in
│   ├── event_wall_service.dart           ── Wall posts, comments, photos, reviews
│   ├── event_organizer_service.dart      ── Analytics, attendees, team, announcements, surveys, payouts
│   └── event_cache_service.dart          ── Hive-based offline caching
│
├── pages/
│   ├── events_home_page.dart             ── Personalized feed with tabs (For You, Friends, Nearby, Calendar)
│   ├── browse_events_page.dart           ── Search + filters + category browsing
│   ├── my_events_page.dart               ── Events I'm hosting + attending + saved
│   ├── event_detail_page.dart            ── Full event detail with RSVP, social, tickets
│   ├── create_event_page.dart            ── Multi-step creation wizard (7 steps)
│   ├── edit_event_page.dart              ── Edit existing event
│   ├── ticket_purchase_page.dart         ── Tier selection + payment flow
│   ├── my_tickets_page.dart              ── All purchased tickets
│   ├── ticket_detail_page.dart           ── Single ticket with rotating QR
│   ├── event_wall_page.dart              ── Social feed within event
│   ├── event_photos_page.dart            ── Crowdsourced photo album
│   ├── event_attendees_page.dart         ── Full attendee list
│   ├── event_reviews_page.dart           ── Post-event reviews
│   ├── event_agenda_page.dart            ── Multi-session schedule
│   ├── event_map_page.dart               ── Map view of event + nearby events
│   ├── event_calendar_page.dart          ── Calendar view of saved/RSVPed events
│   ├── event_search_page.dart            ── Dedicated search with autocomplete
│   ├── event_invite_page.dart            ── Invite friends + phone contacts
│   ├── signup_list_page.dart             ── Potluck / who's bringing what
│   ├── qr_scanner_page.dart              ── QR check-in scanner (organizer)
│   ├── organizer/
│   │   ├── organizer_dashboard_page.dart
│   │   ├── attendee_management_page.dart
│   │   ├── ticket_management_page.dart
│   │   ├── team_management_page.dart
│   │   ├── announcement_page.dart
│   │   ├── sales_report_page.dart
│   │   ├── survey_builder_page.dart
│   │   └── payout_page.dart
│   └── virtual/
│       └── virtual_event_page.dart       ── Virtual event lobby (stream, chat, Q&A)
│
└── widgets/
    ├── event_card.dart                   ── Event list item (image, date, friends going, RSVP)
    ├── event_card_compact.dart           ── Small card for horizontal scrolls
    ├── ticket_card.dart                  ── Ticket row with QR icon + status
    ├── ticket_tier_card.dart             ── Tier selection in purchase flow
    ├── attendee_pill.dart                ── Small avatar + name chip
    ├── friend_avatar_stack.dart          ── Overlapping friend avatars + count
    ├── sponsor_card.dart                 ── Sponsor logo + tier badge
    ├── speaker_card.dart                 ── Speaker avatar + name + title
    ├── session_card.dart                 ── Agenda session item
    ├── review_card.dart                  ── Star rating + review text
    ├── wall_post_card.dart               ── Event wall post
    ├── signup_item_card.dart             ── Potluck item with claim button
    ├── happening_now_banner.dart         ── Red pulsing "Live" banner
    ├── rsvp_button.dart                  ── 3-state RSVP (Going/Interested/Not Going)
    ├── rsvp_button_inline.dart           ── Compact RSVP for cards
    ├── countdown_timer.dart              ── Countdown to event start
    ├── category_chip.dart                ── Category icon + bilingual label
    ├── filter_chip_row.dart              ── Horizontal scrollable filters
    ├── price_tag.dart                    ── "Bure / Free" or "TZS 15,000"
    ├── event_status_badge.dart           ── Draft / Published / Cancelled
    ├── ticket_status_badge.dart          ── Active / Used / Transferred
    ├── promo_code_field.dart             ── Input + validate + status
    ├── quantity_selector.dart            ── [−] N [+] stepper
    ├── payment_method_selector.dart      ── M-Pesa / Tigo / Wallet / Card
    ├── event_share_sheet.dart            ── Share via WhatsApp, SMS, link
    ├── event_invite_sheet.dart           ── Invite friends bottom sheet
    ├── event_filter_sheet.dart           ── Browse filter bottom sheet
    ├── event_sort_sheet.dart             ── Sort options bottom sheet
    ├── event_actions_sheet.dart          ── Report, save, share, calendar
    ├── event_map_preview.dart            ── Mini map with venue pin
    ├── event_cover_hero.dart             ── Hero image with gradient overlay
    ├── event_gallery_grid.dart           ── Photo grid for gallery
    ├── no_events_placeholder.dart        ── Empty state illustration
    └── no_tickets_placeholder.dart       ── Empty state illustration
```

**Total: ~65 files** (13 models, 5 services, 30 pages, 35 widgets)

---

## 22. Phased Implementation Plan

### Phase 1 — Foundation (Core CRUD + RSVP + Basic UI)

**Goal:** Replace current 10-file module with properly architected foundation.

| # | Task | Files |
|---|------|-------|
| 1 | Models: Event, EventTicket, EventRSVP, EventCategory enums | `models/*.dart` (6 files) |
| 2 | EventService with AuthenticatedDio (CRUD + feed + RSVP) | `services/event_service.dart` |
| 3 | EventCacheService (Hive-based) | `services/event_cache_service.dart` |
| 4 | Events Home Page (personalized feed, For You tab) | `pages/events_home_page.dart` |
| 5 | Event Detail Page (full detail, RSVP buttons, friends going) | `pages/event_detail_page.dart` |
| 6 | Create Event Page (multi-step wizard, cover upload) | `pages/create_event_page.dart` |
| 7 | Browse Events Page (search, category filter, date filter) | `pages/browse_events_page.dart` |
| 8 | Core Widgets (EventCard, RSVPButton, CategoryChip, FriendAvatarStack) | `widgets/*.dart` (8 files) |
| 9 | EventStrings (Swahili + English) | `models/event_strings.dart` |
| 10 | Route registration in main.dart | Update `lib/main.dart` |

**Deliverable:** Working event browsing, creation, and RSVP — auth-protected, cached, bilingual.

---

### Phase 2 — Ticketing + Payments

**Goal:** Full ticketing system with M-Pesa payment.

| # | Task | Files |
|---|------|-------|
| 1 | Models: TicketTier, PromoCode, Waitlist | `models/*.dart` (3 files) |
| 2 | TicketService (purchase, transfer, QR, promo, waitlist) | `services/ticket_service.dart` |
| 3 | Ticket Purchase Page (tier select, promo, payment) | `pages/ticket_purchase_page.dart` |
| 4 | My Tickets Page (all tickets, filter) | `pages/my_tickets_page.dart` |
| 5 | Ticket Detail Page (rotating QR, status, transfer) | `pages/ticket_detail_page.dart` |
| 6 | Payment integration with WalletService | Integrate with `lib/services/wallet_service.dart` |
| 7 | Widgets: TicketTierCard, PromoCodeField, PaymentMethodSelector, QuantitySelector | `widgets/*.dart` (4 files) |
| 8 | Offline ticket QR caching | Update `event_cache_service.dart` |

**Deliverable:** End-to-end ticket purchase with M-Pesa, QR code tickets, offline support.

---

### Phase 3 — Social Features

**Goal:** Make events deeply social — the key differentiator.

| # | Task | Files |
|---|------|-------|
| 1 | Models: EventComment, EventWallPost, EventReview | `models/*.dart` (2 files) |
| 2 | EventWallService (wall posts, comments, photos, reviews) | `services/event_wall_service.dart` |
| 3 | Event Wall Page (Partiful-style social feed) | `pages/event_wall_page.dart` |
| 4 | Event Photos Page (crowdsourced album) | `pages/event_photos_page.dart` |
| 5 | Event Attendees Page (full list, friends filter) | `pages/event_attendees_page.dart` |
| 6 | Event Reviews Page (post-event ratings) | `pages/event_reviews_page.dart` |
| 7 | Event Invite Page (TAJIRI friends + phone contacts) | `pages/event_invite_page.dart` |
| 8 | Share Sheet (WhatsApp, SMS, copy link, DM) | `widgets/event_share_sheet.dart` |
| 9 | LiveUpdateService integration (real-time wall updates) | Update `lib/services/live_update_service.dart` |
| 10 | FCM notification types for events | Update `lib/services/fcm_service.dart` |
| 11 | Widgets: WallPostCard, ReviewCard, AttendeePill, InviteSheet | `widgets/*.dart` (4 files) |

**Deliverable:** Social event experience — wall, comments, photos, reviews, sharing, invites, real-time.

---

### Phase 4 — Discovery & Search

**Goal:** Smart event discovery powered by social graph and location.

| # | Task | Files |
|---|------|-------|
| 1 | Event Search Page (autocomplete, history, trending) | `pages/event_search_page.dart` |
| 2 | Event Map Page (nearby events on map, clustering) | `pages/event_map_page.dart` |
| 3 | Event Calendar Page (monthly view of RSVPed/saved) | `pages/event_calendar_page.dart` |
| 4 | Friends tab in home page | Update `pages/events_home_page.dart` |
| 5 | Nearby tab in home page | Update `pages/events_home_page.dart` |
| 6 | Trending events section | Update `pages/events_home_page.dart` |
| 7 | "Happening Now" banner | `widgets/happening_now_banner.dart` |
| 8 | Filter/Sort sheets | `widgets/event_filter_sheet.dart`, `event_sort_sheet.dart` |
| 9 | Calendar external export (Google, Apple, Outlook) | Calendar integration logic |
| 10 | Map widgets | `widgets/event_map_preview.dart`, `event_map_cluster.dart` |

**Deliverable:** Multi-faceted discovery — feed, search, map, calendar, friends, nearby, trending.

---

### Phase 5 — Organizer Tools

**Goal:** Professional event management dashboard.

| # | Task | Files |
|---|------|-------|
| 1 | Models: EventAnalytics, SalesReport, TeamMember | `models/event_analytics.dart` |
| 2 | EventOrganizerService | `services/event_organizer_service.dart` |
| 3 | Organizer Dashboard Page | `pages/organizer/organizer_dashboard_page.dart` |
| 4 | Attendee Management Page | `pages/organizer/attendee_management_page.dart` |
| 5 | Ticket Management Page (tiers, promo codes) | `pages/organizer/ticket_management_page.dart` |
| 6 | QR Scanner Page (check-in) | `pages/qr_scanner_page.dart` |
| 7 | Sales Report Page | `pages/organizer/sales_report_page.dart` |
| 8 | Team Management Page | `pages/organizer/team_management_page.dart` |
| 9 | Announcement Page | `pages/organizer/announcement_page.dart` |
| 10 | Payout Page | `pages/organizer/payout_page.dart` |
| 11 | Edit Event Page | `pages/edit_event_page.dart` |

**Deliverable:** Full organizer toolkit — analytics, check-in, team, announcements, payouts.

---

### Phase 6 — Advanced Features

**Goal:** Polish and differentiation features.

| # | Task | Files |
|---|------|-------|
| 1 | Models: SignupList, RecurrenceRule | `models/*.dart` (2 files) |
| 2 | My Events Page (hosting + attending + saved tabs) | `pages/my_events_page.dart` |
| 3 | Signup List Page (potluck) | `pages/signup_list_page.dart` |
| 4 | Event Agenda Page (multi-session schedule) | `pages/event_agenda_page.dart` |
| 5 | Survey Builder Page | `pages/organizer/survey_builder_page.dart` |
| 6 | Recurring events support | Update create/edit flows |
| 7 | Event duplication | Update EventService |
| 8 | Harambee/fundraiser integration with Michango | Link ContributionService |
| 9 | Event group chat (auto-create via MessageService) | Integration logic |
| 10 | Virtual Event Page (stream + chat + Q&A) | `pages/virtual/virtual_event_page.dart` |
| 11 | Countdown timer widget | `widgets/countdown_timer.dart` |
| 12 | Remaining widgets and polish | Various `widgets/*.dart` |

**Deliverable:** Complete feature set — agenda, surveys, recurring, virtual events, Harambee integration.

---

## 23. Backend API Contract

### 23.1 Response Format

All endpoints follow the standard TAJIRI response wrapper:

```json
{
  "success": true,
  "data": { ... },
  "message": "Tukio limeundwa / Event created",
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 20,
    "total": 93
  }
}
```

### 23.2 Event Create/Update Payload

```json
POST /api/events
Content-Type: multipart/form-data

{
  "name": "Tech Meetup Dar es Salaam",
  "description": "Join us for an evening of...",
  "category": "tech",
  "type": "in_person",
  "privacy": "public",
  "start_date": "2026-04-12",
  "end_date": "2026-04-12",
  "start_time": "18:00",
  "end_time": "22:00",
  "timezone": "Africa/Dar_es_Salaam",
  "is_all_day": false,
  "location_name": "Hyatt Regency",
  "location_address": "Kivukoni, Dar es Salaam",
  "latitude": -6.8235,
  "longitude": 39.2695,
  "region_id": 1,
  "district_id": 3,
  "is_online": false,
  "online_link": null,
  "is_free": false,
  "ticket_currency": "TZS",
  "has_waitlist": true,
  "refund_policy": "full_refund",
  "group_id": null,
  "co_host_ids": [42, 67],
  "tags": ["tech", "daressalaam", "meetup"],
  "cover": <file>,
  "gallery[]": [<file>, <file>]
}
```

### 23.3 Event Detail Response

```json
GET /api/events/123

{
  "success": true,
  "data": {
    "id": 123,
    "name": "Tech Meetup Dar es Salaam",
    "slug": "tech-meetup-dar-es-salaam",
    "description": "...",
    "status": "published",
    "type": "in_person",
    "privacy": "public",
    "category": "tech",

    "start_date": "2026-04-12",
    "end_date": "2026-04-12",
    "start_time": "18:00",
    "end_time": "22:00",
    "timezone": "Africa/Dar_es_Salaam",
    "is_all_day": false,
    "is_recurring": false,

    "location_name": "Hyatt Regency",
    "location_address": "Kivukoni, Dar es Salaam",
    "latitude": -6.8235,
    "longitude": 39.2695,
    "is_online": false,

    "cover_photo_url": "https://tajiri.zimasystems.com/storage/events/123/cover.jpg",
    "gallery_urls": ["...", "..."],

    "creator_id": 42,
    "creator": {
      "id": 42,
      "first_name": "John",
      "last_name": "Doe",
      "username": "john_doe",
      "profile_photo_url": "..."
    },
    "co_hosts": [
      { "id": 67, "first_name": "Amina", "last_name": "Mohamed", "profile_photo_url": "..." }
    ],

    "is_free": false,
    "ticket_currency": "TZS",
    "ticket_tiers": [
      {
        "id": 1,
        "name": "General",
        "price": 15000,
        "total_quantity": 100,
        "sold_quantity": 66,
        "sale_start_date": null,
        "sale_end_date": null,
        "max_per_order": 5,
        "is_transferable": true,
        "addons": [
          { "id": 1, "name": "Parking", "price": 5000 }
        ]
      },
      {
        "id": 2,
        "name": "VIP",
        "price": 50000,
        "total_quantity": 20,
        "sold_quantity": 12,
        "max_per_order": 2,
        "is_transferable": false,
        "addons": []
      }
    ],
    "has_waitlist": true,
    "refund_policy": "full_refund",

    "going_count": 78,
    "interested_count": 156,
    "not_going_count": 12,
    "comments_count": 34,
    "shares_count": 45,
    "views_count": 1234,

    "user_response": "going",
    "is_host": false,
    "is_co_host": false,
    "has_purchased_ticket": true,
    "is_saved": true,

    "friends_going": [
      { "user_id": 101, "first_name": "Amina", "avatar_url": "...", "rsvp_status": "going" },
      { "user_id": 102, "first_name": "Sara", "avatar_url": "...", "rsvp_status": "interested" }
    ],
    "friends_going_count": 5,

    "sessions": [],
    "speakers": [],
    "sponsors": [],
    "tags": ["tech", "daressalaam"],

    "created_at": "2026-03-15T10:00:00Z",
    "published_at": "2026-03-15T12:00:00Z"
  }
}
```

### 23.4 Ticket Purchase Response

```json
POST /api/events/123/tickets/purchase

Request:
{
  "tier_id": 2,
  "quantity": 2,
  "payment_method": "mpesa",
  "phone_number": "0712345678",
  "promo_code": "EARLY20",
  "guests": [
    { "name": "Amina Mohamed", "phone": "0723456789" }
  ]
}

Response:
{
  "success": true,
  "data": {
    "order_id": "ORD-2026-00456",
    "tickets": [
      {
        "id": 789,
        "ticket_number": "TKT-TECH-00789",
        "tier": { "id": 2, "name": "VIP" },
        "qr_code_data": "eyJ0...",
        "status": "active",
        "price_paid": 40000,
        "currency": "TZS",
        "payment_method": "mpesa",
        "payment_reference": "MPESA-REF-123456"
      },
      {
        "id": 790,
        "ticket_number": "TKT-TECH-00790",
        "tier": { "id": 2, "name": "VIP" },
        "qr_code_data": "eyJ1...",
        "status": "active",
        "price_paid": 40000,
        "guest_name": "Amina Mohamed"
      }
    ],
    "total_paid": 80000,
    "discount_applied": 20000,
    "promo_code_used": "EARLY20"
  },
  "message": "Tiketi zimenunuliwa! / Tickets purchased!"
}
```

---

> **This document serves as the single source of truth for the TAJIRI Events module rebuild.** Every feature references existing TAJIRI infrastructure to maximize code reuse and minimize development time. Implementation follows the 6-phase plan, with Phase 1 delivering a working MVP and each subsequent phase adding a complete feature layer.
