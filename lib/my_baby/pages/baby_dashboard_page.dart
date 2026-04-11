// lib/my_baby/pages/baby_dashboard_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/live_update_service.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';
import 'vaccination_page.dart';
import 'feeding_tracker_page.dart';
import 'sleep_tracker_page.dart';
import 'diaper_tracker_page.dart';
import 'growth_charts_page.dart';
import 'milestones_page.dart';
import 'health_log_page.dart';
import 'summary_page.dart';
import 'caregiver_sharing_page.dart';
import 'photo_journal_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BabyDashboardPage extends StatefulWidget {
  final Baby baby;
  final int userId;

  const BabyDashboardPage({
    super.key,
    required this.baby,
    required this.userId,
  });

  @override
  State<BabyDashboardPage> createState() => _BabyDashboardPageState();
}

class _BabyDashboardPageState extends State<BabyDashboardPage>
    with SingleTickerProviderStateMixin {
  final MyBabyService _service = MyBabyService();

  bool _isLoading = true;
  List<Vaccination> _vaccinations = [];
  List<BabyMilestone> _milestones = [];
  List<FeedingLog> _todayFeedings = [];
  Map<String, dynamic>? _dailySummary;
  String? _token;

  String? _profilePhotoUrl;
  DateTime? _nextFeedTime;

  // Speed-dial FAB state
  bool _fabExpanded = false;
  late AnimationController _fabAnimController;
  late Animation<double> _fabAnimation;

  // Real-time caregiver sync
  StreamSubscription<LiveUpdateEvent>? _liveUpdateSub;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOut,
    );
    _loadData();

    // Subscribe to live updates for real-time caregiver sync
    _liveUpdateSub = LiveUpdateService.instance.stream.listen((event) {
      if (event is BabyUpdateEvent) {
        // Reload if it's for this baby or unspecified
        if (event.babyId == null || event.babyId == widget.baby.id) {
          _loadData();
        }
      }
    });
  }

  @override
  void dispose() {
    _liveUpdateSub?.cancel();
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getVaccinationSchedule(_token!, widget.baby.id),
        _service.getMilestones(_token!, widget.baby.id),
        _service.getFeedingHistory(_token!, widget.baby.id, DateTime.now()),
        _service.getDailySummary(_token!, widget.baby.id),
      ]);

      if (mounted) {
        final vaccResult = results[0] as MyBabyListResult<Vaccination>;
        final mileResult = results[1] as MyBabyListResult<BabyMilestone>;
        final feedResult = results[2] as MyBabyListResult<FeedingLog>;
        final summaryResult = results[3] as Map<String, dynamic>?;

        setState(() {
          _isLoading = false;
          if (vaccResult.success) _vaccinations = vaccResult.items;
          if (mileResult.success) _milestones = mileResult.items;
          if (feedResult.success) _todayFeedings = feedResult.items;
          _dailySummary = summaryResult;
        });

        // Load profile photo in the background
        _loadProfilePhoto();
        // Calculate next feed time
        _calculateNextFeed();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw
              ? 'Imeshindikana kupakia data'
              : 'Failed to load data')),
        );
      }
    }
  }

  Future<void> _loadProfilePhoto() async {
    if (_token == null) return;
    try {
      final result = await _service.getPhotos(_token!, widget.baby.id, type: 'profile');
      if (!mounted) return;
      if (result.success && result.items.isNotEmpty) {
        setState(() => _profilePhotoUrl = result.items.first.displayUrl);
      }
    } catch (_) {}
  }

  void _calculateNextFeed() {
    if (_todayFeedings.isEmpty) return;
    // Find the most recent feeding
    final sorted = List<FeedingLog>.from(_todayFeedings)
      ..sort((a, b) => b.date.compareTo(a.date));
    final lastFeed = sorted.first;

    // Interval based on baby age
    final months = widget.baby.ageInMonths;
    int intervalMinutes;
    if (months < 1) {
      intervalMinutes = 150; // 2.5 hours
    } else if (months < 3) {
      intervalMinutes = 210; // 3.5 hours
    } else if (months < 6) {
      intervalMinutes = 270; // 4.5 hours
    } else {
      intervalMinutes = 330; // 5.5 hours
    }

    final nextFeed = lastFeed.date.add(Duration(minutes: intervalMinutes));
    setState(() => _nextFeedTime = nextFeed);

    // Fire-and-forget: schedule backend push notification
    if (nextFeed.isAfter(DateTime.now()) && _token != null) {
      _service.scheduleNextFeedReminder(
        widget.baby.id,
        nextFeed,
        token: _token,
      );
    }
  }

  Widget _buildNextFeedCard(bool sw) {
    if (_nextFeedTime == null) return const SizedBox.shrink();
    final isPast = _nextFeedTime!.isBefore(DateTime.now());
    final h = _nextFeedTime!.hour.toString().padLeft(2, '0');
    final m = _nextFeedTime!.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPast ? Colors.amber.shade50 : _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: isPast ? Border.all(color: Colors.amber.shade300) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.amber.shade100
                  : _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPast ? Icons.notification_important_rounded : Icons.restaurant_rounded,
              color: isPast ? Colors.amber.shade800 : _kPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPast
                      ? (sw ? 'Muda wa kulisha umefika!' : 'Feeding time has passed!')
                      : (sw ? 'Kulisha kujacho saa $h:$m' : 'Next feed expected at $h:$m'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPast ? Colors.amber.shade900 : _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sw
                      ? 'Kulingana na umri wa mtoto'
                      : 'Based on baby\'s age',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    if (_token == null) return;
    final sw = _sw;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sw ? 'Chagua Picha' : 'Choose Photo',
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx, ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 20),
                        label: Text(sw ? 'Kamera' : 'Camera',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 20),
                        label: Text(sw ? 'Galeri' : 'Gallery',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final result = await _service.uploadPhoto(
        token: _token!,
        babyId: widget.baby.id,
        filePath: picked.path,
        type: 'profile',
      );
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() => _profilePhotoUrl = result.data!.displayUrl);
        messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Picha imehifadhiwa' : 'Photo saved'),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(result.message ?? (sw ? 'Imeshindwa' : 'Failed')),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred'),
      ));
    }
  }

  Vaccination? get _nextVaccination {
    final upcoming = _vaccinations.where((v) => !v.isDone).toList()
      ..sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  int get _completedMilestones =>
      _milestones.where((m) => m.isDone).length;

  void _toggleFab() {
    setState(() => _fabExpanded = !_fabExpanded);
    if (_fabExpanded) {
      _fabAnimController.forward();
    } else {
      _fabAnimController.reverse();
    }
  }

  void _closeFab() {
    if (_fabExpanded) {
      setState(() => _fabExpanded = false);
      _fabAnimController.reverse();
    }
  }

  Future<void> _quickStartSleep() async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    _closeFab();

    try {
      final result = await _service.logSleep(
        token: _token!,
        babyId: widget.baby.id,
        startTime: DateTime.now(),
        type: 'nap',
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(sw
                  ? 'Usingizi umeanza!'
                  : 'Sleep session started!')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.baby.name,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: _buildSpeedDialFab(sw),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : GestureDetector(
              onTap: _closeFab,
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  children: [
                    // Baby info card
                    _buildBabyInfoCard(sw),
                    const SizedBox(height: 12),

                    // Daily summary stats
                    _buildDailySummary(sw),
                    const SizedBox(height: 12),

                    // Next feed reminder
                    _buildNextFeedCard(sw),
                    const SizedBox(height: 16),

                    // Quick log buttons
                    Row(
                      children: [
                        Expanded(
                          child: _QuickLogButton(
                            icon: Icons.restaurant_rounded,
                            label: sw ? 'Kulisha' : 'Feeding',
                            onTap: () {
                              _closeFab();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FeedingTrackerPage(
                                    baby: widget.baby,
                                  ),
                                ),
                              ).then((_) {
                                if (mounted) _loadData();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickLogButton(
                            icon: Icons.vaccines_rounded,
                            label: sw ? 'Chanjo' : 'Vaccination',
                            onTap: () {
                              _closeFab();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VaccinationPage(
                                    baby: widget.baby,
                                  ),
                                ),
                              ).then((_) {
                                if (mounted) _loadData();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickLogButton(
                            icon: Icons.baby_changing_station_rounded,
                            label: sw ? 'Nepi' : 'Diaper',
                            onTap: () {
                              _closeFab();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DiaperTrackerPage(
                                    baby: widget.baby,
                                  ),
                                ),
                              ).then((_) {
                                if (mounted) _loadData();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickLogButton(
                            icon: Icons.bedtime_rounded,
                            label: sw ? 'Usingizi' : 'Sleep',
                            onTap: () {
                              _closeFab();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SleepTrackerPage(
                                    baby: widget.baby,
                                  ),
                                ),
                              ).then((_) {
                                if (mounted) _loadData();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick nav section
                    Text(
                      sw ? 'Zaidi' : 'More',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                    ),
                    const SizedBox(height: 8),
                    _buildQuickNavGrid(sw),
                    const SizedBox(height: 20),

                    // Next vaccination
                    if (_nextVaccination != null) ...[
                      Text(
                        sw ? 'Chanjo Ijayo' : 'Next Vaccination',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary),
                      ),
                      const SizedBox(height: 8),
                      _buildNextVaccinationCard(sw),
                      const SizedBox(height: 20),
                    ],

                    // Recent feedings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sw ? 'Kulisha Leo' : "Today's Feeding",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                        ),
                        GestureDetector(
                          onTap: () {
                            _closeFab();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FeedingTrackerPage(baby: widget.baby),
                              ),
                            ).then((_) {
                              if (mounted) _loadData();
                            });
                          },
                          child: Text(sw ? 'Zote' : 'All',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_todayFeedings.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.restaurant_rounded,
                                size: 32, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              sw
                                  ? 'Bado hakuna rekodi ya leo'
                                  : 'No records for today',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._todayFeedings.take(5).map(
                          (f) => _FeedingItem(feeding: f, isSwahili: sw)),
                    const SizedBox(height: 20),

                    // Milestones progress
                    Text(
                      sw ? 'Maendeleo' : 'Development',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                    ),
                    const SizedBox(height: 8),
                    _buildMilestonesCard(sw),
                    const SizedBox(height: 80), // space for FAB
                  ],
                ),
              ),
            ),
    );
  }

  // ── Speed-Dial FAB ──────────────────────────────────────────────

  Widget _buildSpeedDialFab(bool sw) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FABs (animated)
        SizeTransition(
          sizeFactor: _fabAnimation,
          axisAlignment: -1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniFabItem(
                  icon: Icons.woman_rounded,
                  label: sw ? 'Kunyonyesha (Kushoto)' : 'Breast Left',
                  onTap: () {
                    _closeFab();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedingTrackerPage(
                          baby: widget.baby,
                          initialType: FeedingType.breast,
                          initialSide: BreastSide.left,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadData();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _MiniFabItem(
                  icon: Icons.local_drink_rounded,
                  label: sw ? 'Chupa' : 'Bottle',
                  onTap: () {
                    _closeFab();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedingTrackerPage(
                          baby: widget.baby,
                          initialType: FeedingType.bottle,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadData();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _MiniFabItem(
                  icon: Icons.bedtime_rounded,
                  label: sw ? 'Usingizi' : 'Sleep',
                  onTap: _quickStartSleep,
                ),
                const SizedBox(height: 8),
                _MiniFabItem(
                  icon: Icons.baby_changing_station_rounded,
                  label: sw ? 'Nepi' : 'Diaper',
                  onTap: () {
                    _closeFab();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiaperTrackerPage(
                          baby: widget.baby,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadData();
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: _kPrimary,
          shape: const CircleBorder(),
          child: AnimatedRotation(
            turns: _fabExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  // ── Daily Summary ───────────────────────────────────────────────

  Widget _buildDailySummary(bool sw) {
    final feedCount =
        _dailySummary?['feed_count'] ?? _todayFeedings.length;
    final sleepHours =
        ((_dailySummary?['sleep_minutes'] ?? 0) / 60).toStringAsFixed(1);
    final diaperCount =
        (_dailySummary?['diaper_wet'] ?? 0) +
            (_dailySummary?['diaper_dirty'] ?? 0);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.restaurant_rounded,
            value: '$feedCount',
            label: sw ? 'Kulisha' : 'Feeds',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.bedtime_rounded,
            value: '${sleepHours}h',
            label: sw ? 'Usingizi' : 'Sleep',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.baby_changing_station_rounded,
            value: '$diaperCount',
            label: sw ? 'Nepi' : 'Diapers',
          ),
        ),
      ],
    );
  }

  // ── Quick Nav Grid ──────────────────────────────────────────────

  Widget _buildQuickNavGrid(bool sw) {
    final items = <_NavItem>[
      _NavItem(Icons.show_chart_rounded, sw ? 'Ukuaji' : 'Growth Charts',
          () {
        _closeFab();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => GrowthChartsPage(baby: widget.baby)));
      }),
      _NavItem(Icons.emoji_events_rounded, sw ? 'Maendeleo' : 'Milestones',
          () {
        _closeFab();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MilestonesPage(baby: widget.baby)));
      }),
      _NavItem(Icons.local_hospital_rounded, sw ? 'Afya' : 'Health Log',
          () {
        _closeFab();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => HealthLogPage(baby: widget.baby)));
      }),
      _NavItem(Icons.analytics_rounded, sw ? 'Muhtasari' : 'Summary', () {
        _closeFab();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SummaryPage(baby: widget.baby)));
      }),
      _NavItem(Icons.people_rounded, sw ? 'Walezi' : 'Caregivers', () {
        _closeFab();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CaregiverSharingPage(
                    baby: widget.baby, userId: widget.userId)));
      }),
      _NavItem(Icons.photo_library_rounded, sw ? 'Picha' : 'Photos', () {
        _closeFab();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PhotoJournalPage(
                    baby: widget.baby, userId: widget.userId)));
      }),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: items.map((item) => _NavCard(item: item)).toList(),
    );
  }

  Widget _buildBabyInfoCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickProfilePhoto,
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    image: _profilePhotoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_profilePhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profilePhotoUrl == null
                      ? Icon(
                          widget.baby.gender == 'male'
                              ? Icons.boy_rounded
                              : widget.baby.gender == 'female'
                                  ? Icons.girl_rounded
                                  : Icons.child_care_rounded,
                          size: 32,
                          color: Colors.white,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kPrimary, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 12, color: _kPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.baby.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.baby.ageLabelLocalized(isSwahili: sw),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (widget.baby.birthWeightGrams != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    sw
                        ? 'Uzito wa kuzaliwa: ${(widget.baby.birthWeightGrams! / 1000).toStringAsFixed(2)} kg'
                        : 'Birth weight: ${(widget.baby.birthWeightGrams! / 1000).toStringAsFixed(2)} kg',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextVaccinationCard(bool sw) {
    final vacc = _nextVaccination!;
    final isOverdue = vacc.isOverdue;

    return GestureDetector(
      onTap: () {
        _closeFab();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VaccinationPage(baby: widget.baby),
          ),
        ).then((_) {
          if (mounted) _loadData();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isOverdue ? Colors.red.shade50 : _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: isOverdue
              ? Border.all(color: Colors.red.shade300)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.shade100
                    : _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.vaccines_rounded,
                size: 20,
                color: isOverdue ? Colors.red : _kPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw
                        ? (vacc.swahiliName.isNotEmpty
                            ? vacc.swahiliName
                            : vacc.name)
                        : vacc.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    vacc.ageLabel,
                    style:
                        const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                  if (isOverdue)
                    Text(
                      sw ? 'Imechelewa!' : 'Overdue!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isOverdue ? Colors.red : _kSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesCard(bool sw) {
    if (_milestones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events_rounded,
                size: 32, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              sw
                  ? 'Maendeleo yataonekana hapa'
                  : 'Development milestones will appear here',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final recentMilestones = _milestones
        .where((m) => m.ageMonths <= widget.baby.ageInMonths + 3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_completedMilestones / ${_milestones.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              Text(sw ? 'Yaliyokamilika' : 'Completed',
                  style:
                      const TextStyle(fontSize: 12, color: _kSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _milestones.isNotEmpty
                  ? _completedMilestones / _milestones.length
                  : 0,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_kPrimary),
            ),
          ),
          if (recentMilestones.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...recentMilestones.take(5).map((m) => _MilestoneItem(
                  milestone: m,
                  isSwahili: sw,
                  onToggle: () => _toggleMilestone(m),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleMilestone(BabyMilestone milestone) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    if (milestone.isDone) {
      final result = await _service.undoMilestone(_token!, milestone.id);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content:
                  Text(sw ? 'Hatua imeondolewa' : 'Milestone undone')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } else {
      final result =
          await _service.markMilestoneDone(_token!, milestone.id);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(sw
                  ? 'Hongera! Hatua imekamilika!'
                  : 'Congratulations! Milestone completed!')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa kukamilisha' : 'Failed to complete'))),
        );
      }
    }
  }
}

// ─── Stat Card ───────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: _kSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kPrimary),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item + Card ─────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem(this.icon, this.label, this.onTap);
}

class _NavCard extends StatelessWidget {
  final _NavItem item;
  const _NavCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 18, color: _kPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mini FAB Item ───────────────────────────────────────────────

class _MiniFabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniFabItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          height: 44,
          child: FloatingActionButton(
            heroTag: 'mini_$label',
            onPressed: onTap,
            backgroundColor: _kPrimary.withValues(alpha: 0.9),
            elevation: 2,
            shape: const CircleBorder(),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ─── Quick Log Button ────────────────────────────────────────────

class _QuickLogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLogButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 22, color: _kPrimary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feeding Item ────────────────────────────────────────────────

class _FeedingItem extends StatelessWidget {
  final FeedingLog feeding;
  final bool isSwahili;

  const _FeedingItem({required this.feeding, required this.isSwahili});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            feeding.type == FeedingType.breast
                ? Icons.woman_rounded
                : feeding.type == FeedingType.bottle
                    ? Icons.local_drink_rounded
                    : Icons.restaurant_rounded,
            size: 18,
            color: _kSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feeding.type.localizedName(isSwahili: isSwahili),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary),
            ),
          ),
          if (feeding.durationMinutes != null)
            Text(
              isSwahili
                  ? 'Dak. ${feeding.durationMinutes}'
                  : '${feeding.durationMinutes} min',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          if (feeding.amountMl != null)
            Text(
              '${feeding.amountMl!.toStringAsFixed(0)} ml',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          const SizedBox(width: 8),
          Text(
            '${feeding.date.hour.toString().padLeft(2, '0')}:${feeding.date.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Milestone Item ──────────────────────────────────────────────

class _MilestoneItem extends StatelessWidget {
  final BabyMilestone milestone;
  final bool isSwahili;
  final VoidCallback onToggle;

  const _MilestoneItem({
    required this.milestone,
    required this.isSwahili,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onToggle,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: milestone.isDone
                    ? const Color(0xFF4CAF50)
                    : Colors.transparent,
                border: Border.all(
                  color: milestone.isDone
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: milestone.isDone
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                milestone.title,
                style: TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  decoration:
                      milestone.isDone ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              isSwahili
                  ? 'Miezi ${milestone.ageMonths}'
                  : '${milestone.ageMonths} months',
              style: const TextStyle(fontSize: 10, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
