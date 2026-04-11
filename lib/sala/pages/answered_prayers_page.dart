// lib/sala/pages/answered_prayers_page.dart
import 'package:flutter/material.dart';
import '../models/sala_models.dart';
import '../services/sala_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AnsweredPrayersPage extends StatefulWidget {
  const AnsweredPrayersPage({super.key});
  @override
  State<AnsweredPrayersPage> createState() => _AnsweredPrayersPageState();
}

class _AnsweredPrayersPageState extends State<AnsweredPrayersPage> {
  List<PrayerRequest> _answered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await SalaService.getRequests(status: 'answered');
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _answered = r.items;
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
            Text('Maombi Yaliyojibiwa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Answered Prayers',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _answered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.celebration_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Bado hakuna maombi yaliyojibiwa\nNo answered prayers yet',
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
                    itemCount: _answered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final req = _answered[i];
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
                                const Icon(Icons.check_circle_rounded,
                                    size: 20, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(req.title,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            if (req.answerTestimony != null &&
                                req.answerTestimony!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(req.answerTestimony!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: _kPrimary,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(req.createdAt,
                                style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
