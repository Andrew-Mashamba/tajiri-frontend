// lib/my_faith/pages/my_faith_home_page.dart
import 'package:flutter/material.dart';
import '../models/my_faith_models.dart';
import '../services/my_faith_service.dart';
import '../widgets/goal_card.dart';
import 'faith_setup_page.dart';
import 'faith_goals_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class MyFaithHomePage extends StatefulWidget {
  final int userId;
  const MyFaithHomePage({super.key, required this.userId});
  @override
  State<MyFaithHomePage> createState() => _MyFaithHomePageState();
}

class _MyFaithHomePageState extends State<MyFaithHomePage> {
  FaithProfile? _profile;
  List<SpiritualGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profileR = await MyFaithService.getProfile(widget.userId);
      final goalsR = await MyFaithService.getGoals();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (profileR.success) _profile = profileR.data;
          if (goalsR.success) _goals = goalsR.items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa kupakia / Failed to load: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    if (_profile == null) return _buildEmpty();
    return RefreshIndicator(onRefresh: _load, color: _kPrimary, child: _buildContent());
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 56, color: _kPrimary),
            const SizedBox(height: 16),
            const Text('Weka wasifu wa imani yako',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text('Set up your faith profile',
                style: TextStyle(fontSize: 13, color: _kSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _navigateSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anza / Get Started',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    final faithLabel =
        p.faith == FaithSelection.islam ? 'Uislamu / Islam' : 'Ukristo / Christianity';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    p.faith == FaithSelection.islam
                        ? Icons.mosque_rounded
                        : Icons.church_rounded,
                    color: Colors.white, size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(faithLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        if (p.denomination != null)
                          Text(p.denomination!,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (p.isLeader)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(p.leaderRole ?? 'Kiongozi',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
              if (p.homeChurchName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(p.homeChurchName!,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              if (p.faithBio != null && p.faithBio!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(p.faithBio!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Milestones
        if (p.baptismDate != null || p.confirmationDate != null) ...[
          const Text('Hatua za Imani',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Spiritual Milestones',
              style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          if (p.baptismDate != null)
            _MilestoneRow(icon: Icons.water_drop_rounded, label: 'Ubatizo / Baptism', date: p.baptismDate!),
          if (p.confirmationDate != null)
            _MilestoneRow(icon: Icons.verified_rounded, label: 'Kipaimara / Confirmation', date: p.confirmationDate!),
          const SizedBox(height: 20),
        ],

        // Goals section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Malengo ya Kiroho',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                Text('Spiritual Goals',
                    style: TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const FaithGoalsPage())),
              child: const Text('Ona Zote / See All', style: TextStyle(color: _kPrimary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_goals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('Bado huna malengo. Ongeza lengo la kwanza.\nNo goals yet. Add your first goal.',
                style: TextStyle(color: _kSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          )
        else
          ..._goals.take(3).map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GoalCard(goal: g),
                ),
              ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _navigateSetup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => FaithSetupPage(userId: widget.userId, existing: _profile)),
    );
    if (result == true && mounted) _load();
  }
}

class _MilestoneRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String date;
  const _MilestoneRow({required this.icon, required this.label, required this.date});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
            ),
            Text(date, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          ],
        ),
      ),
    );
  }
}
