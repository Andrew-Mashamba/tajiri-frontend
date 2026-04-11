// lib/huduma/pages/speakers_page.dart
import 'package:flutter/material.dart';
import '../models/huduma_models.dart';
import '../services/huduma_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SpeakersPage extends StatefulWidget {
  const SpeakersPage({super.key});
  @override
  State<SpeakersPage> createState() => _SpeakersPageState();
}

class _SpeakersPageState extends State<SpeakersPage> {
  List<Speaker> _speakers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await HudumaService.getSpeakers();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _speakers = r.items;
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
            Text('Wahubiri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Speakers', style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _speakers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Hakuna wahubiri / No speakers',
                          style: TextStyle(color: _kSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _speakers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final sp = _speakers[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: sp.photoUrl != null ? NetworkImage(sp.photoUrl!) : null,
                              child: sp.photoUrl == null
                                  ? const Icon(Icons.person_rounded, color: _kSecondary)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sp.name,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (sp.churchName != null)
                                    Text(sp.churchName!,
                                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('Mahubiri / Sermons: ${sp.sermonCount}',
                                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final r = await HudumaService.followSpeaker(sp.id);
                                if (!mounted) return;
                                if (r.success) {
                                  _load();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(r.message ?? 'Imeshindwa / Failed')),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sp.isFollowing ? Colors.grey.shade100 : _kPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  sp.isFollowing ? 'Unafuatia / Following' : 'Fuata / Follow',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sp.isFollowing ? _kSecondary : Colors.white,
                                  ),
                                ),
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
