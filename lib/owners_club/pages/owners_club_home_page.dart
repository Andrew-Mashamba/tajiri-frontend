// lib/owners_club/pages/owners_club_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/owners_club_models.dart';
import '../services/owners_club_service.dart';
import '../widgets/community_card.dart';
import 'community_feed_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class OwnersClubHomePage extends StatefulWidget {
  final int userId;
  const OwnersClubHomePage({super.key, required this.userId});
  @override
  State<OwnersClubHomePage> createState() => _OwnersClubHomePageState();
}

class _OwnersClubHomePageState extends State<OwnersClubHomePage> {
  final OwnersClubService _service = OwnersClubService();
  List<Community> _myCommunities = [];
  List<Community> _discover = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getCommunities(joined: true),
      _service.getCommunities(joined: false),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (results[0].success) _myCommunities = results[0].items;
        if (results[1].success) _discover = results[1].items;
      });
    }
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openCommunity(Community c) {
    _nav(CommunityFeedPage(community: c));
  }

  Future<void> _joinCommunity(Community c) async {
    final result = await _service.joinCommunity(c.id);
    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${c.name}'), backgroundColor: _kPrimary),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: _kPrimary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                  // My communities
                  Text(_isSwahili ? 'Jumuiya Zangu' : 'My Communities',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 10),
                  if (_myCommunities.isEmpty)
                    Container(
                      height: 80,
                      alignment: Alignment.center,
                      child: Text(_isSwahili ? 'Jiunge na jumuiya hapo chini' : 'Join a community below',
                          style: const TextStyle(color: _kSecondary, fontSize: 13)),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _myCommunities.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => SizedBox(
                          width: 130,
                          child: CommunityCard(
                            community: _myCommunities[i],
                            onTap: () => _openCommunity(_myCommunities[i]),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Discover
                  Text(_isSwahili ? 'Gundua' : 'Discover',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 10),
                  if (_discover.isEmpty)
                    Container(
                      height: 80,
                      alignment: Alignment.center,
                      child: Text(_isSwahili ? 'Hakuna jumuiya za kugundua' : 'No communities to discover',
                          style: const TextStyle(color: _kSecondary, fontSize: 13)),
                    )
                  else
                    ..._discover.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openCommunity(c),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFE8E8E8),
                                      backgroundImage:
                                          c.logoUrl != null ? NetworkImage(c.logoUrl!) : null,
                                      child: c.logoUrl == null
                                          ? Text(c.name.isNotEmpty ? c.name[0] : '?',
                                              style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.name,
                                              style: const TextStyle(
                                                  fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 2),
                                          Text('${c.memberCount} ${_isSwahili ? 'wanachama' : 'members'}',
                                              style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                        ],
                                      ),
                                    ),
                                    if (!c.isJoined)
                                      SizedBox(
                                        height: 34,
                                        child: OutlinedButton(
                                          onPressed: () => _joinCommunity(c),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _kPrimary,
                                            side: const BorderSide(color: _kPrimary),
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          child: Text(_isSwahili ? 'Jiunge' : 'Join'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            );
  }
}
