// lib/fitness/pages/fitness_home_page.dart
import 'package:flutter/material.dart';
import '../models/fitness_models.dart';
import '../services/fitness_service.dart';
import '../widgets/stats_card.dart';
import '../widgets/gym_card.dart';
import '../widgets/class_card.dart';
import 'browse_gyms_page.dart';
import 'gym_detail_page.dart';
import 'live_classes_page.dart';
import 'my_memberships_page.dart';
import 'log_workout_page.dart';
import 'workout_history_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class FitnessHomePage extends StatefulWidget {
  final int userId;
  const FitnessHomePage({super.key, required this.userId});
  @override
  State<FitnessHomePage> createState() => _FitnessHomePageState();
}

class _FitnessHomePageState extends State<FitnessHomePage> {
  final FitnessService _service = FitnessService();

  FitnessStats? _stats;
  List<FitnessClass> _liveClasses = [];
  List<Gym> _featuredGyms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getStats(widget.userId),
      _service.getClasses(liveOnly: true, page: 1),
      _service.findGyms(page: 1),
    ]);
    if (mounted) {
      final statsResult = results[0] as FitnessResult<FitnessStats>;
      final classesResult = results[1] as FitnessListResult<FitnessClass>;
      final gymsResult = results[2] as FitnessListResult<Gym>;
      setState(() {
        _isLoading = false;
        _stats = statsResult.success ? statsResult.data : FitnessStats();
        if (classesResult.success) _liveClasses = classesResult.items.take(5).toList();
        if (gymsResult.success) _featuredGyms = gymsResult.items.take(4).toList();
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Stats card
          if (_stats != null) StatsCard(stats: _stats!),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(child: _QuickAction(icon: Icons.add_rounded, label: 'Log Workout', onTap: () => _nav(LogWorkoutPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.fitness_center_rounded, label: 'Gym', onTap: () => _nav(BrowseGymsPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.live_tv_rounded, label: 'Live', onTap: () => _nav(LiveClassesPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.card_membership_rounded, label: 'Memberships', onTap: () => _nav(MyMembershipsPage(userId: widget.userId)))),
            ],
          ),
          const SizedBox(height: 20),

          // Workout types
          const Text('Workout Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: WorkoutType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _nav(LiveClassesPage(userId: widget.userId, initialType: t)),
                      child: Column(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                            child: Icon(t.icon, size: 22, color: _kPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(t.displayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _kPrimary)),
                        ],
                      ),
                    ),
                  )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Live now
          if (_liveClasses.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.red),
                    SizedBox(width: 6),
                    Text('Live Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _nav(LiveClassesPage(userId: widget.userId)),
                  child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._liveClasses.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClassCard(fitnessClass: c, onTap: () {
                    // Navigate to stream viewer (reuse existing livestream infrastructure)
                    if (c.streamUrl != null) {
                      Navigator.pushNamed(context, '/streams');
                    }
                  }),
                )),
            const SizedBox(height: 16),
          ],

          // Featured gyms
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Popular Gyms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              GestureDetector(
                onTap: () => _nav(BrowseGymsPage(userId: widget.userId)),
                child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._featuredGyms.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GymCard(gym: g, onTap: () => _nav(GymDetailPage(userId: widget.userId, gym: g))),
              )),

          // History link
          const SizedBox(height: 16),
          Material(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _nav(WorkoutHistoryPage(userId: widget.userId)),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: _kPrimary),
                    SizedBox(width: 12),
                    Text('Workout History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    Spacer(),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 22, color: _kPrimary),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}
