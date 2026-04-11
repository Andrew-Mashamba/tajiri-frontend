// lib/tafuta_msikiti/pages/mosque_detail_page.dart
import 'package:flutter/material.dart';
import '../models/tafuta_msikiti_models.dart';
import '../services/tafuta_msikiti_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MosqueDetailPage extends StatefulWidget {
  final int mosqueId;
  const MosqueDetailPage({super.key, required this.mosqueId});

  @override
  State<MosqueDetailPage> createState() => _MosqueDetailPageState();
}

class _MosqueDetailPageState extends State<MosqueDetailPage> {
  final _service = TafutaMsikitiService();
  Mosque? _mosque;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getMosqueDetail(widget.mosqueId);
    if (mounted) {
      setState(() {
        _mosque = result.data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: Text(_mosque?.name ?? 'Msikiti',
            style: const TextStyle(color: _kPrimary, fontSize: 18,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share coming soon / Kushiriki kunakuja'),
                  backgroundColor: _kPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary))
            : _mosque == null
                ? const Center(child: Text('Msikiti haupatikani',
                    style: TextStyle(color: _kSecondary, fontSize: 14)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ─── Hero Image Placeholder ─────────
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12)),
                        child: const Center(
                          child: Icon(Icons.mosque_rounded,
                              size: 64, color: _kSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── Name & Rating ──────────────────
                      Text(_mosque!.name,
                          style: const TextStyle(color: _kPrimary,
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: _kSecondary, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(_mosque!.address,
                                style: const TextStyle(
                                    color: _kSecondary, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ─── Prayer Times ───────────────────
                      if (_mosque!.prayerTimes != null) ...[
                        const Text('Nyakati za Iqamah',
                            style: TextStyle(color: _kPrimary, fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _buildPrayerTimesCard(_mosque!.prayerTimes!),
                        const SizedBox(height: 16),
                      ],

                      // ─── Facilities ─────────────────────
                      if (_mosque!.facilities.isNotEmpty) ...[
                        const Text('Vifaa',
                            style: TextStyle(color: _kPrimary, fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _mosque!.facilities.map((f) =>
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8)),
                              child: Text(f,
                                  style: const TextStyle(
                                      color: _kPrimary, fontSize: 12)),
                            ),
                          ).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ─── Info ───────────────────────────
                      if (_mosque!.imamName != null)
                        _infoRow('Imam', _mosque!.imamName!,
                            Icons.person_rounded),
                      if (_mosque!.denomination != null)
                        _infoRow('Madhehebu', _mosque!.denomination!,
                            Icons.group_rounded),
                      if (_mosque!.capacity != null)
                        _infoRow('Uwezo', '${_mosque!.capacity} watu',
                            Icons.people_rounded),
                      if (_mosque!.phone != null)
                        _infoRow('Simu', _mosque!.phone!,
                            Icons.phone_rounded),

                      const SizedBox(height: 16),

                      // ─── Directions Button ──────────────
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Directions coming soon / Maelekezo yanakuja'),
                                backgroundColor: _kPrimary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions_rounded, size: 20),
                          label: const Text('Get Directions / Pata Maelekezo'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPrayerTimesCard(MosquePrayerTimes pt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          if (pt.fajrIqamah != null) _ptRow('Fajr', pt.fajrIqamah!),
          if (pt.dhuhrIqamah != null) _ptRow('Dhuhr', pt.dhuhrIqamah!),
          if (pt.asrIqamah != null) _ptRow('Asr', pt.asrIqamah!),
          if (pt.maghribIqamah != null) _ptRow('Maghrib', pt.maghribIqamah!),
          if (pt.ishaIqamah != null) _ptRow('Isha', pt.ishaIqamah!),
          if (pt.jumuahKhutbah != null) ...[
            const Divider(height: 16),
            _ptRow('Jumu\'ah Khutbah', pt.jumuahKhutbah!),
          ],
        ],
      ),
    );
  }

  Widget _ptRow(String name, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(
              color: _kSecondary, fontSize: 13)),
          Text(time, style: const TextStyle(
              color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(icon, color: _kSecondary, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: _kSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value, style: const TextStyle(
                color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
