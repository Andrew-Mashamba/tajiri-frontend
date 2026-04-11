// lib/jumuiya/pages/group_finder_page.dart
import 'package:flutter/material.dart';
import '../models/jumuiya_models.dart';
import '../services/jumuiya_service.dart';
import '../widgets/jumuiya_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class GroupFinderPage extends StatefulWidget {
  const GroupFinderPage({super.key});
  @override
  State<GroupFinderPage> createState() => _GroupFinderPageState();
}

class _GroupFinderPageState extends State<GroupFinderPage> {
  final _searchCtrl = TextEditingController();
  List<JumuiyaGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final q = _searchCtrl.text.trim();
    final r = await JumuiyaService.discover(search: q.isEmpty ? null : q);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _groups = r.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tafuta Jumuiya',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Find Groups',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Tafuta jina la jumuiya...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.groups_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Hakuna jumuiya zilizopatikana\nNo groups found',
                                style: TextStyle(color: _kSecondary, fontSize: 14),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _groups.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => JumuiyaCard(
                            group: _groups[i],
                            showJoinButton: !_groups[i].isMember,
                            onJoin: () async {
                              final r = await JumuiyaService.joinGroup(_groups[i].id);
                              if (!mounted) return;
                              if (r.success) {
                                _load();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(r.message ?? 'Imeshindwa kujiunga / Failed to join')),
                                );
                              }
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
