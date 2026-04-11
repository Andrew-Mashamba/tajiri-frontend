// lib/sala/pages/sala_home_page.dart
import 'package:flutter/material.dart';
import '../models/sala_models.dart';
import '../services/sala_service.dart';
import '../widgets/prayer_request_card.dart';
import 'create_prayer_page.dart';
import 'prayer_journal_page.dart';
import 'answered_prayers_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class SalaHomePage extends StatefulWidget {
  final int userId;
  const SalaHomePage({super.key, required this.userId});
  @override
  State<SalaHomePage> createState() => _SalaHomePageState();
}

class _SalaHomePageState extends State<SalaHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<PrayerRequest> _myRequests = [];
  List<PrayerRequest> _sharedFeed = [];
  PrayerStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      SalaService.getRequests(status: 'active'),
      SalaService.getSharedFeed(),
      SalaService.getStats(),
    ]);
    if (mounted) {
      final myR = results[0] as PaginatedResult<PrayerRequest>;
      final feedR = results[1] as PaginatedResult<PrayerRequest>;
      final statsR = results[2] as SingleResult<PrayerStats>;
      setState(() {
        _isLoading = false;
        if (myR.success) _myRequests = myR.items;
        if (feedR.success) _sharedFeed = feedR.items;
        if (statsR.success) _stats = statsR.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.book_rounded, size: 22, color: _kPrimary),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const PrayerJournalPage())),
              ),
              IconButton(
                icon: const Icon(Icons.celebration_rounded, size: 22, color: _kPrimary),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AnsweredPrayersPage())),
              ),
              const Spacer(),
              FloatingActionButton.small(
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePrayerPage()),
                  );
                  if (created == true && mounted) _load();
                },
                backgroundColor: _kPrimary,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        // Tabs
        TabBar(
          controller: _tabCtrl,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [
            Tab(text: 'Zangu / Mine'),
            Tab(text: 'Jamii / Community'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildMyTab(),
                    _buildCommunityTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMyTab() {
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats
          if (_stats != null) _buildStatsRow(),
          const SizedBox(height: 16),
          const Text('Maombi Yangu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('My Prayer Requests',
              style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          if (_myRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('Ongeza ombi la kwanza la sala\nAdd your first prayer request',
                  style: TextStyle(color: _kSecondary, fontSize: 13),
                  textAlign: TextAlign.center),
            )
          else
            ..._myRequests.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PrayerRequestCard(request: r, isOwn: true),
                )),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: _sharedFeed.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Hakuna maombi ya jumuiya\nNo community prayers',
                      style: TextStyle(color: _kSecondary, fontSize: 14),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sharedFeed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => PrayerRequestCard(
                request: _sharedFeed[i],
                isOwn: false,
                onPray: () => _prayFor(_sharedFeed[i].id),
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    final s = _stats!;
    return Row(
      children: [
        _StatBox(value: '${s.totalRequests}', label: 'Maombi / Prayers'),
        const SizedBox(width: 10),
        _StatBox(value: '${s.answeredCount}', label: 'Jibiwa / Answered'),
        const SizedBox(width: 10),
        _StatBox(value: '${s.streak}', label: 'Mfululizo / Streak'),
      ],
    );
  }

  Future<void> _prayFor(int id) async {
    final r = await SalaService.prayForRequest(id);
    if (!mounted) return;
    if (r.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message ?? 'Imeshindwa / Failed')),
      );
    }
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
