// lib/study_groups/pages/study_groups_home_page.dart
import 'package:flutter/material.dart';
import '../models/study_groups_models.dart';
import '../services/study_groups_service.dart';
import 'group_detail_page.dart';
import 'create_group_page.dart';
import '../widgets/study_group_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class StudyGroupsHomePage extends StatefulWidget {
  final int userId;
  const StudyGroupsHomePage({super.key, required this.userId});
  @override
  State<StudyGroupsHomePage> createState() => _StudyGroupsHomePageState();
}

class _StudyGroupsHomePageState extends State<StudyGroupsHomePage> with SingleTickerProviderStateMixin {
  final StudyGroupsService _service = StudyGroupsService();
  late TabController _tabController;
  List<StudyGroup> _myGroups = [];
  List<StudyGroup> _discover = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([_service.getMyGroups(), _service.discoverGroups()]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        final myRes = results[0] as StudyListResult<StudyGroup>;
        final discRes = results[1] as StudyListResult<StudyGroup>;
        if (myRes.success) _myGroups = myRes.items;
        if (discRes.success) _discover = discRes.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : NestedScrollView(
                headerSliverBuilder: (_, __) => [
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
                      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.groups_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text('Vikundi vya Kusoma', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        ]),
                        SizedBox(height: 6),
                        Text('Study Groups — learn together, grow together', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                    ),
                  )),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(TabBar(
                      controller: _tabController,
                      labelColor: _kPrimary, unselectedLabelColor: _kSecondary, indicatorColor: _kPrimary,
                      tabs: [Tab(text: 'Vikundi Vyangu (${_myGroups.length})'), Tab(text: 'Gundua')],
                    )),
                  ),
                ],
                body: TabBarView(controller: _tabController, children: [
                  _buildMyGroups(),
                  _buildDiscover(),
                ]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroupPage(userId: widget.userId))).then((_) => _loadData()),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildMyGroups() {
    if (_myGroups.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.group_add_rounded, size: 48, color: _kSecondary),
        SizedBox(height: 8),
        Text('Huna kikundi bado', style: TextStyle(color: _kSecondary)),
        Text('Create or join a study group', style: TextStyle(color: _kSecondary, fontSize: 12)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myGroups.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: StudyGroupCard(group: _myGroups[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailPage(group: _myGroups[i], userId: widget.userId)))),
      ),
    );
  }

  Widget _buildDiscover() {
    if (_discover.isEmpty) return const Center(child: Text('Hakuna vikundi vya kugundua / No groups to discover', style: TextStyle(color: _kSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _discover.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: StudyGroupCard(
          group: _discover[i],
          showJoin: true,
          onJoin: () async {
            await _service.joinGroup(_discover[i].id);
            if (mounted) _loadData();
          },
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: _kBg, child: tabBar);
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => false;
}
