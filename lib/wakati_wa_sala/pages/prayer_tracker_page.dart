// lib/wakati_wa_sala/pages/prayer_tracker_page.dart
import 'package:flutter/material.dart';
import '../models/wakati_wa_sala_models.dart';
import '../services/wakati_wa_sala_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PrayerTrackerPage extends StatefulWidget {
  final int userId;
  const PrayerTrackerPage({super.key, required this.userId});

  @override
  State<PrayerTrackerPage> createState() => _PrayerTrackerPageState();
}

class _PrayerTrackerPageState extends State<PrayerTrackerPage> {
  final _service = WakatiWaSalaService();
  List<PrayerLogEntry> _logs = [];
  bool _loading = true;

  final _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  final _today = DateTime.now().toString().split(' ').first;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken() ?? '';
    final result = await _service.getLogHistory(token: token);
    if (mounted) {
      setState(() {
        _logs = result.items;
        _loading = false;
      });
    }
  }

  Future<void> _logPrayer(String name, PrayerStatus status) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken() ?? '';
      final entry = PrayerLogEntry(
        id: 0,
        prayerName: name,
        date: _today,
        status: status,
      );
      final result = await _service.logPrayer(token: token, entry: entry);
      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name saved / imehifadhiwa'),
            backgroundColor: _kPrimary,
          ),
        );
        _loadLogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to save / Imeshindwa kuhifadhi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prayer Tracker / Fuatilia Sala',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── Today's Prayers ────────────────────
                  const Text(
                    'Sala za Leo',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._prayerNames.map(_buildPrayerLogCard),

                  const SizedBox(height: 24),

                  // ─── Recent History ─────────────────────
                  const Text(
                    'Historia ya Hivi Karibuni',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_logs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Text(
                        'Hakuna historia bado',
                        style: TextStyle(color: _kSecondary, fontSize: 14),
                      ),
                    )
                  else
                    ..._logs.take(20).map(_buildLogTile),
                ],
              ),
      ),
    );
  }

  Widget _buildPrayerLogCard(String name) {
    final logged = _logs.any((l) => l.prayerName == name && l.date == _today);
    final entry = _logs.where(
      (l) => l.prayerName == name && l.date == _today,
    );
    final status = entry.isNotEmpty ? entry.first.status : PrayerStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: logged ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            logged
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: logged ? Colors.green : _kSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (logged)
                  Text(
                    status.label,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!logged) ...[
            _statusButton('Kwa wakati', PrayerStatus.onTime, name),
            const SizedBox(width: 8),
            _statusButton('Qadha', PrayerStatus.qada, name),
          ],
        ],
      ),
    );
  }

  Widget _statusButton(String label, PrayerStatus status, String prayer) {
    return SizedBox(
      height: 32,
      child: TextButton(
        onPressed: () => _logPrayer(prayer, status),
        style: TextButton.styleFrom(
          foregroundColor: _kPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _kSecondary, width: 0.5),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildLogTile(PrayerLogEntry log) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        log.status == PrayerStatus.onTime
            ? Icons.check_circle_rounded
            : Icons.schedule_rounded,
        color: log.status == PrayerStatus.onTime
            ? Colors.green
            : _kSecondary,
        size: 20,
      ),
      title: Text(
        '${log.prayerName} - ${log.date}',
        style: const TextStyle(color: _kPrimary, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        log.status.label,
        style: const TextStyle(color: _kSecondary, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
