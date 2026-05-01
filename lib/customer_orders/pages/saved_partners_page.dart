import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_i_services.dart';

/// Spec F13 — "Save my partner" works per persona (favorites scoped to skill).
class SavedPartnersPage extends StatefulWidget {
  final int userId;
  const SavedPartnersPage({super.key, required this.userId});

  @override
  State<SavedPartnersPage> createState() => _SavedPartnersPageState();
}

class _SavedPartnersPageState extends State<SavedPartnersPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await SavedPartnerService.mine(widget.userId);
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Future<void> _unsave(Map<String, dynamic> row) async {
    await SavedPartnerService.unsave(
      userId: widget.userId,
      partnerUserId: (row['partner_user_id'] as num).toInt(),
      skillCategory: row['skill_category'] as String?,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Wapendwa wangu' : 'Saved partners'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    isSw ? 'Hujahifadhi mtu yeyote bado' : 'No saved partners yet',
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                )
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, i) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _items[i];
                    final skill = r['skill_category']?.toString();
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEEEEEE),
                        child: Icon(Icons.person, color: Color(0xFF666666)),
                      ),
                      title: Text(r['partner_name']?.toString() ?? '?'),
                      subtitle: skill != null && skill.isNotEmpty
                          ? Text(skill, style: const TextStyle(fontSize: 12))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.bookmark_remove_outlined),
                        onPressed: () => _unsave(r),
                      ),
                    );
                  },
                ),
    );
  }
}
