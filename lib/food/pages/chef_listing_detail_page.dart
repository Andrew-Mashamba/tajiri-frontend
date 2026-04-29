import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../calendar/models/calendar_models.dart';
import '../../calendar/services/calendar_service.dart';
import '../../screens/messages/chat_screen.dart';
import '../../services/income_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/message_service.dart';
import '../models/chef_listing.dart';
import '../models/food_preferences.dart';
import '../services/food_notification_helper.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kWarn = Color(0xFFE67E22);

class ChefListingDetailPage extends StatefulWidget {
  final int listingId;
  final int userId;
  const ChefListingDetailPage({
    super.key,
    required this.listingId,
    required this.userId,
  });

  @override
  State<ChefListingDetailPage> createState() => _ChefListingDetailPageState();
}

class _ChefListingDetailPageState extends State<ChefListingDetailPage> {
  final FoodService _service = FoodService();
  final MessageService _messageService = MessageService();
  ChefListing? _listing;
  bool _loading = true;
  String? _loadError;
  int _portions = 1;
  bool _reserving = false;
  bool _openingChat = false;
  bool _markingPickedUp = false;
  bool _markingOutForDelivery = false;
  bool _markingDelivered = false;
  String _deliveryMode = 'pickup';
  bool _revealingPhone = false;
  String? _revealedPhone;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  bool _cascading = false;

  bool _isFavourite = false;
  int? _favouriteRowId;
  bool _toggleFavBusy = false;

  List<Map<String, dynamic>> _reviews = const [];
  Map<String, dynamic> _reviewSummary = const {};
  bool _reviewsLoading = false;

  FoodPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await _service.getChefListing(widget.listingId, userId: widget.userId);
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() {
        _listing = result.data;
        _loading = false;
        _portions = 1;
        _timeLeft = result.data!.timeUntilClose;
        _revealedPhone = null;
      });
      _startCountdown();
      _refreshFavouriteState();
      _loadReviews();
      _loadPreferences();
    } else {
      setState(() {
        _loading = false;
        _loadError = result.message ?? 'Imeshindwa kupakia';
      });
    }
  }

  Future<void> _loadPreferences() async {
    final result = await _service.getFoodPreferences(userId: widget.userId);
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() => _prefs = result.data);
    }
  }

  List<String> _allergenHits(ChefListing listing) {
    final prefs = _prefs;
    if (prefs == null || prefs.allergens.isEmpty) return const [];
    final haystack = [
      listing.title.toLowerCase(),
      (listing.description ?? '').toLowerCase(),
      ...listing.dietaryTags.map((t) => t.toLowerCase()),
    ].join(' ');
    final hits = <String>[];
    for (final a in prefs.allergens) {
      final key = a.toLowerCase().trim();
      if (key.isEmpty) continue;
      if (haystack.contains(key)) hits.add(a);
    }
    return hits;
  }

  Widget _allergenBanner(List<String> hits) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kWarn.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: _kWarn, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tahadhari ya mzio',
                  style: TextStyle(fontWeight: FontWeight.w600, color: _kPrimary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chakula hiki kinaweza kuwa na: ${hits.join(', ')}. Thibitisha na mpishi kabla ya kuhifadhi.',
                  style: const TextStyle(color: _kPrimary, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithChef() async {
    if (_listing == null || _openingChat) return;
    final partnerUserId = _listing!.partnerUserId;
    if (partnerUserId == null || partnerUserId == widget.userId) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _openingChat = true);
    final result = await _messageService.getPrivateConversation(widget.userId, partnerUserId);
    if (!mounted) return;
    setState(() => _openingChat = false);
    if (result.success && result.conversation != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: result.conversation!.id,
            currentUserId: widget.userId,
            conversation: result.conversation,
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kufungua soga')),
      );
    }
  }

  Future<void> _revealPhone() async {
    if (_listing == null || _revealingPhone) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _revealingPhone = true);
    final result = await _service.getChefListingContact(widget.listingId, widget.userId);
    if (!mounted) return;
    setState(() => _revealingPhone = false);
    if (result.success && result.data != null) {
      if (result.data!.canReveal && result.data!.phoneFull != null) {
        setState(() => _revealedPhone = result.data!.phoneFull);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Weka oda kwanza ili kupata simu ya mpishi')),
        );
      }
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa')),
      );
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _markPickedUp() async {
    if (_listing?.myReservation == null || _markingPickedUp) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _markingPickedUp = true);
    final result = await _service.markChefReservationPickedUp(
      reservationId: _listing!.myReservation!.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _markingPickedUp = false);
    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Asante! Umepokea chakula.')),
      );
      _load();
      _promptReviewSheet();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa')),
      );
    }
  }

  Future<void> _markOutForDelivery() async {
    if (_listing?.myReservation == null || _markingOutForDelivery) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _markingOutForDelivery = true);
    final result = await _service.markChefReservationOutForDelivery(
      reservationId: _listing!.myReservation!.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _markingOutForDelivery = false);
    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Umetoka kwenda kupeleka chakula.')),
      );
      _load();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa')),
      );
    }
  }

  Future<void> _markDelivered() async {
    if (_listing?.myReservation == null || _markingDelivered) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _markingDelivered = true);
    final result = await _service.markChefReservationDelivered(
      reservationId: _listing!.myReservation!.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _markingDelivered = false);
    if (result.success) {
      _logChefIncomeOnDelivery();
      final reservation = _listing!.myReservation!;
      final listing = _listing!;
      FoodNotificationHelper.cancelPickupReminder(reservation.id);
      if (reservation.userId == widget.userId) {
        FoodNotificationHelper.scheduleReviewNudge(
          reservationId: reservation.id,
          listingTitle: listing.title,
          deliveredAt: DateTime.now(),
          prefs: _prefs,
        );
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Chakula kimefikishwa.')),
      );
      _load();
      _promptReviewSheet();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa')),
      );
    }
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _dropPickupCalendarEvent() {
    final listing = _listing;
    if (listing == null) return;
    final start = listing.pickupWindowStart;
    final end = listing.pickupWindowEnd;
    final event = CalendarEvent(
      id: 0,
      userId: widget.userId,
      title: 'Chukua chakula: ${listing.title}',
      date: DateTime(start.year, start.month, start.day),
      startTime: _hhmm(start),
      endTime: _hhmm(end),
      isAllDay: false,
      reminder: EventReminder.min30,
      notes: listing.partnerName == null
          ? 'Chakula cha mpishi'
          : 'Mpishi: ${listing.partnerName}',
      source: EventSource.personal,
    );
    CalendarService().createEvent(event).catchError(
        (_) => CalendarResult<CalendarEvent>(success: false));
  }

  void _logChefIncomeOnDelivery() {
    final listing = _listing;
    if (listing == null) return;
    if (listing.partnerUserId != widget.userId) return;
    final reservation = listing.myReservation;
    if (reservation == null || reservation.totalPriceTzs <= 0) return;
    LocalStorageService.getInstance().then((storage) {
      final token = storage.getAuthToken();
      if (token == null) return;
      IncomeService.recordIncome(
        token: token,
        amount: reservation.totalPriceTzs.toDouble(),
        source: 'chakula',
        description: 'Mauzo ya chakula: ${listing.title}',
        sourceModule: 'food',
        referenceId: 'chef_reservation_${reservation.id}',
      ).catchError((_) => null);
    }).catchError((_) => null);
  }

  Future<void> _refreshFavouriteState() async {
    if (_listing == null) return;
    final res = await _service.listFavourites(widget.userId);
    if (!mounted || !res.success) return;
    final chefId = _listing!.partnerId;
    Map<String, dynamic>? hit;
    for (final row in res.items) {
      if (row['target_type'] == 'chef' && (row['target_id'] as num?)?.toInt() == chefId) {
        hit = row;
        break;
      }
    }
    setState(() {
      _isFavourite = hit != null;
      _favouriteRowId = hit == null ? null : (hit['id'] as num?)?.toInt();
    });
  }

  Future<void> _toggleFavourite() async {
    if (_listing == null || _toggleFavBusy) return;
    setState(() => _toggleFavBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    if (_isFavourite && _favouriteRowId != null) {
      final res = await _service.removeFavourite(userId: widget.userId, favouriteId: _favouriteRowId!);
      if (!mounted) return;
      setState(() {
        _toggleFavBusy = false;
        if (res.success) {
          _isFavourite = false;
          _favouriteRowId = null;
        }
      });
      if (!res.success) {
        messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
      }
    } else {
      final res = await _service.addFavourite(
        userId: widget.userId,
        targetType: 'chef',
        targetId: _listing!.partnerId,
      );
      if (!mounted) return;
      setState(() {
        _toggleFavBusy = false;
        if (res.success) {
          _isFavourite = true;
          _favouriteRowId = (res.data?['id'] as num?)?.toInt();
        }
      });
      if (!res.success) {
        messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa')));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Umemhifadhi mpishi')));
      }
    }
  }

  Future<void> _loadReviews() async {
    if (_listing == null) return;
    setState(() => _reviewsLoading = true);
    final res = await _service.listReviews(targetType: 'chef', targetId: _listing!.partnerId);
    if (!mounted) return;
    setState(() {
      _reviewsLoading = false;
      if (res.success && res.data != null) {
        _reviews = (res.data!['reviews'] as List).cast<Map<String, dynamic>>();
        _reviewSummary = (res.data!['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
      }
    });
  }

  Future<void> _promptReviewSheet() async {
    if (_listing == null) return;
    final result = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      backgroundColor: _kCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ReviewSheet(chefName: _listing!.partnerName ?? 'Mpishi'),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final apiResult = await _service.createReview(
      userId: widget.userId,
      targetType: 'chef',
      targetId: _listing!.partnerId,
      stars: result.stars,
      text: result.text,
      tags: result.tags,
    );
    if (!mounted) return;
    if (apiResult.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Asante kwa maoni yako')));
      _loadReviews();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(apiResult.message ?? 'Imeshindwa')));
    }
  }

  Future<void> _openEditSheet() async {
    if (_listing == null) return;
    final listing = _listing!;
    final result = await showModalBottomSheet<_EditListingAction>(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _EditListingSheet(listing: listing),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final apiResult = await _service.updateChefListing(
      id: listing.id,
      userId: widget.userId,
      extendMinutes: result.extendMinutes,
      addPortions: result.addPortions,
      flipToGiveaway: result.flipToGiveaway,
      close: result.close,
    );
    if (!mounted) return;
    if (apiResult.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Imehifadhiwa')));
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(apiResult.message ?? 'Imeshindwa')));
    }
  }

  Future<void> _cancelReservation() async {
    if (_listing?.myReservation == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: const Text('Futa oda?', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Ukifuta, fedha zitarejeshwa kwenye mkoba wako.', style: TextStyle(color: _kSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ndio, futa')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.cancelChefReservation(
      reservationId: _listing!.myReservation!.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (result.success) {
      FoodNotificationHelper.cancelAllForReservation(_listing!.myReservation!.id);
      messenger.showSnackBar(const SnackBar(content: Text('Oda imefutwa')));
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa')));
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _listing == null) return;
      final left = _listing!.timeUntilClose;
      setState(() => _timeLeft = left);
      if (left.isNegative) _countdownTimer?.cancel();
    });
  }

  Future<void> _reserve() async {
    if (_listing == null || _reserving) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    String? whyMe;
    final isCurated = _listing!.selectionMode == ChefListingSelectionMode.curated &&
        _listing!.mode == ChefListingMode.giveaway;
    if (isCurated) {
      whyMe = await _askWhyMe();
      if (whyMe == null || whyMe.trim().isEmpty) return;
    }

    setState(() => _reserving = true);
    final result = await _service.reserveChefListing(
      listingId: _listing!.id,
      userId: widget.userId,
      portions: _portions,
      whyMe: whyMe,
      deliveryMode: _listing!.deliveryEnabled ? _deliveryMode : 'pickup',
    );
    if (!mounted) return;
    setState(() => _reserving = false);

    if (result.success) {
      _dropPickupCalendarEvent();
      final reservation = result.data;
      if (reservation != null) {
        FoodNotificationHelper.schedulePickupReminder(
          reservationId: reservation.id,
          listingTitle: _listing!.title,
          pickupWindowStart: _listing!.pickupWindowStart,
          prefs: _prefs,
        );
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(isCurated
              ? 'Ombi lako limetumwa. Mpishi atakuchagua.'
              : 'Umeweka oda. Muone mpishi kuchukua.'),
        ),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa')),
      );
    }
  }

  Future<String?> _askWhyMe() async {
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Kwa nini wewe?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 4),
              const Text('Mpishi atasoma na kukuchagua. Maelezo mafupi tu.',
                  style: TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 3,
                maxLength: 80,
                decoration: InputDecoration(
                  hintText: 'k.m. Nina watoto watatu, leo hatuna chakula',
                  hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tuma ombi',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtCountdown(Duration d) {
    if (d.isNegative) return 'Imefungwa';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          'Chakula cha Leo',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_listing != null && _listing!.partnerUserId != widget.userId)
            IconButton(
              tooltip: _isFavourite ? 'Ondoa' : 'Hifadhi mpishi',
              icon: Icon(
                _isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavourite ? Colors.red.shade400 : _kPrimary,
              ),
              onPressed: _toggleFavBusy ? null : _toggleFavourite,
            ),
          if (_listing != null && _listing!.partnerUserId == widget.userId && _listing!.isActive)
            IconButton(
              tooltip: 'Hariri',
              icon: const Icon(Icons.tune_rounded, color: _kPrimary),
              onPressed: _openEditSheet,
            ),
        ],
      ),
      body: _body(),
      bottomNavigationBar: _listing == null ? null : _maybeReserveBar(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 12),
            Text(_loadError!, style: const TextStyle(color: _kSecondary)),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Jaribu tena')),
          ],
        ),
      );
    }
    final listing = _listing!;
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _heroPhoto(listing),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                _countdownChip(listing),
                if (listing.partnerUserId == widget.userId && listing.cascadeReady)
                  _cascadePrompt(listing),
                const SizedBox(height: 16),
                _chefStrip(listing),
                const SizedBox(height: 16),
                _priceAndPortions(listing),
                _myReservationBlock(listing),
                if (listing.description != null && listing.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('Maelezo'),
                  const SizedBox(height: 6),
                  Text(
                    listing.description!,
                    style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.4),
                  ),
                ],
                if (listing.dietaryTags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('Vigezo'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: listing.dietaryTags.map(_tagPill).toList(),
                  ),
                ],
                Builder(
                  builder: (_) {
                    final hits = _allergenHits(listing);
                    if (hits.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _allergenBanner(hits),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _sectionLabel('Kuchukua'),
                const SizedBox(height: 6),
                _pickupBlock(listing),
                const SizedBox(height: 24),
                _reviewsBlock(),
                const SizedBox(height: 16),
                _deliveryModePicker(listing),
                _portionStepper(listing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewsBlock() {
    final avg = _reviewSummary['avg_stars'];
    final total = (_reviewSummary['total'] as num?)?.toInt() ?? 0;
    if (total == 0 && !_reviewsLoading) {
      return Row(
        children: [
          _sectionLabel('Maoni'),
          const SizedBox(width: 8),
          const Text('(hakuna bado)', style: TextStyle(fontSize: 12, color: _kSecondary)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('Maoni'),
            const SizedBox(width: 8),
            if (avg != null)
              Text(
                '${(avg as num).toStringAsFixed(1)} ★  ($total)',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_reviewsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
            ),
          )
        else
          ..._reviews.take(5).map(_reviewCard),
      ],
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    final stars = (r['stars'] as num?)?.toInt() ?? 0;
    final name = r['reviewer_name']?.toString() ?? 'Mteja';
    final text = r['text']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary, fontSize: 13)),
              const SizedBox(width: 6),
              Text('${'★' * stars}${'☆' * (5 - stars)}', style: const TextStyle(color: _kWarn, fontSize: 12)),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 13, color: _kPrimary, height: 1.35)),
          ],
          if (r['seller_response'] != null && r['seller_response'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Jibu la mpishi: ${r['seller_response']}',
                style: const TextStyle(fontSize: 12, color: _kSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroPhoto(ChefListing listing) {
    final url = listing.resolvedPhotoUrl;
    if (url.isEmpty) {
      return Container(
        height: 220,
        color: _kPrimary.withValues(alpha: 0.06),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant_rounded, size: 64, color: _kSecondary),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        height: 220,
        color: Colors.grey.shade200,
      ),
      errorWidget: (_, _, _) => Container(
        height: 220,
        color: _kPrimary.withValues(alpha: 0.06),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, color: _kSecondary),
      ),
    );
  }

  Future<void> _doCascade() async {
    final listing = _listing;
    if (listing == null || _cascading) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tuma mabaki'),
        content: Text(
          'Sehemu ${listing.portionsRemaining} zilizobaki zitafungwa kama mgao wa bure kwa shirika lililochaguliwa. Endelea?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Si sasa')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tuma'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _cascading = true);
    final result = await _service.cascadeChefListing(
      listingId: listing.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _cascading = false);
    if (result.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Mabaki yametumwa kwa shirika.')));
      _load();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa')));
    }
  }

  Widget _cascadePrompt(ChefListing listing) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.volunteer_activism_rounded, size: 22, color: Color(0xFFE65100)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tuma mabaki kwa shirika',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Una sehemu ${listing.portionsRemaining} zilizobaki. Tuma kama mgao wa bure?',
                  style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.3),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: _cascading ? null : _doCascade,
                    icon: _cascading
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Tuma sasa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownChip(ChefListing listing) {
    final closed = _timeLeft.isNegative || !listing.hasPortionsLeft;
    final color = closed
        ? Colors.red.shade400
        : (_timeLeft.inMinutes < 30 ? _kWarn : _kAccent);
    final label = closed ? 'Imefungwa' : 'Inafungwa baada ya ${_fmtCountdown(_timeLeft)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _chefStrip(ChefListing listing) {
    final isOwn = listing.partnerUserId != null && listing.partnerUserId == widget.userId;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _chefAvatar(listing),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.partnerName ?? 'Mpishi',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (listing.partnerLocationText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    listing.partnerLocationText,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (listing.partnerRating > 0) ...[
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        listing.partnerRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600),
                      ),
                      if (listing.partnerJobsCompleted > 0)
                        Text(
                          ' (${listing.partnerJobsCompleted})',
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                        ),
                    ] else
                      const Text(
                        'Mpishi mpya',
                        style: TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!isOwn && listing.partnerUserId != null) ...[
            const SizedBox(width: 8),
            _iconAction(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Soga',
              onTap: _openingChat ? null : _openChatWithChef,
              busy: _openingChat,
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconAction({required IconData icon, required String label, VoidCallback? onTap, bool busy = false}) {
    return Material(
      color: _kPrimary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                    )
                  : Icon(icon, size: 18, color: onTap == null ? _kSecondary : _kPrimary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: onTap == null ? _kSecondary : _kPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myReservationBlock(ChefListing listing) {
    final res = listing.myReservation;
    if (res == null) return const SizedBox.shrink();
    if (res.isCancelled) return const SizedBox.shrink();

    final isPickedUp = res.isPickedUp || res.isDelivered;
    final isDelivery = res.isDelivery;
    final isOwn = listing.partnerUserId != null && listing.partnerUserId == widget.userId;
    final phone = _revealedPhone ?? listing.partnerPhoneMasked;

    final headerLabel = res.isDelivered
        ? 'Imefikishwa'
        : res.isOutForDelivery
            ? 'Inaletwa'
            : res.isPickedUp
                ? 'Umepokea'
                : (isDelivery ? 'Oda yako (Inaletwa)' : 'Oda yako');

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPickedUp ? _kAccent.withValues(alpha: 0.08) : _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPickedUp ? _kAccent.withValues(alpha: 0.3) : _kPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPickedUp ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                size: 16,
                color: isPickedUp ? _kAccent : _kPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                headerLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isPickedUp ? _kAccent : _kPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${res.portions} sehemu${res.totalPriceTzs > 0 ? ' • TZS ${_formatMoney(res.totalPriceTzs)}' : ''}',
                style: const TextStyle(fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (isDelivery) ...[
            const SizedBox(height: 12),
            _deliveryStepper(res.deliveryStepIndex),
          ],
          if (isDelivery && isOwn && (res.isReserved || res.isOutForDelivery)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (res.isReserved)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _markingOutForDelivery ? null : _markOutForDelivery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: _markingOutForDelivery
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delivery_dining_rounded, size: 15),
                      label: const Text('Toka kupeleka',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (res.isOutForDelivery)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _markingDelivered ? null : _markDelivered,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: _markingDelivered
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 15),
                      label: const Text('Nimefikisha',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ],
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: _kSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    phone,
                    style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_revealedPhone == null)
                  TextButton(
                    onPressed: _revealingPhone ? null : _revealPhone,
                    style: TextButton.styleFrom(foregroundColor: _kPrimary, padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: Text(_revealingPhone ? '...' : 'Onesha'),
                  )
                else
                  TextButton(
                    onPressed: () => _callPhone(_revealedPhone!),
                    style: TextButton.styleFrom(foregroundColor: _kPrimary, padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Piga'),
                  ),
              ],
            ),
          ],
          if (!isPickedUp && !isDelivery) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _cancelReservation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Futa oda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: _markingPickedUp ? null : _markPickedUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _markingPickedUp
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Nimechukua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isDelivery && !isOwn && !res.isDelivered) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (res.isReserved)
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: _cancelReservation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: BorderSide(color: _kPrimary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Futa oda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                if (res.isOutForDelivery) ...[
                  if (res.isReserved) const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _markingDelivered ? null : _markDelivered,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _markingDelivered
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Nimepokea', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chefAvatar(ChefListing listing) {
    final url = listing.resolvedPartnerPhotoUrl;
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          placeholder: (_, _) => _chefAvatarFallback(listing),
          errorWidget: (_, _, _) => _chefAvatarFallback(listing),
        ),
      );
    }
    return _chefAvatarFallback(listing);
  }

  Widget _chefAvatarFallback(ChefListing listing) {
    final name = listing.partnerName ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
      ),
    );
  }

  Widget _priceAndPortions(ChefListing listing) {
    final isGiveaway = listing.isGiveaway;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bei', style: TextStyle(fontSize: 11, color: _kSecondary)),
              const SizedBox(height: 2),
              if (isGiveaway)
                Row(
                  children: [
                    Icon(Icons.volunteer_activism_rounded, size: 20, color: _kAccent),
                    const SizedBox(width: 6),
                    const Text(
                      'Bure',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kAccent),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'TZS ${_formatMoney(listing.priceTzs ?? 0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    if (listing.originalPriceTzs != null &&
                        listing.originalPriceTzs! > (listing.priceTzs ?? 0)) ...[
                      const SizedBox(width: 6),
                      Text(
                        'TZS ${_formatMoney(listing.originalPriceTzs!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Zimebaki', style: TextStyle(fontSize: 11, color: _kSecondary)),
            const SizedBox(height: 2),
            Text(
              '${listing.portionsRemaining} / ${listing.portionsTotal}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
    );
  }

  Widget _tagPill(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _tagLabel(key),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
      ),
    );
  }

  String _tagLabel(String key) {
    switch (key) {
      case 'halal': return 'Halal';
      case 'vegetarian': return 'Mboga';
      case 'vegan': return 'Vegan';
      case 'no_pork': return 'Hakuna Nguruwe';
      case 'gluten_free': return 'Bila Ngano';
      case 'spicy': return 'Kali';
    }
    return key;
  }

  Widget _pickupBlock(ChefListing listing) {
    final start = TimeOfDay.fromDateTime(listing.pickupWindowStart.toLocal()).format(context);
    final end = TimeOfDay.fromDateTime(listing.pickupWindowEnd.toLocal()).format(context);
    final address = listing.pickupAddress;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: _kSecondary),
              const SizedBox(width: 8),
              Text(
                '$start – $end',
                style: const TextStyle(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_rounded, size: 18, color: _kSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 13, color: _kPrimary, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
          if (listing.deliveryEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.delivery_dining_rounded, size: 18, color: _kSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _deliveryLabel(listing),
                    style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _deliveryLabel(ChefListing listing) {
    final fee = listing.deliveryFeeTzs;
    final radius = listing.deliveryRadiusKm;
    final parts = <String>['Usafirishaji unapatikana'];
    if (fee != null && fee > 0) parts.add('TZS $fee');
    if (radius != null && radius > 0) parts.add('${radius.toStringAsFixed(1)} km');
    return parts.join(' • ');
  }

  Widget _deliveryModePicker(ChefListing listing) {
    if (!listing.deliveryEnabled) return const SizedBox.shrink();
    final canBuyOwn = listing.partnerUserId != null && listing.partnerUserId == widget.userId;
    final hasActiveReservation = listing.myReservation != null &&
        !listing.myReservation!.isCancelled &&
        !listing.myReservation!.isPickedUp &&
        !listing.myReservation!.isDelivered;
    if (canBuyOwn || hasActiveReservation || !listing.hasPortionsLeft || _timeLeft.isNegative) {
      return const SizedBox.shrink();
    }
    final fee = listing.deliveryFeeTzs ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: _modePill(
                label: 'Nichukue mwenyewe',
                icon: Icons.directions_walk_rounded,
                isSelected: _deliveryMode == 'pickup',
                onTap: () => setState(() => _deliveryMode = 'pickup'),
              ),
            ),
            Expanded(
              child: _modePill(
                label: fee > 0 ? 'Niletewe (TZS $fee)' : 'Niletewe',
                icon: Icons.delivery_dining_rounded,
                isSelected: _deliveryMode == 'delivery',
                onTap: () => setState(() => _deliveryMode = 'delivery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? _kPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : _kSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _kSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deliveryStepper(int stepIndex) {
    const labels = ['Inapikwa', 'Iko njiani', 'Imefikishwa'];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              _stepDot(i, stepIndex),
              if (i < 2) Expanded(child: _stepConnector(active: i < stepIndex)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: i <= stepIndex ? _kPrimary : _kSecondary,
                  ),
                  textAlign: i == 0
                      ? TextAlign.start
                      : (i == 1 ? TextAlign.center : TextAlign.end),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepDot(int step, int stepIndex) {
    final isComplete = step < stepIndex;
    final isCurrent = step == stepIndex;
    final color = isComplete
        ? _kAccent
        : (isCurrent ? _kPrimary : _kSecondary.withValues(alpha: 0.35));
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isComplete || isCurrent ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isComplete
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : Text(
              '${step + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isCurrent ? Colors.white : color,
              ),
            ),
    );
  }

  Widget _stepConnector({required bool active}) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: active ? _kAccent : _kSecondary.withValues(alpha: 0.2),
    );
  }

  Widget _portionStepper(ChefListing listing) {
    final canBuyOwn = listing.partnerUserId != null && listing.partnerUserId == widget.userId;
    final hasActiveReservation = listing.myReservation != null &&
        !listing.myReservation!.isCancelled &&
        !listing.myReservation!.isPickedUp;
    if (canBuyOwn || hasActiveReservation || !listing.hasPortionsLeft || _timeLeft.isNegative) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        const Text('Sehemu:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
        const Spacer(),
        _stepperButton(Icons.remove_rounded, _portions > 1
            ? () => setState(() => _portions--)
            : null),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text(
            '$_portions',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ),
        _stepperButton(Icons.add_rounded, _portions < listing.portionsRemaining
            ? () => setState(() => _portions++)
            : null),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: onTap == null ? Colors.grey.shade200 : _kPrimary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: onTap == null ? _kSecondary : Colors.white),
        ),
      ),
    );
  }

  Widget? _maybeReserveBar() {
    final listing = _listing!;
    final hasActiveReservation = listing.myReservation != null &&
        !listing.myReservation!.isCancelled &&
        !listing.myReservation!.isPickedUp;
    if (hasActiveReservation) return null;
    return _reserveBar();
  }

  Widget _reserveBar() {
    final listing = _listing!;
    final canBuyOwn = listing.partnerUserId != null && listing.partnerUserId == widget.userId;
    final closed = _timeLeft.isNegative || !listing.hasPortionsLeft;
    final total = listing.isGiveaway ? 0 : (listing.priceTzs ?? 0) * _portions;

    String ctaText;
    VoidCallback? onPressed;
    if (canBuyOwn) {
      ctaText = 'Hauwezi kuagiza chakula chako';
      onPressed = null;
    } else if (closed) {
      ctaText = 'Imefungwa';
      onPressed = null;
    } else if (_reserving) {
      ctaText = 'Inaweka oda...';
      onPressed = null;
    } else if (listing.isGiveaway) {
      ctaText = 'Chukua Bure';
      onPressed = _reserve;
    } else {
      ctaText = 'Lipa TZS ${_formatMoney(total)}';
      onPressed = _reserve;
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            if (!listing.isGiveaway && !closed && !canBuyOwn)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jumla', style: TextStyle(fontSize: 11, color: _kSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      'TZS ${_formatMoney(total)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    const SizedBox(height: 1),
                    const Text('Lipa na Tajiri Wallet', style: TextStyle(fontSize: 10, color: _kSecondary)),
                  ],
                ),
              ),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _reserving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          ctaText,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _EditListingAction {
  final int? extendMinutes;
  final int? addPortions;
  final bool flipToGiveaway;
  final bool close;
  _EditListingAction({this.extendMinutes, this.addPortions, this.flipToGiveaway = false, this.close = false});
}

class _EditListingSheet extends StatefulWidget {
  final ChefListing listing;
  const _EditListingSheet({required this.listing});

  @override
  State<_EditListingSheet> createState() => _EditListingSheetState();
}

class _EditListingSheetState extends State<_EditListingSheet> {
  int _extendMinutes = 0;
  int _addPortions = 0;
  bool _flipToGiveaway = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final isGiveaway = l.isGiveaway;
    final canFlip = !isGiveaway;
    final hasChange = _extendMinutes > 0 || _addPortions > 0 || _flipToGiveaway;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Hariri Chakula Chako',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            const Text('Ongeza muda (dakika)', style: TextStyle(fontSize: 12, color: _kSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [0, 15, 30, 45, 60].map((m) {
                return ChoiceChip(
                  label: Text(m == 0 ? 'Hapana' : '+${m}min'),
                  selected: _extendMinutes == m,
                  onSelected: (_) => setState(() => _extendMinutes = m),
                  selectedColor: _kPrimary,
                  labelStyle: TextStyle(
                    color: _extendMinutes == m ? Colors.white : _kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Ongeza sehemu (kuwa na: ${l.portionsRemaining})',
              style: const TextStyle(fontSize: 12, color: _kSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [0, 1, 2, 5, 10].map((p) {
                return ChoiceChip(
                  label: Text(p == 0 ? 'Hapana' : '+$p'),
                  selected: _addPortions == p,
                  onSelected: (_) => setState(() => _addPortions = p),
                  selectedColor: _kPrimary,
                  labelStyle: TextStyle(
                    color: _addPortions == p ? Colors.white : _kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (canFlip)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _kAccent,
                title: const Text('Toa bure sehemu zilizobaki', style: TextStyle(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Chakula kinakuwa mgao wa bure, hakuna malipo', style: TextStyle(fontSize: 11, color: _kSecondary)),
                value: _flipToGiveaway,
                onChanged: (v) => setState(() => _flipToGiveaway = v),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, _EditListingAction(close: true)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Funga sasa'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: !hasChange
                          ? null
                          : () => Navigator.pop(
                                context,
                                _EditListingAction(
                                  extendMinutes: _extendMinutes > 0 ? _extendMinutes : null,
                                  addPortions: _addPortions > 0 ? _addPortions : null,
                                  flipToGiveaway: _flipToGiveaway,
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Hifadhi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDraft {
  final int stars;
  final String? text;
  final List<String> tags;
  _ReviewDraft({required this.stars, required this.text, required this.tags});
}

class _ReviewSheet extends StatefulWidget {
  final String chefName;
  const _ReviewSheet({required this.chefName});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _stars = 5;
  final TextEditingController _textCtrl = TextEditingController();
  final Set<String> _tags = {};

  static const List<String> _tagOptions = [
    'Kwa wakati',
    'Ladha tamu',
    'Bei nzuri',
    'Kusaidia',
    'Safi',
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Chakula cha ${widget.chefName} kilikuwaje?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  final filled = idx <= _stars;
                  return IconButton(
                    iconSize: 34,
                    onPressed: () => setState(() => _stars = idx),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: filled ? _kWarn : _kSecondary,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tagOptions.map((t) {
                  final sel = _tags.contains(t);
                  return FilterChip(
                    label: Text(t),
                    selected: sel,
                    backgroundColor: _kBackground,
                    selectedColor: _kPrimary.withValues(alpha: 0.08),
                    labelStyle: TextStyle(color: sel ? _kPrimary : _kSecondary, fontSize: 12),
                    onSelected: (v) => setState(() {
                      v ? _tags.add(t) : _tags.remove(t);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Maelezo (si lazima)',
                  hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ghairi', style: TextStyle(color: _kSecondary)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _ReviewDraft(
                          stars: _stars,
                          text: _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
                          tags: _tags.toList(),
                        ),
                      );
                    },
                    child: const Text('Wasilisha'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
