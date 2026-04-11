// lib/kanisa_langu/pages/church_members_page.dart
import 'package:flutter/material.dart';
import '../models/kanisa_langu_models.dart';
import '../services/kanisa_langu_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ChurchMembersPage extends StatefulWidget {
  final int churchId;
  const ChurchMembersPage({super.key, required this.churchId});
  @override
  State<ChurchMembersPage> createState() => _ChurchMembersPageState();
}

class _ChurchMembersPageState extends State<ChurchMembersPage> {
  List<ChurchMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await KanisaLanguService.getMembers(widget.churchId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _members = r.items;
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
            Text('Wanachama',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Church Members',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Hakuna wanachama / No members',
                          style: TextStyle(color: _kSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m = _members[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: m.photoUrl != null
                                  ? NetworkImage(m.photoUrl!)
                                  : null,
                              child: m.photoUrl == null
                                  ? const Icon(Icons.person_rounded, color: _kSecondary)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name,
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (m.role != null)
                                    Text(m.role!,
                                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
