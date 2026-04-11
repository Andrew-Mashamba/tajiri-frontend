// lib/sala/pages/prayer_journal_page.dart
import 'package:flutter/material.dart';
import '../models/sala_models.dart';
import '../services/sala_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PrayerJournalPage extends StatefulWidget {
  const PrayerJournalPage({super.key});
  @override
  State<PrayerJournalPage> createState() => _PrayerJournalPageState();
}

class _PrayerJournalPageState extends State<PrayerJournalPage> {
  List<PrayerJournalEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await SalaService.getJournal();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _entries = r.items;
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
            Text('Shajara ya Sala',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Prayer Journal',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.book_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Bado huna maandishi\nNo entries yet',
                          style: TextStyle(color: _kSecondary, fontSize: 14),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 16, color: _kSecondary),
                                const SizedBox(width: 6),
                                Text(e.date,
                                    style: const TextStyle(
                                        fontSize: 12, color: _kSecondary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(e.content,
                                style: const TextStyle(
                                    fontSize: 14, color: _kPrimary, height: 1.5),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis),
                            if (e.scriptureRef != null &&
                                e.scriptureRef!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.menu_book_rounded,
                                      size: 14, color: _kSecondary),
                                  const SizedBox(width: 4),
                                  Text(e.scriptureRef!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: _kSecondary)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showAddDialog() {
    final contentCtrl = TextEditingController();
    final scriptureCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Andika Sala / Write Prayer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Sala yako...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: scriptureCtrl,
              decoration: InputDecoration(
                hintText: 'Aya (hiari) / Scripture (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await SalaService.addJournalEntry({
                    'content': contentCtrl.text.trim(),
                    'scripture_ref': scriptureCtrl.text.trim(),
                  });
                  if (mounted) _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hifadhi / Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
