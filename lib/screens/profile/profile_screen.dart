import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../models/profile_models.dart';
import '../../models/profile_tab_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/profile_service.dart';
import 'cover_photo/cover_canvas.dart';
import 'cover_photo/cover_photo_orchestrator.dart';
import 'cover_photo/cover_upload_overlay.dart';
import 'profile_photo/profile_photo_orchestrator.dart';
import 'partner/partner_picker_sheet.dart';
import '../../myposts/pages/my_posts_page.dart';
import '../../mystreams/pages/my_streams_page.dart';
import '../../mygroups/pages/my_groups_page.dart';
import '../../services/friend_service.dart';
import '../../models/friend_models.dart' hide FriendshipStatus;
import '../../services/message_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/event_tracking_service.dart';
import '../../widgets/cached_media_image.dart';
import '../../photos/screens/photos_screen.dart';
import '../../myphotos/widgets/photo_gallery_widget.dart';
import '../../mymusic/widgets/music_gallery_widget.dart';
import '../../widgets/gallery/shop_gallery_widget.dart';
import '../michangogallerywidget_screen.dart';
import '../campaigns/create_campaign_screen.dart';
import '../settings/settings_screen.dart';
import '../wallet/subscribe_to_creator_screen.dart';
import '../../myvideos/widgets/video_gallery_widget_screen.dart';
import '../groups/groups_screen.dart';
import '../groups/create_group_screen.dart';
import '../groups/group_detail_screen.dart';
import '../../models/group_models.dart';
import '../../models/file_models.dart';
import '../../services/group_service.dart';
import '../../services/file_service.dart';
import 'profile_stats_bottom_sheet.dart';
import '../../creator/screens/creator_revenue_screen.dart';
import 'edit_profile_screen.dart';
import '../../budget/budget_module.dart';
import '../../kikoba/kikoba_module.dart';
import '../../my_wallet/my_wallet_module.dart';
import '../../subscriptions/subscriptions_module.dart';
import '../../investments/investments_module.dart';
import '../../loans/loans_module.dart';
import '../../doctor/doctor_module.dart';
import '../../pharmacy/pharmacy_module.dart';
import '../../insurance/insurance_module.dart';
import '../../government/government_module.dart';
import '../../lawyer/lawyer_module.dart';
import '../../fitness/fitness_module.dart';
import '../../my_circle/my_circle_module.dart';
import '../../my_family/my_family_module.dart';
import '../../my_family/services/my_family_service.dart';
import '../../my_pregnancy/my_pregnancy_module.dart';
import '../../my_baby/my_baby_module.dart';
import '../../skincare/skincare_module.dart';
import '../../hair_nails/hair_nails_module.dart';
import '../../business/business_module.dart';
import '../../business/biz_tab_wrapper.dart';
import '../../business/pages/business_documents_page.dart';
import '../../business/pages/email/email_client_page.dart';
import '../../business/pages/business_card_page.dart';
import '../../business/pages/quotes_page.dart';
import '../../business/pages/invoices_page.dart';
import '../../business/pages/recurring_invoices_page.dart';
import '../../business/pages/vfd_page.dart';

// Recovered orphan modules — see "Recovered orphan modules" section in
// profile_tab_config.dart. Imported with prefixes to avoid clashing with the
// older lib/business/* pages of the same names.
import '../../mafundi/pages/mafundi_home_page.dart' as mafundi_home;
import '../../myjob/pages/my_job_page.dart' as myjob_home;
import '../../clients/pages/clients_page.dart' as clients_v2;
import '../../suppliers/pages/suppliers_page.dart' as suppliers_v2;
import '../../vfd/pages/vfd_page.dart' as vfd_v2;
import '../../business/pages/customers_page.dart';
import '../../business/pages/debts_page.dart';
import '../../business/pages/reminder_settings_page.dart';
import '../../business/pages/expenses_page.dart';
import '../../business/pages/tax_page.dart';
import '../../business/pages/credit_report_page.dart';
import '../../business/pages/employees_page.dart';
import '../../business/pages/payroll_page.dart';
import '../../business/pages/suppliers_page.dart';
import '../../business/pages/purchase_orders_page.dart';
import '../../business/pages/appointments_page.dart';
import '../../tenders/tenders_module.dart';
import '../../housing/housing_module.dart';
import '../../bills/bills_module.dart';
import '../../vehicle/vehicle_module.dart';
import '../../food/food_module.dart';
import '../../transport/transport_module.dart';
import '../../fundi/fundi_module.dart';
import '../../calendar/calendar_module.dart';
import '../../notes/notes_module.dart';
import '../../faith/faith_module.dart';
import '../../community/community_module.dart';
import '../../events/events_module.dart';
import '../../travel/travel_module.dart';
import '../../games/games_module.dart';
import '../../barozi_wangu/barozi_wangu_module.dart';
import '../../ofisi_mtaa/ofisi_mtaa_module.dart';
import '../../dc/dc_module.dart';
import '../../rc/rc_module.dart';
import '../../katiba/katiba_module.dart';
import '../../legal_gpt/legal_gpt_module.dart';
import '../../nida/nida_module.dart';
import '../../rita/rita_module.dart';
import '../../tra/tra_module.dart';
import '../../brela/brela_module.dart';
import '../../passport/passport_module.dart';
import '../../driving_licence/driving_licence_module.dart';
import '../../land_office/land_office_module.dart';
import '../../nhif/nhif_module.dart';
import '../../nssf/nssf_module.dart';
import '../../tanesco/tanesco_module.dart';
import '../../dawasco/dawasco_module.dart';
// My Cars
import '../../my_cars/my_cars_module.dart';
import '../../car_insurance/car_insurance_module.dart';
import '../../buy_car/buy_car_module.dart';
import '../../fuel_delivery/fuel_delivery_module.dart';
import '../../service_garage/service_garage_module.dart';
import '../../sell_car/sell_car_module.dart';
import '../../rent_car/rent_car_module.dart';
import '../../owners_club/owners_club_module.dart';
import '../../spare_parts/spare_parts_module.dart';
// Commerce + Health
import '../../tajirika/tajirika_module.dart';
import '../../ambulance/ambulance_module.dart';
// Govt extra
import '../../latra/latra_module.dart';
import '../../tira/tira_module.dart';
import '../../ewura/ewura_module.dart';
import '../../heslb/heslb_module.dart';
import '../../necta/necta_module.dart';
// Faith
import '../../my_faith/my_faith_module.dart';
import '../../biblia/biblia_module.dart';
import '../../sala/sala_module.dart';
import '../../fungu_la_kumi/fungu_la_kumi_module.dart';
import '../../kanisa_langu/kanisa_langu_module.dart';
import '../../huduma/huduma_module.dart';
import '../../jumuiya/jumuiya_module.dart';
import '../../ibada/ibada_module.dart';
import '../../shule_ya_jumapili/shule_ya_jumapili_module.dart';
import '../../tafuta_kanisa/tafuta_kanisa_module.dart';
import '../../wakati_wa_sala/wakati_wa_sala_module.dart';
import '../../qibla/qibla_module.dart';
import '../../quran/quran_module.dart';
import '../../kalenda_hijri/kalenda_hijri_module.dart';
import '../../ramadan/ramadan_module.dart';
import '../../zaka/zaka_module.dart';
import '../../dua/dua_module.dart';
import '../../hadith/hadith_module.dart';
import '../../tafuta_msikiti/tafuta_msikiti_module.dart';
import '../../maulid/maulid_module.dart';
// Security + Lifestyle
import '../../police/police_module.dart';
import '../../traffic/traffic_module.dart';
import '../../neighbourhood_watch/neighbourhood_watch_module.dart';
import '../../alerts/alerts_module.dart';
import '../../nightlife/nightlife_module.dart';
import '../../my_children/my_children_module.dart';
import '../../my_parents/my_parents_module.dart';
import '../../news/news_module.dart';
import '../../reminders/reminders_module.dart';
import '../../accounting/accounting_module.dart';
// Education
import '../../my_class/my_class_module.dart';
import '../../timetable/timetable_module.dart';
import '../../assignments/assignments_module.dart';
import '../../class_chat/class_chat_module.dart';
import '../../class_notes/class_notes_module.dart';
import '../../exam_prep/exam_prep_module.dart';
import '../../past_papers/past_papers_module.dart';
import '../../newton/newton_module.dart';
import '../../results/results_module.dart';
import '../../fee_status/fee_status_module.dart';
import '../../library/library_module.dart';
import '../../campus_news/campus_news_module.dart';
import '../../study_groups/study_groups_module.dart';
import '../../career/career_module.dart';
import '../../appointments/appointments_module.dart';
import '../../calls/calls_module.dart';
import '../../consultations/consultations_module.dart';
import '../../crb/crb_module.dart';
import '../../customer_orders/customer_orders_module.dart';
import '../../debts/debts_module.dart';
import '../../engagements/engagements_module.dart';
import '../../expenses/expenses_module.dart';
import '../../income/income_module.dart';
import '../../invoices/invoices_module.dart';
import '../../orders/orders_module.dart';
import '../../payroll/payroll_module.dart';
import '../../products/products_module.dart';
import '../../projects/projects_module.dart';
import '../../recurring/recurring_module.dart';
import '../../revenue/revenue_module.dart';
import '../../tax/tax_module.dart';
import '../../team/team_module.dart';
import '../../transactions/transactions_module.dart';
import '../../biz_services/biz_services_module.dart';
class ProfileScreen extends StatefulWidget {
  final int userId;
  final int? currentUserId;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.currentUserId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final FriendService _friendService = FriendService();
  final MessageService _messageService = MessageService();

  TabController? _tabController;

  FullProfile? _profile;
  bool _isLoading = true;
  String? _error;

  // Tab configuration
  List<ProfileTabConfig> _allTabs = [];
  List<ProfileTabConfig> _enabledTabs = [];
  Map<String, String> _customCategoryLabels = {};

  // Profile photo upload
  bool _isUploadingPhoto = false;
  // ignore: unused_field — surfaced inline in the avatar overlay area
  String? _profilePhotoError;
  // Cover photo upload — orchestrator + inline overlay state
  CoverPhotoOrchestrator? _coverOrchestrator;
  CoverUploadState _coverOverlayState = CoverUploadState.idle;
  String? _coverOverlayError;
  // Last successfully-compressed file, kept so Retry can re-upload
  // without forcing the user to re-crop.
  File? _coverLastCompressed;
  // Send friend request in progress
  bool _isSendingFriendRequest = false;

  // Streak data for profile (visible on all profiles)

  // Viral assists count (own profile or when > 0)
  int _familyCount = 0;

  // Cached LocalStorageService (Hive) — initialised on first use, reused after.
  LocalStorageService? _storage;
  Future<LocalStorageService> _ensureStorage() async {
    return _storage ??= await LocalStorageService.getInstance();
  }

  int get _currentUserId => widget.currentUserId ?? widget.userId;
  bool get _isOwnProfile => widget.userId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadTabsAndProfile();
  }

  Future<void> _loadTabsAndProfile() async {
    debugPrint('[ProfileScreen] _loadTabsAndProfile started for userId: ${widget.userId}');

    final storage = await _ensureStorage();
    if (!mounted) return;
    debugPrint('[ProfileScreen] LocalStorageService loaded');

    _allTabs = storage.getProfileTabs();
    _enabledTabs = _allTabs
        .where((t) => t.enabled)
        .where((t) => _isOwnProfile || !ProfileTabDefaults.ownProfileOnlyTabIds.contains(t.id))
        .toList();
    _customCategoryLabels = storage.getUserCategories().labels;
    debugPrint('[ProfileScreen] Tabs: ${_allTabs.length} total, ${_enabledTabs.length} enabled');

    // Dispose any controller from a previous run before reassigning. This is
    // defensive: in the normal mount->initState->_loadTabsAndProfile flow
    // _tabController is null. It only becomes non-null here if _refreshTabs()
    // ran (e.g. after returning from Settings), which means we're being
    // re-entered after a tab-config change. Disposing first prevents a leak.
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _tabController = null;

    if (_enabledTabs.isNotEmpty) {
      _tabController = TabController(
        length: _enabledTabs.length,
        vsync: this,
        animationDuration: const Duration(milliseconds: 280),
      );
      _tabController!.addListener(_onTabChanged);
    } else {
      debugPrint('[ProfileScreen] WARNING: No enabled tabs!');
    }

    setState(() {});
    _loadProfile();
  }

  Future<void> _refreshTabs() async {
    if (!mounted) return;

    final storage = await _ensureStorage();
    final newTabs = storage.getProfileTabs();
    final newEnabledTabs = newTabs
        .where((t) => t.enabled)
        .where((t) => _isOwnProfile || !ProfileTabDefaults.ownProfileOnlyTabIds.contains(t.id))
        .toList();
    _customCategoryLabels = storage.getUserCategories().labels;

    // Check if tabs have actually changed
    final tabsChanged = _enabledTabs.length != newEnabledTabs.length ||
        !_enabledTabs.every((t) => newEnabledTabs.any((n) => n.id == t.id && n.order == t.order));

    if (tabsChanged && mounted) {
      // Store old controller to dispose after frame
      final oldController = _tabController;

      _allTabs = newTabs;
      _enabledTabs = newEnabledTabs;

      // Create new controller
      _tabController = TabController(
        length: _enabledTabs.length,
        vsync: this,
        animationDuration: const Duration(milliseconds: 280),
      );
      _tabController!.addListener(_onTabChanged);

      setState(() {});

      // Dispose old controller after the frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController?.removeListener(_onTabChanged);
        oldController?.dispose();
      });
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _tabController = null;
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController == null || _enabledTabs.isEmpty) return;
    setState(() {}); // Update custom tab bar selected state (e.g. after swipe)
    // Tab content widgets (ProfilePostsPage, PhotoGalleryWidget, etc.) handle
    // their own data loading and pagination internally.
  }

  Future<void> _loadProfile() async {
    debugPrint('[ProfileScreen] _loadProfile started');
    // Only show the full-page spinner on the very first load — when we
    // have nothing to render yet. On subsequent refreshes (e.g. after a
    // cover-photo upload) we keep the existing UI in place and let the
    // localized cover overlay carry the loading affordance instead.
    final isFirstLoad = _profile == null;
    setState(() {
      if (isFirstLoad) _isLoading = true;
      _error = null;
    });

    debugPrint('[ProfileScreen] Calling profileService.getProfile for userId: ${widget.userId}');
    final result = await _profileService.getProfile(
      userId: widget.userId,
      currentUserId: _currentUserId,
    );
    debugPrint('[ProfileScreen] getProfile returned: success=${result.success}, message=${result.message}');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _profile = result.profile;
          debugPrint('[ProfileScreen] Profile loaded: ${_profile?.fullName}');
          // Load family count for the family stat tile.
          _loadFamilyCount();
        } else {
          _error = result.message;
          debugPrint('[ProfileScreen] Profile error: $_error');
        }
      });
    } else {
      debugPrint('[ProfileScreen] Widget not mounted after profile load');
    }
  }

  Future<void> _loadFamilyCount() async {
    try {
      final result = await MyFamilyService().getMembers(widget.userId);
      if (!mounted) return;
      if (result.success) {
        setState(() => _familyCount = result.items.length);
      }
    } catch (e, st) {
      // Non-critical: family stat just renders 0 if the call fails.
      debugPrint('[ProfileScreen] _loadFamilyCount failed: $e\n$st');
    }
  }

  /// Drives the profile-photo flow via [ProfilePhotoOrchestrator]:
  /// bottom sheet → pick/capture → 1:1 crop with circular preview →
  /// chrome preview with soft face hint → compress → Dio upload with
  /// inline overlay rendered on the avatar circle (CoverCanvas's
  /// isUploadingAvatar). No SnackBars — inline feedback only.
  /// Spec: docs/superpowers/specs/2026-05-02-profile-photo-upload-design.md
  Future<void> _updateProfilePhoto() async {
    if (_isUploadingPhoto || !_isOwnProfile) return;

    final orchestrator = ProfilePhotoOrchestrator(profileService: _profileService);
    setState(() => _isUploadingPhoto = true);

    try {
      final outcome = await orchestrator.run(
        context: context,
        userId: widget.userId,
        currentPhotoUrl: _profile?.profilePhotoUrl,
        currentCoverUrl: _profile?.coverPhotoUrl,
        avatarInitials: _profile?.initials,
        fullName: _profile?.fullName,
        username: _profile?.username,
      );
      if (!mounted) return;

      if (outcome.cancelled) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      if (outcome.success) {
        // Evict any cached version of the previous avatar so the new one
        // takes effect immediately across the app.
        final previousUrl = _profile?.profilePhotoUrl;
        if (previousUrl != null && previousUrl.isNotEmpty) {
          try {
            await CachedNetworkImage.evictFromCache(previousUrl);
          } catch (_) {}
        }
        // Persist the new URL into Hive so all other surfaces (chats,
        // post avatars, drawers) see the change without waiting for
        // their own refresh cycles.
        if (outcome.newPhotoUrl != null && outcome.newPhotoUrl!.isNotEmpty) {
          final storage = await _ensureStorage();
          final user = storage.getUser();
          if (user != null && user.userId == widget.userId) {
            user.applyServerProfile({'profile_photo_url': outcome.newPhotoUrl});
            await storage.saveUser(user);
          }
        }
        if (!mounted) return;
        setState(() => _isUploadingPhoto = false);
        _loadProfile(); // silent refetch — won't trigger full-page spinner
        return;
      }

      // Failed (not cancelled, not success). Inline error rendered via
      // _profilePhotoError so the avatar circle shows the recovery affordance.
      setState(() {
        _isUploadingPhoto = false;
        _profilePhotoError = outcome.errorMessage;
      });
    } finally {
      orchestrator.dispose();
    }
  }

  /// Drives the cover-photo flow via [CoverPhotoOrchestrator]:
  /// bottom sheet → pick/capture → crop (16:9) → live preview → compress
  /// → Dio upload with inline progress overlay on the cover canvas.
  /// Spec: docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md
  Future<void> _updateCoverPhoto() async {
    if (!_isOwnProfile) return;
    if (_coverOverlayState == CoverUploadState.uploading) return;

    final orchestrator = CoverPhotoOrchestrator(profileService: _profileService);
    setState(() => _coverOrchestrator = orchestrator);

    orchestrator.phaseListenable.addListener(() {
      if (!mounted) return;
      // Phase only flips between idle/uploading. Errors are reported via
      // the outcome and surfaced through _coverOverlayState below.
    });

    final outcome = await orchestrator.run(
      context: context,
      userId: widget.userId,
      currentCoverUrl: _profile?.coverPhotoUrl,
      avatarUrl: _profile?.profilePhotoUrl,
      avatarInitials: _profile?.initials,
      fullName: _profile?.fullName,
      username: _profile?.username,
    );
    if (!mounted) {
      orchestrator.dispose();
      return;
    }

    if (outcome.cancelled) {
      orchestrator.dispose();
      setState(() {
        _coverOrchestrator = null;
        _coverOverlayState = CoverUploadState.idle;
        _coverOverlayError = null;
      });
      return;
    }

    if (outcome.success) {
      // Evict the previous cover URL from the cached_network_image cache so
      // CachedMediaImage refetches the new bytes immediately rather than
      // showing the stale cached image until next app launch.
      final previousCoverUrl = _profile?.coverPhotoUrl;
      if (previousCoverUrl != null && previousCoverUrl.isNotEmpty) {
        try {
          await CachedNetworkImage.evictFromCache(previousCoverUrl);
        } catch (_) {}
      }
      orchestrator.dispose();
      setState(() {
        _coverOrchestrator = null;
        _coverOverlayState = CoverUploadState.idle;
        _coverOverlayError = null;
        _coverLastCompressed = null;
      });
      _loadProfile(); // pull canonical state with the new cover_photo_url
      return;
    }

    // Failed (not cancelled). Keep overlay in error state so the user can
    // tap Retry without re-cropping. Stash the compressed file from the
    // orchestrator so retry can re-upload it directly.
    setState(() {
      _coverOverlayState = CoverUploadState.error;
      _coverOverlayError = outcome.errorMessage;
      _coverLastCompressed = orchestrator.lastCompressedFile;
    });
  }

  void _cancelCoverUpload() {
    _coverOrchestrator?.cancel();
  }

  void _dismissCoverOverlay() {
    _coverOrchestrator?.dispose();
    setState(() {
      _coverOrchestrator = null;
      _coverOverlayState = CoverUploadState.idle;
      _coverOverlayError = null;
      _coverLastCompressed = null;
    });
  }

  Future<void> _retryCoverUpload() async {
    final compressed = _coverLastCompressed;
    final orchestrator = _coverOrchestrator;
    if (compressed == null || orchestrator == null) {
      // Fall back to restarting the whole flow.
      _dismissCoverOverlay();
      _updateCoverPhoto();
      return;
    }
    setState(() {
      _coverOverlayState = CoverUploadState.uploading;
      _coverOverlayError = null;
    });
    final outcome = await orchestrator.retryUpload(
      userId: widget.userId,
      compressedFile: compressed,
    );
    if (!mounted) return;
    if (outcome.success) {
      orchestrator.dispose();
      setState(() {
        _coverOrchestrator = null;
        _coverOverlayState = CoverUploadState.idle;
        _coverOverlayError = null;
        _coverLastCompressed = null;
      });
      _loadProfile(); // refetch with the new cover_photo_url
    } else if (outcome.cancelled) {
      _dismissCoverOverlay();
    } else {
      setState(() {
        _coverOverlayState = CoverUploadState.error;
        _coverOverlayError = outcome.errorMessage;
      });
    }
  }

  Future<void> _openChatWithProfileUser() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await _messageService.getPrivateConversation(
      _currentUserId,
      widget.userId,
    );
    if (!mounted) return;
    if (result.success && result.conversation != null) {
      navigator.pushNamed(
        '/chat/${result.conversation!.id}',
        arguments: <String, dynamic>{'conversation': result.conversation},
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not open chat')),
      );
    }
  }

  Future<void> _handleFriendAction() async {
    final profile = _profile;
    if (profile == null) return;

    final status = profile.friendshipStatus;

    switch (status) {
      case FriendshipStatus.none:
        // Send friend request
        if (_isSendingFriendRequest) return;
        setState(() => _isSendingFriendRequest = true);
        final result = await _friendService.sendFriendRequest(
          _currentUserId,
          widget.userId,
        );
        if (!mounted) return;
        setState(() => _isSendingFriendRequest = false);
        if (result) {
          EventTrackingService.getInstance().then((tracker) {
            tracker.trackEvent(eventType: 'follow', creatorId: widget.userId);
          }).catchError((e, st) {
            debugPrint('[ProfileScreen] follow tracking failed: $e\n$st');
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStringsScope.of(context)?.friendRequestSent ?? 'Friend request sent')),
          );
          _loadProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStringsScope.of(context)?.friendRequestFailed ?? 'Failed to send friend request. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case FriendshipStatus.pending:
        // Accept friend request
        final result = await _friendService.acceptFriendRequest(
          _currentUserId,
          widget.userId,
        );
        if (mounted && result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStringsScope.of(context)?.nowFriends ?? 'Now friends!')),
          );
          _loadProfile();
        }
        break;
      case FriendshipStatus.requested:
        // Cancel request
        final result = await _friendService.cancelFriendRequest(
          _currentUserId,
          widget.userId,
        );
        if (mounted && result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStringsScope.of(context)?.requestCancelled ?? 'Request cancelled')),
          );
          _loadProfile();
        }
        break;
      case FriendshipStatus.friends:
        // Show unfriend dialog
        _showUnfriendDialog();
        break;
      case FriendshipStatus.self:
      case null:
        // Edit profile
        _showEditProfileDialog();
        break;
    }
  }

  void _showUnfriendDialog() {
    final s = AppStringsScope.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.removeFriendTitle ?? 'Remove friend'),
        content: Text(s?.removeFriendMessage(_profile?.firstName ?? '') ?? 'Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _friendService.removeFriend(
                _currentUserId,
                widget.userId,
              );
              if (mounted && result) {
                EventTrackingService.getInstance().then((tracker) {
                  tracker.trackEvent(eventType: 'unfollow', creatorId: widget.userId);
                }).catchError((e, st) {
                  debugPrint('[ProfileScreen] unfollow tracking failed: $e\n$st');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s?.friendRemoved ?? 'Friend removed')),
                );
                _loadProfile();
              }
            },
            child: Text(s?.yes ?? 'Yes', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          currentUserId: _currentUserId,
          initialProfile: _profile,
        ),
      ),
    ).then((saved) {
      if (saved == true && mounted) _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final secondaryText = theme.colorScheme.onSurfaceVariant;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(backgroundColor: theme.colorScheme.surface),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: secondaryText.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: secondaryText, fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loadProfile,
                      child: Text(AppStringsScope.of(context)?.retry ?? 'Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Wait for tabs to load
    if (_tabController == null || _enabledTabs.isEmpty) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildProfileInfo()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Floating mini sidebar - sticky on right side, from top to just above bottom nav
  /// Contains all profile tabs for navigation
  /// Open a tab as a full page
  void _openTabPage(ProfileTabConfig tab) {
    // Saved + Settings already exist as full-Scaffold screens. Pushing them
    // through _ProfileTabPage would produce duplicate AppBars, so we route
    // directly to the existing screens instead.
    switch (tab.id) {
      case 'saved':
        Navigator.pushNamed(context, '/saved-posts');
        return;
      case 'photos':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotosScreen(
              userId: widget.userId,
              isCurrentUser: _isOwnProfile,
            ),
          ),
        );
        return;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsScreen(currentUserId: _currentUserId)),
        ).then((_) {
          if (mounted) {
            _refreshTabs();
            _loadProfile();
          }
        });
        return;
    }

    final s = AppStringsScope.of(context);
    final label = _isOwnProfile
        ? (s?.profileTabLabelOwn(tab.id) ?? tab.label)
        : (s?.profileTabLabel(tab.id) ?? tab.label);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ProfileTabPage(
          title: label,
          icon: _tabIconData(tab.icon),
          tabId: tab.id,
          userId: widget.userId,
          currentUserId: _currentUserId,
          isOwnProfile: _isOwnProfile,
          profile: _profile,
          onRefresh: _loadProfile,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    // The cover image is cropped at 16:9. Make the SliverAppBar's expanded
    // canvas exactly 16:9 (relative to screen width) so BoxFit.cover can
    // render the user's crop 1:1 with no horizontal cropping at the sides.
    // Add the status-bar inset on top so the actual visible cover remains
    // a true 16:9 below the notch.
    final mq = MediaQuery.of(context);
    final coverHeight = mq.size.width * 9 / 16;
    return SliverAppBar(
      expandedHeight: coverHeight + mq.padding.top,
      pinned: true,
      backgroundColor: TajiriAppBar.surfaceColor,
      foregroundColor: TajiriAppBar.primaryTextColor,
      iconTheme: TajiriAppBar.iconTheme,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        // CoverCanvas defers to the FlexibleSpaceBar's own height
        // constraint here (no inner SizedBox), so collapse mode can stay
        // at the default parallax behavior without distorting the image.
        background: CoverCanvas(
          cover: (_profile?.coverPhotoUrl != null && _profile!.coverPhotoUrl!.isNotEmpty)
              ? CoverImageSource.url(_profile!.coverPhotoUrl!)
              : const CoverImageSource.empty(),
          avatarUrl: _profile?.profilePhotoUrl,
          avatarInitials: _profile?.initials,
          // Name + @handle live as a clean header inside the white card
          // below the stats row, not over the cover photo. Keeps the
          // cover image uncluttered and centralizes the user identity.
          fullName: null,
          username: null,
          onCameraTap: _isOwnProfile ? _updateCoverPhoto : null,
          onAvatarTap: _isOwnProfile ? _updateProfilePhoto : null,
          showAvatarEditBadge: _isOwnProfile,
          isUploadingAvatar: _isUploadingPhoto,
          fallback: _buildDefaultCover(),
          overlay: (_isOwnProfile && _coverOverlayState != CoverUploadState.idle)
              ? CoverUploadOverlay(
                  state: _coverOverlayState,
                  progress: _coverOrchestrator?.progressListenable.value ?? 0,
                  errorMessage: _coverOverlayError,
                  onCancel: _coverOverlayState == CoverUploadState.uploading
                      ? _cancelCoverUpload
                      : _dismissCoverOverlay,
                  onRetry: _coverOverlayState == CoverUploadState.error
                      ? _retryCoverUpload
                      : null,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
    );
  }

  /// Custom horizontal icon + label tab row (no Material TabBar = no overlay/ripple).
  static IconData _tabIconData(String iconName) {
    switch (iconName) {
      case 'article': return Icons.article_outlined;
      case 'photo_library': return Icons.photo_library_outlined;
      case 'video_library': return Icons.video_library_outlined;
      case 'music_note': return Icons.music_note_outlined;
      case 'live_tv': return Icons.live_tv_outlined;
      case 'volunteer_activism': return Icons.volunteer_activism_outlined;
      case 'group': return Icons.group_outlined;
      case 'folder': return Icons.folder_outlined;
      case 'storefront': return Icons.storefront_outlined;
      case 'handshake': return Icons.handshake_outlined;
      case 'people': return Icons.people_outlined;
      case 'info': return Icons.info_outlined;
      case 'bookmark': return Icons.bookmark_outline;
      case 'auto_awesome': return Icons.auto_awesome_outlined;
      case 'settings': return Icons.settings_outlined;
      // Finance
      case 'account_balance_wallet': return Icons.account_balance_wallet_outlined;
      case 'savings': return Icons.savings_outlined;
      case 'account_balance': return Icons.account_balance_outlined;
      case 'trending_up': return Icons.trending_up_rounded;
      case 'request_quote': return Icons.request_quote_outlined;
      // Health
      case 'medical_services': return Icons.medical_services_outlined;
      case 'local_pharmacy': return Icons.local_pharmacy_outlined;
      case 'health_and_safety': return Icons.health_and_safety_outlined;
      case 'fitness_center': return Icons.fitness_center_outlined;
      // Family & Education
      case 'family_restroom': return Icons.family_restroom_outlined;
      case 'school': return Icons.school_outlined;
      case 'child_care': return Icons.child_care_outlined;
      case 'menu_book': return Icons.menu_book_outlined;
      // Work
      case 'work': return Icons.work_outline;
      case 'business_center': return Icons.business_center_outlined;
      // Daily Life
      case 'restaurant': return Icons.restaurant_outlined;
      case 'directions_car': return Icons.directions_car_outlined;
      case 'home_repair_service': return Icons.home_repair_service_outlined;
      case 'home': return Icons.home_outlined;
      case 'receipt_long': return Icons.receipt_long_outlined;
      case 'two_wheeler': return Icons.two_wheeler_outlined;
      // Planning
      case 'calendar_month': return Icons.calendar_month_outlined;
      case 'edit_note': return Icons.edit_note_outlined;
      // Government & Legal
      case 'assured_workload': return Icons.assured_workload_outlined;
      case 'gavel': return Icons.gavel_outlined;
      case 'person_pin': return Icons.person_pin_outlined;
      case 'location_city': return Icons.location_city_outlined;
      case 'account_balance': return Icons.account_balance_outlined;
      case 'domain': return Icons.domain_outlined;
      case 'description': return Icons.description_outlined;
      case 'business': return Icons.business_outlined;
      case 'card_travel': return Icons.card_travel_outlined;
      case 'credit_card': return Icons.credit_card_outlined;
      case 'landscape': return Icons.landscape_outlined;
      case 'security': return Icons.security_outlined;
      case 'bolt': return Icons.bolt_outlined;
      case 'water_drop': return Icons.water_drop_outlined;
      case 'directions_bus': return Icons.directions_bus_outlined;
      case 'policy': return Icons.policy_outlined;
      case 'gas_meter': return Icons.gas_meter_outlined;
      case 'grading': return Icons.grading_outlined;
      // Community & Lifestyle
      case 'mosque': return Icons.mosque_outlined;
      case 'diversity_3': return Icons.diversity_3_outlined;
      case 'nightlife': return Icons.nightlife_outlined;
      case 'event': return Icons.event_outlined;
      case 'flight': return Icons.flight_outlined;
      case 'sports_esports': return Icons.sports_esports_outlined;
      // Women & Family Care
      case 'spa': return Icons.spa_outlined;
      case 'face': return Icons.face_outlined;
      case 'content_cut': return Icons.content_cut_outlined;
      // Business
      case 'email': return Icons.email_outlined;
      case 'app_registration': return Icons.app_registration_outlined;
      case 'qr_code_2': return Icons.qr_code_2_rounded;
      case 'repeat': return Icons.repeat_rounded;
      case 'verified': return Icons.verified_outlined;
      case 'notifications_active': return Icons.notifications_active_outlined;
      case 'money_off': return Icons.money_off_csred_outlined;
      case 'calculate': return Icons.calculate_outlined;
      case 'credit_score': return Icons.credit_score_outlined;
      case 'badge': return Icons.badge_outlined;
      case 'payments': return Icons.payments_outlined;
      case 'local_shipping': return Icons.local_shipping_outlined;
      case 'shopping_cart': return Icons.shopping_cart_outlined;
      // Health (new)
      case 'emergency': return Icons.emergency_outlined;
      // My Cars
      case 'directions_car_filled': return Icons.directions_car_filled_outlined;
      case 'verified_user': return Icons.verified_user_outlined;
      case 'time_to_leave': return Icons.time_to_leave_outlined;
      case 'local_gas_station': return Icons.local_gas_station_outlined;
      case 'car_repair': return Icons.car_repair_outlined;
      case 'car_rental': return Icons.car_rental_outlined;
      case 'groups': return Icons.groups_outlined;
      case 'handyman': return Icons.handyman_outlined;
      // Faith — shared
      case 'favorite': return Icons.favorite_outlined;
      // Faith — Christian
      case 'back_hand': return Icons.back_hand_outlined;
      case 'church': return Icons.church_outlined;
      case 'record_voice_over': return Icons.record_voice_over_outlined;
      case 'location_on': return Icons.location_on_outlined;
      // Faith — Islamic
      case 'schedule': return Icons.schedule_outlined;
      case 'explore': return Icons.explore_outlined;
      case 'auto_stories': return Icons.auto_stories_outlined;
      case 'dark_mode': return Icons.dark_mode_outlined;
      case 'self_improvement': return Icons.self_improvement_outlined;
      case 'format_quote': return Icons.format_quote_outlined;
      case 'celebration': return Icons.celebration_outlined;
      // Education
      case 'calendar_today': return Icons.calendar_today_outlined;
      case 'assignment': return Icons.assignment_outlined;
      case 'forum': return Icons.forum_outlined;
      case 'note_alt': return Icons.note_alt_outlined;
      case 'quiz': return Icons.quiz_outlined;
      case 'grade': return Icons.grade_outlined;
      case 'local_library': return Icons.local_library_outlined;
      case 'campaign': return Icons.campaign_outlined;
      case 'work_outline': return Icons.work_outline;
      case 'history_edu': return Icons.history_edu_outlined;
      case 'psychology': return Icons.psychology_outlined;
      // Security
      case 'local_police': return Icons.local_police_outlined;
      case 'traffic': return Icons.traffic_outlined;
      case 'shield': return Icons.shield_outlined;
      default: return Icons.circle_outlined;
    }
  }

  /// Width of each tile in the stats row. Sized so the longest label
  /// ("Subscribers") fits with comfortable horizontal padding; the row
  /// scrolls horizontally if the total width exceeds the screen.
  static const double _kStatTileWidth = 104.0;


  Widget _buildProfileInfo() {
    const cardRadius = 24.0;
    const horizontalPadding = 20.0;
    const sectionSpacing = 12.0;

    final followersCount = _profile?.stats.followersCount ?? 0;
    final followingCount = _profile?.stats.followingCount ?? 0;
    final subscribersCount = _profile?.stats.subscribersCount ?? 0;
    final friendsCount = _profile?.stats.friendsCount ?? 0;

    final List<Widget> columnChildren = <Widget>[
      // 1. Stats row — soft-chip pattern. Each chip carries its own
      //    shape via a 1px hairline border, so no dividers are needed.
      //    Counts animate odometer-style on first paint via
      //    AnimatedFlipCounter; the row staggers in via flutter_animate.
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _StatChip(
              count: followersCount,
              label: AppStringsScope.of(context)?.followers ?? 'Followers',
              onTap: () => _isOwnProfile
                  ? Navigator.pushNamed(context, '/followers/manage')
                  : _openStatsBottomSheet(ProfileStatsType.followers, followersCount),
            ),
            const _StatDivider(),
            _StatChip(
              count: followingCount,
              label: AppStringsScope.of(context)?.following ?? 'Following',
              onTap: () => _isOwnProfile
                  ? Navigator.pushNamed(context, '/following/manage')
                  : _openStatsBottomSheet(ProfileStatsType.following, followingCount),
            ),
            const _StatDivider(),
            _StatChip(
              count: subscribersCount,
              label: AppStringsScope.of(context)?.subscribers ?? 'Subscribers',
              onTap: () => _isOwnProfile
                  ? Navigator.pushNamed(context, '/subscribers/manage')
                  : _openStatsBottomSheet(ProfileStatsType.subscribers, subscribersCount),
            ),
            const _StatDivider(),
            _StatChip(
              count: friendsCount,
              label: AppStringsScope.of(context)?.friends ?? 'Friends',
              onTap: () => _isOwnProfile
                  ? Navigator.pushNamed(context, '/friends/manage')
                  : _openStatsBottomSheet(ProfileStatsType.friends, friendsCount),
            ),
            if (_isOwnProfile || _familyCount > 0) ...[
              const _StatDivider(),
              _StatChip(
                count: _familyCount,
                label: (AppStringsScope.of(context)?.isSwahili ?? false)
                    ? 'Familia'
                    : 'Family',
                onTap: () {
                  if (!_isOwnProfile) {
                    _openStatsBottomSheet(
                      ProfileStatsType.family,
                      _familyCount,
                    );
                    return;
                  }
                  final isSw =
                      AppStringsScope.of(context)?.isSwahili ?? false;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ProfileTabPage(
                        title: isSw ? 'Familia' : 'Family',
                        icon: Icons.family_restroom_rounded,
                        tabId: 'family',
                        userId: widget.userId,
                        currentUserId: _currentUserId,
                        isOwnProfile: true,
                        profile: _profile,
                        onRefresh: _loadProfile,
                      ),
                    ),
                  );
                },
              ),
            ],
          ]
              .animate(interval: 60.ms)
              .fadeIn(duration: 240.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
        ),
      ),
      // Identity header: full name (bold) + @handle (muted) — single
      // source of truth, lives in the white card under the stats row.
      // Owner sees a trailing edit pencil that pushes EditProfileScreen.
      // Leading gap is part of this conditional so it collapses when
      // both name and handle are missing.
      if ((_profile?.fullName != null && _profile!.fullName.isNotEmpty) ||
          (_profile?.username != null && _profile!.username!.isNotEmpty)) ...[
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_profile?.fullName != null && _profile!.fullName.isNotEmpty)
                    Text(
                      _profile!.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (_profile?.username != null &&
                      _profile!.username!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${_profile!.username}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (_isOwnProfile) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit_rounded),
                iconSize: 20,
                color: const Color(0xFF1A1A1A),
                tooltip: AppStringsScope.of(context)?.isSwahili == true
                    ? 'Hariri wasifu'
                    : 'Edit profile',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ],
          ],
        ),
      ],

      // 3. Action buttons (when viewing someone else). Leading gap is
      // part of the conditional — collapses on own-profile view.
      if (!_isOwnProfile) ...[
        const SizedBox(height: sectionSpacing),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: ElevatedButton.icon(
                    onPressed: _isSendingFriendRequest ? null : _handleFriendAction,
                    icon: _isSendingFriendRequest
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_getActionIcon(), size: 18),
                    label: Text(
                      _isSendingFriendRequest
                          ? (AppStringsScope.of(context)?.sending ?? 'Sending...')
                          : _getFollowButtonLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      backgroundColor: _getActionButtonColor(),
                      foregroundColor: _getActionButtonForegroundColor(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubscribeToCreatorScreen(
                            creatorId: widget.userId,
                            currentUserId: _currentUserId,
                            creatorDisplayName: _profile?.fullName,
                          ),
                        ),
                      );
                      if (result == true && mounted) _loadProfile();
                    },
                    icon: const Icon(Icons.card_membership, size: 18),
                    label: const Text('Subscribe'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: OutlinedButton.icon(
                    onPressed: _openChatWithProfileUser,
                    icon: const Icon(Icons.message_outlined, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],

      // 4. Bio
      if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
        const SizedBox(height: sectionSpacing),
        Text(
          _profile!.bio!,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Colors.grey.shade700,
          ),
        ),
      ],

      // 5. Interests
      if (_profile?.interests != null && _profile!.interests!.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _profile!.interests!
              .map<Widget>((String interest) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],

      // 6. Info rows — location, basics, work, education, contact, joined.
      //    Each row is conditionally rendered by _buildAboutRows().
      ..._buildAboutRows(),

      // Tab menu - grid of four, directly under joined date
      const SizedBox(height: sectionSpacing),
      _buildTabMenuGrid(),

      if (!_isOwnProfile &&
          _profile?.mutualFriendsCount != null &&
          _profile!.mutualFriendsCount! > 0) ...[
        const SizedBox(height: 14),
        Material(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.people_outline, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  '${_profile!.mutualFriendsCount} ${AppStringsScope.of(context)?.mutualFriendsCount ?? 'mutual friends'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(cardRadius),
          topRight: Radius.circular(cardRadius),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      // Top padding tightened so the stats row sits flush against the
      // cover canvas above instead of leaving a visible gap.
      padding: const EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: columnChildren,
      ),
    );
  }

  /// Categorized flat grid: profile tabs grouped by life domain with thin dividers.
  /// Social tabs first (no header), then service categories with hairline + label.
  /// Uses stored [ProfileTabConfig.categoryId] so user-customised category moves are respected.
  Widget _buildTabMenuGrid() {
    final s = AppStringsScope.of(context);

    // Group enabled tabs by their stored category ID.
    final groups = <String, List<ProfileTabConfig>>{};
    for (final tab in _enabledTabs) {
      final catId = tab.categoryId ?? ProfileTabDefaults.getDefaultCategoryId(tab.id);
      groups.putIfAbsent(catId, () => []).add(tab);
    }

    // Sort categories by the default category order.
    final defaultOrder = {
      for (int i = 0; i < ProfileTabDefaults.categories.length; i++)
        ProfileTabDefaults.categories[i].id: i,
    };
    final sortedCategoryIds = groups.keys.toList()
      ..sort((a, b) => (defaultOrder[a] ?? 999).compareTo(defaultOrder[b] ?? 999));

    final children = <Widget>[];
    bool isFirst = true;

    for (final catId in sortedCategoryIds) {
      final categoryTabs = groups[catId]!
        ..sort((a, b) {
          final cmp = a.order.compareTo(b.order);
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        });
      if (categoryTabs.isEmpty) continue;

      // Category header with hairline divider (skip for first/social section)
      if (!isFirst && catId != 'social') {
        final label = _customCategoryLabels[catId] ??
            s?.profileTabCategoryLabel(catId) ??
            ProfileTabDefaults.categories
                .firstWhere((c) => c.id == catId, orElse: () => ProfileTabCategory(id: catId, label: catId.toUpperCase(), tabIds: []))
                .label;
        children.add(_buildCategoryDivider(label));
      }
      isFirst = false;

      // 4-column grid for this category's tabs
      children.add(
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 4,
          crossAxisSpacing: 0,
          childAspectRatio: 0.88,
          children: categoryTabs.map((t) => _buildTabMenuItem(t)).toList(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Thin hairline divider with uppercase category label.
  Widget _buildCategoryDivider(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 0, 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999999),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single tab menu item - icon + label, opens full page on tap (no background)
  Widget _buildTabMenuItem(ProfileTabConfig tab) {
    final s = AppStringsScope.of(context);
    final label = _isOwnProfile
        ? (s?.profileTabLabelOwn(tab.id) ?? tab.label)
        : (s?.profileTabLabel(tab.id) ?? tab.label);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTabPage(tab),
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellHeight = constraints.maxHeight;
            final iconSize = (cellHeight * 0.45).clamp(24.0, 32.0);
            final padding = (iconSize * 0.4).roundToDouble();
            final fontSize = (cellHeight * 0.13).clamp(9.0, 12.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _tabIconData(tab.icon),
                    size: iconSize,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: (cellHeight * 0.08).clamp(4.0, 10.0)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openStatsBottomSheet(ProfileStatsType statsType, int count) {
    ProfileStatsBottomSheet.show(
      context,
      userId: widget.userId,
      currentUserId: _currentUserId,
      statsType: statsType,
      initialCount: count,
    );
  }

  Widget _buildInfoItem(IconData icon, String text, {VoidCallback? onTap}) {
    if (text.isEmpty) return const SizedBox.shrink();
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: row,
      ),
    );
  }

  /// Builds the conditional info rows shown under bio + interests, grouped
  /// into 4 visual sections (basics, work/education, contact, account)
  /// separated by hairline dividers. Empty groups are skipped entirely.
  List<Widget> _buildAboutRows() {
    final s = AppStringsScope.of(context);
    final p = _profile;
    if (p == null) return [];

    // ── Group 1: Basics (location, age+gender, relationship, last active) ──
    final basics = <Widget>[];
    if (p.location != null) {
      basics.add(_buildInfoItem(Icons.location_on_outlined, p.location!.displayText));
    }
    final ageStr = p.age != null
        ? (s?.yearsOldShort(p.age!) ?? '${p.age} years')
        : null;
    final genderStr = _localizedGender(p.gender);
    final ageGenderParts = <String>[
      if (ageStr != null && ageStr.isNotEmpty) ageStr,
      if (genderStr != null && genderStr.isNotEmpty) genderStr,
    ];
    if (ageGenderParts.isNotEmpty) {
      basics.add(_buildInfoItem(Icons.cake_outlined, ageGenderParts.join(' · ')));
    }
    final relLabel = _localizedRelationship(p.relationshipStatus);
    if (relLabel != null && relLabel.isNotEmpty) {
      basics.add(_buildRelationshipRow(p, relLabel));
    }
    if (!_isOwnProfile && p.lastActiveAt != null) {
      basics.add(_buildInfoItem(Icons.access_time_rounded, _formatRelativeAgo(p.lastActiveAt!)));
    }

    // ── Group 2: Work & Education ──
    final workEdu = <Widget>[];
    if (p.currentEmployer != null) {
      final emp = p.currentEmployer!;
      final tags = <String>[
        if (emp.sector != null && emp.sector!.isNotEmpty) emp.sector!,
        if (emp.ownership != null && emp.ownership!.isNotEmpty) emp.ownership!,
      ];
      final empText = (emp.employerName ?? '').isEmpty
          ? ''
          : (tags.isEmpty ? emp.employerName! : '${emp.employerName} · ${tags.join(' · ')}');
      if (empText.isNotEmpty) workEdu.add(_buildInfoItem(Icons.work_outline, empText));
    }
    if (p.universityEducation != null && (p.universityEducation!.universityName ?? '').isNotEmpty) {
      final u = p.universityEducation!;
      final parts = <String>[u.universityName!];
      if (u.programmeName != null && u.programmeName!.isNotEmpty) parts.add(u.programmeName!);
      if (u.degreeLevel != null && u.degreeLevel!.isNotEmpty) parts.add(u.degreeLevel!);
      if (u.isCurrentStudent) {
        parts.add(s?.currentlyStudying ?? 'Currently studying');
      } else if (u.graduationYear != null) {
        parts.add(s?.classOfYear(u.graduationYear!) ?? 'Class of ${u.graduationYear}');
      }
      workEdu.add(_buildInfoItem(Icons.school_outlined, parts.join(' · ')));
    }
    workEdu.addAll(_educationLevelRow(p.postsecondaryEducation, s?.postsecondaryLabel ?? 'College'));
    workEdu.addAll(_educationLevelRow(p.alevelEducation, s?.alevelLabel ?? 'A-Level',
        combinationName: p.alevelEducation?.combinationName,
        combinationCode: p.alevelEducation?.combinationCode,
        subjects: p.alevelEducation?.subjects));
    workEdu.addAll(_educationLevelRow(p.secondarySchool, s?.secondarySchoolLabel ?? 'O-Level'));
    workEdu.addAll(_educationLevelRow(p.primarySchool, s?.primarySchoolLabel ?? 'Primary'));

    // ── Group 3: Contact (tappable, gated) ──
    final contact = <Widget>[];
    if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty &&
        (_isOwnProfile || p.friendshipStatus == FriendshipStatus.friends)) {
      contact.add(_buildInfoItem(
        Icons.phone_outlined,
        p.phoneNumber!,
        onTap: () => _showPhoneActions(p.phoneNumber!),
      ));
    }
    if (_isOwnProfile && p.email != null && p.email!.isNotEmpty) {
      contact.add(_buildInfoItem(
        Icons.email_outlined,
        p.email!,
        onTap: () => _launchUri('mailto:${p.email}'),
      ));
    }

    // ── Group 4: Account (joined date) ──
    final account = <Widget>[
      _buildInfoItem(
        Icons.calendar_today_outlined,
        '${s?.joined ?? 'Joined'} ${_formatDate(p.createdAt)}',
      ),
    ];

    final groups = [basics, workEdu, contact, account].where((g) => g.isNotEmpty).toList();
    if (groups.isEmpty) return [];

    final out = <Widget>[const SizedBox(height: 20.0)];
    for (var i = 0; i < groups.length; i++) {
      if (i > 0) {
        out.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
        ));
      }
      out.addAll(groups[i]);
    }
    return out;
  }

  void _showPhoneActions(String phone) {
    final s = AppStringsScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  phone,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.call_rounded),
                title: Text(s?.isSwahili ?? false ? 'Piga simu' : 'Call'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchUri('tel:$phone');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms_rounded),
                title: Text(s?.isSwahili ?? false ? 'Tuma ujumbe' : 'Send message'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchUri('sms:$phone');
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(s?.isSwahili ?? false ? 'Nakili' : 'Copy'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Clipboard.setData(ClipboardData(text: phone));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s?.isSwahili ?? false ? 'Imenakiliwa' : 'Copied')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUri(String uri) async {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return;
    try {
      await launchUrl(parsed);
    } catch (e) {
      debugPrint('[ProfileScreen] launchUrl failed for $uri: $e');
    }
  }

  List<Widget> _educationLevelRow(
    ProfileEducation? edu,
    String levelLabel, {
    String? combinationName,
    String? combinationCode,
    String? subjects,
  }) {
    if (edu == null || (edu.schoolName ?? '').isEmpty) return [];
    final s = AppStringsScope.of(context);
    final parts = <String>['$levelLabel: ${edu.schoolName}'];
    final combo = combinationName ?? combinationCode;
    if (combo != null && combo.isNotEmpty) parts.add(combo);
    if (subjects != null && subjects.isNotEmpty) parts.add(subjects);
    if (edu.graduationYear != null) {
      parts.add(s?.classOfYear(edu.graduationYear!) ?? 'Class of ${edu.graduationYear}');
    }
    return [_buildInfoItem(Icons.school_outlined, parts.join(' · '))];
  }

  String? _localizedGender(String? raw) {
    if (raw == null) return null;
    final s = AppStringsScope.of(context);
    if (s == null) return raw;
    switch (raw.toLowerCase()) {
      case 'male': return s.genderMale;
      case 'female': return s.genderFemale;
      default: return raw;
    }
  }

  String? _localizedRelationship(String? raw) {
    if (raw == null) return null;
    final s = AppStringsScope.of(context);
    if (s == null) return raw;
    switch (raw.toLowerCase()) {
      case 'single': return s.relationshipSingle;
      case 'married': return s.relationshipMarried;
      case 'engaged': return s.relationshipEngaged;
      case 'complicated': return s.relationshipComplicated;
      default: return raw;
    }
  }

  bool _isRomanticStatus(String? raw) {
    if (raw == null) return false;
    switch (raw.toLowerCase()) {
      case 'married':
      case 'engaged':
      case 'in_relationship':
      case 'dating':
        return true;
      default:
        return false;
    }
  }

  /// Builds the relationship row in the basics group. Three shapes:
  ///   • partner already tagged → label + inline avatar + @handle, tappable
  ///   • own profile, romantic status, no partner → label + "+ Tag" pill
  ///   • everyone else → plain info item
  Widget _buildRelationshipRow(FullProfile p, String relLabel) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;

    if (p.partner != null) {
      final partner = p.partner!;
      final handle = (partner.username ?? '').isNotEmpty
          ? '@${partner.username}'
          : partner.name;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed('/profile/${partner.id}'),
            onLongPress: _isOwnProfile ? () => _showPartnerActions(p) : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Text(
                    relLabel,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  Text(
                    isSw ? ' na ' : ' to ',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  _PartnerAvatar(photoUrl: partner.photoUrl, name: partner.name),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      handle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isOwnProfile && _isRomanticStatus(p.relationshipStatus)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                relLabel,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _TagPartnerPill(
              label: isSw ? '+ Mtaje mpenzi' : '+ Tag partner',
              onTap: _openPartnerPicker,
            ),
          ],
        ),
      );
    }

    return _buildInfoItem(Icons.favorite_border, relLabel);
  }

  Future<void> _openPartnerPicker() async {
    final result = await PartnerPickerSheet.show(
      context,
      currentUserId: widget.userId,
      existingPartnerId: _profile?.partner?.id,
    );
    if (result != null && mounted) {
      _loadProfile();
    }
  }

  void _showPartnerActions(FullProfile p) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF1A1A1A)),
              title: Text(isSw ? 'Badili mpenzi' : 'Change partner'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _openPartnerPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.heart_broken_outlined, color: Color(0xFF1A1A1A)),
              title: Text(isSw ? 'Ondoa mpenzi' : 'Remove partner'),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                await _removePartner();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePartner() async {
    final ok = await ProfileService().removePartner(userId: widget.userId);
    if (ok && mounted) _loadProfile();
  }

  String _formatRelativeAgo(DateTime time) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 5) return s?.activeNow ?? 'Active now';
    String agoStr;
    if (diff.inHours < 1) {
      final m = diff.inMinutes;
      agoStr = isSw ? 'dakika $m zilizopita' : '$m min ago';
    } else if (diff.inDays < 1) {
      final h = diff.inHours;
      agoStr = isSw ? 'saa $h zilizopita' : '${h}h ago';
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      agoStr = isSw ? 'siku $d zilizopita' : '${d}d ago';
    } else if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      agoStr = isSw ? 'wiki $w zilizopita' : '${w}w ago';
    } else if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      agoStr = isSw ? 'miezi $mo iliyopita' : '${mo}mo ago';
    } else {
      final y = (diff.inDays / 365).floor();
      agoStr = isSw ? 'mwaka $y zilizopita' : '${y}y ago';
    }
    return s?.lastSeenAgo(agoStr) ?? 'Last seen $agoStr';
  }

  String _getFollowButtonLabel() {
    if (_isOwnProfile) {
      return AppStringsScope.of(context)?.editProfile ?? 'Edit profile';
    }
    switch (_profile?.friendshipStatus) {
      case FriendshipStatus.none:
        return 'Follow';
      case FriendshipStatus.pending:
        return 'Accept';
      case FriendshipStatus.requested:
        return 'Requested';
      case FriendshipStatus.friends:
        return 'Following';
      case FriendshipStatus.self:
      case null:
        return 'Follow';
    }
  }

  IconData _getActionIcon() {
    switch (_profile?.friendshipStatus) {
      case FriendshipStatus.none:
        return Icons.person_add;
      case FriendshipStatus.pending:
        return Icons.check;
      case FriendshipStatus.requested:
        return Icons.hourglass_empty;
      case FriendshipStatus.friends:
        return Icons.people;
      case FriendshipStatus.self:
      case null:
        return Icons.edit;
    }
  }

  Color _getActionButtonColor() {
    switch (_profile?.friendshipStatus) {
      case FriendshipStatus.none:
        return Theme.of(context).colorScheme.primary;
      case FriendshipStatus.pending:
        return Colors.green;
      case FriendshipStatus.requested:
        return const Color(0xFFF9FAFB); // Tailwind bg-gray-50
      case FriendshipStatus.friends:
        return Colors.green;
      case FriendshipStatus.self:
      case null:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getActionButtonForegroundColor() {
    switch (_profile?.friendshipStatus) {
      case FriendshipStatus.requested:
        return const Color(0xFF6B7280); // Tailwind text-gray-500 for contrast on light bg
      case FriendshipStatus.none:
      case FriendshipStatus.pending:
      case FriendshipStatus.friends:
      case FriendshipStatus.self:
      case null:
        return Colors.white;
    }
  }

  String _formatDate(DateTime date) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return '${_localizedMonth(date.month, isSw: isSw)} ${date.year}';
  }

}

const List<String> _monthsSw = [
  'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
  'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
];

const List<String> _monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _localizedMonth(int monthOneBased, {required bool isSw}) {
  final i = (monthOneBased - 1).clamp(0, 11);
  return (isSw ? _monthsSw : _monthsEn)[i];
}

/// Full page wrapper for profile tab content
class _ProfileTabPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String tabId;
  final int userId;
  final int currentUserId;
  final bool isOwnProfile;
  final FullProfile? profile;
  final VoidCallback? onRefresh;

  const _ProfileTabPage({
    required this.title,
    required this.icon,
    required this.tabId,
    required this.userId,
    required this.currentUserId,
    required this.isOwnProfile,
    this.profile,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _buildContent(context),
    );
  }

  Widget _privateInfoPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppStringsScope.of(context)?.informationIsPrivate ?? 'This information is private',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (tabId) {
      case 'posts':
        return MyPostsPage(
          userId: userId,
          currentUserId: currentUserId,
          isOwnProfile: isOwnProfile,
        );
      case 'photos':
        return PhotoGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          heroTagPrefix: 'profile_photo',
        );
      case 'videos':
        return VideoGalleryWidgetScreen(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onUploadComplete: onRefresh,
        );
      case 'music':
        return MusicGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onUploadComplete: onRefresh,
        );
      case 'live':
        return MyStreamsPage(
          userId: userId,
          isOwnProfile: isOwnProfile,
        );
      case 'michango':
        return MichangoGalleryWidgetScreen(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onCreateCampaign: isOwnProfile
              ? () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateCampaignScreen(currentUserId: userId),
                    ),
                  );
                }
              : null,
        );
      case 'groups':
        return MyGroupsPage(
          userId: userId,
          currentUserId: currentUserId,
          isOwnProfile: isOwnProfile,
        );
      case 'documents':
        return _ProfileDocumentsPage(
          userId: userId,
          currentUserId: currentUserId,
          isOwnProfile: isOwnProfile,
        );
      case 'shop':
        return ShopGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onProductAdded: onRefresh,
        );
      // ── Finance & Money ──────────────────────────────────────────
      case 'budget':
        return BudgetModule(userId: userId);
      case 'kikoba':
        return KikobaModule(userId: userId);
      case 'my_wallet':
        return MyWalletModule(userId: userId);
      case 'subscriptions':
        return SubscriptionsModule(userId: userId);
      case 'investments':
        return InvestmentsModule(userId: userId);
      case 'loans':
        return LoansModule(userId: userId);

      // ── Health & Wellness ─────────────────────────────────────────
      case 'doctor':
        return DoctorModule(userId: userId);
      case 'pharmacy':
        return PharmacyModule(userId: userId);
      case 'insurance':
        return InsuranceModule(userId: userId);
      case 'fitness':
        return FitnessModule(userId: userId);

      // ── Women & Family Care ──────────────────────────────────────
      case 'my_circle':
        if (!isOwnProfile) {
          return _privateInfoPlaceholder(context);
        }
        return MyCircleModule(userId: userId);
      case 'my_pregnancy':
        if (!isOwnProfile) {
          return _privateInfoPlaceholder(context);
        }
        return MyPregnancyModule(userId: userId);
      case 'my_baby':
        if (!isOwnProfile) {
          return _privateInfoPlaceholder(context);
        }
        return MyBabyModule(userId: userId);
      case 'family':
        return MyFamilyModule(userId: userId);
      case 'skincare':
        return SkincareModule(userId: userId);
      case 'hair_nails':
        return HairNailsModule(userId: userId);

      // ── Business (flat tabs) ────────────────────────────────────
      // Each feature gets ALL businesses. Pages that currently take a single
      // businessId receive the first one; they can be updated later to iterate
      // all businesses with BusinessSectionHeader dividers.
      case 'biz_profile':
        return BusinessModule(userId: userId);
      case 'biz_docs':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            BusinessDocumentsPage(userId: uid, businesses: all));
      case 'biz_email':
        return const EmailClientPage();
      case 'biz_card':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            first != null ? BusinessCardPage(business: first) : const SizedBox.shrink());
      case 'biz_quotes':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? QuotesPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_invoices':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? InvoicesPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_recurring':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? RecurringInvoicesPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_vfd':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? VfdPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_customers':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? CustomersPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_debts':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? DebtsPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_reminders':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? ReminderSettingsPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_expenses':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? ExpensesPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_tax':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? TaxPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_credit':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? CreditReportPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_employees':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? EmployeesPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_payroll':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? PayrollPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_suppliers':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? SuppliersPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_po':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? PurchaseOrdersPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_tenders':
        return TendersModule(userId: userId);
      case 'biz_appointments':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? AppointmentsPage(businessId: fId) : const SizedBox.shrink());

      // ── Daily Life & Home ─────────────────────────────────────────
      case 'food':
        return FoodModule(userId: userId);
      case 'transport':
        return TransportModule(userId: userId);
      case 'services':
        return FundiModule(userId: userId);
      case 'housing':
        return HousingModule(userId: userId);
      case 'bills':
        return BillsModule(userId: userId);
      case 'vehicle':
        return VehicleModule(userId: userId);

      // ── Planning & Productivity ───────────────────────────────────
      case 'calendar':
        return CalendarModule(userId: userId);
      case 'notes':
        return NotesModule(userId: userId);

      // ── Government & Legal ────────────────────────────────────────
      case 'government':
        return GovernmentModule(userId: userId);
      case 'lawyer':
        return LawyerModule(userId: userId);
      // Leadership
      case 'barozi_wangu':
        return BaroziWanguModule(userId: userId, wardId: 0);
      case 'ofisi_mtaa':
        return OfisiMtaaModule(userId: userId, mtaaId: 0);
      case 'dc':
        return DcModule(userId: userId, districtId: 0);
      case 'rc':
        return RcModule(userId: userId, regionId: 0);
      case 'katiba':
        return KatibaModule(userId: userId);
      case 'legal_gpt':
        return LegalGptModule(userId: userId);
      // Government services
      case 'nida':
        return NidaModule(userId: userId);
      case 'rita':
        return RitaModule(userId: userId);
      case 'tra':
        return TraModule(userId: userId);
      case 'brela':
        return BrelaModule(userId: userId);
      case 'passport':
        return PassportModule(userId: userId);
      case 'driving_licence':
        return DrivingLicenceModule(userId: userId);
      case 'land_office':
        return LandOfficeModule(userId: userId);
      case 'nhif':
        return NhifModule(userId: userId);
      case 'nssf':
        return NssfModule(userId: userId);
      case 'tanesco':
        return TanescoModule(userId: userId);
      case 'dawasco':
        return DawascoModule(userId: userId);

      // ── Community & Lifestyle ─────────────────────────────────────
      case 'faith':
        return FaithModule(userId: userId);
      case 'community':
        return CommunityModule(userId: userId);
      case 'events':
        return EventsModule(userId: userId);
      case 'travel':
        return TravelModule(userId: userId);
      case 'games':
        return GamesModule(userId: userId);

      case 'creator':
        if (!isOwnProfile) return _privateInfoPlaceholder(context);
        // Creator tab landing = the 9-card revenue-sources grid
        // (Posts / Streams / Subscribers / Brand Deals / Ad Revenue /
        // My Photos / My Videos / My Music / My Files). The full
        // 15-section revenue report is one tap away via the "Full
        // revenue report" link on the grid.
        return CreatorRevenueScreen(creatorId: userId);
      // ── My Cars ──
      case 'my_cars':
        return MyCarsModule(userId: userId);
      case 'car_insurance':
        return CarInsuranceModule(userId: userId);
      case 'buy_car':
        return BuyCarModule(userId: userId);
      case 'fuel_delivery':
        return FuelDeliveryModule(userId: userId);
      case 'service_garage':
        return ServiceGarageModule(userId: userId);
      case 'sell_car':
        return SellCarModule(userId: userId);
      case 'rent_car':
        return RentCarModule(userId: userId);
      case 'owners_club':
        return OwnersClubModule(userId: userId);
      case 'spare_parts':
        return SparePartsModule(userId: userId);

      // ── Commerce + Health ──
      case 'tajirika':
        return TajirikaModule(userId: userId);
      case 'ambulance':
        return AmbulanceModule(userId: userId);

      // ── Govt extra ──
      case 'latra':
        return LatraModule(userId: userId);
      case 'tira':
        return TiraModule(userId: userId);
      case 'ewura':
        return EwuraModule(userId: userId);
      case 'heslb':
        return HeslbModule(userId: userId);
      case 'necta':
        return NectaModule(userId: userId);

      // ── Faith ──
      case 'my_faith':
        return MyFaithModule(userId: userId);
      case 'biblia':
        return BibliaModule(userId: userId);
      case 'sala':
        return SalaModule(userId: userId);
      case 'fungu_la_kumi':
        return FunguLaKumiModule(userId: userId);
      case 'kanisa_langu':
        return KanisaLanguModule(userId: userId);
      case 'huduma':
        return HudumaModule(userId: userId);
      case 'jumuiya':
        return JumuiyaModule(userId: userId);
      case 'ibada':
        return IbadaModule(userId: userId);
      case 'shule_ya_jumapili':
        return ShuleYaJumapiliModule(userId: userId);
      case 'tafuta_kanisa':
        return TafutaKanisaModule(userId: userId);
      case 'wakati_wa_sala':
        return WakatiWaSalaModule(userId: userId);
      case 'qibla':
        return QiblaModule(userId: userId);
      case 'quran':
        return QuranModule(userId: userId);
      case 'kalenda_hijri':
        return KalendaHijriModule(userId: userId);
      case 'ramadan':
        return RamadanModule(userId: userId);
      case 'zaka':
        return ZakaModule(userId: userId);
      case 'dua':
        return DuaModule(userId: userId);
      case 'hadith':
        return HadithModule(userId: userId);
      case 'tafuta_msikiti':
        return TafutaMsikitiModule(userId: userId);
      case 'maulid':
        return MaulidModule(userId: userId);

      // ── Security + Lifestyle ──
      case 'police':
        return PoliceModule(userId: userId);
      case 'traffic':
        return TrafficModule(userId: userId);
      case 'neighbourhood_watch':
        return NeighbourhoodWatchModule(userId: userId);
      case 'alerts':
        return AlertsModule(userId: userId);
      case 'nightlife':
        return NightlifeModule(userId: userId);

      // ── Education ──
      case 'my_class':
        return MyClassModule(userId: userId);
      case 'timetable':
        return TimetableModule(userId: userId);
      case 'assignments':
        return AssignmentsModule(userId: userId);
      case 'class_chat':
        return ClassChatModule(userId: userId);
      case 'class_notes':
        return ClassNotesModule(userId: userId);
      case 'exam_prep':
        return ExamPrepModule(userId: userId);
      case 'past_papers':
        return PastPapersModule(userId: userId);
      case 'newton':
        return NewtonModule(userId: userId);
      case 'results':
        return ResultsModule(userId: userId);
      case 'fee_status':
        return FeeStatusModule(userId: userId);
      case 'library':
        return LibraryModule(userId: userId);
      case 'campus_news':
        return CampusNewsModule(userId: userId);
      case 'study_groups':
        return StudyGroupsModule(userId: userId);
      case 'career':
        return CareerModule(userId: userId);

      // ── New Modules ──
      case 'my_children':
        return MyChildrenModule(userId: userId);
      case 'my_parents':
        return MyParentsModule(userId: userId);
      case 'news':
        return NewsModule(userId: userId);
      case 'reminders':
        return RemindersModule(userId: userId);
      case 'accounting':
        return AccountingModule(userId: userId);

      // ── Additional Modules ──
      case 'appointments':
        return AppointmentsModule(userId: userId);
      case 'calls':
        return CallsModule(userId: userId);
      case 'consultations':
        return ConsultationsModule(userId: userId);
      case 'crb':
        return CrbModule(userId: userId);
      case 'customer_orders':
        return CustomerOrdersModule(userId: userId);
      case 'debts':
        return DebtsModule(userId: userId);
      case 'engagements':
        return EngagementsModule(userId: userId);
      case 'expenses':
        return ExpensesModule(userId: userId);
      case 'income':
        return IncomeModule(userId: userId);
      case 'invoices':
        return InvoicesModule(userId: userId);
      case 'orders':
        return OrdersModule(userId: userId);
      case 'payroll':
        return PayrollModule(userId: userId);
      case 'products':
        return ProductsModule(userId: userId);
      case 'projects':
        return ProjectsModule(userId: userId);
      case 'recurring':
        return RecurringModule(userId: userId);
      case 'revenue':
        return RevenueModule(userId: userId);
      case 'tax':
        return TaxModule(userId: userId);
      case 'team':
        return TeamModule(userId: userId);
      case 'transactions':
        return TransactionsModule(userId: userId);
      case 'biz_services':
        return BizServicesModule(userId: userId);

      // ── Recovered orphan modules ─────────────────────────────────
      case 'mafundi':
        return mafundi_home.MafundiHomePage(userId: userId);
      case 'myjob':
        return _MyJobTokenWrapper(userId: userId);
      case 'client_directory':
        return BizTabWrapper(
            userId: userId,
            builder: (uid, all, first, fId) => fId != null
                ? clients_v2.ClientsPage(businessId: fId)
                : const SizedBox.shrink());
      case 'supplier_directory':
        return BizTabWrapper(
            userId: userId,
            builder: (uid, all, first, fId) => fId != null
                ? suppliers_v2.SuppliersPage(businessId: fId, isOwner: true)
                : const SizedBox.shrink());
      case 'vfd_compliance':
        return BizTabWrapper(
            userId: userId,
            builder: (uid, all, first, fId) => fId != null
                ? vfd_v2.VfdPage(businessId: fId)
                : const SizedBox.shrink());

      default:
        // Defensive fallback for tab IDs added to ProfileTabConfig without
        // a matching dispatcher entry. Visible only to developers; users
        // never see unknown tab IDs because the grid only shows enabled tabs
        // backed by config.
        assert(false, 'ProfileScreen: no widget mapping for tabId="$tabId"');
        final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
        return _ComingSoonTab(
          icon: icon,
          title: title,
          subtitle: isSw ? 'Inakuja Hivi Karibuni' : 'Coming soon',
          description: isSw
              ? 'Kipengele hiki kitapatikana hivi karibuni.'
              : 'This module is not yet available.',
        );
    }
  }
}

/// Instagram-style posts grid — 3-column, 1px gaps, square thumbnails.
///
/// Features:
/// - Pinned posts (up to 3) always shown first with pin icon overlay
/// - Infinite scroll with prefetch at ~70% of current batch
/// - Long-press peek preview with dimmed backdrop
/// - Shimmer loading placeholders
/// - Post type indicators (carousel, video, audio, pin)
/// - Pull-to-refresh
/// - Scroll-direction-aware thumbnail prefetching

/// Groups page content - full management for own profile
/// Documents/Files page content - Dropbox-like file management
class _ProfileDocumentsPage extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final bool isOwnProfile;

  const _ProfileDocumentsPage({
    required this.userId,
    required this.currentUserId,
    required this.isOwnProfile,
  });

  @override
  State<_ProfileDocumentsPage> createState() => _ProfileDocumentsPageState();
}

class _ProfileDocumentsPageState extends State<_ProfileDocumentsPage> {
  final FileService _fileService = FileService();

  List<UserFile> _files = [];
  List<UserFile> _recentFiles = [];
  List<UserFile> _starredFiles = [];
  StorageQuota? _quota;
  bool _isLoading = true;
  String? _error;

  FileCategory _selectedCategory = FileCategory.all;
  int? _currentFolderId;
  String _currentPath = '/';
  final List<_BreadcrumbItem> _breadcrumbs = [_BreadcrumbItem(name: 'Nyaraka', folderId: null, path: '/')];

  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF666666);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.wait([
      _loadFiles(),
      if (widget.isOwnProfile) _loadRecentFiles(),
      if (widget.isOwnProfile) _loadStarredFiles(),
      if (widget.isOwnProfile) _loadQuota(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFiles() async {
    final result = await _fileService.getFiles(
      userId: widget.userId,
      folderId: _currentFolderId,
      path: _currentPath,
      category: _selectedCategory,
    );

    if (mounted) {
      setState(() {
        if (result.success) {
          _files = result.files;
          _error = null; // Clear any previous error on success
          if (result.quota != null) _quota = result.quota;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _loadRecentFiles() async {
    final result = await _fileService.getRecentFiles(widget.userId, limit: 10);
    if (mounted && result.success) {
      setState(() => _recentFiles = result.files);
    }
  }

  Future<void> _loadStarredFiles() async {
    final result = await _fileService.getStarredFiles(widget.userId);
    if (mounted && result.success) {
      setState(() => _starredFiles = result.files);
    }
  }

  Future<void> _loadQuota() async {
    final quota = await _fileService.getStorageQuota(widget.userId);
    if (mounted && quota != null) {
      setState(() => _quota = quota);
    }
  }

  void _navigateToFolder(UserFile folder) {
    setState(() {
      _currentFolderId = folder.id;
      _currentPath = folder.path;
      _breadcrumbs.add(_BreadcrumbItem(
        name: folder.title,
        folderId: folder.id,
        path: folder.path,
      ));
    });
    _loadFiles();
  }

  void _navigateToBreadcrumb(int index) {
    if (index >= _breadcrumbs.length - 1) return;
    setState(() {
      final crumb = _breadcrumbs[index];
      _currentFolderId = crumb.folderId;
      _currentPath = crumb.path;
      _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
    });
    _loadFiles();
  }

  void _onCategoryChanged(FileCategory category) {
    setState(() => _selectedCategory = category);
    _loadFiles();
  }

  Future<void> _uploadFile() async {
    final s = AppStringsScope.of(context);

    try {
      // Pick files - allow documents and archives only
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Documents
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'txt', 'csv', 'rtf', 'odt', 'ods', 'odp',
          // Archives
          'zip', 'rar', '7z', 'tar', 'gz',
        ],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s?.uploading ?? 'Inapakia'} ${result.files.length} ${s?.files ?? 'faili'}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Upload each file
      int successCount = 0;
      int failCount = 0;

      for (final platformFile in result.files) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);
        final uploadResult = await _fileService.uploadFile(
          userId: widget.currentUserId,
          file: file,
          folderId: _currentFolderId,
          path: _currentPath,
          displayName: platformFile.name,
        );

        if (uploadResult.success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      // Show result and refresh
      if (mounted) {
        String message;
        if (failCount == 0) {
          message = '${s?.uploadSuccess ?? 'Imepakiwa'}: $successCount ${s?.files ?? 'faili'}';
        } else {
          message = '${s?.uploaded ?? 'Imepakiwa'}: $successCount, ${s?.failed ?? 'Imeshindwa'}: $failCount';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        _loadData(); // Refresh file list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s?.error ?? 'Hitilafu'}: $e')),
        );
      }
    }
  }

  Future<void> _createFolder() async {
    final s = AppStringsScope.of(context);
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.createFolder ?? 'Unda Folda'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: s?.folderName ?? 'Jina la folda',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s?.cancel ?? 'Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(s?.create ?? 'Unda'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final result = await _fileService.createFolder(
        userId: widget.currentUserId,
        name: name,
        parentFolderId: _currentFolderId,
        path: _currentPath,
      );

      if (mounted) {
        if (result.success) {
          _loadFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Imeshindwa kuunda folda')),
          );
        }
      }
    }
  }

  Future<void> _toggleStar(UserFile file) async {
    final result = await _fileService.toggleStar(file.id);
    if (mounted && result.success) {
      _loadData();
    }
  }

  Future<void> _deleteFile(UserFile file) async {
    final s = AppStringsScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.delete ?? 'Futa'),
        content: Text('${s?.deleteConfirm ?? 'Una uhakika unataka kufuta'} "${file.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s?.cancel ?? 'Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(s?.delete ?? 'Futa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _fileService.deleteFile(file.id);
      if (mounted) {
        if (success) {
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s?.actionFailed ?? 'Imeshindwa')),
          );
        }
      }
    }
  }

  Future<void> _shareFile(UserFile file) async {
    final s = AppStringsScope.of(context);
    final link = await _fileService.shareFile(file.id, publicLink: true);
    if (!mounted) return;
    if (link != null && link.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s?.linkCopied ?? 'Kiungo kimenakiliwa')),
        );
      }
      SharePlus.instance.share(ShareParams(text: link));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.actionFailed ?? 'Imeshindwa kushiriki')),
      );
    }
  }

  Future<void> _renameFile(UserFile file) async {
    final s = AppStringsScope.of(context);
    final controller = TextEditingController(text: file.title);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.rename ?? 'Badilisha jina'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ingiza jina',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s?.cancel ?? 'Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(s?.save ?? 'Hifadhi'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != file.title) {
      final result = await _fileService.renameFile(file.id, newName);
      if (mounted) {
        if (result.success) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imefanikiwa')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? (s?.actionFailed ?? 'Imeshindwa'))),
          );
        }
      }
    }
  }

  Future<void> _moveFile(UserFile file) async {
    final s = AppStringsScope.of(context);
    // Load root-level folders for the user
    final result = await _fileService.getFiles(
      userId: widget.userId,
      path: '/',
    );
    if (!mounted) return;

    final folders = result.success
        ? result.files.where((f) => f.isFolder && f.id != file.id).toList()
        : <UserFile>[];

    final targetFolderId = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.moveTo ?? 'Hamisha'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: folders.isEmpty
              ? Center(
                  child: Text(
                    'Hakuna folda',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: folders.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Root folder option
                      return ListTile(
                        leading: const Icon(Icons.folder_rounded),
                        title: const Text('/ (Mzizi)'),
                        onTap: () => Navigator.pop(context, 0),
                      );
                    }
                    final folder = folders[index - 1];
                    return ListTile(
                      leading: const Icon(Icons.folder_rounded),
                      title: Text(folder.title),
                      onTap: () => Navigator.pop(context, folder.id),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s?.cancel ?? 'Ghairi'),
          ),
        ],
      ),
    );

    if (targetFolderId != null) {
      final moveResult = await _fileService.moveFile(
        file.id,
        targetFolderId: targetFolderId == 0 ? null : targetFolderId,
        targetPath: targetFolderId == 0 ? '/' : null,
      );
      if (mounted) {
        if (moveResult.success) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imehamishwa')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(moveResult.message ?? (s?.actionFailed ?? 'Imeshindwa'))),
          );
        }
      }
    }
  }

  void _showFileOptions(UserFile file) {
    final s = AppStringsScope.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(file.isStarred ? Icons.star : Icons.star_border),
              title: Text(file.isStarred
                  ? (s?.removeFromStarred ?? 'Ondoa nyota')
                  : (s?.addToStarred ?? 'Weka nyota')),
              onTap: () {
                Navigator.pop(context);
                _toggleStar(file);
              },
            ),
            if (!file.isFolder)
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(s?.share ?? 'Shiriki'),
                onTap: () {
                  Navigator.pop(context);
                  _shareFile(file);
                },
              ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(s?.rename ?? 'Badilisha jina'),
              onTap: () {
                Navigator.pop(context);
                _renameFile(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: Text(s?.moveTo ?? 'Hamisha'),
              onTap: () {
                Navigator.pop(context);
                _moveFile(file);
              },
            ),
            if (widget.isOwnProfile)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(s?.delete ?? 'Futa', style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFile(file);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _files.isEmpty) {
      return _buildErrorState(s);
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            color: _textPrimary,
            child: CustomScrollView(
              slivers: [
                // Storage quota indicator (own profile only)
                if (widget.isOwnProfile && _quota != null)
                  SliverToBoxAdapter(child: _buildStorageIndicator(s)),

                // Category filter tabs
                SliverToBoxAdapter(child: _buildCategoryTabs(s)),

                // Breadcrumbs (when in subfolder)
                if (_breadcrumbs.length > 1)
                  SliverToBoxAdapter(child: _buildBreadcrumbs()),

                // Quick access sections (only at root and own profile)
                if (_currentFolderId == null && widget.isOwnProfile) ...[
                  // Recent files section
                  if (_recentFiles.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                        s?.recentFiles ?? 'Hivi Karibuni',
                        Icons.access_time,
                        _recentFiles.take(5).toList(),
                      ),
                    ),

                  // Starred files section
                  if (_starredFiles.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                        s?.starredFiles ?? 'Zenye Nyota',
                        Icons.star,
                        _starredFiles.take(5).toList(),
                      ),
                    ),
                ],

                // Main file list
                if (_files.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(s))
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildFileItem(_files[index]),
                        childCount: _files.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // FAB for upload (own profile only)
          if (widget.isOwnProfile)
            Positioned(
              right: 16,
              bottom: 16 + bottomPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'create_folder',
                    onPressed: _createFolder,
                    backgroundColor: _cardBg,
                    foregroundColor: _textPrimary,
                    child: const Icon(Icons.create_new_folder),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'upload_file',
                    onPressed: _uploadFile,
                    backgroundColor: _textPrimary,
                    foregroundColor: _cardBg,
                    child: const Icon(Icons.upload_file),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageIndicator(AppStrings? s) {
    if (_quota == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s?.storage ?? 'Hifadhi',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Text(
                '${_quota!.formattedUsed} / ${_quota!.formattedTotal}',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _quota!.usagePercent / 100,
              backgroundColor: _accent.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _quota!.usagePercent > 90 ? Colors.red : _textPrimary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_quota!.fileCount} ${s?.filesCount ?? 'faili'} | ${_quota!.folderCount} ${s?.foldersCount ?? 'folda'}',
            style: const TextStyle(fontSize: 11, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(AppStrings? s) {
    final categories = [
      (FileCategory.all, s?.allFiles ?? 'Zote', Icons.folder),
      (FileCategory.document, s?.documents ?? 'Nyaraka', Icons.description),
      (FileCategory.archive, s?.archives ?? 'Kumbukumbu', Icons.archive),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.$3, size: 16),
                  const SizedBox(width: 4),
                  Text(cat.$2),
                ],
              ),
              onSelected: (_) => _onCategoryChanged(cat.$1),
              selectedColor: _textPrimary.withOpacity(0.15),
              checkmarkColor: _textPrimary,
              labelStyle: TextStyle(
                color: isSelected ? _textPrimary : _textSecondary,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _breadcrumbs.asMap().entries.map((entry) {
          final index = entry.key;
          final crumb = entry.value;
          final isLast = index == _breadcrumbs.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: isLast ? null : () => _navigateToBreadcrumb(index),
                child: Text(
                  crumb.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    color: isLast ? _textPrimary : _textSecondary,
                  ),
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: _textSecondary),
                const SizedBox(width: 4),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHorizontalSection(String title, IconData icon, List<UserFile> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: files.length,
            itemBuilder: (context, index) => _buildCompactFileCard(files[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFileCard(UserFile file) {
    return GestureDetector(
      onTap: () {
        if (file.isFolder) {
          _navigateToFolder(file);
        }
        // Else open file preview
      },
      onLongPress: () => _showFileOptions(file),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getFileColor(file).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: file.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedMediaImage(
                        imageUrl: file.thumbnailUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      _getFileIcon(file),
                      size: 28,
                      color: _getFileColor(file),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              file.title,
              style: const TextStyle(fontSize: 11, color: _textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(UserFile file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (file.isFolder) {
              _navigateToFolder(file);
            }
            // Else open file preview
          },
          onLongPress: () => _showFileOptions(file),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // File icon/thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileColor(file).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: file.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedMediaImage(
                            imageUrl: file.thumbnailUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          _getFileIcon(file),
                          size: 24,
                          color: _getFileColor(file),
                        ),
                ),
                const SizedBox(width: 12),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              file.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (file.isStarred)
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file.isFolder
                            ? _formatDate(file.updatedAt)
                            : '${file.formattedSize} • ${_formatDate(file.updatedAt)}',
                        style: const TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                // More options
                IconButton(
                  icon: const Icon(Icons.more_vert, color: _textSecondary),
                  onPressed: () => _showFileOptions(file),
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(UserFile file) {
    if (file.isFolder) return Icons.folder;

    switch (file.category) {
      case FileCategory.document:
        final ext = file.extension;
        if (ext == 'pdf') return Icons.picture_as_pdf;
        if (['doc', 'docx'].contains(ext)) return Icons.description;
        if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
        if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
        if (['txt', 'md', 'rtf'].contains(ext)) return Icons.article;
        return Icons.description;
      case FileCategory.archive:
        return Icons.archive;
      case FileCategory.all:
      case FileCategory.other:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(UserFile file) {
    if (file.isFolder) return Colors.amber.shade700;

    switch (file.category) {
      case FileCategory.document:
        final ext = file.extension;
        if (ext == 'pdf') return Colors.red.shade700;
        if (['doc', 'docx'].contains(ext)) return Colors.blue;
        if (['xls', 'xlsx'].contains(ext)) return Colors.green.shade700;
        if (['ppt', 'pptx'].contains(ext)) return Colors.orange;
        return Colors.blueGrey;
      case FileCategory.archive:
        return Colors.brown;
      case FileCategory.all:
      case FileCategory.other:
        return _textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Leo';
    } else if (diff.inDays == 1) {
      return 'Jana';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} siku zilizopita';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildErrorState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _textSecondary),
            const SizedBox(height: 16),
            Text(
              _error ?? (s?.somethingWrong ?? 'Kuna tatizo'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(s?.retry ?? 'Jaribu tena'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentFolderId != null ? Icons.folder_open : Icons.cloud_upload_outlined,
              size: 64,
              color: _accent,
            ),
            const SizedBox(height: 16),
            Text(
              _currentFolderId != null
                  ? (s?.emptyFolder ?? 'Folda tupu')
                  : (s?.noFiles ?? 'Hakuna faili'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isOwnProfile
                  ? (s?.uploadFilesHint ?? 'Bonyeza + kupakia faili')
                  : (s?.noData ?? 'Hakuna data'),
              style: const TextStyle(fontSize: 14, color: _textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Breadcrumb item for folder navigation
class _BreadcrumbItem {
  final String name;
  final int? folderId;
  final String path;

  _BreadcrumbItem({
    required this.name,
    required this.folderId,
    required this.path,
  });
}

/// Friends page content

/// Placeholder tab for features coming soon.
class _ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const _ComingSoonTab({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Inakuja Hivi Karibuni',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loads the user's auth token then renders the orphan-recovery [MyJobPage].
/// MyJobPage requires the token as a constructor argument; this thin wrapper
/// fetches it from [LocalStorageService] so the dispatcher case stays clean.
class _MyJobTokenWrapper extends StatelessWidget {
  final int userId;

  const _MyJobTokenWrapper({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: () async {
        final storage = await LocalStorageService.getInstance();
        return storage.getAuthToken();
      }(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final token = snap.data;
        if (token == null || token.isEmpty) {
          return Center(child: Text(AppStringsScope.of(context)?.notSignedIn ?? 'Not signed in'));
        }
        return myjob_home.MyJobPage(token: token);
      },
    );
  }
}

/// Stat tile used in the profile stats row. Borderless / chrome-less —
/// visual separation between adjacent tiles comes from [_StatDivider].
/// Tap gives haptic feedback and a brief 0.96 scale-down. Counts <
/// [_flipMax] animate odometer-style via AnimatedFlipCounter; counts ≥
/// [_flipMax] use the compact `K`/`M` form because the flip widget
/// doesn't compact-format internally.
class _StatChip extends StatefulWidget {
  /// Threshold above which the chip falls back to a compact `12.3K`
  /// static label instead of the digit-by-digit flip counter.
  static const int _flipMax = 10000;

  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatChip({
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  State<_StatChip> createState() => _StatChipState();
}

class _StatChipState extends State<_StatChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1A1A1A);
    const muted = Color(0xFF666666);
    final hasTap = widget.onTap != null;
    final useFlip = widget.count < _StatChip._flipMax;

    const countStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.0,
      letterSpacing: -0.3,
      color: ink,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: hasTap
          ? (_) {
              HapticFeedback.selectionClick();
              _setPressed(true);
            }
          : null,
      onTapUp: hasTap ? (_) => _setPressed(false) : null,
      onTapCancel: hasTap ? () => _setPressed(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: _ProfileScreenState._kStatTileWidth,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          // No background, no border, no shadow — visual separation
          // is carried by the vertical _StatDivider between tiles.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (useFlip)
                AnimatedFlipCounter(
                  value: widget.count,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  thousandSeparator: ',',
                  textStyle: countStyle,
                )
              else
                Text(
                  _compact(widget.count),
                  style: countStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: 0.1,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin vertical separator placed between adjacent [_StatChip]s in the
/// profile stats row. Carries 8dp horizontal margin so each chip has
/// breathing room on either side.
class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFE5E5E5),
    );
  }
}

/// 16dp inline avatar shown in the relationship row when a partner is
/// tagged. Falls back to a single-letter circle when no photo is set.
class _PartnerAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;

  const _PartnerAvatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    const double r = 9;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: r,
        backgroundColor: const Color(0xFFF0F0F0),
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
        onBackgroundImageError: (_, _) {},
      );
    }
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: r,
      backgroundColor: const Color(0xFFE5E5E5),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}

/// Compact "+ Tag partner" pill used in the relationship row when the
/// owner has a romantic status but no partner yet.
class _TagPartnerPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TagPartnerPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }
}
