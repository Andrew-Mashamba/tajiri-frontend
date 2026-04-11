// lib/jumuiya/pages/jumuiya_home_page.dart
import 'package:flutter/material.dart';
import '../models/jumuiya_models.dart';
import '../services/jumuiya_service.dart';
import '../widgets/jumuiya_card.dart';
import 'group_detail_page.dart';
import 'group_finder_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class JumuiyaHomePage extends StatefulWidget {
  final int userId;
  const JumuiyaHomePage({super.key, required this.userId});
  @override
  State<JumuiyaHomePage> createState() => _JumuiyaHomePageState();
}

class _JumuiyaHomePageState extends State<JumuiyaHomePage> {
  List<JumuiyaGroup> _myGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await JumuiyaService.getMyGroups();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _myGroups = r.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : _myGroups.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _load,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Explore button
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.explore_rounded, size: 24, color: _kPrimary),
                        onPressed: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const GroupFinderPage()));
                          if (mounted) _load();
                        },
                      ),
                    ),
                      const Text('Jumuiya Zangu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                      const SizedBox(height: 4),
                      const Text('My Groups',
                          style: TextStyle(fontSize: 12, color: _kSecondary)),
                      const SizedBox(height: 12),
                      ..._myGroups.map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: JumuiyaCard(
                              group: g,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => GroupDetailPage(group: g))),
                            ),
                          )),
                      const SizedBox(height: 16),
                      // Find more
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const GroupFinderPage()));
                          if (mounted) _load();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_rounded, size: 24, color: _kPrimary),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tafuta Jumuiya',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                                    Text('Find more groups nearby',
                                        style: TextStyle(fontSize: 12, color: _kSecondary)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _kSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, size: 56, color: _kPrimary),
            const SizedBox(height: 16),
            const Text('Bado hujajiunga na jumuiya',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text('Join a small group',
                style: TextStyle(fontSize: 13, color: _kSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GroupFinderPage()));
                  if (mounted) _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tafuta / Find Groups',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
