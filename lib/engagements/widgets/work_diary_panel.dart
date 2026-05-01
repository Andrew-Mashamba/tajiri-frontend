import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';

/// Spec F7 #66 — Engagement work-diary panel.
///
/// Customer-side gallery view of partner-attached entries (timestamp + photo +
/// note). Polls `/api/engagement-time-diary/{engagementId}`.
class WorkDiaryEntry {
  final int id;
  final String? photoUrl;
  final String? note;
  final int secondsLogged;
  final DateTime? capturedAt;

  const WorkDiaryEntry({
    required this.id,
    this.photoUrl,
    this.note,
    required this.secondsLogged,
    this.capturedAt,
  });

  factory WorkDiaryEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }
    return WorkDiaryEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      photoUrl: json['photo_url'] as String?,
      note: json['note'] as String?,
      secondsLogged: (json['seconds_logged'] as num?)?.toInt() ?? 0,
      capturedAt: parseDt(json['captured_at']),
    );
  }
}

class WorkDiaryPanel extends StatefulWidget {
  final int engagementId;
  const WorkDiaryPanel({super.key, required this.engagementId});

  @override
  State<WorkDiaryPanel> createState() => _WorkDiaryPanelState();
}

class _WorkDiaryPanelState extends State<WorkDiaryPanel> {
  bool _loading = true;
  List<WorkDiaryEntry> _entries = const [];
  int _totalMinutes = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagement-time-diary/${widget.engagementId}')!;
    try {
      final res = await http.get(Uri.parse(url));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          final list = (body['entries'] as List?)
                  ?.whereType<Map>()
                  .map((m) => WorkDiaryEntry.fromJson(m.cast<String, dynamic>()))
                  .toList() ??
              const <WorkDiaryEntry>[];
          setState(() {
            _entries = list;
            _totalMinutes = (body['total_minutes'] as num?)?.toInt() ?? 0;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _fmtTimestamp(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '${t.day}/${t.month} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              const Icon(Icons.timelapse_rounded, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              Text(
                isSw ? 'Diari ya kazi' : 'Work diary',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A)),
              ),
              const Spacer(),
              if (_totalMinutes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_totalMinutes}m ${isSw ? "imefuatiliwa" : "tracked"}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A)),
                  ),
                ),
            ],
          ),
        ),
        if (_entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isSw
                  ? 'Bado hakuna kumbukumbu zilizoongezwa.'
                  : 'No diary entries yet.',
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _entries.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final e = _entries[i];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (e.photoUrl != null && e.photoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            e.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              color: const Color(0xFFEEEEEE),
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_rounded,
                                  color: Color(0xFF999999)),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 14, color: Color(0xFF666666)),
                              const SizedBox(width: 4),
                              Text(
                                e.capturedAt != null
                                    ? _fmtTimestamp(e.capturedAt!)
                                    : '',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF666666)),
                              ),
                              const Spacer(),
                              if (e.secondsLogged > 0)
                                Text(
                                  '${(e.secondsLogged / 60).round()}m',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A)),
                                ),
                            ],
                          ),
                          if (e.note != null && e.note!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              e.note!,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF1A1A1A)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
