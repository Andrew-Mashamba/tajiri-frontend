// lib/community/pages/neighborhood_page.dart
import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../widgets/community_post_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class NeighborhoodPage extends StatefulWidget {
  final int userId;
  const NeighborhoodPage({super.key, required this.userId});
  @override
  State<NeighborhoodPage> createState() => _NeighborhoodPageState();
}

class _NeighborhoodPageState extends State<NeighborhoodPage> {
  final CommunityService _service = CommunityService();
  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  CommunityPostType? _filterType;

  final double _latitude = -6.7924;
  final double _longitude = 39.2083;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final result = await _service.getPosts(
      latitude: _latitude,
      longitude: _longitude,
      type: _filterType,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _posts = result.items;
      });
    }
  }

  void _showCreatePostSheet() {
    final contentController = TextEditingController();
    CommunityPostType selectedType = CommunityPostType.general;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Andika kwa Mtaa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const Text(
                'Post to Neighborhood',
                style: TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const SizedBox(height: 12),
              // Type selector
              Wrap(
                spacing: 8,
                children: CommunityPostType.values.map((type) {
                  final isSelected = type == selectedType;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : _kSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Andika hapa...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;
                    final result = await _service.createPost(
                      userId: widget.userId,
                      content: contentController.text.trim(),
                      type: selectedType,
                      latitude: _latitude,
                      longitude: _longitude,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (result.success) _loadPosts();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tuma / Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mtaa Wangu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('My Neighborhood',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Zote',
                    isSelected: _filterType == null,
                    onTap: () {
                      _filterType = null;
                      _loadPosts();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...CommunityPostType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: type.displayName,
                        isSelected: _filterType == type,
                        onTap: () {
                          _filterType = type;
                          _loadPosts();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Posts
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Hakuna machapisho bado',
                                style: TextStyle(color: _kSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPosts,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => CommunityPostCard(
                            post: _posts[i],
                            onLike: () async {
                              await _service.likePost(
                                  _posts[i].id, widget.userId);
                              _loadPosts();
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _kSecondary,
          ),
        ),
      ),
    );
  }
}
