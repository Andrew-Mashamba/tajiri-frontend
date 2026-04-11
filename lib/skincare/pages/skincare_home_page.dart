// lib/skincare/pages/skincare_home_page.dart
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';
import '../services/skincare_service.dart';
import '../widgets/skin_profile_card.dart';
import '../widgets/product_tile.dart';
import 'skin_profile_page.dart';
import 'routine_page.dart';
import 'skin_diary_page.dart';
import 'products_page.dart';
import 'ingredient_checker_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class SkincareHomePage extends StatefulWidget {
  final int userId;
  const SkincareHomePage({super.key, required this.userId});
  @override
  State<SkincareHomePage> createState() => _SkincareHomePageState();
}

class _SkincareHomePageState extends State<SkincareHomePage> {
  final SkincareService _service = SkincareService();

  SkinProfile? _profile;
  List<SkincareRoutine> _routines = [];
  List<SkinDiaryEntry> _recentDiary = [];
  List<SkinProduct> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final results = await Future.wait([
      _service.getSkinProfile(widget.userId),
      _service.getRoutines(widget.userId),
      _service.getDiaryEntries(widget.userId, month: now.month, year: now.year),
      _service.getRecommendations(widget.userId),
    ]);
    if (mounted) {
      final profileResult = results[0] as SkincareResult<SkinProfile>;
      final routinesResult = results[1] as SkincareListResult<SkincareRoutine>;
      final diaryResult = results[2] as SkincareListResult<SkinDiaryEntry>;
      final recsResult = results[3] as SkincareListResult<SkinProduct>;
      setState(() {
        _isLoading = false;
        _profile = profileResult.success ? profileResult.data : null;
        if (routinesResult.success) _routines = routinesResult.items;
        if (diaryResult.success) _recentDiary = diaryResult.items.take(5).toList();
        if (recsResult.success) _recommendations = recsResult.items.take(6).toList();
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
        onRefresh: _loadData,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Settings button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.settings_rounded, color: _kPrimary, size: 22),
                onPressed: () => _nav(SkinProfilePage(userId: widget.userId, existingProfile: _profile)),
                tooltip: 'Skin Profile',
              ),
            ),
            // Sunscreen reminder banner
            _SunscreenBanner(),
            const SizedBox(height: 12),

            // Skin profile card
            if (_profile != null)
              SkinProfileCard(
                profile: _profile!,
                onTap: () => _nav(SkinProfilePage(userId: widget.userId, existingProfile: _profile)),
              )
            else
              _SetupProfileCard(
                onTap: () => _nav(SkinProfilePage(userId: widget.userId)),
              ),
            const SizedBox(height: 16),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.edit_note_rounded,
                    label: 'Write Diary',
                    onTap: () => _nav(SkinDiaryPage(userId: widget.userId)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.loop_rounded,
                    label: 'My Routine',
                    onTap: () => _nav(RoutinePage(userId: widget.userId, routines: _routines)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Products',
                    onTap: () => _nav(ProductsPage(userId: widget.userId, skinProfile: _profile)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.science_rounded,
                    label: 'Check Ingredients',
                    onTap: () => _nav(const IngredientCheckerPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TMDA warning link
            _TmdaWarningBanner(
              onTap: () => _nav(const IngredientCheckerPage()),
            ),
            const SizedBox(height: 20),

            // Active routines preview
            if (_routines.isNotEmpty) ...[
              const Text(
                'Active Routines',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 10),
              ..._routines.where((r) => r.isActive).take(2).map((routine) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RoutinePreview(
                      routine: routine,
                      onTap: () => _nav(RoutinePage(userId: widget.userId, routines: _routines)),
                    ),
                  )),
              const SizedBox(height: 10),
            ],

            // Recent diary entries
            if (_recentDiary.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Diary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  GestureDetector(
                    onTap: () => _nav(SkinDiaryPage(userId: widget.userId)),
                    child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._recentDiary.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DiaryEntryPreview(entry: entry),
                  )),
              const SizedBox(height: 10),
            ],

            // Product recommendations
            if (_recommendations.isNotEmpty) ...[
              const Text(
                'Recommended Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 10),
              ..._recommendations.map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ProductTile(
                      product: product,
                      onTap: () => _nav(ProductsPage(userId: widget.userId, skinProfile: _profile)),
                    ),
                  )),
            ],

            // Doctor link
            const SizedBox(height: 16),
            Material(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/doctor'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: _kPrimary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact a Dermatologist',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Get professional advice about your skin',
                              style: TextStyle(fontSize: 11, color: _kSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _kSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
  }
}

// ─── Sunscreen Banner ───────────────────────────────────────────

class _SunscreenBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wb_sunny_rounded, size: 24, color: Color(0xFFFF8F00)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strong sun today \u2014 use sunscreen!',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                ),
                SizedBox(height: 2),
                Text(
                  'SPF 30+ every day, even on cloudy days',
                  style: TextStyle(fontSize: 11, color: Color(0xFFFF8F00)),
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
}

// ─── TMDA Warning Banner ────────────────────────────────────────

class _TmdaWarningBanner extends StatelessWidget {
  final VoidCallback? onTap;
  const _TmdaWarningBanner({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 24, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check dangerous products',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Check harmful chemicals in skin products \u2014 TMDA',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.red),
          ],
        ),
      ),
    );
  }
}

// ─── Setup Profile Card ─────────────────────────────────────────

class _SetupProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.face_retouching_natural_rounded, size: 48, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            const Text(
              'Start Your Skin Journey',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Answer a few questions so we can help you care for your skin',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Start Now',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action ───────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 22, color: _kPrimary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Routine Preview ────────────────────────────────────────────

class _RoutinePreview extends StatelessWidget {
  final SkincareRoutine routine;
  final VoidCallback? onTap;
  const _RoutinePreview({required this.routine, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(routine.type.icon, size: 18, color: _kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${routine.name} (${routine.type.displayName})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${routine.steps.length} steps',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                ],
              ),
              if (routine.steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: routine.steps.map((s) => Chip(
                        label: Text(s.stepType.displayName, style: const TextStyle(fontSize: 10)),
                        avatar: Icon(s.stepType.icon, size: 14),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.only(right: 4),
                      )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Diary Entry Preview ────────────────────────────────────────

class _DiaryEntryPreview extends StatelessWidget {
  final SkinDiaryEntry entry;
  const _DiaryEntryPreview({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(entry.moodIcon, size: 28, color: _kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.date.day}/${entry.date.month}/${entry.date.year} \u2014 ${entry.moodEmoji}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.notes!,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.tags.join(', '),
                    style: TextStyle(fontSize: 10, color: _kSecondary.withValues(alpha: 0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
