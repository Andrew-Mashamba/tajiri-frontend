import 'package:flutter/material.dart';
import '../../models/sponsored_post_models.dart';
import '../../services/sponsored_post_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/creator_tier_badge.dart';
import '../../l10n/app_strings_scope.dart';

class SponsoredPostsScreen extends StatefulWidget {
  final int currentUserId;

  const SponsoredPostsScreen({super.key, required this.currentUserId});

  @override
  State<SponsoredPostsScreen> createState() => _SponsoredPostsScreenState();
}

class _SponsoredPostsScreenState extends State<SponsoredPostsScreen> {
  final SponsoredPostService _service = SponsoredPostService();
  List<SponsorableCreator> _creators = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCreators();
  }

  Future<void> _loadCreators() async {
    setState(() { _loading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() { _error = 'Not authenticated'; _loading = false; });
        return;
      }
      final creators = await _service.browseSponsorableCreators(token: token);
      if (mounted) {
        setState(() { _creators = creators; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          strings?.browseSponsorableCreators ?? 'Browse Creators',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Color(0xFF666666))),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _loadCreators, child: Text(strings?.retry ?? 'Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadCreators,
                  color: const Color(0xFF1A1A1A),
                  child: _creators.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 100),
                          Center(child: Text(
                            strings?.starLegendOnly ?? 'Star & Legend only',
                            style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
                          )),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _creators.length,
                          itemBuilder: (context, index) {
                            final creator = _creators[index];
                            return _buildCreatorCard(creator, strings);
                          },
                        ),
                ),
    );
  }

  Widget _buildCreatorCard(SponsorableCreator creator, dynamic strings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/profile/${creator.userId}'),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE0E0E0),
              backgroundImage: creator.avatarUrl != null ? NetworkImage(creator.avatarUrl!) : null,
              child: creator.avatarUrl == null
                  ? const Icon(Icons.person_rounded, size: 24, color: Color(0xFF999999))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(creator.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                      ),
                      const SizedBox(width: 6),
                      CreatorTierBadge(tier: creator.tier),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCount(creator.followerCount)} followers · ${creator.avgEngagementRate.toStringAsFixed(1)}% engagement · ${creator.topCategory}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
