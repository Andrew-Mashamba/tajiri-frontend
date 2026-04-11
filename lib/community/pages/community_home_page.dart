// lib/community/pages/community_home_page.dart
import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../widgets/community_post_card.dart';
import '../widgets/service_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CommunityHomePage extends StatefulWidget {
  final int userId;
  const CommunityHomePage({super.key, required this.userId});
  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> {
  final CommunityService _service = CommunityService();

  List<CommunityPost> _posts = [];
  List<LocalService> _services = [];
  CommunityPostType? _filter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getPosts(type: _filter),
      _service.getNearbyServices(latitude: -6.7924, longitude: 39.2083),
    ]);
    if (mounted) {
      final postsResult = results[0] as CommunityListResult<CommunityPost>;
      final servicesResult = results[1] as CommunityListResult<LocalService>;
      setState(() {
        _isLoading = false;
        if (postsResult.success) _posts = postsResult.items;
        if (servicesResult.success) _services = servicesResult.items;
      });
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.diversity_3_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Jamii Yangu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Jirani, matukio ya mtaa, kujitolea, na arifa za dharura.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Emergency contacts
          const Text('Nambari za Dharura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Emergency Contacts', style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _EmergencyTile(icon: Icons.local_police_rounded, label: 'Polisi', number: '112'),
                const SizedBox(width: 8),
                _EmergencyTile(icon: Icons.local_fire_department_rounded, label: 'Zimamoto', number: '114'),
                const SizedBox(width: 8),
                _EmergencyTile(icon: Icons.local_hospital_rounded, label: 'Ambulance', number: '115'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Post filters
          const Text('Machapisho ya Jamii', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Community Posts', style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(label: 'Zote', isSelected: _filter == null, onTap: () { setState(() => _filter = null); _loadData(); }),
                ...CommunityPostType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FilterChip(
                    label: type.displayName,
                    isSelected: _filter == type,
                    onTap: () { setState(() => _filter = type); _loadData(); },
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Posts
          if (_posts.isNotEmpty)
            ..._posts.map((post) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CommunityPostCard(
                    post: post,
                    onLike: () => _service.likePost(post.id, widget.userId).then((_) { if (mounted) _loadData(); }),
                  ),
                ))
          else
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.forum_outlined, size: 48, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Hakuna machapisho', style: TextStyle(color: _kSecondary, fontSize: 14)),
                  Text('No community posts yet', style: TextStyle(color: _kSecondary, fontSize: 12)),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Nearby Services
          if (_services.isNotEmpty) ...[
            const Text('Huduma za Karibu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text('Nearby Services', style: TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 10),
            ..._services.take(5).map((svc) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ServiceCard(service: svc),
                )),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  const _EmergencyTile({required this.icon, required this.label, required this.number});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Colors.red.shade700),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
          Text(number, style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _kPrimary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : _kPrimary),
        ),
      ),
    );
  }
}
