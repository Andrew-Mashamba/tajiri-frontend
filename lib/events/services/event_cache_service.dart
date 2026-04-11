// lib/events/services/event_cache_service.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';
import '../models/event_ticket.dart';

class EventCacheService {
  static final EventCacheService _instance = EventCacheService._();
  static EventCacheService get instance => _instance;
  EventCacheService._();

  static const String _eventsBoxName = 'events_cache';
  static const String _ticketsBoxName = 'tickets_cache';
  static const String _metaBoxName = 'events_meta';

  Box? _eventsBox;
  Box? _ticketsBox;
  Box? _metaBox;

  Future<void> init() async {
    _eventsBox ??= await Hive.openBox(_eventsBoxName);
    _ticketsBox ??= await Hive.openBox(_ticketsBoxName);
    _metaBox ??= await Hive.openBox(_metaBoxName);
  }

  Future<void> _ensureInit() async {
    if (_eventsBox == null || !_eventsBox!.isOpen) await init();
  }

  // ── Event Lists ──

  Future<void> cacheEvents({required String key, required List<Event> events}) async {
    await _ensureInit();
    final jsonList = events.map((e) => e.toJson()).toList();
    await _eventsBox!.put(key, jsonEncode(jsonList));
    await _metaBox!.put('${key}_time', DateTime.now().toIso8601String());
  }

  Future<List<Event>?> getCachedEvents({required String key}) async {
    await _ensureInit();
    final raw = _eventsBox!.get(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Event.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> getLastFetchTime({required String key}) async {
    await _ensureInit();
    final raw = _metaBox!.get('${key}_time');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool isStale({required String key, Duration threshold = const Duration(minutes: 15)}) {
    final raw = _metaBox?.get('${key}_time');
    if (raw == null) return true;
    final lastFetch = DateTime.tryParse(raw);
    if (lastFetch == null) return true;
    return DateTime.now().difference(lastFetch) > threshold;
  }

  // ── Single Event ──

  Future<void> cacheEvent({required Event event}) async {
    await _ensureInit();
    await _eventsBox!.put('event_${event.id}', jsonEncode(event.toJson()));
  }

  Future<Event?> getCachedEvent({required int eventId}) async {
    await _ensureInit();
    final raw = _eventsBox!.get('event_$eventId');
    if (raw == null) return null;
    try {
      return Event.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // ── Tickets ──

  Future<void> cacheTickets({required List<EventTicket> tickets}) async {
    await _ensureInit();
    final jsonList = tickets.map((t) => {
      'id': t.id,
      'event_id': t.eventId,
      'user_id': t.userId,
      'ticket_number': t.ticketNumber,
      'qr_code_data': t.qrCodeData,
      'status': t.status.name,
      'purchase_date': t.purchaseDate.toIso8601String(),
      'price_paid': t.pricePaid,
      'currency': t.currency,
      'payment_method': t.paymentMethod,
      'guest_name': t.guestName,
    }).toList();
    await _ticketsBox!.put('my_tickets', jsonEncode(jsonList));
  }

  Future<List<EventTicket>?> getCachedTickets() async {
    await _ensureInit();
    final raw = _ticketsBox!.get('my_tickets');
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => EventTicket.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheTicketQR({required int ticketId, required String qrData}) async {
    await _ensureInit();
    await _ticketsBox!.put('qr_$ticketId', qrData);
  }

  Future<String?> getCachedTicketQR({required int ticketId}) async {
    await _ensureInit();
    return _ticketsBox!.get('qr_$ticketId')?.toString();
  }

  // ── Saved Events ──

  Future<void> cacheSavedEvents({required List<Event> events}) async {
    await cacheEvents(key: 'saved_events', events: events);
  }

  Future<List<Event>?> getCachedSavedEvents() async {
    return getCachedEvents(key: 'saved_events');
  }

  // ── Clear ──

  Future<void> clearAll() async {
    await _ensureInit();
    await _eventsBox!.clear();
    await _ticketsBox!.clear();
    await _metaBox!.clear();
  }
}
